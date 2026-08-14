--[[
    GeoMath Module - Geospatial Mathematics and Calculations

    This module provides comprehensive geospatial calculations and utilities
    for DCS World scripting, including distance calculations, bearing computations,
    coordinate transformations, and geometric operations.
]]

require("logger")
require("vector")
require("conversion")

-- Local aliases for HarnessConstants (defined in _header.lua)
local NM_TO_METERS = HarnessConstants.NM_TO_METERS
local METERS_TO_NM = HarnessConstants.METERS_TO_NM
local KM_TO_METERS = HarnessConstants.KM_TO_METERS
local METERS_TO_KM = HarnessConstants.METERS_TO_KM
local EARTH_RADIUS_M = HarnessConstants.EARTH_RADIUS_M
local DEG_TO_RAD = HarnessConstants.DEG_TO_RAD
local RAD_TO_DEG = HarnessConstants.RAD_TO_DEG
local GeoMathInternal = {}

function GeoMathInternal.isFiniteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function GeoMathInternal.groundEast(value)
    if IsVec3(value) and GeoMathInternal.isFiniteNumber(value.z) then
        return value.z
    end
    if IsVec2(value) and GeoMathInternal.isFiniteNumber(value.y) then
        return value.y
    end
    return nil
end

function GeoMathInternal.groundResult(reference, x, east, altitude)
    if IsVec3(reference) then
        return Vec3(x, altitude == nil and reference.y or altitude, east)
    end
    return Vec2(x, east)
end

function GeoMathInternal.componentOrZero(vector, component)
    return (vector and vector[component]) or 0
end

function GeoMathInternal.horizontalPositionAtTime(position, velocity, time)
    return {
        x = GeoMathInternal.componentOrZero(position, "x")
            + GeoMathInternal.componentOrZero(velocity, "x") * time,
        y = GeoMathInternal.componentOrZero(position, "y"),
        z = GeoMathInternal.componentOrZero(position, "z")
            + GeoMathInternal.componentOrZero(velocity, "z") * time,
    }
end

function GeoMathInternal.smallestNonnegativeRoot(a, b, c, epsilon)
    if math.abs(a) < epsilon then
        if math.abs(b) < epsilon then
            if c < epsilon then
                return 0
            end
            return nil
        end
        local root = -c / b
        if root >= 0 then
            return root
        end
        return nil
    end

    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return nil
    end
    local rootOffset = math.sqrt(discriminant)
    local first = (-b - rootOffset) / (2 * a)
    local second = (-b + rootOffset) / (2 * a)
    local result = math.huge
    if first >= 0 then
        result = first
    end
    if second >= 0 then
        result = math.min(result, second)
    end
    if result == math.huge then
        return nil
    end
    return result
end

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
        _HarnessInternal.log.error(
            "NauticalMilesToMeters requires valid nautical miles",
            "GeoMath.NauticalMilesToMeters"
        )
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
        _HarnessInternal.log.error(
            "MetersToNauticalMiles requires valid meters",
            "GeoMath.MetersToNauticalMiles"
        )
        return nil
    end
    return meters * METERS_TO_NM
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

    if
        not point1.x
        or not point1.y
        or not point1.z
        or not point2.x
        or not point2.y
        or not point2.z
    then
        _HarnessInternal.log.error(
            "Distance3D points must have x, y, and z coordinates",
            "GeoMath.Distance3D"
        )
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
--- local bearing = BearingBetween({x=0, y=0}, {x=100, y=0}) -- Returns 0 (North)
--- local hdg = BearingBetween(myUnit:getPoint(), target:getPoint()) -- Bearing to target
--- local intercept = BearingBetween(fighter:getPoint(), bandit:getPoint()) -- Intercept heading
function BearingBetween(from, to)
    return Bearing(from, to)
end

---Displaces a point by a given bearing and distance
---@param point table|Vec2|Vec3 Starting point
---@param bearingDeg number Aviation bearing in degrees (0=North, 90=East)
---@param distance number Distance to displace in meters
---@return table? point New point with x, y, z coordinates, or nil if invalid
---@usage
--- local newPos = DisplacePoint2D({x=0, y=0}, 90, 1000) -- 1km East: {x=0, y=1000}
--- local ip = DisplacePoint2D(airfield:getPoint(), 270, 10 * 1852) -- 10nm West of field
--- local orbit = DisplacePoint2D(tanker:getPoint(), hdg, 40 * 1852) -- 40nm ahead
function DisplacePoint2D(point, bearingDeg, distance)
    return FromBearingDistance(point, bearingDeg, distance)
end

