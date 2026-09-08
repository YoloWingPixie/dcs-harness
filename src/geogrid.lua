--[[
==================================================================================================
    GEOGRID MODULE
    Spatial grid for indexing and querying entities by position
==================================================================================================
]]

---@class GeoGridLocation
---@field cx integer
---@field cz integer
---@field type string
---@field bucket string
---@field p { x: number, y: number, z: number }
---@field id any
---@field previous GeoGridLocation?
---@field next GeoGridLocation?
---@field chain table?

---@class GeoGrid
---@field grid table Grid data. Use the search methods to find entries.
---@field idx table<any, GeoGridLocation>
---@field cell number
---@field types table<string, boolean>
---@field minX number
---@field minZ number
---@field maxX number
---@field maxZ number
---@field count integer
---@field has_bounds boolean
---@field add fun(self: GeoGrid, entityType: string, entityId: any, pos: { x: number, y: number|nil, z: number }): boolean
---@field remove fun(self: GeoGrid, entityId: any): boolean
---@field updatePosition fun(self: GeoGrid, entityId: any, pos: { x: number, y: number|nil, z: number }, defaultType?: string): boolean
---@field move fun(self: GeoGrid, entityId: any, pos: { x: number, y: number|nil, z: number }): boolean, table|nil, table|nil
---@field changeType fun(self: GeoGrid, entityId: any, newType: string): boolean
---@field queryRadius fun(self: GeoGrid, pos: { x: number, y: number|nil, z: number }, radius: number, types: string[]): table<string, table<any, boolean>>
---@field beginRadiusQuery fun(self: GeoGrid, position: Vec3, radius: number, types: string[], maxResults: integer): GeoGridRadiusQuery?, string?
---@field continueRadiusQuery fun(self: GeoGrid, cursor: GeoGridRadiusQuery, workBudget: integer, output: any[]): integer, integer, GeoGridQueryStatus
---@field closeRadiusQuery fun(self: GeoGrid, cursor: GeoGridRadiusQuery)
---@field clear fun(self: GeoGrid)
---@field size fun(self: GeoGrid): integer
---@field has fun(self: GeoGrid, id: any): boolean
---@field toTable fun(self: GeoGrid): table
---@field fromTable fun(self: GeoGrid, t: table): boolean

require("logger")
require("misc")
require("vector")

---@alias GeoGridQueryStatus 'MORE'|'DONE'|'LIMIT'|'CLOSED'|'INVALID'
---@class GeoGridQueryStatusConstants
---@field MORE 'MORE'
---@field DONE 'DONE'
---@field LIMIT 'LIMIT'
---@field CLOSED 'CLOSED'
---@field INVALID 'INVALID'

---@type GeoGridQueryStatusConstants
GeoGridQueryStatus =
    { MORE = "MORE", DONE = "DONE", LIMIT = "LIMIT", CLOSED = "CLOSED", INVALID = "INVALID" }

---@class GeoGridRadiusQuery

local GeoGridInternal = {
    phase = { CELL = "cell", BUCKET = "bucket", ENTRY = "entry" },
}

local floor = math.floor

---@param t any
---@return string|nil et
local function norm_type(t)
    if type(t) ~= "string" then
        return nil
    end
    t = (t:gsub("%s+", "")):gsub("Ids$", "")
    return t ~= "" and t or nil
end

local GeoGridProto = {}

function GeoGridProto:_attach(loc)
    local cell = self:_ensure_cell(loc.cx, loc.cz)
    local chain = cell[loc.bucket]
    if not chain then
        chain = { ids = {} }
        cell[loc.bucket] = chain
    end
    chain.ids[loc.id] = true
    loc.chain, loc.previous, loc.next = chain, chain.last, nil
    if chain.last then
        chain.last.next = loc
    else
        chain.first = loc
    end
    chain.last = loc
end

function GeoGridProto:_detach(loc)
    for _, state in pairs(self._queries) do
        if state.nextEntry == loc then
            state.nextEntry = loc.next
        end
    end
    local chain = loc.chain
    if loc.previous then
        loc.previous.next = loc.next
    else
        chain.first = loc.next
    end
    if loc.next then
        loc.next.previous = loc.previous
    else
        chain.last = loc.previous
    end
    chain.ids[loc.id] = nil
    loc.chain, loc.previous, loc.next = nil, nil, nil
end

