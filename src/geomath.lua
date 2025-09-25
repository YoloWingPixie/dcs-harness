--[[
    GeoMath Module - Geospatial Mathematics and Calculations
    
    This module provides comprehensive geospatial calculations and utilities
    for DCS World scripting, including distance calculations, bearing computations,
    coordinate transformations, and geometric operations.
]]

require("logger")
require("vector")

-- Constants
local NM_TO_METERS = 1852
local METERS_TO_NM = 1 / 1852
local FEET_TO_METERS = 0.3048
local METERS_TO_FEET = 1 / 0.3048
local KM_TO_METERS = 1000
local METERS_TO_KM = 0.001
local EARTH_RADIUS_M = 6371000
local DEG_TO_RAD = math.pi / 180
local RAD_TO_DEG = 180 / math.pi

---Converts degrees to radians
---@param degrees number The angle in degrees
---@return number? radians The angle in radians, or nil if input is invalid
---@usage
--- local rad = DegToRad(90) -- Returns 1.5708 (π/2)
--- local rad2 = DegToRad(180) -- Returns 3.14159 (π)
function DegToRad(degrees)
    if not degrees or type(degrees) ~= "number" then
        _HarnessInternal.log.error("DegToRad requires valid degrees", "GeoMath.DegToRad")
        return nil
    end
    return degrees * DEG_TO_RAD
end

---Converts radians to degrees
---@param radians number The angle in radians
---@return number? degrees The angle in degrees, or nil if input is invalid
---@usage
--- local deg = RadToDeg(math.pi) -- Returns 180
--- local deg2 = RadToDeg(math.pi / 2) -- Returns 90
function RadToDeg(radians)
    if not radians or type(radians) ~= "number" then
        _HarnessInternal.log.error("RadToDeg requires valid radians", "GeoMath.RadToDeg")
        return nil
    end
    return radians * RAD_TO_DEG
end

---Converts nautical miles to meters
---@param nm number Distance in nautical miles
---@return number? meters Distance in meters, or nil if input is invalid
---@usage
--- local meters = NauticalMilesToMeters(10) -- Returns 18520 (10 nautical miles)
--- local range = NauticalMilesToMeters(50) -- Returns 92600 (50 nautical miles)
function NauticalMilesToMeters(nm)
    if not nm or type(nm) ~= "number" then
        _HarnessInternal.log.error("NauticalMilesToMeters requires valid nautical miles", "GeoMath.NauticalMilesToMeters")
        return nil
    end
    return nm * NM_TO_METERS
end

---Converts meters to nautical miles
---@param meters number Distance in meters
---@return number? nm Distance in nautical miles, or nil if input is invalid
---@usage
--- local nm = MetersToNauticalMiles(1852) -- Returns 1 (1 nautical mile)
--- local nm2 = MetersToNauticalMiles(92600) -- Returns 50 (50 nautical miles)
function MetersToNauticalMiles(meters)
    if not meters or type(meters) ~= "number" then
        _HarnessInternal.log.error("MetersToNauticalMiles requires valid meters", "GeoMath.MetersToNauticalMiles")
        return nil
    end
    return meters * METERS_TO_NM
end

---Converts feet to meters
---@param feet number Height/distance in feet
---@return number? meters Height/distance in meters, or nil if input is invalid
---@usage
--- local meters = FeetToMeters(1000) -- Returns 304.8 (1000 feet)
--- local altitude = FeetToMeters(35000) -- Returns 10668 (FL350)
function FeetToMeters(feet)
    if not feet or type(feet) ~= "number" then
        _HarnessInternal.log.error("FeetToMeters requires valid feet", "GeoMath.FeetToMeters")
        return nil
    end
    return feet * FEET_TO_METERS
end

---Converts meters to feet
---@param meters number Height/distance in meters
---@return number? feet Height/distance in feet, or nil if input is invalid
---@usage
--- local feet = MetersToFeet(304.8) -- Returns 1000 (1000 feet)
--- local fl = MetersToFeet(10668) -- Returns 35000 (FL350)
function MetersToFeet(meters)
    if not meters or type(meters) ~= "number" then
        _HarnessInternal.log.error("MetersToFeet requires valid meters", "GeoMath.MetersToFeet")
        return nil
    end
    return meters * METERS_TO_FEET
end