--- Get the unit ground-plane vector for a DCS world heading
---@param headingDeg number Heading in degrees
---@return table? vector DCS Vec2 with north X and east Y components
function HeadingVector2D(headingDeg)
    if
        type(headingDeg) ~= "number"
        or headingDeg ~= headingDeg
        or headingDeg <= -math.huge
        or headingDeg >= math.huge
    then
        _HarnessInternal.log.error(
            "HeadingVector2D requires a finite heading",
            "GeoMath.HeadingVector2D"
        )
        return nil
    end
    local radians = math.rad(headingDeg)
    return Vec2(math.cos(radians), math.sin(radians))
end

--- Get DCS world ground track from a velocity vector
---@param velocity table Vec3 velocity
---@param minSpeedMps number? Minimum horizontal speed, default 15 m/s
---@return number? headingDeg Track heading or nil below the threshold
function GroundTrackFromVelocity(velocity, minSpeedMps)
    minSpeedMps = minSpeedMps == nil and 15 or minSpeedMps
    if
        not IsVec3(velocity)
        or not GeoMathInternal.isFiniteNumber(velocity.x)
        or not GeoMathInternal.isFiniteNumber(velocity.y)
        or not GeoMathInternal.isFiniteNumber(velocity.z)
        or type(minSpeedMps) ~= "number"
        or minSpeedMps ~= minSpeedMps
        or minSpeedMps < 0
        or minSpeedMps >= math.huge
    then
        _HarnessInternal.log.error(
            "GroundTrackFromVelocity requires Vec3 velocity and a non-negative threshold",
            "GeoMath.GroundTrackFromVelocity"
        )
        return nil
    end

    local horizontalSpeed = math.sqrt(velocity.x * velocity.x + velocity.z * velocity.z)
    if horizontalSpeed < minSpeedMps then
        return nil
    end
    return (math.deg(math.atan2(velocity.z, velocity.x)) + 360) % 360
end

--- Create a DCS heading-relative ground-plane frame
---@param origin table Vec3 frame origin
---@param headingDeg number Heading in degrees
---@return table? frame Heading-relative frame
function HeadingFrame2D(origin, headingDeg)
    if
        not IsVec3(origin)
        or not GeoMathInternal.isFiniteNumber(origin.x)
        or not GeoMathInternal.isFiniteNumber(origin.y)
        or not GeoMathInternal.isFiniteNumber(origin.z)
    then
        _HarnessInternal.log.error(
            "HeadingFrame2D requires a Vec3 origin",
            "GeoMath.HeadingFrame2D"
        )
        return nil
    end
    local forward = HeadingVector2D(headingDeg)
    local right = HeadingVector2D(type(headingDeg) == "number" and headingDeg + 90 or headingDeg)
    if not forward or not right then
        return nil
    end
    return {
        origin = Vec3(origin.x, origin.y, origin.z),
        headingDeg = (headingDeg + 360) % 360,
        forward = forward,
        right = right,
    }
end

function GeoMathInternal.isHeadingFrame(frame)
    return type(frame) == "table"
        and IsVec3(frame.origin)
        and GeoMathInternal.isFiniteNumber(frame.origin.x)
        and GeoMathInternal.isFiniteNumber(frame.origin.y)
        and GeoMathInternal.isFiniteNumber(frame.origin.z)
        and IsVec2(frame.forward)
        and GeoMathInternal.isFiniteNumber(frame.forward.x)
        and GeoMathInternal.isFiniteNumber(frame.forward.y)
        and IsVec2(frame.right)
        and GeoMathInternal.isFiniteNumber(frame.right.x)
        and GeoMathInternal.isFiniteNumber(frame.right.y)
        and GeoMathInternal.isFiniteNumber(frame.headingDeg)
end

--- Project a point into a DCS heading-relative frame
---@param frame table HeadingFrame2D value
---@param point table Vec2 or Vec3 point
---@return number? alongM Forward distance
---@return number? lateralM Right distance
function ProjectPointToHeadingFrame2D(frame, point)
    if
        not GeoMathInternal.isHeadingFrame(frame)
        or type(point) ~= "table"
        or not GeoMathInternal.isFiniteNumber(point.x)
        or GeoMathInternal.groundEast(point) == nil
    then
        _HarnessInternal.log.error(
            "ProjectPointToHeadingFrame2D requires a valid frame and point",
            "GeoMath.ProjectPointToHeadingFrame2D"
        )
        return nil, nil
    end
    local deltaX = point.x - frame.origin.x
    local deltaEast = GeoMathInternal.groundEast(point) - frame.origin.z
    return deltaX * frame.forward.x + deltaEast * frame.forward.y,
        deltaX * frame.right.x + deltaEast * frame.right.y
