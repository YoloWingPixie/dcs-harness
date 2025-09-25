--[[
    Test Utilities - Test isolation and mock management framework
    
    Provides utilities for proper test isolation to prevent tests from
    interfering with each other through global state.
]]

-- Environment Management
local function deepCopy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    
    local s = seen or {}
    local res = {}
    s[obj] = res
    
    -- Use pcall to handle potential errors from metamethods
    local ok, err = pcall(function()
        for k, v in pairs(obj) do
            res[deepCopy(k, s)] = deepCopy(v, s)
        end
    end)
    
    if not ok then
        -- If pairs fails due to metamethods, fall back to next
        for k, v in next, obj do
            res[deepCopy(k, s)] = deepCopy(v, s)
        end
    end
    
    -- Don't copy metatables to avoid potential infinite recursion
    return res
end

-- Save current global environment state
function SaveEnvironment()
    local saved = {
        env = env and deepCopy(env) or nil,
        timer = timer,
        world = world,
        coalition = coalition,
        Unit = Unit,
        Group = Group,
        trigger = trigger,
        land = land,
        coord = coord,
        atmosphere = atmosphere,
        _HarnessInternal = _HarnessInternal and deepCopy(_HarnessInternal) or nil,
        -- Save package.loaded state
        package_loaded = {}
    }
    
    -- Save loaded module list (but not the modules themselves)
    for k, v in pairs(package.loaded) do
        saved.package_loaded[k] = true
    end
    
    return saved
end

-- Restore global environment state
function RestoreEnvironment(saved)
    -- Restore globals
    env = saved.env
    timer = saved.timer
    world = saved.world
    coalition = saved.coalition
    Unit = saved.Unit
    Group = saved.Group
    trigger = saved.trigger
    land = saved.land
    coord = saved.coord
    atmosphere = saved.atmosphere
    _HarnessInternal = saved._HarnessInternal
    
    -- Clear any modules loaded after save
    local toRemove = {}
    for k, v in pairs(package.loaded) do
        if not saved.package_loaded[k] then
            toRemove[k] = true
        end
    end
    
    for k, _ in pairs(toRemove) do
        package.loaded[k] = nil
    end
end

-- Mock Manager
MockManager = {}
MockManager.__index = MockManager

function MockManager:new()
    local instance = {
        mocks = {},
        originalFunctions = {}
    }
    setmetatable(instance, MockManager)
    return instance
end

