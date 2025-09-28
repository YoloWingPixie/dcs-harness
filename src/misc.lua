--[[
==================================================================================================
    MISC MODULE
    Miscellaneous utility functions
==================================================================================================
]]
require("logger")
--- Deep copy a table
---@param original any Value to copy (tables are copied recursively)
---@return any copy Deep copy of the original
---@usage local copy = DeepCopy(myTable)
function DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end

    local copy = {}
    for key, value in pairs(original) do
        copy[key] = DeepCopy(value)
    end

    -- Preserve metatable from original table
    local mt = getmetatable(original)
    if mt ~= nil then
        setmetatable(copy, mt)
    end

    return copy
end

--- Shallow copy a table
---@param original any Value to copy (only first level for tables)
---@return any copy Shallow copy of the original
---@usage local copy = ShallowCopy(myTable)
function ShallowCopy(original)
    if type(original) ~= "table" then
        return original
    end

    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end

    return copy
end

--- Check if table contains value
---@param table table Table to search in
---@param value any Value to search for
---@return boolean found True if value is in table
---@usage if Contains(myList, "item") then ... end
function Contains(table, value)
    if type(table) ~= "table" then
        return false
    end

    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

--- Check if table contains key
---@param table table Table to search in
---@param key any Key to search for
---@return boolean found True if key exists in table
---@usage if ContainsKey(myTable, "key") then ... end
function ContainsKey(table, key)
    if type(table) ~= "table" then
        return false
    end

    return table[key] ~= nil
end

--- Get table size (works with non-sequential tables)
---@param t any Value to check (0 if not a table)
---@return number size Number of entries in table
---@usage local size = TableSize(myTable)
function TableSize(t)
    if type(t) ~= "table" then
        return 0
    end

    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end

    return count
end

--- Get table keys
---@param t any Table to get keys from
---@return table keys Array of all keys in the table
---@usage local keys = TableKeys(myTable)
function TableKeys(t)
    if type(t) ~= "table" then
        return {}
    end

    local keys = {}
    for key, _ in pairs(t) do
        table.insert(keys, key)
    end

    return keys
end

--- Get table values
---@param t any Table to get values from
---@return table values Array of all values in the table
---@usage local values = TableValues(myTable)
function TableValues(t)
    if type(t) ~= "table" then
        return {}
    end

    local values = {}
    for _, value in pairs(t) do
        table.insert(values, value)
    end

    return values
end

--- Merge tables (second overwrites first)
---@param t1 any First table (or value)
---@param t2 any Second table to merge
---@return table merged Deep copy of t1 with t2 values merged in
---@usage local merged = MergeTables(defaults, options)
function MergeTables(t1, t2)
    if type(t1) ~= "table" then
        t1 = {}
    end

    if type(t2) ~= "table" then
        return t1
    end

    local merged = DeepCopy(t1)

    for key, value in pairs(t2) do
        merged[key] = value
    end

    return merged
end

--- Filter table by predicate function
---@param t any Table to filter
---@param predicate function Function(value, key) that returns true to keep
---@return table filtered New table with filtered entries
---@usage local evens = FilterTable(nums, function(v) return v % 2 == 0 end)
function FilterTable(t, predicate)
    if type(t) ~= "table" or type(predicate) ~= "function" then
        return {}
    end

    local filtered = {}

    for key, value in pairs(t) do
        if predicate(value, key) then
            filtered[key] = value
        end
    end

    return filtered
end

--- Map table values with function
---@param t any Table to map
---@param func function Function(value, key) that returns new value
---@return table mapped New table with mapped values
---@usage local doubled = MapTable(nums, function(v) return v * 2 end)
function MapTable(t, func)
    if type(t) ~= "table" or type(func) ~= "function" then
        return {}
    end

    local mapped = {}

    for key, value in pairs(t) do
        mapped[key] = func(value, key)
    end

    return mapped
end

