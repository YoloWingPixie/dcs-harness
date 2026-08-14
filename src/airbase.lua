--[[
    Airbase Module - DCS World Airbase API Wrappers

    This module provides validated wrapper functions for DCS airbase operations,
    including runway queries, parking spots, and airbase information.
]]
require("logger")
require("vector")
require("geomath")
--- Get airbase by name
---@param airbaseName string? Name of the airbase
---@return table? airbase Airbase object if found, nil otherwise
---@usage local airbase = getAirbaseByName("Batumi")
function GetAirbaseByName(airbaseName)
    if not airbaseName or type(airbaseName) ~= "string" then
        _HarnessInternal.log.error(
            "GetAirbaseByName requires valid airbase name",
            "Airbase.GetByName"
        )
        return nil
    end

    local success, result = pcall(Airbase.getByName, airbaseName)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase by name: " .. tostring(result),
            "Airbase.GetByName"
        )
        return nil
    end

    return result
end

--- Get airbase descriptor
---@param airbase table? Airbase object
---@return table? descriptor Airbase descriptor if found, nil otherwise
---@usage local desc = getAirbaseDescriptor(airbase)
function GetAirbaseDescriptor(airbase)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseDescriptor requires valid airbase",
            "Airbase.GetDescriptor"
        )
        return nil
    end

    local success, result = pcall(airbase.getDesc, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase descriptor: " .. tostring(result),
            "Airbase.GetDesc"
        )
        return nil
    end

    return result
end

--- Get airbase callsign
---@param airbase table? Airbase object
---@return string? callsign Airbase callsign if found, nil otherwise
---@usage local callsign = getAirbaseCallsign(airbase)
function GetAirbaseCallsign(airbase)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseCallsign requires valid airbase",
            "Airbase.GetCallsign"
        )
        return nil
    end

    local success, result = pcall(airbase.getCallsign, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase callsign: " .. tostring(result),
            "Airbase.GetCallsign"
        )
        return nil
    end

    return result
end

--- Get airbase unit
---@param airbase table? Airbase object
---@return table? unit Airbase unit if found, nil otherwise
---@usage local unit = getAirbaseUnit(airbase)
function GetAirbaseUnit(airbase, unitIndex)
    if not airbase then
        _HarnessInternal.log.error("GetAirbaseUnit requires valid airbase", "Airbase.GetUnit")
        return nil
    end

    local success, result = pcall(airbase.getUnit, airbase, unitIndex)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase unit: " .. tostring(result),
            "Airbase.GetUnit"
        )
        return nil
    end

    return result
end

--- Get airbase category name
---@param airbase table? Airbase object
---@return string? category Category name if found, nil otherwise
---@usage local category = getAirbaseCategoryName(airbase)
function GetAirbaseCategoryName(airbase)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseCategoryName requires valid airbase",
            "Airbase.GetCategoryName"
        )
        return nil
    end

    local success, categoryValue = pcall(airbase.getCategoryEx, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase category: " .. tostring(categoryValue),
            "Airbase.GetCategoryEx"
        )
        return nil
    end

    local names = {}
    local cat = (Airbase and Airbase.Category) or nil
    if cat then
        names[cat.AIRDROME] = "AIRDROME"
        names[cat.HELIPAD] = "HELIPAD"
        local farp = rawget(cat, "FARP")
        if farp ~= nil then
            names[farp] = "FARP"
        end
        local ship = cat["SHIP"]
        if ship ~= nil then
            names[ship] = "SHIP"
        end
        local oil = rawget(cat, "OIL_PLATFORM")
        if oil ~= nil then
            names[oil] = "OIL_PLATFORM"
        end
    end

    return names[categoryValue] or tostring(categoryValue)
end

--- Get airbase parking information
---@param airbase table? Airbase object
---@param available boolean? If true, only return available parking spots
---@return table? parking Parking information if found, nil otherwise
---@usage local parking = getAirbaseParking(airbase, true)
function GetAirbaseParking(airbase, available)
    if not airbase then
        _HarnessInternal.log.error("GetAirbaseParking requires valid airbase", "Airbase.GetParking")
        return nil
    end

    local success, result = pcall(airbase.getParking, airbase, available)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase parking: " .. tostring(result),
            "Airbase.GetParking"
        )
        return nil
    end

    return result
end

--- Get airbase runways
---@param airbase table? Airbase object
---@return table? runways Runway information if found, nil otherwise
---@usage local runways = getAirbaseRunways(airbase)
function GetAirbaseRunways(airbase)
    if not airbase then
        _HarnessInternal.log.error("GetAirbaseRunways requires valid airbase", "Airbase.GetRunways")
        return nil
    end

    local success, result = pcall(airbase.getRunways, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase runways: " .. tostring(result),
            "Airbase.GetRunways"
        )
        return nil
    end

    return result
