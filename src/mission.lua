require("misc")

---@class MissionUnitRecord
---@field name string
---@field unitId number?
---@field typeName string?
---@field skill string?
---@field category string?
---@field countryId number?
---@field coalition string?

---@class MissionUnitIndex
---@field get fun(self: MissionUnitIndex, unitName: any): MissionUnitRecord?

local MissionInternal = {}
local MissionUnitIndexProto = {}

function MissionInternal.tableField(value, field)
    local result = type(value) == "table" and rawget(value, field)
    return type(result) == "table" and result or {}
end

function MissionInternal.scalar(value, expectedType)
    if type(value) ~= expectedType or (expectedType == "number" and not IsFiniteNumber(value)) then
        return nil
    end
    return value
end

function MissionInternal.indexCategory(records, categoryData, category, country, coalitionKey)
    for _, group in pairs(MissionInternal.tableField(categoryData, "group")) do
        for _, unit in pairs(MissionInternal.tableField(group, "units")) do
            local name = type(unit) == "table" and rawget(unit, "name")
            if type(name) == "string" and name ~= "" then
                if records[name] then
                    return nil, "duplicate mission unit name: " .. name
                end
                records[name] = {
                    name = name,
                    unitId = MissionInternal.scalar(rawget(unit, "unitId"), "number"),
                    typeName = MissionInternal.scalar(rawget(unit, "type"), "string"),
                    skill = MissionInternal.scalar(rawget(unit, "skill"), "string"),
                    category = MissionInternal.scalar(category, "string"),
                    countryId = MissionInternal.scalar(rawget(country, "id"), "number"),
                    coalition = MissionInternal.scalar(coalitionKey, "string"),
                }
            end
        end
    end
    return true
end

--- Get a unit's Mission Editor settings by name.
---@param unitName any The unit name used in the Mission Editor.
---@return MissionUnitRecord? record A new table of settings, or nil if the name is invalid or unknown.
---@usage local settings = units:get("SAM Radar")
function MissionUnitIndexProto:get(unitName)
    if type(unitName) ~= "string" or unitName == "" then
        return nil
    end
    local record = self.records[unitName]
    if not record then
        return nil
    end
    local copy = {}
    for key, value in pairs(record) do
        copy[key] = value
    end
    return copy
end

--- Build a name lookup for units placed in the Mission Editor.
--- Build it during setup. Later spawns and mission changes do not update it.
--- Skill stays as the editor text, including Random, Player, and Client.
---@param mission table? Mission data to read. Leave out to use env.mission.
---@return MissionUnitIndex? index Use index:get(unitName) to read a unit's settings.
---@return string? reason Why the lookup could not be built, such as missing mission data or duplicate names.
---@usage local units, reason = MissionUnitIndex()
function MissionUnitIndex(mission)
    if mission == nil then
        local ok, current = pcall(function()
            return env.mission
        end)
        if not ok then
            return nil, "mission data is unavailable"
        end
        mission = current
    end
    if type(mission) ~= "table" then
        return nil, "mission must be a table"
    end
    local records = {}
    for coalitionKey, coalitionData in pairs(MissionInternal.tableField(mission, "coalition")) do
        for _, country in pairs(MissionInternal.tableField(coalitionData, "country")) do
            if type(country) == "table" then
                for category, categoryData in pairs(country) do
                    local ok, reason = MissionInternal.indexCategory(
                        records,
                        categoryData,
                        category,
                        country,
                        coalitionKey
                    )
                    if not ok then
                        return nil, reason
                    end
                end
            end
        end
    end
    return setmetatable({ records = records }, { __index = MissionUnitIndexProto }), nil
end
