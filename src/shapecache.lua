--[[
    ShapeCache Module - Combined cache for drawings and trigger zones
    
    This module provides a unified interface for searching and querying
    both drawings and trigger zones.
]]
require("logger")
require("drawing")
require("zone")
--- Initialize all shape caches (drawings and trigger zones)
---@return boolean success True if all caches initialized successfully
function InitializeShapeCache()
    local drawingSuccess = InitializeDrawingCache()
    local zoneSuccess = InitializeZoneCache()
    
    _HarnessInternal.log.info("Shape cache initialization complete", "ShapeCache.Initialize")
    return drawingSuccess and zoneSuccess
end

--- Get all shapes (drawings and trigger zones)
---@return table shapes Table with drawings and triggerZones arrays
function GetAllShapes()
    return {
        drawings = GetAllDrawings(),
        triggerZones = GetAllZones()
    }
end

--- Find shapes by name (partial match)
---@param pattern string Name pattern to search for
---@return table results Table with matching drawings and triggerZones
function FindShapesByName(pattern)
    if not pattern or type(pattern) ~= "string" then
        _HarnessInternal.log.error("FindShapesByName requires valid pattern", "ShapeCache.FindByName")
        return {drawings = {}, triggerZones = {}}
    end
    
    return {
        drawings = FindDrawingsByName(pattern),
        triggerZones = FindZonesByName(pattern)
    }
end

--- Get shape by exact name (searches both drawings and zones)
---@param name string Shape name
---@return table? shape Shape data with type field or nil if not found
function GetShapeByName(name)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("GetShapeByName requires valid name", "ShapeCache.GetByName")
        return nil
    end
    
    -- Check drawings first
    local drawing = GetDrawingByName(name)
    if drawing then
        drawing.shapeType = "drawing"
        return drawing
    end
    
    -- Check trigger zones
    local zone = GetCachedZoneByName(name)
    if zone then
        zone.shapeType = "triggerZone"
        return zone
    end
    
    return nil
end

--- Check if a point is inside any named shape
---@param point table Point with x, z coordinates
---@param shapeName string? Optional shape name to check specifically
---@return table results Array of shapes containing the point
function GetShapesAtPoint(point, shapeName)
    if not point or type(point) ~= "table" or not point.x or not point.z then
        _HarnessInternal.log.error("GetShapesAtPoint requires valid point with x, z", "ShapeCache.GetShapesAtPoint")
        return {}
    end
    
    local results = {}
    
    if shapeName then
        -- Check specific shape
        local shape = GetShapeByName(shapeName)
        if shape then
            local isInside = false
            if shape.shapeType == "drawing" then
                isInside = IsPointInDrawing(shape, point)
            elseif shape.shapeType == "triggerZone" then
                isInside = IsPointInZoneGeometry(shape, point)
            end
            
            if isInside then
                table.insert(results, shape)
            end
        end
    else
        -- Check all shapes
        local allShapes = GetAllShapes()
        
        -- Check drawings
        for _, drawing in ipairs(allShapes.drawings) do
            if IsPointInDrawing(drawing, point) then
                drawing.shapeType = "drawing"
                table.insert(results, drawing)
            end
        end
        
        -- Check trigger zones
        for _, zone in ipairs(allShapes.triggerZones) do
            if IsPointInZoneGeometry(zone, point) then
                zone.shapeType = "triggerZone"
                table.insert(results, zone)
            end
        end
    end
    
    return results
end

--- Get all circular shapes (both drawings and trigger zones)
---@return table circles Array of circular shapes
function GetAllCircularShapes()
    local circles = {}
    
    -- Get circular drawings
    local polygons = GetDrawingsByType("Polygon")
    for _, drawing in ipairs(polygons) do
        if drawing.polygonMode == "circle" then
            drawing.shapeType = "drawing"
            table.insert(circles, drawing)
        end
    end
    
    -- Get circular trigger zones
    local zones = GetZonesByType("circle")
    for _, zone in ipairs(zones) do
        zone.shapeType = "triggerZone"
        table.insert(circles, zone)
    end
    
    return circles
end

--- Get all polygon shapes (both drawings and trigger zones)
---@return table polygons Array of polygon shapes
function GetAllPolygonShapes()
    local polygons = {}
    
    -- Get polygon drawings
    local drawings = GetDrawingsByType("Polygon")
    for _, drawing in ipairs(drawings) do
        if drawing.polygonMode == "free" or (drawing.points and #drawing.points >= 3) then
            drawing.shapeType = "drawing"
            table.insert(polygons, drawing)
        end
    end
    
    -- Get all lines that are closed (forming polygons)
    local lines = GetDrawingsByType("Line")
    for _, line in ipairs(lines) do
        if line.closed and line.points and #line.points >= 3 then
            line.shapeType = "drawing"
            table.insert(polygons, line)
        end
    end
    
    -- Get polygon trigger zones
    local zones = GetZonesByType("polygon")
    for _, zone in ipairs(zones) do
        zone.shapeType = "triggerZone"
        table.insert(polygons, zone)
    end
    
    return polygons
end

--- Get units in shape
---@param shapeName string Shape name (drawing or trigger zone)
---@return table Array of units inside the shape
function GetUnitsInShape(shapeName)
    if not shapeName or type(shapeName) ~= "string" then
        _HarnessInternal.log.error("GetUnitsInShape requires valid shape name", "ShapeCache.GetUnitsInShape")
        return {}
    end
    
    local shape = GetShapeByName(shapeName)
    if not shape then
        _HarnessInternal.log.warning("Shape not found: " .. shapeName, "ShapeCache.GetUnitsInShape")
        return {}
    end
    
    -- If it's a trigger zone, use GetUnitsInZone with the name
    if shape.shapeType == "triggerZone" then
        return GetUnitsInZone(shapeName)
    end
    
    -- If it's a drawing, use GetUnitsInDrawing
    if shape.shapeType == "drawing" then
        return GetUnitsInDrawing(shapeName)
    end
    
    -- Fallback - shouldn't reach here
    return {}
end

--- Get shape statistics
---@return table stats Statistics about cached shapes
function GetShapeStatistics()
    local allShapes = GetAllShapes()
    local stats = {
        drawings = {
            total = #allShapes.drawings,
            byType = {}
        },
        triggerZones = {
            total = #allShapes.triggerZones,
            byType = {}
        }
    }
    
    -- Count drawings by type
    for _, drawing in ipairs(allShapes.drawings) do
        local dtype = drawing.type or "unknown"
        stats.drawings.byType[dtype] = (stats.drawings.byType[dtype] or 0) + 1
    end
    
    -- Count zones by type
    for _, zone in ipairs(allShapes.triggerZones) do
        local ztype = zone.type or "unknown"
        stats.triggerZones.byType[ztype] = (stats.triggerZones.byType[ztype] or 0) + 1
    end
    
    return stats
end

--- Clear all shape caches
function ClearShapeCache()
    ClearDrawingCache()
    ClearZoneCache()
end

--- Automatically initialize shape cache on mission start
---@return boolean success
function AutoInitializeShapeCache()
    -- Check if we're in a mission
    local success, hasMission = pcall(function()
        return env and env.mission ~= nil
    end)
    
    if success and hasMission then
        return InitializeShapeCache()
    end
    
    return false
end