end

--- Get airbase tech object positions
---@param airbase table? Airbase object
---@param techObjectType number Tech object type ID
---@return table? positions Tech object positions if found, nil otherwise
---@usage local positions = getAirbaseTechObjectPos(airbase, 1)
function GetAirbaseTechObjectPos(airbase, techObjectType)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseTechObjectPos requires valid airbase",
            "Airbase.GetTechObjectPos"
        )
        return nil
    end

    if not techObjectType or type(techObjectType) ~= "number" then
        _HarnessInternal.log.error(
            "GetAirbaseTechObjectPos requires valid tech object type",
            "Airbase.GetTechObjectPos"
        )
        return nil
    end

    local success, result = pcall(airbase.getTechObjectPos, airbase, techObjectType)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get tech object positions: " .. tostring(result),
            "Airbase.GetTechObjectPos"
        )
        return nil
    end

    return result
end

--- Get airbase dispatcher tower position
---@param airbase table? Airbase object
---@return table? position Tower position if found, nil otherwise
---@usage local towerPos = getAirbaseDispatcherTowerPos(airbase)
function GetAirbaseDispatcherTowerPos(airbase)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseDispatcherTowerPos requires valid airbase",
            "Airbase.GetDispatcherTowerPos"
        )
        return nil
    end

    local success, result = pcall(airbase.getDispatcherTowerPos, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get dispatcher tower position: " .. tostring(result),
            "Airbase.GetDispatcherTowerPos"
        )
        return nil
    end

    return result
end

--- Get airbase radio silent mode
---@param airbase table? Airbase object
---@return boolean? silent True if radio silent, nil on error
---@usage local isSilent = getAirbaseRadioSilentMode(airbase)
function GetAirbaseRadioSilentMode(airbase)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseRadioSilentMode requires valid airbase",
            "Airbase.GetRadioSilentMode"
        )
        return nil
    end

    local success, result = pcall(airbase.getRadioSilentMode, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get radio silent mode: " .. tostring(result),
            "Airbase.GetRadioSilentMode"
        )
        return nil
    end

    return result
end

--- Set airbase radio silent mode
---@param airbase table? Airbase object
---@param silent boolean Radio silent mode
---@return boolean? success True if set successfully, nil on error
---@usage SetAirbaseRadioSilentMode(airbase, true)
function SetAirbaseRadioSilentMode(airbase, silent)
    if not airbase then
        _HarnessInternal.log.error(
            "SetAirbaseRadioSilentMode requires valid airbase",
            "Airbase.SetRadioSilentMode"
        )
        return nil
    end

    if type(silent) ~= "boolean" then
        _HarnessInternal.log.error(
            "SetAirbaseRadioSilentMode requires boolean silent value",
            "Airbase.SetRadioSilentMode"
        )
        return nil
    end

    local success, result = pcall(airbase.setRadioSilentMode, airbase, silent)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set radio silent mode: " .. tostring(result),
            "Airbase.SetRadioSilentMode"
        )
        return nil
    end

    return true
end

--- Get airbase beacon information
---@param airbase table? Airbase object
---@return table? beacon Beacon information if found, nil otherwise
---@usage local beacon = getAirbaseBeacon(airbase)
function GetAirbaseBeacon(airbase)
    if not airbase then
        _HarnessInternal.log.error("GetAirbaseBeacon requires valid airbase", "Airbase.GetBeacon")
        return nil
    end

    local success, result = pcall(airbase.getBeacon, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase beacon: " .. tostring(result),
            "Airbase.GetBeacon"
        )
        return nil
    end

    return result
end

--- Set airbase auto capture mode
---@param airbase table? Airbase object
---@param enabled boolean Auto capture enabled
---@return boolean? success True if set successfully, nil on error
---@usage AirbaseAutoCapture(airbase, true)
function AirbaseAutoCapture(airbase, enabled)
    if not airbase then
        _HarnessInternal.log.error(
            "AirbaseAutoCapture requires valid airbase",
            "Airbase.AutoCapture"
        )
        return nil
    end

    if type(enabled) ~= "boolean" then
        _HarnessInternal.log.error(
            "AirbaseAutoCapture requires boolean enabled value",
            "Airbase.AutoCapture"
        )
        return nil
    end

    local success, result = pcall(airbase.autoCapture, airbase, enabled)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set auto capture: " .. tostring(result),
            "Airbase.AutoCapture"
        )
        return nil
    end

    return true
