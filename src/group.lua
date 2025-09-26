--[[
==================================================================================================
    GROUP MODULE
    Validated wrapper functions for DCS Group API
==================================================================================================
]]

require("logger")
require("cache")
require("vector")

--- Get group by name
---@param groupName string The name of the group to retrieve
---@return table? group The group object if found, nil otherwise
---@usage local group = GetGroup("Aerial-1")
function GetGroup(groupName)
    if not groupName or type(groupName) ~= "string" then
        _HarnessInternal.log.error("GetGroup requires string group name", "GetGroup")
        return nil
    end

    -- Check cache first
    local cached = _HarnessInternal.cache.groups[groupName]
    if cached then
        -- Verify group still exists
        local success, exists = pcall(function()
            return cached:isExist()
        end)
        if success and exists then
            _HarnessInternal.cache.stats.hits = _HarnessInternal.cache.stats.hits + 1
            return cached
        else
            -- Remove from cache if no longer exists
            RemoveGroupFromCache(groupName)
        end
    end

    -- Get from DCS API
    local success, group = pcall(Group.getByName, groupName)
    if not success then
        _HarnessInternal.log.error("Failed to get group: " .. tostring(group), "GetGroup")
        return nil
    end

    -- Add to cache if valid
    if group then
        _HarnessInternal.cache.groups[groupName] = group
        _HarnessInternal.cache.stats.misses = _HarnessInternal.cache.stats.misses + 1
    end

    return group
end

--- Check if group exists
---@param groupName string The name of the group to check
---@return boolean exists True if group exists, false otherwise
---@usage if GroupExists("Aerial-1") then ... end
function GroupExists(groupName)
    local group = GetGroup(groupName)
    if not group then
        return false
    end

    local success, exists = pcall(group.isExist, group)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check group existence: " .. tostring(exists),
            "GroupExists"
        )
        return false
    end

    return exists
end

--- Get group units
---@param groupName string The name of the group
---@return table? units Array of unit objects if found, nil otherwise
---@usage local units = GetGroupUnits("Aerial-1")
function GetGroupUnits(groupName)
    local group = GetGroup(groupName)
    if not group then
        return nil
    end

    local success, units = pcall(group.getUnits, group)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get group units: " .. tostring(units),
            "GetGroupUnits"
        )
        return nil
    end

    return units
end

--- Get group size
---@param groupName string The name of the group
---@return number size Current number of units in the group (0 if not found)
---@usage local size = GetGroupSize("Aerial-1")
function GetGroupSize(groupName)
    local group = GetGroup(groupName)
    if not group then
        return 0
    end

    local success, size = pcall(group.getSize, group)
    if not success then
        _HarnessInternal.log.error("Failed to get group size: " .. tostring(size), "GetGroupSize")
        return 0
    end

    return size
end

--- Get group initial size
---@param groupName string The name of the group
---@return number size Initial number of units in the group (0 if not found)
---@usage local initialSize = GetGroupInitialSize("Aerial-1")
function GetGroupInitialSize(groupName)
    local group = GetGroup(groupName)
    if not group then
        return 0
    end

    local success, size = pcall(group.getInitialSize, group)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get group initial size: " .. tostring(size),
            "GetGroupInitialSize"
        )
        return 0
    end

    return size
end

--- Get group coalition
---@param groupName string The name of the group
---@return number? coalition The coalition ID if found, nil otherwise
---@usage local coalition = GetGroupCoalition("Aerial-1")
function GetGroupCoalition(groupName)
    local group = GetGroup(groupName)
    if not group then
        return nil
    end

    local success, coalition = pcall(group.getCoalition, group)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get group coalition: " .. tostring(coalition),
            "GetGroupCoalition"
        )
        return nil
    end

    return coalition
end

--- Get group category
---@param groupName string The name of the group
---@return number? category The category ID if found, nil otherwise
---@usage local category = GetGroupCategory("Aerial-1")
function GetGroupCategory(groupName)
    local group = GetGroup(groupName)
    if not group then
        return nil
    end

    local success, category = pcall(group.getCategory, group)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get group category: " .. tostring(category),
            "GetGroupCategory"
        )
        return nil
    end

    return category
end

--- Get group ID
---@param groupName string The name of the group
---@return number? id The group ID if found, nil otherwise
---@usage local id = GetGroupID("Aerial-1")
function GetGroupID(groupName)
    local group = GetGroup(groupName)
    if not group then
        return nil
    end

    local success, id = pcall(group.getID, group)
    if not success then
        _HarnessInternal.log.error("Failed to get group ID: " .. tostring(id), "GetGroupID")
        return nil
    end

    return id
end

