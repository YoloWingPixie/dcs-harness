--[[
==================================================================================================
    VECTOR MODULE
    Vector types, operations, and utilities
==================================================================================================
]]

-- Vec2 Type Definition with metatables for operator overloading
local Vec2_mt = {}
Vec2_mt.__index = Vec2_mt

--- Creates a 2D vector (x, z coordinates)
---@param x number|table? X coordinate or table {x, z} or {[1], [2]}
---@param z number? Z coordinate (if x is not a table)
---@return table vec2 New Vec2 instance with metatables
---@usage local v = Vec2(100, 200) or Vec2({x=100, z=200})
function Vec2(x, z)
    if type(x) == "table" then
        -- Handle table input {x=1, z=2} or {1, 2} or {x=1, y=2} for DCS compat
        z = x.z or x.y or x[2] or 0
        x = x.x or x[1] or 0
    end
    
    local self = {
        x = x or 0,
        z = z or 0
    }
    
    setmetatable(self, Vec2_mt)
    return self
end

-- Vec3 Type Definition with metatables for operator overloading
local Vec3_mt = {}
Vec3_mt.__index = Vec3_mt

--- Creates a 3D vector (x, y, z coordinates)
---@param x number|table? X coordinate or table {x, y, z} or {[1], [2], [3]}
---@param y number? Y coordinate (if x is not a table)
---@param z number? Z coordinate (if x is not a table)
---@return table vec3 New Vec3 instance with metatables
---@usage local v = Vec3(100, 50, 200) or Vec3({x=100, y=50, z=200})
function Vec3(x, y, z)
    if type(x) == "table" then
        -- Handle table input {x=1, y=2, z=3} or {1, 2, 3}
        z = x.z or x[3] or 0
        y = x.y or x[2] or 0
        x = x.x or x[1] or 0
    end
    
    local self = {
        x = x or 0,
        y = y or 0,
        z = z or 0
    }
    
    setmetatable(self, Vec3_mt)
    return self
end

-- Type checking functions
--- Check if valid 3D vector (works with plain tables or Vec3 instances)
---@param vec any Value to check
---@return boolean isValid True if vec has numeric x, y, z components
---@usage if IsVec3(pos) then ... end
function IsVec3(vec)
    if not vec or type(vec) ~= "table" then
        return false
    end
    return type(vec.x) == "number" and 
           type(vec.y) == "number" and 
           type(vec.z) == "number"
end

--- Check if valid 2D vector (works with plain tables or Vec2 instances)
---@param vec any Value to check
---@return boolean isValid True if vec has numeric x, z components (or x, y for DCS compat)
---@usage if IsVec2(pos) then ... end
function IsVec2(vec)
    if not vec or type(vec) ~= "table" then
        return false
    end
    -- Support both x,z and x,y formats
    return type(vec.x) == "number" and 
           (type(vec.z) == "number" or type(vec.y) == "number")
end

-- Conversion functions
--- Convert to Vec2 (from table, Vec2, or Vec3)
---@param t any Input value to convert
---@return table? vec2 Converted Vec2 or nil on error
---@usage local v2 = ToVec2({x=100, z=200})
function ToVec2(t)
    if not t then return nil end
    
    if getmetatable(t) == Vec2_mt then
        return t
    elseif getmetatable(t) == Vec3_mt then
        return Vec2(t.x, t.z)
    elseif type(t) == "table" then
        -- Support both {x,z} and {x,y} formats
        local z = t.z or t.y or t[2]
        return Vec2(t.x or t[1], z)
    else
        _HarnessInternal.log.error("ToVec2 requires table or vector type", "Vector.ToVec2")
        return nil
    end
end

