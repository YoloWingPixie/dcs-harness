--[[
    Drawing Module - DCS World Drawing API Wrappers
    
    This module provides validated wrapper functions for DCS drawing operations,
    including getting drawing objects from the mission.
]]

require("logger")
require("world")
require("unit")
require("group")
require("coalition")

--- Get all drawings from the mission
---@return table? drawings Table of all drawing layers and objects or nil on error
---@usage local drawings = GetDrawings()
function GetDrawings()
    local success, result = pcall(function()
        if env and env.mission and env.mission.drawings then
            return env.mission.drawings
        end
        return nil
    end)
    
    if not success then
        _HarnessInternal.log.error("Failed to get drawings: " .. tostring(result), "Drawing.GetDrawings")
        return nil
    end
    
    return result
end

--- Process drawing objects and extract geometry
---@param drawing table Drawing object to process
---@return table? geometry Processed geometry data or nil on error
function ProcessDrawingGeometry(drawing)
    if not drawing or type(drawing) ~= "table" then
        return nil
    end
    
    local geometry = {
        name = drawing.name,
        type = drawing.primitiveType,
        visible = drawing.visible,
        layerName = drawing.layerName,
        mapX = drawing.mapX,
        mapY = drawing.mapY
    }
    
    -- Convert mapX, mapY to DCS coordinate system (x, z)
    if geometry.mapX and geometry.mapY then
        geometry.x = geometry.mapX
        geometry.z = geometry.mapY
        geometry.y = 0 -- Default ground level
    end
    
    -- Process based on primitive type
    if drawing.primitiveType == "Line" then
        geometry.lineMode = drawing.lineMode
        geometry.closed = drawing.closed
        geometry.points = {}
        
        if drawing.points then
            for i, point in ipairs(drawing.points) do
                table.insert(geometry.points, {
                    x = (drawing.mapX or 0) + (point.x or 0),
                    y = 0,
                    z = (drawing.mapY or 0) + (point.y or 0)
                })
            end
        end
        
    elseif drawing.primitiveType == "Polygon" then
        geometry.polygonMode = drawing.polygonMode
        
        if drawing.polygonMode == "circle" then
            geometry.radius = drawing.radius
            geometry.center = {x = geometry.x, y = 0, z = geometry.z}
            
        elseif drawing.polygonMode == "rect" then
            geometry.width = drawing.width
            geometry.height = drawing.height
            geometry.angle = drawing.angle or 0
            geometry.center = {x = geometry.x, y = 0, z = geometry.z}
            
        elseif drawing.polygonMode == "oval" then
            geometry.r1 = drawing.r1
            geometry.r2 = drawing.r2
            geometry.angle = drawing.angle or 0
            geometry.center = {x = geometry.x, y = 0, z = geometry.z}
            
        elseif drawing.polygonMode == "arrow" then
            geometry.length = drawing.length
            geometry.angle = drawing.angle or 0
            geometry.points = {}
            
            if drawing.points then
                for i, point in ipairs(drawing.points) do
                    table.insert(geometry.points, {
                        x = (drawing.mapX or 0) + (point.x or 0),
                        y = 0,
                        z = (drawing.mapY or 0) + (point.y or 0)
                    })
                end
            end
            
        elseif drawing.polygonMode == "free" and drawing.points then
            geometry.points = {}
            for i, point in ipairs(drawing.points) do
                table.insert(geometry.points, {
                    x = (drawing.mapX or 0) + (point.x or 0),
                    y = 0,
                    z = (drawing.mapY or 0) + (point.y or 0)
                })
            end
        end
        
    elseif drawing.primitiveType == "Icon" then
        geometry.file = drawing.file
        geometry.scale = drawing.scale or 1
        geometry.angle = drawing.angle or 0
        geometry.position = {x = geometry.x, y = 0, z = geometry.z}
    end
    
    -- Store color information if available
    if drawing.colorString then
        geometry.color = drawing.colorString
    end
    if drawing.fillColorString then
        geometry.fillColor = drawing.fillColorString
    end
    
    return geometry
end

