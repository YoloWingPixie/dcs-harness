--[[
==================================================================================================
    ZONE MODULE
    Trigger zone utilities with caching support
    
    This module provides:
    - Runtime DCS API access to trigger zones (with cache-first lookups)
    - Mission trigger zone caching for fast queries
    - Spatial queries for units and points in zones
    - Support for both circular and polygon zones
==================================================================================================
]]

require("logger")
require("vector")
require("world")
require("drawing")
require("unit")
require("group")
require("coalition")

--- Get zone by name
---@param zoneName string The name of the zone to retrieve
---@return table? zone The zone object if found, nil otherwise
---@usage local zone = GetZone("LZ Alpha")
function GetZone(zoneName)
    if not zoneName or type(zoneName) ~= "string" then
        _HarnessInternal.log.error("GetZone requires string zone name", "GetZone")
        return nil
    end

    -- Check cache first
    if _HarnessInternal.cache and _HarnessInternal.cache.triggerZones then
        local cachedZone = _HarnessInternal.cache.triggerZones.byName[zoneName]
        if cachedZone then
            -- Convert cached format to DCS API format
            if cachedZone.type == "circle" then
                return {
                    point = cachedZone.center or { x = 0, y = 0, z = 0 },
                    radius = cachedZone.radius or 0,
                }
            elseif cachedZone.type == "polygon" and cachedZone.points then
                -- For polygon zones, return the first point as center with radius 0
                -- This matches DCS behavior for polygon zones
                return {
                    point = cachedZone.points[1] or { x = 0, y = 0, z = 0 },
                    radius = 0,
                    vertices = cachedZone.points,
                }
            end
        end
    end

    -- Fall back to API call
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
---@return boolean inZone True if position is within zone (handles both circular and polygon zones)
---@usage if IsInZone(pos, "LZ Alpha") then ... end
function IsInZone(position, zoneName)
    if not IsVec3(position) then
        _HarnessInternal.log.error("IsInZone requires Vec3 position", "IsInZone")
        return false
    end

    -- Try to use cached zone geometry first for polygon support
    if _HarnessInternal.cache and _HarnessInternal.cache.triggerZones then
        local cachedZone = _HarnessInternal.cache.triggerZones.byName[zoneName]
        if cachedZone then
            return IsPointInZoneGeometry(cachedZone, { x = position.x, z = position.z })
        end
    end

    -- Fall back to API zone (only works for circular zones)
    local zone = GetZone(zoneName)
    if not zone then
        return false
    end

    -- Check if zone has vertices (polygon)
    if zone.vertices and #zone.vertices >= 3 then
        return IsInPolygonZone(position, zone.vertices)
    end

    -- Standard circular zone check
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

--- Calculate bounding sphere for a set of points
---@param points table Array of points with x, z coordinates
---@return table center Center point of bounding sphere
---@return number radius Radius of bounding sphere
local function CalculateBoundingSphere(points)
    if not points or #points == 0 then
        return { x = 0, y = 0, z = 0 }, 0
    end

    -- Find centroid
    local sumX, sumZ = 0, 0
    for _, point in ipairs(points) do
        sumX = sumX + (point.x or 0)
        sumZ = sumZ + (point.z or 0)
    end

    local center = {
        x = sumX / #points,
        y = 0,
        z = sumZ / #points,
    }

    -- Find maximum distance from center
    local maxDist = 0
    for _, point in ipairs(points) do
        local dx = (point.x or 0) - center.x
        local dz = (point.z or 0) - center.z
        local dist = math.sqrt(dx * dx + dz * dz)
        if dist > maxDist then
            maxDist = dist
        end
    end

    return center, maxDist
end

