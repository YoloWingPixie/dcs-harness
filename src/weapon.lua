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

    local success, result = pcall(weapon.getTypeName, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon type name: " .. tostring(result),
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

    local success, result = pcall(weapon.getDesc, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon description: " .. tostring(result),
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

    local success, result = pcall(weapon.getLauncher, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon launcher: " .. tostring(result),
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

    local success, result = pcall(weapon.getTarget, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon target: " .. tostring(result),
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

    local success, result = pcall(weapon.getCategory, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon category: " .. tostring(result),
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

    local success, result = pcall(weapon.isExist, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check weapon existence: " .. tostring(result),
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

    local success, result = pcall(weapon.getCoalition, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon coalition: " .. tostring(result),
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

    local success, result = pcall(weapon.getCountry, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon country: " .. tostring(result),
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

    local success, result = pcall(weapon.getPoint, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon point: " .. tostring(result),
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

    local success, result = pcall(weapon.getPosition, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon position: " .. tostring(result),
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

    local success, result = pcall(weapon.getVelocity, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon velocity: " .. tostring(result),
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

    local success, result = pcall(weapon.getName, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon name: " .. tostring(result),
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

    local success, result = pcall(weapon.destroy, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to destroy weapon: " .. tostring(result),
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

    local success, result = pcall(weapon.getCategoryName, weapon)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get weapon category name: " .. tostring(result),
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
    if type(weapon.isActive) == "function" then
        local success, result = pcall(weapon.isActive, weapon)
        if not success then
            _HarnessInternal.log.error(
                "Failed to check if weapon is active: " .. tostring(result),
                "Weapon.IsActive"
            )
            return nil
        end
        return result
    end

    local okExist, exists = pcall(weapon.isExist, weapon)
    if not okExist then
        _HarnessInternal.log.error(
            "Failed to check weapon existence as activity proxy: " .. tostring(exists),
            "Weapon.IsActive"
        )
        return nil
    end
    return exists == true
end
