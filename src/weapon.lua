--[[
    Weapon Module - DCS World Weapon API Wrappers
    
    This module provides validated wrapper functions for DCS weapon operations,
    including weapon tracking, target queries, and launcher information.
]]

require("logger")
-- require("vector")

--- Gets the type name of a weapon
---@param weapon table The weapon object
---@return string? typeName The weapon type name or nil on error
---@usage local typeName = GetWeaponTypeName(weapon)
function GetWeaponTypeName(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponTypeName requires valid weapon", "Weapon.GetTypeName")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getTypeName(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon type name: " .. _HarnessInternal.safeString(result),
            "Weapon.GetTypeName"
        )
        return nil
    end

    return result
end

--- Gets the description of a weapon
---@param weapon table The weapon object
---@return table? desc The weapon description table or nil on error
---@usage local desc = GetWeaponDesc(weapon)
function GetWeaponDesc(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponDesc requires valid weapon", "Weapon.GetDesc")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getDesc(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon description: " .. _HarnessInternal.safeString(result),
            "Weapon.GetDesc"
        )
        return nil
    end

    return result
end

--- Gets the launcher unit of a weapon
---@param weapon table The weapon object
---@return table? launcher The launcher unit object or nil on error
---@usage local launcher = GetWeaponLauncher(weapon)
function GetWeaponLauncher(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponLauncher requires valid weapon", "Weapon.GetLauncher")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getLauncher(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon launcher: " .. _HarnessInternal.safeString(result),
            "Weapon.GetLauncher"
        )
        return nil
    end

    return result
end

--- Gets the target of a weapon
---@param weapon table The weapon object
---@return table? target The target object or nil if no target
---@usage local target = GetWeaponTarget(weapon)
function GetWeaponTarget(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponTarget requires valid weapon", "Weapon.GetTarget")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getTarget(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon target: " .. _HarnessInternal.safeString(result),
            "Weapon.GetTarget"
        )
        return nil
    end

    return result
end

--- Gets the category of a weapon
---@param weapon table The weapon object
---@return number? category The weapon category or nil on error
---@usage local category = GetWeaponCategory(weapon)
function GetWeaponCategory(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponCategory requires valid weapon", "Weapon.GetCategory")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getCategory(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon category: " .. _HarnessInternal.safeString(result),
            "Weapon.GetCategory"
        )
        return nil
    end

    return result
end

--- Checks if a weapon exists
---@param weapon table The weapon object to check
---@return boolean? exists Returns true if exists, false if not, nil on error
---@usage local exists = IsWeaponExist(weapon)
function IsWeaponExist(weapon)
    if not weapon then
        _HarnessInternal.log.error("IsWeaponExist requires valid weapon", "Weapon.IsExist")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.isExist(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check weapon existence: " .. _HarnessInternal.safeString(result),
            "Weapon.IsExist"
        )
        return nil
    end

    return result
end

--- Gets the coalition of a weapon
---@param weapon table The weapon object
---@return number? coalition The coalition ID or nil on error
---@usage local coalition = GetWeaponCoalition(weapon)
function GetWeaponCoalition(weapon)
    if not weapon then
        _HarnessInternal.log.error(
            "GetWeaponCoalition requires valid weapon",
            "Weapon.GetCoalition"
        )
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getCoalition(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon coalition: " .. _HarnessInternal.safeString(result),
            "Weapon.GetCoalition"
        )
        return nil
    end

    return result
end

--- Gets the country of a weapon
---@param weapon table The weapon object
---@return number? country The country ID or nil on error
---@usage local country = GetWeaponCountry(weapon)
function GetWeaponCountry(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponCountry requires valid weapon", "Weapon.GetCountry")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getCountry(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon country: " .. _HarnessInternal.safeString(result),
            "Weapon.GetCountry"
        )
        return nil
    end

    return result
end

--- Gets the 3D position point of a weapon
---@param weapon table The weapon object
---@return table? point Position table with x, y, z coordinates or nil on error
---@usage local point = GetWeaponPoint(weapon)
function GetWeaponPoint(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponPoint requires valid weapon", "Weapon.GetPoint")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getPoint(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon point: " .. _HarnessInternal.safeString(result),
            "Weapon.GetPoint"
        )
        return nil
    end

    return result
