--[[
    Coalition Module - DCS World Coalition API Wrappers
    
    This module provides validated wrapper functions for DCS coalition operations,
    including country queries, group management, and unit spawning.
]]
require("logger")
--- Get the coalition ID for a given country
--- @param countryId number The country ID to query
--- @return number|nil coalitionId The coalition ID (0=neutral, 1=red, 2=blue) or nil on error
--- @usage local coalition = getCoalitionByCountry(country.id.USA)
function GetCoalitionByCountry(countryId)
    if not countryId or type(countryId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionByCountry requires valid country ID",
            "Coalition.GetCoalitionByCountry"
        )
        return nil
    end

    local success, result = pcall(coalition.getCountryCoalition, countryId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition for country: " .. tostring(result),
            "Coalition.GetCoalitionByCountry"
        )
        return nil
    end

    return result
end

--- Get all players (clients) in a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil players Array of player units or nil on error
--- @usage local bluePlayers = getCoalitionPlayers(coalition.side.BLUE)
function GetCoalitionPlayers(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionPlayers requires valid coalition ID",
            "Coalition.GetCoalitionPlayers"
        )
        return nil
    end

    local success, result = pcall(coalition.getPlayers, coalitionId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition players: " .. tostring(result),
            "Coalition.GetCoalitionPlayers"
        )
        return nil
    end

    return result
end

--- Get all groups in a coalition, optionally filtered by category
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @param categoryId number|nil Optional category filter (0=airplane, 1=helicopter, 2=ground, 3=ship, 4=structure)
--- @return table|nil groups Array of group objects or nil on error
--- @usage local redGroundGroups = getCoalitionGroups(coalition.side.RED, Group.Category.GROUND)
function GetCoalitionGroups(coalitionId, categoryId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionGroups requires valid coalition ID",
            "Coalition.GetCoalitionGroups"
        )
        return nil
    end

    if categoryId and type(categoryId) ~= "number" then
        _HarnessInternal.log.error(
            "categoryId must be a number if provided",
            "Coalition.GetCoalitionGroups"
        )
        return nil
    end

    local success, result = pcall(coalition.getGroups, coalitionId, categoryId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition groups: " .. tostring(result),
            "Coalition.GetCoalitionGroups"
        )
        return {}
    end

    return result or {}
end

--- Get all airbases controlled by a coalition
--- @param coalitionId number The coalition ID (0=neutral, 1=red, 2=blue)
--- @return table|nil airbases Array of airbase objects or nil on error
--- @usage local blueAirbases = getCoalitionAirbases(coalition.side.BLUE)
function GetCoalitionAirbases(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionAirbases requires valid coalition ID",
            "Coalition.GetCoalitionAirbases"
        )
        return nil
    end

    local success, result = pcall(coalition.getAirbases, coalitionId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition airbases: " .. tostring(result),
            "Coalition.GetCoalitionAirbases"
        )
        return nil
    end

    return result
end

--- Get all countries in a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil countries Array of country IDs or nil on error
--- @usage local redCountries = getCoalitionCountries(coalition.side.RED)
function GetCoalitionCountries(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionCountries requires valid coalition ID",
            "Coalition.GetCoalitionCountries"
        )
        return nil
    end

    local success, result = pcall(coalition.getCountries, coalitionId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition countries: " .. tostring(result),
            "Coalition.GetCoalitionCountries"
        )
        return nil
    end

    return result
end

--- Get all static objects belonging to a coalition
--- @param coalitionId number The coalition ID (0=neutral, 1=red, 2=blue)
--- @return table|nil staticObjects Array of static object references or nil on error
--- @usage local blueStatics = getCoalitionStaticObjects(coalition.side.BLUE)
function GetCoalitionStaticObjects(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionStaticObjects requires valid coalition ID",
            "Coalition.GetCoalitionStaticObjects"
        )
        return nil
    end

    local success, result = pcall(coalition.getStaticObjects, coalitionId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition static objects: " .. tostring(result),
            "Coalition.GetCoalitionStaticObjects"
        )
        return nil
    end

    return result
end

--- Add a new group to the mission for a specific country
--- @param countryId number The country ID that will own the group
--- @param categoryId number The category ID (0=airplane, 1=helicopter, 2=ground, 3=ship)
--- @param groupData table The group definition table with units, route, etc.
--- @return table|nil group The created group object or nil on error
--- @usage local newGroup = addCoalitionGroup(country.id.USA, Group.Category.AIRPLANE, groupDefinition)
function AddCoalitionGroup(countryId, categoryId, groupData)
    if not countryId or type(countryId) ~= "number" then
        _HarnessInternal.log.error(
            "AddCoalitionGroup requires valid country ID",
            "Coalition.AddGroup"
        )
        return nil
    end

    if not categoryId or type(categoryId) ~= "number" then
        _HarnessInternal.log.error(
            "AddCoalitionGroup requires valid category ID",
            "Coalition.AddGroup"
        )
        return nil
    end

    if not groupData or type(groupData) ~= "table" then
        _HarnessInternal.log.error(
            "AddCoalitionGroup requires valid group data table",
            "Coalition.AddGroup"
        )
        return nil
    end

    local success, result = pcall(coalition.addGroup, countryId, categoryId, groupData)
    if not success then
        _HarnessInternal.log.error(
            "Failed to add coalition group: " .. tostring(result),
            "Coalition.AddGroup"
        )
        return nil
    end

    return result
