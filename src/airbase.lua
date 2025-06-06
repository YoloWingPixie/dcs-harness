--[[
    Airbase Module - DCS World Airbase API Wrappers
    
    This module provides validated wrapper functions for DCS airbase operations,
    including runway queries, parking spots, and airbase information.
]]

--- Get airbase by name
---@param airbaseName string? Name of the airbase
---@return table? airbase Airbase object if found, nil otherwise
---@usage local airbase = getAirbaseByName("Batumi")
function getAirbaseByName(airbaseName)
    if not airbaseName or type(airbaseName) ~= "string" then
        _HarnessInternal.log.error("getAirbaseByName requires valid airbase name", "Airbase.getByName")
        return nil
    end

    local success, result = pcall(Airbase.getByName, airbaseName)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase by name: " .. tostring(result), "Airbase.getByName")
        return nil
    end

    return result
end

--- Get airbase descriptor
---@param airbase table? Airbase object
---@return table? descriptor Airbase descriptor if found, nil otherwise
---@usage local desc = getAirbaseDescriptor(airbase)
function getAirbaseDescriptor(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseDescriptor requires valid airbase", "Airbase.getDescriptor")
        return nil
    end

    local success, result = pcall(airbase.getDescriptor, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase descriptor: " .. tostring(result), "Airbase.getDescriptor")
        return nil
    end

    return result
end

--- Get airbase callsign
---@param airbase table? Airbase object
---@return string? callsign Airbase callsign if found, nil otherwise
---@usage local callsign = getAirbaseCallsign(airbase)
function getAirbaseCallsign(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseCallsign requires valid airbase", "Airbase.getCallsign")
        return nil
    end

    local success, result = pcall(airbase.getCallsign, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase callsign: " .. tostring(result), "Airbase.getCallsign")
        return nil
    end

    return result
end

--- Get airbase unit
---@param airbase table? Airbase object
---@return table? unit Airbase unit if found, nil otherwise
---@usage local unit = getAirbaseUnit(airbase)
function getAirbaseUnit(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseUnit requires valid airbase", "Airbase.getUnit")
        return nil
    end

    local success, result = pcall(airbase.getUnit, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase unit: " .. tostring(result), "Airbase.getUnit")
        return nil
    end

    return result
end

--- Get airbase category name
---@param airbase table? Airbase object
---@return string? category Category name if found, nil otherwise
---@usage local category = getAirbaseCategoryName(airbase)
function getAirbaseCategoryName(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseCategoryName requires valid airbase", "Airbase.getCategoryName")
        return nil
    end

    local success, result = pcall(airbase.getCategoryName, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase category name: " .. tostring(result), "Airbase.getCategoryName")
        return nil
    end

    return result
end

--- Get airbase parking information
---@param airbase table? Airbase object
---@param available boolean? If true, only return available parking spots
---@return table? parking Parking information if found, nil otherwise
---@usage local parking = getAirbaseParking(airbase, true)
function getAirbaseParking(airbase, available)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseParking requires valid airbase", "Airbase.getParking")
        return nil
    end

    local success, result = pcall(airbase.getParking, airbase, available)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase parking: " .. tostring(result), "Airbase.getParking")
        return nil
    end

    return result
end

--- Get airbase runways
---@param airbase table? Airbase object
---@return table? runways Runway information if found, nil otherwise
---@usage local runways = getAirbaseRunways(airbase)
function getAirbaseRunways(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseRunways requires valid airbase", "Airbase.getRunways")
        return nil
    end

    local success, result = pcall(airbase.getRunways, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase runways: " .. tostring(result), "Airbase.getRunways")
        return nil
    end

    return result
end

--- Get airbase tech object positions
---@param airbase table? Airbase object
---@param techObjectType number Tech object type ID
---@return table? positions Tech object positions if found, nil otherwise
---@usage local positions = getAirbaseTechObjectPos(airbase, 1)
function getAirbaseTechObjectPos(airbase, techObjectType)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseTechObjectPos requires valid airbase", "Airbase.getTechObjectPos")
        return nil
    end

    if not techObjectType or type(techObjectType) ~= "number" then
        _HarnessInternal.log.error("getAirbaseTechObjectPos requires valid tech object type", "Airbase.getTechObjectPos")
        return nil
    end

    local success, result = pcall(airbase.getTechObjectPos, airbase, techObjectType)
    if not success then
        _HarnessInternal.log.error("Failed to get tech object positions: " .. tostring(result), "Airbase.getTechObjectPos")
        return nil
    end

    return result
end

--- Get airbase dispatcher tower position
---@param airbase table? Airbase object
---@return table? position Tower position if found, nil otherwise
---@usage local towerPos = getAirbaseDispatcherTowerPos(airbase)
function getAirbaseDispatcherTowerPos(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseDispatcherTowerPos requires valid airbase", "Airbase.getDispatcherTowerPos")
        return nil
    end

    local success, result = pcall(airbase.getDispatcherTowerPos, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get dispatcher tower position: " .. tostring(result), "Airbase.getDispatcherTowerPos")
        return nil
    end

    return result
end

--- Get airbase radio silent mode
---@param airbase table? Airbase object
---@return boolean? silent True if radio silent, nil on error
---@usage local isSilent = getAirbaseRadioSilentMode(airbase)
function getAirbaseRadioSilentMode(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseRadioSilentMode requires valid airbase", "Airbase.getRadioSilentMode")
        return nil
    end

    local success, result = pcall(airbase.getRadioSilentMode, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get radio silent mode: " .. tostring(result), "Airbase.getRadioSilentMode")
        return nil
    end

    return result
end

--- Set airbase radio silent mode
---@param airbase table? Airbase object
---@param silent boolean Radio silent mode
---@return boolean? success True if set successfully, nil on error
---@usage setAirbaseRadioSilentMode(airbase, true)
function setAirbaseRadioSilentMode(airbase, silent)
    if not airbase then
        _HarnessInternal.log.error("setAirbaseRadioSilentMode requires valid airbase", "Airbase.setRadioSilentMode")
        return nil
    end

    if type(silent) ~= "boolean" then
        _HarnessInternal.log.error("setAirbaseRadioSilentMode requires boolean silent value", "Airbase.setRadioSilentMode")
        return nil
    end

    local success, result = pcall(airbase.setRadioSilentMode, airbase, silent)
    if not success then
        _HarnessInternal.log.error("Failed to set radio silent mode: " .. tostring(result), "Airbase.setRadioSilentMode")
        return nil
    end

    return true
end

--- Get airbase beacon information
---@param airbase table? Airbase object
---@return table? beacon Beacon information if found, nil otherwise
---@usage local beacon = getAirbaseBeacon(airbase)
function getAirbaseBeacon(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseBeacon requires valid airbase", "Airbase.getBeacon")
        return nil
    end

    local success, result = pcall(airbase.getBeacon, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase beacon: " .. tostring(result), "Airbase.getBeacon")
        return nil
    end

    return result
end

--- Set airbase auto capture mode
---@param airbase table? Airbase object
---@param enabled boolean Auto capture enabled
---@return boolean? success True if set successfully, nil on error
---@usage airbaseAutoCapture(airbase, true)
function airbaseAutoCapture(airbase, enabled)
    if not airbase then
        _HarnessInternal.log.error("airbaseAutoCapture requires valid airbase", "Airbase.autoCapture")
        return nil
    end

    if type(enabled) ~= "boolean" then
        _HarnessInternal.log.error("airbaseAutoCapture requires boolean enabled value", "Airbase.autoCapture")
        return nil
    end

    local success, result = pcall(airbase.autoCapture, airbase, enabled)
    if not success then
        _HarnessInternal.log.error("Failed to set auto capture: " .. tostring(result), "Airbase.autoCapture")
        return nil
    end

    return true
end

--- Check if airbase auto capture is enabled
---@param airbase table? Airbase object
---@return boolean? enabled True if auto capture is on, nil on error
---@usage local isOn = airbaseAutoCaptureIsOn(airbase)
function airbaseAutoCaptureIsOn(airbase)
    if not airbase then
        _HarnessInternal.log.error("airbaseAutoCaptureIsOn requires valid airbase", "Airbase.autoCaptureIsOn")
        return nil
    end

    local success, result = pcall(airbase.autoCaptureIsOn, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to check auto capture status: " .. tostring(result), "Airbase.autoCaptureIsOn")
        return nil
    end

    return result
end

--- Set airbase coalition
---@param airbase table? Airbase object
---@param coalitionId number Coalition ID
---@return boolean? success True if set successfully, nil on error
---@usage setAirbaseCoalition(airbase, coalition.side.BLUE)
function setAirbaseCoalition(airbase, coalitionId)
    if not airbase then
        _HarnessInternal.log.error("setAirbaseCoalition requires valid airbase", "Airbase.setCoalition")
        return nil
    end

    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("setAirbaseCoalition requires valid coalition ID", "Airbase.setCoalition")
        return nil
    end

    local success, result = pcall(airbase.setCoalition, airbase, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to set airbase coalition: " .. tostring(result), "Airbase.setCoalition")
        return nil
    end

    return true
end

--- Get airbase warehouse
---@param airbase table? Airbase object
---@return table? warehouse Warehouse object if found, nil otherwise
---@usage local warehouse = getAirbaseWarehouse(airbase)
function getAirbaseWarehouse(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseWarehouse requires valid airbase", "Airbase.getWarehouse")
        return nil
    end

    local success, result = pcall(airbase.getWarehouse, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase warehouse: " .. tostring(result), "Airbase.getWarehouse")
        return nil
    end

    return result
end

--- Get free parking terminal
---@param airbase table? Airbase object
---@param terminalType any? Terminal type filter
---@return table? terminal Free parking terminal if found, nil otherwise
---@usage local terminal = getAirbaseFreeParkingTerminal(airbase)
function getAirbaseFreeParkingTerminal(airbase, terminalType)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseFreeParkingTerminal requires valid airbase", "Airbase.getFreeParkingTerminal")
        return nil
    end

    local success, result = pcall(airbase.getFreeParkingTerminal, airbase, terminalType)
    if not success then
        _HarnessInternal.log.error("Failed to get free parking terminal: " .. tostring(result), "Airbase.getFreeParkingTerminal")
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
function getAirbaseFreeParkingTerminalByType(airbase, terminalType, multiple)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseFreeParkingTerminalByType requires valid airbase", "Airbase.getFreeParkingTerminalByType")
        return nil
    end

    local success, result = pcall(airbase.getFreeParkingTerminal, airbase, terminalType, multiple)
    if not success then
        _HarnessInternal.log.error("Failed to get free parking terminals by type: " .. tostring(result), "Airbase.getFreeParkingTerminalByType")
        return nil
    end

    return result
end

--- Get free airbase parking terminal
---@param airbase table? Airbase object
---@param terminalType any? Terminal type filter
---@return table? terminal Free parking terminal if found, nil otherwise
---@usage local terminal = getFreeAirbaseParkingTerminal(airbase)
function getFreeAirbaseParkingTerminal(airbase, terminalType)
    if not airbase then
        _HarnessInternal.log.error("getFreeAirbaseParkingTerminal requires valid airbase", "Airbase.getFreeAirbaseParkingTerminal")
        return nil
    end

    local success, result = pcall(airbase.getFreeAirbaseParkingTerminal, airbase, terminalType)
    if not success then
        _HarnessInternal.log.error("Failed to get free airbase parking terminal: " .. tostring(result), "Airbase.getFreeAirbaseParkingTerminal")
        return nil
    end

    return result
end

--- Get airbase parking terminal
---@param airbase table? Airbase object
---@param terminal number Terminal number
---@return table? terminal Parking terminal if found, nil otherwise
---@usage local terminal = getAirbaseParkingTerminal(airbase, 1)
function getAirbaseParkingTerminal(airbase, terminal)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseParkingTerminal requires valid airbase", "Airbase.getParkingTerminal")
        return nil
    end

    if not terminal or type(terminal) ~= "number" then
        _HarnessInternal.log.error("getAirbaseParkingTerminal requires valid terminal number", "Airbase.getParkingTerminal")
        return nil
    end

    local success, result = pcall(airbase.getParkingTerminal, airbase, terminal)
    if not success then
        _HarnessInternal.log.error("Failed to get parking terminal: " .. tostring(result), "Airbase.getParkingTerminal")
        return nil
    end

    return result
end

--- Get airbase parking terminal by index
---@param airbase table? Airbase object
---@param index number Terminal index
---@return table? terminal Parking terminal if found, nil otherwise
---@usage local terminal = getAirbaseParkingTerminalByIndex(airbase, 1)
function getAirbaseParkingTerminalByIndex(airbase, index)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseParkingTerminalByIndex requires valid airbase", "Airbase.getParkingTerminalByIndex")
        return nil
    end

    if not index or type(index) ~= "number" then
        _HarnessInternal.log.error("getAirbaseParkingTerminalByIndex requires valid index", "Airbase.getParkingTerminalByIndex")
        return nil
    end

    local success, result = pcall(airbase.getParkingTerminalByIndex, airbase, index)
    if not success then
        _HarnessInternal.log.error("Failed to get parking terminal by index: " .. tostring(result), "Airbase.getParkingTerminalByIndex")
        return nil
    end

    return result
end

--- Get airbase parking count
---@param airbase table? Airbase object
---@return number? count Number of parking spots, nil on error
---@usage local count = getAirbaseParkingCount(airbase)
function getAirbaseParkingCount(airbase)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseParkingCount requires valid airbase", "Airbase.getParkingCount")
        return nil
    end

    local success, result = pcall(airbase.getParkingCount, airbase)
    if not success then
        _HarnessInternal.log.error("Failed to get parking count: " .. tostring(result), "Airbase.getParkingCount")
        return nil
    end

    return result
end

--- Get airbase runway details
---@param airbase table? Airbase object
---@param runwayIndex number? Specific runway index
---@return table? details Runway details if found, nil otherwise
---@usage local details = getAirbaseRunwayDetails(airbase, 1)
function getAirbaseRunwayDetails(airbase, runwayIndex)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseRunwayDetails requires valid airbase", "Airbase.getRunwayDetails")
        return nil
    end

    if runwayIndex and type(runwayIndex) ~= "number" then
        _HarnessInternal.log.error("getAirbaseRunwayDetails runway index must be a number if provided", "Airbase.getRunwayDetails")
        return nil
    end

    local success, result = pcall(airbase.getRunwayDetails, airbase, runwayIndex)
    if not success then
        _HarnessInternal.log.error("Failed to get runway details: " .. tostring(result), "Airbase.getRunwayDetails")
        return nil
    end

    return result
end

--- Get airbase meteorological data
---@param airbase table? Airbase object
---@param height number? Height for weather data
---@return table? meteo Weather data if found, nil otherwise
---@usage local weather = getAirbaseMeteo(airbase, 100)
function getAirbaseMeteo(airbase, height)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseMeteo requires valid airbase", "Airbase.getMeteo")
        return nil
    end

    local success, result = pcall(airbase.getMeteo, airbase, height)
    if not success then
        _HarnessInternal.log.error("Failed to get airbase meteo: " .. tostring(result), "Airbase.getMeteo")
        return nil
    end

    return result
end

--- Get airbase wind with turbulence
---@param airbase table? Airbase object
---@param height number? Height for wind data
---@return table? wind Wind data with turbulence if found, nil otherwise
---@usage local wind = getAirbaseWindWithTurbulence(airbase, 100)
function getAirbaseWindWithTurbulence(airbase, height)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseWindWithTurbulence requires valid airbase", "Airbase.getWindWithTurbulence")
        return nil
    end

    local success, result = pcall(airbase.getWindWithTurbulence, airbase, height)
    if not success then
        _HarnessInternal.log.error("Failed to get wind with turbulence: " .. tostring(result), "Airbase.getWindWithTurbulence")
        return nil
    end

    return result
end

--- Check if airbase provides service
---@param airbase table? Airbase object
---@param service number Service type ID
---@return boolean? provided True if service is provided, nil on error
---@usage local hasService = getAirbaseIsServiceProvided(airbase, 1)
function getAirbaseIsServiceProvided(airbase, service)
    if not airbase then
        _HarnessInternal.log.error("getAirbaseIsServiceProvided requires valid airbase", "Airbase.getIsServiceProvided")
        return nil
    end

    if not service or type(service) ~= "number" then
        _HarnessInternal.log.error("getAirbaseIsServiceProvided requires valid service type", "Airbase.getIsServiceProvided")
        return nil
    end

    local success, result = pcall(airbase.getIsServiceProvided, airbase, service)
    if not success then
        _HarnessInternal.log.error("Failed to check service availability: " .. tostring(result), "Airbase.getIsServiceProvided")
        return nil
    end

    return result
end