--- Clamp value between min and max
---@param value number Value to clamp
---@param min number Minimum value
---@param max number Maximum value
---@return number clamped Value clamped between min and max
---@usage local health = Clamp(damage, 0, 100)
function Clamp(value, min, max)
    if type(value) ~= "number" or type(min) ~= "number" or type(max) ~= "number" then
        _HarnessInternal.log.error("Clamp requires three numbers", "Clamp")
        return min
    end

    return math.max(min, math.min(max, value))
end

--- Linear interpolation
---@param a number Start value
---@param b number End value
---@param t number Interpolation factor (0 to 1)
---@return number interpolated Interpolated value
---@usage local mid = Lerp(0, 100, 0.5) -- 50
function Lerp(a, b, t)
    if type(a) ~= "number" or type(b) ~= "number" or type(t) ~= "number" then
        _HarnessInternal.log.error("Lerp requires three numbers", "Lerp")
        return a or 0
    end

    return a + (b - a) * t
end

--- Round to decimal places
---@param value number Value to round
---@param decimals number? Number of decimal places (default 0)
---@return number rounded Rounded value
---@usage local rounded = Round(3.14159, 2) -- 3.14
function Round(value, decimals)
    if type(value) ~= "number" then
        _HarnessInternal.log.error("Round requires number", "Round")
        return 0
    end

    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

--- Random float between min and max
---@param min number Minimum value
---@param max number Maximum value
---@return number random Random float between min and max
---@usage local rand = RandomFloat(0.0, 1.0)
function RandomFloat(min, max)
    if type(min) ~= "number" or type(max) ~= "number" then
        _HarnessInternal.log.error("RandomFloat requires two numbers", "RandomFloat")
        return 0
    end

    return min + math.random() * (max - min)
end

--- Random integer between min and max (inclusive)
---@param min number Minimum value
---@param max number Maximum value
---@return number random Random integer between min and max (inclusive)
---@usage local dice = RandomInt(1, 6)
function RandomInt(min, max)
    if type(min) ~= "number" or type(max) ~= "number" then
        _HarnessInternal.log.error("RandomInt requires two numbers", "RandomInt")
        return 0
    end

    return math.random(min, max)
end

