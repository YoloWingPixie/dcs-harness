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
    if not IsVec3(point) then
        _HarnessInternal.log.error(
            "GetWind requires valid point with x, y, z",
            "Atmosphere.GetWind"
        )
        return nil
    end
    if type(atmosphere) ~= "table" or type(atmosphere.getWind) ~= "function" then
        _HarnessInternal.log.error("atmosphere.getWind is unavailable", "Atmosphere.GetWind")
        return nil
    end

    local success, result = pcall(atmosphere.getWind, point)
    if not success then
        _HarnessInternal.log.error("Failed to get wind: " .. tostring(result), "Atmosphere.GetWind")
        return nil
    end

    if not IsVec3(result) then
        _HarnessInternal.log.error("Wind response was not a Vec3", "Atmosphere.GetWind")
        return nil
    end
    return Vec3(result)
end

--- Get wind with turbulence at a specific point
---@param point table? Vec3 position {x, y, z}
---@return table? wind Wind vector with turbulence if successful, nil otherwise
---@usage local wind = GetWindWithTurbulence(position)
function GetWindWithTurbulence(point)
    if not IsVec3(point) then
        _HarnessInternal.log.error(
            "GetWindWithTurbulence requires valid point with x, y, z",
            "Atmosphere.GetWindWithTurbulence"
        )
        return nil
    end

    if type(atmosphere) ~= "table" or type(atmosphere.getWindWithTurbulence) ~= "function" then
        _HarnessInternal.log.error(
            "atmosphere.getWindWithTurbulence is unavailable",
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

    if not IsVec3(result) then
        _HarnessInternal.log.error(
            "Turbulent wind response was not a Vec3",
            "Atmosphere.GetWindWithTurbulence"
        )
        return nil
    end
    return Vec3(result)
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
    if not IsVec3(point) then
        _HarnessInternal.log.error(
            "GetTemperatureAndPressure requires valid point with x, y, z",
            "Atmosphere.GetTemperatureAndPressure"
        )
        return nil
    end
    if type(atmosphere) ~= "table" or type(atmosphere.getTemperatureAndPressure) ~= "function" then
        _HarnessInternal.log.error(
            "atmosphere.getTemperatureAndPressure is unavailable",
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

local AtmosphereInternal = {}

function AtmosphereInternal.isFinitePositive(value)
    return type(value) == "number" and value == value and value > 0 and value < math.huge
end

function AtmosphereInternal.airData(temperatureK, pressurePa, source)
    local gasConstant = HarnessConstants.DRY_AIR_GAS_CONSTANT_J_KG_K
    local gamma = HarnessConstants.AIR_SPECIFIC_HEAT_RATIO
    return {
        temperatureK = temperatureK,
        pressurePa = pressurePa,
        densityKgM3 = pressurePa / (gasConstant * temperatureK),
        speedOfSoundMps = math.sqrt(gamma * gasConstant * temperatureK),
        source = source,
    }
end

--- Calculate International Standard Atmosphere data from 0 through 20 km
---@param altitudeM number Geopotential altitude in meters
---@return table? airDataValue Air-data table or nil outside the supported range
function CalculateIsaAtmosphere(altitudeM)
    if
        type(altitudeM) ~= "number"
        or altitudeM ~= altitudeM
        or altitudeM < 0
        or altitudeM > 20000
    then
        _HarnessInternal.log.error(
            "CalculateIsaAtmosphere supports altitudes from 0 through 20000 meters",
            "Atmosphere.CalculateIsaAtmosphere"
        )
        return nil
    end

    local seaLevelTemperature = HarnessConstants.SEA_LEVEL_TEMPERATURE_K
    local seaLevelPressure = HarnessConstants.SEA_LEVEL_PRESSURE_PA
    local lapseRate = HarnessConstants.ISA_TEMP_LAPSE_RATE
    local gasConstant = HarnessConstants.DRY_AIR_GAS_CONSTANT_J_KG_K
    local gravity = 9.80665
    local temperatureK
    local pressurePa

    if altitudeM <= 11000 then
        temperatureK = seaLevelTemperature - lapseRate * altitudeM
        pressurePa = seaLevelPressure
            * (temperatureK / seaLevelTemperature) ^ (gravity / (gasConstant * lapseRate))
    else
        local transitionTemperature = seaLevelTemperature - lapseRate * 11000
        local transitionPressure = seaLevelPressure
            * (transitionTemperature / seaLevelTemperature)
                ^ (gravity / (gasConstant * lapseRate))
        temperatureK = transitionTemperature
        pressurePa = transitionPressure
            * math.exp(-gravity * (altitudeM - 11000) / (gasConstant * transitionTemperature))
    end

    return AtmosphereInternal.airData(
        temperatureK,
        pressurePa,
        HarnessConstants.AIR_DATA_SOURCE_ISA
    )
end

--- Get DCS atmosphere data with an ISA fallback
---@param point table Vec3 world position
---@return table? airDataValue Air-data table
function GetAirData(point)
    if not IsVec3(point) then
        _HarnessInternal.log.error("GetAirData requires a Vec3 point", "Atmosphere.GetAirData")
        return nil
    end

    local dcsData = GetTemperatureAndPressure(point)
    if
        dcsData
        and AtmosphereInternal.isFinitePositive(dcsData.temperatureK)
        and AtmosphereInternal.isFinitePositive(dcsData.pressurePa)
    then
        return AtmosphereInternal.airData(
            dcsData.temperatureK,
            dcsData.pressurePa,
            HarnessConstants.AIR_DATA_SOURCE_DCS
        )
    end
    return CalculateIsaAtmosphere(point.y)
end

--- Calculate Mach number from true airspeed and static temperature
---@param tasMps number True airspeed in meters per second
---@param temperatureK number Static temperature in Kelvin
---@return number? mach Mach number
function MachFromTrueAirspeed(tasMps, temperatureK)
    if
        type(tasMps) ~= "number"
        or tasMps ~= tasMps
        or tasMps < 0
        or tasMps >= math.huge
        or not AtmosphereInternal.isFinitePositive(temperatureK)
    then
        _HarnessInternal.log.error(
            "MachFromTrueAirspeed requires non-negative airspeed and positive temperature",
            "Atmosphere.MachFromTrueAirspeed"
        )
        return nil
    end
    return tasMps
        / math.sqrt(
            HarnessConstants.AIR_SPECIFIC_HEAT_RATIO
                * HarnessConstants.DRY_AIR_GAS_CONSTANT_J_KG_K
                * temperatureK
        )
end

--- Convert subsonic true airspeed to calibrated airspeed
---@param tasMps number True airspeed in meters per second
---@param temperatureK number Static temperature in Kelvin
---@param pressurePa number Static pressure in Pascals
---@return number? casMps Calibrated airspeed, or nil for invalid or supersonic input
function TrueAirspeedToCalibratedAirspeed(tasMps, temperatureK, pressurePa)
    if not AtmosphereInternal.isFinitePositive(pressurePa) then
        _HarnessInternal.log.error(
            "TrueAirspeedToCalibratedAirspeed requires positive pressure",
            "Atmosphere.TrueAirspeedToCalibratedAirspeed"
        )
        return nil
    end
    local mach = MachFromTrueAirspeed(tasMps, temperatureK)
    if not mach or mach > 1 then
        if mach and mach > 1 then
            _HarnessInternal.log.error(
                "TrueAirspeedToCalibratedAirspeed does not support supersonic input",
                "Atmosphere.TrueAirspeedToCalibratedAirspeed"
            )
        end
        return nil
    end

    local gamma = HarnessConstants.AIR_SPECIFIC_HEAT_RATIO
    local impactPressure = pressurePa
        * ((1 + ((gamma - 1) * 0.5) * mach * mach) ^ (gamma / (gamma - 1)) - 1)
    local seaLevelSound = math.sqrt(
        gamma
            * HarnessConstants.DRY_AIR_GAS_CONSTANT_J_KG_K
            * HarnessConstants.SEA_LEVEL_TEMPERATURE_K
    )
    local calibratedTerm = ((impactPressure / HarnessConstants.SEA_LEVEL_PRESSURE_PA) + 1)
            ^ ((gamma - 1) / gamma)
        - 1
    return seaLevelSound * math.sqrt((2 / (gamma - 1)) * math.max(0, calibratedTerm))
end

-- ================================================================================================
-- Convenience getters with built-in unit conversions for UI use
-- ================================================================================================

--- Compute heading (direction to) in degrees from a wind vector
---@param wind table Wind vector {x,y,z}
---@return number headingDeg Heading in degrees (0..360), where 0=N, 90=E
function AtmosphereInternal.computeHeadingDeg(wind)
    if not wind or type(wind.x) ~= "number" or type(wind.z) ~= "number" then
        return nil
    end
    local deg = math.deg(math.atan2(wind.z, wind.x))
    return (deg + 360) % 360
end

--- Compute horizontal wind speed in meters per second from a vector
---@param wind table Wind vector {x,y,z}
---@return number mps Horizontal speed in m/s
function AtmosphereInternal.horizontalSpeedMps(wind)
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
    local kts = MpsToKnots(AtmosphereInternal.horizontalSpeedMps(wind))
    return {
        headingDeg = AtmosphereInternal.computeHeadingDeg(wind),
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
    local kts = MpsToKnots(AtmosphereInternal.horizontalSpeedMps(wind))
    return {
        headingDeg = AtmosphereInternal.computeHeadingDeg(wind),
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

--- Get wind heading (direction wind is blowing TO) at a position
---@param position table Vec3 position {x, y, z}
---@return number? headingDeg Wind heading in degrees (0-360), nil on error
---@usage local hdg = GetWindHeading(pos)
function GetWindHeading(position)
    local wind = GetWind(position)
    if not wind then
        return nil
    end
    return AtmosphereInternal.computeHeadingDeg(wind)
end

--- Get wind speed magnitude at a position
---@param position table Vec3 position {x, y, z}
---@return number? speedMps Wind speed in m/s, nil on error
---@usage local spd = GetWindSpeed(pos)
function GetWindSpeed(position)
    local wind = GetWind(position)
    if not wind then
        return nil
    end
    return AtmosphereInternal.horizontalSpeedMps(wind)
end
