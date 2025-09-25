-- Debug test for drawing search
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

-- Initialize logger
_HarnessInternal.log = _HarnessInternal.log or {}
_HarnessInternal.log.info = function() end
_HarnessInternal.log.error = function() end
_HarnessInternal.log.warning = function() end
_HarnessInternal.log.debug = function() end

-- Mock drawing cache
_HarnessInternal.cache = {
    drawings = {
        all = {
            {
                name = "TestCircle",
                type = "Polygon",
                polygonMode = "circle",
                center = {x = 1000, y = 0, z = 2000},
                radius = 500
            }
        },
        byName = {},
        byType = {}
    }
}

-- Index by name
for _, drawing in ipairs(_HarnessInternal.cache.drawings.all) do
    _HarnessInternal.cache.drawings.byName[drawing.name] = drawing
end

-- Mock unit
local mockUnit = {
    getName = function() return "Unit1" end,
    getPosition = function() return {p = {x = 1050, y = 100, z = 2050}} end,
    getCoalition = function() return 1 end
}

-- Mock DCS world.searchObjects API
world.searchObjects = function(category, volume, handler)
    print("world.searchObjects called with:")
    print("  category:", category)
    print("  volume:", volume and volume.id or "nil")
    if volume and volume.params then
        print("  volume.params.point:", volume.params.point and (volume.params.point.x .. "," .. volume.params.point.y .. "," .. volume.params.point.z) or "nil")
        print("  volume.params.radius:", volume.params.radius)
    end
    
    -- Call handler with mock unit
    print("Calling handler with mock unit")
    local result = handler(mockUnit)
    print("Handler returned:", result)
    
    return true
end

-- Test
print("\n=== Testing GetUnitsInDrawing ===")
local units = GetUnitsInDrawing("TestCircle")
print("GetUnitsInDrawing returned", #units, "units")
for i, unit in ipairs(units) do
    print("  Unit", i, ":", unit:getName())
end