end

--- Gets the position and orientation of a weapon
---@param weapon table The weapon object
---@return table? position Position table with p (point) and x,y,z vectors or nil on error
---@usage local pos = GetWeaponPosition(weapon)
function GetWeaponPosition(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponPosition requires valid weapon", "Weapon.GetPosition")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getPosition(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon position: " .. _HarnessInternal.safeString(result),
            "Weapon.GetPosition"
        )
        return nil
    end

    return result
end

--- Gets the velocity vector of a weapon
---@param weapon table The weapon object
---@return table? velocity Velocity vector with x, y, z components or nil on error
---@usage local vel = GetWeaponVelocity(weapon)
function GetWeaponVelocity(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponVelocity requires valid weapon", "Weapon.GetVelocity")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getVelocity(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon velocity: " .. _HarnessInternal.safeString(result),
            "Weapon.GetVelocity"
        )
        return nil
    end

    return result
end

--- Gets the name of a weapon
---@param weapon table The weapon object
---@return string? name The weapon name or nil on error
---@usage local name = GetWeaponName(weapon)
function GetWeaponName(weapon)
    if not weapon then
        _HarnessInternal.log.error("GetWeaponName requires valid weapon", "Weapon.GetName")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getName(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon name: " .. _HarnessInternal.safeString(result),
            "Weapon.GetName"
        )
        return nil
    end

    return result
end

--- Destroys a weapon
---@param weapon table The weapon object to destroy
---@return boolean? success Returns true if successful, nil on error
---@usage DestroyWeapon(weapon)
function DestroyWeapon(weapon)
    if not weapon then
        _HarnessInternal.log.error("DestroyWeapon requires valid weapon", "Weapon.Destroy")
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.destroy(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to destroy weapon: " .. _HarnessInternal.safeString(result),
            "Weapon.Destroy"
        )
        return nil
    end

    return true
end

--- Gets the category name of a weapon
---@param weapon table The weapon object
---@return string? categoryName The weapon category name or nil on error
---@usage local catName = GetWeaponCategoryName(weapon)
function GetWeaponCategoryName(weapon)
    if not weapon then
        _HarnessInternal.log.error(
            "GetWeaponCategoryName requires valid weapon",
            "Weapon.GetCategoryName"
        )
        return nil
    end

    local success, result = pcall(function(...)
        return weapon.getCategoryName(...)
    end, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon category name: " .. _HarnessInternal.safeString(result),
            "Weapon.GetCategoryName"
        )
        return nil
    end

    return result
end

--- Checks if a weapon is active
---@param weapon table The weapon object to check
---@return boolean? active Returns true if active, false if not, nil on error
---@usage local active = IsWeaponActive(weapon)
function IsWeaponActive(weapon)
    if not weapon then
        _HarnessInternal.log.error("IsWeaponActive requires valid weapon", "Weapon.IsActive")
        return nil
    end

    -- Some DCS builds do not expose weapon.isActive; prefer it when present,
    -- otherwise fall back to existence as a proxy for activity to avoid errors.
    local lookupOk, isActive = pcall(function()
        return weapon.isActive
    end)
    if not lookupOk then
        _HarnessInternal.log.error(
            "Failed to resolve weapon activity: " .. _HarnessInternal.safeString(isActive),
            "Weapon.IsActive"
        )
        return nil
    end
    if type(isActive) == "function" then
        local success, result = pcall(isActive, weapon)
        if not success then
            _HarnessInternal.log.error(
                "Failed to check if weapon is active: " .. _HarnessInternal.safeString(result),
                "Weapon.IsActive"
            )
            return nil
        end
        return result
    end

    local okExist, exists = pcall(function(...)
        return weapon.isExist(...)
    end, weapon)
    if not okExist then
        _HarnessInternal.log.error(
            "Failed to check weapon existence as activity proxy: "
                .. _HarnessInternal.safeString(exists),
            "Weapon.IsActive"
        )
        return nil
    end
    return exists == true
end
