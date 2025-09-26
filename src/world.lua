--[[
    World Module - DCS World API Wrappers
    
    This module provides validated wrapper functions for DCS world operations,
    including event management, marking panels, and world information queries.
]]

require("logger")
-- require("vector")

--- Adds an event handler to the world
---@param handler table Event handler table with onEvent function
---@return boolean? success Returns true if successful, nil on error
---@usage AddWorldEventHandler({onEvent = function(self, event) ... end})
function AddWorldEventHandler(handler)
    if not handler or type(handler) ~= "table" then
        _HarnessInternal.log.error(
            "AddWorldEventHandler requires valid handler table",
            "World.AddEventHandler"
        )
        return nil
    end

    if not handler.onEvent or type(handler.onEvent) ~= "function" then
        _HarnessInternal.log.error(
            "AddWorldEventHandler handler must have onEvent function",
            "World.AddEventHandler"
        )
        return nil
    end

    local success, result = pcall(world.addEventHandler, handler)
    if not success then
        _HarnessInternal.log.error(
            "Failed to add event handler: " .. tostring(result),
            "World.AddEventHandler"
        )
        return nil
    end

    return true
end

--- Removes an event handler from the world
---@param handler table The event handler table to remove
---@return boolean? success Returns true if successful, nil on error
---@usage RemoveWorldEventHandler(myHandler)
function RemoveWorldEventHandler(handler)
    if not handler or type(handler) ~= "table" then
        _HarnessInternal.log.error(
            "RemoveWorldEventHandler requires valid handler table",
            "World.RemoveEventHandler"
        )
        return nil
    end

    local success, result = pcall(world.removeEventHandler, handler)
    if not success then
        _HarnessInternal.log.error(
            "Failed to remove event handler: " .. tostring(result),
            "World.RemoveEventHandler"
        )
        return nil
    end

    return true
end

--- Gets the player unit in the world
---@return table? player The player unit object or nil if not found
---@usage local player = GetWorldPlayer()
function GetWorldPlayer()
    local success, result = pcall(world.getPlayer)
    if not success then
        _HarnessInternal.log.error("Failed to get player: " .. tostring(result), "World.GetPlayer")
        return nil
    end

    return result
end

--- Gets all airbases in the world
---@return table? airbases Array of airbase objects or nil on error
---@usage local airbases = GetWorldAirbases()
function GetWorldAirbases()
    local success, result = pcall(world.getAirbases)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get world airbases: " .. tostring(result),
            "World.GetAirbases"
        )
        return nil
    end

    return result
end

--- Searches for objects in the world within a volume
---@param category number? Object category to search for
---@param volume table? Search volume definition
---@param objectFilter function? Filter function for objects
---@return table? objects Array of found objects or nil on error
---@usage local objects = SearchWorldObjects(Object.Category.UNIT, sphereVolume)
function SearchWorldObjects(category, volume, objectFilter)
    if category and type(category) ~= "number" then
        _HarnessInternal.log.error(
            "SearchWorldObjects category must be a number if provided",
            "World.SearchObjects"
        )
        return nil
    end

    if volume and type(volume) ~= "table" then
        _HarnessInternal.log.error(
            "SearchWorldObjects volume must be a table if provided",
            "World.SearchObjects"
        )
        return nil
    end

    local success, result = pcall(world.searchObjects, category, volume, objectFilter)
    if not success then
        _HarnessInternal.log.error(
            "Failed to search world objects: " .. tostring(result),
            "World.SearchObjects"
        )
        return nil
    end

    return result
end

--- Gets all mark panels in the world
---@return table? panels Array of mark panel objects or nil on error
---@usage local panels = getMarkPanels()
function GetMarkPanels()
    local success, result = pcall(world.getMarkPanels)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get mark panels: " .. tostring(result),
            "World.GetMarkPanels"
        )
        return nil
    end

    return result
end

--- Adds a marking panel to the world
---@param name string The name of the marking panel
---@param pos table Position table with x and z coordinates
---@return number? panelId The ID of the created panel or nil on error
---@usage local panelId = AddMarkingPanel("Target Zone", {x=1000, z=2000})
function AddMarkingPanel(name, pos)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error(
            "AddMarkingPanel requires valid name string",
            "World.AddMarkingPanel"
        )
        return nil
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.z then
        _HarnessInternal.log.error(
            "AddMarkingPanel requires valid position with x, z",
            "World.AddMarkingPanel"
        )
        return nil
    end

    local success, result = pcall(world.addMarkingPanel, name, pos)
    if not success then
        _HarnessInternal.log.error(
            "Failed to add marking panel: " .. tostring(result),
            "World.AddMarkingPanel"
        )
        return nil
    end

    return result
end

