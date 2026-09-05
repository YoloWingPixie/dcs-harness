-- Unit tests for vector.lua module
local lu = require("luaunit")

TestVector = {}

-- Test Vec3 creation
function TestVector:testVec3Creation()
    local v1 = Vec3(1, 2, 3)
    lu.assertEquals(v1.x, 1)
    lu.assertEquals(v1.y, 2)
    lu.assertEquals(v1.z, 3)

    -- Test default values
    local v2 = Vec3()
    lu.assertEquals(v2.x, 0)
    lu.assertEquals(v2.y, 0)
    lu.assertEquals(v2.z, 0)

    -- Test partial values
    local v3 = Vec3(5)
    lu.assertEquals(v3.x, 5)
    lu.assertEquals(v3.y, 0)
    lu.assertEquals(v3.z, 0)
end

-- Test Vec2 creation
function TestVector:testVec2Creation()
    local v1 = Vec2(4, 5)
    lu.assertEquals(v1.x, 4)
    lu.assertEquals(v1.y, 5)
    lu.assertNil(v1.z)

    -- Test default values
    local v2 = Vec2()
    lu.assertEquals(v2.x, 0)
    lu.assertEquals(v2.y, 0)
    lu.assertNil(v2.z)
end

-- Test IsVec3 validation
function TestVector:testIsVec3()
    lu.assertTrue(IsVec3(Vec3(1, 2, 3)))
    lu.assertTrue(IsVec3({ x = 1, y = 2, z = 3 }))

    lu.assertFalse(IsVec3(nil))
    lu.assertFalse(IsVec3("string"))
    lu.assertFalse(IsVec3(123))
    lu.assertFalse(IsVec3({ x = 1, y = 2 })) -- missing z
    lu.assertFalse(IsVec3({ x = 1, y = 2, z = "not a number" }))
end

-- Test IsVec2 validation
function TestVector:testIsVec2()
    lu.assertTrue(IsVec2(Vec2(1, 2)))
    lu.assertTrue(IsVec2({ x = 1, y = 2 }))
    lu.assertFalse(IsVec2({ x = 1, z = 2 }))
    lu.assertFalse(IsVec2({ x = 1, y = 2, z = 3 }))

    lu.assertFalse(IsVec2(nil))
    lu.assertFalse(IsVec2("string"))
    lu.assertFalse(IsVec2({ x = 1 })) -- missing y
    lu.assertFalse(IsVec2({ x = "not a number", y = 2 }))
end

function TestVector:testIsFiniteVec2()
    lu.assertTrue(IsFiniteVec2(Vec2()))
    lu.assertTrue(IsFiniteVec2({ x = -1.25, y = 2.5 }))
    lu.assertTrue(IsFiniteVec2({ x = 1e308, y = -1e308 }))

    lu.assertFalse(IsFiniteVec2(nil))
    lu.assertFalse(IsFiniteVec2(false))
    lu.assertFalse(IsFiniteVec2("string"))
    lu.assertFalse(IsFiniteVec2(123))
    lu.assertFalse(IsFiniteVec2({}))
    lu.assertFalse(IsFiniteVec2({ 1, 2 }))
    lu.assertFalse(IsFiniteVec2({ x = 1 }))
    lu.assertFalse(IsFiniteVec2({ y = 2 }))
    lu.assertFalse(IsFiniteVec2({ x = "1", y = 2 }))
    lu.assertFalse(IsFiniteVec2({ x = 1, y = "2" }))
    lu.assertFalse(IsFiniteVec2({ x = 1, z = 2 }))
    lu.assertFalse(IsFiniteVec2(Vec3(1, 2, 3)))
    lu.assertFalse(IsFiniteVec2({ x = 1, y = 2, z = false }))
end

function TestVector:testIsFiniteVec3()
    lu.assertTrue(IsFiniteVec3(Vec3()))
    lu.assertTrue(IsFiniteVec3({ x = -1.25, y = 2.5, z = -3.75 }))
    lu.assertTrue(IsFiniteVec3({ x = 1e308, y = -1e308, z = 1e308 }))

    lu.assertFalse(IsFiniteVec3(nil))
    lu.assertFalse(IsFiniteVec3(false))
    lu.assertFalse(IsFiniteVec3("string"))
    lu.assertFalse(IsFiniteVec3(123))
    lu.assertFalse(IsFiniteVec3({}))
    lu.assertFalse(IsFiniteVec3({ 1, 2, 3 }))
    lu.assertFalse(IsFiniteVec3({ y = 2, z = 3 }))
    lu.assertFalse(IsFiniteVec3({ x = 1, z = 3 }))
    lu.assertFalse(IsFiniteVec3(Vec2(1, 2)))
    lu.assertFalse(IsFiniteVec3({ x = "1", y = 2, z = 3 }))
    lu.assertFalse(IsFiniteVec3({ x = 1, y = "2", z = 3 }))
    lu.assertFalse(IsFiniteVec3({ x = 1, y = 2, z = "3" }))
