-- Test Runner for Harness
-- This loads all test files and runs them with LuaUnit

-- Add test directory to path (platform-independent)
local separator = package.config:sub(1,1)  -- Gets the directory separator
package.path = package.path .. ";" .. "." .. separator .. "tests" .. separator .. "?.lua"

-- Add src directory to path so module requires from src/ resolve during preloads
package.path = package.path .. ";" .. ".." .. separator .. "src" .. separator .. "?.lua"

-- Load LuaUnit
local lu = require('luaunit')

-- Load test utilities for isolation
require('test_utils')

-- Load mock DCS environment
require('mock_dcs')

-- Initialize Harness internal structure (mimicking _header.lua)
HARNESS_VERSION = "1.0.0-test"
_HarnessInternal = {
    loggers = {},
    defaultNamespace = "Harness"
}

-- Ensure cache structure exists (mimic _header.lua)
if not _HarnessInternal.cache then
    _HarnessInternal.cache = {
        units = {},
        groups = {},
        controllers = {},
        airbases = {},
        stats = { hits = 0, misses = 0, evictions = 0 }
    }
end

-- Load all Harness modules
-- We need to load them in dependency order
dofile("../src/logger.lua")
dofile("../src/cache.lua")
dofile("../src/datastructures.lua")
dofile("../src/vector.lua")
dofile("../src/geomath.lua")
dofile("../src/misc.lua")
dofile("../src/coord.lua")
dofile("../src/terrain.lua")
dofile("../src/time.lua")
dofile("../src/flag.lua")
dofile("../src/zone.lua")
dofile("../src/unit.lua")
dofile("../src/group.lua")
dofile("../src/airbase.lua")
dofile("../src/atmosphere.lua")
dofile("../src/coalition.lua")
dofile("../src/staticobject.lua")
dofile("../src/weapon.lua")
dofile("../src/world.lua")
dofile("../src/controller.lua")
dofile("../src/trigger.lua")
dofile("../src/missioncommands.lua")
dofile("../src/shapes.lua")
dofile("../src/vectorops.lua")
dofile("../src/spot.lua")
dofile("../src/net.lua")
dofile("../src/drawing.lua")
dofile("../src/shapecache.lua")

-- Load all test files
require('test_logger')
require('test_datastructures')
require('test_vector')
require('test_misc')
require('test_time')
require('test_flag')
require('test_coord')
require('test_terrain')
require('test_zone')
require('test_unit')
require('test_group')
require('test_spot')
require('test_net')
require('test_trigger')
require('test_unit_group_advanced_simple')
require('test_cache')
require('test_zone_cache')
require('test_zone_search')
require('test_drawing_search')
require('test_shapecache')
require('test_shapes')

-- Run all tests
os.exit(lu.LuaUnit.run())