end

--- Check if airbase auto capture is enabled
---@param airbase table? Airbase object
---@return boolean? enabled True if auto capture is on, nil on error
---@usage local isOn = airbaseAutoCaptureIsOn(airbase)
function AirbaseAutoCaptureIsOn(airbase)
    if not airbase then
        _HarnessInternal.log.error(
            "AirbaseAutoCaptureIsOn requires valid airbase",
            "Airbase.AutoCaptureIsOn"
        )
        return nil
    end

    local success, result = pcall(airbase.autoCaptureIsOn, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check auto capture status: " .. tostring(result),
            "Airbase.AutoCaptureIsOn"
        )
        return nil
    end

    return result
end

--- Set airbase coalition
---@param airbase table? Airbase object
---@param coalitionId number Coalition ID
---@return boolean? success True if set successfully, nil on error
---@usage SetAirbaseCoalition(airbase, coalition.side.BLUE)
function SetAirbaseCoalition(airbase, coalitionId)
    if not airbase then
        _HarnessInternal.log.error(
            "SetAirbaseCoalition requires valid airbase",
            "Airbase.SetCoalition"
        )
        return nil
    end

    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "SetAirbaseCoalition requires valid coalition ID",
            "Airbase.SetCoalition"
        )
        return nil
    end

    local success, result = pcall(airbase.setCoalition, airbase, coalitionId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set airbase coalition: " .. tostring(result),
            "Airbase.SetCoalition"
        )
        return nil
    end

    return true
end

--- Get airbase warehouse
---@param airbase table? Airbase object
---@return table? warehouse Warehouse object if found, nil otherwise
---@usage local warehouse = getAirbaseWarehouse(airbase)
function GetAirbaseWarehouse(airbase)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseWarehouse requires valid airbase",
            "Airbase.GetWarehouse"
        )
        return nil
    end

    local success, result = pcall(airbase.getWarehouse, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase warehouse: " .. tostring(result),
            "Airbase.GetWarehouse"
        )
        return nil
    end

    return result
end

--- Get free parking terminal
---@param airbase table? Airbase object
---@param terminalType any? Terminal type filter
---@return table? terminal Free parking terminal if found, nil otherwise
---@usage local terminal = getAirbaseFreeParkingTerminal(airbase)
function GetAirbaseFreeParkingTerminal(airbase, terminalType)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseFreeParkingTerminal requires valid airbase",
            "Airbase.GetFreeParkingTerminal"
        )
        return nil
    end

    local success, result = pcall(airbase.getFreeParkingTerminal, airbase, terminalType)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get free parking terminal: " .. tostring(result),
            "Airbase.GetFreeParkingTerminal"
        )
        return nil
    end

    return result
end

--- Get free parking terminals by type
---@param airbase table? Airbase object
---@param terminalType any? Terminal type filter
---@param multiple boolean? Return multiple terminals
---@return table? terminals Free parking terminals if found, nil otherwise
---@usage local terminals = getAirbaseFreeParkingTerminalByType(airbase, type, true)
function GetAirbaseFreeParkingTerminalByType(airbase, terminalType, multiple)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseFreeParkingTerminalByType requires valid airbase",
            "Airbase.GetFreeParkingTerminalByType"
        )
        return nil
    end

    local success, result = pcall(airbase.getFreeParkingTerminal, airbase, terminalType, multiple)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get free parking terminals by type: " .. tostring(result),
            "Airbase.GetFreeParkingTerminalByType"
        )
        return nil
    end

    return result
end

--- Get free airbase parking terminal
---@param airbase table? Airbase object
---@param terminalType any? Terminal type filter
---@return table? terminal Free parking terminal if found, nil otherwise
---@usage local terminal = getFreeAirbaseParkingTerminal(airbase)
function GetFreeAirbaseParkingTerminal(airbase, terminalType)
    if not airbase then
        _HarnessInternal.log.error(
            "GetFreeAirbaseParkingTerminal requires valid airbase",
            "Airbase.GetFreeAirbaseParkingTerminal"
        )
        return nil
    end

    local success, result = pcall(airbase.getFreeAirbaseParkingTerminal, airbase, terminalType)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get free airbase parking terminal: " .. tostring(result),
            "Airbase.GetFreeAirbaseParkingTerminal"
        )
        return nil
    end

    return result
end

