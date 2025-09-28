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

---@class GeoGrid
---@field grid table<integer, table<integer, table<string, table<any, boolean>>>>
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
---@field clear fun(self: GeoGrid)
---@field size fun(self: GeoGrid): integer
---@field has fun(self: GeoGrid, id: any): boolean
---@field toTable fun(self: GeoGrid): table
---@field fromTable fun(self: GeoGrid, t: table): boolean

require("logger")
require("misc")

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
    local cell = self:_ensure_cell(cx, cz)
    local bucket = et .. "Ids"
    cell[bucket] = cell[bucket] or {}
    if not cell[bucket][entityId] then
        cell[bucket][entityId] = true
        self.count = self.count + 1
    end
    self.idx[entityId] = {
        cx = cx,
        cz = cz,
        type = et,
        bucket = bucket,
        p = { x = pos.x, y = pos.y or 0, z = pos.z },
    }
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
    local col = self.grid[loc.cx]
    local cell = col and col[loc.cz]
    if cell and cell[loc.bucket] and cell[loc.bucket][entityId] then
        cell[loc.bucket][entityId] = nil
        self.count = self.count - 1
    end
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

    local ocol = self.grid[loc.cx]
    local ocell = ocol and ocol[loc.cz]
    if ocell and ocell[loc.bucket] then
        ocell[loc.bucket][entityId] = nil
    end

    local ncell = self:_ensure_cell(ncx, ncz)
    ncell[loc.bucket] = ncell[loc.bucket] or {}
    ncell[loc.bucket][entityId] = true
    loc.cx, loc.cz = ncx, ncz
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

    if cell[loc.bucket] then
        cell[loc.bucket][entityId] = nil
    end
    local nb = et .. "Ids"
    cell[nb] = cell[nb] or {}
    cell[nb][entityId] = true
    loc.type, loc.bucket = et, nb
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
                            for id in pairs(b) do
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

--- Reset grid state
---@return nil
function GeoGridProto:clear()
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
---@param cellSizeMeters number|nil
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
    }, { __index = GeoGridProto })
end

return GeoGrid
