--[[
==================================================================================================
    TIME MODULE
    Time and scheduling utilities
==================================================================================================
]]

--- Get mission time
---@return number time Current mission time in seconds
---@usage local time = GetTime()
function GetTime()
    local success, time = pcall(timer.getTime)
    if not success then
        _HarnessInternal.log.error("Failed to get mission time: " .. tostring(time), "GetTime")
        return 0
    end
    
    return time
end

--- Get absolute time
---@return number time Absolute time in seconds since midnight
---@usage local absTime = GetAbsTime()
function GetAbsTime()
    local success, time = pcall(timer.getAbsTime)
    if not success then
        _HarnessInternal.log.error("Failed to get absolute time: " .. tostring(time), "GetAbsTime")
        return 0
    end
    
    return time
end

--- Get mission start time
---@return number time Mission start time in seconds
---@usage local startTime = GetTime0()
function GetTime0()
    local success, time = pcall(timer.getTime0)
    if not success then
        _HarnessInternal.log.error("Failed to get mission start time: " .. tostring(time), "GetTime0")
        return 0
    end
    
    return time
end

--- Format time as HH:MM:SS
---@param seconds number Time in seconds
---@return string formatted Time string in HH:MM:SS format
---@usage local timeStr = FormatTime(3661) -- "01:01:01"
function FormatTime(seconds)
    if type(seconds) ~= "number" then
        _HarnessInternal.log.error("FormatTime requires number", "FormatTime")
        return "00:00:00"
    end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

--- Format time as MM:SS
---@param seconds number Time in seconds
---@return string formatted Time string in MM:SS format
---@usage local timeStr = FormatTimeShort(125) -- "02:05"
function FormatTimeShort(seconds)
    if type(seconds) ~= "number" then
        _HarnessInternal.log.error("FormatTimeShort requires number", "FormatTimeShort")
        return "00:00"
    end
    
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    
    return string.format("%02d:%02d", minutes, secs)
end

--- Get current mission time as table
---@return table time Table with hours, minutes, seconds fields
---@usage local t = GetMissionTime() -- {hours=14, minutes=30, seconds=45}
function GetMissionTime()
    local currentTime = GetAbsTime()
    
    local hours = math.floor(currentTime / 3600)
    local minutes = math.floor((currentTime % 3600) / 60)
    local seconds = math.floor(currentTime % 60)
    
    return {
        hours = hours,
        minutes = minutes,
        seconds = seconds
    }
end

--- Check if current time is night (19:00-06:59)
---@return boolean isNight True if between 19:00 and 06:59
---@usage if IsNightTime() then ... end
function IsNightTime()
    local absTime = GetAbsTime()
    local secondsInDay = absTime % 86400
    local hour = math.floor(secondsInDay / 3600)
    
    return hour >= 19 or hour < 7
end

--- Schedule a function (no recurring - pure function)
---@param func function Function to schedule
---@param args any? Arguments to pass to function
---@param delay number? Delay in seconds (default 0)
---@return number? timerId Timer ID for cancellation, nil on error
---@usage local id = ScheduleOnce(myFunc, {arg1, arg2}, 10)
function ScheduleOnce(func, args, delay)
    if type(func) ~= "function" then
        _HarnessInternal.log.error("ScheduleOnce requires function", "ScheduleOnce")
        return nil
    end
    
    delay = delay or 0
    local time = GetTime() + delay
    
    local success, timerId = pcall(timer.scheduleFunction, func, args, time)
    if not success then
        _HarnessInternal.log.error("Failed to schedule function: " .. tostring(timerId), "ScheduleOnce")
        return nil
    end
    
    return timerId
end

--- Cancel scheduled function
---@param timerId number? Timer ID to cancel
---@return boolean success True if cancelled successfully
---@usage CancelSchedule(timerId)
function CancelSchedule(timerId)
    if not timerId then
        return false
    end
    
    local success, result = pcall(timer.removeFunction, timerId)
    if not success then
        _HarnessInternal.log.warn("Failed to cancel scheduled function: " .. tostring(result), "CancelSchedule")
        return false
    end
    
    return true
end

--- Reschedule function
---@param timerId number Timer ID to reschedule
---@param newTime number New execution time in seconds
---@return boolean success True if rescheduled successfully
---@usage RescheduleFunction(timerId, GetTime() + 30)
function RescheduleFunction(timerId, newTime)
    if not timerId or type(newTime) ~= "number" then
        _HarnessInternal.log.error("RescheduleFunction requires timerId and new time", "RescheduleFunction")
        return false
    end
    
    local success, result = pcall(timer.setFunctionTime, timerId, newTime)
    if not success then
        _HarnessInternal.log.error("Failed to reschedule function: " .. tostring(result), "RescheduleFunction")
        return false
    end
    
    return true
end

--- Convert seconds to time components
---@param seconds number Time in seconds
---@return table components Table with hours, minutes, seconds fields
---@usage local t = SecondsToTime(3661) -- {hours=1, minutes=1, seconds=1}
function SecondsToTime(seconds)
    if type(seconds) ~= "number" then
        _HarnessInternal.log.error("SecondsToTime requires number", "SecondsToTime")
        return {hours = 0, minutes = 0, seconds = 0}
    end
    
    return {
        hours = math.floor(seconds / 3600),
        minutes = math.floor((seconds % 3600) / 60),
        seconds = math.floor(seconds % 60)
    }
end

--- Convert time components to seconds
---@param hours number? Hours (default 0)
---@param minutes number? Minutes (default 0)
---@param seconds number? Seconds (default 0)
---@return number totalSeconds Total seconds
---@usage local secs = TimeToSeconds(1, 30, 45) -- 5445
function TimeToSeconds(hours, minutes, seconds)
    hours = hours or 0
    minutes = minutes or 0
    seconds = seconds or 0
    
    if type(hours) ~= "number" or type(minutes) ~= "number" or type(seconds) ~= "number" then
        _HarnessInternal.log.error("TimeToSeconds requires numeric values", "TimeToSeconds")
        return 0
    end
    
    return hours * 3600 + minutes * 60 + seconds
end

--- Get elapsed time since mission start
---@return number elapsed Mission elapsed time in seconds
---@usage local elapsed = GetElapsedTime()
function GetElapsedTime()
    return GetTime()
end

--- Get elapsed real time since mission start
---@return number elapsed Real elapsed time in seconds
---@usage local realElapsed = GetElapsedRealTime()
function GetElapsedRealTime()
    return GetAbsTime() - GetTime0()
end