--- Get airbase parking terminal
---@param airbase table? Airbase object
---@param terminal number Terminal number
---@return table? terminal Parking terminal if found, nil otherwise
---@usage local terminal = getAirbaseParkingTerminal(airbase, 1)
function GetAirbaseParkingTerminal(airbase, terminal)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseParkingTerminal requires valid airbase",
            "Airbase.GetParkingTerminal"
        )
        return nil
    end

    if not terminal or type(terminal) ~= "number" then
        _HarnessInternal.log.error(
            "GetAirbaseParkingTerminal requires valid terminal number",
            "Airbase.GetParkingTerminal"
        )
        return nil
    end

    local success, result = pcall(airbase.getParkingTerminal, airbase, terminal)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get parking terminal: " .. tostring(result),
            "Airbase.GetParkingTerminal"
        )
        return nil
    end

    return result
end

--- Get airbase parking terminal by index
---@param airbase table? Airbase object
---@param index number Terminal index
---@return table? terminal Parking terminal if found, nil otherwise
---@usage local terminal = getAirbaseParkingTerminalByIndex(airbase, 1)
function GetAirbaseParkingTerminalByIndex(airbase, index)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseParkingTerminalByIndex requires valid airbase",
            "Airbase.GetParkingTerminalByIndex"
        )
        return nil
    end

    if not index or type(index) ~= "number" then
        _HarnessInternal.log.error(
            "GetAirbaseParkingTerminalByIndex requires valid index",
            "Airbase.GetParkingTerminalByIndex"
        )
        return nil
    end

    local success, result = pcall(airbase.getParkingTerminalByIndex, airbase, index)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get parking terminal by index: " .. tostring(result),
            "Airbase.GetParkingTerminalByIndex"
        )
        return nil
    end

    return result
end

--- Get airbase parking count
---@param airbase table? Airbase object
---@return number? count Number of parking spots, nil on error
---@usage local count = getAirbaseParkingCount(airbase)
function GetAirbaseParkingCount(airbase)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseParkingCount requires valid airbase",
            "Airbase.GetParkingCount"
        )
        return nil
    end

    local success, result = pcall(airbase.getParkingCount, airbase)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get parking count: " .. tostring(result),
            "Airbase.GetParkingCount"
        )
        return nil
    end

    return result
end

--- Get airbase runway details
---@param airbase table? Airbase object
---@param runwayIndex number? Specific runway index
---@return table? details Runway details if found, nil otherwise
---@usage local details = getAirbaseRunwayDetails(airbase, 1)
function GetAirbaseRunwayDetails(airbase, runwayIndex)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseRunwayDetails requires valid airbase",
            "Airbase.GetRunwayDetails"
        )
        return nil
    end

    if runwayIndex and type(runwayIndex) ~= "number" then
        _HarnessInternal.log.error(
            "getAirbaseRunwayDetails runway index must be a number if provided",
            "Airbase.GetRunwayDetails"
        )
        return nil
    end

    local success, result = pcall(airbase.getRunwayDetails, airbase, runwayIndex)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get runway details: " .. tostring(result),
            "Airbase.GetRunwayDetails"
        )
        return nil
    end

    return result
end

--- Get airbase meteorological data
---@param airbase table? Airbase object
---@param height number? Height for weather data
---@return table? meteo Weather data if found, nil otherwise
---@usage local weather = getAirbaseMeteo(airbase, 100)
function GetAirbaseMeteo(airbase, height)
    if not airbase then
        _HarnessInternal.log.error("GetAirbaseMeteo requires valid airbase", "Airbase.GetMeteo")
        return nil
    end

    local success, result = pcall(airbase.getMeteo, airbase, height)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get airbase meteo: " .. tostring(result),
            "Airbase.GetMeteo"
        )
        return nil
    end

    return result
end

--- Get airbase wind with turbulence
---@param airbase table? Airbase object
---@param height number? Height for wind data
---@return table? wind Wind data with turbulence if found, nil otherwise
---@usage local wind = getAirbaseWindWithTurbulence(airbase, 100)
function GetAirbaseWindWithTurbulence(airbase, height)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseWindWithTurbulence requires valid airbase",
            "Airbase.GetWindWithTurbulence"
        )
        return nil
    end

    local success, result = pcall(airbase.getWindWithTurbulence, airbase, height)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get wind with turbulence: " .. tostring(result),
            "Airbase.GetWindWithTurbulence"
        )
        return nil
    end

    return result
end

