-- Unit tests for geomath.lua module (pure functions)
local lu = require("luaunit")

TestGeoMath = {}

function TestGeoMath:testDegRadConversions()
    local a = DegToRad(0)
    lu.assertNotNil(a)
    lu.assertAlmostEquals(a, 0, 1e-6)
    local b = DegToRad(180)
    lu.assertNotNil(b)
    lu.assertAlmostEquals(b, math.pi, 1e-6)
    local c = RadToDeg(0)
    lu.assertNotNil(c)
    lu.assertAlmostEquals(c, 0, 1e-6)
    local d = RadToDeg(math.pi)
    lu.assertNotNil(d)
    lu.assertAlmostEquals(d, 180, 1e-6)
end

function TestGeoMath:testNMeters()
    local m = NauticalMilesToMeters(1)
    lu.assertNotNil(m)
    lu.assertEquals(m, 1852)
    local nm = MetersToNauticalMiles(1852)
    lu.assertNotNil(nm)
    lu.assertAlmostEquals(nm, 1, 1e-9)
end

function TestGeoMath:testFeetMeters()
    local m = FeetToMeters(1000)
    lu.assertNotNil(m)
    lu.assertAlmostEquals(m, 304.8, 1e-6)
    local f = MetersToFeet(304.8)
    lu.assertNotNil(f)
    lu.assertAlmostEquals(f, 1000, 1e-6)
end

function TestGeoMath:testDistance2D3D()
    local d2 = Distance2D({ x = 0, y = 0, z = 0 }, { x = 3, y = 0, z = 4 })
    lu.assertNotNil(d2)
    lu.assertAlmostEquals(d2, 5, 1e-6)
    local d3 = Distance3D({ x = 0, y = 0, z = 0 }, { x = 1, y = 2, z = 2 })
    lu.assertNotNil(d3)
    lu.assertAlmostEquals(d3, 3, 1e-6)
end

function TestGeoMath:testBearingBetween()
    local bN = BearingBetween({ x = 0, y = 0, z = 0 }, { x = 10, y = 0, z = 0 })
    lu.assertNotNil(bN)
    lu.assertAlmostEquals(bN, 0, 1e-6)
    local bE = BearingBetween({ x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 10 })
    lu.assertNotNil(bE)
    lu.assertAlmostEquals(bE, 90, 1e-6)
    local bS = BearingBetween({ x = 0, y = 0, z = 0 }, { x = -10, y = 0, z = 0 })
    lu.assertNotNil(bS)
    lu.assertAlmostEquals(bS, 180, 1e-6)
    local bW = BearingBetween({ x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = -10 })
    lu.assertNotNil(bW)
    lu.assertAlmostEquals(bW, 270, 1e-6)
end

function TestGeoMath:testDisplacePoint2D()
    local p = { x = 100, y = 50, z = 200 }
    local north = DisplacePoint2D(p, 0, 100)
    lu.assertNotNil(north)
    lu.assertAlmostEquals(north.x, 200, 1e-6)
    lu.assertEquals(north.y, 50)
    lu.assertAlmostEquals(north.z, 200, 1e-6)

    local east = DisplacePoint2D(p, 90, 100)
    lu.assertNotNil(east)
    lu.assertAlmostEquals(east.x, 100, 1e-6)
    lu.assertEquals(east.y, 50)
    lu.assertAlmostEquals(east.z, 300, 1e-6)
end

function TestGeoMath:testHeadingAndProjection()
    lu.assertEquals(HeadingVector2D(0), Vec2(1, 0))
    local east = HeadingVector2D(90)
    lu.assertAlmostEquals(east.x, 0, 1e-9)
    lu.assertAlmostEquals(east.y, 1, 1e-9)
    lu.assertNil(east.z)
    lu.assertEquals(GroundTrackFromVelocity({ x = 20, y = 0, z = 0 }), 0)
    lu.assertEquals(GroundTrackFromVelocity({ x = 0, y = 0, z = 20 }), 90)
    lu.assertNil(GroundTrackFromVelocity({ x = 10, y = 0, z = 0 }))

    local frame = HeadingFrame2D(Vec3(100, 20, 200), 0)
    local along, lateral = ProjectPointToHeadingFrame2D(frame, Vec3(125, 20, 210))
    lu.assertAlmostEquals(along, 25, 1e-9)
    lu.assertAlmostEquals(lateral, 10, 1e-9)
    local forward, right = ProjectVectorToHeadingFrame2D(frame, { x = 5, y = 2, z = -3 })
    lu.assertAlmostEquals(forward, 5, 1e-9)
    lu.assertAlmostEquals(right, -3, 1e-9)
