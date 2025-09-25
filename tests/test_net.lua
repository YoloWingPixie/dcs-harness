local lu = require('luaunit')

TestNet = {}

function TestNet:setUp()
    -- Save original net if it exists
    self.originalNet = _G.net
    
    -- Mock net API
    _G.net = {
        -- Constants
        PS_PING = 0,
        PS_SCORE = 1,
        PS_PLANE = 2,
        
        -- Functions
        send_chat = function(message, all) return true end,
        send_chat_to = function(message, playerId, fromId) return true end,
        get_player_list = function() return {1, 2, 3} end,
        get_player_info = function(id) 
            return {
                id = id,
                name = "Player" .. id,
                side = id % 2 + 1,
                slot = "slot_" .. id
            }
        end,
        get_server_settings = function()
            return {
                name = "Test Server",
                password = "",
                maxPlayers = 16
            }
        end,
        kick = function(playerId, reason) return true end,
        get_stat = function(playerId, statId) return statId * 10 + playerId end,
        is_server = function() return true end,
        is_multiplayer = function() return true end,
        pause = function(paused) return true end,
        load_mission = function(path) return true end,
        load_next_mission = function() return true end,
        get_mission_name = function() return "test_mission.miz" end,
        force_player_slot = function(playerId, side, slotId) return true end
    }
end

function TestNet:tearDown()
    -- Restore original net
    _G.net = self.originalNet
end

function TestNet:testSendChat()
    -- Test valid chat
    lu.assertTrue(SendChat("Hello world", true))
    lu.assertTrue(SendChat("Team message", false))
    
    -- Test invalid inputs
    lu.assertFalse(SendChat(nil, true))
    lu.assertFalse(SendChat(123, true))
    lu.assertFalse(SendChat("Message", nil))
    lu.assertFalse(SendChat("Message", "invalid"))
end

function TestNet:testSendChatTo()
    -- Test valid chat to player
    lu.assertTrue(SendChatTo("Private message", 1))
    lu.assertTrue(SendChatTo("From player 2", 1, 2))
    
    -- Test invalid inputs
    lu.assertFalse(SendChatTo(nil, 1))
    lu.assertFalse(SendChatTo(123, 1))
    lu.assertFalse(SendChatTo("Message", nil))
    lu.assertFalse(SendChatTo("Message", "invalid"))
    lu.assertFalse(SendChatTo("Message", 1, "invalid"))
end

function TestNet:testGetPlayers()
    local players = GetPlayers()
    lu.assertNotNil(players)
    lu.assertEquals(#players, 3)
    lu.assertEquals(players[1], 1)
end

function TestNet:testGetPlayerInfo()
    -- Test valid player info
    local info = GetPlayerInfo(1)
    lu.assertNotNil(info)
    lu.assertEquals(info.id, 1)
    lu.assertEquals(info.name, "Player1")
    lu.assertEquals(info.side, 2)
    lu.assertEquals(info.slot, "slot_1")
    
    -- Test invalid input
    lu.assertNil(GetPlayerInfo(nil))
    lu.assertNil(GetPlayerInfo("invalid"))
end

function TestNet:testGetServerSettings()
    local settings = GetServerSettings()
    lu.assertNotNil(settings)
    lu.assertEquals(settings.name, "Test Server")
    lu.assertEquals(settings.maxPlayers, 16)
end

function TestNet:testKickPlayer()
    -- Test valid kick
    lu.assertTrue(KickPlayer(1))
    lu.assertTrue(KickPlayer(2, "Custom reason"))
    
    -- Test invalid inputs
    lu.assertFalse(KickPlayer(nil))
    lu.assertFalse(KickPlayer("invalid"))
end

function TestNet:testGetPlayerStat()
    -- Test valid stat
    lu.assertEquals(GetPlayerStat(1, net.PS_PING), 1)
    lu.assertEquals(GetPlayerStat(2, net.PS_SCORE), 12)
    
    -- Test invalid inputs
    lu.assertNil(GetPlayerStat(nil, net.PS_PING))
    lu.assertNil(GetPlayerStat("invalid", net.PS_PING))
    lu.assertNil(GetPlayerStat(1, nil))
    lu.assertNil(GetPlayerStat(1, "invalid"))
end

function TestNet:testServerChecks()
    lu.assertTrue(IsServer())
    lu.assertTrue(IsMultiplayer())
    
    -- Test with false returns
    net.is_server = function() return false end
    net.is_multiplayer = function() return false end
    
    lu.assertFalse(IsServer())
    lu.assertFalse(IsMultiplayer())
end

function TestNet:testPauseServer()
    -- Test valid pause
    lu.assertTrue(PauseServer(true))
    lu.assertTrue(PauseServer(false))
    
    -- Test invalid input
    lu.assertFalse(PauseServer(nil))
    lu.assertFalse(PauseServer("invalid"))
end

function TestNet:testMissionLoading()
    -- Test load mission
    lu.assertTrue(LoadMission("C:/Missions/test.miz"))
    lu.assertFalse(LoadMission(nil))
    lu.assertFalse(LoadMission(123))
    
    -- Test load next
    lu.assertTrue(LoadNextMission())
    
    -- Test get name
    lu.assertEquals(GetMissionName(), "test_mission.miz")
end

function TestNet:testForcePlayerSlot()
    -- Test valid slot change
    lu.assertTrue(ForcePlayerSlot(1, 2, "blue_f16_pilot"))
    
    -- Test invalid inputs
    lu.assertFalse(ForcePlayerSlot(nil, 2, "slot"))
    lu.assertFalse(ForcePlayerSlot("invalid", 2, "slot"))
    lu.assertFalse(ForcePlayerSlot(1, nil, "slot"))
    lu.assertFalse(ForcePlayerSlot(1, "invalid", "slot"))
    lu.assertFalse(ForcePlayerSlot(1, 2, nil))
    lu.assertFalse(ForcePlayerSlot(1, 2, 123))
end