--- Check if airbase provides service
---@param airbase table? Airbase object
---@param service number Service type ID
---@return boolean? provided True if service is provided, nil on error
---@usage local hasService = getAirbaseIsServiceProvided(airbase, 1)
function GetAirbaseIsServiceProvided(airbase, service)
    if not airbase then
        _HarnessInternal.log.error(
            "GetAirbaseIsServiceProvided requires valid airbase",
            "Airbase.GetIsServiceProvided"
        )
        return nil
    end

    if not service or type(service) ~= "number" then
        _HarnessInternal.log.error(
            "GetAirbaseIsServiceProvided requires valid service type",
            "Airbase.GetIsServiceProvided"
        )
        return nil
    end

    local success, result = pcall(airbase.getIsServiceProvided, airbase, service)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check service availability: " .. tostring(result),
            "Airbase.GetIsServiceProvided"
        )
        return nil
    end

    return result
end

local AirbaseInternal = {}

function AirbaseInternal.finiteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function AirbaseInternal.protectedObjectMethod(object, methodName, ...)
    if object == nil then
        return false, "missing object"
    end
    local methodOk, method = pcall(function()
        return object[methodName]
    end)
    if not methodOk or type(method) ~= "function" then
        return false, methodOk and (methodName .. " unavailable") or method
    end
    return pcall(method, object, ...)
end

function AirbaseInternal.shortestHeadingDifference(first, second)
    local difference = (first - second + 180) % 360 - 180
    return math.abs(difference)
end

function AirbaseInternal.isGroundPoint(value)
    return type(value) == "table"
        and AirbaseInternal.finiteNumber(value.x)
        and (
            (IsVec2(value) and AirbaseInternal.finiteNumber(value.y))
            or (IsVec3(value) and AirbaseInternal.finiteNumber(value.z))
        )
end

--- Get the reciprocal runway designator
---@param name any Runway designator
---@return string reciprocalName Reciprocal designator
function GetReciprocalRunwayName(name)
    local text = tostring(name)
    local designator = tonumber(string.match(text, "^%s*(%d+)"))
    local suffix = string.match(text, "%d+%s*([LRC])") or ""
    if not designator then
        return text .. "-R"
    end
    local reciprocal = designator + 18
    if reciprocal > 36 then
        reciprocal = reciprocal - 36
    end
    local reciprocalSuffix = ({ L = "R", R = "L", C = "C" })[suffix] or ""
    return string.format("%02d%s", reciprocal, reciprocalSuffix)
end

function AirbaseInternal.buildDirectionalRunway(
    airbaseName,
    name,
    headingDeg,
    center,
    lengthM,
    widthM,
    sourceIndex,
    courseAdjusted
)
    local forward = HeadingVector2D(headingDeg)
    local right = HeadingVector2D(headingDeg + 90)
    local threshold = FromBearingDistance(center, headingDeg, -lengthM * 0.5)
    local departureEnd = FromBearingDistance(center, headingDeg, lengthM * 0.5)
    local runway = {
        airbase = nil,
        airbaseName = airbaseName,
        name = tostring(name),
        key = airbaseName .. "|" .. tostring(name),
        headingDeg = (headingDeg + 360) % 360,
        lengthM = lengthM,
        widthM = widthM,
        center = Vec3(center.x, center.y, center.z),
        threshold = threshold,
        departureEnd = departureEnd,
        forward = forward,
        right = right,
        sourceIndex = sourceIndex,
        courseAdjusted = courseAdjusted,
    }
    runway.frame = HeadingFrame2D(runway.threshold, runway.headingDeg)
    return runway
end

function AirbaseInternal.parseRawRunway(rawRunway, sourceIndex)
    if type(rawRunway) ~= "table" then
        _HarnessInternal.log.error(
            "Skipped malformed runway record at source index " .. tostring(sourceIndex),
            "Airbase.NormalizeDirectionalRunways"
        )
        return nil
    end

    local parsed = {
        lengthM = tonumber(rawRunway.length),
        widthM = tonumber(rawRunway.width),
        course = tonumber(rawRunway.course),
        center = rawRunway.position,
        name = rawRunway.Name or rawRunway.name,
    }
    if
        not AirbaseInternal.finiteNumber(parsed.lengthM)
        or parsed.lengthM <= 0
        or not AirbaseInternal.finiteNumber(parsed.widthM)
        or parsed.widthM <= 0
        or not AirbaseInternal.finiteNumber(parsed.course)
        or type(parsed.center) ~= "table"
        or not AirbaseInternal.finiteNumber(parsed.center.x)
        or not AirbaseInternal.finiteNumber(parsed.center.y)
        or not AirbaseInternal.finiteNumber(parsed.center.z)
    then
        _HarnessInternal.log.error(
            "Skipped malformed runway record at source index " .. tostring(sourceIndex),
            "Airbase.NormalizeDirectionalRunways"
        )
        return nil
    end
    return parsed
end