end

--- Project a vector into a DCS heading-relative frame
---@param frame table HeadingFrame2D value
---@param vector table Vec2 or Vec3 vector
---@return number? forwardMps Forward component
---@return number? lateralMps Right component
function ProjectVectorToHeadingFrame2D(frame, vector)
    if
        not GeoMathInternal.isHeadingFrame(frame)
        or type(vector) ~= "table"
        or not GeoMathInternal.isFiniteNumber(vector.x)
        or GeoMathInternal.groundEast(vector) == nil
    then
        _HarnessInternal.log.error(
            "ProjectVectorToHeadingFrame2D requires a valid frame and vector",
            "GeoMath.ProjectVectorToHeadingFrame2D"
        )
        return nil, nil
    end
    local east = GeoMathInternal.groundEast(vector)
    return vector.x * frame.forward.x + east * frame.forward.y,
        vector.x * frame.right.x + east * frame.right.y
end

---Calculates the midpoint between two points
---@param point1 table|Vec2|Vec3 First point
---@param point2 table|Vec2|Vec3 Second point
---@return table? midpoint DCS Vec2 or Vec3 midpoint, or nil if invalid
---@usage
--- local mid = MidPoint({x=0, y=0}, {x=100, y=100}) -- Returns {x=50, y=50}
--- local center = MidPoint(wp1, wp2) -- Center point between waypoints
function MidPoint(point1, point2)
    if not point1 or not point2 then
        _HarnessInternal.log.error("MidPoint requires two valid points", "GeoMath.MidPoint")
        return nil
    end

    if IsVec3(point1) and IsVec3(point2) then
        return Vec3((point1.x + point2.x) / 2, (point1.y + point2.y) / 2, (point1.z + point2.z) / 2)
    end
    if IsVec2(point1) and IsVec2(point2) then
        return Vec2((point1.x + point2.x) / 2, (point1.y + point2.y) / 2)
    end
    _HarnessInternal.log.error("MidPoint requires points of the same dimension", "GeoMath.MidPoint")
    return nil
end

---Rotates a point around a center point by a given angle
---@param point table|Vec2|Vec3 Point to rotate
---@param center table|Vec2|Vec3 Center of rotation
---@param angleDeg number Rotation angle in degrees (positive = clockwise)
---@return table? point Rotated DCS Vec2 or Vec3, or nil if invalid
---@usage
--- local rotated = RotatePoint2D({x=100, y=0}, {x=0, y=0}, 90) -- Returns {x=0, y=100}
--- local formation = RotatePoint2D(wingman, lead, 45) -- Rotate wingman 45° around lead
function RotatePoint2D(point, center, angleDeg)
    if not point or not center or not GeoMathInternal.isFiniteNumber(angleDeg) then
        _HarnessInternal.log.error(
            "RotatePoint2D requires point, center, and angle",
            "GeoMath.RotatePoint2D"
        )
        return nil
    end

    local pointEast = GeoMathInternal.groundEast(point)
    local centerEast = GeoMathInternal.groundEast(center)
    if pointEast == nil or centerEast == nil or IsVec3(point) ~= IsVec3(center) then
        _HarnessInternal.log.error(
            "RotatePoint2D requires points of the same dimension",
            "GeoMath.RotatePoint2D"
        )
        return nil
    end

    local angleRad = DegToRad(angleDeg)
    local cos_a = math.cos(angleRad)
    local sin_a = math.sin(angleRad)

    -- Translate to origin
    local dx = point.x - center.x
    local de = pointEast - centerEast

    -- Rotate
    local newDx = dx * cos_a - de * sin_a
    local newEast = dx * sin_a + de * cos_a

    -- Translate back
    return GeoMathInternal.groundResult(point, center.x + newDx, centerEast + newEast)
end

---Normalizes a 2D vector to unit length
---@param vector table|Vec2|Vec3 Vector to normalize in the ground plane
---@return table? normalized DCS Vec2 or Vec3 unit vector, or nil if invalid
---@usage
--- local unit = NormalizeVector2D({x=3, y=4}) -- Returns {x=0.6, y=0.8}
--- local dir = NormalizeVector2D(velocity) -- Get direction from velocity
function NormalizeVector2D(vector)
    local east = GeoMathInternal.groundEast(vector)
    if type(vector) ~= "table" or not GeoMathInternal.isFiniteNumber(vector.x) or east == nil then
        _HarnessInternal.log.error(
            "NormalizeVector2D requires a DCS Vec2 or Vec3",
            "GeoMath.NormalizeVector2D"
        )
        return nil
    end

    local magnitude = math.sqrt(vector.x * vector.x + east * east)

    if magnitude < 1e-6 then
        return GeoMathInternal.groundResult(vector, 0, 0)
    end

    return GeoMathInternal.groundResult(vector, vector.x / magnitude, east / magnitude)
