--[[
==================================================================================================
    SPOT MODULE
    Laser and IR spot management utilities
==================================================================================================
]]
require("logger")
require("vector")
--- Create a laser spot
---@param source table Unit or weapon that creates the spot
---@param target table? Target position (Vec3) or nil for unguided
---@param offset table? Offset from target position (Vec3)
---@param code number Laser code (1111-1788)
---@return table? spot Created spot object or nil on error
---@usage local spot = CreateLaserSpot(jtac, targetPos, nil, 1688)
function CreateLaserSpot(source, target, offset, code)
    if not source then
        _HarnessInternal.log.error("CreateLaserSpot requires source unit/weapon", "CreateLaserSpot")
        return nil
    end

    if not code or type(code) ~= "number" then
        _HarnessInternal.log.error("CreateLaserSpot requires numeric laser code", "CreateLaserSpot")
        return nil
    end

    if code < 1111 or code > 1788 then
        _HarnessInternal.log.error("Laser code must be between 1111-1788", "CreateLaserSpot")
        return nil
    end

    local spotType = {
        type = Spot.LaserSpotType.LASER,
        point = target,
        offset = offset,
    }

    local success, spot = pcall(Spot.createLaser, source, spotType, code)
    if not success then
        _HarnessInternal.log.error(
            "Failed to create laser spot: " .. tostring(spot),
            "CreateLaserSpot"
        )
        return nil
    end

    _HarnessInternal.log.info("Created laser spot with code " .. code, "CreateLaserSpot")
    return spot
end

--- Create an IR pointer spot
---@param source table Unit that creates the spot
---@param target table Target position (Vec3)
---@return table? spot Created spot object or nil on error
---@usage local spot = CreateIRSpot(aircraft, targetPos)
function CreateIRSpot(source, target)
    if not source then
        _HarnessInternal.log.error("CreateIRSpot requires source unit", "CreateIRSpot")
        return nil
    end

    if not target or not IsVec3(target) then
        _HarnessInternal.log.error("CreateIRSpot requires Vec3 target position", "CreateIRSpot")
        return nil
    end

    local success, spot = pcall(Spot.createInfraRed, source, target)
    if not success then
        _HarnessInternal.log.error("Failed to create IR spot: " .. tostring(spot), "CreateIRSpot")
        return nil
    end

    _HarnessInternal.log.info("Created IR spot", "CreateIRSpot")
    return spot
end

--- Destroy a spot
---@param spot table Spot object to destroy
---@return boolean success True if destroyed
---@usage DestroySpot(laserSpot)
function DestroySpot(spot)
    if not spot then
        _HarnessInternal.log.error("DestroySpot requires spot object", "DestroySpot")
        return false
    end

    local success, result = pcall(function()
        spot:destroy()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to destroy spot: " .. tostring(result), "DestroySpot")
        return false
    end

    _HarnessInternal.log.info("Destroyed spot", "DestroySpot")
    return true
end

--- Get spot point/position
---@param spot table Spot object
---@return table? point Spot position (Vec3) or nil on error
---@usage local pos = GetSpotPoint(laserSpot)
function GetSpotPoint(spot)
    if not spot then
        _HarnessInternal.log.error("GetSpotPoint requires spot object", "GetSpotPoint")
        return nil
    end

    local success, point = pcall(function()
        return spot:getPoint()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to get spot point: " .. tostring(point), "GetSpotPoint")
        return nil
    end

    return point
end

--- Set spot point/position
---@param spot table Spot object
---@param point table New position (Vec3)
---@return boolean success True if position was set
---@usage SetSpotPoint(laserSpot, newTargetPos)
function SetSpotPoint(spot, point)
    if not spot then
        _HarnessInternal.log.error("SetSpotPoint requires spot object", "SetSpotPoint")
        return false
    end

    if not point or not IsVec3(point) then
        _HarnessInternal.log.error("SetSpotPoint requires Vec3 position", "SetSpotPoint")
        return false
    end

    local success, result = pcall(function()
        spot:setPoint(point)
    end)
    if not success then
        _HarnessInternal.log.error("Failed to set spot point: " .. tostring(result), "SetSpotPoint")
        return false
    end

    return true
end

--- Get laser code
---@param spot table Laser spot object
---@return number? code Laser code or nil on error
---@usage local code = GetLaserCode(laserSpot)
function GetLaserCode(spot)
    if not spot then
        _HarnessInternal.log.error("GetLaserCode requires spot object", "GetLaserCode")
        return nil
    end

    local success, code = pcall(function()
        return spot:getCode()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to get laser code: " .. tostring(code), "GetLaserCode")
        return nil
    end

    return code
end

--- Set laser code
---@param spot table Laser spot object
---@param code number New laser code (1111-1788)
---@return boolean success True if code was set
---@usage SetLaserCode(laserSpot, 1688)
function SetLaserCode(spot, code)
    if not spot then
        _HarnessInternal.log.error("SetLaserCode requires spot object", "SetLaserCode")
        return false
    end

    if not code or type(code) ~= "number" then
        _HarnessInternal.log.error("SetLaserCode requires numeric laser code", "SetLaserCode")
        return false
    end

    if code < 1111 or code > 1788 then
        _HarnessInternal.log.error("Laser code must be between 1111-1788", "SetLaserCode")
        return false
    end

    local success, result = pcall(function()
        spot:setCode(code)
    end)
    if not success then
        _HarnessInternal.log.error("Failed to set laser code: " .. tostring(result), "SetLaserCode")
        return false
    end

    _HarnessInternal.log.info("Set laser code to " .. code, "SetLaserCode")
    return true
end

--- Check if spot exists/is active
---@param spot table Spot object
---@return boolean exists True if spot exists
---@usage if SpotExists(laserSpot) then ... end
function SpotExists(spot)
    if not spot then
        return false
    end

    local success, exists = pcall(function()
        return spot:isExist()
    end)
    if not success then
        return false
    end

    return exists == true
end

--- Get spot category
---@param spot table Spot object
---@return number? category Spot category or nil on error
---@usage local cat = GetSpotCategory(spot)
function GetSpotCategory(spot)
    if not spot then
        _HarnessInternal.log.error("GetSpotCategory requires spot object", "GetSpotCategory")
        return nil
    end

    local success, category = pcall(function()
        return spot:getCategory()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get spot category: " .. tostring(category),
            "GetSpotCategory"
        )
        return nil
    end

    return category
end
