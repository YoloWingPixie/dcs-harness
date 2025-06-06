-- Test Runner for Harness
-- This loads all test files and runs them with LuaUnit

-- Add test directory to path
package.path = package.path .. ";./tests/?.lua"

-- Load LuaUnit
local lu = require('luaunit')

-- Load mock DCS environment
require('mock_dcs')

-- Initialize Harness internal structure (mimicking _header.lua)
HARNESS_VERSION = "1.0.0-test"
_HarnessInternal = {
    loggers = {},
    defaultNamespace = "Harness"
}

-- Load all Harness modules
-- We need to load them in dependency order
dofile("../src/logger.lua")
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

-- Run all tests
os.exit(lu.LuaUnit.run())