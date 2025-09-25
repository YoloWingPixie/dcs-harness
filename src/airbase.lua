--[[
    Airbase Module - DCS World Airbase API Wrappers
    
    This module provides validated wrapper functions for DCS airbase operations,
    including runway queries, parking spots, and airbase information.
]]
require("logger")
--- Get airbase by name
---@param airbaseName string? Name of the airbase
---@return table? airbase Airbase object if found, nil otherwise
---@usage local airbase = getAirbaseByName("Batumi")
function GetAirbaseByName(airbaseName)
    if not airbaseName or type(airbaseName) ~= "string" then
        _HarnessInternal.log.error("GetAirbaseByName requires valid airbase name", "Airbase.GetByName")
        return nil
    end

    local success, result = pcall(Airbase.getByName, airbaseName)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase by name: " .. tostring(result), "Airbase.GetByName")
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
        _HarnessInternal.log.error("GetAirbaseDescriptor requires valid airbase", "Airbase.GetDescriptor")
        return nil
    end

    local success, result = pcall(airbase.getDescriptor, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase descriptor: " .. tostring(result), "Airbase.GetDescriptor")
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
        _HarnessInternal.log.error("GetAirbaseCallsign requires valid airbase", "Airbase.GetCallsign")
        return nil
    end

    local success, result = pcall(airbase.getCallsign, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase callsign: " .. tostring(result), "Airbase.GetCallsign")
        return nil
    end

    return result
end

--- Get airbase unit
---@param airbase table? Airbase object
---@return table? unit Airbase unit if found, nil otherwise
---@usage local unit = getAirbaseUnit(airbase)
function GetAirbaseUnit(airbase)
    if not airbase then
        _HarnessInternal.log.error("GetAirbaseUnit requires valid airbase", "Airbase.GetUnit")
        return nil
    end

    local success, result = pcall(airbase.getUnit, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase unit: " .. tostring(result), "Airbase.GetUnit")
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
        _HarnessInternal.log.error("GetAirbaseCategoryName requires valid airbase", "Airbase.GetCategoryName")
        return nil
    end

    local success, result = pcall(airbase.getCategoryName, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase category name: " .. tostring(result), "Airbase.GetCategoryName")
        return nil
    end

    return result
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
        _HarnessInternal.log.error("Failed to get airbase parking: " .. tostring(result), "Airbase.GetParking")
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
        _HarnessInternal.log.error("Failed to get airbase runways: " .. tostring(result), "Airbase.GetRunways")
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
        _HarnessInternal.log.error("GetAirbaseTechObjectPos requires valid airbase", "Airbase.GetTechObjectPos")
        return nil
    end

    if not techObjectType or type(techObjectType) ~= "number" then
        _HarnessInternal.log.error("GetAirbaseTechObjectPos requires valid tech object type", "Airbase.GetTechObjectPos")
        return nil
    end

    local success, result = pcall(airbase.getTechObjectPos, airbase, techObjectType)
    if not success then
        _HarnessInternal.log.error("Failed to get tech object positions: " .. tostring(result), "Airbase.GetTechObjectPos")
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
        _HarnessInternal.log.error("GetAirbaseDispatcherTowerPos requires valid airbase", "Airbase.GetDispatcherTowerPos")
        return nil
    end

    local success, result = pcall(airbase.getDispatcherTowerPos, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get dispatcher tower position: " .. tostring(result), "Airbase.GetDispatcherTowerPos")
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
        _HarnessInternal.log.error("GetAirbaseRadioSilentMode requires valid airbase", "Airbase.GetRadioSilentMode")
        return nil
    end

    local success, result = pcall(airbase.getRadioSilentMode, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get radio silent mode: " .. tostring(result), "Airbase.GetRadioSilentMode")
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
        _HarnessInternal.log.error("SetAirbaseRadioSilentMode requires valid airbase", "Airbase.SetRadioSilentMode")
        return nil
    end

    if type(silent) ~= "boolean" then
        _HarnessInternal.log.error("SetAirbaseRadioSilentMode requires boolean silent value", "Airbase.SetRadioSilentMode")
        return nil
    end

    local success, result = pcall(airbase.setRadioSilentMode, airbase, silent)
    if not success then
        _HarnessInternal.log.error("Failed to set radio silent mode: " .. tostring(result), "Airbase.SetRadioSilentMode")
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
        _HarnessInternal.log.error("Failed to get airbase beacon: " .. tostring(result), "Airbase.GetBeacon")
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
        _HarnessInternal.log.error("AirbaseAutoCapture requires valid airbase", "Airbase.AutoCapture")
        return nil
    end

    if type(enabled) ~= "boolean" then
        _HarnessInternal.log.error("AirbaseAutoCapture requires boolean enabled value", "Airbase.AutoCapture")
        return nil
    end

    local success, result = pcall(airbase.autoCapture, airbase, enabled)
    if not success then
        _HarnessInternal.log.error("Failed to set auto capture: " .. tostring(result), "Airbase.AutoCapture")
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
        _HarnessInternal.log.error("AirbaseAutoCaptureIsOn requires valid airbase", "Airbase.AutoCaptureIsOn")
        return nil
    end

    local success, result = pcall(airbase.autoCaptureIsOn, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to check auto capture status: " .. tostring(result), "Airbase.AutoCaptureIsOn")
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
        _HarnessInternal.log.error("SetAirbaseCoalition requires valid airbase", "Airbase.SetCoalition")
        return nil
    end

    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("SetAirbaseCoalition requires valid coalition ID", "Airbase.SetCoalition")
        return nil
    end

    local success, result = pcall(airbase.setCoalition, airbase, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to set airbase coalition: " .. tostring(result), "Airbase.SetCoalition")
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
        _HarnessInternal.log.error("GetAirbaseWarehouse requires valid airbase", "Airbase.GetWarehouse")
        return nil
    end

    local success, result = pcall(airbase.getWarehouse, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase warehouse: " .. tostring(result), "Airbase.GetWarehouse")
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
        _HarnessInternal.log.error("GetAirbaseFreeParkingTerminal requires valid airbase", "Airbase.GetFreeParkingTerminal")
        return nil
    end

    local success, result = pcall(airbase.getFreeParkingTerminal, airbase, terminalType)
    if not success then
        _HarnessInternal.log.error("Failed to get free parking terminal: " .. tostring(result), "Airbase.GetFreeParkingTerminal")
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
        _HarnessInternal.log.error("GetAirbaseFreeParkingTerminalByType requires valid airbase", "Airbase.GetFreeParkingTerminalByType")
        return nil
    end

    local success, result = pcall(airbase.getFreeParkingTerminal, airbase, terminalType, multiple)
    if not success then
        _HarnessInternal.log.error("Failed to get free parking terminals by type: " .. tostring(result), "Airbase.GetFreeParkingTerminalByType")
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
        _HarnessInternal.log.error("GetFreeAirbaseParkingTerminal requires valid airbase", "Airbase.GetFreeAirbaseParkingTerminal")
        return nil
    end

    local success, result = pcall(airbase.getFreeAirbaseParkingTerminal, airbase, terminalType)
    if not success then
        _HarnessInternal.log.error("Failed to get free airbase parking terminal: " .. tostring(result), "Airbase.GetFreeAirbaseParkingTerminal")
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
        _HarnessInternal.log.error("GetAirbaseParkingTerminal requires valid airbase", "Airbase.GetParkingTerminal")
        return nil
    end

    if not terminal or type(terminal) ~= "number" then
        _HarnessInternal.log.error("GetAirbaseParkingTerminal requires valid terminal number", "Airbase.GetParkingTerminal")
        return nil
    end

    local success, result = pcall(airbase.getParkingTerminal, airbase, terminal)
    if not success then
        _HarnessInternal.log.error("Failed to get parking terminal: " .. tostring(result), "Airbase.GetParkingTerminal")
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
        _HarnessInternal.log.error("GetAirbaseParkingTerminalByIndex requires valid airbase", "Airbase.GetParkingTerminalByIndex")
        return nil
    end

    if not index or type(index) ~= "number" then
        _HarnessInternal.log.error("GetAirbaseParkingTerminalByIndex requires valid index", "Airbase.GetParkingTerminalByIndex")
        return nil
    end

    local success, result = pcall(airbase.getParkingTerminalByIndex, airbase, index)
    if not success then
        _HarnessInternal.log.error("Failed to get parking terminal by index: " .. tostring(result), "Airbase.GetParkingTerminalByIndex")
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
        _HarnessInternal.log.error("GetAirbaseParkingCount requires valid airbase", "Airbase.GetParkingCount")
        return nil
    end

    local success, result = pcall(airbase.getParkingCount, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get parking count: " .. tostring(result), "Airbase.GetParkingCount")
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
        _HarnessInternal.log.error("GetAirbaseRunwayDetails requires valid airbase", "Airbase.GetRunwayDetails")
        return nil
    end

    if runwayIndex and type(runwayIndex) ~= "number" then
        _HarnessInternal.log.error("getAirbaseRunwayDetails runway index must be a number if provided", "Airbase.GetRunwayDetails")
        return nil
    end

    local success, result = pcall(airbase.getRunwayDetails, airbase, runwayIndex)
    if not success then
        _HarnessInternal.log.error("Failed to get runway details: " .. tostring(result), "Airbase.GetRunwayDetails")
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
        _HarnessInternal.log.error("Failed to get airbase meteo: " .. tostring(result), "Airbase.GetMeteo")
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
        _HarnessInternal.log.error("GetAirbaseWindWithTurbulence requires valid airbase", "Airbase.GetWindWithTurbulence")
        return nil
    end

    local success, result = pcall(airbase.getWindWithTurbulence, airbase, height)
    if not success then
        _HarnessInternal.log.error("Failed to get wind with turbulence: " .. tostring(result), "Airbase.GetWindWithTurbulence")
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
        _HarnessInternal.log.error("GetAirbaseIsServiceProvided requires valid airbase", "Airbase.GetIsServiceProvided")
        return nil
    end

    if not service or type(service) ~= "number" then
        _HarnessInternal.log.error("GetAirbaseIsServiceProvided requires valid service type", "Airbase.GetIsServiceProvided")
        return nil
    end

    local success, result = pcall(airbase.getIsServiceProvided, airbase, service)
    if not success then
        _HarnessInternal.log.error("Failed to check service availability: " .. tostring(result), "Airbase.GetIsServiceProvided")
        return nil
    end

    return result
end