end

---Normalizes a 3D vector to unit length
---@param vector table|Vec3 Vector to normalize (must have x, y, and z)
---@return table? normalized Unit vector with x, y, z coordinates, or nil if invalid
---@usage
--- local unit = NormalizeVector3D({x=2, y=2, z=1}) -- Returns {x=0.667, y=0.667, z=0.333}
--- local dir = NormalizeVector3D(velocity) -- Get 3D direction from velocity
function NormalizeVector3D(vector)
    if not vector or not vector.x or not vector.y or not vector.z then
        _HarnessInternal.log.error(
            "NormalizeVector3D requires valid vector with x, y, and z",
            "GeoMath.NormalizeVector3D"
        )
        return nil
    end

    local magnitude = math.sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)

    if magnitude < 1e-6 then
        return { x = 0, y = 0, z = 0 }
    end

    return {
        x = vector.x / magnitude,
        y = vector.y / magnitude,
        z = vector.z / magnitude,
    }
end

---Calculates the dot product of two 2D vectors
---@param v1 table|Vec2 First vector
---@param v2 table|Vec2 Second vector
---@return number? dot Dot product value, or nil if invalid
---@usage
--- local dot = DotProduct2D({x=1, y=0}, {x=0, y=1}) -- Returns 0 (perpendicular)
--- local dot2 = DotProduct2D({x=1, y=0}, {x=1, y=0}) -- Returns 1 (parallel)
function DotProduct2D(v1, v2)
    if not v1 or not v2 then
        _HarnessInternal.log.error(
            "DotProduct2D requires two valid vectors",
            "GeoMath.DotProduct2D"
        )
        return nil
    end

    local firstEast = GeoMathInternal.groundEast(v1)
    local secondEast = GeoMathInternal.groundEast(v2)
    if
        not GeoMathInternal.isFiniteNumber(v1.x)
        or firstEast == nil
        or not GeoMathInternal.isFiniteNumber(v2.x)
        or secondEast == nil
    then
        _HarnessInternal.log.error(
            "DotProduct2D requires DCS Vec2 or Vec3 values",
            "GeoMath.DotProduct2D"
        )
        return nil
    end
    return v1.x * v2.x + firstEast * secondEast
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
        _HarnessInternal.log.error(
            "DotProduct3D requires two valid vectors",
            "GeoMath.DotProduct3D"
        )
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
        _HarnessInternal.log.error(
            "CrossProduct3D requires two valid vectors",
            "GeoMath.CrossProduct3D"
        )
        return nil
    end

    return {
        x = (v1.y or 0) * (v2.z or 0) - (v1.z or 0) * (v2.y or 0),
        y = (v1.z or 0) * (v2.x or 0) - (v1.x or 0) * (v2.z or 0),
        z = (v1.x or 0) * (v2.y or 0) - (v1.y or 0) * (v2.x or 0),
    }
end

---Calculates the angle between two 2D vectors
---@param v1 table|Vec2 First vector
---@param v2 table|Vec2 Second vector
---@return number? angle Angle in degrees (0-180), or nil if invalid
---@usage
--- local angle = AngleBetweenVectors2D({x=1, y=0}, {x=0, y=1}) -- Returns 90
--- local angle2 = AngleBetweenVectors2D({x=1, y=0}, {x=-1, y=0}) -- Returns 180
function AngleBetweenVectors2D(v1, v2)
    if not v1 or not v2 then
        _HarnessInternal.log.error(
            "AngleBetweenVectors2D requires two valid vectors",
            "GeoMath.AngleBetweenVectors2D"
        )
        return nil
    end

    local firstEast = GeoMathInternal.groundEast(v1)
    local secondEast = GeoMathInternal.groundEast(v2)
    if
        not GeoMathInternal.isFiniteNumber(v1.x)
        or firstEast == nil
        or not GeoMathInternal.isFiniteNumber(v2.x)
        or secondEast == nil
    then
        _HarnessInternal.log.error(
            "AngleBetweenVectors2D requires DCS Vec2 or Vec3 values",
            "GeoMath.AngleBetweenVectors2D"
        )
        return nil
    end
    local dot = DotProduct2D(v1, v2)
    local mag1 = math.sqrt(v1.x ^ 2 + firstEast ^ 2)
    local mag2 = math.sqrt(v2.x ^ 2 + secondEast ^ 2)

    if mag1 < 1e-6 or mag2 < 1e-6 then
        return 0
    end

    local cosAngle = dot / (mag1 * mag2)
    cosAngle = math.max(-1, math.min(1, cosAngle)) -- Clamp to [-1, 1]

    return RadToDeg(math.acos(cosAngle))
