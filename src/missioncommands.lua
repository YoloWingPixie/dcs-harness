--[[
    MissionCommands Module - DCS World Mission Commands API Wrappers
    
    This module provides validated wrapper functions for DCS F10 radio menu operations,
    including menu creation, command handling, and menu removal.
]]
require("logger")
--- Adds a command to the F10 radio menu
--- @param path table Array of menu path elements (numbers or strings)
--- @param menuItem table Menu item definition with name, enabled, and removable fields
--- @param handler function Function to call when menu item is selected
--- @param params any? Optional parameters to pass to the handler
--- @return number|nil commandId The command ID if successful, nil otherwise
--- @usage local cmdId = AddCommand({"Main", "SubMenu"}, {name="Test", enabled=true}, function() print("Selected") end)
function AddCommand(path, menuItem, handler, params)
    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("AddCommand requires valid path table", "MissionCommands.AddCommand")
        return nil
    end

    if not menuItem or type(menuItem) ~= "table" then
        _HarnessInternal.log.error("AddCommand requires valid menu item table", "MissionCommands.AddCommand")
        return nil
    end

    if not handler or type(handler) ~= "function" then
        _HarnessInternal.log.error("AddCommand requires valid handler function", "MissionCommands.AddCommand")
        return nil
    end

    local success, result = pcall(missionCommands.addCommand, path, menuItem, handler, params)
    if not success then
        _HarnessInternal.log.error("Failed to add command: " .. tostring(result), "MissionCommands.AddCommand")
        return nil
    end

    return result
end

--- Adds a submenu to the F10 radio menu
--- @param path table Array of menu path elements (numbers or strings)
--- @param name string The name of the submenu to create
--- @return table|nil submenuPath The path to the new submenu if successful, nil otherwise
--- @usage local subPath = AddSubMenu({}, "My Menu")
function AddSubMenu(path, name)
    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("AddSubMenu requires valid path table", "MissionCommands.AddSubMenu")
        return nil
    end

    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("AddSubMenu requires valid name string", "MissionCommands.AddSubMenu")
        return nil
    end

    local success, result = pcall(missionCommands.addSubMenu, path, name)
    if not success then
        _HarnessInternal.log.error("Failed to add submenu: " .. tostring(result), "MissionCommands.AddSubMenu")
        return nil
    end

    return result
end

--- Removes a menu item or submenu from the F10 radio menu
--- @param path table Array of menu path elements to remove
--- @return boolean|nil success True if removed successfully, nil otherwise
--- @usage RemoveItem({"Main", "SubMenu", "Command"})
function RemoveItem(path)
    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("RemoveItem requires valid path table", "MissionCommands.RemoveItem")
        return nil
    end

    local success, result = pcall(missionCommands.removeItem, path)
    if not success then
        _HarnessInternal.log.error("Failed to remove item: " .. tostring(result), "MissionCommands.RemoveItem")
        return nil
    end

    return true
end

--- Adds a command to the F10 radio menu for a specific coalition
--- @param coalitionId number Coalition ID (coalition.side.RED or coalition.side.BLUE)
--- @param path table Array of menu path elements
--- @param menuItem table Menu item definition with name, enabled, and removable fields
--- @param handler function Function to call when menu item is selected
--- @param params any? Optional parameters to pass to the handler
--- @return number|nil commandId The command ID if successful, nil otherwise
--- @usage AddCommandForCoalition(coalition.side.BLUE, {}, {name="Intel"}, function() end)
function AddCommandForCoalition(coalitionId, path, menuItem, handler, params)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("AddCommandForCoalition requires valid coalition ID", "MissionCommands.AddCommandForCoalition")
        return nil
    end

    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("AddCommandForCoalition requires valid path table", "MissionCommands.AddCommandForCoalition")
        return nil
    end

    if not menuItem or type(menuItem) ~= "table" then
        _HarnessInternal.log.error("AddCommandForCoalition requires valid menu item table", "MissionCommands.AddCommandForCoalition")
        return nil
    end

    if not handler or type(handler) ~= "function" then
        _HarnessInternal.log.error("AddCommandForCoalition requires valid handler function", "MissionCommands.AddCommandForCoalition")
        return nil
    end

    local success, result = pcall(missionCommands.addCommandForCoalition, coalitionId, path, menuItem, handler, params)
    if not success then
        _HarnessInternal.log.error("Failed to add coalition command: " .. tostring(result), "MissionCommands.AddCommandForCoalition")
        return nil
    end

    return result