--- Compute integer cell coordinates for a position
---@param p { x: number|nil, y: number|nil, z: number|nil }
---@return integer cx
---@return integer cz
function GeoGridProto:_cell_coords(p)
    return floor((p.x or 0) / self.cell), floor((p.z or 0) / self.cell)
end

--- Ensure a cell exists and expand bounds as needed
---@param cx integer
---@param cz integer
---@return table cell
function GeoGridProto:_ensure_cell(cx, cz)
    local col = self.grid[cx]
    if not col then
        col = {}
        self.grid[cx] = col
    end
    local cell = col[cz]
    if not cell then
        cell = {}
        col[cz] = cell
        local x0, x1 = cx * self.cell, (cx + 1) * self.cell
        local z0, z1 = cz * self.cell, (cz + 1) * self.cell
        if not self.has_bounds then
            self.minX, self.maxX, self.minZ, self.maxZ, self.has_bounds = x0, x1, z0, z1, true
        else
            if x0 < self.minX then
                self.minX = x0
            end
            if x1 > self.maxX then
                self.maxX = x1
            end
            if z0 < self.minZ then
                self.minZ = z0
            end
            if z1 > self.maxZ then
                self.maxZ = z1
            end
        end
    end
    return cell
end

--- Add an entity to the grid (idempotent for same type)
---@param entityType string
---@param entityId any
---@param pos { x: number, y: number|nil, z: number }
---@return boolean ok
function GeoGridProto:add(entityType, entityId, pos)
    if type(pos) ~= "table" or type(pos.x) ~= "number" or type(pos.z) ~= "number" then
        return false
    end
    local et = norm_type(entityType)
    if not et then
        return false
    end
    if not (self.types and self.types[et]) then
        return false
    end

    local loc = self.idx[entityId]
    if loc then
        if loc.type ~= et then
            return false
        end
        return self:updatePosition(entityId, pos)
    end

    local cx, cz = self:_cell_coords(pos)
    local bucket = et .. "Ids"
    loc = {
        id = entityId,
        cx = cx,
        cz = cz,
        type = et,
        bucket = bucket,
        p = { x = pos.x, y = pos.y or 0, z = pos.z },
    }
    self:_attach(loc)
    self.idx[entityId] = loc
    self.count = self.count + 1
    return true
end

--- Remove an entity from the grid
---@param entityId any
---@return boolean ok
function GeoGridProto:remove(entityId)
    local loc = self.idx[entityId]
    if not loc then
        return false
    end
    self:_detach(loc)
    self.count = self.count - 1
    self.idx[entityId] = nil
    return true
end

--- Update an entity position (optionally upsert with defaultType)
---@param entityId any
---@param pos { x: number, y: number|nil, z: number }
---@param defaultType string|nil
---@return boolean ok
function GeoGridProto:updatePosition(entityId, pos, defaultType)
    local loc = self.idx[entityId]
    if not loc then
        return defaultType and self:add(defaultType, entityId, pos) or false
    end
    if type(pos) ~= "table" or type(pos.x) ~= "number" or type(pos.z) ~= "number" then
        return false
    end

    local ncx, ncz = self:_cell_coords(pos)
    loc.p.x, loc.p.y, loc.p.z = pos.x, pos.y or 0, pos.z
    if ncx == loc.cx and ncz == loc.cz then
        return true
    end

    self:_detach(loc)
    loc.cx, loc.cz = ncx, ncz
    self:_attach(loc)
    return true
end

--- Move an entity and return from/to cell indices
---@param entityId any
---@param pos { x: number, y: number|nil, z: number }
---@return boolean ok
---@return table|nil from
---@return table|nil to
function GeoGridProto:move(entityId, pos)
    local loc = self.idx[entityId]
    local from = loc and { cx = loc.cx, cz = loc.cz } or nil
    local ok = self:updatePosition(entityId, pos)
    loc = self.idx[entityId]
    local to = loc and { cx = loc.cx, cz = loc.cz } or nil
    return ok, from, to
end

--- Change the entity type without re-adding
---@param entityId any
---@param newType string
---@return boolean ok
function GeoGridProto:changeType(entityId, newType)
    local loc = self.idx[entityId]
    if not loc then
        return false
    end
    local et = norm_type(newType)
    if not et then
        return false
    end
    if not (self.types and self.types[et]) then
        return false
    end
    if et == loc.type then
        return true
    end
    local col = self.grid[loc.cx]
    local cell = col and col[loc.cz]
    if not cell then
        return false
    end

    self:_detach(loc)
    local nb = et .. "Ids"
    loc.type, loc.bucket = et, nb
    self:_attach(loc)
    return true