end

--- Add a new static object to the mission for a specific country
--- @param countryId number The country ID that will own the static object
--- @param staticData table The static object definition table
--- @return table|nil staticObject The created static object or nil on error
--- @usage local newStatic = addCoalitionStaticObject(country.id.USA, staticDefinition)
function AddCoalitionStaticObject(countryId, staticData)
    if not countryId or type(countryId) ~= "number" then
        _HarnessInternal.log.error(
            "AddCoalitionStaticObject requires valid country ID",
            "Coalition.AddStaticObject"
        )
        return nil
    end

    if not staticData or type(staticData) ~= "table" then
        _HarnessInternal.log.error(
            "AddCoalitionStaticObject requires valid static object data",
            "Coalition.AddStaticObject"
        )
        return nil
    end

    local success, result = pcall(coalition.addStaticObject, countryId, staticData)
    if not success then
        _HarnessInternal.log.error(
            "Failed to add coalition static object: " .. tostring(result),
            "Coalition.AddStaticObject"
        )
        return nil
    end

    return result
end

--- Get all reference points for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil refPoints Table of reference points or nil on error
--- @usage local blueRefPoints = getCoalitionRefPoints(coalition.side.BLUE)
function GetCoalitionRefPoints(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionRefPoints requires valid coalition ID",
            "Coalition.GetRefPoints"
        )
        return nil
    end

    local success, result = pcall(coalition.getRefPoints, coalitionId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition reference points: " .. tostring(result),
            "Coalition.GetRefPoints"
        )
        return nil
    end

    return result
end

--- Get the main reference point (bullseye) for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil refPoint The main reference point with x, y, z coordinates or nil on error
--- @usage local blueBullseye = getCoalitionMainRefPoint(coalition.side.BLUE)
function GetCoalitionMainRefPoint(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionMainRefPoint requires valid coalition ID",
            "Coalition.GetMainRefPoint"
        )
        return nil
    end

    local success, result = pcall(coalition.getMainRefPoint, coalitionId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition main reference point: " .. tostring(result),
            "Coalition.GetMainRefPoint"
        )
        return nil
    end

    return result
end

--- Get the bullseye coordinates for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil bullseye The bullseye position with x, y, z coordinates or nil on error
--- @usage local redBullseye = getCoalitionBullseye(coalition.side.RED)
function GetCoalitionBullseye(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionBullseye requires valid coalition ID",
            "Coalition.GetBullseye"
        )
        return nil
    end

    local success, result = pcall(coalition.getBullseye, coalitionId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition bullseye: " .. tostring(result),
            "Coalition.GetBullseye"
        )
        return nil
    end

    return result
end

--- Add a reference point for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @param refPointData table The reference point data table
--- @return table|nil refPoint The created reference point or nil on error
--- @usage local newRefPoint = addCoalitionRefPoint(coalition.side.BLUE, {callsign = "ALPHA", x = 100000, y = 0, z = 200000})
function AddCoalitionRefPoint(coalitionId, refPointData)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "AddCoalitionRefPoint requires valid coalition ID",
            "Coalition.AddRefPoint"
        )
        return nil
    end

    if not refPointData or type(refPointData) ~= "table" then
        _HarnessInternal.log.error(
            "AddCoalitionRefPoint requires valid reference point data",
            "Coalition.AddRefPoint"
        )
        return nil
    end

    local success, result = pcall(coalition.addRefPoint, coalitionId, refPointData)
    if not success then
        _HarnessInternal.log.error(
            "Failed to add coalition reference point: " .. tostring(result),
            "Coalition.AddRefPoint"
        )
        return nil
    end

    return result
end

--- Remove a reference point from a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @param refPointId number|string The reference point ID to remove
--- @return boolean|nil success True if removed successfully, nil on error
--- @usage RemoveCoalitionRefPoint(coalition.side.BLUE, "ALPHA")
function RemoveCoalitionRefPoint(coalitionId, refPointId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "RemoveCoalitionRefPoint requires valid coalition ID",
            "Coalition.RemoveRefPoint"
        )
        return nil
    end

    if not refPointId then
        _HarnessInternal.log.error(
            "RemoveCoalitionRefPoint requires valid reference point ID",
            "Coalition.RemoveRefPoint"
        )
        return nil
    end

    local success, result = pcall(coalition.removeRefPoint, coalitionId, refPointId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to remove coalition reference point: " .. tostring(result),
            "Coalition.RemoveRefPoint"
        )
        return nil
    end

    return result
end

--- Get service providers (tankers, AWACS, etc.) for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @param serviceType number The service type to query
--- @return table|nil providers Array of units providing the service or nil on error
--- @usage local blueTankers = getCoalitionServiceProviders(coalition.side.BLUE, coalition.service.TANKER)
function GetCoalitionServiceProviders(coalitionId, serviceType)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionServiceProviders requires valid coalition ID",
            "Coalition.GetServiceProviders"
        )
        return nil
    end

    if not serviceType or type(serviceType) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionServiceProviders requires valid service type",
            "Coalition.GetServiceProviders"
        )
        return nil
    end

    local success, result = pcall(coalition.getServiceProviders, coalitionId, serviceType)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition service providers: " .. tostring(result),
            "Coalition.GetServiceProviders"
        )
        return nil
    end

    return result
end