function AirbaseInternal.directionalRunwayNameAndHeading(parsed, reciprocalSanityDeg)
    local headingDeg = (math.deg(-parsed.course) + 360) % 360
    local designator
    if parsed.name ~= nil then
        designator = tonumber(string.match(tostring(parsed.name), "^%s*(%d+)"))
    end
    local courseAdjusted = false
    if
        designator
        and AirbaseInternal.shortestHeadingDifference(headingDeg, (designator * 10) % 360)
            > reciprocalSanityDeg
    then
        headingDeg = (headingDeg + 180) % 360
        courseAdjusted = true
    end

    local name = parsed.name
    if name == nil then
        local roundedDesignator = math.floor((headingDeg + 5) / 10) % 36
        name = string.format("%02d", roundedDesignator == 0 and 36 or roundedDesignator)
    end
    return name, headingDeg, courseAdjusted
end

function AirbaseInternal.appendDirectionalRunwayPair(
    runways,
    airbaseName,
    rawRunway,
    sourceIndex,
    reciprocalSanityDeg
)
    local parsed = AirbaseInternal.parseRawRunway(rawRunway, sourceIndex)
    if not parsed then
        return
    end
    local name, headingDeg, courseAdjusted =
        AirbaseInternal.directionalRunwayNameAndHeading(parsed, reciprocalSanityDeg)
    runways[#runways + 1] = AirbaseInternal.buildDirectionalRunway(
        airbaseName,
        name,
        headingDeg,
        parsed.center,
        parsed.lengthM,
        parsed.widthM,
        sourceIndex,
        courseAdjusted
    )
    runways[#runways + 1] = AirbaseInternal.buildDirectionalRunway(
        airbaseName,
        GetReciprocalRunwayName(name),
        headingDeg + 180,
        parsed.center,
        parsed.lengthM,
        parsed.widthM,
        sourceIndex,
        courseAdjusted
    )
end

--- Normalize physical runway records into directional runway records
---@param airbaseName string Airbase name
---@param rawRunways table Raw Airbase:getRunways() records
---@param reciprocalSanityDeg number? Maximum designator/course difference before correction
---@return table? runways Directional runway array
function NormalizeDirectionalRunways(airbaseName, rawRunways, reciprocalSanityDeg)
    reciprocalSanityDeg = reciprocalSanityDeg == nil and 60 or reciprocalSanityDeg
    if
        type(airbaseName) ~= "string"
        or airbaseName == ""
        or type(rawRunways) ~= "table"
        or not AirbaseInternal.finiteNumber(reciprocalSanityDeg)
        or reciprocalSanityDeg < 0
        or reciprocalSanityDeg > 180
    then
        _HarnessInternal.log.error(
            "NormalizeDirectionalRunways requires an airbase name, runway array, and sanity angle",
            "Airbase.NormalizeDirectionalRunways"
        )
        return nil
    end

    local runways = {}
    for sourceIndex = 1, #rawRunways do
        AirbaseInternal.appendDirectionalRunwayPair(
            runways,
            airbaseName,
            rawRunways[sourceIndex],
            sourceIndex,
            reciprocalSanityDeg
        )
    end
    return runways
end

--- Get directional runways from the Harness Airbase:getRunways compatibility boundary
---@param airbase table Airbase object
---@param reciprocalSanityDeg number? Maximum designator/course difference before correction
---@return table? runways Directional runway array
function GetDirectionalRunways(airbase, reciprocalSanityDeg)
    local nameOk, airbaseName = AirbaseInternal.protectedObjectMethod(airbase, "getName")
    if not nameOk or type(airbaseName) ~= "string" or airbaseName == "" then
        _HarnessInternal.log.error(
            "Failed to get airbase name: " .. tostring(airbaseName),
            "Airbase.GetDirectionalRunways"
        )
        return nil
    end
    local runwayOk, rawRunways = AirbaseInternal.protectedObjectMethod(airbase, "getRunways")
    if not runwayOk or type(rawRunways) ~= "table" then
        _HarnessInternal.log.error(
            "Failed Airbase:getRunways compatibility call: " .. tostring(rawRunways),
            "Airbase.GetDirectionalRunways"
        )
        return nil
    end
    local runways = NormalizeDirectionalRunways(airbaseName, rawRunways, reciprocalSanityDeg)
    if not runways then
        return nil
    end
    for _, runway in ipairs(runways) do
        runway.airbase = airbase
    end
    return runways
end

