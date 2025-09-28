local lu = require("luaunit")

---@class GeoGridObject
---@field add fun(self: GeoGridObject, entityType: string, entityId: any, position: table)
---@field remove fun(self: GeoGridObject, entityId: any)
---@field updatePosition fun(self: GeoGridObject, entityId: any, position: table)
---@field queryRadius fun(self: GeoGridObject, position: table, radius: number, entityTypes: table): table

TestGeoGrid = {}

function TestGeoGrid:test_create_and_add()
    local grid = GeoGrid(5000, { "Track", "Battery", "SensorUnit" })
    lu.assertNotNil(grid)

    grid:add("Track", 1, { x = 100, y = 0, z = 100 })
    grid:add("Battery", 2, { x = 5200, y = 0, z = 100 })

    local res = grid:queryRadius({ x = 0, y = 0, z = 0 }, 6000, { "Track", "Battery" })
    lu.assertEquals(type(res["TrackIds"]), "table")
    lu.assertEquals(type(res["BatteryIds"]), "table")
    lu.assertTrue(res["TrackIds"][1])
    lu.assertTrue(res["BatteryIds"][2])
end

function TestGeoGrid:test_update_and_move_between_cells()
    local grid = GeoGrid(2000, { "Track" })
    grid:add("Track", "A", { x = 0, y = 0, z = 0 })

    -- Initially in cell (0,0); move to (2,0)
    grid:updatePosition("A", { x = 4100, y = 0, z = 100 })

    local resNearOld = grid:queryRadius({ x = 0, y = 0, z = 0 }, 1000, { "Track" })
    lu.assertFalse(resNearOld["TrackIds"]["A"] == true)

    local resNearNew = grid:queryRadius({ x = 4000, y = 0, z = 0 }, 1500, { "Track" })
    lu.assertTrue(resNearNew["TrackIds"]["A"])
end

function TestGeoGrid:test_remove()
    local grid = GeoGrid(3000, { "SensorUnit" })
    grid:add("SensorUnit", 7, { x = 0, y = 0, z = 0 })
    grid:remove(7)
    local res = grid:queryRadius({ x = 0, y = 0, z = 0 }, 5000, { "SensorUnit" })
    lu.assertFalse(res["SensorUnitIds"][7] == true)

    -- validate helpers
    lu.assertEquals(grid:size(), 0)
    lu.assertFalse(grid:has(7))
end

function TestGeoGrid:test_change_type_and_exact_radius_filter()
    local grid = GeoGrid(3000, { "Track", "Battery" })
    grid:add("Track", 10, { x = 0, y = 0, z = 0 })
    grid:add("Track", 11, { x = 2900, y = 0, z = 0 }) -- within 3km
    grid:add("Track", 12, { x = 3100, y = 0, z = 0 }) -- just outside 3km

    -- Exact radius 3000 should include 10,11 but not 12
    local res = grid:queryRadius({ x = 0, y = 0, z = 0 }, 3000, { "Track" })
    lu.assertTrue(res["TrackIds"][10])
    lu.assertTrue(res["TrackIds"][11])
    lu.assertFalse(res["TrackIds"][12] == true)

    -- change type of 11
    lu.assertTrue(grid:changeType(11, "Battery"))
    local res2 = grid:queryRadius({ x = 0, y = 0, z = 0 }, 3000, { "Battery" })
    lu.assertTrue(res2["BatteryIds"][11])
end

return TestGeoGrid
