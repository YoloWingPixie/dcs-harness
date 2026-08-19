--[[
==================================================================================================
    CONVERSION MODULE
    Unit conversion helpers with strict validation and predictable behavior
==================================================================================================
]]

require("logger")

-- Internal safe number parser
local function toNumberOrNil(value)
    if type(value) == "number" then
        return value
    end
    if type(value) == "string" then
        local n = tonumber(value)
        return n
    end
    return nil
end

--[[
Temperature conversions
]]

--- Convert Celsius to Kelvin
---@param c number|string
---@return number
function CtoK(c)
    local n = toNumberOrNil(c)
    if n == nil then
        _HarnessInternal.log.error("CtoK requires number", "Conversion.CtoK")
        return 0
    end
    return n + 273.15
end

--- Convert Kelvin to Celsius
---@param k number|string
---@return number
function KtoC(k)
    local n = toNumberOrNil(k)
    if n == nil then
        _HarnessInternal.log.error("KtoC requires number", "Conversion.KtoC")
        return 0
    end
    return n - 273.15
end

--- Convert Celsius to Fahrenheit
---@param c number|string
---@return number
function CtoF(c)
    local n = toNumberOrNil(c)
    if n == nil then
        _HarnessInternal.log.error("CtoF requires number", "Conversion.CtoF")
        return 0
    end
    return (n * 9 / 5) + 32
end

--- Convert Fahrenheit to Celsius
---@param f number|string
---@return number
function FtoC(f)
    local n = toNumberOrNil(f)
    if n == nil then
        _HarnessInternal.log.error("FtoC requires number", "Conversion.FtoC")
        return 0
    end
    return (n - 32) * 5 / 9
end

--- Convert Kelvin to Fahrenheit
---@param k number|string
---@return number
function KtoF(k)
    return CtoF(KtoC(k))
end

--- Convert Fahrenheit to Kelvin
---@param f number|string
---@return number
function FtoK(f)
    return CtoK(FtoC(f))
end

--[[
Pressure conversions
]]

--- Pascals to inches of mercury
---@param pa number|string
---@return number
function PaToInHg(pa)
    local n = toNumberOrNil(pa)
    if n == nil then
        _HarnessInternal.log.error("PaToInHg requires number", "Conversion.PaToInHg")
        return 0
    end
    return n / 3386.389
end

--- inches of mercury to Pascals
---@param inHg number|string
---@return number
function InHgToPa(inHg)
    local n = toNumberOrNil(inHg)
    if n == nil then
        _HarnessInternal.log.error("InHgToPa requires number", "Conversion.InHgToPa")
        return 0
    end
    return n * 3386.389
end

--- Pascals to hectoPascals
---@param pa number|string
---@return number
function PaTohPa(pa)
    local n = toNumberOrNil(pa)
    if n == nil then
        _HarnessInternal.log.error("PaTohPa requires number", "Conversion.PaTohPa")
        return 0
    end
    return n / 100.0
end

--- hectoPascals to Pascals
---@param hPa number|string
---@return number
function hPaToPa(hPa)
    local n = toNumberOrNil(hPa)
    if n == nil then
        _HarnessInternal.log.error("hPaToPa requires number", "Conversion.hPaToPa")
        return 0
    end
    return n * 100.0
end

--[[
Distance / altitude
]]

--- Meters to Feet
---@param m number|string
---@return number
function MetersToFeet(m)
    local n = toNumberOrNil(m)
    if n == nil then
        _HarnessInternal.log.error("MetersToFeet requires number", "Conversion.MetersToFeet")
        return 0
    end
    return n * 3.280839895
end

--- Feet to Meters
---@param ft number|string
---@return number
function FeetToMeters(ft)
    local n = toNumberOrNil(ft)
    if n == nil then
        _HarnessInternal.log.error("FeetToMeters requires number", "Conversion.FeetToMeters")
        return 0
    end
    return n / 3.280839895
end

--[[
Speed
]]

--- Meters per second to Knots
---@param mps number|string
---@return number
function MpsToKnots(mps)
    local n = toNumberOrNil(mps)
    if n == nil then
        _HarnessInternal.log.error("MpsToKnots requires number", "Conversion.MpsToKnots")
        return 0
    end
    return n * 1.943844492
end