--- Convert to Vec3 (from table, Vec2, or Vec3)
---@param t any Input value to convert
---@param altitude number? Y coordinate for Vec2 to Vec3 conversion (default 0)
---@return table? vec3 Converted Vec3 or nil on error
---@usage local v3 = ToVec3({x=100, y=50, z=200})
function ToVec3(t, altitude)
    if not t then return nil end
    
    if getmetatable(t) == Vec3_mt then
        return t
    elseif getmetatable(t) == Vec2_mt then
        return Vec3(t.x, altitude or 0, t.z)
    elseif type(t) == "table" then
        if t.y then
            -- Already has y component
            return Vec3(t.x or t[1], t.y or t[2], t.z or t[3])
        else
            -- Vec2-like table, use altitude parameter
            return Vec3(t.x or t[1], altitude or 0, t.z or t[2])
        end
    else
        _HarnessInternal.log.error("ToVec3 requires table or vector type", "Vector.ToVec3")
        return nil
    end
end

-- Basic vector operations (work with both plain tables and vector types)
--- Add vectors
---@param a table First vector
---@param b table Second vector
---@return table result Vector sum of a + b
---@usage local sum = VecAdd(v1, v2)
function VecAdd(a, b)
    if IsVec3(a) and IsVec3(b) then
        return Vec3(a.x + b.x, a.y + b.y, a.z + b.z)
    elseif IsVec2(a) and IsVec2(b) then
        return Vec2(a.x + b.x, (a.z or a.y) + (b.z or b.y))
    else
        _HarnessInternal.log.error("VecAdd requires two valid vectors of same type", "Vector.VecAdd")
        return Vec3()
    end
end

--- Subtract vectors
---@param a table First vector
---@param b table Second vector
---@return table result Vector difference of a - b
---@usage local diff = VecSub(v1, v2)
function VecSub(a, b)
    if IsVec3(a) and IsVec3(b) then
        return Vec3(a.x - b.x, a.y - b.y, a.z - b.z)
    elseif IsVec2(a) and IsVec2(b) then
        return Vec2(a.x - b.x, (a.z or a.y) - (b.z or b.y))
    else
        _HarnessInternal.log.error("VecSub requires two valid vectors of same type", "Vector.VecSub")
        return Vec3()
    end
end

--- Multiply vector by scalar
---@param vec table Vector to scale
---@param scalar number Scale factor
---@return table result Scaled vector
---@usage local scaled = VecScale(v, 2.5)
function VecScale(vec, scalar)
    if type(scalar) ~= "number" then
        _HarnessInternal.log.error("VecScale requires valid vector and number", "Vector.VecScale")
        return Vec3()
    end
    
    if IsVec3(vec) then
        return Vec3(vec.x * scalar, vec.y * scalar, vec.z * scalar)
    elseif IsVec2(vec) then
        return Vec2(vec.x * scalar, (vec.z or vec.y) * scalar)
    else
        _HarnessInternal.log.error("VecScale requires valid vector", "Vector.VecScale")
        return Vec3()
    end
end

--- Divide vector by scalar
---@param vec table Vector to divide
---@param scalar number Divisor (must not be 0)
---@return table result Divided vector
---@usage local divided = VecDiv(v, 2)
function VecDiv(vec, scalar)
    if type(scalar) ~= "number" or scalar == 0 then
        _HarnessInternal.log.error("VecDiv requires valid vector and non-zero number", "Vector.VecDiv")
        return IsVec3(vec) and Vec3() or Vec2()
    end
    
    return VecScale(vec, 1 / scalar)
end

--- Get vector length
---@param vec table Vector
---@return number length 3D length/magnitude
---@usage local len = VecLength(v)
function VecLength(vec)
    if IsVec3(vec) then
        return math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    elseif IsVec2(vec) then
        local z = vec.z or vec.y
        return math.sqrt(vec.x * vec.x + z * z)
    else
        _HarnessInternal.log.error("VecLength requires valid vector", "Vector.VecLength")
        return 0
    end
end

--- Get 2D vector length (ignoring Y)
---@param vec table Vector
---@return number length 2D length in XZ plane
---@usage local len2d = VecLength2D(v)
function VecLength2D(vec)
    if not vec or type(vec) ~= "table" then
        _HarnessInternal.log.error("VecLength2D requires valid vector", "Vector.VecLength2D")
        return 0
    end
    
    local z = vec.z or vec.y or 0
    return math.sqrt(vec.x * vec.x + z * z)
end

