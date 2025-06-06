--[[
==================================================================================================
    ZONE MODULE
    Trigger zone utilities
==================================================================================================
]]

--- Get zone by name
---@param zoneName string The name of the zone to retrieve
---@return table? zone The zone object if found, nil otherwise
---@usage local zone = GetZone("LZ Alpha")
function GetZone(zoneName)
    if not zoneName or type(zoneName) ~= "string" then
        _HarnessInternal.log.error("GetZone requires string zone name", "GetZone")
        return nil
    end
    
    local success, zone = pcall(trigger.misc.getZone, zoneName)
    if not success then
        _HarnessInternal.log.error("Failed to get zone: " .. tostring(zone), "GetZone")
        return nil
    end
    
    return zone
end

--- Get zone position
---@param zoneName string The name of the zone
---@return table? position The zone center position as Vec3 if found, nil otherwise
---@usage local pos = GetZonePosition("LZ Alpha")
function GetZonePosition(zoneName)
    local zone = GetZone(zoneName)
    if not zone then
        return nil
    end
    
    return Vec3(zone.point.x, zone.point.y, zone.point.z)
end

--- Get zone radius
---@param zoneName string The name of the zone
---@return number? radius The zone radius if found, nil otherwise
---@usage local radius = GetZoneRadius("LZ Alpha")
function GetZoneRadius(zoneName)
    local zone = GetZone(zoneName)
    if not zone then
        return nil
    end
    
    return zone.radius
end

--- Check if point is in zone
---@param position table Vec3 position to check
---@param zoneName string The name of the zone
---@return boolean inZone True if position is within zone radius
---@usage if IsInZone(pos, "LZ Alpha") then ... end
function IsInZone(position, zoneName)
    if not IsVec3(position) then
        _HarnessInternal.log.error("IsInZone requires Vec3 position", "IsInZone")
        return false
    end
    
    local zone = GetZone(zoneName)
    if not zone then
        return false
    end
    
    local zonePos = Vec3(zone.point.x, zone.point.y, zone.point.z)
    local distance = Distance2D(position, zonePos)
    
    return distance <= zone.radius
end

--- Check if unit is in zone
---@param unitName string The name of the unit
---@param zoneName string The name of the zone
---@return boolean inZone True if unit is within zone radius
---@usage if IsUnitInZone("Player", "LZ Alpha") then ... end
function IsUnitInZone(unitName, zoneName)
    local position = GetUnitPosition(unitName)
    if not position then
        return false
    end
    
    return IsInZone(position, zoneName)
end

--- Check if group is in zone (any unit)
---@param groupName string The name of the group
---@param zoneName string The name of the zone
---@return boolean inZone True if any unit of the group is in zone
---@usage if IsGroupInZone("Aerial-1", "LZ Alpha") then ... end
function IsGroupInZone(groupName, zoneName)
    local units = GetGroupUnits(groupName)
    if not units then
        return false
    end
    
    for _, unit in ipairs(units) do
        local success, unitName = pcall(unit.getName, unit)
        if success and unitName then
            if IsUnitInZone(unitName, zoneName) then
                return true
            end
        end
    end
    
    return false
end

--- Check if entire group is in zone (all units)
---@param groupName string The name of the group
---@param zoneName string The name of the zone
---@return boolean inZone True if all units of the group are in zone
---@usage if IsGroupCompletelyInZone("Aerial-1", "LZ Alpha") then ... end
function IsGroupCompletelyInZone(groupName, zoneName)
    local units = GetGroupUnits(groupName)
    if not units or #units == 0 then
        return false
    end
    
    for _, unit in ipairs(units) do
        local success, unitName = pcall(unit.getName, unit)
        if success and unitName then
            if not IsUnitInZone(unitName, zoneName) then
                return false
            end
        end
    end
    
    return true
end