end

--- Adds a submenu to the F10 radio menu for a specific coalition
--- @param coalitionId number Coalition ID (coalition.side.RED or coalition.side.BLUE)
--- @param path table Array of menu path elements
--- @param name string The name of the submenu to create
--- @return table|nil submenuPath The path to the new submenu if successful, nil otherwise
--- @usage AddSubMenuForCoalition(coalition.side.RED, {}, "Enemy Options")
function AddSubMenuForCoalition(coalitionId, path, name)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("AddSubMenuForCoalition requires valid coalition ID", "MissionCommands.AddSubMenuForCoalition")
        return nil
    end

    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("AddSubMenuForCoalition requires valid path table", "MissionCommands.AddSubMenuForCoalition")
        return nil
    end

    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("AddSubMenuForCoalition requires valid name string", "MissionCommands.AddSubMenuForCoalition")
        return nil
    end

    local success, result = pcall(missionCommands.addSubMenuForCoalition, coalitionId, path, name)
    if not success then
        _HarnessInternal.log.error("Failed to add coalition submenu: " .. tostring(result), "MissionCommands.AddSubMenuForCoalition")
        return nil
    end

    return result
end

--- Removes a menu item or submenu for a specific coalition
--- @param coalitionId number Coalition ID (coalition.side.RED or coalition.side.BLUE)
--- @param path table Array of menu path elements to remove
--- @return boolean|nil success True if removed successfully, nil otherwise
--- @usage RemoveItemForCoalition(coalition.side.BLUE, {"Intel", "Report"})
function RemoveItemForCoalition(coalitionId, path)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("RemoveItemForCoalition requires valid coalition ID", "MissionCommands.RemoveItemForCoalition")
        return nil
    end

    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("RemoveItemForCoalition requires valid path table", "MissionCommands.RemoveItemForCoalition")
        return nil
    end

    local success, result = pcall(missionCommands.removeItemForCoalition, coalitionId, path)
    if not success then
        _HarnessInternal.log.error("Failed to remove coalition item: " .. tostring(result), "MissionCommands.RemoveItemForCoalition")
        return nil
    end

    return true
end

--- Adds a command to the F10 radio menu for a specific group
--- @param groupId number Group ID from DCS
--- @param path table Array of menu path elements
--- @param menuItem table Menu item definition with name, enabled, and removable fields
--- @param handler function Function to call when menu item is selected
--- @param params any? Optional parameters to pass to the handler
--- @return number|nil commandId The command ID if successful, nil otherwise
--- @usage AddCommandForGroup(groupId, {}, {name="Request Support"}, function() end)
function AddCommandForGroup(groupId, path, menuItem, handler, params)
    if not groupId or type(groupId) ~= "number" then
        _HarnessInternal.log.error("AddCommandForGroup requires valid group ID", "MissionCommands.AddCommandForGroup")
        return nil
    end

    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("AddCommandForGroup requires valid path table", "MissionCommands.AddCommandForGroup")
        return nil
    end

    if not menuItem or type(menuItem) ~= "table" then
        _HarnessInternal.log.error("AddCommandForGroup requires valid menu item table", "MissionCommands.AddCommandForGroup")
        return nil
    end

    if not handler or type(handler) ~= "function" then
        _HarnessInternal.log.error("AddCommandForGroup requires valid handler function", "MissionCommands.AddCommandForGroup")
        return nil
    end

    local success, result = pcall(missionCommands.addCommandForGroup, groupId, path, menuItem, handler, params)
    if not success then
        _HarnessInternal.log.error("Failed to add group command: " .. tostring(result), "MissionCommands.AddCommandForGroup")
        return nil
    end

    return result
end

--- Adds a submenu to the F10 radio menu for a specific group
--- @param groupId number Group ID from DCS
--- @param path table Array of menu path elements
--- @param name string The name of the submenu to create
--- @return table|nil submenuPath The path to the new submenu if successful, nil otherwise
--- @usage AddSubMenuForGroup(groupId, {}, "Flight Options")
function AddSubMenuForGroup(groupId, path, name)
    if not groupId or type(groupId) ~= "number" then
        _HarnessInternal.log.error("AddSubMenuForGroup requires valid group ID", "MissionCommands.AddSubMenuForGroup")
        return nil
    end

    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("AddSubMenuForGroup requires valid path table", "MissionCommands.AddSubMenuForGroup")
        return nil
    end

    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("AddSubMenuForGroup requires valid name string", "MissionCommands.AddSubMenuForGroup")
        return nil
    end

    local success, result = pcall(missionCommands.addSubMenuForGroup, groupId, path, name)
    if not success then
        _HarnessInternal.log.error("Failed to add group submenu: " .. tostring(result), "MissionCommands.AddSubMenuForGroup")
        return nil
    end

    return result
