--[[
    Atmosphere Module - DCS World Atmosphere API Wrappers
    
    This module provides validated wrapper functions for DCS atmosphere operations,
    including wind, temperature, and pressure queries.
]]

require("logger")
require("vector")
require("conversion")

--- Get wind at a specific point
---@param point table? Vec3 position {x, y, z}
---@return table? wind Wind vector if successful, nil otherwise
---@usage local wind = GetWind(position)
function GetWind(point)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error(
            "GetWind requires valid point with x, y, z",
            "Atmosphere.GetWind"
        )
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
        _HarnessInternal.log.error(
            "GetWindWithTurbulence requires valid point with x, y, z",
            "Atmosphere.GetWindWithTurbulence"
        )
        return nil
    end

    local success, result = pcall(atmosphere.getWindWithTurbulence, point)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get wind with turbulence: " .. tostring(result),
            "Atmosphere.GetWindWithTurbulence"
        )
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
        _HarnessInternal.log.error(
            "GetTemperatureAndPressure requires valid point with x, y, z",
            "Atmosphere.GetTemperatureAndPressure"
        )
        return nil
    end

    -- DCS returns two numbers (temperature in Kelvin, pressure in Pascals)
    local success, temperatureK, pressurePa = pcall(atmosphere.getTemperatureAndPressure, point)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get temperature and pressure: " .. tostring(temperatureK),
            "Atmosphere.GetTemperatureAndPressure"
        )
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
        _HarnessInternal.log.error(
            "Temperature/pressure response could not be interpreted",
            "Atmosphere.GetTemperatureAndPressure"
        )
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

-- ================================================================================================
-- Convenience getters with built-in unit conversions for UI use
-- ================================================================================================

--- Compute heading (direction to) in degrees from a wind vector
---@param wind table Wind vector {x,y,z}
---@return number headingDeg Heading in degrees (0..360), where 0=N, 90=E
local function _ComputeHeadingDeg(wind)
    if not wind or type(wind.x) ~= "number" or type(wind.z) ~= "number" then
        return 0
    end
    local deg = math.deg(math.atan2(wind.x, wind.z))
    return (deg + 360) % 360
end

--- Compute horizontal wind speed in meters per second from a vector
---@param wind table Wind vector {x,y,z}
---@return number mps Horizontal speed in m/s
local function _HorizontalSpeedMps(wind)
    if not wind or type(wind.x) ~= "number" or type(wind.z) ~= "number" then
        return 0
    end
    return math.sqrt((wind.x * wind.x) + (wind.z * wind.z))
end

--- Get wind (no turbulence) with heading and speed in knots
---@param point table Vec3 position {x, y, z}
---@return table? data { headingDeg, speedKts, vector }
---@usage local w = GetWindKnots(p) -- w.headingDeg, w.speedKts
function GetWindKnots(point)
    local wind = GetWind(point)
    if not wind then
        return nil
    end
    local kts = MpsToKnots(_HorizontalSpeedMps(wind))
    return {
        headingDeg = _ComputeHeadingDeg(wind),
        speedKts = kts,
        vector = wind,
    }
end

--- Get wind with turbulence, returning heading and speed in knots
---@param point table Vec3 position {x, y, z}
---@return table? data { headingDeg, speedKts, vector }
---@usage local w = GetWindWithTurbulenceKnots(p)
function GetWindWithTurbulenceKnots(point)
    local wind = GetWindWithTurbulence(point)
    if not wind then
        return nil
    end
    local kts = MpsToKnots(_HorizontalSpeedMps(wind))
    return {
        headingDeg = _ComputeHeadingDeg(wind),
        speedKts = kts,
        vector = wind,
    }
end

--- Get temperature in Celsius at a point
---@param point table Vec3 position {x, y, z}
---@return number? celsius Temperature in °C or nil on error
function GetTemperatureC(point)
    local tp = GetTemperatureAndPressure(point)
    if not tp or type(tp.temperatureK) ~= "number" then
        return nil
    end
    return KtoC(tp.temperatureK)
end

--- Get temperature in Fahrenheit at a point
---@param point table Vec3 position {x, y, z}
---@return number? fahrenheit Temperature in °F or nil on error
function GetTemperatureF(point)
    local c = GetTemperatureC(point)
    return c and CtoF(c) or nil
end

--- Get pressure in inches of mercury at a point
---@param point table Vec3 position {x, y, z}
---@return number? inHg Pressure in inHg or nil on error
function GetPressureInHg(point)
    local tp = GetTemperatureAndPressure(point)
    if not tp or type(tp.pressurePa) ~= "number" then
        return nil
    end
    return PaToInHg(tp.pressurePa)
end

--- Get pressure in hectoPascals at a point
---@param point table Vec3 position {x, y, z}
---@return number? hPa Pressure in hPa or nil on error
function GetPressurehPa(point)
    local tp = GetTemperatureAndPressure(point)
    if not tp or type(tp.pressurePa) ~= "number" then
        return nil
    end
    return PaTohPa(tp.pressurePa)
end