---Calculates the 2D distance between two points (ignoring altitude)
---@param point1 table|Vec2|Vec3 First point with x and z coordinates
---@param point2 table|Vec2|Vec3 Second point with x and z coordinates
---@return number? distance Distance in meters, or nil if inputs are invalid
---@usage
--- local dist = Distance2D({x=0, z=0}, {x=100, z=100}) -- Returns 141.42 (diagonal)
--- local range = Distance2D(unit1:getPoint(), unit2:getPoint()) -- Distance between units
function Distance2D(point1, point2)
    if not point1 or not point2 then
        _HarnessInternal.log.error("Distance2D requires two valid points", "GeoMath.Distance2D")
        return nil
    end
    
    if not point1.x or not point1.z or not point2.x or not point2.z then
        _HarnessInternal.log.error("Distance2D points must have x and z coordinates", "GeoMath.Distance2D")
        return nil
    end
    
    local dx = point2.x - point1.x
    local dz = point2.z - point1.z
    return math.sqrt(dx * dx + dz * dz)
end

---Calculates the 3D distance between two points (including altitude)
---@param point1 table|Vec3 First point with x, y, and z coordinates
---@param point2 table|Vec3 Second point with x, y, and z coordinates
---@return number? distance Distance in meters, or nil if inputs are invalid
---@usage
--- local dist = Distance3D({x=0, y=0, z=0}, {x=100, y=50, z=100}) -- Returns 158.11
--- local slantRange = Distance3D(aircraft:getPoint(), target:getPoint()) -- Slant range
function Distance3D(point1, point2)
    if not point1 or not point2 then
        _HarnessInternal.log.error("Distance3D requires two valid points", "GeoMath.Distance3D")
        return nil
    end
    
    if not point1.x or not point1.y or not point1.z or not point2.x or not point2.y or not point2.z then
        _HarnessInternal.log.error("Distance3D points must have x, y, and z coordinates", "GeoMath.Distance3D")
        return nil
    end
    
    local dx = point2.x - point1.x
    local dy = point2.y - point1.y
    local dz = point2.z - point1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---Calculates the bearing from one point to another
---@param from table|Vec2|Vec3 Starting point
---@param to table|Vec2|Vec3 Target point
---@return number? bearing Aviation bearing in degrees (0=North, 90=East), or nil if invalid
---@usage
--- local bearing = BearingBetween({x=0, z=0}, {x=100, z=0}) -- Returns 90 (East)
--- local hdg = BearingBetween(myUnit:getPoint(), target:getPoint()) -- Bearing to target
--- local intercept = BearingBetween(fighter:getPoint(), bandit:getPoint()) -- Intercept heading
function BearingBetween(from, to)
    if not from or not to then
        _HarnessInternal.log.error("BearingBetween requires two valid points", "GeoMath.BearingBetween")
        return nil
    end
    
    if not from.x or not from.z or not to.x or not to.z then
        _HarnessInternal.log.error("BearingBetween points must have x and z coordinates", "GeoMath.BearingBetween")
        return nil
    end
    
    local dx = to.x - from.x
    local dz = to.z - from.z
    
    -- Calculate mathematical angle (0 = East, counterclockwise)
    local mathAngleRad = math.atan2(dz, dx)
    
    -- Convert to aviation bearing (0 = North, clockwise)
    local aviationBearingRad = math.pi / 2 - mathAngleRad
    local aviationBearingDeg = RadToDeg(aviationBearingRad)
    
    -- Normalize to 0-360
    return (aviationBearingDeg + 360) % 360
end

---Displaces a point by a given bearing and distance
---@param point table|Vec2|Vec3 Starting point
---@param bearingDeg number Aviation bearing in degrees (0=North, 90=East)
---@param distance number Distance to displace in meters
---@return table? point New point with x, y, z coordinates, or nil if invalid
---@usage
--- local newPos = DisplacePoint2D({x=0, z=0}, 90, 1000) -- 1km East: {x=1000, y=0, z=0}
--- local ip = DisplacePoint2D(airfield:getPoint(), 270, 10 * 1852) -- 10nm West of field
--- local orbit = DisplacePoint2D(tanker:getPoint(), hdg, 40 * 1852) -- 40nm ahead
function DisplacePoint2D(point, bearingDeg, distance)
    if not point or not bearingDeg or not distance then
        _HarnessInternal.log.error("DisplacePoint2D requires point, bearing, and distance", "GeoMath.DisplacePoint2D")
        return nil
    end
    
    if not point.x or not point.z then
        _HarnessInternal.log.error("DisplacePoint2D point must have x and z coordinates", "GeoMath.DisplacePoint2D")
        return nil
    end
    
    -- Convert aviation bearing to mathematical angle
    local mathAngleDeg = (90 - bearingDeg + 360) % 360
    local angleRad = DegToRad(mathAngleDeg)
    
    local dx = math.cos(angleRad) * distance
    local dz = math.sin(angleRad) * distance
    
    -- Mitigate floating point errors
    if math.abs(dx) < 1e-6 then dx = 0 end
    if math.abs(dz) < 1e-6 then dz = 0 end
    
    return {
        x = point.x + dx,
        y = point.y or 0,
        z = point.z + dz
    }