--- Removes a marking panel from the world
---@param id number The ID of the panel to remove
---@return boolean? success Returns true if successful, nil on error
---@usage RemoveMarkingPanel(panelId)
function RemoveMarkingPanel(id)
    if not id then
        _HarnessInternal.log.error(
            "RemoveMarkingPanel requires valid panel ID",
            "World.RemoveMarkingPanel"
        )
        return nil
    end

    local success, result = pcall(world.removeMarkingPanel, id)
    if not success then
        _HarnessInternal.log.error(
            "Failed to remove marking panel: " .. tostring(result),
            "World.RemoveMarkingPanel"
        )
        return nil
    end

    return true
end

--- Processes a world event
---@param event table The event table to process
---@return boolean? success Returns true if successful, nil on error
---@usage OnWorldEvent({id = world.event.S_EVENT_SHOT, ...})
function OnWorldEvent(event)
    if not event or type(event) ~= "table" then
        _HarnessInternal.log.error("OnWorldEvent requires valid event table", "World.OnEvent")
        return nil
    end

    local success, result = pcall(world.onEvent, event)
    if not success then
        _HarnessInternal.log.error(
            "Failed to process world event: " .. tostring(result),
            "World.OnEvent"
        )
        return nil
    end

    return true
end

--- Gets the current weather in the world
---@return table? weather Weather information table or nil on error
---@usage local weather = GetWorldWeather()
function GetWorldWeather()
    local success, result = pcall(world.getWeather)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get world weather: " .. tostring(result),
            "World.GetWeather"
        )
        return nil
    end

    return result
end

--- Removes junk objects within a search volume
---@param searchVolume table The search volume definition
---@return number? count Number of objects removed or nil on error
---@usage local removed = RemoveWorldJunk(sphereVolume)
function RemoveWorldJunk(searchVolume)
    if not searchVolume or type(searchVolume) ~= "table" then
        _HarnessInternal.log.error(
            "RemoveWorldJunk requires valid search volume",
            "World.RemoveJunk"
        )
        return nil
    end

    local success, result = pcall(world.removeJunk, searchVolume)
    if not success then
        _HarnessInternal.log.error(
            "Failed to remove world junk: " .. tostring(result),
            "World.RemoveJunk"
        )
        return nil
    end

    return result
end

--- Creates a world event handler with named event callbacks
---@param handlers table Table of event name to callback function mappings
---@return table? eventHandler Event handler object or nil on error
---@usage local handler = CreateWorldEventHandler({S_EVENT_SHOT = function(event) ... end})
function CreateWorldEventHandler(handlers)
    if not handlers or type(handlers) ~= "table" then
        _HarnessInternal.log.error(
            "CreateWorldEventHandler requires valid handlers table",
            "World.CreateEventHandler"
        )
        return nil
    end

    local eventHandler = {}

    eventHandler.onEvent = function(self, event)
        if not event or not event.id then
            return
        end

        local eventName = nil
        for name, id in pairs(world.event) do
            if id == event.id then
                eventName = name
                break
            end
        end

        if eventName and handlers[eventName] then
            local success, result = pcall(handlers[eventName], event)
            if not success then
                _HarnessInternal.log.error(
                    "Event handler error for " .. eventName .. ": " .. tostring(result),
                    "World.EventHandler"
                )
            end
        end
    end

    return eventHandler
end

--- Gets all world event type constants
---@return table? eventTypes Table of event name to ID mappings or nil on error
---@usage local eventTypes = GetWorldEventTypes()
function GetWorldEventTypes()
    local success, result = pcall(function()
        return world.event
    end)

    if not success then
        _HarnessInternal.log.error(
            "Failed to get world event types: " .. tostring(result),
            "World.GetEventTypes"
        )
        return nil
    end

    return result
end

--- Gets all world volume type constants
---@return table? volumeTypes Table of volume type constants or nil on error
---@usage local volumeTypes = GetWorldVolumeTypes()
function GetWorldVolumeTypes()
    local success, result = pcall(function()
        return world.VolumeType
    end)

    if not success then
        _HarnessInternal.log.error(
            "Failed to get world volume types: " .. tostring(result),
            "World.GetVolumeTypes"
        )
        return nil
    end

    return result
end

--- Creates a search volume for world object searches
---@param volumeType number The volume type constant
---@param params table Parameters for the volume type
---@return table? volume Volume definition or nil on error
---@usage local volume = CreateWorldSearchVolume(world.VolumeType.SPHERE, {point={x=0,y=0,z=0}, radius=1000})
function CreateWorldSearchVolume(volumeType, params)
    if not volumeType or type(volumeType) ~= "number" then
        _HarnessInternal.log.error(
            "CreateWorldSearchVolume requires valid volume type",
            "World.CreateSearchVolume"
        )
        return nil
    end

    if not params or type(params) ~= "table" then
        _HarnessInternal.log.error(
            "CreateWorldSearchVolume requires valid parameters table",
            "World.CreateSearchVolume"
        )
        return nil
    end

    local volume = {
        id = volumeType,
        params = params,
    }

    return volume
