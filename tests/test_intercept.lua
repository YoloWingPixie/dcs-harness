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
