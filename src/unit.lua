--[[
==================================================================================================
    UNIT MODULE
    Validated wrapper functions for DCS Unit API
==================================================================================================
]]

--- Get unit by name with validation and error handling
---@param unitName string The name of the unit to retrieve
---@return table? unit The unit object if found, nil otherwise
---@usage local unit = GetUnit("Player")
function GetUnit(unitName)
    if not unitName or type(unitName) ~= "string" then
        _HarnessInternal.log.error("GetUnit requires string unit name", "GetUnit")
        return nil
    end
    
    local success, unit = pcall(Unit.getByName, unitName)
    if not success then
        _HarnessInternal.log.error("Failed to get unit: " .. tostring(unit), "GetUnit")
        return nil
    end
    
    if not unit then
        _HarnessInternal.log.debug("Unit not found: " .. unitName, "GetUnit")
        return nil
    end
    
    return unit
end

--- Check if unit exists and is active
---@param unitName string The name of the unit to check
---@return boolean exists True if unit exists and is active, false otherwise
---@usage if UnitExists("Player") then ... end
function UnitExists(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return false
    end
    
    local success, exists = pcall(unit.isExist, unit)
    if not success then
        _HarnessInternal.log.error("Failed to check unit existence: " .. tostring(exists), "UnitExists")
        return false
    end
    
    return exists
end

--- Get unit position
---@param unitName string The name of the unit
---@return table? position The position {x, y, z} if found, nil otherwise
---@usage local pos = GetUnitPosition("Player")
function GetUnitPosition(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, position = pcall(unit.getPosition, unit)
    if not success or not position or not position.p then
        _HarnessInternal.log.error("Failed to get unit position: " .. tostring(position), "GetUnitPosition")
        return nil
    end
    
    return position.p
end

--- Get unit heading in degrees
---@param unitName string The name of the unit
---@return number? heading The heading in degrees (0-360) if found, nil otherwise
---@usage local heading = GetUnitHeading("Player")
function GetUnitHeading(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, position = pcall(unit.getPosition, unit)
    if not success or not position then
        _HarnessInternal.log.error("Failed to get unit position for heading: " .. tostring(position), "GetUnitHeading")
        return nil
    end
    
    -- Extract heading from orientation matrix
    -- position.x is the forward vector, so heading is atan2(forward.z, forward.x)
    local heading = math.atan2(position.x.z, position.x.x)
    heading = math.deg(heading)
    
    -- Normalize to 0-360
    if heading < 0 then
        heading = heading + 360
    end
    
    return heading
end

--- Get unit velocity
---@param unitName string The name of the unit
---@return table? velocity The velocity vector {x, y, z} if found, nil otherwise
---@usage local vel = GetUnitVelocity("Player")
function GetUnitVelocity(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, velocity = pcall(unit.getVelocity, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit velocity: " .. tostring(velocity), "GetUnitVelocity")
        return nil
    end
    
    return velocity
end

--- Get unit type name
---@param unitName string The name of the unit
---@return string? typeName The unit type name if found, nil otherwise
---@usage local type = GetUnitType("Player")
function GetUnitType(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, typeName = pcall(unit.getTypeName, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit type: " .. tostring(typeName), "GetUnitType")
        return nil
    end
    
    return typeName
end

--- Get unit coalition
---@param unitName string The name of the unit
---@return number? coalition The coalition ID if found, nil otherwise
---@usage local coalition = GetUnitCoalition("Player")
function GetUnitCoalition(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, coalition = pcall(unit.getCoalition, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit coalition: " .. tostring(coalition), "GetUnitCoalition")
        return nil
    end
    
    return coalition
end

--- Get unit country
---@param unitName string The name of the unit
---@return number? country The country ID if found, nil otherwise
---@usage local country = GetUnitCountry("Player")
function GetUnitCountry(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, country = pcall(unit.getCountry, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit country: " .. tostring(country), "GetUnitCountry")
        return nil
    end
    
    return country
end

--- Get unit group
---@param unitName string The name of the unit
---@return table? group The group object if found, nil otherwise
---@usage local group = GetUnitGroup("Player")
function GetUnitGroup(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, group = pcall(unit.getGroup, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit group: " .. tostring(group), "GetUnitGroup")
        return nil
    end
    
    return group
end

--- Get unit player name (if player controlled)
---@param unitName string The name of the unit
---@return string? playerName The player name if unit is player-controlled, nil otherwise
---@usage local playerName = GetUnitPlayerName("Player")
function GetUnitPlayerName(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, playerName = pcall(unit.getPlayerName, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit player name: " .. tostring(playerName), "GetUnitPlayerName")
        return nil
    end
    
    return playerName
end

--- Get unit life/health
---@param unitName string The name of the unit
---@return number? life The current life/health if found, nil otherwise
---@usage local life = GetUnitLife("Player")
function GetUnitLife(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, life = pcall(unit.getLife, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit life: " .. tostring(life), "GetUnitLife")
        return nil
    end
    
    return life
end

--- Get unit maximum life/health
---@param unitName string The name of the unit
---@return number? maxLife The maximum life/health if found, nil otherwise
---@usage local maxLife = GetUnitLife0("Player")
function GetUnitLife0(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, life0 = pcall(unit.getLife0, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit max life: " .. tostring(life0), "GetUnitLife0")
        return nil
    end
    
    return life0
end

--- Get unit fuel (0.0 to 1.0+)
---@param unitName string The name of the unit
---@return number? fuel The fuel level (0.0 to 1.0+) if found, nil otherwise
---@usage local fuel = GetUnitFuel("Player")
function GetUnitFuel(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, fuel = pcall(unit.getFuel, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit fuel: " .. tostring(fuel), "GetUnitFuel")
        return nil
    end
    
    return fuel
end

--- Check if unit is in air
---@param unitName string The name of the unit
---@return boolean inAir True if unit is in air, false otherwise
---@usage if IsUnitInAir("Player") then ... end
function IsUnitInAir(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return false
    end
    
    local success, inAir = pcall(unit.inAir, unit)
    if not success then
        _HarnessInternal.log.error("Failed to check if unit in air: " .. tostring(inAir), "IsUnitInAir")
        return false
    end
    
    return inAir
end

--- Get unit ammo
---@param unitName string The name of the unit
---@return table? ammo The ammo table if found, nil otherwise
---@usage local ammo = GetUnitAmmo("Player")
function GetUnitAmmo(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end
    
    local success, ammo = pcall(unit.getAmmo, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit ammo: " .. tostring(ammo), "GetUnitAmmo")
        return nil
    end
    
    return ammo
end