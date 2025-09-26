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
---@return table? data Table with standardized fields if successful, nil otherwise
---        data.temperatureK number   -- Temperature in Kelvin (raw from DCS)
---        data.temperatureC number   -- Temperature in Celsius
---        data.pressurePa number     -- Pressure in Pascals (raw from DCS)
---        data.pressurehPa number    -- Pressure in hPa (millibars)
---        data.pressureInHg number   -- Pressure in inches of mercury
---@usage local data = GetTemperatureAndPressure(position)
function GetTemperatureAndPressure(point)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error("GetTemperatureAndPressure requires valid point with x, y, z", "Atmosphere.GetTemperatureAndPressure")
        return nil
    end

    -- DCS returns two numbers (temperature in Kelvin, pressure in Pascals)
    local success, temperatureK, pressurePa = pcall(atmosphere.getTemperatureAndPressure, point)
    if not success then
        _HarnessInternal.log.error("Failed to get temperature and pressure: " .. tostring(temperatureK), "Atmosphere.GetTemperatureAndPressure")
        return nil
    end

    -- Some environments may return a single number or a table; normalize
    local tK = nil
    local pPa = nil
    if type(temperatureK) == "number" and type(pressurePa) == "number" then
        tK = temperatureK
        pPa = pressurePa
    elseif type(temperatureK) == "table" then
        tK = tonumber(temperatureK.temperature or temperatureK.temp or temperatureK.t)
        pPa = tonumber(temperatureK.pressure or temperatureK.p or temperatureK.qnh)
    elseif type(temperatureK) == "number" then
        tK = temperatureK
    end

    if not tK and not pPa then
        _HarnessInternal.log.error("Temperature/pressure response could not be interpreted", "Atmosphere.GetTemperatureAndPressure")
        return nil
    end

    local data = {}
    if tK then
        data.temperatureK = tK
        data.temperatureC = tK - 273.15
    end
    if pPa then
        data.pressurePa = pPa
        data.pressurehPa = pPa / 100.0
        -- 1 inHg = 3386.389 Pa
        data.pressureInHg = pPa / 3386.389
    end

    return data
end