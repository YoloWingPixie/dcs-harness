-- test_drawing_search.lua
local lu = require('luaunit')
require('test_utils')

-- Setup test environment
package.path = package.path .. ';../src/?.lua'

-- Create isolated test suite
TestDrawingSearch = CreateIsolatedTestSuite('TestDrawingSearch', {})

function TestDrawingSearch:setUp()
    -- Load required modules
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
    
    require('cache')
    require('misc')
    require('unit')
    require('group')
    require('coalition')
    require('world')
    require('drawing')
    
    -- Save original mission if it exists
    self.originalMission = env.mission
    
    -- Mock DCS mission drawings
    env.mission = {
        drawings = {
            layers = {
                {
                    name = "Test Layer",
                    objects = {
                        {
                            name = "TestCircle",
                            primitiveType = "Polygon",
                            polygonMode = "circle",
                            mapX = 1000,
                            mapY = 2000,
                            radius = 500
                        },
                        {
                            name = "TestRect",
                            primitiveType = "Polygon", 
                            polygonMode = "rect",
                            mapX = -1000,
                            mapY = -1000,
                            width = 200,
                            height = 100
                        },
                        {
                            name = "TestPolygon",
                            primitiveType = "Polygon",
                            polygonMode = "free",
                            mapX = 0,
                            mapY = 0,
                            points = {
                                {x = 0, y = 0},
                                {x = 100, y = 0},
                                {x = 100, y = 100},
                                {x = 0, y = 100}
                            }
                        },
                        {
                            name = "TestClosedLine",
                            primitiveType = "Line",
                            closed = true,
                            mapX = 2000,
                            mapY = 2000,
                            points = {
                                {x = 0, y = 0},
                                {x = 100, y = 0},
                                {x = 50, y = 100}
                            }
                        }
                    }
                }
            }
        }
    }
    
    -- Initialize the drawing cache properly
    InitializeDrawingCache()
    
    -- Mock units
    self.mockUnits = {
        {
            getName = function() return "Unit1" end,
            getPosition = function() return {p = {x = 1050, y = 100, z = 2050}} end,
            getCoalition = function() return 1 end
        },
        {
            getName = function() return "Unit2" end,
            getPosition = function() return {p = {x = -1000, y = 100, z = -1000}} end,
            getCoalition = function() return 2 end
        },
        {
            getName = function() return "Unit3" end,
            getPosition = function() return {p = {x = 50, y = 100, z = 50}} end,
            getCoalition = function() return 1 end
        },
        {
            getName = function() return "Unit4" end,
            getPosition = function() return {p = {x = 2050, y = 100, z = 2050}} end,
            getCoalition = function() return 2 end
        }
    }
    
    -- Store original world.searchObjects
    self.originalSearchObjects = world.searchObjects
    
    -- Mock DCS world.searchObjects API
    local mockUnits = self.mockUnits  -- Store reference to mock units
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

function TestDrawingSearch:tearDown()
    -- Restore original world.searchObjects
    world.searchObjects = self.originalSearchObjects
    
    -- Restore original mission
    env.mission = self.originalMission
end

function TestDrawingSearch:testGetUnitsInCircleDrawing()
    local units = GetUnitsInDrawing("TestCircle")
    
    -- Should find Unit1 inside the circle
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit1")
end

function TestDrawingSearch:testGetUnitsInRectDrawing()
    local units = GetUnitsInDrawing("TestRect")
    
    -- Should find Unit2 inside the rectangle
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit2")
end

function TestDrawingSearch:testGetUnitsInPolygonDrawing()
    local units = GetUnitsInDrawing("TestPolygon")
    
    -- Should find Unit3 inside the polygon
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit3")
end