--- Get units in zone
---@param zoneName string The name of the zone
---@param coalitionId number? Optional coalition ID to filter by (0=neutral, 1=red, 2=blue)
---@return table units Array of unit objects found in zone
---@usage local units = GetUnitsInZone("LZ Alpha", coalition.side.BLUE)
function GetUnitsInZone(zoneName, coalitionId)
    local unitsInZone = {}

    -- Get zone geometry
    local zone = nil

    -- Try to use cached zone geometry first for better performance
    if _HarnessInternal.cache and _HarnessInternal.cache.triggerZones then
        zone = _HarnessInternal.cache.triggerZones.byName[zoneName]
    end

    -- Fall back to API zone
    if not zone then
        local apiZone = GetZone(zoneName)
        if not apiZone then
            return {}
        end

        -- Convert API zone to our geometry format
        zone = {
            type = "circle",
            center = apiZone.point,
            radius = apiZone.radius or 0,
        }
    end

    -- Create search volume based on zone type
    local searchVolume
    if zone.type == "circle" and zone.center and zone.radius then
        -- For circular zones, use sphere volume with 1.5x radius for search
        searchVolume = CreateSphereVolume(zone.center, zone.radius * 1.5)
    elseif zone.type == "polygon" and zone.points and #zone.points >= 3 then
        -- For polygon zones, calculate bounding sphere with 1.5x radius
        local center, radius = CalculateBoundingSphere(zone.points)
        searchVolume = CreateSphereVolume(center, radius * 1.5)
    else
        return {}
    end

    if not searchVolume then
        return {}
    end

    -- Handler function for found objects
    local function handleUnit(unit, data)
        if not unit then
            return true
        end

        -- Check coalition filter
        if coalitionId then
            local unitCoalition = GetUnitCoalition(unit)
            if unitCoalition ~= coalitionId then
                return true
            end
        end

        -- Get unit position for precise zone check
        local pos = GetUnitPosition(unit)
        if pos then
            local point = { x = pos.x, z = pos.z }

            -- Check if unit is actually in the zone (not just the bounding sphere)
            if IsPointInZoneGeometry(zone, point) then
                table.insert(unitsInZone, unit)
            end
        end

        return true
    end

    -- Search for units in the volume
    -- Object.Category.UNIT = 1 in DCS
    SearchWorldObjects(1, searchVolume, handleUnit)

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
    local coalitions = coalitionId and { coalitionId } or { 0, 1, 2 }

    for _, coal in ipairs(coalitions) do
        -- Check all categories
        for _, category in ipairs({
            Group.Category.AIRPLANE,
            Group.Category.HELICOPTER,
            Group.Category.GROUND,
            Group.Category.SHIP,
        }) do
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
        _HarnessInternal.log.error(
            "IsInPolygonZone requires Vec3 point and vertices table",
            "IsInPolygonZone"
        )
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

-- ==================================================================================================
-- ZONE CACHING FUNCTIONALITY
-- Cache trigger zones from mission for fast lookups
-- ==================================================================================================

--- Get all trigger zones from the mission
---@return table? zones Array of trigger zone data or nil on error
function GetMissionZones()
    local success, result = pcall(function()
        if env.mission and env.mission.triggers and env.mission.triggers.zones then
            return env.mission.triggers.zones
        end
        return nil
    end)

    if not success then
        _HarnessInternal.log.error(
            "Failed to get mission zones: " .. tostring(result),
            "Zone.GetMissionZones"
        )
        return nil
    end

    return result
end

--- Process trigger zone geometry from mission data
---@param zone table Trigger zone data
---@return table? geometry Processed zone geometry or nil
function ProcessZoneGeometry(zone)
    if not zone or type(zone) ~= "table" then
        return nil
    end

    -- Skip zones attached to units (they move)
    if zone.linkUnit then
        return nil
    end

    local geometry = {
        name = zone.name,
        zoneId = zone.zoneId,
        hidden = zone.hidden,
        color = zone.color,
        properties = zone.properties or {},
    }

    -- Zone type: 0 = circular, 2 = quadpoint
    if zone.type == 0 then
        -- Circular zone
        geometry.type = "circle"
        geometry.center = {
            x = zone.x or 0,
            y = 0,
            z = zone.y or 0, -- Note: mission y is DCS z
        }
        geometry.radius = zone.radius or 0
    elseif zone.type == 2 and zone.verticies then
        -- Quadpoint/polygon zone
        geometry.type = "polygon"
        geometry.points = {}

        -- Check if vertices appear to be absolute or relative coordinates
        -- If any vertex coordinate is very large (>10000), assume absolute coordinates
        local useAbsolute = false
        for _, vertex in ipairs(zone.verticies) do
            if math.abs(vertex.x or 0) > 10000 or math.abs(vertex.y or 0) > 10000 then
                useAbsolute = true
                break
            end
        end

        -- Zone center position
        local centerX = zone.x or 0
        local centerZ = zone.y or 0 -- Mission y is DCS z

        for i, vertex in ipairs(zone.verticies) do
            if useAbsolute then
                -- Vertices are absolute coordinates
                table.insert(geometry.points, {
                    x = vertex.x or 0,
                    y = 0,
                    z = vertex.y or 0, -- Note: mission y is DCS z
                })
            else
                -- Vertices are relative to center
                table.insert(geometry.points, {
                    x = centerX + (vertex.x or 0),
                    y = 0,
                    z = centerZ + (vertex.y or 0), -- Note: mission y is DCS z
                })
            end
        end
    else
        -- Unknown zone type
        return nil
    end

    return geometry
end

