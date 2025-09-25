--[[
    VectorOps Module - Vector Operations and Shape Merging
    
    This module provides vector operations similar to Adobe Illustrator,
    including union, intersection, difference, and shape merging operations.
    All shapes are represented as arrays of Vec2/Vec3 points.
]]

require("logger")
require("geomath")

--- Finds intersection point of two 2D line segments
--- @param p1 table First point of first line segment {x, z}
--- @param p2 table Second point of first line segment {x, z}
--- @param p3 table First point of second line segment {x, z}
--- @param p4 table Second point of second line segment {x, z}
--- @return table|nil intersection Point of intersection {x, y, z} or nil if no intersection
--- @usage local pt = LineSegmentIntersection2D({x=0,z=0}, {x=10,z=10}, {x=0,z=10}, {x=10,z=0})
function LineSegmentIntersection2D(p1, p2, p3, p4)
    if not p1 or not p2 or not p3 or not p4 then
        _HarnessInternal.log.error("LineSegmentIntersection2D requires four valid points", "VectorOps.LineSegmentIntersection2D")
        return nil
    end
    
    local x1, y1 = p1.x, p1.z
    local x2, y2 = p2.x, p2.z
    local x3, y3 = p3.x, p3.z
    local x4, y4 = p4.x, p4.z
    
    local denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    
    if math.abs(denom) < 1e-10 then
        return nil -- Lines are parallel
    end
    
    local t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
    local u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom
    
    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        return {
            x = x1 + t * (x2 - x1),
            y = p1.y or 0,
            z = y1 + t * (y2 - y1)
        }
    end
    
    return nil
end

