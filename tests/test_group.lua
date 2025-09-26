-- test_group.lua
local lu = require("luaunit")
require("test_utils")

-- Setup test environment
package.path = package.path .. ";../src/?.lua"

-- Create isolated test suite
TestGroup = CreateIsolatedTestSuite("TestGroup", {})

function TestGroup:setUp()
    -- Load required modules in clean environment
    require("mock_dcs")

    -- Initialize _HarnessInternal before loading any harness modules
    HARNESS_VERSION = "1.0.0-test"
    _HarnessInternal = {
        loggers = {},
        defaultNamespace = "Harness",
    }

    -- Load harness modules using dofile like the test runner does
    dofile("../src/logger.lua")
    dofile("../src/cache.lua")
    dofile("../src/vector.lua")
    dofile("../src/misc.lua")
    dofile("../src/coalition.lua")
    dofile("../src/group.lua")

    -- Internal logger should already be created by logger.lua
    -- No need to create it manually

    -- Clear cache data but preserve functions
    if _HarnessInternal.cache then
        _HarnessInternal.cache.units = {}
        _HarnessInternal.cache.groups = {}
        _HarnessInternal.cache.controllers = {}
        _HarnessInternal.cache.airbases = {}
        _HarnessInternal.cache.stats = { hits = 0, misses = 0, evictions = 0 }
    end

    -- Save original mock functions
    self.original_getByName = Group.getByName
    self.original_getGroups = coalition.getGroups
    self.original_outText = trigger.action.outText
    self.original_outTextForGroup = trigger.action.outTextForGroup
    self.original_outTextForCoalition = trigger.action.outTextForCoalition

    -- Create mock units for groups
    local mockUnit1 = {
        isExist = function(self)
            return true
        end,
        getName = function(self)
            return "Unit-1"
        end,
    }
    local mockUnit2 = {
        isExist = function(self)
            return true
        end,
        getName = function(self)
            return "Unit-2"
        end,
    }
    local mockUnit3 = {
        isExist = function(self)
            return true
        end,
        getName = function(self)
            return "Unit-3"
        end,
    }

    -- Create detailed mock groups
    self.mockGroups = {
        ["Aerial-1"] = {
            isExist = function(self)
                return true
            end,
            getUnits = function(self)
                return { mockUnit1, mockUnit2 }
            end,
            getSize = function(self)
                return 2
            end,
            getInitialSize = function(self)
                return 4
            end,
            getCoalition = function(self)
                return 2
            end, -- Blue
            getCategory = function(self)
                return 0
            end, -- AIRPLANE
            getID = function(self)
                return 101
            end,
            getController = function(self)
                return { type = "AI" }
            end,
            activate = function(self)
                return true
            end,
            getName = function(self)
                return "Aerial-1"
            end,
        },
        ["Ground-1"] = {
            isExist = function(self)
                return true
            end,
            getUnits = function(self)
                return { mockUnit3 }
            end,
            getSize = function(self)
                return 1
            end,
            getInitialSize = function(self)
                return 1
            end,
            getCoalition = function(self)
                return 1
            end, -- Red
            getCategory = function(self)
                return 2
            end, -- GROUND
            getID = function(self)
                return 201
            end,
            getController = function(self)
                return { type = "AI" }
            end,
            activate = function(self)
                return true
            end,
            getName = function(self)
                return "Ground-1"
            end,
        },
        ["Destroyed-1"] = {
            isExist = function(self)
                return false
            end,
            getUnits = function(self)
                return {}
            end,
            getSize = function(self)
                return 0
            end,
            getInitialSize = function(self)
                return 2
            end,
            getName = function(self)
                return "Destroyed-1"
            end,
        },
        ["Empty-1"] = {
            isExist = function(self)
                return true
            end,
            getUnits = function(self)
                return {}
            end,
            getSize = function(self)
                return 0
            end,
            getInitialSize = function(self)
                return 3
            end,
            getCoalition = function(self)
                return 0
            end, -- Neutral
            getCategory = function(self)
                return 3
            end, -- SHIP
            getID = function(self)
                return 301
            end,
            getController = function(self)
                return { type = "AI" }
            end,
            activate = function(self)
                return true
            end,
            getName = function(self)
                return "Empty-1"
            end,
        },
    }

    -- Override getByName to use mock groups
    Group.getByName = function(name)
        return self.mockGroups[name]
    end

    -- Track message calls
    self.messagesSent = {}

    trigger.action.outText = function(message, duration)
        table.insert(self.messagesSent, { type = "all", message = message, duration = duration })
        return true
    end

    trigger.action.outTextForGroup = function(groupId, message, duration, clear)
        table.insert(
            self.messagesSent,
            { type = "group", groupId = groupId, message = message, duration = duration }
        )
        return true
    end

    trigger.action.outTextForCoalition = function(coalitionId, message, duration)
        table.insert(
            self.messagesSent,
            { type = "coalition", coalitionId = coalitionId, message = message, duration = duration }
        )
        return true
    end
