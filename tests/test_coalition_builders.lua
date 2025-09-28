local lu = require("luaunit")
require("test_utils")

package.path = package.path .. ";../src/?.lua"

TestCoalitionBuilders = CreateIsolatedTestSuite("TestCoalitionBuilders", {})

function TestCoalitionBuilders:setUp()
    if not package.loaded["mock_dcs"] then
        require("mock_dcs")
    end
    -- Minimal header init
    HARNESS_VERSION = "1.0.0-test"
    _HarnessInternal = {
        loggers = {},
        defaultNamespace = "Harness",
    }
    -- Load modules under test
    dofile("../src/logger.lua")
    dofile("../src/coalition.lua")
end

function TestCoalitionBuilders:testBuildUnitEntry_valid()
    local u = BuildUnitEntry("F-15C", "Unit-1", 100, 200, 3000, math.pi / 2, {
        skill = AI and AI.Skill and AI.Skill.HIGH or "High",
        callsign = { 1, 1, 1 },
        onboard_num = "010",
    })
    lu.assertNotNil(u)
    lu.assertEquals(u.type, "F-15C")
    lu.assertEquals(u.name, "Unit-1")
    lu.assertEquals(u.x, 100)
    lu.assertEquals(u.y, 200)
    lu.assertEquals(u.alt, 3000)
    lu.assertEquals(u.heading, math.pi / 2)
    lu.assertEquals(u.callsign[1], 1)
    lu.assertEquals(u.onboard_num, "010")
end

function TestCoalitionBuilders:testBuildUnitEntry_invalid()
    local u1 = BuildUnitEntry(nil, "U", 0, 0, 0, 0)
    lu.assertNil(u1)
    local u2 = BuildUnitEntry("Type", nil, 0, 0, 0, 0)
    lu.assertNil(u2)
    local u3 = BuildUnitEntry("Type", "U", "x", 0, 0, 0)
    lu.assertNil(u3)
    local u4 = BuildUnitEntry("Type", "U", 0, 0, "alt", 0)
    lu.assertNil(u4)
end

function TestCoalitionBuilders:testBuildWaypoint_withTasks()
    local tasks = {
        { number = 1, auto = false, enabled = true, id = "Orbit", params = { pattern = "Circle" } },
    }
    local wp = BuildWaypoint(1000, 2000, 3000, 250, tasks)
    lu.assertNotNil(wp)
    lu.assertEquals(wp.x, 1000)
    lu.assertEquals(wp.z, 2000)
    lu.assertEquals(wp.alt, 3000)
    lu.assertEquals(wp.speed, 250)
    lu.assertEquals(#wp.task.params.tasks, 1)
end

function TestCoalitionBuilders:testBuildGroupData_valid()
    local unit = BuildUnitEntry("F-15C", "U1", 0, 0, 1000, 0)
    local wp1 = BuildWaypoint(0, 0, 1000, 200)
    local wp2 = BuildWaypoint(10000, 0, 1000, 200)
    local grp = BuildGroupData("G1", "CAP", { unit }, { wp1, wp2 }, { frequency = 251 })
    lu.assertNotNil(grp)
    lu.assertEquals(grp.name, "G1")
    lu.assertEquals(grp.task, "CAP")
    lu.assertEquals(#grp.units, 1)
    lu.assertEquals(#grp.route.points, 2)
    lu.assertEquals(grp.frequency, 251)
end

function TestCoalitionBuilders:testBuildGroupData_invalid()
    local unit = BuildUnitEntry("F-15C", "U1", 0, 0, 1000, 0)
    lu.assertNil(BuildGroupData(nil, "CAP", { unit }))
    lu.assertNil(BuildGroupData("", "CAP", { unit }))
    lu.assertNil(BuildGroupData("G1", nil, { unit }))
    lu.assertNil(BuildGroupData("G1", "", { unit }))
    lu.assertNil(BuildGroupData("G1", "CAP", {}))
end

function TestCoalitionBuilders:testBuildRoute_points()
    local wp1 = BuildWaypoint(0, 0, 1000, 200)
    local wp2 = BuildWaypoint(100, 0, 1000, 200)
    local route = BuildRoute({ wp1, wp2 })
    lu.assertNotNil(route)
    lu.assertEquals(#route.points, 2)
end

return TestCoalitionBuilders