--- Get point coordinates relative to a runway threshold
---@param runway table Directional runway
---@param point table Vec3 world point
---@return number? alongM Forward distance
---@return number? lateralM Right distance
function GetRunwayRelativePosition(runway, point)
    if type(runway) ~= "table" then
        _HarnessInternal.log.error(
            "GetRunwayRelativePosition requires a runway",
            "Airbase.GetRunwayRelativePosition"
        )
        return nil, nil
    end
    return ProjectPointToHeadingFrame2D(runway.frame, point)
end

--- Get velocity components relative to a runway heading
---@param runway table Directional runway
---@param velocity table Vec3 velocity
---@return number? forwardMps Forward velocity
---@return number? lateralMps Right velocity
function GetRunwayRelativeVelocity(runway, velocity)
    if type(runway) ~= "table" then
        _HarnessInternal.log.error(
            "GetRunwayRelativeVelocity requires a runway",
            "Airbase.GetRunwayRelativeVelocity"
        )
        return nil, nil
    end
    return ProjectVectorToHeadingFrame2D(runway.frame, velocity)
end

--- Get angular runway lineup error
---@param runway table Directional runway
---@param point table Vec3 world point
---@param minRangeM number? Minimum approach range, default 50 m
---@return number? degrees Positive values are right of centerline
function GetRunwayLineupError(runway, point, minRangeM)
    minRangeM = minRangeM == nil and 50 or minRangeM
    if not AirbaseInternal.finiteNumber(minRangeM) or minRangeM < 0 then
        _HarnessInternal.log.error(
            "GetRunwayLineupError requires non-negative range",
            "Airbase.GetRunwayLineupError"
        )
        return nil
    end
    local alongM, lateralM = GetRunwayRelativePosition(runway, point)
    if alongM == nil or -alongM <= minRangeM then
        return nil
    end
    return math.deg(math.atan2(lateralM, -alongM))
end

--- Get glidepath angle from a point to a runway threshold
---@param runway table Directional runway
---@param point table Vec3 world point
---@param thresholdElevationM number Threshold elevation in meters
---@param minRangeM number? Minimum horizontal range, default 50 m
---@return number? degrees Glidepath angle
function GetRunwayGlidepathAngle(runway, point, thresholdElevationM, minRangeM)
    minRangeM = minRangeM == nil and 50 or minRangeM
    if
        not IsVec3(point)
        or not AirbaseInternal.finiteNumber(thresholdElevationM)
        or not AirbaseInternal.finiteNumber(minRangeM)
        or minRangeM < 0
    then
        _HarnessInternal.log.error(
            "GetRunwayGlidepathAngle requires point, threshold elevation, and non-negative range",
            "Airbase.GetRunwayGlidepathAngle"
        )
        return nil
    end
    local alongM, lateralM = GetRunwayRelativePosition(runway, point)
    if alongM == nil then
        return nil
    end
    local rangeM = math.sqrt(alongM * alongM + lateralM * lateralM)
    if rangeM <= minRangeM then
        return nil
    end
    return math.deg(math.atan2(point.y - thresholdElevationM, rangeM))
end

--- Get the wind component opposing a landing heading
---@param wind table Vec3 wind velocity
---@param headingDeg number Landing heading
---@return number? mps Headwind component
function GetHeadwindComponent(wind, headingDeg)
    if
        type(wind) ~= "table"
        or not AirbaseInternal.finiteNumber(wind.x)
        or not AirbaseInternal.finiteNumber(wind.z)
    then
        _HarnessInternal.log.error(
            "GetHeadwindComponent requires a wind vector",
            "Airbase.GetHeadwindComponent"
        )
        return nil
    end
    local heading = HeadingVector2D(headingDeg)
    return heading and -(wind.x * heading.x + wind.z * heading.y) or nil
end

--- Select the first runway with the greatest headwind component
---@param runways table Directional runway array
---@param wind table Vec3 wind velocity
---@return table? runway Selected runway
---@return number? componentMps Headwind component
function SelectRunwayByHeadwind(runways, wind)
    if type(runways) ~= "table" then
        _HarnessInternal.log.error(
            "SelectRunwayByHeadwind requires a runway array",
            "Airbase.SelectRunwayByHeadwind"
        )
        return nil, nil
    end
    local bestRunway
    local bestComponent
    for _, runway in ipairs(runways) do
        local component = type(runway) == "table" and GetHeadwindComponent(wind, runway.headingDeg)
            or nil
        if component == nil then
            return nil, nil
        end
        if bestComponent == nil or component > bestComponent then
            bestRunway = runway
            bestComponent = component
        end
    end
    return bestRunway, bestComponent
end