--- Knots to meters per second
---@param knots number|string
---@return number
function KnotsToMps(knots)
    local n = toNumberOrNil(knots)
    if n == nil then
        _HarnessInternal.log.error("KnotsToMps requires number", "Conversion.KnotsToMps")
        return 0
    end
    return n / 1.943844492
end

--- Airspeed (IAS) helper in knots to meters per second
---@param knots number|string
---@return number
function GetSpeedIAS(knots)
    return KnotsToMps(knots)
end

--[[
Generic helpers for UI / Getters
]]

--- Convert temperature value from one unit to another
---@param value number|string
---@param from string one of: "C","F","K"
---@param to string one of: "C","F","K"
---@return number
function ConvertTemperature(value, from, to)
    local f = string.upper(tostring(from or ""))
    local t = string.upper(tostring(to or ""))
    if f == t then
        return toNumberOrNil(value) or 0
    end
    if f == "C" and t == "F" then
        return CtoF(value)
    elseif f == "F" and t == "C" then
        return FtoC(value)
    elseif f == "C" and t == "K" then
        return CtoK(value)
    elseif f == "K" and t == "C" then
        return KtoC(value)
    elseif f == "F" and t == "K" then
        return FtoK(value)
    elseif f == "K" and t == "F" then
        return KtoF(value)
    end
    _HarnessInternal.log.error("ConvertTemperature invalid units", "Conversion.ConvertTemperature")
    return 0
end

--- Convert pressure value from one unit to another
---@param value number|string
---@param from string one of: "Pa","hPa","inHg"
---@param to string one of: "Pa","hPa","inHg"
---@return number
function ConvertPressure(value, from, to)
    local f = string.upper(tostring(from or ""))
    local t = string.upper(tostring(to or ""))
    if f == t then
        return toNumberOrNil(value) or 0
    end
    if f == "PA" and t == "INHG" then
        return PaToInHg(value)
    elseif f == "INHG" and t == "PA" then
        return InHgToPa(value)
    elseif f == "PA" and t == "HPA" then
        return PaTohPa(value)
    elseif f == "HPA" and t == "PA" then
        return hPaToPa(value)
    elseif f == "HPA" and t == "INHG" then
        return PaToInHg(hPaToPa(value))
    elseif f == "INHG" and t == "HPA" then
        return PaTohPa(InHgToPa(value))
    end
    _HarnessInternal.log.error("ConvertPressure invalid units", "Conversion.ConvertPressure")
    return 0
end

--- Convert distance/altitude value from one unit to another
---@param value number|string
---@param from string one of: "m","ft"
---@param to string one of: "m","ft"
---@return number
function ConvertDistance(value, from, to)
    local f = string.lower(tostring(from or ""))
    local t = string.lower(tostring(to or ""))
    if f == t then
        return toNumberOrNil(value) or 0
    end
    if f == "m" and t == "ft" then
        return MetersToFeet(value)
    elseif f == "ft" and t == "m" then
        return FeetToMeters(value)
    end
    _HarnessInternal.log.error("ConvertDistance invalid units", "Conversion.ConvertDistance")
    return 0
end

--- Convert speed value from one unit to another
---@param value number|string
---@param from string one of: "mps","knots"
---@param to string one of: "mps","knots"
---@return number
function ConvertSpeed(value, from, to)
    local f = string.lower(tostring(from or ""))
    local t = string.lower(tostring(to or ""))
    if f == t then
        return toNumberOrNil(value) or 0
    end
    if f == "mps" and t == "knots" then
        return MpsToKnots(value)
    elseif f == "knots" and t == "mps" then
        return KnotsToMps(value)
    end
    _HarnessInternal.log.error("ConvertSpeed invalid units", "Conversion.ConvertSpeed")
    return 0
end

