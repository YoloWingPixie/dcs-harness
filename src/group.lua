--[[
==================================================================================================
    GROUP MODULE
    Validated wrapper functions for DCS Group API
==================================================================================================
]]

--- Get group by name
---@param groupName string The name of the group to retrieve
---@return table? group The group object if found, nil otherwise
---@usage local group = GetGroup("Aerial-1")
function GetGroup(groupName)
    if not groupName or type(groupName) ~= "string" then
        _HarnessInternal.log.error("GetGroup requires string group name", "GetGroup")
        return nil
    end
    
    local success, group = pcall(Group.getByName, groupName)
    if not success then
        _HarnessInternal.log.error("Failed to get group: " .. tostring(group), "GetGroup")
        return nil
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
        _HarnessInternal.log.error("Failed to check group existence: " .. tostring(exists), "GroupExists")
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
        _HarnessInternal.log.error("Failed to get group units: " .. tostring(units), "GetGroupUnits")
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
        _HarnessInternal.log.error("Failed to get group initial size: " .. tostring(size), "GetGroupInitialSize")
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
        _HarnessInternal.log.error("Failed to get group coalition: " .. tostring(coalition), "GetGroupCoalition")
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
        _HarnessInternal.log.error("Failed to get group category: " .. tostring(category), "GetGroupCategory")
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
    local group = GetGroup(groupName)
    if not group then
        return nil
    end
    
    local success, controller = pcall(group.getController, group)
    if not success then
        _HarnessInternal.log.error("Failed to get group controller: " .. tostring(controller), "GetGroupController")
        return nil
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
        _HarnessInternal.log.error(string.format("Failed to send message to group %d: %s", groupId, tostring(result)), "MessageToGroup")
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
        _HarnessInternal.log.error("MessageToCoalition requires numeric coalition ID", "MessageToCoalition")
        return false
    end
    
    if not message or type(message) ~= "string" then
        _HarnessInternal.log.error("MessageToCoalition requires string message", "MessageToCoalition")
        return false
    end
    
    duration = duration or 20
    
    local success, result = pcall(trigger.action.outTextForCoalition, coalitionId, message, duration)
    if not success then
        _HarnessInternal.log.error(string.format("Failed to send message to coalition %d: %s", coalitionId, tostring(result)), "MessageToCoalition")
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
        _HarnessInternal.log.error("Failed to send message to all: " .. tostring(result), "MessageToAll")
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
        _HarnessInternal.log.error("Failed to activate group: " .. tostring(result), "ActivateGroup")
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
        _HarnessInternal.log.error("GetCoalitionGroups requires numeric coalition ID", "GetCoalitionGroups")
        return {}
    end
    
    local success, groups = pcall(coalition.getGroups, coalitionId, categoryId)
    if not success then
        _HarnessInternal.log.error("Failed to get coalition groups: " .. tostring(groups), "GetCoalitionGroups")
        return {}
    end
    
    return groups or {}
end