--- Normalize vector
---@param vec table Vector to normalize
---@return table normalized Unit vector (length 1) or zero vector
---@usage local unit = VecNormalize(v)
function VecNormalize(vec)
    local length = VecLength(vec)
    if length == 0 then
        return IsVec3(vec) and Vec3() or Vec2()
    end
    
    return VecScale(vec, 1 / length)
end

--- Normalize 2D vector (preserving Y)
---@param vec table Vec3 to normalize in XZ plane
---@return table normalized Vec3 with unit XZ, preserved Y
---@usage local unit2d = VecNormalize2D(v)
function VecNormalize2D(vec)
    if not IsVec3(vec) then
        _HarnessInternal.log.error("VecNormalize2D requires valid Vec3", "Vector.VecNormalize2D")
        return Vec3()
    end
    
    local length = VecLength2D(vec)
    if length == 0 then
        return Vec3(0, vec.y, 0)
    end
    
    return Vec3(vec.x / length, vec.y, vec.z / length)
end

--- Dot product
---@param a table First vector
---@param b table Second vector
---@return number dot Dot product a·b
---@usage local dot = VecDot(v1, v2)
function VecDot(a, b)
    if IsVec3(a) and IsVec3(b) then
        return a.x * b.x + a.y * b.y + a.z * b.z
    elseif IsVec2(a) and IsVec2(b) then
        return a.x * b.x + (a.z or a.y) * (b.z or b.y)
    else
        _HarnessInternal.log.error("VecDot requires two valid vectors of same type", "Vector.VecDot")
        return 0
    end
end

--- Cross product (3D only)
---@param a table First Vec3
---@param b table Second Vec3
---@return table cross Vec3 cross product a×b
---@usage local cross = VecCross(v1, v2)
function VecCross(a, b)
    if not IsVec3(a) or not IsVec3(b) then
        _HarnessInternal.log.error("VecCross requires two valid Vec3", "Vector.VecCross")
        return Vec3()
    end
    
    return Vec3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
end

--- Get distance between two points
---@param a table First position
---@param b table Second position
---@return number distance 3D distance
---@usage local dist = Distance(pos1, pos2)
function Distance(a, b)
    if IsVec3(a) and IsVec3(b) then
        local dx = b.x - a.x
        local dy = b.y - a.y
        local dz = b.z - a.z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    else
        return Distance2D(a, b)
    end
end

--- Get 2D distance between two points
---@param a table First position
---@param b table Second position
---@return number distance 2D distance in XZ plane
---@usage local dist2d = Distance2D(pos1, pos2)
function Distance2D(a, b)
    if not a or not b or type(a) ~= "table" or type(b) ~= "table" then
        _HarnessInternal.log.error("Distance2D requires two valid positions", "Vector.Distance2D")
        return 0
    end
    
    local dx = b.x - a.x
    local az = a.z or a.y or 0
    local bz = b.z or b.y or 0
    local dz = bz - az
    return math.sqrt(dx * dx + dz * dz)
end

--- Get squared distance (avoids sqrt)
---@param a table First position
---@param b table Second position
---@return number distanceSquared 3D distance squared
---@usage local distSq = DistanceSquared(pos1, pos2)
function DistanceSquared(a, b)
    if not IsVec3(a) or not IsVec3(b) then
        _HarnessInternal.log.error("DistanceSquared requires two valid Vec3", "Vector.DistanceSquared")
        return 0
    end
    
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dz = b.z - a.z
    return dx * dx + dy * dy + dz * dz
end

--- Get squared 2D distance
---@param a table First position
---@param b table Second position
---@return number distanceSquared 2D distance squared in XZ plane
---@usage local dist2dSq = Distance2DSquared(pos1, pos2)
function Distance2DSquared(a, b)
    if not a or not b or type(a) ~= "table" or type(b) ~= "table" then
        _HarnessInternal.log.error("Distance2DSquared requires two valid positions", "Vector.Distance2DSquared")
        return 0
    end
    
    local dx = b.x - a.x
    local az = a.z or a.y or 0
    local bz = b.z or b.y or 0
    local dz = bz - az
    return dx * dx + dz * dz
end