end

function TestVector:testFiniteValidationRejectsNonFiniteCoordinatesWithoutChangingTypeChecks()
    for _, value in ipairs({ 0 / 0, math.huge, -math.huge }) do
        for _, coordinate in ipairs({ "x", "y" }) do
            local vec = { x = 1, y = 2 }
            vec[coordinate] = value
            lu.assertTrue(IsVec2(vec), coordinate)
            lu.assertFalse(IsFiniteVec2(vec), coordinate)
        end
        for _, coordinate in ipairs({ "x", "y", "z" }) do
            local vec = { x = 1, y = 2, z = 3 }
            vec[coordinate] = value
            lu.assertTrue(IsVec3(vec), coordinate)
            lu.assertFalse(IsFiniteVec3(vec), coordinate)
        end
    end
end

-- Test Vec2 to Vec3 conversion
function TestVector:testToVec3()
    local v2 = Vec2(10, 20)
    local v3 = ToVec3(v2, 50)

    lu.assertEquals(v3.x, 10)
    lu.assertEquals(v3.y, 50)
    lu.assertEquals(v3.z, 20) -- Vec2.y becomes Vec3.z

    -- Test default altitude
    local v3_default = ToVec3(v2)
    lu.assertEquals(v3_default.y, 0)
end

-- Test Vec3 to Vec2 conversion
function TestVector:testToVec2()
    local v3 = Vec3(10, 50, 20)
    local v2 = ToVec2(v3)

    lu.assertEquals(v2.x, 10)
    lu.assertEquals(v2.y, 20) -- Vec3.z becomes Vec2.y
    lu.assertNil(v2.z)
    lu.assertEquals(ToVec2({ x = 10, y = 20 }), Vec2(10, 20))
    lu.assertNil(ToVec2({ x = 10, z = 20 }))
    lu.assertNil(ToVec2({}))
end

-- Test vector addition
function TestVector:testVecAdd()
    local v1 = Vec3(1, 2, 3)
    local v2 = Vec3(4, 5, 6)
    local result = VecAdd(v1, v2)

    lu.assertEquals(result.x, 5)
    lu.assertEquals(result.y, 7)
    lu.assertEquals(result.z, 9)
end

-- Test vector subtraction
function TestVector:testVecSub()
    local v1 = Vec3(10, 20, 30)
    local v2 = Vec3(1, 2, 3)
    local result = VecSub(v1, v2)

    lu.assertEquals(result.x, 9)
    lu.assertEquals(result.y, 18)
    lu.assertEquals(result.z, 27)
end

-- Test vector scaling
function TestVector:testVecScale()
    local v = Vec3(2, 3, 4)
    local result = VecScale(v, 2.5)

    lu.assertEquals(result.x, 5)
    lu.assertEquals(result.y, 7.5)
    lu.assertEquals(result.z, 10)
end

-- Test vector division
function TestVector:testVecDiv()
    local v = Vec3(10, 20, 30)
    local result = VecDiv(v, 2)

    lu.assertEquals(result.x, 5)
    lu.assertEquals(result.y, 10)
    lu.assertEquals(result.z, 15)

    -- Test division by zero protection
    local zero_result = VecDiv(v, 0)
    lu.assertNotNil(zero_result, "VecDiv should return a vector, not nil")
    lu.assertNotNil(zero_result.x, "zero_result.x should not be nil")
    lu.assertNotNil(zero_result.y, "zero_result.y should not be nil")
    lu.assertNotNil(zero_result.z, "zero_result.z should not be nil")
    lu.assertEquals(zero_result.x, 0)
    lu.assertEquals(zero_result.y, 0)
    lu.assertEquals(zero_result.z, 0)
end

-- Test vector length
function TestVector:testVecLength()
    local v = Vec3(3, 4, 0)
    lu.assertEquals(VecLength(v), 5) -- 3-4-5 triangle

    local v2 = Vec3(1, 1, 1)
    lu.assertAlmostEquals(VecLength(v2), math.sqrt(3), 0.0001)
end

-- Test 2D vector length
function TestVector:testVecLength2D()
    local v = Vec3(3, 100, 4) -- y is ignored
    lu.assertEquals(VecLength2D(v), 5) -- 3-4-5 triangle in XZ plane
end

