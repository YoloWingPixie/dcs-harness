-- test_flag.lua
local lu = require('luaunit')

-- Setup test environment
package.path = package.path .. ';../src/?.lua'
require('mock_dcs')
require('_header')
require('logger')
require('flag')

TestFlag = {}

function TestFlag:setUp()
    -- Reset mock behavior before each test
    self.original_getUserFlag = trigger.misc.getUserFlag
    self.original_setUserFlag = trigger.action.setUserFlag
    
    -- Mock flag storage
    self.flagStorage = {}
    
    -- Override mock functions to use storage
    trigger.misc.getUserFlag = function(flagName)
        return self.flagStorage[flagName] or 0
    end
    
    trigger.action.setUserFlag = function(flagName, value)
        self.flagStorage[flagName] = value
        return true
    end
end

function TestFlag:tearDown()
    -- Restore original mocks
    trigger.misc.getUserFlag = self.original_getUserFlag
    trigger.action.setUserFlag = self.original_setUserFlag
end

-- GetFlag tests
function TestFlag:testGetFlag_ValidFlag()
    self.flagStorage["testFlag"] = 42
    local value = GetFlag("testFlag")
    lu.assertEquals(value, 42)
end

function TestFlag:testGetFlag_NonExistentFlag()
    local value = GetFlag("nonExistent")
    lu.assertEquals(value, 0)
end

function TestFlag:testGetFlag_NilName()
    local value = GetFlag(nil)
    lu.assertEquals(value, 0)
end

function TestFlag:testGetFlag_EmptyString()
    local value = GetFlag("")
    lu.assertEquals(value, 0)
end

function TestFlag:testGetFlag_APIError()
    trigger.misc.getUserFlag = function(flagName)
        error("API error")
    end
    local value = GetFlag("testFlag")
    lu.assertEquals(value, 0)
end

-- SetFlag tests
function TestFlag:testSetFlag_ValidValues()
    local success = SetFlag("testFlag", 100)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["testFlag"], 100)
end

function TestFlag:testSetFlag_DefaultValue()
    local success = SetFlag("testFlag")
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["testFlag"], 1)
end

function TestFlag:testSetFlag_ZeroValue()
    local success = SetFlag("testFlag", 0)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["testFlag"], 0)
end

function TestFlag:testSetFlag_NegativeValue()
    local success = SetFlag("testFlag", -50)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["testFlag"], -50)
end

function TestFlag:testSetFlag_NilName()
    local success = SetFlag(nil, 10)
    lu.assertFalse(success)
end

function TestFlag:testSetFlag_APIError()
    trigger.action.setUserFlag = function(flagName, value)
        error("API error")
    end
    local success = SetFlag("testFlag", 10)
    lu.assertFalse(success)
end

-- IncFlag tests
function TestFlag:testIncFlag_DefaultIncrement()
    self.flagStorage["counter"] = 5
    local success = IncFlag("counter")
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["counter"], 6)
end

function TestFlag:testIncFlag_CustomIncrement()
    self.flagStorage["counter"] = 10
    local success = IncFlag("counter", 5)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["counter"], 15)
end

function TestFlag:testIncFlag_NegativeIncrement()
    self.flagStorage["counter"] = 10
    local success = IncFlag("counter", -3)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["counter"], 7)
end

function TestFlag:testIncFlag_NonExistentFlag()
    local success = IncFlag("newCounter", 5)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["newCounter"], 5)
end

-- DecFlag tests
function TestFlag:testDecFlag_DefaultDecrement()
    self.flagStorage["counter"] = 10
    local success = DecFlag("counter")
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["counter"], 9)
end

function TestFlag:testDecFlag_CustomDecrement()
    self.flagStorage["counter"] = 20
    local success = DecFlag("counter", 5)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["counter"], 15)
end

function TestFlag:testDecFlag_ResultingNegative()
    self.flagStorage["counter"] = 5
    local success = DecFlag("counter", 10)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["counter"], -5)
end

-- ToggleFlag tests
function TestFlag:testToggleFlag_FromZero()
    self.flagStorage["switch"] = 0
    local success = ToggleFlag("switch")
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["switch"], 1)
end

function TestFlag:testToggleFlag_FromOne()
    self.flagStorage["switch"] = 1
    local success = ToggleFlag("switch")
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["switch"], 0)
end

function TestFlag:testToggleFlag_FromNonZero()
    self.flagStorage["switch"] = 42
    local success = ToggleFlag("switch")
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["switch"], 0)
end

-- Boolean flag tests
function TestFlag:testIsFlagTrue_Zero()
    self.flagStorage["flag"] = 0
    lu.assertFalse(IsFlagTrue("flag"))
end

function TestFlag:testIsFlagTrue_One()
    self.flagStorage["flag"] = 1
    lu.assertTrue(IsFlagTrue("flag"))
end

function TestFlag:testIsFlagTrue_NonZero()
    self.flagStorage["flag"] = -5
    lu.assertTrue(IsFlagTrue("flag"))
end

function TestFlag:testIsFlagFalse_Zero()
    self.flagStorage["flag"] = 0
    lu.assertTrue(IsFlagFalse("flag"))
end

function TestFlag:testIsFlagFalse_NonZero()
    self.flagStorage["flag"] = 1
    lu.assertFalse(IsFlagFalse("flag"))
end