--- Get bearing from one point to another (degrees)
---@param from table Source position
---@param to table Target position
---@return number bearing Bearing in degrees (0-360)
---@usage local bearing = Bearing(myPos, targetPos)
function Bearing(from, to)
    if not from or not to or type(from) ~= "table" or type(to) ~= "table" then
        _HarnessInternal.log.error("Bearing requires two valid positions", "Vector.Bearing")
        return 0
    end
    
    local dx = to.x - from.x
    local fz = from.z or from.y or 0
    local tz = to.z or to.y or 0
    local dz = tz - fz
    local bearing = math.atan2(dx, dz) * 180 / math.pi
    
    if bearing < 0 then
        bearing = bearing + 360
    end
    
    return bearing
end

--- Get position from bearing and distance
---@param origin table Origin position
---@param bearing number Bearing in degrees
---@param distance number Distance in meters
---@return table position New position
---@usage local newPos = FromBearingDistance(pos, 45, 1000)
function FromBearingDistance(origin, bearing, distance)
    if not origin or type(origin) ~= "table" or type(bearing) ~= "number" or type(distance) ~= "number" then
        _HarnessInternal.log.error("FromBearingDistance requires origin, bearing, and distance", "Vector.FromBearingDistance")
        return Vec3()
    end
    
    local angle = bearing * math.pi / 180
    local dx = distance * math.sin(angle)
    local dz = distance * math.cos(angle)
    
    if IsVec3(origin) then
        return Vec3(origin.x + dx, origin.y, origin.z + dz)
    else
        local oz = origin.z or origin.y or 0
        return Vec2(origin.x + dx, oz + dz)
    end
end

--- Get angle between vectors (degrees)
---@param a table First vector
---@param b table Second vector
---@return number angle Angle in degrees (0-180)
---@usage local angle = AngleBetween(v1, v2)
function AngleBetween(a, b)
    local normA = VecNormalize(a)
    local normB = VecNormalize(b)
    local dot = VecDot(normA, normB)
    
    -- Clamp to avoid floating point errors with acos
    dot = math.max(-1, math.min(1, dot))
    
    return math.acos(dot) * 180 / math.pi
end

--- Get midpoint between two points
---@param a table First position
---@param b table Second position
---@return table midpoint Position at center between a and b
---@usage local mid = Midpoint(pos1, pos2)
function Midpoint(a, b)
    if IsVec3(a) and IsVec3(b) then
        return Vec3(
            (a.x + b.x) / 2,
            (a.y + b.y) / 2,
            (a.z + b.z) / 2
        )
    elseif IsVec2(a) and IsVec2(b) then
        return Vec2(
            (a.x + b.x) / 2,
            ((a.z or a.y) + (b.z or b.y)) / 2
        )
    else
        _HarnessInternal.log.error("Midpoint requires two valid vectors of same type", "Vector.Midpoint")
        return Vec3()
    end
end

--- Linear interpolation between vectors
---@param a table Start vector
---@param b table End vector
---@param t number Interpolation factor (0 to 1)
---@return table interpolated Vector between a and b
---@usage local interp = VecLerp(v1, v2, 0.5)
function VecLerp(a, b, t)
    if type(t) ~= "number" then
        _HarnessInternal.log.error("VecLerp requires number for t", "Vector.VecLerp")
        return a
    end
    
    if IsVec3(a) and IsVec3(b) then
        return Vec3(
            a.x + (b.x - a.x) * t,
            a.y + (b.y - a.y) * t,
            a.z + (b.z - a.z) * t
        )
    elseif IsVec2(a) and IsVec2(b) then
        return Vec2(
            a.x + (b.x - a.x) * t,
            (a.z or a.y) + ((b.z or b.y) - (a.z or a.y)) * t
        )
    else
        _HarnessInternal.log.error("VecLerp requires two valid vectors of same type", "Vector.VecLerp")
        return Vec3()
    end
end