--- Calculate TACAN frequency in Hz from channel and mode
---@param channel number TACAN channel (1-126)
---@param channelMode string TACAN mode ("X" or "Y")
---@return number? frequency Frequency in Hz, or nil for invalid inputs
---@usage local freq = GetTacanFrequency(71, "X")
function GetTacanFrequency(channel, channelMode)
    if type(channel) ~= "number" then
        _HarnessInternal.log.error(
            "GetTacanFrequency requires channel as number",
            "Conversion.GetTacanFrequency"
        )
        return nil
    end

    if channel < 1 or channel > 126 or channel ~= math.floor(channel) then
        _HarnessInternal.log.error(
            "GetTacanFrequency channel must be integer 1-126",
            "Conversion.GetTacanFrequency"
        )
        return nil
    end

    if type(channelMode) ~= "string" then
        _HarnessInternal.log.error(
            "GetTacanFrequency requires channelMode as string",
            "Conversion.GetTacanFrequency"
        )
        return nil
    end

    local mode = string.upper(channelMode)
    if mode ~= "X" and mode ~= "Y" then
        _HarnessInternal.log.error(
            "GetTacanFrequency channelMode must be 'X' or 'Y'",
            "Conversion.GetTacanFrequency"
        )
        return nil
    end

    local frequency
    if channel <= 63 then
        if mode == "X" then
            frequency = (1025 + (channel - 1)) * 1e6
        else
            frequency = (1088 + (channel - 1)) * 1e6
        end
    else
        if mode == "X" then
            frequency = (961 + (channel - 64)) * 1e6
        else
            frequency = (1024 + (channel - 64)) * 1e6
        end
    end

    return frequency
end

-- Local aliases for HarnessConstants (defined in _header.lua)
local ISA_SEA_LEVEL_TEMP_K = HarnessConstants.ISA_SEA_LEVEL_TEMP_K
local ISA_TEMP_LAPSE_RATE = HarnessConstants.ISA_TEMP_LAPSE_RATE
local ISA_DENSITY_EXPONENT = HarnessConstants.ISA_DENSITY_EXPONENT
local CONVERSION_FEET_TO_METERS = HarnessConstants.FEET_TO_METERS
local MPS_TO_KNOTS = HarnessConstants.MPS_TO_KNOTS
local KNOTS_TO_MPS = HarnessConstants.KNOTS_TO_MPS

--- Convert KIAS to true ground speed in knots using ISA atmosphere model
---@param iasKnots number Indicated airspeed in knots
---@param altitudeFeet number Altitude in feet MSL
---@param position table? Vec3 position for wind correction
---@param trackBearing number? Track bearing in degrees for wind correction
---@return number groundSpeedKnots Ground speed in knots
---@usage local gs = ConvertKiasToGroundSpeed(250, 25000)
function ConvertKiasToGroundSpeed(iasKnots, altitudeFeet, position, trackBearing)
    if type(iasKnots) ~= "number" then
        _HarnessInternal.log.error(
            "ConvertKiasToGroundSpeed requires iasKnots as number",
            "Conversion.ConvertKiasToGroundSpeed"
        )
        return 0
    end

    if type(altitudeFeet) ~= "number" then
        _HarnessInternal.log.error(
            "ConvertKiasToGroundSpeed requires altitudeFeet as number",
            "Conversion.ConvertKiasToGroundSpeed"
        )
        return 0
    end

    local altMeters = altitudeFeet * CONVERSION_FEET_TO_METERS

    local tempRatio = 1 - (ISA_TEMP_LAPSE_RATE * altMeters / ISA_SEA_LEVEL_TEMP_K)
    if tempRatio < 0 then
        tempRatio = 0
    end

    local densityRatio = tempRatio ^ ISA_DENSITY_EXPONENT
    if densityRatio <= 0 then
        densityRatio = 0.001
    end

    local tasKnots = iasKnots / math.sqrt(densityRatio)

    local groundSpeedKnots = tasKnots

    if type(GetWind) == "function" and position and trackBearing then
        local ok, wind = pcall(GetWind, position)
        if ok and wind then
            local trackRad = math.rad(trackBearing)
            local headwind = (wind.x * math.cos(trackRad) + wind.z * math.sin(trackRad))
            local headwindKnots = headwind * MPS_TO_KNOTS
            groundSpeedKnots = tasKnots - headwindKnots
        end
    end

    if groundSpeedKnots < 0 then
        groundSpeedKnots = 0
    end

    return groundSpeedKnots
end

--- Convert KIAS to ground speed in meters per second using ISA atmosphere model
---@param iasKnots number Indicated airspeed in knots
---@param altitudeFeet number Altitude in feet MSL
---@param position table? Vec3 position for wind correction
---@param trackBearing number? Track bearing in degrees for wind correction
---@return number groundSpeedMps Ground speed in m/s
---@usage local gs = ConvertKiasToMps(250, 25000)
function ConvertKiasToMps(iasKnots, altitudeFeet, position, trackBearing)
    return ConvertKiasToGroundSpeed(iasKnots, altitudeFeet, position, trackBearing) * KNOTS_TO_MPS
end
