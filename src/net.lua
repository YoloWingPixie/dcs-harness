--[[
==================================================================================================
    NET MODULE
    Multiplayer networking utilities
==================================================================================================
]]
require("logger")
--- Send chat message to all players or coalition
---@param message string Message text to send
---@param all boolean True to send to all, false for coalition only
---@return boolean success True if message was sent
---@usage SendChat("Hello everyone!", true)
function SendChat(message, all)
    if not message or type(message) ~= "string" then
        _HarnessInternal.log.error("SendChat requires string message", "SendChat")
        return false
    end
    
    if type(all) ~= "boolean" then
        _HarnessInternal.log.error("SendChat requires boolean for 'all' parameter", "SendChat")
        return false
    end
    
    local success, result = pcall(net.send_chat, message, all)
    if not success then
        _HarnessInternal.log.error("Failed to send chat: " .. tostring(result), "SendChat")
        return false
    end
    
    _HarnessInternal.log.info("Sent chat message", "SendChat")
    return true
end

--- Send chat message to specific player
---@param message string Message text to send
---@param playerId number Target player ID
---@param fromId number? Sender player ID (optional)
---@return boolean success True if message was sent
---@usage SendChatTo("Private message", 2)
function SendChatTo(message, playerId, fromId)
    if not message or type(message) ~= "string" then
        _HarnessInternal.log.error("SendChatTo requires string message", "SendChatTo")
        return false
    end
    
    if not playerId or type(playerId) ~= "number" then
        _HarnessInternal.log.error("SendChatTo requires numeric player ID", "SendChatTo")
        return false
    end
    
    if fromId and type(fromId) ~= "number" then
        _HarnessInternal.log.error("SendChatTo fromId must be numeric", "SendChatTo")
        return false
    end
    
    local success, result = pcall(net.send_chat_to, message, playerId, fromId)
    if not success then
        _HarnessInternal.log.error("Failed to send chat to player: " .. tostring(result), "SendChatTo")
        return false
    end
    
    _HarnessInternal.log.info("Sent chat to player " .. playerId, "SendChatTo")
    return true
end

--- Get list of all connected players
---@return table players Array of player info tables
---@usage local players = GetPlayers()
function GetPlayers()
    local success, players = pcall(net.get_player_list)
    if not success then
        _HarnessInternal.log.error("Failed to get player list: " .. tostring(players), "GetPlayers")
        return {}
    end
    
    return players or {}
end

--- Get information about specific player
---@param playerId number Player ID
---@return table? info Player info table or nil on error
---@usage local info = GetPlayerInfo(1)
function GetPlayerInfo(playerId)
    if not playerId or type(playerId) ~= "number" then
        _HarnessInternal.log.error("GetPlayerInfo requires numeric player ID", "GetPlayerInfo")
        return nil
    end
    
    local success, info = pcall(net.get_player_info, playerId)
    if not success then
        _HarnessInternal.log.error("Failed to get player info: " .. tostring(info), "GetPlayerInfo")
        return nil
    end
    
    return info
end

--- Get server settings
---@return table? settings Server settings table or nil on error
---@usage local settings = GetServerSettings()
function GetServerSettings()
    local success, settings = pcall(net.get_server_settings)
    if not success then
        _HarnessInternal.log.error("Failed to get server settings: " .. tostring(settings), "GetServerSettings")
        return nil
    end
    
    return settings
end

--- Kick player from server
---@param playerId number Player ID to kick
---@param reason string? Kick reason message
---@return boolean success True if kick command was sent
---@usage KickPlayer(3, "Team killing")
function KickPlayer(playerId, reason)
    if not playerId or type(playerId) ~= "number" then
        _HarnessInternal.log.error("KickPlayer requires numeric player ID", "KickPlayer")
        return false
    end
    
    reason = reason or "Kicked by server"
    
    local success, result = pcall(net.kick, playerId, reason)
    if not success then
        _HarnessInternal.log.error("Failed to kick player: " .. tostring(result), "KickPlayer")
        return false
    end
    
    _HarnessInternal.log.info("Kicked player " .. playerId .. ": " .. reason, "KickPlayer")
    return true
end

