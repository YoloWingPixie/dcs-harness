--[[
==================================================================================================
    FLAG MODULE
    User flag utilities
==================================================================================================
]]
require("logger")
--- Get flag value
---@param flagName string? Name of the flag
---@return number value Flag value (0 if not found or error)
---@usage local value = GetFlag("myFlag")
function GetFlag(flagName)
    if not flagName then
        _HarnessInternal.log.error("GetFlag requires flag name", "GetFlag")
        return 0
    end
    
    local success, value = pcall(trigger.misc.getUserFlag, flagName)
    if not success then
        _HarnessInternal.log.error("Failed to get flag: " .. tostring(value), "GetFlag")
        return 0
    end
    
    return value
end

--- Set flag value
---@param flagName string? Name of the flag
---@param value number? Value to set (default 1)
---@return boolean success True if set successfully
---@usage SetFlag("myFlag", 5)
function SetFlag(flagName, value)
    if not flagName then
        _HarnessInternal.log.error("SetFlag requires flag name", "SetFlag")
        return false
    end
    
    value = value or 1
    
    local success, result = pcall(trigger.action.setUserFlag, flagName, value)
    if not success then
        _HarnessInternal.log.error("Failed to set flag: " .. tostring(result), "SetFlag")
        return false
    end
    
    return true
end

--- Increment flag value
---@param flagName string Name of the flag
---@param amount number? Amount to increment (default 1)
---@return boolean success True if incremented successfully
---@usage IncFlag("counter", 5)
function IncFlag(flagName, amount)
    amount = amount or 1
    
    local currentValue = GetFlag(flagName)
    return SetFlag(flagName, currentValue + amount)
end

--- Decrement flag value
---@param flagName string Name of the flag
---@param amount number? Amount to decrement (default 1)
---@return boolean success True if decremented successfully
---@usage DecFlag("counter", 2)
function DecFlag(flagName, amount)
    amount = amount or 1
    
    local currentValue = GetFlag(flagName)
    return SetFlag(flagName, currentValue - amount)
end

--- Toggle flag between 0 and 1
---@param flagName string Name of the flag
---@return boolean success True if toggled successfully
---@usage ToggleFlag("switch")
function ToggleFlag(flagName)
    local currentValue = GetFlag(flagName)
    return SetFlag(flagName, currentValue == 0 and 1 or 0)
end

--- Check if flag is true (non-zero)
---@param flagName string Name of the flag
---@return boolean isTrue True if flag is non-zero
---@usage if IsFlagTrue("activated") then ... end
function IsFlagTrue(flagName)
    return GetFlag(flagName) ~= 0
end

--- Check if flag is false (zero)
---@param flagName string Name of the flag
---@return boolean isFalse True if flag is zero
---@usage if IsFlagFalse("activated") then ... end
function IsFlagFalse(flagName)
    return GetFlag(flagName) == 0
end

--- Check if flag equals value
---@param flagName string Name of the flag
---@param value number Value to compare
---@return boolean equals True if flag equals value
---@usage if FlagEquals("state", 3) then ... end
function FlagEquals(flagName, value)
    return GetFlag(flagName) == value
end

--- Check if flag is greater than value
---@param flagName string Name of the flag
---@param value number Value to compare
---@return boolean greater True if flag > value
---@usage if FlagGreaterThan("score", 100) then ... end
function FlagGreaterThan(flagName, value)
    return GetFlag(flagName) > value
end

--- Check if flag is less than value
---@param flagName string Name of the flag
---@param value number Value to compare
---@return boolean less True if flag < value
---@usage if FlagLessThan("health", 20) then ... end
function FlagLessThan(flagName, value)
    return GetFlag(flagName) < value
end

--- Check if flag is between values (inclusive)
---@param flagName string Name of the flag
---@param min number Minimum value (inclusive)
---@param max number Maximum value (inclusive)
---@return boolean between True if min <= flag <= max
---@usage if FlagBetween("temperature", 20, 30) then ... end
function FlagBetween(flagName, min, max)
    local value = GetFlag(flagName)
    return value >= min and value <= max
end

--- Set multiple flags at once
---@param flagTable table Table of flagName = value pairs
---@return boolean success True if all flags set successfully
---@usage SetFlags({flag1 = 10, flag2 = 20, flag3 = 0})
function SetFlags(flagTable)
    if type(flagTable) ~= "table" then
        _HarnessInternal.log.error("SetFlags requires table of flag name/value pairs", "SetFlags")
        return false
    end
    
    local allSuccess = true
    
    for flagName, value in pairs(flagTable) do
        if not SetFlag(flagName, value) then
            allSuccess = false
        end
    end
    
    return allSuccess
end

--- Get multiple flags at once
---@param flagNames table Array of flag names
---@return table values Table of flagName = value pairs
---@usage local vals = GetFlags({"flag1", "flag2", "flag3"})
function GetFlags(flagNames)
    if type(flagNames) ~= "table" then
        _HarnessInternal.log.error("GetFlags requires table of flag names", "GetFlags")
        return {}
    end
    
    local values = {}
    
    for _, flagName in ipairs(flagNames) do
        values[flagName] = GetFlag(flagName)
    end
    
    return values
end

--- Clear flag (set to 0)
---@param flagName string Name of the flag
---@return boolean success True if cleared successfully
---@usage ClearFlag("myFlag")
function ClearFlag(flagName)
    return SetFlag(flagName, 0)
end

--- Clear multiple flags
---@param flagNames table Array of flag names to clear
---@return boolean success True if all flags cleared successfully
---@usage ClearFlags({"flag1", "flag2", "flag3"})
function ClearFlags(flagNames)
    if type(flagNames) ~= "table" then
        _HarnessInternal.log.error("ClearFlags requires table of flag names", "ClearFlags")
        return false
    end
    
    local allSuccess = true
    
    for _, flagName in ipairs(flagNames) do
        if not ClearFlag(flagName) then
            allSuccess = false
        end
    end
    
    return allSuccess
end