local lu = require("luaunit")
require("test_utils")

package.path = package.path .. ";../src/?.lua"

TestControllerOptionBuilders = CreateIsolatedTestSuite("TestControllerOptionBuilders", {})

function TestControllerOptionBuilders:setUp()
    if not package.loaded["mock_dcs"] then
        require("mock_dcs")
    end
    HARNESS_VERSION = "1.0.0-test"
    _HarnessInternal = { loggers = {}, defaultNamespace = "Harness" }
    dofile("../src/logger.lua")
    dofile("../src/controller.lua")
end

function TestControllerOptionBuilders:testBuildAirOptionTask_shape()
    local optId = (AI and AI.Option and AI.Option.Air and AI.Option.Air.id and AI.Option.Air.id.ROE)
        or 0
    local t = BuildAirOptionTask(optId, 2)
    lu.assertEquals(t.id, "Option")
    lu.assertEquals(t.params.enable, true)
    lu.assertEquals(t.params.name, optId)
    lu.assertEquals(t.params.value, 2)
end

function TestControllerOptionBuilders:testBuildGroundOptionTask_shape()
    local optId = (
        AI
        and AI.Option
        and AI.Option.Ground
        and AI.Option.Ground.id
        and AI.Option.Ground.id.ROE
    ) or 0
    local t = BuildGroundOptionTask(optId, 4)
    lu.assertEquals(t.id, "Option")
    lu.assertEquals(t.params.name, optId)
    lu.assertEquals(t.params.value, 4)
end

function TestControllerOptionBuilders:testBuildNavalOptionTask_shape()
    local optId = (
        AI
        and AI.Option
        and AI.Option.Naval
        and AI.Option.Naval.id
        and AI.Option.Naval.id.ROE
    ) or 0
    local t = BuildNavalOptionTask(optId, 3)
    lu.assertEquals(t.id, "Option")
    lu.assertEquals(t.params.name, optId)
    lu.assertEquals(t.params.value, 3)
end

function TestControllerOptionBuilders:testBuildAirOptions_defaults_and_overrides()
    local tasks = BuildAirOptions()
    lu.assertTrue(#tasks >= 5)
    -- Override ROE and SILENCE
    tasks = BuildAirOptions({ ROE = "WEAPON_HOLD", SILENCE = true })
    local foundROE, foundSilence = false, false
    for _, t in ipairs(tasks) do
        if
            t.params.name
            == (AI and AI.Option and AI.Option.Air and AI.Option.Air.id and AI.Option.Air.id.ROE)
        then
            foundROE = true
            lu.assertEquals(t.id, "Option")
            -- cannot reliably assert exact numeric without mapping table; ensure it's a number
            lu.assertEquals(type(t.params.value), "number")
        elseif
            t.params.name
            == (
                AI
                and AI.Option
                and AI.Option.Air
                and AI.Option.Air.id
                and AI.Option.Air.id.SILENCE
            )
        then
            foundSilence = true
            lu.assertEquals(t.params.value, true)
        end
    end
    lu.assertTrue(foundROE)
    lu.assertTrue(foundSilence)
end

function TestControllerOptionBuilders:testBuildGroundOptions_defaults_and_overrides()
    local tasks = BuildGroundOptions()
    lu.assertTrue(#tasks >= 2)
    tasks =
        BuildGroundOptions({ ROE = "OPEN_FIRE", ALARM_STATE = "GREEN", DISPERSE_ON_ATTACK = 60 })
    local names = {}
    for _, t in ipairs(tasks) do
        names[t.params.name] = t.params.value
    end
    local gid = AI and AI.Option and AI.Option.Ground and AI.Option.Ground.id
    if gid then
        lu.assertNotNil(names[gid.ROE])
        lu.assertNotNil(names[gid.ALARM_STATE])
        lu.assertEquals(names[gid.DISPERSE_ON_ATTACK], 60)
    end
end

function TestControllerOptionBuilders:testBuildNavalOptions_defaults_and_overrides()
    local tasks = BuildNavalOptions()
    lu.assertTrue(#tasks >= 1)
    tasks = BuildNavalOptions({ ROE = "RETURN_FIRE" })
    local nid = AI and AI.Option and AI.Option.Naval and AI.Option.Naval.id
    if nid then
        local found = false
        for _, t in ipairs(tasks) do
            if t.params.name == nid.ROE then
                found = true
            end
        end
        lu.assertTrue(found)
    end
end

return TestControllerOptionBuilders
