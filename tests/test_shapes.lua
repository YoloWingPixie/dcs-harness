-- test_shapes.lua
local lu = require('luaunit')

-- Ensure src on path
package.path = package.path .. ';../src/?.lua'

require('mock_dcs')
require('logger')
require('vector')
require('geomath')
require('shapes')

TestShapes = {}

function TestShapes:testCreateCross()
    local center = {x = 0, z = 0}
    local pts = CreateCross(center, 2000, 400, 0)
    lu.assertNotNil(pts)
    lu.assertEquals(#pts, 12)
    -- Points should be Vec2-like tables
    lu.assertEquals(type(pts[1].x), 'number')
    lu.assertEquals(type(pts[1].z or pts[1].y), 'number')
end

function TestShapes:testCreatePill()
    local center = {x = 0, z = 0}
    local pts = CreatePill(center, 90, 20000, 5000, 19)
    lu.assertNotNil(pts)
    -- Two caps concatenated
    lu.assertTrue(#pts >= 38)
    -- All points should be valid Vec2
    for _, p in ipairs(pts) do
        lu.assertEquals(type(p.x), 'number')
        lu.assertEquals(type(p.z or p.y), 'number')
    end
end

function TestShapes:testCreateSpiral()
    local center = {x = 0, z = 0}
    local pts = CreateSpiral(center, 100, 1000, 3, 36)
    lu.assertNotNil(pts)
    lu.assertEquals(#pts, 3 * 36)
end

function TestShapes:testCreateRing()
    local center = {x = 0, z = 0}
    local pts = CreateRing(center, 5000, 3000, 36)
    lu.assertNotNil(pts)
    -- Outer (36) + connector (1) + inner (36) + close (1)
    lu.assertEquals(#pts, 36 + 1 + 36 + 1)
end

return TestShapes