-- Test vector normalization
function TestVector:testVecNormalize()
    local v = Vec3(3, 4, 0)
    local norm = VecNormalize(v)

    lu.assertAlmostEquals(VecLength(norm), 1.0, 0.0001)
    lu.assertAlmostEquals(norm.x, 0.6, 0.0001)
    lu.assertAlmostEquals(norm.y, 0.8, 0.0001)
    lu.assertAlmostEquals(norm.z, 0.0, 0.0001)

    -- Test zero vector
    local zero_norm = VecNormalize(Vec3(0, 0, 0))
    lu.assertNotNil(zero_norm, "VecNormalize should return a vector, not nil")
    lu.assertNotNil(zero_norm.x, "zero_norm.x should not be nil")
    lu.assertNotNil(zero_norm.y, "zero_norm.y should not be nil")
    lu.assertNotNil(zero_norm.z, "zero_norm.z should not be nil")
    lu.assertEquals(zero_norm.x, 0)
    lu.assertEquals(zero_norm.y, 0)
    lu.assertEquals(zero_norm.z, 0)
end

-- Test 2D vector normalization
function TestVector:testVecNormalize2D()
    local v = Vec3(3, 100, 4)
    local norm = VecNormalize2D(v)

    lu.assertAlmostEquals(VecLength2D(norm), 1.0, 0.0001)
    lu.assertEquals(norm.y, 100) -- y preserved
end

-- Test dot product
function TestVector:testVecDot()
    local v1 = Vec3(1, 2, 3)
    local v2 = Vec3(4, 5, 6)
    local dot = VecDot(v1, v2)

    lu.assertEquals(dot, 32) -- 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32

    -- Test perpendicular vectors
    local v3 = Vec3(1, 0, 0)
    local v4 = Vec3(0, 1, 0)
    lu.assertEquals(VecDot(v3, v4), 0)
end

-- Test cross product
function TestVector:testVecCross()
    local v1 = Vec3(1, 0, 0)
    local v2 = Vec3(0, 1, 0)
    local cross = VecCross(v1, v2)

    lu.assertEquals(cross.x, 0)
    lu.assertEquals(cross.y, 0)
    lu.assertEquals(cross.z, 1) -- i × j = k

    -- Test anticommutative property
    local cross2 = VecCross(v2, v1)
    lu.assertEquals(cross2.z, -1)
end

-- Test distance calculation
function TestVector:testDistance()
    local v1 = Vec3(0, 0, 0)
    local v2 = Vec3(3, 4, 0)

    lu.assertEquals(Distance(v1, v2), 5)

    local v3 = Vec3(1, 1, 1)
    local v4 = Vec3(2, 2, 2)
    lu.assertAlmostEquals(Distance(v3, v4), math.sqrt(3), 0.0001)
end

-- Test 2D distance calculation
function TestVector:testDistance2D()
    local v1 = Vec3(0, 100, 0)
    local v2 = Vec3(3, 200, 4)

    lu.assertEquals(Distance2D(v1, v2), 5) -- ignores y
end

-- Test squared distances (optimization)
function TestVector:testDistanceSquared()
    local v1 = Vec3(0, 0, 0)
    local v2 = Vec3(3, 0, 4) -- x=3, z=4 for 2D distance

    lu.assertEquals(DistanceSquared(v1, v2), 25) -- 3² + 0² + 4² = 25
    lu.assertEquals(Distance2DSquared(v1, v2), 25) -- 3² + 4² = 25
end

-- Test bearing calculation
function TestVector:testBearing()
    local from = Vec3(0, 0, 0)

    -- North (0°)
    local to_north = Vec3(10, 0, 0)
    lu.assertAlmostEquals(Bearing(from, to_north), 0, 0.0001)

    -- East (90°)
    local to_east = Vec3(0, 0, 10)
    lu.assertAlmostEquals(Bearing(from, to_east), 90, 0.0001)

    -- South (180°)
    local to_south = Vec3(-10, 0, 0)
    lu.assertAlmostEquals(Bearing(from, to_south), 180, 0.0001)

    -- West (270°)
    local to_west = Vec3(0, 0, -10)
    lu.assertAlmostEquals(Bearing(from, to_west), 270, 0.0001)
end

-- Test position from bearing and distance
function TestVector:testFromBearingDistance()
    local origin = Vec3(100, 50, 200)

    -- North
    local north = FromBearingDistance(origin, 0, 100)
    lu.assertAlmostEquals(north.x, 200, 0.0001)
    lu.assertEquals(north.y, 50) -- altitude preserved
    lu.assertAlmostEquals(north.z, 200, 0.0001)

    -- East
    local east = FromBearingDistance(origin, 90, 100)
    lu.assertAlmostEquals(east.x, 100, 0.0001)
    lu.assertEquals(east.y, 50)
    lu.assertAlmostEquals(east.z, 300, 0.0001)

    local diagonal = FromBearingDistance(origin, 45, 100)
    lu.assertAlmostEquals(Bearing(origin, diagonal), 45, 0.0001)
    lu.assertAlmostEquals(Distance2D(origin, diagonal), 100, 0.0001)

    local groundEast = FromBearingDistance(Vec2(100, 200), 90, 100)
    lu.assertAlmostEquals(groundEast.x, 100, 0.0001)
    lu.assertAlmostEquals(groundEast.y, 300, 0.0001)
    lu.assertNil(groundEast.z)