--- Get units in zone
---@param zoneName string The name of the zone
---@param coalitionId number? Optional coalition ID to filter by (0=neutral, 1=red, 2=blue)
---@return table units Array of unit objects found in zone
---@usage local units = GetUnitsInZone("LZ Alpha", coalition.side.BLUE)
function GetUnitsInZone(zoneName, coalitionId)
    local zone = GetZone(zoneName)
    if not zone then
        return {}
    end
    
    local unitsInZone = {}
    local zonePos = Vec3(zone.point.x, zone.point.y, zone.point.z)
    
    -- Get all groups for the coalition (or all coalitions if not specified)
    local coalitions = coalitionId and {coalitionId} or {0, 1, 2}
    
    for _, coal in ipairs(coalitions) do
        -- Check all categories
        for _, category in ipairs({Group.Category.AIRPLANE, Group.Category.HELICOPTER, Group.Category.GROUND, Group.Category.SHIP}) do
            local groups = GetCoalitionGroups(coal, category)
            
            for _, group in ipairs(groups) do
                local success, units = pcall(group.getUnits, group)
                if success and units then
                    for _, unit in ipairs(units) do
                        local unitSuccess, unitName = pcall(unit.getName, unit)
                        if unitSuccess and unitName and IsUnitInZone(unitName, zoneName) then
                            table.insert(unitsInZone, unit)
                        end
                    end
                end
            end
        end
    end
    
    return unitsInZone
end

--- Get groups in zone
---@param zoneName string The name of the zone
---@param coalitionId number? Optional coalition ID to filter by (0=neutral, 1=red, 2=blue)
---@return table groups Array of group objects found in zone
---@usage local groups = GetGroupsInZone("LZ Alpha", coalition.side.BLUE)
function GetGroupsInZone(zoneName, coalitionId)
    local zone = GetZone(zoneName)
    if not zone then
        return {}
    end
    
    local groupsInZone = {}
    local groupsAdded = {}
    
    -- Get all groups for the coalition (or all coalitions if not specified)
    local coalitions = coalitionId and {coalitionId} or {0, 1, 2}
    
    for _, coal in ipairs(coalitions) do
        -- Check all categories
        for _, category in ipairs({Group.Category.AIRPLANE, Group.Category.HELICOPTER, Group.Category.GROUND, Group.Category.SHIP}) do
            local groups = GetCoalitionGroups(coal, category)
            
            for _, group in ipairs(groups) do
                local success, groupName = pcall(group.getName, group)
                if success and groupName and not groupsAdded[groupName] then
                    if IsGroupInZone(groupName, zoneName) then
                        table.insert(groupsInZone, group)
                        groupsAdded[groupName] = true
                    end
                end
            end
        end
    end
    
    return groupsInZone
end

--- Create random position in zone
---@param zoneName string The name of the zone
---@param inner number? Minimum distance from center (default 0)
---@param outer number? Maximum distance from center (default zone radius)
---@return table? position Random Vec3 position within zone, nil if zone not found
---@usage local randPos = RandomPointInZone("LZ Alpha", 100, 500)
function RandomPointInZone(zoneName, inner, outer)
    local zone = GetZone(zoneName)
    if not zone then
        return nil
    end
    
    inner = inner or 0
    outer = outer or zone.radius
    
    -- Random angle
    local angle = math.random() * 2 * math.pi
    
    -- Random distance between inner and outer radius
    local distance = inner + math.random() * (outer - inner)
    
    -- Calculate position
    local x = zone.point.x + distance * math.cos(angle)
    local z = zone.point.z + distance * math.sin(angle)
    
    return Vec3(x, zone.point.y, z)
end

--- Check if point is in polygon zone
---@param point table Vec3 position to check
---@param vertices table Array of Vec3 vertices defining the polygon
---@return boolean inZone True if point is inside the polygon
---@usage if IsInPolygonZone(pos, {v1, v2, v3, v4}) then ... end
function IsInPolygonZone(point, vertices)
    if not IsVec3(point) or not vertices or type(vertices) ~= "table" then
        _HarnessInternal.log.error("IsInPolygonZone requires Vec3 point and vertices table", "IsInPolygonZone")
        return false
    end
    
    -- Ray casting algorithm for point-in-polygon test
    local x, z = point.x, point.z
    local inside = false
    local j = #vertices
    
    for i = 1, #vertices do
        local xi, zi = vertices[i].x, vertices[i].z
        local xj, zj = vertices[j].x, vertices[j].z
        
        if ((zi > z) ~= (zj > z)) and (x < (xj - xi) * (z - zi) / (zj - zi) + xi) then
            inside = not inside
        end
        j = i
    end
    
    return inside
end