require("logger")
require("vector")

local ObjectInternal = {}

function ObjectInternal.readMethod(object, method, caller)
    local ok, value = pcall(function()
        return object[method](object)
    end)
    if not ok then
        _HarnessInternal.log.error(
            "Failed to read object: " .. _HarnessInternal.safeString(value),
            caller
        )
        return nil
    end
    return value
end

function ObjectInternal.readVector(object, method, caller)
    local value = ObjectInternal.readMethod(object, method, caller)
    local ok, copy = pcall(function()
        if type(value) == "table" then
            local result = { x = value.x, y = value.y, z = value.z }
            if IsFiniteVec3(result) then
                return result
            end
        end
    end)
    if not ok or not copy then
        _HarnessInternal.log.error("Object returned an invalid finite Vec3", caller)
        return nil
    end
    return copy
end

--- Get the ID carried by a detected unit or weapon.
---@param object table|userdata The detected unit or weapon object.
---@return number|string? id The object's id_ value, or nil if it cannot be read or is invalid.
---@usage local id = GetObjectID(detection.object)
function GetObjectID(object)
    local ok, id = pcall(function()
        return object.id_
    end)
    if ok and (IsFiniteNumber(id) or (type(id) == "string" and id ~= "")) then
        return id
    end
    _HarnessInternal.log.error(
        "Failed to read detected-object identity: " .. _HarnessInternal.safeString(id),
        "GetObjectID"
    )
    return nil
end

--- Get the DCS object category of a unit or weapon.
---@param object table|userdata The unit or weapon object.
---@return number? category An Object.Category value, or nil if it cannot be read.
---@usage local category = GetObjectCategory(detection.object)
function GetObjectCategory(object)
    local category = ObjectInternal.readMethod(object, "getCategory", "GetObjectCategory")
    if IsFiniteNumber(category) then
        return category
    end
    return nil
end

--- Get the position of a unit or weapon.
--- The result is a new {x, y, z} table in meters. Y is altitude.
---@param object table|userdata The unit or weapon object.
---@return Vec3? point Position, or nil if it cannot be read or has invalid numbers.
---@usage local position = GetObjectPoint(detection.object)
function GetObjectPoint(object)
    return ObjectInternal.readVector(object, "getPoint", "GetObjectPoint")
end

--- Get the velocity of a unit or weapon.
--- The result is a new {x, y, z} table in meters per second.
---@param object table|userdata The unit or weapon object.
---@return Vec3? velocity Velocity, or nil if it cannot be read or has invalid numbers.
---@usage local velocity = GetObjectVelocity(detection.object)
function GetObjectVelocity(object)
    return ObjectInternal.readVector(object, "getVelocity", "GetObjectVelocity")
end
