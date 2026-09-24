local lu = require("luaunit")

TestNativeBoundary = {}

function TestNativeBoundary:setUp()
    self.savedLog = _HarnessInternal.log.error
    self.savedGlobals = {}
    self.globalNames = {
        "coord",
        "Unit",
        "Group",
        "StaticObject",
        "trigger",
        "land",
        "net",
        "world",
        "atmosphere",
        "missionCommands",
        "DCS",
        "coalition",
    }
    for _, name in ipairs(self.globalNames) do
        self.savedGlobals[name] = _G[name]
    end
    self.messages = {}
    _HarnessInternal.log.error = function(message)
        self.messages[#self.messages + 1] = message
    end
end

function TestNativeBoundary:tearDown()
    _HarnessInternal.log.error = self.savedLog
    for _, name in ipairs(self.globalNames) do
        _G[name] = self.savedGlobals[name]
    end
end

function TestNativeBoundary:testCoordinateTuplePreservesLongitude()
    local calls = 0
    coord = {
        LOtoLL = function(point)
            calls = calls + 1
            lu.assertEquals(point, { x = 1, y = 2, z = 3 })
            return 12.5, -45.25, 100
        end,
    }
    local first = LOtoLL({ x = 1, y = 2, z = 3 })
    lu.assertEquals(first, { latitude = 12.5, longitude = -45.25 })
    local second = LOtoLL({ x = 1, y = 2, z = 3 })
    lu.assertFalse(rawequal(first, second))
    lu.assertEquals(calls, 2)
end

function TestNativeBoundary:testWeaponLookupFailureIsContained()
    local weapon = setmetatable({}, {
        __index = function()
            error("removed object")
        end,
    })
    lu.assertNil(GetWeaponPoint(weapon))
    lu.assertNil(GetWeaponPoint(42))
    lu.assertTrue(#self.messages > 0)
end

function TestNativeBoundary:testUnprintableNativeErrorIsContained()
    local failure = setmetatable({}, {
        __tostring = function()
            error("cannot stringify")
        end,
    })
    local weapon = {
        getPoint = function()
            error(failure)
        end,
    }
    lu.assertNil(GetWeaponPoint(weapon))
    lu.assertTrue(#self.messages > 0)
    lu.assertStrContains(self.messages[1], "Failed to get weapon point")
end

function TestNativeBoundary:testSuccessfulFalseAndArgumentsArePreserved()
    local weapon = {}
    local calls = 0
    weapon.isExist = function(receiver)
        lu.assertIs(receiver, weapon)
        calls = calls + 1
        return false, "private native detail"
    end
    local result, extra = IsWeaponExist(weapon)
    lu.assertFalse(result)
    lu.assertNil(extra)
    lu.assertEquals(calls, 1)
end

function TestNativeBoundary:testUnavailableGlobalIsContained()
    coord = nil
    lu.assertNil(LOtoLL({ x = 1, y = 2, z = 3 }))
    Unit = nil
    lu.assertNil(GetUnit("missing native unit"))
end

function TestNativeBoundary:testGlobalMemberFailuresRespectWrapperFallbacks()
    local unavailable = setmetatable({}, {
        __index = function()
            error("native lookup failed")
        end,
    })
    local cases = {
        {
            "missionCommands",
            function()
                return AddSubMenu(nil, "Menu")
            end,
        },
        {
            "land",
            function()
                return GetTerrainHeight(Vec3())
            end,
            0,
        },
        {
            "land",
            function()
                return HasLOS(Vec3(), Vec3())
            end,
            false,
        },
        {
            "atmosphere",
            function()
                return GetWind(Vec3())
            end,
        },
        {
            "net",
            function()
                return GetPlayerIds()
            end,
        },
        {
            "DCS",
            function()
                return IsServer()
            end,
            false,
        },
        {
            "DCS",
            function()
                return GetMissionName()
            end,
        },
        {
            "world",
            function()
                return GetFogThickness()
            end,
        },
    }
    for _, case in ipairs(cases) do
        local previous = _G[case[1]]
        _G[case[1]] = unavailable
        local ok, result = pcall(case[2])
        _G[case[1]] = previous
        lu.assertTrue(ok, case[1])
        lu.assertEquals(result, case[3])
    end
    world, coalition = unavailable, nil
    lu.assertNil(GetAllAirbases())
    world = { weather = unavailable }
    lu.assertNil(GetWorldWeather())
end

function TestNativeBoundary:testCoordinateValidationAndZeroResults()
    local calls = 0
    coord = {
        LOtoLL = function()
            calls = calls + 1
            return 0, 0
        end,
    }
    lu.assertEquals(LOtoLL(Vec3()), { latitude = 0, longitude = 0 })
    for _, invalid in ipairs({ Vec3("1", 0, 0), Vec3(0, math.huge, 0), Vec3(0, 0, 0 / 0) }) do
        lu.assertNil(LOtoLL(invalid))
    end
    lu.assertEquals(calls, 1)
    for _, value in ipairs({ false, "1", 0 / 0, math.huge, -math.huge }) do
        coord.LOtoLL = function()
            return value, 2
        end
        lu.assertNil(LOtoLL(Vec3()))
        coord.LOtoLL = function()
            return 1, value
        end
        lu.assertNil(LOtoLL(Vec3()))
    end
    coord.LOtoLL = function()
        return 1
    end
    lu.assertNil(LOtoLL(Vec3()))
end

function TestNativeBoundary:testNativeArgumentsAndNilReturnPositions()
    local target = {}
    local unit = {}
    unit.getRadar = function(receiver)
        lu.assertIs(receiver, unit)
        return nil, target, "unexposed"
    end
    local active, returned, extra = GetUnitRadar(unit)
    lu.assertNil(active)
    lu.assertIs(returned, target)
    lu.assertNil(extra)
    lu.assertEquals(select("#", GetUnitRadar(unit)), 2)
    local controller = {}
    local calls = 0
    controller.setSpeed = function(receiver, speed, keep)
        lu.assertIs(receiver, controller)
        lu.assertEquals(speed, 123)
        lu.assertFalse(keep)
        calls = calls + 1
    end
    lu.assertTrue(SetControllerSpeed(controller, 123, false))
    lu.assertEquals(calls, 1)
end
