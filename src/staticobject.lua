--[[
    StaticObject Module - DCS World Static Object API Wrappers
    
    This module provides validated wrapper functions for DCS static object operations,
    including object queries, destruction, and property access.
]]

require("logger")
require("coalition")

--- Gets a static object by its name
---@param name string The name of the static object
---@return table? staticObject The static object or nil if not found
---@usage local static = GetStaticByName("Warehouse01")
function GetStaticByName(name)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("GetStaticByName requires valid name string", "StaticObject.GetByName")
        return nil
    end

    local success, result = pcall(StaticObject.getByName, name)
    if not success then
        _HarnessInternal.log.error("Failed to get static object by name: " .. tostring(result), "StaticObject.GetByName")
        return nil
    end

    return result
end

--- Gets the ID of a static object
---@param staticObject table The static object
---@return number? id The ID of the static object or nil on error
---@usage local id = GetStaticID(staticObj)
function GetStaticID(staticObject) 
    if not staticObject then
        _HarnessInternal.log.error("GetStaticID requires valid static object", "StaticObject.GetID")
        return nil
    end

    local success, result = pcall(staticObject.getID, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object ID: " .. tostring(result), "StaticObject.GetID")
        return nil
    end

    return result
end

--- Gets the current life/health of a static object
---@param staticObject table The static object
---@return number? life The current life value or nil on error
---@usage local life = GetStaticLife(staticObj)
function GetStaticLife(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticLife requires valid static object", "StaticObject.GetLife")
        return nil
    end

    local success, result = pcall(staticObject.getLife, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object life: " .. tostring(result), "StaticObject.GetLife")
        return nil
    end

    return result
end

--- Gets the cargo display name of a static object
---@param staticObject table The static object
---@return string? displayName The cargo display name or nil on error
---@usage local cargoName = GetStaticCargoDisplayName(staticObj)
function GetStaticCargoDisplayName(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticCargoDisplayName requires valid static object", "StaticObject.GetCargoDisplayName")
        return nil
    end

    local success, result = pcall(staticObject.getCargoDisplayName, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get cargo display name: " .. tostring(result), "StaticObject.GetCargoDisplayName")
        return nil
    end

    return result
end

--- Gets the cargo weight of a static object
---@param staticObject table The static object
---@return number? weight The cargo weight in kg or nil on error
---@usage local weight = GetStaticCargoWeight(staticObj)
function GetStaticCargoWeight(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticCargoWeight requires valid static object", "StaticObject.GetCargoWeight")
        return nil
    end

    local success, result = pcall(staticObject.getCargoWeight, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get cargo weight: " .. tostring(result), "StaticObject.GetCargoWeight")
        return nil
    end

    return result
end

--- Destroys a static object
---@param staticObject table The static object to destroy
---@return boolean? success Returns true if successful, nil on error
---@usage DestroyStatic(staticObj)
function DestroyStatic(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("DestroyStatic requires valid static object", "StaticObject.Destroy")
        return nil
    end

    local success, result = pcall(staticObject.destroy, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to destroy static object: " .. tostring(result), "StaticObject.Destroy")
        return nil
    end

    return true
end

--- Gets the category of a static object
---@param staticObject table The static object
---@return number? category The object category or nil on error
---@usage local category = GetStaticCategory(staticObj)
function GetStaticCategory(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticCategory requires valid static object", "StaticObject.GetCategory")
        return nil
    end

    local success, result = pcall(staticObject.getCategory, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object category: " .. tostring(result), "StaticObject.GetCategory")
        return nil
    end

    return result
end

--- Gets the type name of a static object
---@param staticObject table The static object
---@return string? typeName The type name or nil on error
---@usage local typeName = GetStaticTypeName(staticObj)
function GetStaticTypeName(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticTypeName requires valid static object", "StaticObject.GetTypeName")
        return nil
    end

    local success, result = pcall(staticObject.getTypeName, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object type name: " .. tostring(result), "StaticObject.GetTypeName")
        return nil
    end

    return result
end

--- Gets the description of a static object
---@param staticObject table The static object
---@return table? desc The description table or nil on error
---@usage local desc = GetStaticDesc(staticObj)
function GetStaticDesc(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticDesc requires valid static object", "StaticObject.GetDesc")
        return nil
    end

    local success, result = pcall(staticObject.getDesc, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object description: " .. tostring(result), "StaticObject.GetDesc")
        return nil
    end

    return result
end

--- Checks if a static object exists
---@param staticObject table The static object to check
---@return boolean? exists Returns true if exists, false if not, nil on error
---@usage local exists = IsStaticExist(staticObj)
function IsStaticExist(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("IsStaticExist requires valid static object", "StaticObject.IsExist")
        return nil
    end

    local success, result = pcall(staticObject.isExist, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to check static object existence: " .. tostring(result), "StaticObject.IsExist")
        return nil
    end

    return result
end

--- Gets the coalition of a static object
---@param staticObject table The static object
---@return number? coalition The coalition ID or nil on error
---@usage local coalition = GetStaticCoalition(staticObj)
function GetStaticCoalition(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticCoalition requires valid static object", "StaticObject.GetCoalition")
        return nil
    end

    local success, result = pcall(staticObject.getCoalition, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object coalition: " .. tostring(result), "StaticObject.GetCoalition")
        return nil
    end

    return result
end

--- Gets the country of a static object
---@param staticObject table The static object
---@return number? country The country ID or nil on error
---@usage local country = GetStaticCountry(staticObj)
function GetStaticCountry(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticCountry requires valid static object", "StaticObject.GetCountry")
        return nil
    end

    local success, result = pcall(staticObject.getCountry, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object country: " .. tostring(result), "StaticObject.GetCountry")
        return nil
    end

    return result
end

--- Gets the 3D position point of a static object
---@param staticObject table The static object
---@return table? point Position table with x, y, z coordinates or nil on error
---@usage local point = GetStaticPoint(staticObj)
function GetStaticPoint(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticPoint requires valid static object", "StaticObject.GetPoint")
        return nil
    end

    local success, result = pcall(staticObject.getPoint, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object point: " .. tostring(result), "StaticObject.GetPoint")
        return nil
    end

    return result
end

--- Gets the position and orientation of a static object
---@param staticObject table The static object
---@return table? position Position table with p (point) and x,y,z vectors or nil on error
---@usage local pos = GetStaticPosition(staticObj)
function GetStaticPosition(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticPosition requires valid static object", "StaticObject.GetPosition")
        return nil
    end

    local success, result = pcall(staticObject.getPosition, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object position: " .. tostring(result), "StaticObject.GetPosition")
        return nil
    end

    return result
end

--- Gets the velocity vector of a static object
---@param staticObject table The static object
---@return table? velocity Velocity vector with x, y, z components or nil on error
---@usage local vel = GetStaticVelocity(staticObj)
function GetStaticVelocity(staticObject)
    if not staticObject then
        _HarnessInternal.log.error("GetStaticVelocity requires valid static object", "StaticObject.GetVelocity")
        return nil
    end

    local success, result = pcall(staticObject.getVelocity, staticObject)
    if not success then
        _HarnessInternal.log.error("Failed to get static object velocity: " .. tostring(result), "StaticObject.GetVelocity")
        return nil
    end

    return result
end

--- Creates a new static object
---@param staticData table Static object data table with type, x, y, country, etc.
---@return table? staticObject The created static object or nil on error
---@usage local static = CreateStaticObject({type="Warehouse", x=1000, y=2000, country=2})
function CreateStaticObject(staticData)
    if not staticData or type(staticData) ~= "table" then
        _HarnessInternal.log.error("CreateStaticObject requires valid static data table", "StaticObject.Create")
        return nil
    end

    if not staticData.type or type(staticData.type) ~= "string" then
        _HarnessInternal.log.error("CreateStaticObject requires valid type in static data", "StaticObject.Create")
        return nil
    end

    if not staticData.x or not staticData.y then
        _HarnessInternal.log.error("CreateStaticObject requires valid x and y coordinates", "StaticObject.Create")
        return nil
    end

    if not staticData.country or type(staticData.country) ~= "number" then
        _HarnessInternal.log.error("CreateStaticObject requires valid country ID", "StaticObject.Create")
        return nil
    end

    return AddCoalitionStaticObject(staticData.country, staticData)
end