end

---Calculates the midpoint between two points
---@param point1 table|Vec2|Vec3 First point
---@param point2 table|Vec2|Vec3 Second point
---@return table? midpoint Point with x, y, z coordinates, or nil if invalid
---@usage
--- local mid = MidPoint({x=0, z=0}, {x=100, z=100}) -- Returns {x=50, y=0, z=50}
--- local center = MidPoint(wp1, wp2) -- Center point between waypoints
function MidPoint(point1, point2)
    if not point1 or not point2 then
        _HarnessInternal.log.error("MidPoint requires two valid points", "GeoMath.MidPoint")
        return nil
    end
    
    return {
        x = (point1.x + point2.x) / 2,
        y = ((point1.y or 0) + (point2.y or 0)) / 2,
        z = (point1.z + point2.z) / 2
    }
end

---Rotates a point around a center point by a given angle
---@param point table|Vec2|Vec3 Point to rotate
---@param center table|Vec2|Vec3 Center of rotation
---@param angleDeg number Rotation angle in degrees (positive = clockwise)
---@return table? point Rotated point with x, y, z coordinates, or nil if invalid
---@usage
--- local rotated = RotatePoint2D({x=100, z=0}, {x=0, z=0}, 90) -- Returns {x=0, y=0, z=100}
--- local formation = RotatePoint2D(wingman, lead, 45) -- Rotate wingman 45° around lead
function RotatePoint2D(point, center, angleDeg)
    if not point or not center or not angleDeg then
        _HarnessInternal.log.error("RotatePoint2D requires point, center, and angle", "GeoMath.RotatePoint2D")
        return nil
    end
    
    local angleRad = DegToRad(angleDeg)
    local cos_a = math.cos(angleRad)
    local sin_a = math.sin(angleRad)
    
    -- Translate to origin
    local dx = point.x - center.x
    local dz = point.z - center.z
    
    -- Rotate
    local new_dx = dx * cos_a - dz * sin_a
    local new_dz = dx * sin_a + dz * cos_a
    
    -- Translate back
    return {
        x = center.x + new_dx,
        y = point.y or 0,
        z = center.z + new_dz
    }
end

---Normalizes a 2D vector to unit length
---@param vector table|Vec2 Vector to normalize (must have x and z)
---@return table? normalized Unit vector with x, y, z coordinates, or nil if invalid
---@usage
--- local unit = NormalizeVector2D({x=3, z=4}) -- Returns {x=0.6, y=0, z=0.8}
--- local dir = NormalizeVector2D(velocity) -- Get direction from velocity
function NormalizeVector2D(vector)
    if not vector or not vector.x or not vector.z then
        _HarnessInternal.log.error("NormalizeVector2D requires valid vector with x and z", "GeoMath.NormalizeVector2D")
        return nil
    end
    
    local magnitude = math.sqrt(vector.x * vector.x + vector.z * vector.z)
    
    if magnitude < 1e-6 then
        return {x = 0, y = 0, z = 0}
    end
    
    return {
        x = vector.x / magnitude,
        y = vector.y or 0,
        z = vector.z / magnitude
    }
end

---Normalizes a 3D vector to unit length
---@param vector table|Vec3 Vector to normalize (must have x, y, and z)
---@return table? normalized Unit vector with x, y, z coordinates, or nil if invalid
---@usage
--- local unit = NormalizeVector3D({x=2, y=2, z=1}) -- Returns {x=0.667, y=0.667, z=0.333}
--- local dir = NormalizeVector3D(velocity) -- Get 3D direction from velocity
function NormalizeVector3D(vector)
    if not vector or not vector.x or not vector.y or not vector.z then
        _HarnessInternal.log.error("NormalizeVector3D requires valid vector with x, y, and z", "GeoMath.NormalizeVector3D")
        return nil
    end
    
    local magnitude = math.sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    
    if magnitude < 1e-6 then
        return {x = 0, y = 0, z = 0}
    end
    
    return {
        x = vector.x / magnitude,
        y = vector.y / magnitude,
        z = vector.z / magnitude
    }
