-- Test Runner for Harness
-- This loads all test files and runs them with LuaUnit

local separator = package.config:sub(1, 1) -- Gets the directory separator
package.path = "." .. separator .. "tests" .. separator .. "?.lua;" .. package.path

-- Add src directory to path so module requires from src/ resolve during preloads
package.path = ".." .. separator .. "src" .. separator .. "?.lua;" .. package.path

-- Add luaunit directory to path so we can require the vendored luaunit (must take precedence)
package.path = ".." .. separator .. "luaunit" .. separator .. "?.lua;" .. package.path

-- Load LuaUnit
local lu = require("luaunit")

-- Load test utilities for isolation
require("test_utils")

-- Load mock DCS environment
require("mock_dcs")

-- Initialize Harness internal structure (mimicking _header.lua)
HARNESS_VERSION = "1.0.0-test"
_HarnessInternal = {
    loggers = {},
    defaultNamespace = "Harness",
}

-- Ensure cache structure exists (mimic _header.lua)
if not _HarnessInternal.cache then
    _HarnessInternal.cache = {
        units = {},
        groups = {},
        controllers = {},
        airbases = {},
        stats = { hits = 0, misses = 0, evictions = 0 },
    }
end

-- Load all Harness modules
-- We need to load them in dependency order
dofile("../src/logger.lua")
dofile("../src/cache.lua")
dofile("../src/namespace.lua")
dofile("../src/datastructures.lua")
dofile("../src/vector.lua")
dofile("../src/geomath.lua")
dofile("../src/misc.lua")
dofile("../src/coord.lua")
dofile("../src/terrain.lua")
dofile("../src/conversion.lua")
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
-- project extras
dofile("../src/geogrid.lua")

-- Dynamically load all test_*.lua files in the tests directory (excluding this runner)
local function listTestModules()
    local modules = {}
    local sep = package.config:sub(1, 1)
    local testsDir = "." -- this script runs from tests/ as CWD

    -- Prefer LuaFileSystem if available
    local ok, lfs = pcall(require, "lfs")
    if ok and lfs and lfs.dir then
        for file in lfs.dir(testsDir) do
            if
                type(file) == "string"
                and file:match("^test_.*%.lua$")
                and file ~= "test_runner.lua"
            then
                table.insert(modules, (file:gsub("%.lua$", "")))
            end
        end
    else
        -- Fallback: use OS directory listing
        local cmd
        if sep == "\\" then
            cmd = 'cmd /c dir /b "' .. testsDir .. '\\test_*.lua"'
        else
            cmd = 'sh -c "ls ' .. testsDir .. '/test_*.lua 2>/dev/null"'
        end
        local p = io.popen(cmd)
        if p then
            for line in p:lines() do
                local name = line
                -- Normalize to filename only
                if sep == "\\" then
                    name = name:match("([^\\/]+)$") or name
                else
                    name = name:match("([^/]+)$") or name
                end
                if name ~= "test_runner.lua" and name:match("^test_.*%.lua$") then
                    table.insert(modules, (name:gsub("%.lua$", "")))
                end
            end
            p:close()
        end
    end
    table.sort(modules)
    return modules
end

for _, mod in ipairs(listTestModules()) do
    require(mod)
end

-- Run all tests
os.exit(lu.LuaUnit.run())