end

--- Creates a spherical search volume
---@param center table Center position with x, y, z coordinates
---@param radius number Sphere radius in meters
---@return table? volume Sphere volume definition or nil on error
---@usage local sphere = CreateSphereVolume({x=1000, y=100, z=2000}, 500)
function CreateSphereVolume(center, radius)
    if not center or type(center) ~= "table" or not center.x or not center.y or not center.z then
        _HarnessInternal.log.error(
            "CreateSphereVolume requires valid center position",
            "World.CreateSphereVolume"
        )
        return nil
    end

    if not radius or type(radius) ~= "number" or radius <= 0 then
        _HarnessInternal.log.error(
            "CreateSphereVolume requires valid radius",
            "World.CreateSphereVolume"
        )
        return nil
    end

    return CreateWorldSearchVolume(world.VolumeType.SPHERE, {
        point = center,
        radius = radius,
    })
end

--- Creates a box-shaped search volume
---@param min table Minimum corner position with x, y, z coordinates
---@param max table Maximum corner position with x, y, z coordinates
---@return table? volume Box volume definition or nil on error
---@usage local box = CreateBoxVolume({x=0, y=0, z=0}, {x=1000, y=500, z=1000})
function CreateBoxVolume(min, max)
    if not min or type(min) ~= "table" or not min.x or not min.y or not min.z then
        _HarnessInternal.log.error(
            "CreateBoxVolume requires valid min position",
            "World.CreateBoxVolume"
        )
        return nil
    end

    if not max or type(max) ~= "table" or not max.x or not max.y or not max.z then
        _HarnessInternal.log.error(
            "CreateBoxVolume requires valid max position",
            "World.CreateBoxVolume"
        )
        return nil
    end

    return CreateWorldSearchVolume(world.VolumeType.BOX, {
        min = min,
        max = max,
    })
end

--- Creates a pyramid-shaped search volume
---@param pos table Position and orientation table
---@param length number Length of the pyramid in meters
---@param halfAngleHor number Horizontal half angle in radians
---@param halfAngleVer number Vertical half angle in radians
---@return table? volume Pyramid volume definition or nil on error
---@usage local pyramid = CreatePyramidVolume({x=0, y=100, z=0}, 5000, math.rad(30), math.rad(20))
function CreatePyramidVolume(pos, length, halfAngleHor, halfAngleVer)
    if not pos or type(pos) ~= "table" then
        _HarnessInternal.log.error(
            "CreatePyramidVolume requires valid position",
            "World.CreatePyramidVolume"
        )
        return nil
    end

    if not length or type(length) ~= "number" or length <= 0 then
        _HarnessInternal.log.error(
            "CreatePyramidVolume requires valid length",
            "World.CreatePyramidVolume"
        )
        return nil
    end

    if not halfAngleHor or type(halfAngleHor) ~= "number" then
        _HarnessInternal.log.error(
            "CreatePyramidVolume requires valid horizontal half angle",
            "World.CreatePyramidVolume"
        )
        return nil
    end

    if not halfAngleVer or type(halfAngleVer) ~= "number" then
        _HarnessInternal.log.error(
            "CreatePyramidVolume requires valid vertical half angle",
            "World.CreatePyramidVolume"
        )
        return nil
    end

    return CreateWorldSearchVolume(world.VolumeType.PYRAMID, {
        pos = pos,
        length = length,
        halfAngleHor = halfAngleHor,
        halfAngleVer = halfAngleVer,
    })
end

--- Creates a line segment search volume
---@param from table Start position with x, y, z coordinates
---@param to table End position with x, y, z coordinates
---@return table? volume Segment volume definition or nil on error
---@usage local segment = CreateSegmentVolume({x=0, y=100, z=0}, {x=1000, y=100, z=1000})
function CreateSegmentVolume(from, to)
    if not from or type(from) ~= "table" or not from.x or not from.y or not from.z then
        _HarnessInternal.log.error(
            "CreateSegmentVolume requires valid from position",
            "World.CreateSegmentVolume"
        )
        return nil
    end

    if not to or type(to) ~= "table" or not to.x or not to.y or not to.z then
        _HarnessInternal.log.error(
            "CreateSegmentVolume requires valid to position",
            "World.CreateSegmentVolume"
        )
        return nil
    end

    return CreateWorldSearchVolume(world.VolumeType.SEGMENT, {
        from = from,
        to = to,
    })
end
