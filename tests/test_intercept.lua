local lu = require("luaunit")

TestIntercept = {}

function TestIntercept:testInterceptForSpeed_headOn()
    local t, p, v = EstimateInterceptForSpeed(
        { x = 0, y = 0, z = 0 },
        1,
        { x = 10, y = 0, z = 0 },
        { x = 0, y = 0, z = 0 }
    )
    lu.assertAlmostEquals(t, 10, 1e-6)
    lu.assertAlmostEquals(p.x, 10, 1e-6)
    lu.assertAlmostEquals(v.x, 1, 1e-6)
end

function TestIntercept:testInterceptForSpeed_movingTarget()
    -- A at origin speed 2, B at x=10 moving +x at 1 => meet in ~10s at x~20
    local t, p, v = EstimateInterceptForSpeed(
        { x = 0, y = 0, z = 0 },
        2,
        { x = 10, y = 0, z = 0 },
        { x = 1, y = 0, z = 0 }
    )
    lu.assertNotNil(t)
    lu.assertTrue(t > 0)
    lu.assertAlmostEquals(p.x, (10 + 1 * t), 1e-4)
    -- required velocity magnitude approx 2
    local mag = math.sqrt(v.x * v.x + v.z * v.z)
    lu.assertAlmostEquals(mag, 2, 1e-6)
end

function TestIntercept:testInterceptForSpeed_linearSolution()
    local t, p, v = EstimateInterceptForSpeed(
        { x = 0, y = 100, z = 0 },
        1,
        { x = 10, y = 200, z = 0 },
        { x = -1, y = 0, z = 0 }
    )

    lu.assertAlmostEquals(t, 5, 1e-6)
    lu.assertAlmostEquals(p.x, 5, 1e-6)
    lu.assertAlmostEquals(v.x, 1, 1e-6)
end

function TestIntercept:testInterceptForSpeed_colocatedInterceptsImmediately()
    local t, p, v = EstimateInterceptForSpeed(
        { x = 4, y = 100, z = 8 },
        1,
        { x = 4, y = 200, z = 8 },
        { x = 1, y = 0, z = 0 }
    )

    lu.assertEquals(t, 0)
    lu.assertEquals(p, { x = 4, y = 100, z = 8 })
    lu.assertEquals(v, { x = 0, y = 100, z = 0 })
end

function TestIntercept:testInterceptForSpeed_rejectsUnavailableSolutions()
    local perpendicular = {
        EstimateInterceptForSpeed(
            { x = 0, y = 0, z = 0 },
            1,
            { x = 10, y = 0, z = 0 },
            { x = 0, y = 0, z = 2 }
        ),
    }
    local movingAway = {
        EstimateInterceptForSpeed(
            { x = 0, y = 0, z = 0 },
            1,
            { x = 10, y = 0, z = 0 },
            { x = 2, y = 0, z = 0 }
        ),
    }

    lu.assertEquals(perpendicular, {})
    lu.assertEquals(movingAway, {})
end

function TestIntercept:testDeltaV_withSpeed()
    local dV, t, p, v = EstimateInterceptDeltaV(
        { x = 0, y = 0, z = 0 },
        { x = 0, y = 0, z = 0 },
        { x = 10, y = 0, z = 0 },
        { x = 0, y = 0, z = 0 },
        1
    )
    lu.assertAlmostEquals(t, 10, 1e-6)
    lu.assertAlmostEquals(p.x, 10, 1e-6)
    lu.assertAlmostEquals(dV.x, 1, 1e-6)
end

return TestIntercept