-- Comparison tests
function TestFlag:testFlagEquals()
    self.flagStorage["state"] = 3
    lu.assertTrue(FlagEquals("state", 3))
    lu.assertFalse(FlagEquals("state", 4))
end

function TestFlag:testFlagGreaterThan()
    self.flagStorage["score"] = 150
    lu.assertTrue(FlagGreaterThan("score", 100))
    lu.assertFalse(FlagGreaterThan("score", 200))
    lu.assertFalse(FlagGreaterThan("score", 150))
end

function TestFlag:testFlagLessThan()
    self.flagStorage["health"] = 20
    lu.assertTrue(FlagLessThan("health", 50))
    lu.assertFalse(FlagLessThan("health", 10))
    lu.assertFalse(FlagLessThan("health", 20))
end

function TestFlag:testFlagBetween_Inclusive()
    self.flagStorage["temp"] = 25
    lu.assertTrue(FlagBetween("temp", 20, 30))
    lu.assertTrue(FlagBetween("temp", 25, 30))
    lu.assertTrue(FlagBetween("temp", 20, 25))
    lu.assertFalse(FlagBetween("temp", 26, 30))
    lu.assertFalse(FlagBetween("temp", 10, 24))
end

-- Multiple flag operations
function TestFlag:testSetFlags_ValidTable()
    local flags = {
        flag1 = 10,
        flag2 = 20,
        flag3 = 0
    }
    local success = SetFlags(flags)
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["flag1"], 10)
    lu.assertEquals(self.flagStorage["flag2"], 20)
    lu.assertEquals(self.flagStorage["flag3"], 0)
end

function TestFlag:testSetFlags_EmptyTable()
    local success = SetFlags({})
    lu.assertTrue(success)
end

function TestFlag:testSetFlags_InvalidInput()
    local success = SetFlags("not a table")
    lu.assertFalse(success)
end

function TestFlag:testSetFlags_PartialFailure()
    local callCount = 0
    trigger.action.setUserFlag = function(flagName, value)
        callCount = callCount + 1
        if callCount == 2 then
            error("API error on second flag")
        end
        self.flagStorage[flagName] = value
        return true
    end
    
    local flags = {flag1 = 10, flag2 = 20, flag3 = 30}
    local success = SetFlags(flags)
    lu.assertFalse(success)  -- Overall failure
    -- First flag should be set
    lu.assertTrue(self.flagStorage["flag1"] == 10 or self.flagStorage["flag3"] == 30)
end

function TestFlag:testGetFlags_ValidArray()
    self.flagStorage["flag1"] = 10
    self.flagStorage["flag2"] = 20
    self.flagStorage["flag3"] = 0
    
    local values = GetFlags({"flag1", "flag2", "flag3", "nonExistent"})
    lu.assertEquals(values["flag1"], 10)
    lu.assertEquals(values["flag2"], 20)
    lu.assertEquals(values["flag3"], 0)
    lu.assertEquals(values["nonExistent"], 0)
end

function TestFlag:testGetFlags_EmptyArray()
    local values = GetFlags({})
    lu.assertEquals(type(values), "table")
    lu.assertEquals(next(values), nil)  -- Empty table
end

function TestFlag:testGetFlags_InvalidInput()
    local values = GetFlags("not a table")
    lu.assertEquals(type(values), "table")
    lu.assertEquals(next(values), nil)  -- Empty table
end

-- Clear flag operations
function TestFlag:testClearFlag()
    self.flagStorage["flag"] = 42
    local success = ClearFlag("flag")
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["flag"], 0)
end

function TestFlag:testClearFlags_ValidArray()
    self.flagStorage["flag1"] = 10
    self.flagStorage["flag2"] = 20
    self.flagStorage["flag3"] = 30
    
    local success = ClearFlags({"flag1", "flag2", "flag3"})
    lu.assertTrue(success)
    lu.assertEquals(self.flagStorage["flag1"], 0)
    lu.assertEquals(self.flagStorage["flag2"], 0)
    lu.assertEquals(self.flagStorage["flag3"], 0)
end

function TestFlag:testClearFlags_EmptyArray()
    local success = ClearFlags({})
    lu.assertTrue(success)
end

function TestFlag:testClearFlags_InvalidInput()
    local success = ClearFlags("not a table")
    lu.assertFalse(success)
end

function TestFlag:testClearFlags_PartialFailure()
    local callCount = 0
    trigger.action.setUserFlag = function(flagName, value)
        callCount = callCount + 1
        if callCount == 2 then
            error("API error on second flag")
        end
        self.flagStorage[flagName] = value
        return true
    end
    
    local success = ClearFlags({"flag1", "flag2", "flag3"})
    lu.assertFalse(success)  -- Overall failure
end

-- Edge cases
function TestFlag:testFlagOperations_SpecialCharacters()
    local flagName = "flag-with.special_chars!@#"
    local success = SetFlag(flagName, 123)
    lu.assertTrue(success)
    lu.assertEquals(GetFlag(flagName), 123)
end

function TestFlag:testFlagOperations_VeryLongName()
    local flagName = string.rep("a", 1000)
    local success = SetFlag(flagName, 999)
    lu.assertTrue(success)
    lu.assertEquals(GetFlag(flagName), 999)
end

function TestFlag:testFlagOperations_NumericStringName()
    local success = SetFlag("12345", 67)
    lu.assertTrue(success)
    lu.assertEquals(GetFlag("12345"), 67)
end

return TestFlag