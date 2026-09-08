local lu = require("luaunit")

TestGeoGridCursor = {}

function TestGeoGridCursor:testRemovedEntriesAreReleasedWhileSearchIsPaused()
    local grid = GeoGrid(10, { "Unit" })
    grid:add("Unit", 1, Vec3())
    local cursor = grid:beginRadiusQuery(Vec3(), 0, { "Unit" }, 10)
    grid:continueRadiusQuery(cursor, 2, {})
    local retired = setmetatable({}, { __mode = "k" })
    for id = 1, 100 do
        retired[grid.idx[id]] = true
        grid:remove(id)
        grid:add("Unit", id + 1, Vec3())
    end
    collectgarbage("collect")
    lu.assertNil(next(retired))
    grid:closeRadiusQuery(cursor)
end

function TestGeoGridCursor:testCloseAndDroppingCursorReleaseQueryData()
    local grid = GeoGrid(1, { "Unit" })
    local id = {}
    local retained = setmetatable({ [id] = true }, { __mode = "k" })
    grid:add("Unit", id, Vec3())
    local cursor = grid:beginRadiusQuery(Vec3(), 1, { "Unit" }, 10)
    local output = {}
    repeat
        grid:continueRadiusQuery(cursor, 1, output)
    until #output > 0
    grid:remove(id)
    id, output[1] = nil, nil
    collectgarbage("collect")
    lu.assertNotNil(next(retained))
    grid:closeRadiusQuery(cursor)
    collectgarbage("collect")
    lu.assertNil(next(retained))
    local cursors = setmetatable({ [cursor] = true }, { __mode = "k" })
    cursor = nil
    collectgarbage("collect")
    lu.assertNil(next(cursors))
end