--- Initialize trigger zone cache
---@return boolean success True if cache initialized successfully
function InitializeZoneCache()
    if not _HarnessInternal.cache then
        _HarnessInternal.cache = {}
    end

    _HarnessInternal.cache.triggerZones = {
        all = {},
        byName = {},
        byId = {},
        byType = {},
    }

    -- Get mission trigger zones
    local zones = GetMissionZones()
    if not zones then
        _HarnessInternal.log.warning("No zones found in mission", "Zone.InitializeCache")
        return true
    end

    -- Process each zone
    for _, zone in pairs(zones) do
        local geometry = ProcessZoneGeometry(zone)
        if geometry then
            -- Store in all
            table.insert(_HarnessInternal.cache.triggerZones.all, geometry)

            -- Index by name
            if geometry.name then
                _HarnessInternal.cache.triggerZones.byName[geometry.name] = geometry
            end

            -- Index by ID
            if geometry.zoneId then
                _HarnessInternal.cache.triggerZones.byId[geometry.zoneId] = geometry
            end

            -- Index by type
            if geometry.type then
                if not _HarnessInternal.cache.triggerZones.byType[geometry.type] then
                    _HarnessInternal.cache.triggerZones.byType[geometry.type] = {}
                end
                table.insert(_HarnessInternal.cache.triggerZones.byType[geometry.type], geometry)
            end
        end
    end

    _HarnessInternal.log.info(
        "Zone cache initialized with " .. #_HarnessInternal.cache.triggerZones.all .. " zones",
        "Zone.InitializeCache"
    )
    return true
end

--- Get all cached trigger zones
---@return table Array of all trigger zone geometries
function GetAllZones()
    if not _HarnessInternal.cache or not _HarnessInternal.cache.triggerZones then
        InitializeZoneCache()
    end

    return _HarnessInternal.cache.triggerZones.all or {}
end

--- Get cached trigger zone by exact name
---@param name string Zone name
---@return table? zone Trigger zone geometry or nil if not found
function GetCachedZoneByName(name)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error(
            "GetCachedZoneByName requires valid name",
            "Zone.GetCachedByName"
        )
        return nil
    end

    if not _HarnessInternal.cache or not _HarnessInternal.cache.triggerZones then
        InitializeZoneCache()
    end

    return _HarnessInternal.cache.triggerZones.byName[name]
end

--- Get cached trigger zone by ID
---@param zoneId number Zone ID
---@return table? zone Trigger zone geometry or nil if not found
function GetCachedZoneById(zoneId)
    if not zoneId or type(zoneId) ~= "number" then
        _HarnessInternal.log.error("GetCachedZoneById requires valid ID", "Zone.GetCachedById")
        return nil
    end

    if not _HarnessInternal.cache or not _HarnessInternal.cache.triggerZones then
        InitializeZoneCache()
    end

    return _HarnessInternal.cache.triggerZones.byId[zoneId]
end

--- Find cached trigger zones by partial name
---@param pattern string Name pattern to search for
---@return table Array of matching zone geometries
function FindZonesByName(pattern)
    if not pattern or type(pattern) ~= "string" then
        _HarnessInternal.log.error("FindZonesByName requires valid pattern", "Zone.FindByName")
        return {}
    end

    if not _HarnessInternal.cache or not _HarnessInternal.cache.triggerZones then
        InitializeZoneCache()
    end

    local results = {}
    local lowerPattern = string.lower(pattern)

    for _, zone in ipairs(_HarnessInternal.cache.triggerZones.all) do
        if zone.name and string.find(string.lower(zone.name), lowerPattern, 1, true) then
            table.insert(results, zone)
        end
    end

    return results
end

--- Get all cached trigger zones of a specific type
---@param zoneType string Zone type (circle, polygon)
---@return table Array of zone geometries of the specified type
function GetZonesByType(zoneType)
    if not zoneType or type(zoneType) ~= "string" then
        _HarnessInternal.log.error("GetZonesByType requires valid type", "Zone.GetByType")
        return {}
    end

    if not _HarnessInternal.cache or not _HarnessInternal.cache.triggerZones then
        InitializeZoneCache()
    end

    return _HarnessInternal.cache.triggerZones.byType[zoneType] or {}
end

--- Check if a point is inside a cached trigger zone
---@param zone table Trigger zone geometry
---@param point table Point with x, z coordinates
---@return boolean isInside True if point is inside the zone
function IsPointInZoneGeometry(zone, point)
    if not zone or not point then
        return false
    end

    if zone.type == "circle" and zone.center and zone.radius then
        local dx = point.x - zone.center.x
        local dz = point.z - zone.center.z
        return (dx * dx + dz * dz) <= (zone.radius * zone.radius)
    elseif zone.type == "polygon" and zone.points and #zone.points >= 3 then
        -- Convert 2D point to 3D for IsInPolygonZone
        local point3d = { x = point.x, y = 0, z = point.z }
        return IsInPolygonZone(point3d, zone.points)
    end

    return false
end

--- Clear trigger zone cache
function ClearZoneCache()
    if _HarnessInternal.cache and _HarnessInternal.cache.triggerZones then
        _HarnessInternal.cache.triggerZones = {
            all = {},
            byName = {},
            byId = {},
            byType = {},
        }
    end
end
