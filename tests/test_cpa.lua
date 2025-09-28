local lu = require("luaunit")

TestCPA = {}

function TestCPA:testCPAToPoint_stationary()
    local t, d, p = EstimateCPAToPoint(
        { x = 0, y = 0, z = 0 },
        { x = 0, y = 0, z = 0 },
        { x = 10, y = 0, z = 0 }
    )
    lu.assertEquals(t, 0)
    lu.assertAlmostEquals(d, 10, 1e-6)
    lu.assertEquals(p.x, 0)
end

function TestCPA:testCPAToPoint_movingToward()
    local t, d, p = EstimateCPAToPoint(
        { x = 0, y = 0, z = 0 },
        { x = 1, y = 0, z = 0 },
        { x = 10, y = 0, z = 0 }
    )
    lu.assertAlmostEquals(t, 10, 1e-6)
    lu.assertAlmostEquals(d, 0, 1e-6)
    lu.assertAlmostEquals(p.x, 10, 1e-6)
end

function TestCPA:testTwoBodyCPA_headOn()
    local t, d, a, b = EstimateTwoBodyCPA(
        { x = -10, y = 0, z = 0 },
        { x = 1, y = 0, z = 0 },
        { x = 10, y = 0, z = 0 },
        { x = -1, y = 0, z = 0 }
    )
    lu.assertAlmostEquals(t, 10, 1e-6)
    lu.assertAlmostEquals(d, 0, 1e-6)
    lu.assertAlmostEquals(a.x, 0, 1e-6)
    lu.assertAlmostEquals(b.x, 0, 1e-6)
end

function TestCPA:testCPAToCircle()
    local t, d = EstimateCPAToCircle(
        { x = 0, y = 0, z = 0 },
        { x = 1, y = 0, z = 0 },
        { x = 10, y = 0, z = 0 },
        2
    )
    lu.assertAlmostEquals(t, 8, 1e-6)
    lu.assertAlmostEquals(d, 0, 1e-6)
end

function TestCPA:testCPAToPolygon_square()
    local square = { { x = 10, z = -1 }, { x = 12, z = -1 }, { x = 12, z = 1 }, { x = 10, z = 1 } }
    local t, d = EstimateCPAToPolygon({ x = 0, y = 0, z = 0 }, { x = 1, y = 0, z = 0 }, square)
    lu.assertTrue(t >= 8 and t <= 12)
    lu.assertAlmostEquals(d, 0, 1e-6)
end

return TestCPA