local function collectRadius(grid, cursor, budget)
    local output, seen, work = { "old" }, {}, 0
    for _ = 1, 10000 do
        local written, used, status = grid:continueRadiusQuery(cursor, budget, output)
        lu.assertEquals(written, #output)
        lu.assertTrue(used <= budget)
        work = work + used
        for _, id in ipairs(output) do
            lu.assertNil(seen[id], "duplicate ID")
            lu.assertTrue(grid:has(id))
            seen[id] = true
        end
        if status ~= GeoGridQueryStatus.MORE then
            return seen, status, work
        end
    end
    error("query did not finish")
end

function TestGeoGridCursor:testIndependentRadiusResultsAndCopiedInputs()
    local grid = GeoGrid(10, { "Track", "Battery" })
    local fixtures = {
        { "a", "Track", 0, 0 },
        { "b", "Track", 3, 4 },
        { "c", "Battery", -5, 0 },
        { "d", "Track", 6, 0 },
        { "e", "Track", -3, -4 },
        { "f", "Battery", 0, 0 },
    }
    local expected = {}
    for _, item in ipairs(fixtures) do
        grid:add(item[2], item[1], Vec3(item[3], 100, item[4]))
        if item[3] ^ 2 + item[4] ^ 2 <= 25 then
            expected[item[1]] = true
        end
    end
    local position, types = Vec3(), { "TrackIds", "Battery", "Track" }
    local cursor, reason = grid:beginRadiusQuery(position, 5, types, 100)
    lu.assertNil(reason)
    position.x, types[1], types[2] = 1000, "invalid", "invalid"
    local result, status = collectRadius(grid, cursor, 1)
    lu.assertEquals(result, expected)
    lu.assertEquals(status, GeoGridQueryStatus.DONE)
    lu.assertEquals(
        grid:queryRadius(Vec3(), 5, { "Track" }).TrackIds,
        { a = true, b = true, e = true }
    )
end

function TestGeoGridCursor:testEmptyCellsAndDenseBucketChargeEveryInspection()
    local empty = GeoGrid(1, { "Track" })
    local cursor = empty:beginRadiusQuery(Vec3(), 2, { "Track" }, 5)
    local result, status, work = collectRadius(empty, cursor, 1)
    lu.assertEquals(result, {})
    lu.assertEquals(status, GeoGridQueryStatus.DONE)
    lu.assertEquals(work, 25)
    local grid = GeoGrid(100, { "Track", "Battery" })
    for id = 1, 100 do
        grid:add("Track", id, Vec3(5, 0, 5))
    end
    cursor = grid:beginRadiusQuery(Vec3(1, 0, 1), 0, { "Battery", "Track" }, 1)
    result, status, work = collectRadius(grid, cursor, 1)
    lu.assertEquals(result, {})
    lu.assertEquals(work, 103)
    lu.assertEquals(status, GeoGridQueryStatus.DONE)
end

function TestGeoGridCursor:testResultLimitAndTerminalOutput()
    local grid = GeoGrid(10, { "Track" })
    for id = 1, 10 do
        grid:add("Track", id, Vec3(1, 0, 1))
    end
    local cursor = grid:beginRadiusQuery(Vec3(1, 0, 1), 0, { "Track" }, 3)
    local result, status = collectRadius(grid, cursor, 2)
    local count = 0
    for _ in pairs(result) do
        count = count + 1
    end
    lu.assertEquals(count, 3)
    lu.assertEquals(status, GeoGridQueryStatus.LIMIT)
    local output = { "old" }
    local written, work, terminal = grid:continueRadiusQuery(cursor, 20, output)
    lu.assertEquals({ written, work, terminal }, { 0, 0, GeoGridQueryStatus.LIMIT })
    lu.assertEquals(output, {})
end

function TestGeoGridCursor:testMutationsDoNotSkipStationaryMatchesOrRepeatIDs()
    local grid = GeoGrid(10, { "Track", "Battery" })
    for id = 1, 30 do
        grid:add("Track", id, Vec3(1, 0, 1))
    end
    local cursor = grid:beginRadiusQuery(Vec3(1, 0, 1), 0, { "Track" }, 100)
    local output = {}
    local written = grid:continueRadiusQuery(cursor, 3, output)
    lu.assertEquals(written, 1)
    local first = output[1]
    for id = 1, 20 do
        if id ~= first then
            grid:remove(id)
        end
    end
    grid:updatePosition(first, Vec3(50, 0, 50))
    grid:updatePosition(first, Vec3(1, 0, 1))
    grid:changeType(21, "Battery")
    grid:add("Track", "new", Vec3(1, 0, 1))
    local result, status = collectRadius(grid, cursor, 1)
    lu.assertNil(result[first])
    lu.assertNil(result[21])
    for id = 22, 30 do
        if id ~= first then
            lu.assertTrue(result[id])
        end
    end
    lu.assertEquals(status, GeoGridQueryStatus.DONE)
end

function TestGeoGridCursor:testCloseClearAndForeignCursors()
    local grid, other = GeoGrid(10, { "Track" }), GeoGrid(10, { "Track" })
    grid:add("Track", 1, Vec3())
    local cursor = grid:beginRadiusQuery(Vec3(), 1, { "Track" }, 10)
    local output = { "old" }
    local written, work, status = other:continueRadiusQuery(cursor, 1, output)
    lu.assertEquals({ written, work, status }, { 0, 0, GeoGridQueryStatus.INVALID })
    lu.assertEquals(output, {})
    grid:closeRadiusQuery(cursor)
    grid:closeRadiusQuery(cursor)
    lu.assertEquals(
        select(3, grid:continueRadiusQuery(cursor, 1, output)),
        GeoGridQueryStatus.CLOSED
    )
    lu.assertEquals(grid:size(), 1)
    cursor = grid:beginRadiusQuery(Vec3(), 1, { "Track" }, 10)
    grid:clear()
    lu.assertEquals(
        select(3, grid:continueRadiusQuery(cursor, 1, output)),
        GeoGridQueryStatus.CLOSED
    )
    lu.assertEquals(grid:size(), 0)
end

function TestGeoGridCursor:testInvalidInputsZeroBudgetAndLazyCreation()
    local grid = GeoGrid(10, { "Track" })
    local invalid = {
        { {}, 1, { "Track" }, 1 },
        { Vec3(math.huge, 0, 0), 1, { "Track" }, 1 },
        { Vec3(), -1, { "Track" }, 1 },
        { Vec3(), 0 / 0, { "Track" }, 1 },
        { Vec3(), math.huge, { "Track" }, 1 },
        { Vec3(), 1, { "Other" }, 1 },
        { Vec3(), 1, { [2] = "Track" }, 1 },
        { Vec3(), 1, { false }, 1 },
        { Vec3(), 1, "Track", 1 },
        { Vec3(), 1, { "Track" }, 0 },
        { Vec3(), 1, { "Track" }, 1.5 },
        { Vec3(), 1, { "Track" }, math.huge },
        { Vec3(1e308, 0, 0), 1, { "Track" }, 1 },
    }
    for _, arguments in ipairs(invalid) do
        local cursor, reason = grid:beginRadiusQuery(unpack(arguments))
        lu.assertNil(cursor)
        lu.assertIsString(reason)
    end
    setmetatable(grid.grid, {
        __index = function()
            error("eager cell lookup")
        end,
    })
    local cursor = grid:beginRadiusQuery(Vec3(), 1, { "Track" }, 5)
    setmetatable(grid.grid, nil)
    local output = { "old" }
    lu.assertEquals(
        { grid:continueRadiusQuery(cursor, 0, output) },
        { 0, 0, GeoGridQueryStatus.MORE }
    )
    lu.assertEquals(output, {})
    for _, budget in ipairs({ -1, 0.5, "1", false, 0 / 0, math.huge }) do
        output[1] = "old"
        lu.assertEquals(
            { grid:continueRadiusQuery(cursor, budget, output) },
            { 0, 0, GeoGridQueryStatus.INVALID }
        )
        lu.assertEquals(output, {})
    end
    lu.assertEquals(select(3, grid:continueRadiusQuery({}, 1, output)), GeoGridQueryStatus.INVALID)
    lu.assertEquals(
        select(3, grid:continueRadiusQuery(cursor, 1, false)),
        GeoGridQueryStatus.INVALID
    )
    cursor = grid:beginRadiusQuery(Vec3(), 1, {}, 5)
    lu.assertEquals(select(3, grid:continueRadiusQuery(cursor, 0, output)), GeoGridQueryStatus.DONE)
end
