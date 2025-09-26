-- Unit tests for time.lua module
local lu = require("luaunit")
require("test_utils")

-- Setup test environment
package.path = package.path .. ";../src/?.lua"

-- Create isolated test suite
TestTime = CreateIsolatedTestSuite("TestTime", {})

function TestTime:setUp()
    -- Load required modules
    require("mock_dcs")
    require("_header")

    -- Ensure _HarnessInternal has required fields before loading logger
    if not _HarnessInternal.loggers then
        _HarnessInternal.loggers = {}
    end
    if not _HarnessInternal.defaultNamespace then
        _HarnessInternal.defaultNamespace = "Harness"
    end

    require("logger")

    -- Ensure internal logger is created
    if not _HarnessInternal.log then
        _HarnessInternal.log = HarnessLogger("Harness")
    end

    require("time")
    -- Store original timer functions
    self.originalTimer = {
        getTime = timer.getTime,
        getAbsTime = timer.getAbsTime,
        getTime0 = timer.getTime0,
        scheduleFunction = timer.scheduleFunction,
        removeFunction = timer.removeFunction,
        setFunctionTime = timer.setFunctionTime,
    }

    -- Set up predictable time values
    self.currentTime = 1000.0
    self.absTime = 50000.0 -- 13:53:20
    self.time0 = 43200.0 -- 12:00:00 (noon)

    timer.getTime = function()
        return self.currentTime
    end
    timer.getAbsTime = function()
        return self.absTime
    end
    timer.getTime0 = function()
        return self.time0
    end
end

function TestTime:tearDown()
    -- Restore original timer functions
    timer.getTime = self.originalTimer.getTime
    timer.getAbsTime = self.originalTimer.getAbsTime
    timer.getTime0 = self.originalTimer.getTime0
    timer.scheduleFunction = self.originalTimer.scheduleFunction
    timer.removeFunction = self.originalTimer.removeFunction
    timer.setFunctionTime = self.originalTimer.setFunctionTime
end

-- Test GetTime
function TestTime:testGetTime()
    lu.assertEquals(GetTime(), 1000.0)

    -- Change time and test again
    self.currentTime = 2500.5
    lu.assertEquals(GetTime(), 2500.5)
end

-- Test GetAbsTime
function TestTime:testGetAbsTime()
    lu.assertEquals(GetAbsTime(), 50000.0)

    -- Change time and test again
    self.absTime = 65000.0
    lu.assertEquals(GetAbsTime(), 65000.0)
end

-- Test GetTime0
function TestTime:testGetTime0()
    lu.assertEquals(GetTime0(), 43200.0)

    -- Change time and test again
    self.time0 = 0.0
    lu.assertEquals(GetTime0(), 0.0)
end

-- Test FormatTime
function TestTime:testFormatTime()
    -- Basic cases
    lu.assertEquals(FormatTime(0), "00:00:00")
    lu.assertEquals(FormatTime(1), "00:00:01")
    lu.assertEquals(FormatTime(60), "00:01:00")
    lu.assertEquals(FormatTime(3600), "01:00:00")

    -- Complex time
    lu.assertEquals(FormatTime(3661), "01:01:01")
    lu.assertEquals(FormatTime(3723), "01:02:03")
    lu.assertEquals(FormatTime(45296), "12:34:56")

    -- Large values
    lu.assertEquals(FormatTime(86400), "24:00:00") -- 24 hours
    lu.assertEquals(FormatTime(90061), "25:01:01") -- Over 24 hours

    -- Decimal seconds (should be floored)
    lu.assertEquals(FormatTime(3661.9), "01:01:01")

    -- Invalid input
    lu.assertEquals(FormatTime("not a number"), "00:00:00")
    lu.assertEquals(FormatTime(nil), "00:00:00")
end

-- Test FormatTimeShort
function TestTime:testFormatTimeShort()
    -- Basic cases
    lu.assertEquals(FormatTimeShort(0), "00:00")
    lu.assertEquals(FormatTimeShort(1), "00:01")
    lu.assertEquals(FormatTimeShort(60), "01:00")
    lu.assertEquals(FormatTimeShort(3600), "60:00") -- 60 minutes

    -- Complex time
    lu.assertEquals(FormatTimeShort(125), "02:05")
    lu.assertEquals(FormatTimeShort(3665), "61:05")

    -- Invalid input
    lu.assertEquals(FormatTimeShort("not a number"), "00:00")
    lu.assertEquals(FormatTimeShort(nil), "00:00")