end

---Calculates the dot product of two 2D vectors
---@param v1 table|Vec2 First vector
---@param v2 table|Vec2 Second vector
---@return number? dot Dot product value, or nil if invalid
---@usage
--- local dot = DotProduct2D({x=1, z=0}, {x=0, z=1}) -- Returns 0 (perpendicular)
--- local dot2 = DotProduct2D({x=1, z=0}, {x=1, z=0}) -- Returns 1 (parallel)
function DotProduct2D(v1, v2)
    if not v1 or not v2 then
        _HarnessInternal.log.error("DotProduct2D requires two valid vectors", "GeoMath.DotProduct2D")
        return nil
    end
    
    return (v1.x or 0) * (v2.x or 0) + (v1.z or 0) * (v2.z or 0)
end

---Calculates the dot product of two 3D vectors
---@param v1 table|Vec3 First vector
---@param v2 table|Vec3 Second vector
---@return number? dot Dot product value, or nil if invalid
---@usage
--- local dot = DotProduct3D({x=1, y=0, z=0}, {x=0, y=1, z=0}) -- Returns 0
--- local align = DotProduct3D(forward, target) -- Check alignment with target
function DotProduct3D(v1, v2)
    if not v1 or not v2 then
        _HarnessInternal.log.error("DotProduct3D requires two valid vectors", "GeoMath.DotProduct3D")
        return nil
    end
    
    return (v1.x or 0) * (v2.x or 0) + (v1.y or 0) * (v2.y or 0) + (v1.z or 0) * (v2.z or 0)
end

---Calculates the cross product of two 3D vectors
---@param v1 table|Vec3 First vector
---@param v2 table|Vec3 Second vector
---@return table? cross Cross product vector with x, y, z, or nil if invalid
---@usage
--- local cross = CrossProduct3D({x=1, y=0, z=0}, {x=0, y=1, z=0}) -- Returns {x=0, y=0, z=1}
--- local normal = CrossProduct3D(edge1, edge2) -- Surface normal from two edges
function CrossProduct3D(v1, v2)
    if not v1 or not v2 then
        _HarnessInternal.log.error("CrossProduct3D requires two valid vectors", "GeoMath.CrossProduct3D")
        return nil
    end
    
    return {
        x = (v1.y or 0) * (v2.z or 0) - (v1.z or 0) * (v2.y or 0),
        y = (v1.z or 0) * (v2.x or 0) - (v1.x or 0) * (v2.z or 0),
        z = (v1.x or 0) * (v2.y or 0) - (v1.y or 0) * (v2.x or 0)
    }
end

---Calculates the angle between two 2D vectors
---@param v1 table|Vec2 First vector
---@param v2 table|Vec2 Second vector
---@return number? angle Angle in degrees (0-180), or nil if invalid
---@usage
--- local angle = AngleBetweenVectors2D({x=1, z=0}, {x=0, z=1}) -- Returns 90
--- local angle2 = AngleBetweenVectors2D({x=1, z=0}, {x=-1, z=0}) -- Returns 180
function AngleBetweenVectors2D(v1, v2)
    if not v1 or not v2 then
        _HarnessInternal.log.error("AngleBetweenVectors2D requires two valid vectors", "GeoMath.AngleBetweenVectors2D")
        return nil
    end
    
    local dot = DotProduct2D(v1, v2)
    local mag1 = math.sqrt((v1.x or 0)^2 + (v1.z or 0)^2)
    local mag2 = math.sqrt((v2.x or 0)^2 + (v2.z or 0)^2)
    
    if mag1 < 1e-6 or mag2 < 1e-6 then
        return 0
    end
    
    local cosAngle = dot / (mag1 * mag2)
    cosAngle = math.max(-1, math.min(1, cosAngle)) -- Clamp to [-1, 1]
    
    return RadToDeg(math.acos(cosAngle))
end