end

function PointInPolygon2D(point, polygon)
    if not point or not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error(
            "PointInPolygon2D requires valid point and polygon with at least 3 vertices",
            "GeoMath.PointInPolygon2D"
        )
        return nil
    end

    local x, east = point.x, GeoMathInternal.groundEast(point)
    if not GeoMathInternal.isFiniteNumber(x) or east == nil then
        _HarnessInternal.log.error(
            "PointInPolygon2D requires a DCS Vec2 or Vec3 point",
            "GeoMath.PointInPolygon2D"
        )
        return nil
    end
    local inside = false

    local p1x, p1East = polygon[1].x, GeoMathInternal.groundEast(polygon[1])
    if type(p1x) ~= "number" or p1East == nil then
        return nil
    end

    for i = 1, #polygon do
        local nextPoint = polygon[i % #polygon + 1]
        local p2x, p2East = nextPoint.x, GeoMathInternal.groundEast(nextPoint)
        if type(p2x) ~= "number" or p2East == nil then
            return nil
        end

        if
            east > math.min(p1East, p2East)
            and east <= math.max(p1East, p2East)
            and x <= math.max(p1x, p2x)
        then
            if p1East ~= p2East then
                local xinters = (east - p1East) * (p2x - p1x) / (p2East - p1East) + p1x
                if p1x == p2x or x <= xinters then
                    inside = not inside
                end
            end
        end

        p1x, p1East = p2x, p2East
    end

    return inside
end

function CircleLineIntersection2D(circleCenter, radius, lineStart, lineEnd)
    if not circleCenter or not radius or not lineStart or not lineEnd then
        _HarnessInternal.log.error(
            "CircleLineIntersection2D requires all parameters",
            "GeoMath.CircleLineIntersection2D"
        )
        return nil
    end

    local centerEast = GeoMathInternal.groundEast(circleCenter)
    local lineStartEast = GeoMathInternal.groundEast(lineStart)
    local lineEndEast = GeoMathInternal.groundEast(lineEnd)
    if centerEast == nil or lineStartEast == nil or lineEndEast == nil then
        _HarnessInternal.log.error(
            "CircleLineIntersection2D requires DCS Vec2 or Vec3 points",
            "GeoMath.CircleLineIntersection2D"
        )
        return nil
    end

    local dx = lineEnd.x - lineStart.x
    local de = lineEndEast - lineStartEast
    local fx = lineStart.x - circleCenter.x
    local fe = lineStartEast - centerEast

    local a = dx * dx + de * de
    local b = 2 * (fx * dx + fe * de)
    local c = (fx * fx + fe * fe) - radius * radius

    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return {} -- No intersection
    end

    local discriminantSqrt = math.sqrt(discriminant)
    local t1 = (-b - discriminantSqrt) / (2 * a)
    local t2 = (-b + discriminantSqrt) / (2 * a)

    local intersections = {}

    if t1 >= 0 and t1 <= 1 then
        table.insert(
            intersections,
            GeoMathInternal.groundResult(lineStart, lineStart.x + t1 * dx, lineStartEast + t1 * de)
        )
    end

    if t2 >= 0 and t2 <= 1 and math.abs(t2 - t1) > 1e-6 then
        table.insert(
            intersections,
            GeoMathInternal.groundResult(lineStart, lineStart.x + t2 * dx, lineStartEast + t2 * de)
        )
    end

    return intersections
end

function PolygonArea2D(polygon)
    if not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error(
            "PolygonArea2D requires polygon with at least 3 vertices",
            "GeoMath.PolygonArea2D"
        )
        return nil
    end

    local area = 0
    local n = #polygon

    for i = 1, n do
        local j = (i % n) + 1
        local currentEast = GeoMathInternal.groundEast(polygon[i])
        local nextEast = GeoMathInternal.groundEast(polygon[j])
        if currentEast == nil or nextEast == nil then
            return nil
        end
        area = area + polygon[i].x * nextEast
        area = area - polygon[j].x * currentEast
    end

    return math.abs(area) / 2
end

function PolygonCentroid2D(polygon)
    if not polygon or type(polygon) ~= "table" or #polygon < 3 then
        _HarnessInternal.log.error(
            "PolygonCentroid2D requires polygon with at least 3 vertices",
            "GeoMath.PolygonCentroid2D"
        )
        return nil
    end

    local cx, ce = 0, 0
    local area = 0

    for i = 1, #polygon do
        local j = (i % #polygon) + 1
        local currentEast = GeoMathInternal.groundEast(polygon[i])
        local nextEast = GeoMathInternal.groundEast(polygon[j])
        if currentEast == nil or nextEast == nil then
            return nil
        end
        local a = polygon[i].x * nextEast - polygon[j].x * currentEast
        area = area + a
        cx = cx + (polygon[i].x + polygon[j].x) * a
        ce = ce + (currentEast + nextEast) * a
    end

    area = area / 2

    if math.abs(area) < 1e-6 then
        -- Degenerate polygon, return average of points
        for _, p in ipairs(polygon) do
            cx = cx + p.x
            ce = ce + GeoMathInternal.groundEast(p)
        end
        return GeoMathInternal.groundResult(polygon[1], cx / #polygon, ce / #polygon, 0)
    end

    return GeoMathInternal.groundResult(polygon[1], cx / (6 * area), ce / (6 * area), 0)
end

function ConvexHull2D(points)
    if not points or type(points) ~= "table" or #points < 3 then
        _HarnessInternal.log.error(
            "ConvexHull2D requires at least 3 points",
            "GeoMath.ConvexHull2D"
        )
        return points or {}
    end

    -- Find the leftmost point
    local start = 1
    for i = 2, #points do
        if
            points[i].x < points[start].x
            or (
                points[i].x == points[start].x
                and GeoMathInternal.groundEast(points[i])
                    < GeoMathInternal.groundEast(points[start])
            )
        then
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
                    local cross = (points[i].x - points[current].x)
                            * (GeoMathInternal.groundEast(points[next]) - GeoMathInternal.groundEast(
                                points[current]
                            ))
                        - (
                                GeoMathInternal.groundEast(points[i])
                                - GeoMathInternal.groundEast(points[current])
                            )
                            * (points[next].x - points[current].x)

                    if
                        cross > 0
                        or (
                            cross == 0
                            and Distance2D(points[current], points[i])
                                > Distance2D(points[current], points[next])
                        )
                    then
                        next = i
                    end
                end
            end
        end

        current = next
    until current == start

    return hull
end

-- ==================== Closest Point of Approach (CPA) Utilities ====================

--- Estimate time of closest approach between a moving point and a fixed point (2D)
---@param pos table Vec3 current position
---@param vel table Vec3 velocity vector
---@param target table Vec3 target point
---@return number tStar Time in seconds to closest approach (>= 0)
---@return number distanceAtT Minimum distance at tStar (meters)
---@return table pointAtT Pos at tStar
function EstimateCPAToPoint(pos, vel, target)
    if not pos or not vel or not target then
        _HarnessInternal.log.error(
            "EstimateCPAToPoint requires pos, vel, target",
            "GeoMath.CPA.Point"
        )
        return 0, math.huge, pos
    end
    local rx = ((pos and pos.x) or 0) - ((target and target.x) or 0)
    local rz = ((pos and pos.z) or 0) - ((target and target.z) or 0)
    local vx = (vel and vel.x) or 0
    local vz = (vel and vel.z) or 0
    local v2 = vx * vx + vz * vz
    local tStar = 0
    if v2 > 1e-9 then
        tStar = math.max(0, -((rx * vx + rz * vz) / v2))
    end
    local px = ((pos and pos.x) or 0) + vx * tStar
    local pz = ((pos and pos.z) or 0) + vz * tStar
    local dx = px - ((target and target.x) or 0)
    local dz = pz - ((target and target.z) or 0)
    local d = math.sqrt(dx * dx + dz * dz)
    return tStar, d, { x = px, y = pos.y or 0, z = pz }
end

--- Estimate CPA to a circle region
---@param pos table Vec3 position
---@param vel table Vec3 velocity
---@param center table Vec3 center
---@param radius number radius meters
---@return number tEntry Time when path first reaches minimum distance
---@return number distanceAtT Minimum distance at tEntry
---@return table pointAtT Position at tEntry
function EstimateCPAToCircle(pos, vel, center, radius)
    local r = radius or 0
    local vx = (vel and vel.x) or 0
    local vz = (vel and vel.z) or 0
    local fx = ((pos and pos.x) or 0) - ((center and center.x) or 0)
    local fz = ((pos and pos.z) or 0) - ((center and center.z) or 0)
    local a = vx * vx + vz * vz
    local b = 2 * (fx * vx + fz * vz)
    local c = (fx * fx + fz * fz) - r * r

    if a > 1e-12 then
        local disc = b * b - 4 * a * c
        if disc >= 0 then
            local sqrtDisc = math.sqrt(disc)
            local t1 = (-b - sqrtDisc) / (2 * a)
            local t2 = (-b + sqrtDisc) / (2 * a)
            local tEntry = math.huge
            if t1 >= 0 then
                tEntry = math.min(tEntry, t1)
            end
            if t2 >= 0 then
                tEntry = math.min(tEntry, t2)
            end
            if tEntry < math.huge then
                local px = (((pos and pos.x) or 0) + vx * tEntry)
                local pz = (((pos and pos.z) or 0) + vz * tEntry)
                return tEntry, 0, { x = px, y = (pos and pos.y) or 0, z = pz }
            end
        end
    end

    -- Fallback to CPA to center if no intersection
    local tStar, d, p = EstimateCPAToPoint(pos, vel, center)
    return tStar, math.max(0, d - r), p
end

--- Estimate CPA to a polygon (2D). Approximates by CPA to edges and vertices.
---@param pos table Vec3 position
---@param vel table Vec3 velocity
---@param polygon table Array of Vec3 points
---@return number tStar Time of closest approach
---@return number distanceAtT Minimum distance to polygon boundary
---@return table pointAtT Position at tStar
function EstimateCPAToPolygon(pos, vel, polygon)
    if not polygon or #polygon == 0 then
        return EstimateCPAToPoint(pos, vel, pos)
    end
    local bestT, bestD, bestP = math.huge, math.huge, pos
    -- Check vertices
    for i = 1, #polygon do
        local t, d, p = EstimateCPAToPoint(pos, vel, polygon[i])
        if d < bestD or (math.abs(d - bestD) < 1e-6 and t < bestT) then
            bestD, bestT, bestP = d, t, p
        end
    end
    -- Check edges by projecting CPA point onto segments at time tStar
    -- Sample a few times near bestT to improve robustness
    local samples = { math.max(0, bestT - 5), bestT, bestT + 5 }
    for _, t in ipairs(samples) do
        local px = (((pos and pos.x) or 0) + (((vel and vel.x) or 0) * t))
        local pz = (((pos and pos.z) or 0) + (((vel and vel.z) or 0) * t))
        for i = 1, #polygon do
            local j = (i % #polygon) + 1
            local ax, az = (polygon[i].x or 0), (polygon[i].z or 0)
            local bx, bz = (polygon[j].x or 0), (polygon[j].z or 0)
            local abx, abz = bx - ax, bz - az
            local apx, apz = px - ax, pz - az
            local ab2 = abx * abx + abz * abz
            local u = 0
            if ab2 > 1e-9 then
                u = math.max(0, math.min(1, (apx * abx + apz * abz) / ab2))
            end
            local cx = ax + u * abx
            local cz = az + u * abz
            local dx = px - cx
            local dz = pz - cz
            local d = math.sqrt(dx * dx + dz * dz)
            if d < bestD or (math.abs(d - bestD) < 1e-6 and t < bestT) then
                bestD, bestT, bestP = d, t, { x = px, y = (pos and pos.y) or 0, z = pz }
            end
        end
    end
    return bestT, bestD, bestP
end

--- Two-body closest point of approach (relative motion, 2D)
---@param posA table Vec3 position
---@param velA table Vec3 velocity
---@param posB table Vec3 position
---@param velB table Vec3 velocity
---@return number tStar Time of closest approach (>=0)
---@return number distanceAtT Distance at tStar
---@return table aAtT Position A at tStar
---@return table bAtT Position B at tStar
function EstimateTwoBodyCPA(posA, velA, posB, velB)
    if not posA or not velA or not posB or not velB then
        _HarnessInternal.log.error(
            "EstimateTwoBodyCPA requires posA, velA, posB, velB",
            "GeoMath.CPA.TwoBody"
        )
        return 0, math.huge, posA, posB
    end
    local rx = GeoMathInternal.componentOrZero(posA, "x")
        - GeoMathInternal.componentOrZero(posB, "x")
    local rz = GeoMathInternal.componentOrZero(posA, "z")
        - GeoMathInternal.componentOrZero(posB, "z")
    local vx = GeoMathInternal.componentOrZero(velA, "x")
        - GeoMathInternal.componentOrZero(velB, "x")
    local vz = GeoMathInternal.componentOrZero(velA, "z")
        - GeoMathInternal.componentOrZero(velB, "z")
    local v2 = vx * vx + vz * vz
    local tStar = 0
    if v2 > 1e-9 then
        tStar = math.max(0, -((rx * vx + rz * vz) / v2))
    end
    local aAtT = GeoMathInternal.horizontalPositionAtTime(posA, velA, tStar)
    local bAtT = GeoMathInternal.horizontalPositionAtTime(posB, velB, tStar)
    return tStar, Distance2D(aAtT, bAtT), aAtT, bAtT
end

-- ==================== Intercept Solvers ====================

--- Solve intercept for a pursuer with fixed speed (2D x/z)
---@param posA table Vec3 pursuer current position
---@param speedA number pursuer speed (m/s)
---@param posB table Vec3 target current position
---@param velB table Vec3 target velocity
---@return number|nil tIntercept Time to intercept (seconds) or nil if no solution
---@return table|nil interceptPoint Intercept point {x,y,z} at time t
---@return table|nil requiredVelocity Required pursuer velocity vector {x,y,z}
function EstimateInterceptForSpeed(posA, speedA, posB, velB)
    if not posA or not posB or type(speedA) ~= "number" or not velB then
        _HarnessInternal.log.error(
            "EstimateInterceptForSpeed requires posA, speedA, posB, velB",
            "GeoMath.Intercept"
        )
        return nil, nil, nil
    end

    local posAX = GeoMathInternal.componentOrZero(posA, "x")
    local posAY = GeoMathInternal.componentOrZero(posA, "y")
    local posAZ = GeoMathInternal.componentOrZero(posA, "z")
    local posBX = GeoMathInternal.componentOrZero(posB, "x")
    local posBZ = GeoMathInternal.componentOrZero(posB, "z")
    local vX = GeoMathInternal.componentOrZero(velB, "x")
    local vZ = GeoMathInternal.componentOrZero(velB, "z")
    local rX = posBX - posAX
    local rZ = posBZ - posAZ
    local s = speedA

    local a = vX * vX + vZ * vZ - s * s
    local b = 2 * (rX * vX + rZ * vZ)
    local c = rX * rX + rZ * rZ

    local eps = 1e-9
    local t = GeoMathInternal.smallestNonnegativeRoot(a, b, c, eps)
    if t == nil then
        return nil, nil, nil
    end

    local interceptX = posBX + vX * t
    local interceptZ = posBZ + vZ * t
    local dx = interceptX - posAX
    local dz = interceptZ - posAZ
    local reqVX, reqVZ
    if t > eps then
        reqVX = dx / t
        reqVZ = dz / t
    else
        reqVX = 0
        reqVZ = 0
    end
    local mag = math.sqrt(reqVX * reqVX + reqVZ * reqVZ)
    if mag > eps and s > 0 then
        reqVX = reqVX * (s / mag)
        reqVZ = reqVZ * (s / mag)
    end

    return t, { x = interceptX, y = posAY, z = interceptZ }, { x = reqVX, y = posAY, z = reqVZ }
end

--- Compute delta-velocity required for A to intercept B at given speed
---@param posA table Vec3 position
---@param velA table Vec3 velocity
---@param posB table Vec3 position
---@param velB table Vec3 velocity
---@param speedA number? If provided, solve using this speed; otherwise use |requiredVelocity|
---@return table|nil deltaV Vector {x,y,z} to add to velA; nil if no solution
---@return number|nil tIntercept Time to intercept
---@return table|nil interceptPoint Intercept position
---@return table|nil requiredVelocity Velocity vector needed
function EstimateInterceptDeltaV(posA, velA, posB, velB, speedA)
    if type(speedA) == "number" then
        local t, p, reqV = EstimateInterceptForSpeed(posA, speedA, posB, velB)
        if not t then
            return nil, nil, nil, nil
        end
        local dV = {
            x = (reqV.x or 0) - ((velA and velA.x) or 0),
            y = (reqV.y or 0) - ((velA and velA.y) or 0),
            z = (reqV.z or 0) - ((velA and velA.z) or 0),
        }
        return dV, t, p, reqV
    else
        -- If speed not provided, derive from solution magnitude
        local vAx = (velA and velA.x) or 0
        local vAz = (velA and velA.z) or 0
        local speedGuess = math.sqrt(vAx * vAx + vAz * vAz)
        -- If stationary, use distance/time heuristic by assuming time from CPA to point
        if speedGuess < 1e-6 then
            speedGuess = 1
        end
        local t, p, reqV = EstimateInterceptForSpeed(posA, speedGuess, posB, velB)
        if not t then
            return nil, nil, nil, nil
        end
        local dV = {
            x = (reqV.x or 0) - vAx,
            y = (reqV.y or 0) - ((velA and velA.y) or 0),
            z = (reqV.z or 0) - vAz,
        }
        return dV, t, p, reqV
    end
end
