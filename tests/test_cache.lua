local lu = require("luaunit")
require("test_utils")

-- Setup test environment
package.path = package.path .. ";../src/?.lua"

-- Create isolated test suite
TestCache = CreateIsolatedTestSuite("TestCache", {})

function TestCache:setUp()
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

    require("cache")

    -- Clear all caches before each test
    ClearAllCaches()

    -- Reset cache stats
    _HarnessInternal.cache.stats = {
        hits = 0,
        misses = 0,
        evictions = 0,
    }

    -- Mock timer.getTime
    self.currentTime = 1000
    self:mock("timer.getTime", function()
        return self.currentTime
    end)

    -- Create mock objects
    self.mockUnit = {
        getName = function()
            return "TestUnit"
        end,
        isExist = function()
            return true
        end,
        getTypeName = function()
            return "F-16C"
        end,
    }

    self.mockGroup = {
        getName = function()
            return "TestGroup"
        end,
        isExist = function()
            return true
        end,
        getSize = function()
            return 4
        end,
    }

    self.mockController = {
        name = "TestController",
    }
end

function TestCache:tearDown()
    ClearAllCaches()
end

function TestCache:testCacheStats()
    -- Test initial stats
    local stats = GetCacheStats()
    lu.assertEquals(stats.hits, 0)
    lu.assertEquals(stats.misses, 0)
    lu.assertEquals(stats.evictions, 0)
    lu.assertEquals(stats.units, 0)
    lu.assertEquals(stats.groups, 0)
    lu.assertEquals(stats.controllers, 0)
    lu.assertEquals(stats.hitRate, 0)
end

function TestCache:testUnitCache()
    -- Test adding unit to cache
    _HarnessInternal.cache.addUnit("TestUnit", self.mockUnit)

    -- Test cache hit
    local cached = _HarnessInternal.cache.getUnit("TestUnit")
    lu.assertNotNil(cached)
    lu.assertEquals(cached:getName(), "TestUnit")

    local stats = GetCacheStats()
    lu.assertEquals(stats.hits, 1)
    lu.assertEquals(stats.misses, 0)
    lu.assertEquals(stats.units, 1)

    -- Test cache miss
    local notCached = _HarnessInternal.cache.getUnit("NonExistent")
    lu.assertNil(notCached)

    stats = GetCacheStats()
    lu.assertEquals(stats.hits, 1)
    lu.assertEquals(stats.misses, 1)

    -- Test removal
    RemoveUnitFromCache("TestUnit")
    cached = _HarnessInternal.cache.getUnit("TestUnit")
    lu.assertNil(cached)

    stats = GetCacheStats()
    lu.assertEquals(stats.units, 0)
    lu.assertEquals(stats.evictions, 1)
end

function TestCache:testGroupCache()
    -- Test adding group to cache
    _HarnessInternal.cache.addGroup("TestGroup", self.mockGroup)

    -- Test cache hit
    local cached = _HarnessInternal.cache.getGroup("TestGroup")
    lu.assertNotNil(cached)
    lu.assertEquals(cached:getName(), "TestGroup")

    -- Test removal
    RemoveGroupFromCache("TestGroup")
    cached = _HarnessInternal.cache.getGroup("TestGroup")
    lu.assertNil(cached)
end

function TestCache:testControllerCache()
    -- Test adding controller to cache
    _HarnessInternal.cache.addController("unit:TestUnit", self.mockController)

    -- Test cache hit
    local cached = _HarnessInternal.cache.getController("unit:TestUnit")
    lu.assertNotNil(cached)
    lu.assertEquals(cached.name, "TestController")

    -- Clear controller cache
    ClearControllerCache()
    cached = _HarnessInternal.cache.getController("unit:TestUnit")
    lu.assertNil(cached)
end

function TestCache:testCacheTTL()
    -- Set short TTL
    SetCacheConfig({ ttl = 10 })

    -- Add unit to cache
    _HarnessInternal.cache.addUnit("TestUnit", self.mockUnit)

    -- Should be cached
    lu.assertNotNil(_HarnessInternal.cache.getUnit("TestUnit"))

    -- Advance time past TTL
    self.currentTime = 1015

    -- Should be expired
    lu.assertNil(_HarnessInternal.cache.getUnit("TestUnit"))

    local stats = GetCacheStats()
    lu.assertEquals(stats.evictions, 1)
end