end

function TestGeoMath:testMidpoint()
    local mid = MidPoint({ x = 0, y = 0, z = 0 }, { x = 10, y = 20, z = 30 })
    lu.assertNotNil(mid)
    lu.assertEquals(mid.x, 5)
    lu.assertEquals(mid.y, 10)
    lu.assertEquals(mid.z, 15)
end

function TestGeoMath:testRotatePoint2D()
    local p = { x = 100, y = 50, z = 0 }
    local r = RotatePoint2D(p, { x = 0, y = 0, z = 0 }, 90)
    lu.assertNotNil(r)
    -- Rotating (100,0) around origin 90° clockwise yields (0,100)
    lu.assertAlmostEquals(r.x, 0, 1e-6)
    lu.assertEquals(r.y, 50)
    lu.assertAlmostEquals(r.z, 100, 1e-6)
end

function TestGeoMath:testNormalizeVectors()
    local n2 = NormalizeVector2D(Vec2(3, 4))
    lu.assertNotNil(n2)
    lu.assertAlmostEquals(math.sqrt(n2.x * n2.x + n2.y * n2.y), 1.0, 1e-6)
    lu.assertNil(n2.z)

    local n3 = NormalizeVector3D({ x = 2, y = 2, z = 1 })
    lu.assertNotNil(n3)
    lu.assertAlmostEquals(math.sqrt(n3.x * n3.x + n3.y * n3.y + n3.z * n3.z), 1.0, 1e-6)
end

function TestGeoMath:testDotCross()
    local d2 = DotProduct2D(Vec2(1, 0), Vec2(0, 1))
    lu.assertNotNil(d2)
    lu.assertEquals(d2, 0)
    local d3 = DotProduct3D({ x = 1, y = 0, z = 0 }, { x = 0, y = 1, z = 0 })
    lu.assertNotNil(d3)
    lu.assertEquals(d3, 0)

    local c = CrossProduct3D({ x = 1, y = 0, z = 0 }, { x = 0, y = 1, z = 0 })
    lu.assertNotNil(c)
    lu.assertEquals(c.x, 0)
    lu.assertEquals(c.y, 0)
    lu.assertEquals(c.z, 1)
end

function TestGeoMath:testAngleBetweenVectors2D()
    local a = AngleBetweenVectors2D(Vec2(1, 0), Vec2(0, 1))
    lu.assertNotNil(a)
    lu.assertAlmostEquals(a, 90, 1e-6)
    local b = AngleBetweenVectors2D(Vec2(1, 0), Vec2(-1, 0))
    lu.assertNotNil(b)
    lu.assertAlmostEquals(b, 180, 1e-6)
end

function TestGeoMath:testPointInPolygon2D()
    local tri = { Vec2(0, 0), Vec2(10, 0), Vec2(0, 10) }
    local inside = PointInPolygon2D(Vec2(1, 1), tri)
    lu.assertNotNil(inside)
    lu.assertTrue(inside)
    local outside = PointInPolygon2D(Vec2(11, 1), tri)
    lu.assertNotNil(outside)
    lu.assertFalse(outside)
end

function TestGeoMath:testCircleLineIntersection2D()
    local hits = CircleLineIntersection2D(Vec2(0, 0), 5, Vec2(-10, 0), Vec2(10, 0))
    lu.assertNotNil(hits)
    lu.assertEquals(#hits, 2)
    lu.assertTrue(IsVec2(hits[1]))
    lu.assertNil(hits[1].z)
end

function TestGeoMath:testPolygonAreaCentroid2D()
    local square = {
        Vec2(0, 0),
        Vec2(2, 0),
        Vec2(2, 2),
        Vec2(0, 2),
    }
    local area = PolygonArea2D(square)
    lu.assertNotNil(area)
    lu.assertAlmostEquals(area, 4, 1e-6)
    local c = PolygonCentroid2D(square)
    lu.assertNotNil(c)
    lu.assertAlmostEquals(c.x, 1, 1e-6)
    lu.assertAlmostEquals(c.y, 1, 1e-6)
    lu.assertNil(c.z)
end

function TestGeoMath:testConvexHull2D()
    local pts = {
        Vec2(0, 0),
        Vec2(2, 0),
        Vec2(2, 2),
        Vec2(0, 2),
        Vec2(1, 1),
    }
    local hull = ConvexHull2D(pts)
    lu.assertNotNil(hull)
    lu.assertTrue(#hull >= 4)
end

return TestGeoMath
