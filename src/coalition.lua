--[[
    Coalition Module - DCS World Coalition API Wrappers
    
    This module provides validated wrapper functions for DCS coalition operations,
    including country queries, group management, and unit spawning.
]]

--- Get the coalition ID for a given country
--- @param countryId number The country ID to query
--- @return number|nil coalitionId The coalition ID (0=neutral, 1=red, 2=blue) or nil on error
--- @usage local coalition = getCoalitionByCountry(country.id.USA)
function getCoalitionByCountry(countryId)
    if not countryId or type(countryId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionByCountry requires valid country ID", "Coalition.getCoalitionByCountry")
        return nil
    end

    local success, result = pcall(coalition.getCountryCoalition, countryId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition for country: " .. tostring(result), "Coalition.getCoalitionByCountry")
        return nil
    end

    return result
end

--- Get all players (clients) in a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil players Array of player units or nil on error
--- @usage local bluePlayers = getCoalitionPlayers(coalition.side.BLUE)
function getCoalitionPlayers(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionPlayers requires valid coalition ID", "Coalition.getCoalitionPlayers")
        return nil
    end

    local success, result = pcall(coalition.getPlayers, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition players: " .. tostring(result), "Coalition.getCoalitionPlayers")
        return nil
    end

    return result
end

--- Get all groups in a coalition, optionally filtered by category
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @param categoryId number|nil Optional category filter (0=airplane, 1=helicopter, 2=ground, 3=ship, 4=structure)
--- @return table|nil groups Array of group objects or nil on error
--- @usage local redGroundGroups = getCoalitionGroups(coalition.side.RED, Group.Category.GROUND)
function getCoalitionGroups(coalitionId, categoryId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionGroups requires valid coalition ID", "Coalition.getCoalitionGroups")
        return nil
    end

    if categoryId and type(categoryId) ~= "number" then
        _HarnessInternal.log.error("categoryId must be a number if provided", "Coalition.getCoalitionGroups")
        return nil
    end

    local success, result = pcall(coalition.getGroups, coalitionId, categoryId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition groups: " .. tostring(result), "Coalition.getCoalitionGroups")
        return nil
    end

    return result
end

--- Get all airbases controlled by a coalition
--- @param coalitionId number The coalition ID (0=neutral, 1=red, 2=blue)
--- @return table|nil airbases Array of airbase objects or nil on error
--- @usage local blueAirbases = getCoalitionAirbases(coalition.side.BLUE)
function getCoalitionAirbases(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionAirbases requires valid coalition ID", "Coalition.getCoalitionAirbases")
        return nil
    end

    local success, result = pcall(coalition.getAirbases, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition airbases: " .. tostring(result), "Coalition.getCoalitionAirbases")
        return nil
    end

    return result
end

--- Get all countries in a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil countries Array of country IDs or nil on error
--- @usage local redCountries = getCoalitionCountries(coalition.side.RED)
function getCoalitionCountries(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionCountries requires valid coalition ID", "Coalition.getCoalitionCountries")
        return nil
    end

    local success, result = pcall(coalition.getCountries, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition countries: " .. tostring(result), "Coalition.getCoalitionCountries")
        return nil
    end

    return result
end

--- Get all static objects belonging to a coalition
--- @param coalitionId number The coalition ID (0=neutral, 1=red, 2=blue)
--- @return table|nil staticObjects Array of static object references or nil on error
--- @usage local blueStatics = getCoalitionStaticObjects(coalition.side.BLUE)
function getCoalitionStaticObjects(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionStaticObjects requires valid coalition ID", "Coalition.getCoalitionStaticObjects")
        return nil
    end

    local success, result = pcall(coalition.getStaticObjects, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition static objects: " .. tostring(result), "Coalition.getCoalitionStaticObjects")
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
function addCoalitionGroup(countryId, categoryId, groupData)
    if not countryId or type(countryId) ~= "number" then
        _HarnessInternal.log.error("addCoalitionGroup requires valid country ID", "Coalition.addGroup")
        return nil
    end

    if not categoryId or type(categoryId) ~= "number" then
        _HarnessInternal.log.error("addCoalitionGroup requires valid category ID", "Coalition.addGroup")
        return nil
    end

    if not groupData or type(groupData) ~= "table" then
        _HarnessInternal.log.error("addCoalitionGroup requires valid group data table", "Coalition.addGroup")
        return nil
    end

    local success, result = pcall(coalition.addGroup, countryId, categoryId, groupData)
    if not success then
        _HarnessInternal.log.error("Failed to add coalition group: " .. tostring(result), "Coalition.addGroup")
        return nil
    end

    return result
end

--- Add a new static object to the mission for a specific country
--- @param countryId number The country ID that will own the static object
--- @param staticData table The static object definition table
--- @return table|nil staticObject The created static object or nil on error
--- @usage local newStatic = addCoalitionStaticObject(country.id.USA, staticDefinition)
function addCoalitionStaticObject(countryId, staticData)
    if not countryId or type(countryId) ~= "number" then
        _HarnessInternal.log.error("addCoalitionStaticObject requires valid country ID", "Coalition.addStaticObject")
        return nil
    end

    if not staticData or type(staticData) ~= "table" then
        _HarnessInternal.log.error("addCoalitionStaticObject requires valid static object data", "Coalition.addStaticObject")
        return nil
    end

    local success, result = pcall(coalition.addStaticObject, countryId, staticData)
    if not success then
        _HarnessInternal.log.error("Failed to add coalition static object: " .. tostring(result), "Coalition.addStaticObject")
        return nil
    end

    return result
end

--- Get all reference points for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil refPoints Table of reference points or nil on error
--- @usage local blueRefPoints = getCoalitionRefPoints(coalition.side.BLUE)
function getCoalitionRefPoints(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionRefPoints requires valid coalition ID", "Coalition.getRefPoints")
        return nil
    end

    local success, result = pcall(coalition.getRefPoints, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition reference points: " .. tostring(result), "Coalition.getRefPoints")
        return nil
    end

    return result
end

--- Get the main reference point (bullseye) for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil refPoint The main reference point with x, y, z coordinates or nil on error
--- @usage local blueBullseye = getCoalitionMainRefPoint(coalition.side.BLUE)
function getCoalitionMainRefPoint(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionMainRefPoint requires valid coalition ID", "Coalition.getMainRefPoint")
        return nil
    end

    local success, result = pcall(coalition.getMainRefPoint, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition main reference point: " .. tostring(result), "Coalition.getMainRefPoint")
        return nil
    end

    return result
end

--- Get the bullseye coordinates for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @return table|nil bullseye The bullseye position with x, y, z coordinates or nil on error
--- @usage local redBullseye = getCoalitionBullseye(coalition.side.RED)
function getCoalitionBullseye(coalitionId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionBullseye requires valid coalition ID", "Coalition.getBullseye")
        return nil
    end

    local success, result = pcall(coalition.getBullseye, coalitionId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition bullseye: " .. tostring(result), "Coalition.getBullseye")
        return nil
    end

    return result
end

--- Add a reference point for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @param refPointData table The reference point data table
--- @return table|nil refPoint The created reference point or nil on error
--- @usage local newRefPoint = addCoalitionRefPoint(coalition.side.BLUE, {callsign = "ALPHA", x = 100000, y = 0, z = 200000})
function addCoalitionRefPoint(coalitionId, refPointData)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("addCoalitionRefPoint requires valid coalition ID", "Coalition.addRefPoint")
        return nil
    end

    if not refPointData or type(refPointData) ~= "table" then
        _HarnessInternal.log.error("addCoalitionRefPoint requires valid reference point data", "Coalition.addRefPoint")
        return nil
    end

    local success, result = pcall(coalition.addRefPoint, coalitionId, refPointData)
    if not success then
        _HarnessInternal.log.error("Failed to add coalition reference point: " .. tostring(result), "Coalition.addRefPoint")
        return nil
    end

    return result
end

--- Remove a reference point from a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @param refPointId number|string The reference point ID to remove
--- @return boolean|nil success True if removed successfully, nil on error
--- @usage removeCoalitionRefPoint(coalition.side.BLUE, "ALPHA")
function removeCoalitionRefPoint(coalitionId, refPointId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("removeCoalitionRefPoint requires valid coalition ID", "Coalition.removeRefPoint")
        return nil
    end

    if not refPointId then
        _HarnessInternal.log.error("removeCoalitionRefPoint requires valid reference point ID", "Coalition.removeRefPoint")
        return nil
    end

    local success, result = pcall(coalition.removeRefPoint, coalitionId, refPointId)
    if not success then
        _HarnessInternal.log.error("Failed to remove coalition reference point: " .. tostring(result), "Coalition.removeRefPoint")
        return nil
    end

    return result
end

--- Get service providers (tankers, AWACS, etc.) for a coalition
--- @param coalitionId number The coalition ID (1=red, 2=blue)
--- @param serviceType number The service type to query
--- @return table|nil providers Array of units providing the service or nil on error
--- @usage local blueTankers = getCoalitionServiceProviders(coalition.side.BLUE, coalition.service.TANKER)
function getCoalitionServiceProviders(coalitionId, serviceType)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("getCoalitionServiceProviders requires valid coalition ID", "Coalition.getServiceProviders")
        return nil
    end

    if not serviceType or type(serviceType) ~= "number" then
        _HarnessInternal.log.error("getCoalitionServiceProviders requires valid service type", "Coalition.getServiceProviders")
        return nil
    end

    local success, result = pcall(coalition.getServiceProviders, coalitionId, serviceType)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition service providers: " .. tostring(result), "Coalition.getServiceProviders")
        return nil
    end

    return result
end