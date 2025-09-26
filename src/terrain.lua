--[[
==================================================================================================
    TERRAIN MODULE
    Terrain and land utilities
==================================================================================================
]]

require("logger")
require("vector")

--- Get terrain height at position
---@param position table Vec2 or Vec3 position
---@return number height Terrain height at position (0 on error)
---@usage local height = GetTerrainHeight(position)
function GetTerrainHeight(position)
    if not position then
        _HarnessInternal.log.error("GetTerrainHeight requires position", "GetTerrainHeight")
        return 0
    end

    local vec2 = IsVec3(position) and Vec2(position.x, position.z) or ToVec2(position)

    if not IsVec2(vec2) then
        _HarnessInternal.log.error("GetTerrainHeight requires Vec2 or Vec3", "GetTerrainHeight")
        return 0
    end

    local success, height = pcall(land.getHeight, vec2)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get terrain height: " .. tostring(height),
            "GetTerrainHeight"
        )
        return 0
    end

    return height or 0
end

--- Get altitude above ground level
---@param position table Vec3 position
---@return number agl Altitude above ground level (0 on error)
---@usage local agl = GetAGL(position)
function GetAGL(position)
    if not IsVec3(position) then
        _HarnessInternal.log.error("GetAGL requires Vec3 position", "GetAGL")
        return 0
    end

    local groundHeight = GetTerrainHeight(position)
    return position.y - groundHeight
end

--- Set altitude to specific AGL
---@param position table Vec3 position
---@param agl number Desired altitude above ground level
---@return table newPosition Vec3 with adjusted altitude
---@usage local newPos = SetAGL(position, 100)
function SetAGL(position, agl)
    if not IsVec3(position) or type(agl) ~= "number" then
        _HarnessInternal.log.error("SetAGL requires Vec3 and number", "SetAGL")
        return Vec3()
    end

    local groundHeight = GetTerrainHeight(position)
    return Vec3(position.x, groundHeight + agl, position.z)
end

--- Check line of sight between two points
---@param from table Vec3 start position
---@param to table Vec3 end position
---@return boolean hasLOS True if line of sight exists
---@usage if HasLOS(pos1, pos2) then ... end
function HasLOS(from, to)
    if not IsVec3(from) or not IsVec3(to) then
        _HarnessInternal.log.error("HasLOS requires two valid Vec3", "HasLOS")
        return false
    end

    local success, visible = pcall(land.isVisible, from, to)
    if not success then
        _HarnessInternal.log.error("Failed to check LOS: " .. tostring(visible), "HasLOS")
        return false
    end

    return visible == true
end

--- Get surface type at position
---@param position table Vec2 or Vec3 position
---@return number? surfaceType Surface type ID (1=land, 2=shallow water, 3=water, 4=road, 5=runway)
---@usage local surface = GetSurfaceType(position)
function GetSurfaceType(position)
    if not position then
        _HarnessInternal.log.error("GetSurfaceType requires position", "GetSurfaceType")
        return nil
    end

    local vec2 = IsVec3(position) and Vec2(position.x, position.z) or ToVec2(position)

    if not IsVec2(vec2) then
        _HarnessInternal.log.error("GetSurfaceType requires Vec2 or Vec3", "GetSurfaceType")
        return nil
    end

    local success, surfaceType = pcall(land.getSurfaceType, vec2)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get surface type: " .. tostring(surfaceType),
            "GetSurfaceType"
        )
        return nil
    end

    return surfaceType
end

--- Check if position is over water
---@param position table Vec2 or Vec3 position
---@return boolean overWater True if over water or shallow water
---@usage if IsOverWater(position) then ... end
function IsOverWater(position)
    local surfaceType = GetSurfaceType(position)
    if not surfaceType then
        return false
    end

    -- land.SurfaceType.WATER = 3, SHALLOW_WATER = 2
    return surfaceType == 2 or surfaceType == 3
end

--- Check if position is over land
---@param position table Vec2 or Vec3 position
---@return boolean overLand True if over land, road, or runway
---@usage if IsOverLand(position) then ... end
function IsOverLand(position)
    local surfaceType = GetSurfaceType(position)
    if not surfaceType then
        return false
    end

    -- land.SurfaceType.LAND = 1, ROAD = 4, RUNWAY = 5
    return surfaceType == 1 or surfaceType == 4 or surfaceType == 5
end