--- Get group controller
---@param groupName string The name of the group
---@return table? controller The controller object if found, nil otherwise
---@usage local controller = GetGroupController("Aerial-1")
function GetGroupController(groupName)
    -- Check cache first
    local cacheKey = "group:" .. groupName
    local cached = _HarnessInternal.cache.getController(cacheKey)
    if cached then
        return cached
    end

    local group = GetGroup(groupName)
    if not group then
        return nil
    end

    local success, controller = pcall(group.getController, group)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get group controller: " .. tostring(controller),
            "GetGroupController"
        )
        return nil
    end

    -- Add to cache with optional metadata
    if controller then
        local info = { groupName = groupName }

        -- If this is an air group, capture unit names for reference
        local cat = GetGroupCategory(groupName)
        if cat == Group.Category.AIRPLANE or cat == Group.Category.HELICOPTER then
            local units = GetGroupUnits(groupName)
            if units and type(units) == "table" then
                local names = {}
                for i = 1, #units do
                    local u = units[i]
                    local ok, nm = pcall(function()
                        return u:getName()
                    end)
                    if ok and nm then
                        names[#names + 1] = nm
                    end
                end
                if #names > 0 then
                    info.unitNames = names
                end
            end
        end

        -- Determine and store domain
        local domain = nil
        if cat == Group.Category.AIRPLANE or cat == Group.Category.HELICOPTER then
            domain = "Air"
        elseif cat == Group.Category.GROUND then
            domain = "Ground"
        elseif cat == Group.Category.SHIP then
            domain = "Naval"
        end
        info.domain = domain

        _HarnessInternal.cache.addController(cacheKey, controller, info)
        -- Fallback: ensure metadata is stored even if addController ignores info
        local entry = _HarnessInternal.cache.controllers[cacheKey]
        if entry then
            if info.groupName and entry.groupName == nil then
                entry.groupName = info.groupName
            end
            if info.unitNames and entry.unitNames == nil then
                entry.unitNames = info.unitNames
            end
            if info.domain and entry.domain == nil then
                entry.domain = info.domain
            end
        end
    end

    return controller
end

--- Send message to group
---@param groupId number The group ID to send message to
---@param message string The message text
---@param duration number? Duration in seconds (default 20)
---@return boolean success True if message sent successfully
---@usage MessageToGroup(1, "Hello group", 10)
function MessageToGroup(groupId, message, duration)
    if not groupId or type(groupId) ~= "number" then
        _HarnessInternal.log.error("MessageToGroup requires numeric group ID", "MessageToGroup")
        return false
    end

    if not message or type(message) ~= "string" then
        _HarnessInternal.log.error("MessageToGroup requires string message", "MessageToGroup")
        return false
    end

    duration = duration or 20

    local success, result = pcall(trigger.action.outTextForGroup, groupId, message, duration, false)
    if not success then
        _HarnessInternal.log.error(
            string.format("Failed to send message to group %d: %s", groupId, tostring(result)),
            "MessageToGroup"
        )
        return false
    end

    return true
end

--- Send message to coalition
---@param coalitionId number The coalition ID to send message to
---@param message string The message text
---@param duration number? Duration in seconds (default 20)
---@return boolean success True if message sent successfully
---@usage MessageToCoalition(coalition.side.BLUE, "Hello blues", 10)
function MessageToCoalition(coalitionId, message, duration)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "MessageToCoalition requires numeric coalition ID",
            "MessageToCoalition"
        )
        return false
    end

    if not message or type(message) ~= "string" then
        _HarnessInternal.log.error(
            "MessageToCoalition requires string message",
            "MessageToCoalition"
        )
        return false
    end

    duration = duration or 20

    local success, result =
        pcall(trigger.action.outTextForCoalition, coalitionId, message, duration)
    if not success then
        _HarnessInternal.log.error(
            string.format(
                "Failed to send message to coalition %d: %s",
                coalitionId,
                tostring(result)
            ),
            "MessageToCoalition"
        )
        return false
    end

    return true
end

--- Send message to all
---@param message string The message text
---@param duration number? Duration in seconds (default 20)
---@return boolean success True if message sent successfully
---@usage MessageToAll("Hello everyone", 10)
function MessageToAll(message, duration)
    if not message or type(message) ~= "string" then
        _HarnessInternal.log.error("MessageToAll requires string message", "MessageToAll")
        return false
    end

    duration = duration or 20

    local success, result = pcall(trigger.action.outText, message, duration)
    if not success then
        _HarnessInternal.log.error(
            "Failed to send message to all: " .. tostring(result),
            "MessageToAll"
        )
        return false
    end

    return true
end

--- Activate group
---@param groupName string The name of the group to activate
---@return boolean success True if group activated successfully
---@usage ActivateGroup("Aerial-1")
function ActivateGroup(groupName)
    local group = GetGroup(groupName)
    if not group then
        return false
    end

    local success, result = pcall(group.activate, group)
    if not success then
        _HarnessInternal.log.error(
            "Failed to activate group: " .. tostring(result),
            "ActivateGroup"
        )
        return false
    end

    return true
end

