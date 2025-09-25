--[[
    Atmosphere Module - DCS World Atmosphere API Wrappers
    
    This module provides validated wrapper functions for DCS atmosphere operations,
    including wind, temperature, and pressure queries.
]]

require("logger")
require("vector")

--- Get wind at a specific point
---@param point table? Vec3 position {x, y, z}
---@return table? wind Wind vector if successful, nil otherwise
---@usage local wind = GetWind(position)
function GetWind(point)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error("GetWind requires valid point with x, y, z", "Atmosphere.GetWind")
        return nil
    end

    local success, result = pcall(atmosphere.getWind, point)
    if not success then
        _HarnessInternal.log.error("Failed to get wind: " .. tostring(result), "Atmosphere.GetWind")
        return nil
    end

    return result
end

--- Get wind with turbulence at a specific point
---@param point table? Vec3 position {x, y, z}
---@return table? wind Wind vector with turbulence if successful, nil otherwise
---@usage local wind = GetWindWithTurbulence(position)
function GetWindWithTurbulence(point)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error("GetWindWithTurbulence requires valid point with x, y, z", "Atmosphere.GetWindWithTurbulence")
        return nil
    end

    local success, result = pcall(atmosphere.getWindWithTurbulence, point)
    if not success then
        _HarnessInternal.log.error("Failed to get wind with turbulence: " .. tostring(result), "Atmosphere.GetWindWithTurbulence")
        return nil
    end

    return result
end

--- Get temperature and pressure at a specific point
---@param point table? Vec3 position {x, y, z}
---@return table? data Table with temperature and pressure if successful, nil otherwise
---@usage local data = GetTemperatureAndPressure(position)
function GetTemperatureAndPressure(point)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error("GetTemperatureAndPressure requires valid point with x, y, z", "Atmosphere.GetTemperatureAndPressure")
        return nil
    end

    local success, result = pcall(atmosphere.getTemperatureAndPressure, point)
    if not success then
        _HarnessInternal.log.error("Failed to get temperature and pressure: " .. tostring(result), "Atmosphere.GetTemperatureAndPressure")
        return nil
    end

    return result
end