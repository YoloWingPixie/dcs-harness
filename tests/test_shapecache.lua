-- test_shapecache.lua
local lu = require('luaunit')

-- Setup test environment
package.path = package.path .. ';../src/?.lua'
require('mock_dcs')
require('_header')
require('logger')
require('misc')
require('unit')
require('group')
require('coalition')
require('world')
require('drawing')
require('zone')
require('shapecache')

TestShapeCache = {}

function TestShapeCache:setUp()
    -- Save original mission if it exists
    self.originalMission = env.mission
    
    -- Mock DCS mission data with drawings and trigger zones
    env.mission = {
            drawings = {
                layers = {
                    {
                        name = "Author",
                        objects = {
                            {
                                name = "TEST_DISK",
                                primitiveType = "Polygon",
                                polygonMode = "circle",
                                visible = true,
                                layerName = "Author",
                                mapX = -359172.51,
                                mapY = 298863.28,
                                radius = 37426.79,
                                colorString = "0xff0000ff",
                                fillColorString = "0xff000080"
                            },
                            {
                                name = "TEST_SEGMENTS",
                                primitiveType = "Line",
                                lineMode = "segments",
                                closed = false,
                                visible = true,
                                layerName = "Author",
                                mapX = -329428.57,
                                mapY = 433714.29,
                                points = {
                                    {x = 0, y = 0},
                                    {x = 2000, y = 571.43},
                                    {x = 55142.86, y = 27428.57},
                                    {x = 7428.57, y = 84857.14}
                                }
                            },
                            {
                                name = "TEST_POLYGON_FREE",
                                primitiveType = "Polygon",
                                polygonMode = "free",
                                visible = true,
                                layerName = "Author",
                                mapX = -494114.13,
                                mapY = 394132.63,
                                points = {
                                    {x = 0, y = 0},
                                    {x = 7263.94, y = 9219.61},
                                    {x = 15645.41, y = 24865.02},
                                    {x = 22071.20, y = 36040.31},
                                    {x = 24585.64, y = 39392.90}
                                }
                            }
                        }
                    }
                }
            },
            triggers = {
                zones = {
                    {
                        name = "TEST_CIRCULAR_TRIGGER_ZONE",
                        zoneId = 165,
                        type = 0,  -- circular
                        x = -360569.42,
                        y = 185434.09,  -- Note: this is z in DCS
                        radius = 3000,
                        hidden = false,
                        color = {1, 1, 1, 0.15}
                    },
                    {
                        name = "TEST_QUADPOINT_TRIGGER_ZONE",
                        zoneId = 166,
                        type = 2,  -- quadpoint
                        x = -396819.27,
                        y = 213827.99,
                        hidden = false,
                        verticies = {
                            {x = -399050.97, y = 196123.82},
                            {x = -424547.95, y = 216166.14},
                            {x = -370627.18, y = 246898.19},
                            {x = -393050.97, y = 196123.82}
                        }
                    },
                    {
                        name = "MOVING_ZONE",
                        zoneId = 167,
                        type = 0,
                        x = 0,
                        y = 0,
                        radius = 1000,
                        linkUnit = 123,  -- This zone should be ignored
                        hidden = false
                    }
                }
            }
        }
    
    -- Clear caches
    ClearShapeCache()
end

function TestShapeCache:testInitialize()
    local success = InitializeShapeCache()
    lu.assertTrue(success)
    
    -- Check statistics
    local stats = GetShapeStatistics()
    lu.assertEquals(stats.drawings.total, 3)
    lu.assertEquals(stats.triggerZones.total, 2)  -- Moving zone should be ignored
end