--- Get player's network statistics
---@param playerId number Player ID
---@param statId number Statistic ID (use net.PS_* constants)
---@return number? value Statistic value or nil on error
---@usage local ping = GetPlayerStat(1, net.PS_PING)
function GetPlayerStat(playerId, statId)
    if not playerId or type(playerId) ~= "number" then
        _HarnessInternal.log.error("GetPlayerStat requires numeric player ID", "GetPlayerStat")
        return nil
    end
    
    if not statId or type(statId) ~= "number" then
        _HarnessInternal.log.error("GetPlayerStat requires numeric stat ID", "GetPlayerStat")
        return nil
    end
    
    local success, value = pcall(net.get_stat, playerId, statId)
    if not success then
        _HarnessInternal.log.error("Failed to get player stat: " .. tostring(value), "GetPlayerStat")
        return nil
    end
    
    return value
end

--- Check if running as server
---@return boolean isServer True if running as server
---@usage if IsServer() then ... end
function IsServer()
    local success, result = pcall(net.is_server)
    if not success then
        _HarnessInternal.log.error("Failed to check server status: " .. tostring(result), "IsServer")
        return false
    end
    
    return result == true
end

--- Check if running in multiplayer
---@return boolean isMultiplayer True if in multiplayer
---@usage if IsMultiplayer() then ... end  
function IsMultiplayer()
    local success, result = pcall(net.is_multiplayer)
    if not success then
        _HarnessInternal.log.error("Failed to check multiplayer status: " .. tostring(result), "IsMultiplayer")
        return false
    end
    
    return result == true
end

--- Pause the server
---@param paused boolean True to pause, false to unpause
---@return boolean success True if pause state was changed
---@usage PauseServer(true)
function PauseServer(paused)
    if type(paused) ~= "boolean" then
        _HarnessInternal.log.error("PauseServer requires boolean parameter", "PauseServer")
        return false
    end
    
    local success, result = pcall(net.pause, paused)
    if not success then
        _HarnessInternal.log.error("Failed to pause server: " .. tostring(result), "PauseServer")
        return false
    end
    
    _HarnessInternal.log.info("Server pause state: " .. tostring(paused), "PauseServer")
    return true
end

--- Load a new mission
---@param missionPath string Path to mission file
---@return boolean success True if mission load was initiated
---@usage LoadMission("C:/Missions/my_mission.miz")
function LoadMission(missionPath)
    if not missionPath or type(missionPath) ~= "string" then
        _HarnessInternal.log.error("LoadMission requires string mission path", "LoadMission")
        return false
    end
    
    local success, result = pcall(net.load_mission, missionPath)
    if not success then
        _HarnessInternal.log.error("Failed to load mission: " .. tostring(result), "LoadMission")
        return false
    end
    
    _HarnessInternal.log.info("Loading mission: " .. missionPath, "LoadMission")
    return true
end

--- Load next mission in list
---@return boolean success True if next mission load was initiated
---@usage LoadNextMission()
function LoadNextMission()
    local success, result = pcall(net.load_next_mission)
    if not success then
        _HarnessInternal.log.error("Failed to load next mission: " .. tostring(result), "LoadNextMission")
        return false
    end
    
    _HarnessInternal.log.info("Loading next mission", "LoadNextMission")
    return true
end

--- Get current mission name
---@return string? name Mission name or nil on error
---@usage local mission = GetMissionName()
function GetMissionName()
    local success, name = pcall(net.get_mission_name)
    if not success then
        _HarnessInternal.log.error("Failed to get mission name: " .. tostring(name), "GetMissionName")
        return nil
    end
    
    return name
end

--- Force player to slot
---@param playerId number Player ID
---@param side number Coalition side (0=neutral, 1=red, 2=blue)
---@param slotId string Slot ID string
---@return boolean success True if slot change was initiated
---@usage ForcePlayerSlot(2, 2, "blue_f16_pilot")
function ForcePlayerSlot(playerId, side, slotId)
    if not playerId or type(playerId) ~= "number" then
        _HarnessInternal.log.error("ForcePlayerSlot requires numeric player ID", "ForcePlayerSlot")
        return false
    end
    
    if not side or type(side) ~= "number" then
        _HarnessInternal.log.error("ForcePlayerSlot requires numeric side", "ForcePlayerSlot")
        return false
    end
    
    if not slotId or type(slotId) ~= "string" then
        _HarnessInternal.log.error("ForcePlayerSlot requires string slot ID", "ForcePlayerSlot")
        return false
    end
    
    local success, result = pcall(net.force_player_slot, playerId, side, slotId)
    if not success then
        _HarnessInternal.log.error("Failed to force player slot: " .. tostring(result), "ForcePlayerSlot")
        return false
    end
    
    _HarnessInternal.log.info("Forced player " .. playerId .. " to slot " .. slotId, "ForcePlayerSlot")
    return true
end