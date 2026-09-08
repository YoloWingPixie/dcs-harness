local lu = require("luaunit")

TestMissionUnitIndex = {}

function TestMissionUnitIndex:testSparseCategoriesAndRawSkills()
    local mission = {
        coalition = {
            blue = { country = { [3] = { id = 2 } } },
            red = { country = { [8] = { id = 9 } } },
        },
    }
    local categories = { "vehicle", "plane", "helicopter", "ship", "static" }
    local skills = { "Random", "Player", "Client", "Excellent", "Average" }
    for i, category in ipairs(categories) do
        mission.coalition.blue.country[3][category] = {
            group = {
                [9] = {
                    units = {
                        [4] = {
                            name = category,
                            unitId = i,
                            type = "type " .. i,
                            skill = skills[i],
                        },
                    },
                },
            },
        }
    end
    mission.coalition.red.country[8].plane =
        { group = { sample = { units = { named = { name = "red" } } } } }
    local index, reason = MissionUnitIndex(mission)
    lu.assertNil(reason)
    for i, category in ipairs(categories) do
        lu.assertEquals(index:get(category), {
            name = category,
            unitId = i,
            typeName = "type " .. i,
            skill = skills[i],
            category = category,
            countryId = 2,
            coalition = "blue",
        })
    end
    lu.assertEquals(index:get("red").coalition, "red")
    lu.assertNil(index:get("absent"))
    lu.assertNil(index:get(false))
    lu.assertNil(index:get(""))
end

function TestMissionUnitIndex:testMalformedBranchesDuplicatesAndIsolation()
    local unit = { name = "named", unitId = {}, type = false, skill = 4 }
    local units = { unit, false, { name = "" }, { name = 5 } }
    local country =
        { id = "invalid", vehicle = { group = { false, { units = units } } }, plane = 7 }
    local mission = { coalition = { false, blue = { country = { false, country } } } }
    local index = MissionUnitIndex(mission)
    lu.assertEquals(
        index:get("named"),
        { name = "named", category = "vehicle", coalition = "blue" }
    )
    unit.name, unit.skill = "changed", "Random"
    local returned = index:get("named")
    returned.skill, returned.name = "Player", "edited"
    lu.assertEquals(
        index:get("named"),
        { name = "named", category = "vehicle", coalition = "blue" }
    )
    units[9] = { name = "changed" }
    local duplicate, reason = MissionUnitIndex(mission)
    lu.assertNil(duplicate)
    lu.assertStrContains(reason, "changed")
end

function TestMissionUnitIndex:testExplicitInputDoesNotReadEnvironment()
    local original = env
    env = setmetatable({}, {
        __index = function()
            error("environment read")
        end,
    })
    local ok, index = pcall(MissionUnitIndex, {})
    env = original
    lu.assertTrue(ok)
    lu.assertNotNil(index)
    local originalMission = env.mission
    env.mission = nil
    local missing, reason = MissionUnitIndex()
    env.mission = originalMission
    lu.assertNil(missing)
    lu.assertIsString(reason)
    lu.assertNil(MissionUnitIndex(false))
    env.mission = {}
    local selected = MissionUnitIndex()
    env.mission = originalMission
    lu.assertNotNil(selected)
end