end

function TestGroup:tearDown()
    -- Restore original mock functions
    Group.getByName = self.original_getByName
    coalition.getGroups = self.original_getGroups
    trigger.action.outText = self.original_outText
    trigger.action.outTextForGroup = self.original_outTextForGroup
    trigger.action.outTextForCoalition = self.original_outTextForCoalition
end

-- GetGroup tests
function TestGroup:testGetGroup_ValidGroup()
    local group = GetGroup("Aerial-1")
    lu.assertNotNil(group)
    lu.assertEquals(group:getName(), "Aerial-1")
end

function TestGroup:testGetGroup_NonExistentGroup()
    local group = GetGroup("NonExistent")
    lu.assertNil(group)
end

function TestGroup:testGetGroup_NilName()
    local group = GetGroup(nil)
    lu.assertNil(group)
end

function TestGroup:testGetGroup_InvalidType()
    local group = GetGroup(12345)
    lu.assertNil(group)
end

function TestGroup:testGetGroup_EmptyString()
    local group = GetGroup("")
    lu.assertNil(group)
end

function TestGroup:testGetGroup_APIError()
    -- Clear cache first
    ClearGroupCache()

    -- Save original function
    local originalGetByName = Group.getByName

    -- Override with error function
    Group.getByName = function(name)
        error("DCS API error")
    end

    local group = GetGroup("TestErrorGroup")
    lu.assertNil(group)

    -- Restore original function
    Group.getByName = originalGetByName
end

-- GroupExists tests
function TestGroup:testGroupExists_ExistingGroup()
    local exists = GroupExists("Aerial-1")
    lu.assertTrue(exists)
end

function TestGroup:testGroupExists_DestroyedGroup()
    local exists = GroupExists("Destroyed-1")
    lu.assertFalse(exists)
end

function TestGroup:testGroupExists_NonExistentGroup()
    local exists = GroupExists("NonExistent")
    lu.assertFalse(exists)
end

function TestGroup:testGroupExists_EmptyGroup()
    local exists = GroupExists("Empty-1")
    lu.assertTrue(exists) -- Empty but still exists
end

function TestGroup:testGroupExists_APIError()
    self.mockGroups["ErrorGroup"] = {
        isExist = function(self)
            error("API error")
        end,
        getName = function(self)
            return "ErrorGroup"
        end,
    }
    local exists = GroupExists("ErrorGroup")
    lu.assertFalse(exists)
end

