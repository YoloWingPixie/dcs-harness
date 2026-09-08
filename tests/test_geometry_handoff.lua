local lu = require("luaunit")

TestCPA3D = {}

function TestCPA3D:testApproachVerticalMissAndPast()
    local cases = {
        { { x = 10, y = 0, z = 0 }, { x = -2, y = 0, z = 0 }, 5, 0 },
        { { x = 0, y = 10, z = 0 }, { x = 0, y = -2, z = 0 }, 5, 0 },
        { { x = 10, y = 3, z = 4 }, { x = -2, y = 0, z = 0 }, 5, 5 },
        { { x = 3, y = 4, z = 0 }, { x = 2, y = 0, z = 0 }, 0, 5 },
    }
    for _, case in ipairs(cases) do
        local seconds, distance = EstimateCPAToPoint3D(case[1], case[2], Vec3())
        lu.assertAlmostEquals(seconds, case[3], 1e-12)
        lu.assertAlmostEquals(distance, case[4], 1e-12)
    end
end

function TestCPA3D:testStationaryThresholdAndInputIsolation()
    local position, target = Vec3(1, 0, 0), Vec3()
    for _, speed in ipairs({ 0, 0.000999999 }) do
        local seconds, distance = EstimateCPAToPoint3D(position, Vec3(-speed, 0, 0), target)
        lu.assertEquals({ seconds, distance }, { 0, 1 })
    end
    local velocity = Vec3(-0.001, 0, 0)
    local seconds, distance = EstimateCPAToPoint3D(position, velocity, target)
    lu.assertAlmostEquals(seconds, 1000, 1e-9)
    lu.assertAlmostEquals(distance, 0, 1e-12)
    lu.assertEquals(position, Vec3(1, 0, 0))
    lu.assertEquals(velocity, Vec3(-0.001, 0, 0))
    lu.assertEquals(target, Vec3())
end

function TestCPA3D:testInvalidAndOverflowingCalculations()
    lu.assertNil(EstimateCPAToPoint3D(nil, Vec3(), Vec3()))
    for _, bad in ipairs({
        {},
        false,
        { x = 1, y = 2 },
        { x = "1", y = 2, z = 3 },
        Vec3(math.huge, 0, 0),
        Vec3(0, 0 / 0, 0),
        Vec3(0, 0, -math.huge),
    }) do
        for i = 1, 3 do
            local inputs = { Vec3(), Vec3(), Vec3() }
            inputs[i] = bad
            local seconds, distance = EstimateCPAToPoint3D(unpack(inputs))
            lu.assertNil(seconds)
            lu.assertNil(distance)
        end
    end
    local seconds, distance =
        EstimateCPAToPoint3D(Vec3(1e308, 0, 0), Vec3(1e308, 0, 0), Vec3(-1e308, 0, 0))
    lu.assertNil(seconds)
    lu.assertNil(distance)
end

TestCircleCoveredArea = {}

local function coverageCircle(x, y, radius)
    return { center = { x = x, y = y }, radius = radius }
end

function TestCircleCoveredArea:testAnalyticOverlapAndTranslations()
    local expected = 2 * math.pi / 3 - math.sqrt(3) / 2
    for _, offset in ipairs({ 0, 1e6, -1e6 }) do
        local envelope = coverageCircle(offset, offset, 1)
        local provider = coverageCircle(offset + 1, offset, 1)
        lu.assertAlmostEquals(CircleCoveredArea2D(envelope, { provider }), expected, 1e-9 * math.pi)
        lu.assertAlmostEquals(
            CircleCoveredArea2D(envelope, { provider, provider }),
            expected,
            1e-9 * math.pi
        )
        lu.assertEquals(envelope, coverageCircle(offset, offset, 1))
        lu.assertEquals(provider, coverageCircle(offset + 1, offset, 1))
    end
end

function TestCircleCoveredArea:testEmptyDisjointTangentAndContainment()
    local envelope = coverageCircle(0, 0, 1)
    lu.assertEquals(CircleCoveredArea2D(envelope, {}), 0)
    lu.assertEquals(CircleCoveredArea2D(envelope, { coverageCircle(3, 0, 1) }), 0)
    lu.assertEquals(CircleCoveredArea2D(envelope, { coverageCircle(2, 0, 1) }), 0)
    lu.assertAlmostEquals(
        CircleCoveredArea2D(envelope, { coverageCircle(0, 0, 1 / math.sqrt(2)) }),
        math.pi / 2,
        1e-9 * math.pi
    )
    lu.assertAlmostEquals(CircleCoveredArea2D(envelope, { envelope }), math.pi, 1e-9 * math.pi)
    lu.assertAlmostEquals(
        CircleCoveredArea2D(envelope, { coverageCircle(0, 0, 1e150) }),
        math.pi,
        1e-9 * math.pi
    )
    lu.assertAlmostEquals(
        CircleCoveredArea2D(
            coverageCircle(0, 0, 4),
            { coverageCircle(-2, 0, 1), coverageCircle(2, 0, 1) }
        ),
        2 * math.pi,
        1e-9 * math.pi * 16
    )
    lu.assertAlmostEquals(
        CircleCoveredArea2D(
            coverageCircle(0, 0, 4),
            { coverageCircle(0, 0, 1), coverageCircle(1, 0, 1) }
        ),
        2 * math.pi - (2 * math.pi / 3 - math.sqrt(3) / 2),
        1e-9 * math.pi * 16
    )
end

function TestCircleCoveredArea:testInvalidGeometryAndOverflow()
    local valid = coverageCircle(0, 0, 1)
    lu.assertNil(CircleCoveredArea2D(nil, {}))
    lu.assertNil(CircleCoveredArea2D(valid, nil))
    lu.assertNil(CircleCoveredArea2D(valid, { [1] = valid, [3] = valid }))
    for _, invalid in ipairs({
        {},
        false,
        coverageCircle(0, 0, 0),
        coverageCircle(0, 0, -1),
        coverageCircle(0 / 0, 0, 1),
        coverageCircle(math.huge, 0, 1),
        coverageCircle(0, -math.huge, 1),
        coverageCircle(0, 0, math.huge),
        { center = Vec3(), radius = 1 },
    }) do
        lu.assertNil(CircleCoveredArea2D(invalid, {}))
        lu.assertNil(CircleCoveredArea2D(valid, { invalid }))
    end
    lu.assertNil(CircleCoveredArea2D(coverageCircle(0, 0, 1e308), { valid }))
end
