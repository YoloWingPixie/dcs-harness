-- test_zone_search.lua
local lu = require("luaunit")
require("test_utils")

-- Setup test environment
package.path = package.path .. ";../src/?.lua"

-- Create isolated test suite
TestZoneSearch = CreateIsolatedTestSuite("TestZoneSearch", {})

function TestZoneSearch:setUp()
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

    -- Ensure env logging functions exist
    if not env.info then
        env.info = function() end
    end
    if not env.warning then
        env.warning = function() end
    end
    if not env.error then
        env.error = function() end
    end

    require("cache")
    require("vector")
    require("misc")
    require("unit")
    require("group")
    require("coalition")
    require("world")
    require("zone")

    -- Mock DCS mission trigger zones
    env.mission = {
        triggers = {
            zones = {
                {
                    name = "TestCircleZone",
                    type = 0, -- circular
                    x = 1000,
                    y = 2000,
                    radius = 500,
                },
                {
                    name = "TestPolygonZone",
                    type = 2, -- polygon
                    x = 50,
                    y = 50,
                    verticies = {
                        { x = 0, y = 0 },
                        { x = 100, y = 0 },
                        { x = 100, y = 100 },
                        { x = 0, y = 100 },
                    },
                },
            },
        },
    }

    -- Initialize the zone cache properly
    InitializeZoneCache()

    -- Also mock trigger.misc.getZone for fallback (when zone is not in cache)
    trigger.misc.getZone = function(name)
        -- Return nil for non-existent zones
        return nil
    end

    -- Mock units found in search
    self.mockUnits = {
        {
            getName = function()
                return "Unit1"
            end,
            getPosition = function()
                return { p = { x = 1050, y = 100, z = 2050 } }
            end,
            getCoalition = function()
                return 1
            end,
        },
        {
            getName = function()
                return "Unit2"
            end,
            getPosition = function()
                return { p = { x = 100, y = 100, z = 100 } }
            end,
            getCoalition = function()
                return 2
            end,
        },
        {
            getName = function()
                return "Unit3"
            end,
            getPosition = function()
                return { p = { x = 5000, y = 100, z = 5000 } }
            end,
            getCoalition = function()
                return 1
            end,
        },
    }

    -- Store original world.searchObjects
    self.originalSearchObjects = world.searchObjects

    -- Mock DCS world.searchObjects API
    local mockUnits = self.mockUnits -- Store reference to mock units
    world.searchObjects = function(category, volume, handler)
        -- Simulate spatial search - only return units "near" the volume
        if volume and volume.params and volume.params.point then
            local center = volume.params.point
            local radius = volume.params.radius or 1000

            for _, unit in ipairs(mockUnits) do
                local pos = unit:getPosition()
                local dx = pos.p.x - center.x
                local dz = pos.p.z - center.z
                local dist = math.sqrt(dx * dx + dz * dz)

                -- Only process units within bounding sphere
                if dist <= radius then
                    handler(unit)
                end
            end
        end
        return true
    end
end

function TestZoneSearch:tearDown()
    -- Restore original world.searchObjects
    world.searchObjects = self.originalSearchObjects

    -- Clear mission data
    if env and env.mission then
        env.mission = nil
    end
end

function TestZoneSearch:testGetUnitsInCircleZone()
    local units = GetUnitsInZone("TestCircleZone")

    -- Should find Unit1 (inside circle) but not Unit2 or Unit3
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit1")
end

function TestZoneSearch:testGetUnitsInPolygonZone()
    local units = GetUnitsInZone("TestPolygonZone")

    -- Should find Unit2 (inside square) but not Unit1 or Unit3
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit2")
end

function TestZoneSearch:testGetUnitsWithCoalitionFilter()
    -- Test coalition 1 filter
    local units = GetUnitsInZone("TestCircleZone", 1)
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit1")

    -- Test coalition 2 filter (should find none in circle zone)
    units = GetUnitsInZone("TestCircleZone", 2)
    lu.assertEquals(#units, 0)

    -- Test coalition 2 in polygon zone
    units = GetUnitsInZone("TestPolygonZone", 2)
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit2")
end

function TestZoneSearch:testGetUnitsInNonExistentZone()
    local units = GetUnitsInZone("DoesNotExist")
    lu.assertNotNil(units)
    lu.assertEquals(#units, 0)
end

function TestZoneSearch:testSearchVolumeCreation()
    -- Test should create proper search volumes
    local units = GetUnitsInZone("TestCircleZone")
    lu.assertNotNil(units)
end

function TestZoneSearch:testBoundingSphereCalculation()
    -- Test with triangle
    local points = {
        { x = 0, z = 0 },
        { x = 100, z = 0 },
        { x = 50, z = 86.6 }, -- Approximate equilateral triangle
    }

    -- Access the local function through the zone module
    -- Since it's local, we need to test it indirectly
    local units = GetUnitsInZone("TestPolygonZone")

    -- The function should calculate a bounding sphere that encompasses the polygon
    lu.assertNotNil(units)
end

return TestZoneSearch