-- GetGroupUnits tests
function TestGroup:testGetGroupUnits_MultipleUnits()
    local units = GetGroupUnits("Aerial-1")
    lu.assertNotNil(units)
    lu.assertEquals(#units, 2)
    lu.assertEquals(units[1]:getName(), "Unit-1")
    lu.assertEquals(units[2]:getName(), "Unit-2")
end

function TestGroup:testGetGroupUnits_SingleUnit()
    local units = GetGroupUnits("Ground-1")
    lu.assertNotNil(units)
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit-3")
end

function TestGroup:testGetGroupUnits_EmptyGroup()
    local units = GetGroupUnits("Empty-1")
    lu.assertNotNil(units)
    lu.assertEquals(#units, 0)
end

function TestGroup:testGetGroupUnits_NonExistentGroup()
    local units = GetGroupUnits("NonExistent")
    lu.assertNil(units)
end

function TestGroup:testGetGroupUnits_APIError()
    self.mockGroups["UnitsError"] = {
        isExist = function(self)
            return true
        end,
        getUnits = function(self)
            error("API error")
        end,
        getName = function(self)
            return "UnitsError"
        end,
    }
    local units = GetGroupUnits("UnitsError")
    lu.assertNil(units)
end

-- GetGroupSize tests
function TestGroup:testGetGroupSize_MultipleUnits()
    local size = GetGroupSize("Aerial-1")
    lu.assertEquals(size, 2)
end

function TestGroup:testGetGroupSize_SingleUnit()
    local size = GetGroupSize("Ground-1")
    lu.assertEquals(size, 1)
end

function TestGroup:testGetGroupSize_EmptyGroup()
    local size = GetGroupSize("Empty-1")
    lu.assertEquals(size, 0)
end

function TestGroup:testGetGroupSize_NonExistentGroup()
    local size = GetGroupSize("NonExistent")
    lu.assertEquals(size, 0)
end

function TestGroup:testGetGroupSize_APIError()
    self.mockGroups["SizeError"] = {
        isExist = function(self)
            return true
        end,
        getSize = function(self)
            error("API error")
        end,
        getName = function(self)
            return "SizeError"
        end,
    }
    local size = GetGroupSize("SizeError")
    lu.assertEquals(size, 0)
end

-- GetGroupInitialSize tests
function TestGroup:testGetGroupInitialSize_PartiallyDestroyed()
    local initialSize = GetGroupInitialSize("Aerial-1")
    lu.assertEquals(initialSize, 4) -- Started with 4, now has 2
end

function TestGroup:testGetGroupInitialSize_Intact()
    local initialSize = GetGroupInitialSize("Ground-1")
    lu.assertEquals(initialSize, 1)
end

function TestGroup:testGetGroupInitialSize_FullyDestroyed()
    local initialSize = GetGroupInitialSize("Empty-1")
    lu.assertEquals(initialSize, 3) -- Started with 3, now empty
end

function TestGroup:testGetGroupInitialSize_NonExistentGroup()
    local initialSize = GetGroupInitialSize("NonExistent")
    lu.assertEquals(initialSize, 0)
end

-- GetGroupCoalition tests
function TestGroup:testGetGroupCoalition_Blue()
    local coalition = GetGroupCoalition("Aerial-1")
    lu.assertEquals(coalition, 2)
end

function TestGroup:testGetGroupCoalition_Red()
    local coalition = GetGroupCoalition("Ground-1")
    lu.assertEquals(coalition, 1)
end

function TestGroup:testGetGroupCoalition_Neutral()
    local coalition = GetGroupCoalition("Empty-1")
    lu.assertEquals(coalition, 0)
end

function TestGroup:testGetGroupCoalition_NonExistentGroup()
    local coalition = GetGroupCoalition("NonExistent")
    lu.assertNil(coalition)
end

-- GetGroupCategory tests
function TestGroup:testGetGroupCategory_Airplane()
    local category = GetGroupCategory("Aerial-1")
    lu.assertEquals(category, 0) -- AIRPLANE
end

function TestGroup:testGetGroupCategory_Ground()
    local category = GetGroupCategory("Ground-1")
    lu.assertEquals(category, 2) -- GROUND
end

function TestGroup:testGetGroupCategory_Ship()
    local category = GetGroupCategory("Empty-1")
    lu.assertEquals(category, 3) -- SHIP
end

function TestGroup:testGetGroupCategory_Helicopter()
    self.mockGroups["Helo-1"] = {
        isExist = function(self)
            return true
        end,
        getCategory = function(self)
            return 1
        end, -- HELICOPTER
        getName = function(self)
            return "Helo-1"
        end,
    }
    local category = GetGroupCategory("Helo-1")
    lu.assertEquals(category, 1)
end

function TestGroup:testGetGroupCategory_Structure()
    self.mockGroups["Structure-1"] = {
        isExist = function(self)
            return true
        end,
        getCategory = function(self)
            return 4
        end, -- STRUCTURE
        getName = function(self)
            return "Structure-1"
        end,
    }
    local category = GetGroupCategory("Structure-1")
    lu.assertEquals(category, 4)
end

-- GetGroupID tests
function TestGroup:testGetGroupID_ValidGroups()
    local id1 = GetGroupID("Aerial-1")
    lu.assertEquals(id1, 101)

    local id2 = GetGroupID("Ground-1")
    lu.assertEquals(id2, 201)

    local id3 = GetGroupID("Empty-1")
    lu.assertEquals(id3, 301)
end

function TestGroup:testGetGroupID_NonExistentGroup()
    local id = GetGroupID("NonExistent")
    lu.assertNil(id)
end

-- GetGroupController tests
function TestGroup:testGetGroupController_ValidGroup()
    local controller = GetGroupController("Aerial-1")
    lu.assertNotNil(controller)
    lu.assertEquals(controller.type, "AI")
end

function TestGroup:testGetGroupController_NonExistentGroup()
    local controller = GetGroupController("NonExistent")
    lu.assertNil(controller)
end

function TestGroup:testGetGroupController_APIError()
    self.mockGroups["ControllerError"] = {
        isExist = function(self)
            return true
        end,
        getController = function(self)
            error("API error")
        end,
        getName = function(self)
            return "ControllerError"
        end,
    }
    local controller = GetGroupController("ControllerError")
    lu.assertNil(controller)
end

-- MessageToGroup tests
function TestGroup:testMessageToGroup_ValidMessage()
    local success = MessageToGroup(101, "Hello group", 15)
    lu.assertTrue(success)
    lu.assertEquals(#self.messagesSent, 1)
    lu.assertEquals(self.messagesSent[1].type, "group")
    lu.assertEquals(self.messagesSent[1].groupId, 101)
    lu.assertEquals(self.messagesSent[1].message, "Hello group")
    lu.assertEquals(self.messagesSent[1].duration, 15)
end

function TestGroup:testMessageToGroup_DefaultDuration()
    local success = MessageToGroup(101, "Test message")
    lu.assertTrue(success)
    lu.assertEquals(self.messagesSent[1].duration, 20) -- Default
end

function TestGroup:testMessageToGroup_InvalidGroupId()
    local success = MessageToGroup(nil, "Test message")
    lu.assertFalse(success)
    lu.assertEquals(#self.messagesSent, 0)
end

function TestGroup:testMessageToGroup_InvalidMessage()
    local success = MessageToGroup(101, nil)
    lu.assertFalse(success)
    lu.assertEquals(#self.messagesSent, 0)
end

function TestGroup:testMessageToGroup_NumericMessage()
    local success = MessageToGroup(101, 12345)
    lu.assertFalse(success)
    lu.assertEquals(#self.messagesSent, 0)
end

function TestGroup:testMessageToGroup_APIError()
    trigger.action.outTextForGroup = function(groupId, message, duration, clear)
        error("API error")
    end
    local success = MessageToGroup(101, "Test message")
    lu.assertFalse(success)
end

-- MessageToCoalition tests
function TestGroup:testMessageToCoalition_Blue()
    local success = MessageToCoalition(2, "Hello blues", 10)
    lu.assertTrue(success)
    lu.assertEquals(#self.messagesSent, 1)
    lu.assertEquals(self.messagesSent[1].type, "coalition")
    lu.assertEquals(self.messagesSent[1].coalitionId, 2)
    lu.assertEquals(self.messagesSent[1].message, "Hello blues")
    lu.assertEquals(self.messagesSent[1].duration, 10)
end

function TestGroup:testMessageToCoalition_Red()
    local success = MessageToCoalition(1, "Hello reds")
    lu.assertTrue(success)
    lu.assertEquals(self.messagesSent[1].coalitionId, 1)
    lu.assertEquals(self.messagesSent[1].duration, 20) -- Default
end

function TestGroup:testMessageToCoalition_Neutral()
    local success = MessageToCoalition(0, "Hello neutrals", 5)
    lu.assertTrue(success)
    lu.assertEquals(self.messagesSent[1].coalitionId, 0)
end

function TestGroup:testMessageToCoalition_InvalidCoalitionId()
    local success = MessageToCoalition("not a number", "Test")
    lu.assertFalse(success)
end

function TestGroup:testMessageToCoalition_APIError()
    trigger.action.outTextForCoalition = function(coalitionId, message, duration)
        error("API error")
    end
    local success = MessageToCoalition(2, "Test message")
    lu.assertFalse(success)
end

-- MessageToAll tests
function TestGroup:testMessageToAll_ValidMessage()
    local success = MessageToAll("Global message", 30)
    lu.assertTrue(success)
    lu.assertEquals(#self.messagesSent, 1)
    lu.assertEquals(self.messagesSent[1].type, "all")
    lu.assertEquals(self.messagesSent[1].message, "Global message")
    lu.assertEquals(self.messagesSent[1].duration, 30)
end

function TestGroup:testMessageToAll_DefaultDuration()
    local success = MessageToAll("Test message")
    lu.assertTrue(success)
    lu.assertEquals(self.messagesSent[1].duration, 20)
end

function TestGroup:testMessageToAll_EmptyMessage()
    local success = MessageToAll("")
    lu.assertTrue(success) -- Empty string is still valid
end

function TestGroup:testMessageToAll_InvalidMessage()
    local success = MessageToAll(nil)
    lu.assertFalse(success)
end

function TestGroup:testMessageToAll_APIError()
    trigger.action.outText = function(message, duration)
        error("API error")
    end
    local success = MessageToAll("Test message")
    lu.assertFalse(success)
end

-- ActivateGroup tests
function TestGroup:testActivateGroup_ValidGroup()
    local success = ActivateGroup("Aerial-1")
    lu.assertTrue(success)
end

function TestGroup:testActivateGroup_AlreadyActive()
    local success = ActivateGroup("Ground-1")
    lu.assertTrue(success)
end

function TestGroup:testActivateGroup_NonExistentGroup()
    local success = ActivateGroup("NonExistent")
    lu.assertFalse(success)
end

function TestGroup:testActivateGroup_APIError()
    self.mockGroups["ActivateError"] = {
        isExist = function(self)
            return true
        end,
        activate = function(self)
            error("API error")
        end,
        getName = function(self)
            return "ActivateError"
        end,
    }
    local success = ActivateGroup("ActivateError")
    lu.assertFalse(success)
end

-- GetCoalitionGroups tests
function TestGroup:testGetCoalitionGroups_ValidCoalition()
    -- Mock coalition.getGroups
    coalition.getGroups = function(coalitionId, categoryId)
        if coalitionId == 2 and categoryId == 0 then
            return { self.mockGroups["Aerial-1"] }
        elseif coalitionId == 1 and categoryId == 2 then
            return { self.mockGroups["Ground-1"] }
        else
            return {}
        end
    end

    local blueAir = GetCoalitionGroups(2, 0)
    lu.assertEquals(#blueAir, 1)
    lu.assertEquals(blueAir[1]:getName(), "Aerial-1")

    local redGround = GetCoalitionGroups(1, 2)
    lu.assertEquals(#redGround, 1)
    lu.assertEquals(redGround[1]:getName(), "Ground-1")
end

function TestGroup:testGetCoalitionGroups_AllCategories()
    coalition.getGroups = function(coalitionId, categoryId)
        if coalitionId == 2 and not categoryId then
            return { self.mockGroups["Aerial-1"], self.mockGroups["Empty-1"] }
        else
            return {}
        end
    end

    local blueAll = GetCoalitionGroups(2)
    lu.assertEquals(#blueAll, 2)
end

function TestGroup:testGetCoalitionGroups_EmptyResult()
    coalition.getGroups = function(coalitionId, categoryId)
        return nil
    end

    local groups = GetCoalitionGroups(2, 0)
    lu.assertNotNil(groups)
    lu.assertEquals(#groups, 0)
end

function TestGroup:testGetCoalitionGroups_InvalidCoalition()
    -- Ensure GetCoalitionGroups is loaded
    lu.assertNotNil(GetCoalitionGroups, "GetCoalitionGroups function should exist")

    -- Direct call without pcall to see what happens
    local groups = GetCoalitionGroups(nil, 0)

    -- Test with nil coalition ID
    lu.assertNotNil(groups, "GetCoalitionGroups should return a table, not nil")
    lu.assertEquals(type(groups), "table", "GetCoalitionGroups should return a table")
    lu.assertEquals(#groups, 0)
end

function TestGroup:testGetCoalitionGroups_InvalidType()
    local groups = GetCoalitionGroups("not a number", 0)
    lu.assertNotNil(groups, "GetCoalitionGroups should return a table, not nil")
    lu.assertEquals(type(groups), "table", "GetCoalitionGroups should return a table")
    lu.assertEquals(#groups, 0)
end

function TestGroup:testGetCoalitionGroups_APIError()
    coalition.getGroups = function(coalitionId, categoryId)
        error("API error")
    end

    local groups = GetCoalitionGroups(2, 0)
    lu.assertEquals(#groups, 0)
end

-- Edge cases
function TestGroup:testGroup_VeryLongName()
    local longName = string.rep("a", 1000)
    self.mockGroups[longName] = {
        isExist = function(self)
            return true
        end,
        getID = function(self)
            return 999
        end,
        getName = function(self)
            return longName
        end,
    }
    local id = GetGroupID(longName)
    lu.assertEquals(id, 999)
end

function TestGroup:testGroup_SpecialCharactersInName()
    local specialName = "Group-123_Test!@#"
    self.mockGroups[specialName] = {
        isExist = function(self)
            return true
        end,
        getSize = function(self)
            return 5
        end,
        getName = function(self)
            return specialName
        end,
    }
    local size = GetGroupSize(specialName)
    lu.assertEquals(size, 5)
end

function TestGroup:testGroup_VeryLargeGroup()
    local units = {}
    for i = 1, 100 do
        table.insert(units, {
            isExist = function(self)
                return true
            end,
            getName = function(self)
                return "Unit-" .. i
            end,
        })
    end

    self.mockGroups["LargeGroup"] = {
        isExist = function(self)
            return true
        end,
        getUnits = function(self)
            return units
        end,
        getSize = function(self)
            return 100
        end,
        getInitialSize = function(self)
            return 100
        end,
        getName = function(self)
            return "LargeGroup"
        end,
    }

    local groupUnits = GetGroupUnits("LargeGroup")
    lu.assertEquals(#groupUnits, 100)

    local size = GetGroupSize("LargeGroup")
    lu.assertEquals(size, 100)
end

function TestGroup:testMessage_VeryLongMessage()
    local longMessage = string.rep("This is a very long message. ", 1000)
    local success = MessageToAll(longMessage, 5)
    lu.assertTrue(success)
    lu.assertEquals(self.messagesSent[1].message, longMessage)
end

function TestGroup:testMessage_SpecialCharacters()
    local message = "Test\nNew Line\tTab\"Quote'Apostrophe\\Backslash"
    local success = MessageToAll(message)
    lu.assertTrue(success)
    lu.assertEquals(self.messagesSent[1].message, message)
end

function TestGroup:testMessage_UnicodeCharacters()
    local message = "Привет мир! 你好世界! مرحبا بالعالم!"
    local success = MessageToAll(message)
    lu.assertTrue(success)
    lu.assertEquals(self.messagesSent[1].message, message)
end

return TestGroup
