-- test_zone_cache.lua
local lu = require('luaunit')
require('test_utils')

-- Setup test environment
package.path = package.path .. ';../src/?.lua'

-- Create isolated test suite
TestZoneCache = CreateIsolatedTestSuite('TestZoneCache', {})

function TestZoneCache:setUp()
    -- Load required modules in clean environment
    require('mock_dcs')
    require('_header')
    
    -- Ensure _HarnessInternal has required fields before loading logger
    if not _HarnessInternal.loggers then
        _HarnessInternal.loggers = {}
    end
    if not _HarnessInternal.defaultNamespace then
        _HarnessInternal.defaultNamespace = "Harness"
    end
    
    require('logger')
    
    -- Ensure internal logger is created
    if not _HarnessInternal.log then
        _HarnessInternal.log = HarnessLogger("Harness")
    end
    
    -- Mock logger functions to suppress output during tests
    self:mock("_HarnessInternal.log.info", function() end)
    self:mock("_HarnessInternal.log.error", function() end)
    self:mock("_HarnessInternal.log.warning", function() end)
    self:mock("_HarnessInternal.log.debug", function() end)
    
    -- Load other required modules
    require('cache')
    require('misc')
    require('vector')
    require('unit')
    require('group')
    require('coalition')
    require('zone')
    
    -- No need to override IsVec3 - we'll provide proper 3D points in our test data
    
    -- Mock mission data with trigger zones
    env = {
        mission = {
            triggers = {
                zones = {
                    {
                        name = "TEST_ZONE_1",
                        zoneId = 1,
                        type = 0,  -- circular
                        x = 1000,
                        y = 2000,  -- Note: this is z in DCS
                        radius = 500,
                        hidden = false,
                        color = {1, 1, 1, 0.15}
                    },
                    {
                        name = "TEST_ZONE_2",
                        zoneId = 2,
                        type = 2,  -- polygon
                        x = 0,
                        y = 0,
                        hidden = false,
                        verticies = {
                            {x = 0, y = 0},
                            {x = 100, y = 0},
                            {x = 100, y = 100},
                            {x = 0, y = 100}
                        }
                    },
                    {
                        name = "MOVING_ZONE",
                        zoneId = 3,
                        type = 0,
                        x = 0,
                        y = 0,
                        radius = 100,
                        linkUnit = 123,  -- This zone should be ignored
                        hidden = false
                    }
                }
            }
        }
    }
    
    -- Clear cache
    ClearZoneCache()
end

function TestZoneCache:testInitialize()
    local success = InitializeZoneCache()
    lu.assertTrue(success)
    
    -- Check that moving zone was filtered out
    local allZones = GetAllZones()
    lu.assertEquals(#allZones, 2)
end

function TestZoneCache:testGetByName()
    InitializeZoneCache()
    
    local zone = GetCachedZoneByName("TEST_ZONE_1")
    lu.assertNotNil(zone)
    lu.assertEquals(zone.name, "TEST_ZONE_1")
    lu.assertEquals(zone.type, "circle")
    lu.assertEquals(zone.radius, 500)
    lu.assertEquals(zone.center.x, 1000)
    lu.assertEquals(zone.center.z, 2000)  -- y converted to z
end

function TestZoneCache:testGetById()
    InitializeZoneCache()
    
    local zone = GetCachedZoneById(2)
    lu.assertNotNil(zone)
    lu.assertEquals(zone.name, "TEST_ZONE_2")
    lu.assertEquals(zone.type, "polygon")
    lu.assertEquals(#zone.points, 4)
end

function TestZoneCache:testFindByName()
    InitializeZoneCache()
    
    local zones = FindZonesByName("TEST")
    lu.assertEquals(#zones, 2)
    
    zones = FindZonesByName("ZONE_1")
    lu.assertEquals(#zones, 1)
    lu.assertEquals(zones[1].name, "TEST_ZONE_1")
end

function TestZoneCache:testGetByType()
    InitializeZoneCache()
    
    local circles = GetZonesByType("circle")
    lu.assertEquals(#circles, 1)
    lu.assertEquals(circles[1].name, "TEST_ZONE_1")
    
    local polygons = GetZonesByType("polygon")
    lu.assertEquals(#polygons, 1)
    lu.assertEquals(polygons[1].name, "TEST_ZONE_2")
end

function TestZoneCache:testPointInZone()
    InitializeZoneCache()
    
    local zone = GetCachedZoneByName("TEST_ZONE_1")
    
    -- Point at center
    lu.assertTrue(IsPointInZoneGeometry(zone, {x = 1000, z = 2000}))
    
    -- Point inside
    lu.assertTrue(IsPointInZoneGeometry(zone, {x = 1200, z = 2000}))
    
    -- Point outside
    lu.assertFalse(IsPointInZoneGeometry(zone, {x = 2000, z = 2000}))
    
    -- Test polygon zone
    local polyZone = GetCachedZoneByName("TEST_ZONE_2")
    
    -- Point inside square
    lu.assertTrue(IsPointInZoneGeometry(polyZone, {x = 50, z = 50}))
    
    -- Point outside square
    lu.assertFalse(IsPointInZoneGeometry(polyZone, {x = 150, z = 50}))
end

-- Test that runtime API still works
function TestZoneCache:testRuntimeAPI()
    -- Mock trigger.misc.getZone
    trigger.misc.getZone = function(name)
        if name == "RuntimeZone" then
            return {
                point = {x = 100, y = 0, z = 200},
                radius = 300
            }
        end
        error("Zone not found")
    end
    
    -- Test runtime API
    local zone = GetZone("RuntimeZone")
    lu.assertNotNil(zone)
    lu.assertEquals(zone.radius, 300)
    
    local pos = GetZonePosition("RuntimeZone")
    lu.assertNotNil(pos)
    lu.assertEquals(pos.x, 100)
    lu.assertEquals(pos.z, 200)
    
    local radius = GetZoneRadius("RuntimeZone")
    lu.assertEquals(radius, 300)
end

return TestZoneCache