function MockManager:mockFunction(path, mockFn)
    -- Split path (e.g., "timer.getTime" -> {"timer", "getTime"})
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end
    
    -- Navigate to parent object
    local parent = _G
    for i = 1, #parts - 1 do
        parent = parent[parts[i]]
        if not parent then
            error("Cannot mock " .. path .. " - parent does not exist")
        end
    end
    
    local funcName = parts[#parts]
    
    -- Save original
    table.insert(self.mocks, {
        parent = parent,
        name = funcName,
        original = parent[funcName]
    })
    
    -- Set mock
    parent[funcName] = mockFn
end

function MockManager:mockGlobal(name, value)
    table.insert(self.mocks, {
        parent = _G,
        name = name,
        original = _G[name]
    })
    _G[name] = value
end

function MockManager:restoreAll()
    -- Restore in reverse order
    for i = #self.mocks, 1, -1 do
        local mock = self.mocks[i]
        mock.parent[mock.name] = mock.original
    end
    self.mocks = {}
end

-- Base Test Class
HarnessTestCase = {}
HarnessTestCase.__index = HarnessTestCase

function HarnessTestCase:new(testClass)
    testClass = testClass or {}
    
    -- Save original setUp and tearDown if they exist
    local originalSetUp = testClass.setUp
    local originalTearDown = testClass.tearDown
    
    -- Create wrapper setUp that ensures framework setup runs first
    local frameworkSetUp = function(self)
        -- Save environment
        self._savedEnv = SaveEnvironment()
        self._mockManager = MockManager:new()
        
        -- Ensure mock_dcs is loaded
        if not package.loaded['mock_dcs'] then
            require('mock_dcs')
        end
        
        -- Initialize Harness internal structure
        HARNESS_VERSION = "1.0.0-test"
        _HarnessInternal = {
            loggers = {},
            defaultNamespace = "Harness"
        }
        -- Initialize minimal cache structure for tests (no production changes)
        _HarnessInternal.cache = {
            units = {},
            groups = {},
            controllers = {},
            airbases = {},
            stats = { hits = 0, misses = 0, evictions = 0 },
            config = { maxUnits = 1000, maxGroups = 500, maxControllers = 500, maxAirbases = 100, ttl = 300 }
        }
        -- Load production cache module to attach cache methods (no edits to production code)
        package.path = package.path .. ';../src/?.lua'
        if not package.loaded['logger'] then require('logger') end
        if not package.loaded['cache'] then require('cache') end
    end
    
    -- Override setUp
    testClass.setUp = function(self)
        -- Always run framework setup first
        frameworkSetUp(self)
        
        -- Call original setUp if exists
        if originalSetUp then
            originalSetUp(self)
        end
    end
    
    -- Override tearDown
    testClass.tearDown = function(self)
        -- Call original tearDown first
        if originalTearDown then
            originalTearDown(self)
        end
        
        -- Restore mocks
        if self._mockManager then
            self._mockManager:restoreAll()
        end
        
        -- Restore environment
        if self._savedEnv then
            RestoreEnvironment(self._savedEnv)
        end
    end
    
    -- Helper to reload Harness modules
    testClass.reloadHarnessModules = function(self)
        -- Clear Harness modules from cache
        local modulesToReload = {}
        for k, v in pairs(package.loaded) do
            if string.match(k, "^logger$") or
               string.match(k, "^cache$") or
               string.match(k, "^group$") or
               string.match(k, "^coalition$") or
               string.match(k, "^unit$") or
               string.match(k, "^zone$") or
               string.match(k, "^drawing$") then
                package.loaded[k] = nil
                table.insert(modulesToReload, k)
            end
        end
        
        -- Reinitialize _HarnessInternal
        _HarnessInternal = {
            loggers = {},
            defaultNamespace = "Harness"
        }
        
        -- Reload modules that were cleared
        for _, module in ipairs(modulesToReload) do
            require(module)
        end
    end
    
    -- Mock helper
    testClass.mock = function(self, path, value)
        return self._mockManager:mockFunction(path, value)
    end
    
    testClass.mockGlobal = function(self, name, value)
        return self._mockManager:mockGlobal(name, value)
    end
    
    return testClass
end

-- Helper to create isolated test suite
function CreateIsolatedTestSuite(name, testDefinitions)
    local testClass = testDefinitions or {}
    
    -- Store setUp/tearDown that will be defined later
    local userSetUp = nil
    local userTearDown = nil
    
    -- Create metatable to intercept setUp/tearDown definitions
    local mt = {
        __newindex = function(t, k, v)
            if k == "setUp" then
                userSetUp = v
                -- Don't actually set it, we'll wrap it
                rawset(t, k, function(self)
                    -- Framework setup
                    self._savedEnv = SaveEnvironment()
                    self._mockManager = MockManager:new()
                    
                    if not package.loaded['mock_dcs'] then
                        require('mock_dcs')
                    end
                    
                    HARNESS_VERSION = "1.0.0-test"
                    _HarnessInternal = {
                        loggers = {},
                        defaultNamespace = "Harness"
                    }
                    -- Initialize minimal cache structure for tests (no production changes)
                    _HarnessInternal.cache = {
                        units = {},
                        groups = {},
                        controllers = {},
                        airbases = {},
                        stats = { hits = 0, misses = 0, evictions = 0 },
                        config = { maxUnits = 1000, maxGroups = 500, maxControllers = 500, maxAirbases = 100, ttl = 300 }
                    }
                    -- Load production cache module to attach cache methods (no edits to production code)
                    package.path = package.path .. ';../src/?.lua'
                    if not package.loaded['logger'] then require('logger') end
                    if not package.loaded['cache'] then require('cache') end
                    
                    -- User setup
                    if userSetUp then
                        userSetUp(self)
                    end

                    -- After user setup (which may reset _HarnessInternal via _header),
                    -- reload cache module so its functions attach to the fresh structure
                    package.path = package.path .. ';../src/?.lua'
                    package.loaded['cache'] = nil
                    require('cache')
                end)
            elseif k == "tearDown" then
                userTearDown = v
                -- Wrap tearDown
                rawset(t, k, function(self)
                    -- User teardown first
                    if userTearDown then
                        userTearDown(self)
                    end
                    
                    -- Framework teardown
                    if self._mockManager then
                        self._mockManager:restoreAll()
                    end
                    
                    if self._savedEnv then
                        RestoreEnvironment(self._savedEnv)
                    end
                end)
            else
                rawset(t, k, v)
            end
        end
    }
    
    setmetatable(testClass, mt)
    
    -- Add helper methods
    testClass.mock = function(self, path, value)
        return self._mockManager:mockFunction(path, value)
    end
    
    testClass.mockGlobal = function(self, name, value)
        return self._mockManager:mockGlobal(name, value)
    end
    
    return testClass
end