--- Convert Vec3 to string for debugging
---@param vec table Vec3 to convert
---@param precision number? Decimal places (default 2)
---@return string formatted String representation "(x, y, z)"
---@usage print(Vec3ToString(pos, 1))
function Vec3ToString(vec, precision)
    if not IsVec3(vec) then
        return "(invalid)"
    end
    
    precision = precision or 2
    local format = "%." .. precision .. "f"
    
    return string.format("(" .. format .. ", " .. format .. ", " .. format .. ")", 
                        vec.x, vec.y, vec.z)
end

--- Convert Vec2 to string for debugging
---@param vec table Vec2 to convert
---@param precision number? Decimal places (default 2)
---@return string formatted String representation "(x, z)"
---@usage print(Vec2ToString(pos, 1))
function Vec2ToString(vec, precision)
    if not IsVec2(vec) then
        return "(invalid)"
    end
    
    precision = precision or 2
    local format = "%." .. precision .. "f"
    local z = vec.z or vec.y
    
    return string.format("(" .. format .. ", " .. format .. ")", vec.x, z)
end

-- Vec2 Methods (for metatabled instances)
--- Convert Vec2 to Vec3 with specified altitude
---@param y number? Y coordinate/altitude (default: 0)
---@return table vec3 New Vec3 instance
function Vec2_mt:toVec3(y)
    return Vec3(self.x, y or 0, self.z)
end

--- Get the length/magnitude of this Vec2
---@return number length 2D length
function Vec2_mt:length()
    return VecLength(self)
end

--- Get a normalized (unit) version of this Vec2
---@return table vec2 Normalized Vec2 with length 1
function Vec2_mt:normalized()
    return VecNormalize(self)
end

--- Calculate dot product with another Vec2
---@param other table Another Vec2
---@return number dot Dot product result
function Vec2_mt:dot(other)
    return VecDot(self, other)
end

--- Calculate distance to another Vec2
---@param other table Another Vec2 position
---@return number distance 2D distance in meters
function Vec2_mt:distanceTo(other)
    return Distance2D(self, other)
end

--- Calculate bearing to another Vec2
---@param other table Another Vec2 position
---@return number bearing Bearing in degrees (0-360)
function Vec2_mt:bearingTo(other)
    return Bearing(self, other)
end

--- Get position displaced by bearing and distance
---@param bearingDeg number Bearing in degrees
---@param distance number Distance in meters
---@return table vec2 New displaced position
function Vec2_mt:displace(bearingDeg, distance)
    return FromBearingDistance(self, bearingDeg, distance)
end

--- Get midpoint between this and another Vec2
---@param other table Another Vec2 position
---@return table vec2 Midpoint position
function Vec2_mt:midpointTo(other)
    return Midpoint(self, other)
end

--- Calculate angle between this and another Vec2
---@param other table Another Vec2
---@return number angle Angle in degrees (0-180)
function Vec2_mt:angleTo(other)
    return AngleBetween(self, other)
end

--- Rotate this Vec2 around origin by angle
---@param angleDeg number Rotation angle in degrees (positive = clockwise)
---@return table vec2 New rotated Vec2
function Vec2_mt:rotate(angleDeg)
    local angleRad = angleDeg * math.pi / 180
    local cos_a = math.cos(angleRad)
    local sin_a = math.sin(angleRad)
    return Vec2(self.x * cos_a - self.z * sin_a, self.x * sin_a + self.z * cos_a)
end

-- Vec2 Operators
function Vec2_mt.__add(a, b)
    return Vec2(a.x + b.x, a.z + b.z)
end

function Vec2_mt.__sub(a, b)
    return Vec2(a.x - b.x, a.z - b.z)
end

function Vec2_mt.__mul(a, b)
    if type(a) == "number" then
        return Vec2(a * b.x, a * b.z)
    elseif type(b) == "number" then
        return Vec2(a.x * b, a.z * b)
    else
        return Vec2(a.x * b.x, a.z * b.z)
    end
end

function Vec2_mt.__div(a, b)
    if type(b) == "number" then
        return Vec2(a.x / b, a.z / b)
    else
        return Vec2(a.x / b.x, a.z / b.z)
    end
end

function Vec2_mt.__unm(a)
    return Vec2(-a.x, -a.z)
end