function TestDrawingSearch:testGetUnitsInClosedLine()
    local units = GetUnitsInDrawing("TestClosedLine")
    
    -- Debug info
    print("DEBUG: GetUnitsInDrawing('TestClosedLine') returned", #units, "units")
    for i, unit in ipairs(units) do
        print("  Unit", i, ":", unit:getName())
    end
    
    -- Should find Unit4 inside the closed line triangle
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit4")
end

function TestDrawingSearch:testGetUnitsWithCoalitionFilter()
    -- Test coalition 1 filter in circle
    local units = GetUnitsInDrawing("TestCircle", 1)
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit1")
    
    -- Test coalition 2 filter in circle (should find none)
    units = GetUnitsInDrawing("TestCircle", 2)
    lu.assertEquals(#units, 0)
    
    -- Test coalition 2 in rectangle
    units = GetUnitsInDrawing("TestRect", 2)
    lu.assertEquals(#units, 1)
    lu.assertEquals(units[1]:getName(), "Unit2")
end

function TestDrawingSearch:testGetUnitsInNonExistentDrawing()
    local units = GetUnitsInDrawing("DoesNotExist")
    lu.assertNotNil(units)
    lu.assertEquals(#units, 0)
end

function TestDrawingSearch:testGetDrawingsAtPoint()
    -- Test point inside circle
    local drawings = GetDrawingsAtPoint({x = 1050, z = 2050})
    lu.assertEquals(#drawings, 1)
    lu.assertEquals(drawings[1].name, "TestCircle")
    
    -- Test point inside rectangle
    drawings = GetDrawingsAtPoint({x = -1000, z = -1000})
    lu.assertEquals(#drawings, 1)
    lu.assertEquals(drawings[1].name, "TestRect")
    
    -- Test point inside polygon
    drawings = GetDrawingsAtPoint({x = 50, z = 50})
    lu.assertEquals(#drawings, 1)
    lu.assertEquals(drawings[1].name, "TestPolygon")
    
    -- Test point outside all drawings
    drawings = GetDrawingsAtPoint({x = 10000, z = 10000})
    lu.assertEquals(#drawings, 0)
end

function TestDrawingSearch:testGetDrawingsAtPointWithTypeFilter()
    -- Add multiple overlapping drawings at origin
    table.insert(_HarnessInternal.cache.drawings.all, {
        name = "TestLine",
        type = "Line",
        closed = false,
        points = {{x = -10, z = -10}, {x = 10, z = 10}}
    })
    _HarnessInternal.cache.drawings.byType["Line"] = {{
        name = "TestLine",
        type = "Line",
        closed = false,
        points = {{x = -10, z = -10}, {x = 10, z = 10}}
    }}
    
    -- Test filtering by type
    local polygons = GetDrawingsAtPoint({x = 50, z = 50}, "Polygon")
    lu.assertEquals(#polygons, 1)
    lu.assertEquals(polygons[1].name, "TestPolygon")
    
    -- Test with type that doesn't contain the point
    local lines = GetDrawingsAtPoint({x = 50, z = 50}, "Line")
    lu.assertEquals(#lines, 0)
end

function TestDrawingSearch:testInvalidInputs()
    -- Test with nil drawing name
    local units = GetUnitsInDrawing(nil)
    lu.assertEquals(#units, 0)
    
    -- Test GetDrawingsAtPoint with invalid point
    local drawings = GetDrawingsAtPoint(nil)
    lu.assertEquals(#drawings, 0)
    
    drawings = GetDrawingsAtPoint({x = 100}) -- Missing z
    lu.assertEquals(#drawings, 0)
end

function TestDrawingSearch:testUnsupportedDrawingTypes()
    -- Test with Icon type (not searchable for units)
    _HarnessInternal.cache.drawings.byName["TestIcon"] = {
        name = "TestIcon",
        type = "Icon",
        position = {x = 0, y = 0, z = 0}
    }
    
    local units = GetUnitsInDrawing("TestIcon")
    lu.assertEquals(#units, 0)
    
    -- Test with open line (not searchable for units)
    _HarnessInternal.cache.drawings.byName["TestOpenLine"] = {
        name = "TestOpenLine",
        type = "Line",
        closed = false,
        points = {{x = 0, z = 0}, {x = 100, z = 100}}
    }
    
    units = GetUnitsInDrawing("TestOpenLine")
    lu.assertEquals(#units, 0)
end

return TestDrawingSearch