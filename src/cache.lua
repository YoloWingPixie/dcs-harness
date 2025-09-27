--[[
==================================================================================================
    CACHE MODULE
    Internal caching system for DCS object handles
==================================================================================================
]]
require("logger")
-- Ensure cache tables exist (may have been initialized in _header.lua)
_HarnessInternal.cache = _HarnessInternal.cache
    or {
        units = {},
        groups = {},
        controllers = {},
        airbases = {},

        -- Statistics
        stats = {
            hits = 0,
            misses = 0,
            evictions = 0,
        },
    }

-- Cache configuration
_HarnessInternal.cache.config = _HarnessInternal.cache.config
    or {
        maxUnits = 1000,
        maxGroups = 500,
        maxControllers = 500,
        maxAirbases = 100,
        ttl = 300, -- 5 minutes default TTL
    }

--- Clear all caches
---@usage ClearAllCaches()
function ClearAllCaches()
    local count = 0
    for _ in pairs(_HarnessInternal.cache.units) do
        count = count + 1
    end
    for _ in pairs(_HarnessInternal.cache.groups) do
        count = count + 1
    end
    for _ in pairs(_HarnessInternal.cache.controllers) do
        count = count + 1
    end
    for _ in pairs(_HarnessInternal.cache.airbases) do
        count = count + 1
    end

    _HarnessInternal.cache.units = {}
    _HarnessInternal.cache.groups = {}
    _HarnessInternal.cache.controllers = {}
    _HarnessInternal.cache.airbases = {}

    if count > 0 then
        _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + count
    end

    _HarnessInternal.log.info("Cleared all caches (" .. count .. " entries)", "ClearAllCaches")
end

--- Clear unit cache
---@usage ClearUnitCache()
function ClearUnitCache()
    local count = 0
    for _ in pairs(_HarnessInternal.cache.units) do
        count = count + 1
    end
    _HarnessInternal.cache.units = {}
    _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + count
    _HarnessInternal.log.info("Cleared unit cache (" .. count .. " entries)", "ClearUnitCache")
end

--- Clear group cache
---@usage ClearGroupCache()
function ClearGroupCache()
    local count = 0
    for _ in pairs(_HarnessInternal.cache.groups) do
        count = count + 1
    end
    _HarnessInternal.cache.groups = {}
    _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + count
    _HarnessInternal.log.info("Cleared group cache (" .. count .. " entries)", "ClearGroupCache")
end

--- Clear controller cache
---@usage ClearControllerCache()
function ClearControllerCache()
    local count = 0
    for _ in pairs(_HarnessInternal.cache.controllers) do
        count = count + 1
    end
    _HarnessInternal.cache.controllers = {}
    _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + count
    _HarnessInternal.log.info(
        "Cleared controller cache (" .. count .. " entries)",
        "ClearControllerCache"
    )
end

--- Remove specific unit from cache
---@param unitName string Unit name
---@usage RemoveUnitFromCache("Pilot-1")
function RemoveUnitFromCache(unitName)
    if unitName and _HarnessInternal.cache.units[unitName] then
        _HarnessInternal.cache.units[unitName] = nil
        _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
        _HarnessInternal.log.debug("Removed unit from cache: " .. unitName, "RemoveUnitFromCache")
    end
end

--- Remove specific group from cache
---@param groupName string Group name
---@usage RemoveGroupFromCache("Blue Squadron")
function RemoveGroupFromCache(groupName)
    if groupName and _HarnessInternal.cache.groups[groupName] then
        _HarnessInternal.cache.groups[groupName] = nil
        _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
        _HarnessInternal.log.debug(
            "Removed group from cache: " .. groupName,
            "RemoveGroupFromCache"
        )
    end
end

--- Get cache statistics
---@return table stats Cache statistics
---@usage local stats = GetCacheStats()
function GetCacheStats()
    local stats = {
        hits = _HarnessInternal.cache.stats.hits,
        misses = _HarnessInternal.cache.stats.misses,
        evictions = _HarnessInternal.cache.stats.evictions,
        hitRate = 0,
        units = 0,
        groups = 0,
        controllers = 0,
        airbases = 0,
    }

    -- Count entries
    for _ in pairs(_HarnessInternal.cache.units) do
        stats.units = stats.units + 1
    end
    for _ in pairs(_HarnessInternal.cache.groups) do
        stats.groups = stats.groups + 1
    end
    for _ in pairs(_HarnessInternal.cache.controllers) do
        stats.controllers = stats.controllers + 1
    end
    for _ in pairs(_HarnessInternal.cache.airbases) do
        stats.airbases = stats.airbases + 1
    end

    -- Calculate hit rate
    local total = stats.hits + stats.misses
    if total > 0 then
        stats.hitRate = stats.hits / total
    end

    return stats
end