--- Get all groups of coalition and category
---@param coalitionId number The coalition ID to query
---@param categoryId number? Optional category ID to filter by
---@return table groups Array of group objects (empty if error)
---@usage local blueAirGroups = GetCoalitionGroups(coalition.side.BLUE, Group.Category.AIRPLANE)
function GetCoalitionGroups(coalitionId, categoryId)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error(
            "GetCoalitionGroups requires numeric coalition ID",
            "GetCoalitionGroups"
        )
        return {}
    end

    local success, groups = pcall(coalition.getGroups, coalitionId, categoryId)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get coalition groups: " .. tostring(groups),
            "GetCoalitionGroups"
        )
        return {}
    end

    return groups or {}
end

-- Advanced Group Functions

--- Get group name
---@param group table Group object
---@return string? name Group name or nil on error
---@usage local name = GetGroupName(group)
function GetGroupName(group)
    if not group then
        _HarnessInternal.log.error("GetGroupName requires group", "GetGroupName")
        return nil
    end

    local success, name = pcall(function()
        return group:getName()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to get group name: " .. tostring(name), "GetGroupName")
        return nil
    end

    return name
end

--- Get unit by index
---@param group table Group object
---@param index number Unit index (1-based)
---@return table? unit Unit object or nil on error
---@usage local unit = GetGroupUnit(group, 1)
function GetGroupUnit(group, index)
    if not group then
        _HarnessInternal.log.error("GetGroupUnit requires group", "GetGroupUnit")
        return nil
    end

    if not index or type(index) ~= "number" then
        _HarnessInternal.log.error("GetGroupUnit requires numeric index", "GetGroupUnit")
        return nil
    end

    local success, unit = pcall(function()
        return group:getUnit(index)
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit by index: " .. tostring(unit),
            "GetGroupUnit"
        )
        return nil
    end

    return unit
end

--- Get group category extended
---@param group table Group object
---@return number? category Extended category or nil on error
---@usage local cat = GetGroupCategoryEx(group)
function GetGroupCategoryEx(group)
    if not group then
        _HarnessInternal.log.error("GetGroupCategoryEx requires group", "GetGroupCategoryEx")
        return nil
    end

    local success, category = pcall(function()
        return group:getCategoryEx()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get group category ex: " .. tostring(category),
            "GetGroupCategoryEx"
        )
        return nil
    end

    return category
end

--- Enable/disable group emissions
---@param group table Group object
---@param enabled boolean True to enable emissions
---@return boolean success True if emissions were set
---@usage EnableGroupEmissions(group, false) -- Go dark
function EnableGroupEmissions(group, enabled)
    if not group then
        _HarnessInternal.log.error("EnableGroupEmissions requires group", "EnableGroupEmissions")
        return false
    end

    if type(enabled) ~= "boolean" then
        _HarnessInternal.log.error(
            "EnableGroupEmissions requires boolean enabled",
            "EnableGroupEmissions"
        )
        return false
    end

    local success, result = pcall(function()
        group:enableEmission(enabled)
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set group emissions: " .. tostring(result),
            "EnableGroupEmissions"
        )
        return false
    end

    _HarnessInternal.log.info("Set group emissions: " .. tostring(enabled), "EnableGroupEmissions")
    return true
end

--- Destroy group without events
---@param group table Group object
---@return boolean success True if destroyed
---@usage DestroyGroup(group)
function DestroyGroup(group)
    if not group then
        _HarnessInternal.log.error("DestroyGroup requires group", "DestroyGroup")
        return false
    end

    local success, result = pcall(function()
        group:destroy()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to destroy group: " .. tostring(result), "DestroyGroup")
        return false
    end

    _HarnessInternal.log.info("Destroyed group", "DestroyGroup")
    return true
end

--- Check if group is embarking
---@param group table Group object
---@return boolean? embarking True if embarking, nil on error
---@usage if IsGroupEmbarking(group) then ... end
function IsGroupEmbarking(group)
    if not group then
        _HarnessInternal.log.error("IsGroupEmbarking requires group", "IsGroupEmbarking")
        return nil
    end

    local success, embarking = pcall(function()
        return group:embarking()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check group embarking: " .. tostring(embarking),
            "IsGroupEmbarking"
        )
        return nil
    end

    return embarking
end

--- Create map marker for group
---@param group table Group object
---@param point table Position for marker (Vec3)
---@param text string Marker text
---@return boolean success True if marker created
---@usage MarkGroup(group, position, "Enemy armor")
function MarkGroup(group, point, text)
    if not group then
        _HarnessInternal.log.error("MarkGroup requires group", "MarkGroup")
        return false
    end

    if not point or not IsVec3(point) then
        _HarnessInternal.log.error("MarkGroup requires Vec3 position", "MarkGroup")
        return false
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("MarkGroup requires string text", "MarkGroup")
        return false
    end

    local success, result = pcall(function()
        group:markGroup(point, text)
    end)
    if not success then
        _HarnessInternal.log.error("Failed to mark group: " .. tostring(result), "MarkGroup")
        return false
    end

    _HarnessInternal.log.info("Marked group with: " .. text, "MarkGroup")
    return true
end