function TestShapeCache:testGetAllShapes()
    InitializeShapeCache()
    local shapes = GetAllShapes()
    
    lu.assertNotNil(shapes.drawings)
    lu.assertNotNil(shapes.triggerZones)
    lu.assertEquals(#shapes.drawings, 3)
    lu.assertEquals(#shapes.triggerZones, 2)
end

function TestShapeCache:testFindByName()
    InitializeShapeCache()
    
    -- Find by partial name
    local results = FindShapesByName("TEST")
    lu.assertEquals(#results.drawings, 3)
    lu.assertEquals(#results.triggerZones, 2)
    
    -- Find specific pattern
    results = FindShapesByName("DISK")
    lu.assertEquals(#results.drawings, 1)
    lu.assertEquals(#results.triggerZones, 0)
    
    results = FindShapesByName("TRIGGER")
    lu.assertEquals(#results.drawings, 0)
    lu.assertEquals(#results.triggerZones, 2)
end

function TestShapeCache:testGetByExactName()
    InitializeShapeCache()
    
    -- Get drawing
    local shape = GetShapeByName("TEST_DISK")
    lu.assertNotNil(shape)
    lu.assertEquals(shape.shapeType, "drawing")
    lu.assertEquals(shape.type, "Polygon")
    lu.assertEquals(shape.polygonMode, "circle")
    lu.assertAlmostEquals(shape.radius, 37426.79, 0.01)
    
    -- Get trigger zone
    shape = GetShapeByName("TEST_CIRCULAR_TRIGGER_ZONE")
    lu.assertNotNil(shape)
    lu.assertEquals(shape.shapeType, "triggerZone")
    lu.assertEquals(shape.type, "circle")
    lu.assertEquals(shape.radius, 3000)
    
    -- Non-existent shape
    shape = GetShapeByName("DOES_NOT_EXIST")
    lu.assertNil(shape)
end

function TestShapeCache:testCircularShapes()
    InitializeShapeCache()
    
    local circles = GetAllCircularShapes()
    lu.assertEquals(#circles, 2)  -- 1 drawing + 1 trigger zone
    
    -- Check we have both types
    local hasDrawing = false
    local hasZone = false
    for _, circle in ipairs(circles) do
        if circle.shapeType == "drawing" then
            hasDrawing = true
            lu.assertEquals(circle.name, "TEST_DISK")
        elseif circle.shapeType == "triggerZone" then
            hasZone = true
            lu.assertEquals(circle.name, "TEST_CIRCULAR_TRIGGER_ZONE")
        end
    end
    
    lu.assertTrue(hasDrawing)
    lu.assertTrue(hasZone)
end

function TestShapeCache:testPolygonShapes()
    InitializeShapeCache()
    
    local polygons = GetAllPolygonShapes()
    lu.assertEquals(#polygons, 2)  -- 1 free polygon + 1 quadpoint zone
    
    -- Check types
    local hasDrawing = false
    local hasZone = false
    for _, poly in ipairs(polygons) do
        if poly.shapeType == "drawing" then
            hasDrawing = true
            lu.assertEquals(poly.name, "TEST_POLYGON_FREE")
        elseif poly.shapeType == "triggerZone" then
            hasZone = true
            lu.assertEquals(poly.name, "TEST_QUADPOINT_TRIGGER_ZONE")
        end
    end
    
    lu.assertTrue(hasDrawing)
    lu.assertTrue(hasZone)
end

function TestShapeCache:testPointInShape()
    InitializeShapeCache()
    
    -- Test point in circular drawing
    local pointInDisk = {x = -359172.51, z = 298863.28}  -- Center of disk
    local pointOutsideDisk = {x = -300000, z = 298863.28}  -- Far outside
    
    local shapesAtPoint = GetShapesAtPoint(pointInDisk)
    lu.assertEquals(#shapesAtPoint, 1)
    lu.assertEquals(shapesAtPoint[1].name, "TEST_DISK")
    
    shapesAtPoint = GetShapesAtPoint(pointOutsideDisk)
    local foundDisk = false
    for _, shape in ipairs(shapesAtPoint) do
        if shape.name == "TEST_DISK" then
            foundDisk = true
        end
    end
    lu.assertFalse(foundDisk)
    
    -- Test point in circular trigger zone
    local pointInZone = {x = -360569.42, z = 185434.09}  -- Center of zone
    shapesAtPoint = GetShapesAtPoint(pointInZone)
    local foundZone = false
    for _, shape in ipairs(shapesAtPoint) do
        if shape.name == "TEST_CIRCULAR_TRIGGER_ZONE" then
            foundZone = true
        end
    end
    lu.assertTrue(foundZone)
    
    -- Test specific shape check
    shapesAtPoint = GetShapesAtPoint(pointInDisk, "TEST_DISK")
    lu.assertEquals(#shapesAtPoint, 1)
    
    shapesAtPoint = GetShapesAtPoint(pointInDisk, "WRONG_NAME")
    lu.assertEquals(#shapesAtPoint, 0)
end

function TestShapeCache:testDrawingGeometry()
    InitializeShapeCache()
    
    -- Test line drawing
    local line = GetDrawingByName("TEST_SEGMENTS")
    lu.assertNotNil(line)
    lu.assertEquals(line.type, "Line")
    lu.assertEquals(line.lineMode, "segments")
    lu.assertFalse(line.closed)
    lu.assertEquals(#line.points, 4)
    
    -- Check points are converted to world coordinates
    lu.assertAlmostEquals(line.points[1].x, -329428.57, 0.01)
    lu.assertAlmostEquals(line.points[1].z, 433714.29, 0.01)
    lu.assertAlmostEquals(line.points[2].x, -327428.57, 0.01)  -- -329428.57 + 2000
end

function TestShapeCache:testTriggerZoneGeometry()
    InitializeShapeCache()
    
    -- Test polygon zone
    local zone = GetCachedZoneByName("TEST_QUADPOINT_TRIGGER_ZONE")
    lu.assertNotNil(zone)
    lu.assertEquals(zone.type, "polygon")
    lu.assertEquals(#zone.points, 4)
    
    -- Check coordinate conversion (mission y -> DCS z)
    lu.assertAlmostEquals(zone.points[1].x, -399050.97, 0.01)
    lu.assertAlmostEquals(zone.points[1].z, 196123.82, 0.01)
    lu.assertEquals(zone.points[1].y, 0)  -- Ground level
end


function TestShapeCache:tearDown()
    -- Restore original mission
    env.mission = self.originalMission
end

function TestShapeCache:testUnitsInShape()
    InitializeShapeCache()
    
    -- Mock some units
    local mockUnits = {
        {
            getName = function() return "Unit1" end,
            getPosition = function() return {
                p = {x = -360569.42, y = 100, z = 185434.09}  -- In trigger zone
            } end,
            getCoalition = function() return 1 end
        },
        {
            getName = function() return "Unit2" end,
            getPosition = function() return {
                p = {x = -359172.51, y = 100, z = 298863.28}  -- In drawing
            } end,
            getCoalition = function() return 2 end
        }
    }
    
    -- Store original world.searchObjects
    local originalSearchObjects = world.searchObjects
    
    -- Mock DCS world.searchObjects API
    world.searchObjects = function(category, volume, handler)
        -- Simulate spatial search - only return units "near" the volume
        if volume and volume.params and volume.params.point then
            local center = volume.params.point
            local radius = volume.params.radius or 1000000  -- Large default radius
            
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
    
    -- Test units in trigger zone
    local units = GetUnitsInShape("TEST_CIRCULAR_TRIGGER_ZONE")
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit1")
    
    -- Test units in drawing
    units = GetUnitsInShape("TEST_DISK")
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit2")
    
    -- Restore original world.searchObjects
    world.searchObjects = originalSearchObjects
end

function TestShapeCache:testAutoInitialize()
    -- Should work when mission exists
    local success = AutoInitializeShapeCache()
    lu.assertTrue(success)
    
    -- Test without mission
    env.mission = nil
    ClearShapeCache()
    success = AutoInitializeShapeCache()
    lu.assertFalse(success)
end

return TestShapeCache