function Vec2_mt.__eq(a, b)
    return math.abs(a.x - b.x) < 1e-6 and math.abs(a.z - b.z) < 1e-6
end

function Vec2_mt.__tostring(a)
    return string.format("Vec2(%.3f, %.3f)", a.x, a.z)
end

-- Vec3 Methods (for metatabled instances)
--- Convert Vec3 to Vec2 (drops Y coordinate)
---@return table vec2 New Vec2 with x and z from this Vec3
function Vec3_mt:toVec2()
    return Vec2(self.x, self.z)
end

--- Get the 3D length/magnitude of this Vec3
---@return number length 3D length
function Vec3_mt:length()
    return VecLength(self)
end

--- Get the 2D length/magnitude (ignoring Y)
---@return number length 2D length in XZ plane
function Vec3_mt:length2D()
    return VecLength2D(self)
end

--- Get a normalized (unit) version of this Vec3
---@return table vec3 Normalized Vec3 with length 1
function Vec3_mt:normalized()
    return VecNormalize(self)
end

--- Get a 2D normalized version (normalized in XZ plane, preserving Y)
---@return table vec3 Vec3 with unit XZ and preserved Y
function Vec3_mt:normalized2D()
    return VecNormalize2D(self)
end

--- Calculate dot product with another Vec3
---@param other table Another Vec3
---@return number dot Dot product result
function Vec3_mt:dot(other)
    return VecDot(self, other)
end

--- Calculate cross product with another Vec3
---@param other table Another Vec3
---@return table vec3 Cross product result
function Vec3_mt:cross(other)
    return VecCross(self, other)
end

--- Calculate 3D distance to another Vec3
---@param other table Another Vec3 position
---@return number distance 3D distance in meters
function Vec3_mt:distanceTo(other)
    return Distance(self, other)
end

--- Calculate 2D distance to another position (ignoring Y)
---@param other table Another position
---@return number distance 2D distance in XZ plane
function Vec3_mt:distance2DTo(other)
    return Distance2D(self, other)
end

--- Calculate bearing to another position
---@param other table Another position
---@return number bearing Bearing in degrees (0-360)
function Vec3_mt:bearingTo(other)
    return Bearing(self, other)
end

--- Get position displaced by bearing and distance (preserving Y)
---@param bearingDeg number Bearing in degrees
---@param distance number Distance in meters
---@return table vec3 New displaced position
function Vec3_mt:displace2D(bearingDeg, distance)
    return FromBearingDistance(self, bearingDeg, distance)
end

--- Get midpoint between this and another Vec3
---@param other table Another Vec3 position
---@return table vec3 Midpoint position
function Vec3_mt:midpointTo(other)
    return Midpoint(self, other)
end

--- Calculate angle between this and another Vec3
---@param other table Another Vec3
---@return number angle Angle in degrees (0-180)
function Vec3_mt:angleTo(other)
    return AngleBetween(self, other)
end

-- Vec3 Operators
function Vec3_mt.__add(a, b)
    return Vec3(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vec3_mt.__sub(a, b)
    return Vec3(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vec3_mt.__mul(a, b)
    if type(a) == "number" then
        return Vec3(a * b.x, a * b.y, a * b.z)
    elseif type(b) == "number" then
        return Vec3(a.x * b, a.y * b, a.z * b)
    else
        return Vec3(a.x * b.x, a.y * b.y, a.z * b.z)
    end
end

function Vec3_mt.__div(a, b)
    if type(b) == "number" then
        return Vec3(a.x / b, a.y / b, a.z / b)
    else
        return Vec3(a.x / b.x, a.y / b.y, a.z / b.z)
    end
end

function Vec3_mt.__unm(a)
    return Vec3(-a.x, -a.y, -a.z)
end

function Vec3_mt.__eq(a, b)
    return math.abs(a.x - b.x) < 1e-6 and 
           math.abs(a.y - b.y) < 1e-6 and 
           math.abs(a.z - b.z) < 1e-6
end

function Vec3_mt.__tostring(a)
    return string.format("Vec3(%.3f, %.3f, %.3f)", a.x, a.y, a.z)
end