--- Get intersection point of ray with terrain
---@param origin table Vec3 ray origin
---@param direction table Vec3 ray direction
---@param maxDistance number Maximum ray distance
---@return table? intersection Vec3 intersection point if found
---@usage local hit = GetTerrainIntersection(origin, direction, 10000)
function GetTerrainIntersection(origin, direction, maxDistance)
    if not IsVec3(origin) or not IsVec3(direction) or type(maxDistance) ~= "number" then
        _HarnessInternal.log.error(
            "GetTerrainIntersection requires origin Vec3, direction Vec3, and maxDistance",
            "GetTerrainIntersection"
        )
        return nil
    end

    local success, intersection = pcall(land.getIP, origin, direction, maxDistance)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get terrain intersection: " .. tostring(intersection),
            "GetTerrainIntersection"
        )
        return nil
    end

    return intersection
end

--- Get terrain profile between two points
---@param from table Vec3 start position
---@param to table Vec3 end position
---@return table profile Array of profile points (empty on error)
---@usage local profile = GetTerrainProfile(pos1, pos2)
function GetTerrainProfile(from, to)
    if not IsVec3(from) or not IsVec3(to) then
        _HarnessInternal.log.error("GetTerrainProfile requires two valid Vec3", "GetTerrainProfile")
        return {}
    end

    local success, profile = pcall(land.profile, from, to)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get terrain profile: " .. tostring(profile),
            "GetTerrainProfile"
        )
        return {}
    end

    return profile or {}
end

--- Find closest point on roads
---@param position table Vec2 or Vec3 position
---@param roadType string? Road type ("roads" or "rails", default "roads")
---@return table? point Closest point on road if found
---@usage local roadPoint = GetClosestRoadPoint(position, "roads")
function GetClosestRoadPoint(position, roadType)
    if not position then
        _HarnessInternal.log.error("GetClosestRoadPoint requires position", "GetClosestRoadPoint")
        return nil
    end

    local vec2 = IsVec3(position) and Vec2(position.x, position.z) or ToVec2(position)

    if not IsVec2(vec2) then
        _HarnessInternal.log.error(
            "GetClosestRoadPoint requires Vec2 or Vec3",
            "GetClosestRoadPoint"
        )
        return nil
    end

    roadType = roadType or "roads"
    -- DCS API nuance: getClosestPointOnRoads expects 'railroads', while findPathOnRoads uses 'rails'
    if roadType == "rails" then
        roadType = "railroads"
    end

    if type(vec2.x) ~= "number" or type(vec2.z) ~= "number" then
        _HarnessInternal.log.error(
            "GetClosestRoadPoint requires numeric x/z on position",
            "GetClosestRoadPoint"
        )
        return nil
    end

    local success, r1, r2 =
        pcall(land.getClosestPointOnRoads, roadType, tonumber(vec2.x), tonumber(vec2.z))
    if not success then
        _HarnessInternal.log.error(
            "Failed to get closest road point: " .. tostring(r1),
            "GetClosestRoadPoint"
        )
        return nil
    end

    -- Normalize return: API may return table or two numeric coordinates
    if type(r1) == "table" then
        return r1
    end
    if type(r1) == "number" and type(r2) == "number" then
        return { x = r1, y = r2 }
    end
    return nil
end

--- Find path on roads between two points
---@param from table Vec2 or Vec3 start position
---@param to table Vec2 or Vec3 end position
---@param roadType string? Road type ("roads" or "railroads", default "roads")
---@return table path Array of path points (empty on error)
---@usage local path = FindRoadPath(start, finish, "roads")
function FindRoadPath(from, to, roadType)
    if not from or not to then
        _HarnessInternal.log.error("FindRoadPath requires from and to positions", "FindRoadPath")
        return {}
    end

    local fromVec2 = IsVec3(from) and Vec2(from.x, from.z) or from
    local toVec2 = IsVec3(to) and Vec2(to.x, to.z) or to

    if not IsVec2(fromVec2) or not IsVec2(toVec2) then
        _HarnessInternal.log.error("FindRoadPath requires Vec2 or Vec3 positions", "FindRoadPath")
        return {}
    end

    -- Note: For rails, the parameter should be "rails" not "railroads"
    roadType = roadType or "roads"
    if roadType == "railroads" then
        roadType = "rails"
    end

    local success, path =
        pcall(land.findPathOnRoads, roadType, fromVec2.x, fromVec2.z, toVec2.x, toVec2.z)
    if not success then
        _HarnessInternal.log.error("Failed to find road path: " .. tostring(path), "FindRoadPath")
        return {}
    end

    return path or {}
end