--- Set cache configuration
---@param config table Configuration options
---@usage SetCacheConfig({maxUnits = 2000, ttl = 600})
function SetCacheConfig(config)
    if type(config) ~= "table" then
        _HarnessInternal.log.error("SetCacheConfig requires table", "SetCacheConfig")
        return
    end

    if config.maxUnits and type(config.maxUnits) == "number" then
        _HarnessInternal.cache.config.maxUnits = config.maxUnits
    end
    if config.maxGroups and type(config.maxGroups) == "number" then
        _HarnessInternal.cache.config.maxGroups = config.maxGroups
    end
    if config.maxControllers and type(config.maxControllers) == "number" then
        _HarnessInternal.cache.config.maxControllers = config.maxControllers
    end
    if config.maxAirbases and type(config.maxAirbases) == "number" then
        _HarnessInternal.cache.config.maxAirbases = config.maxAirbases
    end
    if config.ttl and type(config.ttl) == "number" then
        _HarnessInternal.cache.config.ttl = config.ttl
    end

    _HarnessInternal.log.info("Updated cache configuration", "SetCacheConfig")
end

--- Get direct access to cache tables (for advanced users)
---@return table caches All cache tables
---@usage local caches = GetCacheTables()
function GetCacheTables()
    return {
        units = _HarnessInternal.cache.units,
        groups = _HarnessInternal.cache.groups,
        controllers = _HarnessInternal.cache.controllers,
        airbases = _HarnessInternal.cache.airbases,
    }
end

-- Internal cache management functions

--- Check if cache entry is expired
---@param entry table Cache entry
---@return boolean expired True if expired
function _HarnessInternal.cache.isExpired(entry)
    if not entry or not entry.time then
        return true
    end

    local currentTime = timer and timer.getTime and timer.getTime() or os.time()
    return (currentTime - entry.time) > _HarnessInternal.cache.config.ttl
end

--- Add unit to cache
---@param name string Unit name
---@param unit table Unit object
function _HarnessInternal.cache.addUnit(name, unit)
    if not name or not unit then
        return
    end

    -- Check cache size
    local count = 0
    for _ in pairs(_HarnessInternal.cache.units) do
        count = count + 1
    end

    if count >= _HarnessInternal.cache.config.maxUnits then
        -- Evict oldest entry
        local oldestKey, oldestTime = nil, math.huge
        for k, v in pairs(_HarnessInternal.cache.units) do
            if v.time < oldestTime then
                oldestKey = k
                oldestTime = v.time
            end
        end
        if oldestKey then
            _HarnessInternal.cache.units[oldestKey] = nil
            _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
        end
    end

    _HarnessInternal.cache.units[name] = {
        object = unit,
        time = timer and timer.getTime and timer.getTime() or os.time(),
    }
end

--- Get unit from cache
---@param name string Unit name
---@return table? unit Unit object or nil
function _HarnessInternal.cache.getUnit(name)
    if not name then
        return nil
    end

    local entry = _HarnessInternal.cache.units[name]
    if not entry then
        _HarnessInternal.cache.stats.misses = _HarnessInternal.cache.stats.misses + 1
        return nil
    end

    -- Check expiration
    if _HarnessInternal.cache.isExpired(entry) then
        _HarnessInternal.cache.units[name] = nil
        _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
        _HarnessInternal.cache.stats.misses = _HarnessInternal.cache.stats.misses + 1
        return nil
    end

    _HarnessInternal.cache.stats.hits = _HarnessInternal.cache.stats.hits + 1
    return entry.object
end

--- Add group to cache
---@param name string Group name
---@param group table Group object
function _HarnessInternal.cache.addGroup(name, group)
    if not name or not group then
        return
    end

    -- Check cache size
    local count = 0
    for _ in pairs(_HarnessInternal.cache.groups) do
        count = count + 1
    end

    if count >= _HarnessInternal.cache.config.maxGroups then
        -- Evict oldest entry
        local oldestKey, oldestTime = nil, math.huge
        for k, v in pairs(_HarnessInternal.cache.groups) do
            if v.time < oldestTime then
                oldestKey = k
                oldestTime = v.time
            end
        end
        if oldestKey then
            _HarnessInternal.cache.groups[oldestKey] = nil
            _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
        end
    end

    _HarnessInternal.cache.groups[name] = {
        object = group,
        time = timer and timer.getTime and timer.getTime() or os.time(),
    }
end

--- Get group from cache
---@param name string Group name
---@return table? group Group object or nil
function _HarnessInternal.cache.getGroup(name)
    if not name then
        return nil
    end

    local entry = _HarnessInternal.cache.groups[name]
    if not entry then
        _HarnessInternal.cache.stats.misses = _HarnessInternal.cache.stats.misses + 1
        return nil
    end

    -- Check expiration
    if _HarnessInternal.cache.isExpired(entry) then
        _HarnessInternal.cache.groups[name] = nil
        _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
        _HarnessInternal.cache.stats.misses = _HarnessInternal.cache.stats.misses + 1
        return nil
    end

    _HarnessInternal.cache.stats.hits = _HarnessInternal.cache.stats.hits + 1
    return entry.object
end

