local lu = require("luaunit")

TestVectorOps = {}

function TestVectorOps:testLineSegmentIntersectionUsesDcsVec2()
    local intersection =
        LineSegmentIntersection2D(Vec2(0, 0), Vec2(10, 10), Vec2(0, 10), Vec2(10, 0))

    lu.assertNotNil(intersection)
    lu.assertAlmostEquals(intersection.x, 5, 1e-9)
    lu.assertAlmostEquals(intersection.y, 5, 1e-9)
    lu.assertNil(intersection.z)
end

function TestVectorOps:testPolygonOperationsPreserveDcsVec2()
    local polygon = {
        Vec2(0, 0),
        Vec2(10, 0),
        Vec2(10, 10),
        Vec2(0, 10),
    }

    local offset = OffsetPolygon(polygon, 1)
    lu.assertEquals(#offset, 4)
    for _, point in ipairs(offset) do
        lu.assertTrue(IsVec2(point))
        lu.assertNil(point.z)
    end

    lu.assertTrue(PointInTriangle2D(Vec2(2, 2), polygon[1], polygon[2], polygon[4]))
end

return TestVectorOps