--- Random choice from array
---@param choices table? Array to choose from
---@return any? choice Random element from array, nil if empty
---@usage local item = RandomChoice({"red", "green", "blue"})
function RandomChoice(choices)
    if type(choices) ~= "table" or #choices == 0 then
        return nil
    end

    return choices[math.random(1, #choices)]
end

--- Shuffle array in place
---@param array any Array to shuffle (modified in place)
---@return any array The shuffled array (same reference)
---@usage Shuffle(myArray)
function Shuffle(array)
    if type(array) ~= "table" then
        return array
    end

    local n = #array
    for i = n, 2, -1 do
        local j = math.random(1, i)
        array[i], array[j] = array[j], array[i]
    end

    return array
end

--- Create shuffled copy of array
---@param array any Array to copy and shuffle
---@return table shuffled New shuffled array
---@usage local shuffled = ShuffledCopy(myArray)
function ShuffledCopy(array)
    if type(array) ~= "table" then
        return {}
    end

    local copy = {}
    for i, v in ipairs(array) do
        copy[i] = v
    end

    return Shuffle(copy)
end

--- Split string by delimiter
---@param str any String to split
---@param delimiter string? Delimiter (default ",")
---@return table parts Array of string parts
---@usage local parts = SplitString("a,b,c", ",")
function SplitString(str, delimiter)
    if type(str) ~= "string" then
        return {}
    end

    delimiter = delimiter or ","

    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)

    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end

    return result
end

--- Trim whitespace from string
---@param str any String to trim
---@return string trimmed Trimmed string (empty if not string)
---@usage local clean = TrimString("  hello  ")
function TrimString(str)
    if type(str) ~= "string" then
        return ""
    end

    return str:match("^%s*(.-)%s*$")
end

--- Check if string starts with prefix
---@param str any String to check
---@param prefix any Prefix to look for
---@return boolean starts True if str starts with prefix
---@usage if StartsWith(filename, "test_") then ... end
function StartsWith(str, prefix)
    if type(str) ~= "string" or type(prefix) ~= "string" then
        return false
    end

    return string.sub(str, 1, string.len(prefix)) == prefix
end

--- Check if string ends with suffix
---@param str any String to check
---@param suffix any Suffix to look for
---@return boolean ends True if str ends with suffix
---@usage if EndsWith(filename, ".lua") then ... end
function EndsWith(str, suffix)
    if type(str) ~= "string" or type(suffix) ~= "string" then
        return false
    end

    return string.sub(str, -string.len(suffix)) == suffix
end

-- Note: DegToRad and RadToDeg functions are available in geomath.lua

--- Normalize angle to 0-360 range
---@param angle number Angle in degrees
---@return number normalized Angle normalized to 0-360
---@usage local norm = NormalizeAngle(450) -- 90
function NormalizeAngle(angle)
    if type(angle) ~= "number" then
        _HarnessInternal.log.error("NormalizeAngle requires number", "NormalizeAngle")
        return 0
    end

    while angle < 0 do
        angle = angle + 360
    end

    while angle >= 360 do
        angle = angle - 360
    end

    return angle
end

--- Get angle difference (shortest path)
---@param angle1 number First angle in degrees
---@param angle2 number Second angle in degrees
---@return number difference Shortest angle difference (-180 to 180)
---@usage local diff = AngleDiff(350, 10) -- 20
function AngleDiff(angle1, angle2)
    if type(angle1) ~= "number" or type(angle2) ~= "number" then
        _HarnessInternal.log.error("AngleDiff requires two numbers", "AngleDiff")
        return 0
    end

    local diff = angle2 - angle1

    while diff > 180 do
        diff = diff - 360
    end

    while diff < -180 do
        diff = diff + 360
    end

    return diff
end

--- Simple table serialization for debugging
---@param tbl any Table to serialize
---@param indent number? Indentation level (default 0)
---@return string serialized String representation of table
---@usage print(TableToString(myTable))
function TableToString(tbl, indent)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end

    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local result = "{\n"

    for key, value in pairs(tbl) do
        result = result .. indentStr .. "  [" .. tostring(key) .. "] = "

        if type(value) == "table" then
            result = result .. TableToString(value, indent + 1)
        else
            result = result .. tostring(value)
        end

        result = result .. ",\n"
    end

    result = result .. indentStr .. "}"

    return result
end

--- Encode a Lua value to JSON string
---@param value any Value to encode (tables, numbers, strings, booleans, nil)
---@return string|nil json JSON string on success, nil on error
---@usage local s = EncodeJson({a=1})
function EncodeJson(value)
    -- Prefer DCS-provided implementation if available
    if _G.net and type(_G.net.lua2json) == "function" then
        local ok, res = pcall(_G.net.lua2json, value)
        if ok then
            return res
        end
        _HarnessInternal.log.error("EncodeJson failed via net.lua2json: " .. tostring(res), "EncodeJson")
        return nil
    end

    -- Minimal fallback encoder (sufficient for simple tables without cycles or functions)
    local t = type(value)
    if t == "nil" then
        return "null"
    elseif t == "number" or t == "boolean" then
        return tostring(value)
    elseif t == "string" then
        local s = value
        s = s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r')
        return '"' .. s .. '"'
    elseif t == "table" then
        -- Detect array-like table
        local isArray = true
        local count = 0
        for k, _ in pairs(value) do
            count = count + 1
            if type(k) ~= "number" then
                isArray = false
                break
            end
        end
        if isArray then
            local parts = {}
            for i = 1, #value do
                parts[#parts + 1] = EncodeJson(value[i]) or "null"
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(value) do
                local keyType = type(k)
                if keyType ~= "string" then
                    -- JSON keys must be strings; stringify others
                    k = tostring(k)
                end
                local keyJson = EncodeJson(k)
                local valJson = EncodeJson(v) or "null"
                parts[#parts + 1] = tostring(keyJson) .. ":" .. valJson
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end

    _HarnessInternal.log.error("EncodeJson cannot encode type: " .. t, "EncodeJson")
    return nil
end

--- Decode a JSON string to Lua value
---@param json string JSON string to decode
---@return any value Decoded Lua value (or nil on error)
---@usage local t = DecodeJson('{"a":1}')
function DecodeJson(json)
    if type(json) ~= "string" then
        _HarnessInternal.log.error("DecodeJson requires string", "DecodeJson")
        return nil
    end

    -- Prefer DCS-provided implementation if available
    if _G.net and type(_G.net.json2lua) == "function" then
        local ok, res = pcall(_G.net.json2lua, json)
        if ok then
            return res
        end
        _HarnessInternal.log.error("DecodeJson failed via net.json2lua: " .. tostring(res), "DecodeJson")
        return nil
    end

    -- Extremely small fallback: handle null, booleans, numbers, quoted strings, simple arrays/objects
    local str = json:match("^%s*(.-)%s*$")
    if str == "null" then
        return nil
    end
    if str == "true" then
        return true
    end
    if str == "false" then
        return false
    end
    -- number
    local num = tonumber(str)
    if num ~= nil then
        return num
    end
    -- quoted string
    local s = str:match('^"(.*)"$')
    if s ~= nil then
        s = s:gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\"', '"'):gsub('\\\\', '\\')
        return s
    end

    -- Very naive parser for flat arrays/objects without nesting or spaces inside keys
    local function splitTopLevel(content)
        local parts = {}
        local buf = {}
        local inString = false
        local escape = false
        for i = 1, #content do
            local ch = content:sub(i, i)
            if inString then
                table.insert(buf, ch)
                if escape then
                    escape = false
                elseif ch == '\\' then
                    escape = true
                elseif ch == '"' then
                    inString = false
                end
            else
                if ch == '"' then
                    inString = true
                    table.insert(buf, ch)
                elseif ch == ',' then
                    parts[#parts + 1] = table.concat(buf)
                    buf = {}
                else
                    table.insert(buf, ch)
                end
            end
        end
        if #buf > 0 then
            parts[#parts + 1] = table.concat(buf)
        end
        return parts
    end

    -- Array [a,b,c]
    local inner = str:match("^%[(.*)%]$")
    if inner ~= nil then
        local items = splitTopLevel(inner)
        local result = {}
        for i = 1, #items do
            local v = DecodeJson(items[i])
            result[#result + 1] = v
        end
        return result
    end

    -- Object {"k":v,...} (flat only)
    inner = str:match("^%{(.*)%}$")
    if inner ~= nil then
        local items = splitTopLevel(inner)
        local obj = {}
        for _, item in ipairs(items) do
            local k, v = item:match("^%s*(.-)%s*:%s*(.-)%s*$")
            if k ~= nil then
                local key = DecodeJson(k)
                obj[key] = DecodeJson(v)
            end
        end
        return obj
    end

    _HarnessInternal.log.error("DecodeJson fallback cannot parse input", "DecodeJson")
    return nil
end

--- Retry decorator: retries function on failure
---@param func function Function to wrap
---@param options table? Options {retries:number, shouldRetry:function?, onRetry:function?}
---@return function wrapped Function that retries on error
---@usage
--- local unstable = function(x)
--- 	if math.random() < 0.5 then error("boom") end
--- 	return x * 2
--- end
--- local safe = Retry(unstable, {retries = 3})
--- local result = safe(10)
function Retry(func, options)
    if type(func) ~= "function" then
        _HarnessInternal.log.error("Retry requires function", "Retry")
        return func
    end

    options = options or {}
    local maxRetries = tonumber(options.retries) or 3
    local shouldRetry = options.shouldRetry -- function(success, ...): boolean
    local onRetry = options.onRetry -- function(attempt, err)

    return function(...)
        local args = { ... }
        local attempt = 0
        while true do
            local results = { pcall(func, unpack(args)) }
            local ok = results[1]
            if ok then
                local ret = {}
                for i = 2, #results do
                    ret[i - 1] = results[i]
                end
                local shouldRetryNow = false
                if type(shouldRetry) == "function" then
                    local ok2, decision = pcall(shouldRetry, true, unpack(ret))
                    if ok2 then
                        shouldRetryNow = decision and attempt < maxRetries
                    end
                end
                if shouldRetryNow then
                    attempt = attempt + 1
                    if type(onRetry) == "function" then
                        pcall(onRetry, attempt, nil)
                    end
                    -- loop to retry
                else
                    return unpack(ret)
                end
            else
                local err = results[2]
                if attempt >= maxRetries then
                    _HarnessInternal.log.error(
                        "Retry exhausted after "
                            .. tostring(attempt)
                            .. " attempts: "
                            .. tostring(err),
                        "Retry"
                    )
                    return nil
                end
                attempt = attempt + 1
                if type(onRetry) == "function" then
                    pcall(onRetry, attempt, err)
                end
                _HarnessInternal.log.warn(
                    "Retry attempt " .. tostring(attempt) .. " after error: " .. tostring(err),
                    "Retry"
                )
                -- loop to retry
            end
        end
    end
end

--- Circuit breaker decorator: opens circuit after failures, with cooldown
---@param func function Function to wrap
---@param options table? Options {failureThreshold:number, cooldown:number, timeProvider:function?, shouldCountFailure:function?}
---@return function wrapped Wrapped function with breaker behavior
---@usage
--- local safe = CircuitBreaker(unstable, {failureThreshold=3, cooldown=30})
--- local result = safe(10)
function CircuitBreaker(func, options)
    if type(func) ~= "function" then
        _HarnessInternal.log.error("CircuitBreaker requires function", "CircuitBreaker")
        return func
    end

    options = options or {}
    local failureThreshold = tonumber(options.failureThreshold) or 5
    local cooldown = tonumber(options.cooldown) or 30
    local timeProvider = options.timeProvider
    if type(timeProvider) ~= "function" then
        timeProvider = function()
            return GetTime()
        end
    end
    local shouldCountFailure = options.shouldCountFailure -- function(success, ...) -> boolean (count as failure?)

    local state = {
        status = "closed", -- "closed" | "open" | "half_open"
        consecutiveFailures = 0,
        openedAt = nil,
    }

    local function transitionToOpen(now)
        state.status = "open"
        state.openedAt = now
        _HarnessInternal.log.warn("Circuit opened after failures", "CircuitBreaker")
    end

    local function transitionToHalfOpen()
        state.status = "half_open"
        _HarnessInternal.log.info("Circuit half-open: trial call permitted", "CircuitBreaker")
    end

    local function transitionToClosed()
        state.status = "closed"
        state.consecutiveFailures = 0
        state.openedAt = nil
        _HarnessInternal.log.info("Circuit closed", "CircuitBreaker")
    end

    return function(...)
        local now = timeProvider()

        -- Handle open state cooldown expiry
        if state.status == "open" then
            if cooldown <= 0 or (state.openedAt and now - state.openedAt >= cooldown) then
                transitionToHalfOpen()
            else
                _HarnessInternal.log.warn("Call short-circuited (circuit open)", "CircuitBreaker")
                return nil
            end
        end

        -- Allow single trial in half-open
        local trial = state.status == "half_open"
        local packed = { pcall(func, ...) }
        local ok = packed[1]
        if ok then
            local ret = {}
            for i = 2, #packed do
                ret[i - 1] = packed[i]
            end
            -- Success: optionally consult shouldCountFailure (if provided) to treat as failure
            local countAsFailure = false
            if type(shouldCountFailure) == "function" then
                local ok2, decision = pcall(shouldCountFailure, true, unpack(ret))
                if ok2 then
                    countAsFailure = decision
                end
            end
            if countAsFailure then
                state.consecutiveFailures = state.consecutiveFailures + 1
                if state.consecutiveFailures >= failureThreshold then
                    transitionToOpen(now)
                end
                return unpack(ret)
            end
            transitionToClosed()
            return unpack(ret)
        else
            -- Failure
            local err = packed[2]
            state.consecutiveFailures = state.consecutiveFailures + 1
            _HarnessInternal.log.warn(
                "Function error (failure "
                    .. tostring(state.consecutiveFailures)
                    .. "): "
                    .. tostring(err),
                "CircuitBreaker"
            )
            if trial then
                transitionToOpen(now)
            elseif state.consecutiveFailures >= failureThreshold then
                transitionToOpen(now)
            end
            return nil
        end
    end
end