--- Add controller to cache
---@param key string Cache key (unit/group name + type)
---@param controller table Controller object
function _HarnessInternal.cache.addController(key, controller)
    if not key or not controller then
        return
    end

    -- Check cache size
    local count = 0
    for _ in pairs(_HarnessInternal.cache.controllers) do
        count = count + 1
    end

    if count >= _HarnessInternal.cache.config.maxControllers then
        -- Evict oldest entry
        local oldestKey, oldestTime = nil, math.huge
        for k, v in pairs(_HarnessInternal.cache.controllers) do
            if v.time < oldestTime then
                oldestKey = k
                oldestTime = v.time
            end
        end
        if oldestKey then
            _HarnessInternal.cache.controllers[oldestKey] = nil
            _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
        end
    end

    _HarnessInternal.cache.controllers[key] = {
        object = controller,
        time = timer and timer.getTime and timer.getTime() or os.time(),
    }
end

--- Get controller from cache
---@param key string Cache key
---@return table? controller Controller object or nil
function _HarnessInternal.cache.getController(key)
    if not key then
        return nil
    end

    local entry = _HarnessInternal.cache.controllers[key]
    if not entry then
        _HarnessInternal.cache.stats.misses = _HarnessInternal.cache.stats.misses + 1
        return nil
    end

    -- Check expiration
    if _HarnessInternal.cache.isExpired(entry) then
        _HarnessInternal.cache.controllers[key] = nil
        _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
        _HarnessInternal.cache.stats.misses = _HarnessInternal.cache.stats.misses + 1
        return nil
    end

    _HarnessInternal.cache.stats.hits = _HarnessInternal.cache.stats.hits + 1
    return entry.object
end

-- Caching Decorator

--- Create a cached version of a function that returns DCS objects
---@param func function The function to cache
---@param getCacheKey function Function that generates cache key from arguments
---@param cacheType string Cache type: "unit", "group", "controller", or "generic"
---@param verifyFunc function? Optional function to verify cached object is still valid
---@return function cached Cached version of the function
---@usage local cachedGetUnit = CacheDecorator(Unit.getByName, function(name) return name end, "unit")
function CacheDecorator(func, getCacheKey, cacheType, verifyFunc)
    if type(func) ~= "function" then
        _HarnessInternal.log.error("CacheDecorator requires a function", "CacheDecorator")
        return func
    end

    if type(getCacheKey) ~= "function" then
        _HarnessInternal.log.error("CacheDecorator requires getCacheKey function", "CacheDecorator")
        return func
    end

    local validTypes = { unit = true, group = true, controller = true, generic = true }
    if not validTypes[cacheType] then
        _HarnessInternal.log.error("Invalid cache type: " .. tostring(cacheType), "CacheDecorator")
        return func
    end

    -- Default verify function checks isExist()
    verifyFunc = verifyFunc
        or function(obj)
            local success, exists = pcall(function()
                return obj:isExist()
            end)
            return success and exists
        end

    return function(...)
        local cacheKey = getCacheKey(...)
        if not cacheKey then
            return func(...)
        end

        -- Check appropriate cache
        local cached = nil
        if cacheType == "unit" then
            cached = _HarnessInternal.cache.getUnit(cacheKey)
        elseif cacheType == "group" then
            cached = _HarnessInternal.cache.getGroup(cacheKey)
        elseif cacheType == "controller" then
            cached = _HarnessInternal.cache.getController(cacheKey)
        end

        -- Verify cached object is still valid
        if cached and verifyFunc(cached) then
            return cached
        elseif cached then
            -- Remove invalid object from cache
            if cacheType == "unit" then
                RemoveUnitFromCache(cacheKey)
            elseif cacheType == "group" then
                RemoveGroupFromCache(cacheKey)
            elseif cacheType == "controller" then
                _HarnessInternal.cache.controllers[cacheKey] = nil
                _HarnessInternal.cache.stats.evictions = _HarnessInternal.cache.stats.evictions + 1
            end
        end

        -- Call original function
        local result = func(...)

        -- Cache the result if valid
        if result then
            if cacheType == "unit" then
                _HarnessInternal.cache.addUnit(cacheKey, result)
            elseif cacheType == "group" then
                _HarnessInternal.cache.addGroup(cacheKey, result)
            elseif cacheType == "controller" then
                _HarnessInternal.cache.addController(cacheKey, result)
            end
        end

        return result
    end
end

--- Get cached unit (convenience function for external users)
---@param unitName string Unit name
---@return table? unit Cached unit or nil
---@usage local unit = GetCachedUnit("Pilot-1")
function GetCachedUnit(unitName)
    return _HarnessInternal.cache.getUnit(unitName)
end

--- Get cached group (convenience function for external users)
---@param groupName string Group name
---@return table? group Cached group or nil
---@usage local group = GetCachedGroup("Blue Squadron")
function GetCachedGroup(groupName)
    return _HarnessInternal.cache.getGroup(groupName)
end

--- Get cached controller (convenience function for external users)
---@param key string Cache key
---@return table? controller Cached controller or nil
---@usage local controller = GetCachedController("unit:Pilot-1")
function GetCachedController(key)
    return _HarnessInternal.cache.getController(key)
end