function TestCache:testCacheEviction()
    -- Set small cache size
    SetCacheConfig({ maxUnits = 2 })

    -- Add units to fill cache
    _HarnessInternal.cache.addUnit("Unit1", { name = "Unit1" })
    _HarnessInternal.cache.addUnit("Unit2", { name = "Unit2" })

    local stats = GetCacheStats()
    lu.assertEquals(stats.units, 2)

    -- Add third unit should evict oldest
    _HarnessInternal.cache.addUnit("Unit3", { name = "Unit3" })

    stats = GetCacheStats()
    lu.assertEquals(stats.units, 2)
    lu.assertEquals(stats.evictions, 1)

    -- Unit1 should be evicted (oldest)
    lu.assertNil(_HarnessInternal.cache.getUnit("Unit1"))
    lu.assertNotNil(_HarnessInternal.cache.getUnit("Unit2"))
    lu.assertNotNil(_HarnessInternal.cache.getUnit("Unit3"))
end

function TestCache:testCacheDecorator()
    -- Mock DCS API function
    local apiCallCount = 0
    local mockGetByName = function(name)
        apiCallCount = apiCallCount + 1
        if name == "TestUnit" then
            return self.mockUnit
        end
        return nil
    end

    -- Create cached version
    local cachedGetUnit = CacheDecorator(
        mockGetByName,
        function(name)
            return name
        end, -- Cache key is just the name
        "unit"
    )

    -- First call should hit API
    local unit = cachedGetUnit("TestUnit")
    lu.assertNotNil(unit)
    lu.assertEquals(apiCallCount, 1)

    -- Second call should hit cache
    unit = cachedGetUnit("TestUnit")
    lu.assertNotNil(unit)
    lu.assertEquals(apiCallCount, 1) -- No additional API call

    -- Different unit should hit API
    unit = cachedGetUnit("OtherUnit")
    lu.assertNil(unit)
    lu.assertEquals(apiCallCount, 2)
end

function TestCache:testConvenienceFunctions()
    -- Add objects to cache
    _HarnessInternal.cache.addUnit("TestUnit", self.mockUnit)
    _HarnessInternal.cache.addGroup("TestGroup", self.mockGroup)
    _HarnessInternal.cache.addController("unit:TestUnit", self.mockController)

    -- Test convenience getters
    lu.assertNotNil(GetCachedUnit("TestUnit"))
    lu.assertNotNil(GetCachedGroup("TestGroup"))
    lu.assertNotNil(GetCachedController("unit:TestUnit"))

    -- Test non-existent
    lu.assertNil(GetCachedUnit("NonExistent"))
    lu.assertNil(GetCachedGroup("NonExistent"))
    lu.assertNil(GetCachedController("NonExistent"))
end

function TestCache:testGetCacheTables()
    -- Add some objects
    _HarnessInternal.cache.addUnit("TestUnit", self.mockUnit)
    _HarnessInternal.cache.addGroup("TestGroup", self.mockGroup)

    -- Get direct access to tables
    local tables = GetCacheTables()
    lu.assertNotNil(tables.units)
    lu.assertNotNil(tables.groups)
    lu.assertNotNil(tables.controllers)
    lu.assertNotNil(tables.airbases)

    -- Verify we can access cached objects directly
    lu.assertNotNil(tables.units["TestUnit"])
    lu.assertNotNil(tables.groups["TestGroup"])
end

function TestCache:testClearFunctions()
    -- Add objects to all caches
    _HarnessInternal.cache.addUnit("TestUnit", self.mockUnit)
    _HarnessInternal.cache.addGroup("TestGroup", self.mockGroup)
    _HarnessInternal.cache.addController("unit:TestUnit", self.mockController)

    -- Verify they're cached
    local stats = GetCacheStats()
    lu.assertEquals(stats.units, 1)
    lu.assertEquals(stats.groups, 1)
    lu.assertEquals(stats.controllers, 1)

    -- Clear individual caches
    ClearUnitCache()
    stats = GetCacheStats()
    lu.assertEquals(stats.units, 0)
    lu.assertEquals(stats.groups, 1)
    lu.assertEquals(stats.controllers, 1)

    ClearGroupCache()
    stats = GetCacheStats()
    lu.assertEquals(stats.groups, 0)
    lu.assertEquals(stats.controllers, 1)

    ClearControllerCache()
    stats = GetCacheStats()
    lu.assertEquals(stats.controllers, 0)
end

function TestCache:testSetCacheConfig()
    -- Test setting configuration
    SetCacheConfig({
        maxUnits = 500,
        maxGroups = 250,
        maxControllers = 300,
        ttl = 600,
    })

    lu.assertEquals(_HarnessInternal.cache.config.maxUnits, 500)
    lu.assertEquals(_HarnessInternal.cache.config.maxGroups, 250)
    lu.assertEquals(_HarnessInternal.cache.config.maxControllers, 300)
    lu.assertEquals(_HarnessInternal.cache.config.ttl, 600)

    -- Test invalid config
    SetCacheConfig("invalid") -- Should log error but not crash
    SetCacheConfig({ maxUnits = "invalid" }) -- Should ignore invalid values
end