end

function TestVector:testBearingAndDisplacementRoundTrip()
    local origin3 = Vec3(100, 50, 200)
    local origin2 = Vec2(100, 200)
    for _, heading in ipairs({ 0, 45, 90, 180, 270 }) do
        local point3 = FromBearingDistance(origin3, heading, 100)
        lu.assertAlmostEquals(Bearing(origin3, point3), heading, 0.0001)
        lu.assertAlmostEquals(Distance2D(origin3, point3), 100, 0.0001)

        local point2 = FromBearingDistance(origin2, heading, 100)
        lu.assertAlmostEquals(Bearing(origin2, point2), heading, 0.0001)
        lu.assertAlmostEquals(Distance2D(origin2, point2), 100, 0.0001)
    end
end

function TestVector:testVec2OperationsUseDcsFields()
    local first = Vec2(3, 4)
    local second = Vec2(1, 2)

    lu.assertEquals(first + second, Vec2(4, 6))
    lu.assertEquals(first - second, Vec2(2, 2))
    lu.assertEquals(first * 2, Vec2(6, 8))
    lu.assertEquals(first:dot(second), 11)
    lu.assertEquals(first:length(), 5)
    lu.assertEquals(first:toVec3(10), Vec3(3, 10, 4))
    lu.assertNil((first + second).z)
end

-- Test angle between vectors
function TestVector:testAngleBetween()
    -- Same direction
    local v1 = Vec3(1, 0, 0)
    local v2 = Vec3(2, 0, 0)
    lu.assertAlmostEquals(AngleBetween(v1, v2), 0, 0.0001)

    -- Perpendicular
    local v3 = Vec3(1, 0, 0)
    local v4 = Vec3(0, 1, 0)
    lu.assertAlmostEquals(AngleBetween(v3, v4), 90, 0.0001)

    -- Opposite
    local v5 = Vec3(1, 0, 0)
    local v6 = Vec3(-1, 0, 0)
    lu.assertAlmostEquals(AngleBetween(v5, v6), 180, 0.0001)
end

-- Test midpoint calculation
function TestVector:testMidpoint()
    local v1 = Vec3(0, 0, 0)
    local v2 = Vec3(10, 20, 30)
    local mid = Midpoint(v1, v2)

    lu.assertEquals(mid.x, 5)
    lu.assertEquals(mid.y, 10)
    lu.assertEquals(mid.z, 15)
end

-- Test linear interpolation
function TestVector:testVecLerp()
    local v1 = Vec3(0, 0, 0)
    local v2 = Vec3(10, 20, 30)

    -- t = 0 (start)
    local lerp0 = VecLerp(v1, v2, 0)
    lu.assertEquals(lerp0.x, 0)
    lu.assertEquals(lerp0.y, 0)
    lu.assertEquals(lerp0.z, 0)

    -- t = 0.5 (middle)
    local lerp05 = VecLerp(v1, v2, 0.5)
    lu.assertEquals(lerp05.x, 5)
    lu.assertEquals(lerp05.y, 10)
    lu.assertEquals(lerp05.z, 15)

    -- t = 1 (end)
    local lerp1 = VecLerp(v1, v2, 1)
    lu.assertEquals(lerp1.x, 10)
    lu.assertEquals(lerp1.y, 20)
    lu.assertEquals(lerp1.z, 30)
end

-- Test vector to string conversion
function TestVector:testVec3ToString()
    local v = Vec3(1.234, 5.678, 9.012)

    -- Default precision (2)
    local str1 = Vec3ToString(v)
    lu.assertEquals(str1, "(1.23, 5.68, 9.01)")

    -- Custom precision
    local str2 = Vec3ToString(v, 1)
    lu.assertEquals(str2, "(1.2, 5.7, 9.0)")

    local str3 = Vec3ToString(v, 3)
    lu.assertEquals(str3, "(1.234, 5.678, 9.012)")

    -- Invalid vector
    lu.assertEquals(Vec3ToString(nil), "(invalid)")
end

-- Test Vec2 to string conversion
function TestVector:testVec2ToString()
    local v = Vec2(3.456, 7.890)

    -- Default precision (2)
    local str1 = Vec2ToString(v)
    lu.assertEquals(str1, "(3.46, 7.89)")

    -- Custom precision
    local str2 = Vec2ToString(v, 0)
    lu.assertEquals(str2, "(3, 8)")

    -- Invalid vector
    lu.assertEquals(Vec2ToString("not a vec2"), "(invalid)")
end

return TestVector