--- Initialize drawing cache
---@return boolean success True if cache initialized successfully
function InitializeDrawingCache()
    if not _HarnessInternal.cache then
        _HarnessInternal.cache = {}
    end
    
    _HarnessInternal.cache.drawings = {
        all = {},
        byName = {},
        byType = {},
        byLayer = {}
    }
    
    -- Get mission drawings
    local missionDrawings = GetDrawings()
    if not missionDrawings then
        _HarnessInternal.log.warning("No drawings found in mission", "Drawing.InitializeCache")
        return true
    end
    
    -- Process each layer
    if missionDrawings.layers then
        for _, layer in pairs(missionDrawings.layers) do
            if layer.objects then
                for _, drawing in pairs(layer.objects) do
                    local geometry = ProcessDrawingGeometry(drawing)
                    if geometry then
                        -- Store in all
                        table.insert(_HarnessInternal.cache.drawings.all, geometry)
                        
                        -- Index by name
                        if geometry.name then
                            _HarnessInternal.cache.drawings.byName[geometry.name] = geometry
                        end
                        
                        -- Index by type
                        if geometry.type then
                            if not _HarnessInternal.cache.drawings.byType[geometry.type] then
                                _HarnessInternal.cache.drawings.byType[geometry.type] = {}
                            end
                            table.insert(_HarnessInternal.cache.drawings.byType[geometry.type], geometry)
                        end
                        
                        -- Index by layer
                        if geometry.layerName then
                            if not _HarnessInternal.cache.drawings.byLayer[geometry.layerName] then
                                _HarnessInternal.cache.drawings.byLayer[geometry.layerName] = {}
                            end
                            table.insert(_HarnessInternal.cache.drawings.byLayer[geometry.layerName], geometry)
                        end
                    end
                end
            end
        end
    end
    
    _HarnessInternal.log.info("Drawing cache initialized with " .. #_HarnessInternal.cache.drawings.all .. " drawings", "Drawing.InitializeCache")
    return true
end

--- Get all cached drawings
---@return table Array of all drawing geometries
function GetAllDrawings()
    if not _HarnessInternal.cache or not _HarnessInternal.cache.drawings then
        InitializeDrawingCache()
    end
    
    return _HarnessInternal.cache.drawings.all or {}
end

--- Get drawing by exact name
---@param name string Drawing name
---@return table? drawing Drawing geometry or nil if not found
function GetDrawingByName(name)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("GetDrawingByName requires valid name", "Drawing.GetByName")
        return nil
    end
    
    if not _HarnessInternal.cache or not _HarnessInternal.cache.drawings then
        InitializeDrawingCache()
    end
    
    return _HarnessInternal.cache.drawings.byName[name]
end

--- Find drawings by partial name
---@param pattern string Name pattern to search for
---@return table Array of matching drawing geometries
function FindDrawingsByName(pattern)
    if not pattern or type(pattern) ~= "string" then
        _HarnessInternal.log.error("FindDrawingsByName requires valid pattern", "Drawing.FindByName")
        return {}
    end
    
    if not _HarnessInternal.cache or not _HarnessInternal.cache.drawings then
        InitializeDrawingCache()
    end
    
    local results = {}
    local lowerPattern = string.lower(pattern)
    
    for _, drawing in ipairs(_HarnessInternal.cache.drawings.all) do
        if drawing.name and string.find(string.lower(drawing.name), lowerPattern, 1, true) then
            table.insert(results, drawing)
        end
    end
    
    return results
end

--- Get all drawings of a specific type
---@param drawingType string Drawing type (Line, Polygon, Icon)
---@return table Array of drawing geometries of the specified type
function GetDrawingsByType(drawingType)
    if not drawingType or type(drawingType) ~= "string" then
        _HarnessInternal.log.error("GetDrawingsByType requires valid type", "Drawing.GetByType")
        return {}
    end
    
    if not _HarnessInternal.cache or not _HarnessInternal.cache.drawings then
        InitializeDrawingCache()
    end
    
    return _HarnessInternal.cache.drawings.byType[drawingType] or {}
end

--- Get all drawings in a specific layer
---@param layerName string Layer name
---@return table Array of drawing geometries in the specified layer
function GetDrawingsByLayer(layerName)
    if not layerName or type(layerName) ~= "string" then
        _HarnessInternal.log.error("GetDrawingsByLayer requires valid layer name", "Drawing.GetByLayer")
        return {}
    end
    
    if not _HarnessInternal.cache or not _HarnessInternal.cache.drawings then
        InitializeDrawingCache()
    end
    
    return _HarnessInternal.cache.drawings.byLayer[layerName] or {}
end

--- Check if a point is inside a drawing shape
---@param drawing table Drawing geometry
---@param point table Point with x, z coordinates
---@return boolean isInside True if point is inside the shape
function IsPointInDrawing(drawing, point)
    if not drawing or not point then
        return false
    end
    
    if drawing.type == "Polygon" then
        if drawing.polygonMode == "circle" and drawing.center and drawing.radius then
            local dx = point.x - drawing.center.x
            local dz = point.z - drawing.center.z
            return (dx * dx + dz * dz) <= (drawing.radius * drawing.radius)
            
        elseif drawing.polygonMode == "rect" and drawing.center and drawing.width and drawing.height then
            -- Simple axis-aligned check (ignoring rotation for now)
            local halfWidth = drawing.width / 2
            local halfHeight = drawing.height / 2
            local dx = math.abs(point.x - drawing.center.x)
            local dz = math.abs(point.z - drawing.center.z)
            return dx <= halfWidth and dz <= halfHeight
            
        elseif drawing.points and #drawing.points >= 3 then
            -- Point-in-polygon test using ray casting algorithm
            local x, z = point.x, point.z
            local inside = false
            local j = #drawing.points
            
            for i = 1, #drawing.points do
                local xi, zi = drawing.points[i].x, drawing.points[i].z
                local xj, zj = drawing.points[j].x, drawing.points[j].z
                
                if ((zi > z) ~= (zj > z)) and (x < (xj - xi) * (z - zi) / (zj - zi) + xi) then
                    inside = not inside
                end
                j = i
            end
            
            return inside
        end
    elseif drawing.type == "Line" and drawing.closed and drawing.points and #drawing.points >= 3 then
        -- Closed lines form polygons, use same algorithm
        local x, z = point.x, point.z
        local inside = false
        local j = #drawing.points
        
        for i = 1, #drawing.points do
            local xi, zi = drawing.points[i].x, drawing.points[i].z
            local xj, zj = drawing.points[j].x, drawing.points[j].z
            
            if ((zi > z) ~= (zj > z)) and (x < (xj - xi) * (z - zi) / (zj - zi) + xi) then
                inside = not inside
            end
            j = i
        end
        
        return inside
    end
    
    return false
end

--- Calculate bounding sphere for a set of points
---@param points table Array of points with x, z coordinates
---@return table center Center point of bounding sphere
---@return number radius Radius of bounding sphere
local function CalculateBoundingSphere(points)
    if not points or #points == 0 then
        return {x = 0, y = 0, z = 0}, 0
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
        z = sumZ / #points
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

--- Get units in drawing
---@param drawingName string The name of the drawing
---@param coalitionId number? Optional coalition ID to filter by (0=neutral, 1=red, 2=blue)
---@return table units Array of unit objects found in drawing
---@usage local units = GetUnitsInDrawing("Target Area", coalition.side.RED)
function GetUnitsInDrawing(drawingName, coalitionId)
    local unitsInDrawing = {}
    
    -- Get drawing geometry
    local drawing = GetDrawingByName(drawingName)
    if not drawing then
        return {}
    end
    
    -- Create search volume based on drawing type
    local searchVolume
    if drawing.type == "Polygon" then
        if drawing.polygonMode == "circle" and drawing.center and drawing.radius then
            -- For circular drawings, use sphere volume with 1.5x radius for search
            searchVolume = CreateSphereVolume(drawing.center, drawing.radius * 1.5)
            
        elseif drawing.polygonMode == "rect" and drawing.center and drawing.width and drawing.height then
            -- For rectangles, calculate bounding sphere with 1.5x radius
            local halfWidth = drawing.width / 2
            local halfHeight = drawing.height / 2
            local radius = math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight) * 1.5
            searchVolume = CreateSphereVolume(drawing.center, radius)
            
        elseif drawing.points and #drawing.points >= 3 then
            -- For polygon drawings, calculate bounding sphere with 1.5x radius
            local center, radius = CalculateBoundingSphere(drawing.points)
            searchVolume = CreateSphereVolume(center, radius * 1.5)
        else
            return {}
        end
    elseif drawing.type == "Line" and drawing.closed and drawing.points and #drawing.points >= 3 then
        -- Closed lines form polygons
        local center, radius = CalculateBoundingSphere(drawing.points)
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
        
        -- Get unit position for precise drawing check
        local pos = GetUnitPosition(unit)
        if pos then
            local point = {x = pos.x, z = pos.z}
            
            -- Check if unit is actually in the drawing (not just the bounding sphere)
            if IsPointInDrawing(drawing, point) then
                table.insert(unitsInDrawing, unit)
            end
        end
        
        return true
    end
    
    -- Search for units in the volume
    -- Object.Category.UNIT = 1 in DCS
    SearchWorldObjects(1, searchVolume, handleUnit)
    
    return unitsInDrawing
end

--- Get drawings containing a specific point
---@param point table Point with x, z coordinates
---@param drawingType string? Optional filter by drawing type
---@return table drawings Array of drawings containing the point
---@usage local drawings = GetDrawingsAtPoint({x=1000, z=2000})
function GetDrawingsAtPoint(point, drawingType)
    if not point or type(point) ~= "table" or not point.x or not point.z then
        _HarnessInternal.log.error("GetDrawingsAtPoint requires valid point with x, z", "Drawing.GetDrawingsAtPoint")
        return {}
    end
    
    if not _HarnessInternal.cache or not _HarnessInternal.cache.drawings then
        InitializeDrawingCache()
    end
    
    local results = {}
    local drawings = drawingType and GetDrawingsByType(drawingType) or GetAllDrawings()
    
    for _, drawing in ipairs(drawings) do
        if IsPointInDrawing(drawing, point) then
            table.insert(results, drawing)
        end
    end
    
    return results
end

--- Clear drawing cache
function ClearDrawingCache()
    if _HarnessInternal.cache and _HarnessInternal.cache.drawings then
        _HarnessInternal.cache.drawings = {
            all = {},
            byName = {},
            byType = {},
            byLayer = {}
        }
    end
end