function PointInPolygon2D(point, polygon)
    if not point or not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error("PointInPolygon2D requires valid point and polygon with at least 3 vertices", "GeoMath.PointInPolygon2D")
        return nil
    end
    
    local x, z = point.x, point.z
    local inside = false
    
    local p1x, p1z = polygon[1].x, polygon[1].z
    
    for i = 1, #polygon do
        local p2x, p2z = polygon[i % #polygon + 1].x, polygon[i % #polygon + 1].z
        
        if z > math.min(p1z, p2z) and z <= math.max(p1z, p2z) and x <= math.max(p1x, p2x) then
            if p1z ~= p2z then
                local xinters = (z - p1z) * (p2x - p1x) / (p2z - p1z) + p1x
                if p1x == p2x or x <= xinters then
                    inside = not inside
                end
            end
        end
        
        p1x, p1z = p2x, p2z
    end
    
    return inside
end

function CircleLineIntersection2D(circleCenter, radius, lineStart, lineEnd)
    if not circleCenter or not radius or not lineStart or not lineEnd then
        _HarnessInternal.log.error("CircleLineIntersection2D requires all parameters", "GeoMath.CircleLineIntersection2D")
        return nil
    end
    
    local dx = lineEnd.x - lineStart.x
    local dz = lineEnd.z - lineStart.z
    local fx = lineStart.x - circleCenter.x
    local fz = lineStart.z - circleCenter.z
    
    local a = dx * dx + dz * dz
    local b = 2 * (fx * dx + fz * dz)
    local c = (fx * fx + fz * fz) - radius * radius
    
    local discriminant = b * b - 4 * a * c
    
    if discriminant < 0 then
        return {} -- No intersection
    end
    
    local discriminantSqrt = math.sqrt(discriminant)
    local t1 = (-b - discriminantSqrt) / (2 * a)
    local t2 = (-b + discriminantSqrt) / (2 * a)
    
    local intersections = {}
    
    if t1 >= 0 and t1 <= 1 then
        table.insert(intersections, {
            x = lineStart.x + t1 * dx,
            y = lineStart.y or 0,
            z = lineStart.z + t1 * dz
        })
    end
    
    if t2 >= 0 and t2 <= 1 and math.abs(t2 - t1) > 1e-6 then
        table.insert(intersections, {
            x = lineStart.x + t2 * dx,
            y = lineStart.y or 0,
            z = lineStart.z + t2 * dz
        })
    end
    
    return intersections
end

function PolygonArea2D(polygon)
    if not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error("PolygonArea2D requires polygon with at least 3 vertices", "GeoMath.PolygonArea2D")
        return nil
    end
    
    local area = 0
    local n = #polygon
    
    for i = 1, n do
        local j = (i % n) + 1
        area = area + polygon[i].x * polygon[j].z
        area = area - polygon[j].x * polygon[i].z
    end
    
    return math.abs(area) / 2
end

function PolygonCentroid2D(polygon)
    if not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error("PolygonCentroid2D requires polygon with at least 3 vertices", "GeoMath.PolygonCentroid2D")
        return nil
    end
    
    local cx, cz = 0, 0
    local area = 0
    
    for i = 1, #polygon do
        local j = (i % #polygon) + 1
        local a = polygon[i].x * polygon[j].z - polygon[j].x * polygon[i].z
        area = area + a
        cx = cx + (polygon[i].x + polygon[j].x) * a
        cz = cz + (polygon[i].z + polygon[j].z) * a
    end
    
    area = area / 2
    
    if math.abs(area) < 1e-6 then
        -- Degenerate polygon, return average of points
        for _, p in ipairs(polygon) do
            cx = cx + p.x
            cz = cz + p.z
        end
        return {x = cx / #polygon, y = 0, z = cz / #polygon}
    end
    
    return {x = cx / (6 * area), y = 0, z = cz / (6 * area)}
end

function ConvexHull2D(points)
    if not points or type(points) ~= "table" or #points < 3 then
        _HarnessInternal.log.error("ConvexHull2D requires at least 3 points", "GeoMath.ConvexHull2D")
        return points or {}
    end
    
    -- Find the leftmost point
    local start = 1
    for i = 2, #points do
        if points[i].x < points[start].x or 
           (points[i].x == points[start].x and points[i].z < points[start].z) then
            start = i
        end
    end
    
    local hull = {}
    local current = start
    
    repeat
        table.insert(hull, points[current])
        local next = 1
        
        for i = 1, #points do
            if i ~= current then
                if next == current then
                    next = i
                else
                    local cross = (points[i].x - points[current].x) * (points[next].z - points[current].z) -
                                  (points[i].z - points[current].z) * (points[next].x - points[current].x)
                    
                    if cross > 0 or (cross == 0 and 
                       Distance2D(points[current], points[i]) > Distance2D(points[current], points[next])) then
                        next = i
                    end
                end
            end
        end
        
        current = next
    until current == start
    
    return hull
end