end

--- Removes a menu item or submenu for a specific group
--- @param groupId number Group ID from DCS
--- @param path table Array of menu path elements to remove
--- @return boolean|nil success True if removed successfully, nil otherwise
--- @usage RemoveItemForGroup(groupId, {"Flight Options", "RTB"})
function RemoveItemForGroup(groupId, path)
    if not groupId or type(groupId) ~= "number" then
        _HarnessInternal.log.error("RemoveItemForGroup requires valid group ID", "MissionCommands.RemoveItemForGroup")
        return nil
    end

    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("RemoveItemForGroup requires valid path table", "MissionCommands.RemoveItemForGroup")
        return nil
    end

    local success, result = pcall(missionCommands.removeItemForGroup, groupId, path)
    if not success then
        _HarnessInternal.log.error("Failed to remove group item: " .. tostring(result), "MissionCommands.RemoveItemForGroup")
        return nil
    end

    return true
end

--- Adds a command to the F10 radio menu for a specific unit
--- @param unitId number Unit ID from DCS
--- @param path table Array of menu path elements
--- @param menuItem table Menu item definition with name, enabled, and removable fields
--- @param handler function Function to call when menu item is selected
--- @param params any? Optional parameters to pass to the handler
--- @return number|nil commandId The command ID if successful, nil otherwise
--- @usage AddCommandForUnit(unitId, {}, {name="Eject"}, function() end)
function AddCommandForUnit(unitId, path, menuItem, handler, params)
    if not unitId or type(unitId) ~= "number" then
        _HarnessInternal.log.error("AddCommandForUnit requires valid unit ID", "MissionCommands.AddCommandForUnit")
        return nil
    end

    if not path or type(path) ~= "table" then
        _HarnessInternal.log.error("AddCommandForUnit requires valid path table", "MissionCommands.AddCommandForUnit")
        return nil
    end

    if not menuItem or type(menuItem) ~= "table" then
        _HarnessInternal.log.error("AddCommandForUnit requires valid menu item table", "MissionCommands.AddCommandForUnit")
        return nil
    end

    if not handler or type(handler) ~= "function" then
        _HarnessInternal.log.error("AddCommandForUnit requires valid handler function", "MissionCommands.AddCommandForUnit")
        return nil
    end

    local success, result = pcall(missionCommands.addCommandForUnit, unitId, path, menuItem, handler, params)
    if not success then
        _HarnessInternal.log.error("Failed to add unit command: " .. tostring(result), "MissionCommands.AddCommandForUnit")
        return nil
    end

    return result
end

--- Creates a menu item definition for use with AddCommand functions
--- @param name string The display name of the menu item
--- @param enabled boolean? Whether the item is enabled (default: true)
--- @param removable boolean? Whether the item can be removed (default: true)
--- @return table|nil menuItem Menu item definition or nil on error
--- @usage local item = CreateMenuItem("Launch Attack", true, false)
function CreateMenuItem(name, enabled, removable)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("CreateMenuItem requires valid name string", "MissionCommands.CreateMenuItem")
        return nil
    end

    if enabled == nil then
        enabled = true
    end

    if removable == nil then
        removable = true
    end

    return {
        name = name,
        enabled = enabled,
        removable = removable
    }
end

--- Creates a menu path from variable arguments
--- @param ... string|number Path elements (strings or command IDs)
--- @return table|nil path Array of path elements or nil on error
--- @usage local path = CreateMenuPath("Main", "Options", "Graphics")
function CreateMenuPath(...)
    local path = {}
    for i, v in ipairs({...}) do
        if type(v) == "number" or type(v) == "string" then
            table.insert(path, v)
        else
            _HarnessInternal.log.error("CreateMenuPath requires number or string path elements", "MissionCommands.CreateMenuPath")
            return nil
        end
    end
    return path
end