end

-- Test GetMissionTime
function TestTime:testGetMissionTime()
    -- Test with 50000 seconds (13:53:20)
    local missionTime = GetMissionTime()
    lu.assertEquals(missionTime.hours, 13)
    lu.assertEquals(missionTime.minutes, 53)
    lu.assertEquals(missionTime.seconds, 20)

    -- Test with different time
    self.absTime = 45296 -- 12:34:56
    missionTime = GetMissionTime()
    lu.assertEquals(missionTime.hours, 12)
    lu.assertEquals(missionTime.minutes, 34)
    lu.assertEquals(missionTime.seconds, 56)

    -- Test midnight
    self.absTime = 0
    missionTime = GetMissionTime()
    lu.assertEquals(missionTime.hours, 0)
    lu.assertEquals(missionTime.minutes, 0)
    lu.assertEquals(missionTime.seconds, 0)
end

-- Test IsNightTime
function TestTime:testIsNightTime()
    -- Test day times (7:00 - 18:59)
    self.absTime = 25200 -- 07:00
    lu.assertFalse(IsNightTime())

    self.absTime = 43200 -- 12:00
    lu.assertFalse(IsNightTime())

    self.absTime = 68399 -- 18:59:59
    lu.assertFalse(IsNightTime())

    -- Test night times (19:00 - 06:59)
    self.absTime = 68400 -- 19:00
    lu.assertTrue(IsNightTime())

    self.absTime = 0 -- 00:00
    lu.assertTrue(IsNightTime())

    self.absTime = 10800 -- 03:00
    lu.assertTrue(IsNightTime())

    self.absTime = 25199 -- 06:59:59
    lu.assertTrue(IsNightTime())

    -- Test edge cases
    self.absTime = 25200 -- 07:00:00 (first moment of day)
    lu.assertFalse(IsNightTime())

    self.absTime = 68400 -- 19:00:00 (first moment of night)
    lu.assertTrue(IsNightTime())
end

-- Test ScheduleOnce
function TestTime:testScheduleOnce()
    local functionCalled = false
    local functionArgs = nil
    local scheduledTime = nil

    -- Mock scheduleFunction
    timer.scheduleFunction = function(func, args, time)
        functionCalled = func
        functionArgs = args
        scheduledTime = time
        return 123 -- mock timer ID
    end

    -- Test basic scheduling
    local testFunc = function(args) end
    local timerId = ScheduleOnce(testFunc, { a = 1, b = 2 }, 10)

    lu.assertEquals(timerId, 123)
    lu.assertEquals(functionCalled, testFunc)
    lu.assertEquals(functionArgs, { a = 1, b = 2 })
    lu.assertEquals(scheduledTime, 1010) -- current time + delay

    -- Test with no delay
    timerId = ScheduleOnce(testFunc, nil, nil)
    lu.assertEquals(scheduledTime, 1000) -- current time

    -- Test invalid function
    lu.assertNil(ScheduleOnce("not a function", nil, 0))
    lu.assertNil(ScheduleOnce(nil, nil, 0))
end

-- Test CancelSchedule
function TestTime:testCancelSchedule()
    local removedTimerId = nil

    -- Mock removeFunction
    timer.removeFunction = function(timerId)
        removedTimerId = timerId
        return true
    end

    -- Test valid cancel
    lu.assertTrue(CancelSchedule(123))
    lu.assertEquals(removedTimerId, 123)

    -- Test nil timer ID
    lu.assertFalse(CancelSchedule(nil))

    -- Test with failure
    timer.removeFunction = function(timerId)
        error("Failed to remove")
    end
    lu.assertFalse(CancelSchedule(456))
end

