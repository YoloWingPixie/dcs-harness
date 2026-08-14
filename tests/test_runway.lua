local lu = require("luaunit")

TestRunway = {}

local function rawRunway(name, course, position)
    return {
        Name = name,
        length = 1000,
        width = 40,
        course = course,
        position = position or { x = 500, y = 25, z = 1000 },
    }
end

function TestRunway:testReciprocalNames()
    lu.assertEquals(GetReciprocalRunwayName("09"), "27")
    lu.assertEquals(GetReciprocalRunwayName("09L"), "27R")
    lu.assertEquals(GetReciprocalRunwayName("27R"), "09L")
    lu.assertEquals(GetReciprocalRunwayName("18C"), "36C")
end

function TestRunway:testNormalizationGeometryAndOrder()
    local runways = NormalizeDirectionalRunways("Test Field", {
        rawRunway("09L", -math.pi / 2),
        { Name = "bad", length = "x" },
        rawRunway("18C", -math.pi),
    })

    lu.assertEquals(#runways, 4)
    lu.assertEquals(runways[1].name, "09L")
    lu.assertEquals(runways[2].name, "27R")
    lu.assertEquals(runways[3].name, "18C")
    lu.assertEquals(runways[4].name, "36C")
    lu.assertEquals(runways[1].sourceIndex, 1)
    lu.assertEquals(runways[3].sourceIndex, 3)
    lu.assertEquals(runways[1].key, "Test Field|09L")
    lu.assertEquals(runways[1].headingDeg, 90)
    lu.assertAlmostEquals(runways[1].forward.y, 1, 1e-8)
    lu.assertNil(runways[1].forward.z)
    lu.assertAlmostEquals(runways[1].threshold.x, 500, 1e-8)
    lu.assertAlmostEquals(runways[1].threshold.z, 500, 1e-8)
    lu.assertAlmostEquals(runways[1].departureEnd.z, 1500, 1e-8)
    lu.assertEquals(runways[1].center.y, 25)
    lu.assertAlmostEquals(runways[2].threshold.z, 1500, 1e-8)
    lu.assertAlmostEquals(runways[2].departureEnd.z, 500, 1e-8)
end

function TestRunway:testCourseCorrection()
    local runways = NormalizeDirectionalRunways("Correction", {
        rawRunway("09", math.pi / 2),
    })
    lu.assertEquals(runways[1].headingDeg, 90)
    lu.assertTrue(runways[1].courseAdjusted)
    lu.assertTrue(runways[2].courseAdjusted)
end

function TestRunway:testGetDirectionalRunwaysProtectsBoundary()
    local airbase = {
        getName = function()
            return "Boundary"
        end,
        getRunways = function()
            return { rawRunway("36", 0) }
        end,
    }
    local runways = GetDirectionalRunways(airbase)
    lu.assertEquals(#runways, 2)
    lu.assertEquals(runways[1].airbase, airbase)
    lu.assertEquals(runways[1].airbaseName, "Boundary")

    airbase.getRunways = function()
        error("failure")
    end
    lu.assertNil(GetDirectionalRunways(airbase))
end

function TestRunway:testValidAirbaseWithNoUsableRunwaysReturnsEmptyArray()
    local airbase = {
        getName = function()
            return "Empty"
        end,
        getRunways = function()
            return { { Name = "bad", length = "invalid" } }
        end,
    }
    lu.assertEquals(GetDirectionalRunways(airbase), {})
end

function TestRunway:testConvenienceFunctions()
    local runway = NormalizeDirectionalRunways("Geometry", {
        rawRunway("36", 0, { x = 0, y = 10, z = 0 }),
    })[1]
    local along, lateral = GetRunwayRelativePosition(runway, { x = -100, y = 100, z = 25 })
    lu.assertAlmostEquals(along, 400, 1e-8)
    lu.assertAlmostEquals(lateral, 25, 1e-8)

    local forward, right = GetRunwayRelativeVelocity(runway, { x = 20, y = -2, z = -4 })
    lu.assertAlmostEquals(forward, 20, 1e-8)
    lu.assertAlmostEquals(right, -4, 1e-8)

    local finalPoint = { x = -1000, y = 110, z = 100 }
    lu.assertTrue(GetRunwayLineupError(runway, finalPoint) > 0)
    lu.assertTrue(GetRunwayGlidepathAngle(runway, finalPoint, 10) > 0)
    lu.assertNil(GetRunwayLineupError(runway, runway.threshold))
    lu.assertNil(GetRunwayGlidepathAngle(runway, runway.threshold, 10))

    lu.assertEquals(GetHeadwindComponent({ x = -10, y = 0, z = 0 }, 0), 10)
    local reciprocal = NormalizeDirectionalRunways("Tie", { rawRunway("36", 0) })
    local selected, component = SelectRunwayByHeadwind(reciprocal, { x = 0, y = 0, z = 0 })
    lu.assertEquals(selected, reciprocal[1])
    lu.assertEquals(component, 0)

    local nearest, distance = FindNearestRunway(reciprocal, { x = 500, y = 0, z = 1000 })
    lu.assertEquals(nearest, reciprocal[1])
    lu.assertEquals(distance, 0)
end

return TestRunway