--- Finds all intersection points between two polygons
--- @param poly1 table Array of points defining first polygon
--- @param poly2 table Array of points defining second polygon
--- @return table intersections Array of intersection data with point and edge info
--- @usage local intersections = FindPolygonIntersections(shape1, shape2)
function FindPolygonIntersections(poly1, poly2)
    if not poly1 or not poly2 or type(poly1) ~= "table" or type(poly2) ~= "table" then
        _HarnessInternal.log.error("FindPolygonIntersections requires two valid polygons", "VectorOps.FindPolygonIntersections")
        return {}
    end
    
    local intersections = {}
    
    -- Check each edge of poly1 against each edge of poly2
    for i = 1, #poly1 do
        local p1 = poly1[i]
        local p2 = poly1[(i % #poly1) + 1]
        
        for j = 1, #poly2 do
            local p3 = poly2[j]
            local p4 = poly2[(j % #poly2) + 1]
            
            local intersection = LineSegmentIntersection2D(p1, p2, p3, p4)
            if intersection then
                table.insert(intersections, {
                    point = intersection,
                    edge1 = {i, (i % #poly1) + 1},
                    edge2 = {j, (j % #poly2) + 1}
                })
            end
        end
    end
    
    return intersections
end

--- Merges two polygons with option to keep interior points
--- @param poly1 table Array of points defining first polygon
--- @param poly2 table Array of points defining second polygon
--- @param keepInterior boolean? Whether to keep interior points (default: false)
--- @return table|nil merged Merged polygon points or nil on error
--- @usage local merged = MergePolygons(shape1, shape2, false)
function MergePolygons(poly1, poly2, keepInterior)
    if not poly1 or not poly2 or type(poly1) ~= "table" or type(poly2) ~= "table" then
        _HarnessInternal.log.error("MergePolygons requires two valid polygons", "VectorOps.MergePolygons")
        return nil
    end
    
    -- If keepInterior is false, we want to remove interior points (union operation)
    -- If keepInterior is true, we keep all points
    
    local merged = {}
    local used = {}
    
    -- First, find all intersection points
    local intersections = FindPolygonIntersections(poly1, poly2)
    
    -- Add all vertices from poly1 that are outside poly2 (for union)
    for i, point in ipairs(poly1) do
        if keepInterior or not PointInPolygon2D(point, poly2) then
            table.insert(merged, point)
            used[point] = true
        end
    end
    
    -- Add all vertices from poly2 that are outside poly1 (for union)
    for i, point in ipairs(poly2) do
        if not used[point] and (keepInterior or not PointInPolygon2D(point, poly1)) then
            table.insert(merged, point)
        end
    end
    
    -- Add intersection points
    for _, intersection in ipairs(intersections) do
        table.insert(merged, intersection.point)
    end
    
    -- Sort points by angle from centroid to create proper polygon
    if #merged > 2 then
        local centroid = PolygonCentroid2D(merged)
        table.sort(merged, function(a, b)
            local angle_a = math.atan2(a.z - centroid.z, a.x - centroid.x)
            local angle_b = math.atan2(b.z - centroid.z, b.x - centroid.x)
            return angle_a < angle_b
        end)
    end
    
    -- If not keeping interior, compute convex hull to get outer boundary
    if not keepInterior and #merged > 2 then
        merged = ConvexHull2D(merged)
    end
    
    return merged
end

--- Creates union of two polygons (combines and keeps outer boundary)
--- @param poly1 table Array of points defining first polygon
--- @param poly2 table Array of points defining second polygon
--- @return table|nil union Combined polygon boundary or nil on error
--- @usage local union = UnionPolygons(shape1, shape2)
function UnionPolygons(poly1, poly2)
    -- Union: merge polygons and keep only the outer boundary
    return MergePolygons(poly1, poly2, false)
end

--- Creates intersection of two polygons (overlapping area)
--- @param poly1 table Array of points defining first polygon
--- @param poly2 table Array of points defining second polygon
--- @return table|nil intersection Overlapping area points or nil on error
--- @usage local overlap = IntersectPolygons(shape1, shape2)
function IntersectPolygons(poly1, poly2)
    if not poly1 or not poly2 or type(poly1) ~= "table" or type(poly2) ~= "table" then
        _HarnessInternal.log.error("IntersectPolygons requires two valid polygons", "VectorOps.IntersectPolygons")
        return nil
    end
    
    local intersection = {}
    
    -- Find all intersection points
    local intersections = FindPolygonIntersections(poly1, poly2)
    
    -- Add intersection points
    for _, inter in ipairs(intersections) do
        table.insert(intersection, inter.point)
    end
    
    -- Add vertices of poly1 that are inside poly2
    for _, point in ipairs(poly1) do
        if PointInPolygon2D(point, poly2) then
            table.insert(intersection, point)
        end
    end
    
    -- Add vertices of poly2 that are inside poly1
    for _, point in ipairs(poly2) do
        if PointInPolygon2D(point, poly1) then
            table.insert(intersection, point)
        end
    end
    
    -- Sort points by angle from centroid
    if #intersection > 2 then
        local centroid = PolygonCentroid2D(intersection)
        table.sort(intersection, function(a, b)
            local angle_a = math.atan2(a.z - centroid.z, a.x - centroid.x)
            local angle_b = math.atan2(b.z - centroid.z, b.x - centroid.x)
            return angle_a < angle_b
        end)
    end
    
    return intersection
end

--- Creates difference of two polygons (poly1 minus poly2)
--- @param poly1 table Array of points defining first polygon
--- @param poly2 table Array of points defining second polygon to subtract
--- @return table|nil difference Remaining area points or nil on error
--- @usage local diff = DifferencePolygons(shape1, shape2)
function DifferencePolygons(poly1, poly2)
    if not poly1 or not poly2 or type(poly1) ~= "table" or type(poly2) ~= "table" then
        _HarnessInternal.log.error("DifferencePolygons requires two valid polygons", "VectorOps.DifferencePolygons")
        return nil
    end
    
    local difference = {}
    
    -- Add vertices of poly1 that are outside poly2
    for _, point in ipairs(poly1) do
        if not PointInPolygon2D(point, poly2) then
            table.insert(difference, point)
        end
    end
    
    -- Add intersection points
    local intersections = FindPolygonIntersections(poly1, poly2)
    for _, inter in ipairs(intersections) do
        table.insert(difference, inter.point)
    end
    
    -- Sort points by angle from centroid
    if #difference > 2 then
        local centroid = PolygonCentroid2D(difference)
        table.sort(difference, function(a, b)
            local angle_a = math.atan2(a.z - centroid.z, a.x - centroid.x)
            local angle_b = math.atan2(b.z - centroid.z, b.x - centroid.x)
            return angle_a < angle_b
        end)
    end
    
    return difference
end

--- Simplifies a polygon by removing unnecessary points
--- @param polygon table Array of points defining the polygon
--- @param tolerance number? Maximum allowed deviation in meters (default: 1.0)
--- @return table simplified Simplified polygon points
--- @usage local simple = SimplifyPolygon(complexShape, 10)
function SimplifyPolygon(polygon, tolerance)
    if not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error("SimplifyPolygon requires valid polygon with at least 3 points", "VectorOps.SimplifyPolygon")
        return polygon or {}
    end
    
    tolerance = tolerance or 1.0
    
    -- Douglas-Peucker algorithm
    local function douglasPeucker(points, start, endIdx, tolerance)
        if endIdx <= start + 1 then
            return {}
        end
        
        local maxDist = 0
        local maxIndex = 0
        
        -- Find the point with maximum distance from line
        for i = start + 1, endIdx - 1 do
            local dist = PerpendicularDistance2D(points[i], points[start], points[endIdx])
            if dist > maxDist then
                maxDist = dist
                maxIndex = i
            end
        end
        
        -- If max distance is greater than tolerance, recursively simplify
        local result = {}
        if maxDist > tolerance then
            -- Recursive call
            local left = douglasPeucker(points, start, maxIndex, tolerance)
            local right = douglasPeucker(points, maxIndex, endIdx, tolerance)
            
            -- Build the result
            for _, p in ipairs(left) do
                table.insert(result, p)
            end
            table.insert(result, points[maxIndex])
            for _, p in ipairs(right) do
                table.insert(result, p)
            end
        end
        
        return result
    end
    
    local simplified = {polygon[1]}
    local middle = douglasPeucker(polygon, 1, #polygon, tolerance)
    for _, p in ipairs(middle) do
        table.insert(simplified, p)
    end
    table.insert(simplified, polygon[#polygon])
    
    return simplified
end

--- Calculates perpendicular distance from point to line
--- @param point table Point to measure from {x, z}
--- @param lineStart table Start point of line {x, z}
--- @param lineEnd table End point of line {x, z}
--- @return number distance Distance in meters
--- @usage local dist = PerpendicularDistance2D({x=5,z=5}, {x=0,z=0}, {x=10,z=0})
function PerpendicularDistance2D(point, lineStart, lineEnd)
    if not point or not lineStart or not lineEnd then
        _HarnessInternal.log.error("PerpendicularDistance2D requires valid points", "VectorOps.PerpendicularDistance2D")
        return 0
    end
    
    local dx = lineEnd.x - lineStart.x
    local dz = lineEnd.z - lineStart.z
    
    if math.abs(dx) < 1e-6 and math.abs(dz) < 1e-6 then
        -- Line start and end are the same
        return Distance2D(point, lineStart)
    end
    
    local t = ((point.x - lineStart.x) * dx + (point.z - lineStart.z) * dz) / (dx * dx + dz * dz)
    
    if t < 0 then
        return Distance2D(point, lineStart)
    elseif t > 1 then
        return Distance2D(point, lineEnd)
    else
        local projection = {
            x = lineStart.x + t * dx,
            y = point.y or 0,
            z = lineStart.z + t * dz
        }
        return Distance2D(point, projection)
    end
end

--- Offsets a polygon by a specified distance (inward or outward)
--- @param polygon table Array of points defining the polygon
--- @param distance number Offset distance in meters (positive = outward)
--- @return table|nil offset Offset polygon points or nil on error
--- @usage local expanded = OffsetPolygon(shape, 100)
function OffsetPolygon(polygon, distance)
    if not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error("OffsetPolygon requires valid polygon with at least 3 points", "VectorOps.OffsetPolygon")
        return nil
    end
    
    local offset = {}
    local n = #polygon
    
    for i = 1, n do
        local prev = polygon[((i - 2) % n) + 1]
        local curr = polygon[i]
        local next = polygon[(i % n) + 1]
        
        -- Calculate edge vectors
        local v1 = {x = curr.x - prev.x, z = curr.z - prev.z}
        local v2 = {x = next.x - curr.x, z = next.z - curr.z}
        
        -- Normalize
        local len1 = math.sqrt(v1.x * v1.x + v1.z * v1.z)
        local len2 = math.sqrt(v2.x * v2.x + v2.z * v2.z)
        
        if len1 > 1e-6 and len2 > 1e-6 then
            v1.x, v1.z = v1.x / len1, v1.z / len1
            v2.x, v2.z = v2.x / len2, v2.z / len2
            
            -- Calculate normals (perpendicular)
            local n1 = {x = -v1.z, z = v1.x}
            local n2 = {x = -v2.z, z = v2.x}
            
            -- Calculate miter
            local miter = {x = n1.x + n2.x, z = n1.z + n2.z}
            local miterLen = math.sqrt(miter.x * miter.x + miter.z * miter.z)
            
            if miterLen > 1e-6 then
                -- Calculate miter length
                local dot = v1.x * v2.x + v1.z * v2.z
                local miterScale = 1 / (1 + dot)
                
                -- Apply offset
                table.insert(offset, {
                    x = curr.x + miter.x * distance * miterScale / miterLen,
                    y = curr.y or 0,
                    z = curr.z + miter.z * distance * miterScale / miterLen
                })
            else
                -- Fallback for sharp angles
                table.insert(offset, {
                    x = curr.x + n1.x * distance,
                    y = curr.y or 0,
                    z = curr.z + n1.z * distance
                })
            end
        else
            -- Degenerate case
            table.insert(offset, curr)
        end
    end
    
    return offset
end

--- Clips one polygon to another using Sutherland-Hodgman algorithm
--- @param subject table Array of points defining polygon to clip
--- @param clip table Array of points defining clipping polygon
--- @return table|nil clipped Clipped polygon points or nil on error
--- @usage local clipped = ClipPolygonToPolygon(shape, boundary)
function ClipPolygonToPolygon(subject, clip)
    -- Sutherland-Hodgman algorithm
    if not subject or not clip or type(subject) ~= "table" or type(clip) ~= "table" then
        _HarnessInternal.log.error("ClipPolygonToPolygon requires two valid polygons", "VectorOps.ClipPolygonToPolygon")
        return nil
    end
    
    local function inside(p, edge_start, edge_end)
        return (edge_end.x - edge_start.x) * (p.z - edge_start.z) - 
               (edge_end.z - edge_start.z) * (p.x - edge_start.x) >= 0
    end
    
    local output = subject
    
    for i = 1, #clip do
        if #output == 0 then break end
        
        local input = output
        output = {}
        
        local edge_start = clip[i]
        local edge_end = clip[(i % #clip) + 1]
        
        for j = 1, #input do
            local current = input[j]
            local previous = input[((j - 2) % #input) + 1]
            
            if inside(current, edge_start, edge_end) then
                if not inside(previous, edge_start, edge_end) then
                    -- Entering the inside
                    local intersection = LineSegmentIntersection2D(previous, current, edge_start, edge_end)
                    if intersection then
                        table.insert(output, intersection)
                    end
                end
                table.insert(output, current)
            elseif inside(previous, edge_start, edge_end) then
                -- Leaving the inside
                local intersection = LineSegmentIntersection2D(previous, current, edge_start, edge_end)
                if intersection then
                    table.insert(output, intersection)
                end
            end
        end
    end
    
    return output
end

--- Triangulates a polygon into triangles using ear clipping
--- @param polygon table Array of points defining the polygon
--- @return table triangles Array of triangles, each with 3 vertices
--- @usage local triangles = TriangulatePolygon(shape)
function TriangulatePolygon(polygon)
    if not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error("TriangulatePolygon requires valid polygon with at least 3 points", "VectorOps.TriangulatePolygon")
        return {}
    end
    
    -- Simple ear clipping algorithm
    local triangles = {}
    local vertices = {}
    
    -- Copy vertices
    for i, v in ipairs(polygon) do
        table.insert(vertices, {x = v.x, y = v.y or 0, z = v.z, index = i})
    end
    
    local function isEar(vertices, i)
        local n = #vertices
        local prev = ((i - 2) % n) + 1
        local next = (i % n) + 1
        
        local p1 = vertices[prev]
        local p2 = vertices[i]
        local p3 = vertices[next]
        
        -- Check if angle is convex
        local cross = (p2.x - p1.x) * (p3.z - p1.z) - (p2.z - p1.z) * (p3.x - p1.x)
        if cross <= 0 then
            return false
        end
        
        -- Check if any other vertex is inside the triangle
        for j = 1, n do
            if j ~= prev and j ~= i and j ~= next then
                if PointInTriangle2D(vertices[j], p1, p2, p3) then
                    return false
                end
            end
        end
        
        return true
    end
    
    while #vertices > 3 do
        local found = false
        
        for i = 1, #vertices do
            if isEar(vertices, i) then
                local n = #vertices
                local prev = ((i - 2) % n) + 1
                local next = (i % n) + 1
                
                table.insert(triangles, {
                    vertices[prev],
                    vertices[i],
                    vertices[next]
                })
                
                table.remove(vertices, i)
                found = true
                break
            end
        end
        
        if not found then
            -- Fallback: just create a fan from first vertex
            for i = 2, #vertices - 1 do
                table.insert(triangles, {
                    vertices[1],
                    vertices[i],
                    vertices[i + 1]
                })
            end
            break
        end
    end
    
    -- Add the last triangle
    if #vertices == 3 then
        table.insert(triangles, vertices)
    end
    
    return triangles
end

--- Checks if a point is inside a 2D triangle
--- @param p table Point to test {x, z}
--- @param a table First vertex of triangle {x, z}
--- @param b table Second vertex of triangle {x, z}
--- @param c table Third vertex of triangle {x, z}
--- @return boolean inside True if point is inside triangle
--- @usage local inside = PointInTriangle2D({x=5,z=5}, {x=0,z=0}, {x=10,z=0}, {x=5,z=10})
function PointInTriangle2D(p, a, b, c)
    local function sign(p1, p2, p3)
        return (p1.x - p3.x) * (p2.z - p3.z) - (p2.x - p3.x) * (p1.z - p3.z)
    end
    
    local d1 = sign(p, a, b)
    local d2 = sign(p, b, c)
    local d3 = sign(p, c, a)
    
    local has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    local has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    
    return not (has_neg and has_pos)
end