end

--- Query entities within radius; exact distance (2D) filter applied
---@param pos { x: number, y: number|nil, z: number }
---@param radius number
---@param types string[]
---@return table<string, table<any, boolean>> out
function GeoGridProto:queryRadius(pos, radius, types)
    local out = {}
    if type(pos) ~= "table" or type(radius) ~= "number" or radius < 0 or type(types) ~= "table" then
        return out
    end
    local keys = {}
    for i = 1, #types do
        local et = norm_type(types[i])
        if et and self.types and self.types[et] then
            local k = et .. "Ids"
            out[k] = {}
            keys[#keys + 1] = k
        end
    end
    if #keys == 0 then
        return out
    end

    local ccx, ccz = self:_cell_coords(pos)
    local cr = math.ceil(radius / self.cell)
    local r2 = radius * radius
    local px, pz = pos.x or 0, pos.z or 0

    for dx = -cr, cr do
        local col = self.grid[ccx + dx]
        if col then
            for dz = -cr, cr do
                local cell = col[ccz + dz]
                if cell then
                    for k = 1, #keys do
                        local b = cell[keys[k]]
                        if b then
                            for id in pairs(b.ids) do
                                local loc = self.idx[id]
                                local lp = loc and loc.p
                                if lp then
                                    local dxp, dzp = lp.x - px, lp.z - pz
                                    if dxp * dxp + dzp * dzp <= r2 then
                                        out[keys[k]][id] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return out
end

function GeoGridInternal.finishQuery(state, status)
    for key in pairs(state) do
        state[key] = nil
    end
    state.status = status
end

function GeoGridInternal.copyQueryTypes(grid, types)
    if type(types) ~= "table" then
        return nil
    end
    local count = 0
    for key in pairs(types) do
        if not IsFiniteNumber(key) or key < 1 or key % 1 ~= 0 then
            return nil
        end
        count = count + 1
    end
    if count ~= #types then
        return nil
    end
    local keys, seen = {}, {}
    for _, value in ipairs(types) do
        local entityType = norm_type(value)
        if not entityType or not grid.types[entityType] then
            return nil
        end
        if not seen[entityType] then
            keys[#keys + 1] = entityType .. "Ids"
            seen[entityType] = true
        end
    end
    return keys
end

function GeoGridInternal.cellBound(value, cellSize)
    local bound = floor(value / cellSize)
    if not IsFiniteNumber(bound) or (bound + 1) - bound ~= 1 then
        return nil
    end
    return bound
end

--- Start a radius search that you can finish over several calls.
--- Searches distance along the ground. The search remembers its center and type list.
---@param position Vec3 Center of the search. All three coordinates must be valid numbers.
---@param radius number Search radius in meters; zero is allowed.
---@param types string[] Types registered with this grid, such as {"Unit"}. Use a list without gaps.
---@param maxResults integer Stop after returning this many IDs across all calls. Must be positive.
---@return GeoGridRadiusQuery? cursor Pass this search to continueRadiusQuery; nil if it cannot start.
---@return string? reason Why the search could not start.
---@usage local search, reason = grid:beginRadiusQuery(center, 5000, {"Unit"}, 100)
function GeoGridProto:beginRadiusQuery(position, radius, types, maxResults)
    if not IsFiniteVec3(position) then
        return nil, "search center needs numeric x, y, z coordinates without NaN or infinity"
    end
    if not IsFiniteNumber(radius) or radius < 0 then
        return nil, "search radius must be zero or greater, without NaN or infinity"
    end
    if not IsFiniteNumber(maxResults) or maxResults <= 0 or maxResults % 1 ~= 0 then
        return nil, "maxResults must be a positive finite integer"
    end
    if not IsFiniteNumber(self.cell) or self.cell <= 0 then
        return nil, "grid cell size must be finite and positive"
    end
    local keys = GeoGridInternal.copyQueryTypes(self, types)
    if not keys then
        return nil, "types must be a list of registered grid types, with no gaps"
    end
    local minX = GeoGridInternal.cellBound(position.x - radius, self.cell)
    local maxX = GeoGridInternal.cellBound(position.x + radius, self.cell)
    local minZ = GeoGridInternal.cellBound(position.z - radius, self.cell)
    local maxZ = GeoGridInternal.cellBound(position.z + radius, self.cell)
    if not minX or not maxX or not minZ or not maxZ then
        return nil, "search coordinates are too large for this grid's cell size"
    end
    local cursor = {}
    local state = {
        status = GeoGridQueryStatus.MORE,
        phase = GeoGridInternal.phase.CELL,
        position = { x = position.x, y = position.y, z = position.z },
        radius = radius,
        keys = keys,
        maxResults = maxResults,
        emitted = 0,
        seen = {},
        cx = minX,
        cz = minZ,
        minZ = minZ,
        maxX = maxX,
        maxZ = maxZ,
    }
    if #keys == 0 then
        GeoGridInternal.finishQuery(state, GeoGridQueryStatus.DONE)
    end
    self._queries[cursor] = state
    return cursor, nil
end

function GeoGridInternal.nextQueryCell(state)
    state.cell, state.chain, state.nextEntry = nil, nil, nil
    if state.cz == state.maxZ then
        if state.cx == state.maxX then
            GeoGridInternal.finishQuery(state, GeoGridQueryStatus.DONE)
            return
        end
        state.cx, state.cz = state.cx + 1, state.minZ
    else
        state.cz = state.cz + 1
    end
    state.phase = GeoGridInternal.phase.CELL
end

function GeoGridInternal.nextQueryBucket(state)
    state.chain, state.nextEntry = nil, nil
    state.typeIndex = state.typeIndex + 1
    if state.typeIndex > #state.keys then
        GeoGridInternal.nextQueryCell(state)
    else
        state.phase = GeoGridInternal.phase.BUCKET
    end
end

function GeoGridInternal.queryMatches(state, loc)
    local dx, dz = loc.p.x - state.position.x, loc.p.z - state.position.z
    if not IsFiniteNumber(dx) or not IsFiniteNumber(dz) then
        return false
    end
    if state.radius == 0 then
        return dx == 0 and dz == 0
    end
    if math.abs(dx) > state.radius or math.abs(dz) > state.radius then
        return false
    end
    return (dx / state.radius) ^ 2 + (dz / state.radius) ^ 2 <= 1
end

function GeoGridInternal.inspectQueryEntry(grid, state)
    local loc = state.nextEntry
    local id = nil
    if loc then
        state.nextEntry = loc.next
        if
            grid.idx[loc.id] == loc
            and loc.chain == state.chain
            and not state.seen[loc.id]
            and GeoGridInternal.queryMatches(state, loc)
        then
            id = loc.id
            state.seen[id] = true
            state.emitted = state.emitted + 1
        end
    end
    if state.emitted >= state.maxResults then
        GeoGridInternal.finishQuery(state, GeoGridQueryStatus.LIMIT)
    elseif not state.nextEntry then
        GeoGridInternal.nextQueryBucket(state)
    end
    return id
end

function GeoGridInternal.inspectQuery(grid, state)
    if state.phase == GeoGridInternal.phase.CELL then
        local column = grid.grid[state.cx]
        state.cell = column and column[state.cz]
        if state.cell then
            state.typeIndex, state.phase = 1, GeoGridInternal.phase.BUCKET
        else
            GeoGridInternal.nextQueryCell(state)
        end
    elseif state.phase == GeoGridInternal.phase.BUCKET then
        state.chain = state.cell[state.keys[state.typeIndex]]
        state.nextEntry = state.chain and state.chain.first
        if state.nextEntry then
            state.phase = GeoGridInternal.phase.ENTRY
        else
            GeoGridInternal.nextQueryBucket(state)
        end
    else
        return GeoGridInternal.inspectQueryEntry(grid, state)
    end
    return nil
end

--- Continue a radius search and fill output with this call's matching IDs.
--- Process the IDs before calling again: each call clears the previous output.
--- Objects can move between calls. Each returned ID matches when it is checked.
--- Keep calling while status is MORE. DONE means the search finished.
--- LIMIT means maxResults was reached; other matches may still exist.
--- CLOSED means the search was stopped. INVALID means check the arguments.
---@param cursor GeoGridRadiusQuery A search started by this grid.
---@param workBudget integer Maximum search steps this call. Zero pauses the search.
---@param output any[] Your result list. The same table is reused and cleared even if the call fails.
---@return integer written Number of IDs added to output.
---@return integer workUsed Steps used to check grid squares, object types, and entries. Never exceeds workBudget.
---@return GeoGridQueryStatus status Whether to continue, stop, or check the arguments.
---@usage local found, work, status = grid:continueRadiusQuery(search, 50, matches)
function GeoGridProto:continueRadiusQuery(cursor, workBudget, output)
    if type(output) ~= "table" then
        return 0, 0, GeoGridQueryStatus.INVALID
    end
    for key in pairs(output) do
        if type(key) == "number" and key >= 1 and key % 1 == 0 then
            output[key] = nil
        end
    end
    local state = type(cursor) == "table" and self._queries[cursor]
    if not state or not IsFiniteNumber(workBudget) or workBudget < 0 or workBudget % 1 ~= 0 then
        return 0, 0, GeoGridQueryStatus.INVALID
    end
    local written, used = 0, 0
    while state.status == GeoGridQueryStatus.MORE and used < workBudget do
        local id = GeoGridInternal.inspectQuery(self, state)
        used = used + 1
        if id ~= nil then
            written = written + 1
            output[written] = id
        end
    end
    return written, used, state.status
end

--- Stop a radius search and release the memory it uses.
--- Leaves grid entries unchanged. Calling it again is harmless.
---@param cursor GeoGridRadiusQuery The search to stop. Searches from other grids are ignored.
---@usage grid:closeRadiusQuery(search)
function GeoGridProto:closeRadiusQuery(cursor)
    local state = type(cursor) == "table" and self._queries[cursor]
    if state then
        GeoGridInternal.finishQuery(state, GeoGridQueryStatus.CLOSED)
    end
end

--- Reset grid state
---@return nil
function GeoGridProto:clear()
    for _, state in pairs(self._queries) do
        GeoGridInternal.finishQuery(state, GeoGridQueryStatus.CLOSED)
    end
    self.grid, self.idx, self.count, self.has_bounds = {}, {}, 0, false
    self.minX, self.minZ, self.maxX, self.maxZ = 0, 0, 0, 0
end

--- Get total number of entities
---@return integer n
function GeoGridProto:size()
    return self.count
end

--- Check if an entity exists
---@param id any
---@return boolean hasIt
function GeoGridProto:has(id)
    return self.idx[id] ~= nil
end

--- Serialize grid to a plain table for persistence
---@return table t
function GeoGridProto:toTable()
    local t = {
        cellSize = self.cell,
        minX = self.minX,
        minZ = self.minZ,
        maxX = self.maxX,
        maxZ = self.maxZ,
        entities = {},
    }
    local i = 0
    for id, loc in pairs(self.idx) do
        i = i + 1
        t.entities[i] =
            { id = id, entityType = loc.type, position = { x = loc.p.x, y = loc.p.y, z = loc.p.z } }
    end
    return t
end

--- Restore grid from a plain table
---@param t table
---@return boolean ok
function GeoGridProto:fromTable(t)
    if type(t) ~= "table" or type(t.cellSize) ~= "number" then
        return false
    end
    self:clear()
    self.cell = t.cellSize
    self.minX, self.minZ, self.maxX, self.maxZ, self.has_bounds =
        t.minX or 0, t.minZ or 0, t.maxX or 0, t.maxZ or 0, true
    local es = t.entities
    if type(es) == "table" then
        for i = 1, #es do
            local e = es[i]
            if e and e.entityType and e.id and e.position then
                self:add(e.entityType, e.id, e.position)
            end
        end
    end
    return true
end

---
---@param cellSizeMeters number?
---@param allowedTypes string[]
---@return GeoGrid
function GeoGrid(cellSizeMeters, allowedTypes)
    local typesSet = {}
    if type(allowedTypes) == "table" then
        for i = 1, #allowedTypes do
            local et = norm_type(allowedTypes[i])
            if et then
                typesSet[et] = true
            end
        end
    end
    return setmetatable({
        grid = {},
        idx = {},
        cell = (type(cellSizeMeters) == "number" and cellSizeMeters > 0) and cellSizeMeters
            or 10000,
        types = typesSet,
        minX = 0,
        minZ = 0,
        maxX = 0,
        maxZ = 0,
        count = 0,
        has_bounds = false,
        _queries = setmetatable({}, { __mode = "k" }),
    }, { __index = GeoGridProto })
end