--- Find the runway whose center is nearest to a point
---@param runways table Directional runway array
---@param point table Vec2 or Vec3 point
---@return table? runway Nearest runway
---@return number? distanceM Distance to its center
function FindNearestRunway(runways, point)
    if type(runways) ~= "table" or not AirbaseInternal.isGroundPoint(point) then
        _HarnessInternal.log.error(
            "FindNearestRunway requires runways and point",
            "Airbase.FindNearestRunway"
        )
        return nil, nil
    end
    local bestRunway
    local bestDistance
    for _, runway in ipairs(runways) do
        local distanceM = type(runway) == "table"
                and AirbaseInternal.isGroundPoint(runway.center)
                and Distance2D(runway.center, point)
            or nil
        if distanceM ~= nil and (bestDistance == nil or distanceM < bestDistance) then
            bestRunway = runway
            bestDistance = distanceM
        end
    end
    return bestRunway, bestDistance
end

function AirbaseInternal.collectNamedAirbases(target, list)
    if type(list) ~= "table" then
        return
    end
    for _, airbase in pairs(list) do
        local nameOk, name = AirbaseInternal.protectedObjectMethod(airbase, "getName")
        if nameOk and type(name) == "string" and name ~= "" then
            if target[name] == nil then
                target[name] = airbase
            end
        else
            _HarnessInternal.log.error(
                "Skipped invalid airbase handle: " .. tostring(name),
                "Airbase.GetAllAirbases"
            )
        end
    end
end

--- Enumerate all airbases without caching
---@return table? airbases Name-sorted airbase handles
function GetAllAirbases()
    local byName = {}
    local successfulCalls = 0
    if type(world) == "table" and type(world.getAirbases) == "function" then
        local success, result = pcall(world.getAirbases)
        if success and type(result) == "table" then
            successfulCalls = successfulCalls + 1
            AirbaseInternal.collectNamedAirbases(byName, result)
        else
            _HarnessInternal.log.error(
                "world.getAirbases failed: " .. tostring(result),
                "Airbase.GetAllAirbases"
            )
        end
    end

    if type(coalition) == "table" and type(coalition.getAirbases) == "function" then
        local sides = type(coalition.side) == "table"
                and { coalition.side.NEUTRAL, coalition.side.RED, coalition.side.BLUE }
            or {}
        for _, side in ipairs(sides) do
            local success, result = pcall(coalition.getAirbases, side)
            if success and type(result) == "table" then
                successfulCalls = successfulCalls + 1
                AirbaseInternal.collectNamedAirbases(byName, result)
            else
                _HarnessInternal.log.error(
                    "coalition.getAirbases failed for side "
                        .. tostring(side)
                        .. ": "
                        .. tostring(result),
                    "Airbase.GetAllAirbases"
                )
            end
        end
    end
    if successfulCalls == 0 then
        return nil
    end

    local names = {}
    for name in pairs(byName) do
        names[#names + 1] = name
    end
    table.sort(names)
    local airbases = {}
    for _, name in ipairs(names) do
        airbases[#airbases + 1] = byName[name]
    end
    return airbases
end

--- Filter a caller-supplied airbase list by distance
---@param airbases table Airbase handle array
---@param point table Vec2 or Vec3 point
---@param radiusM number Search radius in meters
---@return table? matches Distance-sorted matches
function FindAirbasesWithin(airbases, point, radiusM)
    if
        type(airbases) ~= "table"
        or not AirbaseInternal.isGroundPoint(point)
        or not AirbaseInternal.finiteNumber(radiusM)
        or radiusM < 0
    then
        _HarnessInternal.log.error(
            "FindAirbasesWithin requires airbases, point, and non-negative radius",
            "Airbase.FindAirbasesWithin"
        )
        return nil
    end

    local matches = {}
    for _, airbase in ipairs(airbases) do
        local nameOk, name = AirbaseInternal.protectedObjectMethod(airbase, "getName")
        local pointOk, airbasePoint = AirbaseInternal.protectedObjectMethod(airbase, "getPoint")
        if
            nameOk
            and type(name) == "string"
            and pointOk
            and AirbaseInternal.isGroundPoint(airbasePoint)
        then
            local distanceM = Distance2D(airbasePoint, point)
            if distanceM <= radiusM then
                matches[#matches + 1] = {
                    airbase = airbase,
                    distanceM = distanceM,
                    _name = name,
                }
            end
        else
            _HarnessInternal.log.error(
                "Skipped invalid airbase during distance search",
                "Airbase.FindAirbasesWithin"
            )
        end
    end
    table.sort(matches, function(first, second)
        if first.distanceM ~= second.distanceM then
            return first.distanceM < second.distanceM
        end
        return first._name < second._name
    end)
    for _, match in ipairs(matches) do
        match._name = nil
    end
    return matches
end