-- Test RescheduleFunction
function TestTime:testRescheduleFunction()
    local rescheduledTimerId = nil
    local rescheduledTime = nil

    -- Mock setFunctionTime
    timer.setFunctionTime = function(timerId, newTime)
        rescheduledTimerId = timerId
        rescheduledTime = newTime
        return true
    end

    -- Test valid reschedule
    lu.assertTrue(RescheduleFunction(123, 2000))
    lu.assertEquals(rescheduledTimerId, 123)
    lu.assertEquals(rescheduledTime, 2000)

    -- Test invalid inputs
    lu.assertFalse(RescheduleFunction(nil, 2000))
    lu.assertFalse(RescheduleFunction(123, "not a number"))
    lu.assertFalse(RescheduleFunction(nil, nil))
end

-- Test SecondsToTime
function TestTime:testSecondsToTime()
    -- Basic conversions
    local time = SecondsToTime(0)
    lu.assertEquals(time.hours, 0)
    lu.assertEquals(time.minutes, 0)
    lu.assertEquals(time.seconds, 0)

    time = SecondsToTime(3661)
    lu.assertEquals(time.hours, 1)
    lu.assertEquals(time.minutes, 1)
    lu.assertEquals(time.seconds, 1)

    time = SecondsToTime(45296)
    lu.assertEquals(time.hours, 12)
    lu.assertEquals(time.minutes, 34)
    lu.assertEquals(time.seconds, 56)

    -- Large values
    time = SecondsToTime(90061)
    lu.assertEquals(time.hours, 25)
    lu.assertEquals(time.minutes, 1)
    lu.assertEquals(time.seconds, 1)

    -- Decimal values (should be floored)
    time = SecondsToTime(3661.9)
    lu.assertEquals(time.hours, 1)
    lu.assertEquals(time.minutes, 1)
    lu.assertEquals(time.seconds, 1)

    -- Invalid input
    time = SecondsToTime("not a number")
    lu.assertEquals(time.hours, 0)
    lu.assertEquals(time.minutes, 0)
    lu.assertEquals(time.seconds, 0)
end

-- Test TimeToSeconds
function TestTime:testTimeToSeconds()
    -- Basic conversions
    lu.assertEquals(TimeToSeconds(0, 0, 0), 0)
    lu.assertEquals(TimeToSeconds(1, 0, 0), 3600)
    lu.assertEquals(TimeToSeconds(0, 1, 0), 60)
    lu.assertEquals(TimeToSeconds(0, 0, 1), 1)
    lu.assertEquals(TimeToSeconds(1, 1, 1), 3661)
    lu.assertEquals(TimeToSeconds(12, 34, 56), 45296)

    -- Default values
    lu.assertEquals(TimeToSeconds(), 0)
    lu.assertEquals(TimeToSeconds(1), 3600)
    lu.assertEquals(TimeToSeconds(nil, 30), 1800)
    lu.assertEquals(TimeToSeconds(nil, nil, 45), 45)

    -- Invalid inputs
    lu.assertEquals(TimeToSeconds("not", "a", "number"), 0)
    lu.assertEquals(TimeToSeconds(1, "bad", 30), 0)
end

-- Test GetElapsedTime
function TestTime:testGetElapsedTime()
    -- Should return mission time
    lu.assertEquals(GetElapsedTime(), 1000.0)

    self.currentTime = 5555.5
    lu.assertEquals(GetElapsedTime(), 5555.5)
end

-- Test GetElapsedRealTime
function TestTime:testGetElapsedRealTime()
    -- Should return absTime - time0
    lu.assertEquals(GetElapsedRealTime(), 6800.0) -- 50000 - 43200

    self.absTime = 50000
    self.time0 = 40000
    lu.assertEquals(GetElapsedRealTime(), 10000.0)

    -- Test when mission starts at midnight
    self.absTime = 3600
    self.time0 = 0
    lu.assertEquals(GetElapsedRealTime(), 3600.0)
end

-- Test edge cases and error handling
function TestTime:testErrorHandling()
    -- Make timer functions throw errors
    timer.getTime = function()
        error("Timer error")
    end
    timer.getAbsTime = function()
        error("Timer error")
    end
    timer.getTime0 = function()
        error("Timer error")
    end

    -- Functions should return safe defaults
    lu.assertEquals(GetTime(), 0)
    lu.assertEquals(GetAbsTime(), 0)
    lu.assertEquals(GetTime0(), 0)
end

return TestTime
