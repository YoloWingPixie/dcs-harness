-- Unit tests for logger.lua module
local lu = require('luaunit')
require('test_utils')

-- Setup test environment
package.path = package.path .. ';../src/?.lua'

-- Create isolated test suite
TestLogger = CreateIsolatedTestSuite('TestLogger', {})

function TestLogger:setUp()
    -- Load required modules
    require('mock_dcs')
    require('_header')
    
    -- Ensure _HarnessInternal has required fields before loading logger
    if not _HarnessInternal.loggers then
        _HarnessInternal.loggers = {}
    end
    if not _HarnessInternal.defaultNamespace then
        _HarnessInternal.defaultNamespace = "Harness"
    end
    
    require('logger')
    
    -- Ensure internal logger is created
    if not _HarnessInternal.log then
        _HarnessInternal.log = HarnessLogger("Harness")
    end
    
    -- Capture log messages
    self.capturedLogs = {
        info = {},
        warn = {},
        error = {}
    }
    
    -- Save original Log global
    self.originalLog = Log
    
    -- Mock DCS env functions to capture output
    self.originalEnv = {
        info = env.info,
        warning = env.warning,
        error = env.error
    }
    
    env.info = function(msg)
        table.insert(self.capturedLogs.info, msg)
    end
    
    env.warning = function(msg)
        table.insert(self.capturedLogs.warn, msg)
    end
    
    env.error = function(msg)
        table.insert(self.capturedLogs.error, msg)
    end
end

function TestLogger:tearDown()
    -- Restore original env functions
    env.info = self.originalEnv.info
    env.warning = self.originalEnv.warning
    env.error = self.originalEnv.error
    
    -- Restore original Log global
    Log = self.originalLog
end

-- Test logger creation with default namespace
function TestLogger:testCreateLoggerDefault()
    local logger = HarnessLogger()
    
    lu.assertNotNil(logger)
    lu.assertEquals(logger.namespace, "Harness")
    lu.assertIsFunction(logger.info)
    lu.assertIsFunction(logger.warn)
    lu.assertIsFunction(logger.error)
    lu.assertIsFunction(logger.debug)
end

-- Test logger creation with custom namespace
function TestLogger:testCreateLoggerCustomNamespace()
    local logger = HarnessLogger("MyMod")
    
    lu.assertNotNil(logger)
    lu.assertEquals(logger.namespace, "MyMod")
end

-- Test logger creation with invalid namespace
function TestLogger:testCreateLoggerInvalidNamespace()
    -- Non-string namespaces should default to "Harness"
    local logger1 = HarnessLogger(123)
    lu.assertEquals(logger1.namespace, "Harness")
    
    local logger2 = HarnessLogger(nil)
    lu.assertEquals(logger2.namespace, "Harness")
    
    local logger3 = HarnessLogger({})
    lu.assertEquals(logger3.namespace, "Harness")
end

-- Test logger caching
function TestLogger:testLoggerCaching()
    local logger1 = HarnessLogger("TestMod")
    local logger2 = HarnessLogger("TestMod")
    
    -- Should return same instance
    lu.assertIs(logger1, logger2)
    
    -- Different namespace should create new logger
    local logger3 = HarnessLogger("OtherMod")
    lu.assertNotIs(logger1, logger3)
end

-- Test info logging
function TestLogger:testInfoLogging()
    local logger = HarnessLogger("TestMod")
    
    -- Without caller
    logger.info("Test message")
    lu.assertEquals(#self.capturedLogs.info, 1)
    lu.assertEquals(self.capturedLogs.info[1], "[TestMod]: Test message")
    
    -- With caller
    logger.info("Another message", "TestFunction")
    lu.assertEquals(#self.capturedLogs.info, 2)
    lu.assertEquals(self.capturedLogs.info[2], "[TestMod : TestFunction]: Another message")
end

-- Test warning logging
function TestLogger:testWarnLogging()
    local logger = HarnessLogger("WarnTest")
    
    -- Without caller
    logger.warn("Warning message")
    lu.assertEquals(#self.capturedLogs.warn, 1)
    lu.assertEquals(self.capturedLogs.warn[1], "[WarnTest]: Warning message")
    
    -- With caller
    logger.warn("Another warning", "WarnFunc")
    lu.assertEquals(#self.capturedLogs.warn, 2)
    lu.assertEquals(self.capturedLogs.warn[2], "[WarnTest : WarnFunc]: Another warning")
end

-- Test error logging
function TestLogger:testErrorLogging()
    local logger = HarnessLogger("ErrorTest")
    
    -- Without caller
    logger.error("Error message")
    lu.assertEquals(#self.capturedLogs.error, 1)
    lu.assertEquals(self.capturedLogs.error[1], "[ErrorTest]: Error message")
    
    -- With caller
    logger.error("Critical error", "ErrorFunc")
    lu.assertEquals(#self.capturedLogs.error, 2)
    lu.assertEquals(self.capturedLogs.error[2], "[ErrorTest : ErrorFunc]: Critical error")
end

-- Test debug logging
function TestLogger:testDebugLogging()
    local logger = HarnessLogger("DebugTest")
    
    -- Debug uses info channel with DEBUG prefix
    logger.debug("Debug message")
    lu.assertEquals(#self.capturedLogs.info, 1)
    lu.assertEquals(self.capturedLogs.info[1], "[DebugTest : DEBUG]: Debug message")
    
    -- With caller
    logger.debug("Debug info", "DebugFunc")
    lu.assertEquals(#self.capturedLogs.info, 2)
    lu.assertEquals(self.capturedLogs.info[2], "[DebugTest : DEBUG : DebugFunc]: Debug info")
end

-- Test multiple loggers
function TestLogger:testMultipleLoggers()
    local logger1 = HarnessLogger("Mod1")
    local logger2 = HarnessLogger("Mod2")
    local logger3 = HarnessLogger("Mod3")
    
    logger1.info("Message from Mod1")
    logger2.info("Message from Mod2")
    logger3.info("Message from Mod3")
    logger1.info("Another from Mod1")
    
    lu.assertEquals(#self.capturedLogs.info, 4)
    lu.assertStrContains(self.capturedLogs.info[1], "[Mod1]:")
    lu.assertStrContains(self.capturedLogs.info[2], "[Mod2]:")
    lu.assertStrContains(self.capturedLogs.info[3], "[Mod3]:")
    lu.assertStrContains(self.capturedLogs.info[4], "[Mod1]:")
end

-- Test internal logger
function TestLogger:testInternalLogger()
    -- Internal logger should exist
    lu.assertNotNil(_HarnessInternal.log)
    lu.assertEquals(_HarnessInternal.log.namespace, "Harness")
    
    -- Test it works
    _HarnessInternal.log.info("Internal message")
    lu.assertEquals(#self.capturedLogs.info, 1)
    lu.assertEquals(self.capturedLogs.info[1], "[Harness]: Internal message")
end

-- Test global Log object
function TestLogger:testGlobalLog()
    -- Global Log should exist with default "Script" namespace
    lu.assertNotNil(Log)
    lu.assertEquals(Log.namespace, "Script")
    
    -- Test it works
    Log.info("Script message")
    lu.assertEquals(#self.capturedLogs.info, 1)
    lu.assertEquals(self.capturedLogs.info[1], "[Script]: Script message")
    
    -- Can be reassigned
    Log = HarnessLogger("MyProject")
    lu.assertEquals(Log.namespace, "MyProject")
    
    Log.info("Project message")
    lu.assertEquals(#self.capturedLogs.info, 2)
    lu.assertEquals(self.capturedLogs.info[2], "[MyProject]: Project message")
end

-- Test message formatting edge cases
function TestLogger:testMessageFormatting()
    local logger = HarnessLogger("FormatTest")
    
    -- Empty message
    logger.info("")
    lu.assertEquals(self.capturedLogs.info[1], "[FormatTest]: ")
    
    -- Message with special characters
    logger.info("Message with : colons : and [brackets]")
    lu.assertStrContains(self.capturedLogs.info[2], "Message with : colons : and [brackets]")
    
    -- Very long namespace
    local longLogger = HarnessLogger("VeryLongNamespaceNameThatGoesOnAndOn")
    longLogger.info("Test")
    lu.assertStrContains(self.capturedLogs.info[3], "[VeryLongNamespaceNameThatGoesOnAndOn]:")
    
    -- Empty caller
    logger.info("Message", "")
    lu.assertEquals(self.capturedLogs.info[4], "[FormatTest : ]: Message")
end

-- Test logger storage
function TestLogger:testLoggerStorage()
    -- Create several loggers
    HarnessLogger("Logger1")
    HarnessLogger("Logger2")
    HarnessLogger("Logger3")
    
    -- Check they're stored
    lu.assertNotNil(_HarnessInternal.loggers["Logger1"])
    lu.assertNotNil(_HarnessInternal.loggers["Logger2"])
    lu.assertNotNil(_HarnessInternal.loggers["Logger3"])
    
    -- Check count
    local count = 0
    for _ in pairs(_HarnessInternal.loggers) do
        count = count + 1
    end
    -- Should have at least these 3 (plus any created by other tests/initialization)
    lu.assertTrue(count >= 3)
end

-- Test concurrent usage
function TestLogger:testConcurrentUsage()
    local logger1 = HarnessLogger("Concurrent1")
    local logger2 = HarnessLogger("Concurrent2")
    
    -- Interleaved logging
    logger1.info("A")
    logger2.warn("B")
    logger1.error("C")
    logger2.debug("D")
    logger1.info("E", "Func1")
    logger2.info("F", "Func2")
    
    -- Check all messages were logged correctly
    lu.assertEquals(#self.capturedLogs.info, 4)  -- A, D (debug as info), E, F
    lu.assertEquals(#self.capturedLogs.warn, 1)
    lu.assertEquals(#self.capturedLogs.error, 1)
    
    lu.assertStrContains(self.capturedLogs.info[1], "[Concurrent1]: A")
    lu.assertStrContains(self.capturedLogs.warn[1], "[Concurrent2]: B")
    lu.assertStrContains(self.capturedLogs.error[1], "[Concurrent1]: C")
    lu.assertStrContains(self.capturedLogs.info[2], "[Concurrent2 : DEBUG]: D")
    lu.assertStrContains(self.capturedLogs.info[3], "[Concurrent1 : Func1]: E")
    lu.assertStrContains(self.capturedLogs.info[4], "[Concurrent2 : Func2]: F")
end

return TestLogger