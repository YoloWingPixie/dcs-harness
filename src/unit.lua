--[[
==================================================================================================
    UNIT MODULE
    Validated wrapper functions for DCS Unit API
==================================================================================================
]]

require("logger")
require("cache")
require("vector")
require("terrain")
require("conversion")

-- Ensure minimal cache structure in case environment hasn't initialized it yet
_HarnessInternal = _HarnessInternal or {}
_HarnessInternal.cache = _HarnessInternal.cache or {}
_HarnessInternal.cache.units = _HarnessInternal.cache.units or {}
_HarnessInternal.cache.groups = _HarnessInternal.cache.groups or {}
_HarnessInternal.cache.controllers = _HarnessInternal.cache.controllers or {}
_HarnessInternal.cache.airbases = _HarnessInternal.cache.airbases or {}
_HarnessInternal.cache.stats = _HarnessInternal.cache.stats
    or { hits = 0, misses = 0, evictions = 0 }

local UnitInternal = {}

function UnitInternal.validVector(vector)
    return type(vector) == "table"
        and type(vector.x) == "number"
        and vector.x == vector.x
        and vector.x > -math.huge
        and vector.x < math.huge
        and type(vector.y) == "number"
        and vector.y == vector.y
        and vector.y > -math.huge
        and vector.y < math.huge
        and type(vector.z) == "number"
        and vector.z == vector.z
        and vector.z > -math.huge
        and vector.z < math.huge
end

function UnitInternal.isCompletePosition3(value)
    return type(value) == "table"
        and UnitInternal.validVector(value.p)
        and UnitInternal.validVector(value.x)
        and UnitInternal.validVector(value.y)
        and UnitInternal.validVector(value.z)
end

function UnitInternal.normalizeId(value)
    local numeric = tonumber(value)
    if
        type(numeric) ~= "number"
        or numeric ~= numeric
        or numeric <= 0
        or numeric >= math.huge
        or numeric % 1 ~= 0
    then
        return nil
    end
    return numeric
end

function UnitInternal.resolve(unitOrName, requiredMethod, caller)
    if type(unitOrName) == "string" then
        return GetUnit(unitOrName)
    end
    if type(unitOrName) ~= "table" and type(unitOrName) ~= "userdata" then
        _HarnessInternal.log.error(caller .. " requires unit name or unit object", caller)
        return nil
    end
    local success, method = pcall(function()
        return unitOrName[requiredMethod]
    end)
    if not success or type(method) ~= "function" then
        _HarnessInternal.log.error(caller .. " requires a unit with " .. requiredMethod, caller)
        return nil
    end
    return unitOrName
end

function UnitInternal.readPosition3(unit, caller)
    local success, position3 = pcall(unit.getPosition, unit)
    if not success or not UnitInternal.isCompletePosition3(position3) then
        _HarnessInternal.log.error(
            "Failed to get complete unit Position3: " .. tostring(position3),
            caller
        )
        return nil
    end
    return position3
end

--- Get unit by name with validation and error handling
---@param unitName string The name of the unit to retrieve
---@return table? unit The unit object if found, nil otherwise
---@usage local unit = GetUnit("Player")
function GetUnit(unitName)
    if not unitName or type(unitName) ~= "string" then
        _HarnessInternal.log.error("GetUnit requires string unit name", "GetUnit")
        return nil
    end

    -- Ensure cache tables are available
    if not _HarnessInternal.cache then
        _HarnessInternal.cache = {
            units = {},
            groups = {},
            controllers = {},
            airbases = {},
            stats = { hits = 0, misses = 0, evictions = 0 },
        }
    else
        _HarnessInternal.cache.units = _HarnessInternal.cache.units or {}
        _HarnessInternal.cache.groups = _HarnessInternal.cache.groups or {}
        _HarnessInternal.cache.controllers = _HarnessInternal.cache.controllers or {}
        _HarnessInternal.cache.airbases = _HarnessInternal.cache.airbases or {}
        _HarnessInternal.cache.stats = _HarnessInternal.cache.stats
            or { hits = 0, misses = 0, evictions = 0 }
    end

    -- Check cache first
    local cached = _HarnessInternal.cache.units[unitName]
    if cached then
        -- Verify unit still exists
        local success, exists = pcall(function()
            return cached:isExist()
        end)
        if success and exists then
            _HarnessInternal.cache.stats.hits = _HarnessInternal.cache.stats.hits + 1
            return cached
        else
            -- Remove from cache if no longer exists
            RemoveUnitFromCache(unitName)
        end
    end

    -- Get from DCS API
    local success, unit = pcall(Unit.getByName, unitName)
    if not success then
        _HarnessInternal.log.error("Failed to get unit: " .. tostring(unit), "GetUnit")
        return nil
    end

    if not unit then
        _HarnessInternal.log.debug("Unit not found: " .. unitName, "GetUnit")
        return nil
    end

    -- Add to cache
    _HarnessInternal.cache.units[unitName] = unit
    _HarnessInternal.cache.stats.misses = _HarnessInternal.cache.stats.misses + 1

    return unit
end

--- Check if unit exists and is active
---@param unitName string The name of the unit to check
---@return boolean exists True if unit exists and is active, false otherwise
---@usage if UnitExists("Player") then ... end
function UnitExists(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return false
    end

    local success, exists = pcall(unit.isExist, unit)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check unit existence: " .. tostring(exists),
            "UnitExists"
        )
        return false
    end

    return exists
end

--- Get complete DCS Position3 for a unit
---@param unitOrName string|table The name of the unit or unit object
---@return table? position3 Complete Position3 or nil
function GetUnitPosition3(unitOrName)
    local unit = UnitInternal.resolve(unitOrName, "getPosition", "GetUnitPosition3")
    return unit and UnitInternal.readPosition3(unit, "GetUnitPosition3") or nil
end

--- Calculate attitude from a complete DCS Position3
---@param position3 table DCS Position3
---@return table? attitude Heading, pitch, and bank in degrees
function GetAttitudeFromPosition3(position3)
    if not UnitInternal.isCompletePosition3(position3) then
        _HarnessInternal.log.error(
            "GetAttitudeFromPosition3 requires complete Position3 axes",
            "GetAttitudeFromPosition3"
        )
        return nil
    end
    local headingDeg = (math.deg(math.atan2(position3.x.z, position3.x.x)) + 360) % 360
    local pitchDeg = math.deg(math.asin(math.max(-1, math.min(1, position3.x.y))))
    local bankDeg = math.deg(math.atan2(position3.z.y, position3.y.y))
    return { headingDeg = headingDeg, pitchDeg = pitchDeg, bankDeg = bankDeg }
end

--- Get unit position
---@param unitOrName string|table The name of the unit or unit object
---@return table? position The position {x, y, z} if found, nil otherwise
---@usage local pos = GetUnitPosition("Player") or GetUnitPosition(unitObject)
function GetUnitPosition(unitOrName)
    local position3 = GetUnitPosition3(unitOrName)
    return position3 and position3.p or nil
end

--- Get unit heading in degrees
---@param unitOrName string|table The name of the unit or unit object
---@return number? heading The heading in degrees (0-360) if found, nil otherwise
---@usage local heading = GetUnitHeading("Player") or GetUnitHeading(unitObject)
function GetUnitHeading(unitOrName)
    local attitude = GetAttitudeFromPosition3(GetUnitPosition3(unitOrName))
    return attitude and attitude.headingDeg or nil
end

--- Get unit position and heading in one call
---@param unitOrName string|table The name of the unit or unit object
---@return table? position The position {x, y, z} if found, nil otherwise
---@return number? heading The heading in degrees (0-360) if found, nil otherwise
---@usage local pos, hdg = GetUnitOrientation("Player")
function GetUnitOrientation(unitOrName)
    local position3 = GetUnitPosition3(unitOrName)
    local attitude = position3 and GetAttitudeFromPosition3(position3) or nil
    if not attitude then
        return nil, nil
    end
    return position3.p, attitude.headingDeg
end

--- Get unit position, heading, and unit object in one call
---@param unitName string The name of the unit
---@return table? position The position {x, y, z} if found, nil otherwise
---@return number? heading The heading in degrees (0-360) if found, nil otherwise
---@return table? unit The unit object if found, nil otherwise
---@usage local pos, hdg, unit = GetUnitPositionAndHeading("Player")
function GetUnitPositionAndHeading(unitName)
    if not unitName or type(unitName) ~= "string" then
        _HarnessInternal.log.error(
            "GetUnitPositionAndHeading requires string unit name",
            "GetUnitPositionAndHeading"
        )
        return nil, nil, nil
    end

    local unit = UnitInternal.resolve(unitName, "getPosition", "GetUnitPositionAndHeading")
    if not unit then
        return nil, nil, nil
    end
    local position3 = UnitInternal.readPosition3(unit, "GetUnitPositionAndHeading")
    local attitude = position3 and GetAttitudeFromPosition3(position3) or nil
    if not attitude then
        return nil, nil, nil
    end
    return position3.p, attitude.headingDeg, unit
end

--- Get unit velocity
---@param unitOrName string|table The name of the unit or unit object
---@return table? velocity The velocity vector {x, y, z} if found, nil otherwise
---@usage local vel = GetUnitVelocity("Player")
function GetUnitVelocity(unitOrName)
    local unit = UnitInternal.resolve(unitOrName, "getVelocity", "GetUnitVelocity")
    if not unit then
        return nil
    end

    local success, velocity = pcall(unit.getVelocity, unit)
    if not success or not UnitInternal.validVector(velocity) then
        _HarnessInternal.log.error(
            "Failed to get unit velocity: " .. tostring(velocity),
            "GetUnitVelocity"
        )
        return nil
    end

    return Vec3(velocity)
end

-- =========================================
-- Convenience Getters (Speed / Altitude)
-- =========================================

--- Get unit speed magnitude in meters per second
---@param unitName string
---@return number? speedMps
---@usage local v = GetUnitSpeedMps("Player")
function GetUnitSpeedMps(unitName)
    local v = GetUnitVelocity(unitName)
    if not v or type(v.x) ~= "number" or type(v.y) ~= "number" or type(v.z) ~= "number" then
        return nil
    end
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

--- Get unit speed magnitude in knots
---@param unitName string
---@return number? speedKts
---@usage local kts = GetUnitSpeedKnots("Player")
function GetUnitSpeedKnots(unitName)
    local mps = GetUnitSpeedMps(unitName)
    if type(mps) ~= "number" then
        return nil
    end
    return MpsToKnots(mps)
end

--- Get unit vertical speed in feet per second
---@param unitName string
---@return number? feetPerSecond
---@usage local vs = GetUnitVerticalSpeedFeet("Player")
function GetUnitVerticalSpeedFeet(unitName)
    local v = GetUnitVelocity(unitName)
    if not v or type(v.y) ~= "number" then
        return nil
    end
    return MetersToFeet(v.y)
end

--- Get unit altitude MSL in feet
---@param unitName string
---@return number? feetMSL
---@usage local alt = GetUnitAltitudeMSLFeet("Player")
function GetUnitAltitudeMSLFeet(unitName)
    local pos = GetUnitPosition(unitName)
    if not pos or type(pos.y) ~= "number" then
        return nil
    end
    return MetersToFeet(pos.y)
end

--- Get unit altitude AGL in feet
---@param unitName string
---@return number? feetAGL
---@usage local agl = GetUnitAltitudeAGLFeet("Player")
function GetUnitAltitudeAGLFeet(unitName)
    local pos = GetUnitPosition(unitName)
    if not pos then
        return nil
    end
    local aglMeters = GetAGL(pos)
    if type(aglMeters) ~= "number" then
        return nil
    end
    return MetersToFeet(aglMeters)
end

--- Get unit type name
---@param unitName string The name of the unit
---@return string? typeName The unit type name if found, nil otherwise
---@usage local type = GetUnitType("Player")
function GetUnitType(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end

    local success, typeName = pcall(unit.getTypeName, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit type: " .. tostring(typeName), "GetUnitType")
        return nil
    end

    return typeName
end

--- Get unit coalition
---@param unitOrName string|table The name of the unit or unit object
---@return number coalition The coalition ID (0 if unit not found or error)
---@usage local coalition = GetUnitCoalition("Player") or GetUnitCoalition(unitObject)
function GetUnitCoalition(unitOrName)
    local unit

    -- Handle both unit objects and unit names
    if type(unitOrName) == "string" then
        unit = GetUnit(unitOrName)
        if not unit then
            return 0 -- Return 0 instead of nil for consistency
        end
    elseif type(unitOrName) == "table" and unitOrName.getCoalition then
        unit = unitOrName
    else
        _HarnessInternal.log.error(
            "GetUnitCoalition requires unit name or unit object",
            "GetUnitCoalition"
        )
        return 0
    end

    local success, coalition = pcall(unit.getCoalition, unit)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit coalition: " .. tostring(coalition),
            "GetUnitCoalition"
        )
        return 0
    end

    return coalition or 0
end

--- Get unit country
---@param unitName string The name of the unit
---@return number? country The country ID if found, nil otherwise
---@usage local country = GetUnitCountry("Player")
function GetUnitCountry(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end

    local success, country = pcall(unit.getCountry, unit)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit country: " .. tostring(country),
            "GetUnitCountry"
        )
        return nil
    end

    return country
end

--- Get unit group
---@param unitName string The name of the unit
---@return table? group The group object if found, nil otherwise
---@usage local group = GetUnitGroup("Player")
function GetUnitGroup(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end

    local success, group = pcall(unit.getGroup, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit group: " .. tostring(group), "GetUnitGroup")
        return nil
    end

    return group
end

--- Get unit player name (if player controlled)
---@param unitName string The name of the unit
---@return string? playerName The player name if unit is player-controlled, nil otherwise
---@usage local playerName = GetUnitPlayerName("Player")
function GetUnitPlayerName(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end

    local success, playerName = pcall(unit.getPlayerName, unit)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit player name: " .. tostring(playerName),
            "GetUnitPlayerName"
        )
        return nil
    end

    return playerName
end

--- Get unit life/health
---@param unitName string The name of the unit
---@return number? life The current life/health if found, nil otherwise
---@usage local life = GetUnitLife("Player")
function GetUnitLife(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end

    local success, life = pcall(unit.getLife, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit life: " .. tostring(life), "GetUnitLife")
        return nil
    end

    return life
end

--- Get unit maximum life/health
---@param unitName string The name of the unit
---@return number? maxLife The maximum life/health if found, nil otherwise
---@usage local maxLife = GetUnitLife0("Player")
function GetUnitLife0(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end

    local success, life0 = pcall(unit.getLife0, unit)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit max life: " .. tostring(life0),
            "GetUnitLife0"
        )
        return nil
    end

    return life0
end

--- Get unit fuel (0.0 to 1.0+)
---@param unitName string The name of the unit
---@return number? fuel The fuel level (0.0 to 1.0+) if found, nil otherwise
---@usage local fuel = GetUnitFuel("Player")
function GetUnitFuel(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end

    local success, fuel = pcall(unit.getFuel, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit fuel: " .. tostring(fuel), "GetUnitFuel")
        return nil
    end

    return fuel
end

--- Check if unit is in air
---@param unitName string The name of the unit
---@return boolean inAir True if unit is in air, false otherwise
---@usage if IsUnitInAir("Player") then ... end
function IsUnitInAir(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return false
    end

    local success, inAir = pcall(unit.inAir, unit)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check if unit in air: " .. tostring(inAir),
            "IsUnitInAir"
        )
        return false
    end

    return inAir
end

--- Get unit ammo
---@param unitName string The name of the unit
---@return table? ammo The ammo table if found, nil otherwise
---@usage local ammo = GetUnitAmmo("Player")
function GetUnitAmmo(unitName)
    local unit = GetUnit(unitName)
    if not unit then
        return nil
    end

    local success, ammo = pcall(unit.getAmmo, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit ammo: " .. tostring(ammo), "GetUnitAmmo")
        return nil
    end

    return ammo
end

-- Advanced Unit Functions

--- Get unit ID
---@param unitOrName string|table Unit name or object
---@return integer? id Positive integral unit ID or nil on error
---@usage local id = GetUnitID(unit)
function GetUnitID(unitOrName)
    local unit = UnitInternal.resolve(unitOrName, "getID", "GetUnitID")
    if not unit then
        return nil
    end
    local success, id = pcall(unit.getID, unit)
    if not success then
        _HarnessInternal.log.error("Failed to get unit ID: " .. tostring(id), "GetUnitID")
        return nil
    end
    local normalized = UnitInternal.normalizeId(id)
    if not normalized then
        _HarnessInternal.log.error("Invalid unit ID: " .. tostring(id), "GetUnitID")
        return nil
    end
    return normalized
end

--- Get unit number within group
---@param unit table Unit object
---@return number? number Unit number or nil on error
---@usage local num = GetUnitNumber(unit)
function GetUnitNumber(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitNumber requires unit", "GetUnitNumber")
        return nil
    end

    local success, number = pcall(function()
        return unit:getNumber()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit number: " .. tostring(number),
            "GetUnitNumber"
        )
        return nil
    end

    return number
end

--- Get unit callsign
---@param unit table Unit object
---@return string? callsign Unit callsign or nil on error
---@usage local callsign = GetUnitCallsign(unit)
function GetUnitCallsign(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitCallsign requires unit", "GetUnitCallsign")
        return nil
    end

    local success, callsign = pcall(function()
        return unit:getCallsign()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit callsign: " .. tostring(callsign),
            "GetUnitCallsign"
        )
        return nil
    end

    return callsign
end

--- Get unit object ID
---@param unit table Unit object
---@return number? objectId Object ID or nil on error
---@usage local objId = GetUnitObjectID(unit)
function GetUnitObjectID(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitObjectID requires unit", "GetUnitObjectID")
        return nil
    end

    local success, objectId = pcall(function()
        return unit:getObjectID()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit object ID: " .. tostring(objectId),
            "GetUnitObjectID"
        )
        return nil
    end

    return objectId
end

--- Get unit category extended
---@param unit table Unit object
---@return number? category Extended category or nil on error
---@usage local cat = GetUnitCategoryEx(unit)
function GetUnitCategoryEx(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitCategoryEx requires unit", "GetUnitCategoryEx")
        return nil
    end

    local success, category = pcall(function()
        return unit:getCategoryEx()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit category ex: " .. tostring(category),
            "GetUnitCategoryEx"
        )
        return nil
    end

    return category
end

--- Get unit description
---@param unit table Unit object
---@return table? desc Unit description table or nil on error
---@usage local desc = GetUnitDesc(unit)
function GetUnitDesc(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitDesc requires unit", "GetUnitDesc")
        return nil
    end

    local success, desc = pcall(function()
        return unit:getDesc()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to get unit desc: " .. tostring(desc), "GetUnitDesc")
        return nil
    end

    return desc
end

--- Get unit forces name
---@param unit table Unit object
---@return string? forcesName Forces name or nil on error
---@usage local forces = GetUnitForcesName(unit)
function GetUnitForcesName(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitForcesName requires unit", "GetUnitForcesName")
        return nil
    end

    local success, forcesName = pcall(function()
        return unit:getForcesName()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit forces name: " .. tostring(forcesName),
            "GetUnitForcesName"
        )
        return nil
    end

    return forcesName
end

--- Check if unit is active
---@param unit table Unit object
---@return boolean active True if unit is active
---@usage if IsUnitActive(unit) then ... end
function IsUnitActive(unit)
    if not unit then
        _HarnessInternal.log.error("IsUnitActive requires unit", "IsUnitActive")
        return false
    end

    local success, active = pcall(function()
        return unit:isActive()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check unit active: " .. tostring(active),
            "IsUnitActive"
        )
        return false
    end

    return active == true
end

--- Get unit controller
---@param unit table Unit object
---@return table? controller Unit controller or nil on error
---@usage local controller = GetUnitController(unit)
function GetUnitController(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitController requires unit", "GetUnitController")
        return nil
    end

    -- Try to get unit name for cache key
    local unitName = nil
    local ok_get_name, name = pcall(function()
        return unit:getName()
    end)
    if ok_get_name and name then
        unitName = name

        -- Check cache first
        local cacheKey = "unit:" .. unitName
        local cached = _HarnessInternal.cache.getController(cacheKey)
        if cached then
            return cached
        end
    end

    -- Get controller from DCS API
    local ok_get_controller, controller = pcall(function()
        return unit:getController()
    end)
    if not ok_get_controller then
        _HarnessInternal.log.error(
            "Failed to get unit controller: " .. tostring(controller),
            "GetUnitController"
        )
        return nil
    end

    -- Add to cache if we have a name, with optional metadata
    if controller and unitName then
        local info = { unitNames = { unitName } }

        -- Attempt to capture owning group name
        local ok_get_group_name, grpName = pcall(function()
            local grp = unit:getGroup()
            return grp and grp.getName and grp:getName() or nil
        end)
        if ok_get_group_name and grpName then
            info.groupName = grpName
        end

        -- For air units, try to include all unit names from the group
        local ok_get_category, cat = pcall(function()
            return unit.getCategory and unit:getCategory() or nil
        end)
        -- Infer domain from unit category
        if ok_get_category then
            if cat == Unit.Category.AIRPLANE or cat == Unit.Category.HELICOPTER then
                info.domain = "Air"
            elseif cat == Unit.Category.GROUND_UNIT then
                info.domain = "Ground"
            elseif cat == Unit.Category.SHIP then
                info.domain = "Naval"
            end
        end
        if
            ok_get_category
            and (cat == Unit.Category.AIRPLANE or cat == Unit.Category.HELICOPTER)
            and info.groupName
        then
            local ok_get_units, names = pcall(function()
                local grp = unit:getGroup()
                if grp and grp.getUnits then
                    local list = grp:getUnits()
                    if type(list) == "table" then
                        local acc = {}
                        for i = 1, #list do
                            local u = list[i]
                            local ok_get_unit_name, nm = pcall(function()
                                return u:getName()
                            end)
                            if ok_get_unit_name and nm then
                                acc[#acc + 1] = nm
                            end
                        end
                        return acc
                    end
                end
                return nil
            end)
            if ok_get_units and names and #names > 0 then
                info.unitNames = names
            end
        end

        _HarnessInternal.cache.addController("unit:" .. unitName, controller, info)
        -- Fallback: ensure metadata is stored even if addController ignores info
        local entry = _HarnessInternal.cache.controllers["unit:" .. unitName]
        if entry then
            if info.groupName and entry.groupName == nil then
                entry.groupName = info.groupName
            end
            if info.unitNames and entry.unitNames == nil then
                entry.unitNames = info.unitNames
            end
            if info.domain and entry.domain == nil then
                entry.domain = info.domain
            end
        end
    end

    return controller
end

-- Sensor Functions

--- Get unit sensors
---@param unit table Unit object
---@return table? sensors Sensors table or nil on error
---@usage local sensors = GetUnitSensors(unit)
function GetUnitSensors(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitSensors requires unit", "GetUnitSensors")
        return nil
    end

    local success, sensors = pcall(function()
        return unit:getSensors()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit sensors: " .. tostring(sensors),
            "GetUnitSensors"
        )
        return nil
    end

    return sensors
end

--- Check if unit has sensors
---@param unit table Unit object
---@param sensorType number? Sensor type to check
---@param subCategory number? Sensor subcategory
---@return boolean hasSensors True if unit has specified sensors
---@usage if UnitHasSensors(unit, Sensor.RADAR) then ... end
function UnitHasSensors(unit, sensorType, subCategory)
    if not unit then
        _HarnessInternal.log.error("UnitHasSensors requires unit", "UnitHasSensors")
        return false
    end

    local success, hasSensors = pcall(function()
        return unit:hasSensors(sensorType, subCategory)
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check unit sensors: " .. tostring(hasSensors),
            "UnitHasSensors"
        )
        return false
    end

    return hasSensors == true
end

--- Get unit radar
---@param unit table Unit object
---@return boolean active True if radar is active
---@return table? target Tracked target or nil
---@usage local active, target = GetUnitRadar(unit)
function GetUnitRadar(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitRadar requires unit", "GetUnitRadar")
        return false, nil
    end

    local success, active, target = pcall(function()
        return unit:getRadar()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to get unit radar: " .. tostring(active), "GetUnitRadar")
        return false, nil
    end

    return active, target
end

--- Enable/disable unit emissions
---@param unit table Unit object
---@param enabled boolean True to enable emissions
---@return boolean success True if emissions were set
---@usage EnableUnitEmissions(unit, false) -- Go dark
function EnableUnitEmissions(unit, enabled)
    if not unit then
        _HarnessInternal.log.error("EnableUnitEmissions requires unit", "EnableUnitEmissions")
        return false
    end

    if type(enabled) ~= "boolean" then
        _HarnessInternal.log.error(
            "EnableUnitEmissions requires boolean enabled",
            "EnableUnitEmissions"
        )
        return false
    end

    local success, result = pcall(function()
        unit:enableEmission(enabled)
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set unit emissions: " .. tostring(result),
            "EnableUnitEmissions"
        )
        return false
    end

    _HarnessInternal.log.info("Set unit emissions: " .. tostring(enabled), "EnableUnitEmissions")
    return true
end

-- Cargo Functions

--- Get nearest cargo objects
---@param unit table Unit object
---@return table cargos Array of nearby cargo objects
---@usage local cargos = GetUnitNearestCargos(unit)
function GetUnitNearestCargos(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitNearestCargos requires unit", "GetUnitNearestCargos")
        return {}
    end

    local success, cargos = pcall(function()
        return unit:getNearestCargos()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get nearest cargos: " .. tostring(cargos),
            "GetUnitNearestCargos"
        )
        return {}
    end

    return cargos or {}
end

--- Get cargo objects on board
---@param unit table Unit object
---@return table cargos Array of cargo objects on board
---@usage local cargos = GetUnitCargosOnBoard(unit)
function GetUnitCargosOnBoard(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitCargosOnBoard requires unit", "GetUnitCargosOnBoard")
        return {}
    end

    local success, cargos = pcall(function()
        return unit:getCargosOnBoard()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get cargos on board: " .. tostring(cargos),
            "GetUnitCargosOnBoard"
        )
        return {}
    end

    return cargos or {}
end

--- Get unit descent capacity
---@param unit table Unit object
---@return number? capacity Infantry capacity or nil on error
---@usage local capacity = GetUnitDescentCapacity(unit)
function GetUnitDescentCapacity(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitDescentCapacity requires unit", "GetUnitDescentCapacity")
        return nil
    end

    local success, capacity = pcall(function()
        return unit:getDescentCapacity()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get descent capacity: " .. tostring(capacity),
            "GetUnitDescentCapacity"
        )
        return nil
    end

    return capacity
end

--- Get troops on board
---@param unit table Unit object
---@return table? troops Troops info or nil on error
---@usage local troops = GetUnitDescentOnBoard(unit)
function GetUnitDescentOnBoard(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitDescentOnBoard requires unit", "GetUnitDescentOnBoard")
        return nil
    end

    local success, troops = pcall(function()
        return unit:getDescentOnBoard()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get descent on board: " .. tostring(troops),
            "GetUnitDescentOnBoard"
        )
        return nil
    end

    return troops
end

--- Load cargo/troops on board
---@param unit table Unit object
---@param cargo table Cargo or troops to load
---@return boolean success True if loaded
---@usage LoadUnitCargo(transportUnit, cargoObject)
function LoadUnitCargo(unit, cargo)
    if not unit then
        _HarnessInternal.log.error("LoadUnitCargo requires unit", "LoadUnitCargo")
        return false
    end

    if not cargo then
        _HarnessInternal.log.error("LoadUnitCargo requires cargo", "LoadUnitCargo")
        return false
    end

    local success, result = pcall(function()
        unit:LoadOnBoard(cargo)
    end)
    if not success then
        _HarnessInternal.log.error("Failed to load cargo: " .. tostring(result), "LoadUnitCargo")
        return false
    end

    _HarnessInternal.log.info("Loaded cargo on unit", "LoadUnitCargo")
    return true
end

--- Unload cargo
---@param unit table Unit object
---@param cargo table? Specific cargo to unload or nil for all
---@return boolean success True if unloaded
---@usage UnloadUnitCargo(transportUnit)
function UnloadUnitCargo(unit, cargo)
    if not unit then
        _HarnessInternal.log.error("UnloadUnitCargo requires unit", "UnloadUnitCargo")
        return false
    end

    local success, result = pcall(function()
        unit:UnloadCargo(cargo)
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to unload cargo: " .. tostring(result),
            "UnloadUnitCargo"
        )
        return false
    end

    _HarnessInternal.log.info("Unloaded cargo from unit", "UnloadUnitCargo")
    return true
end

--- Open unit ramp
---@param unit table Unit object
---@return boolean success True if ramp opened
---@usage OpenUnitRamp(transportUnit)
function OpenUnitRamp(unit)
    if not unit then
        _HarnessInternal.log.error("OpenUnitRamp requires unit", "OpenUnitRamp")
        return false
    end

    local success, result = pcall(function()
        unit:openRamp()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to open ramp: " .. tostring(result), "OpenUnitRamp")
        return false
    end

    _HarnessInternal.log.info("Opened unit ramp", "OpenUnitRamp")
    return true
end

--- Check if ramp is open
---@param unit table Unit object
---@return boolean? isOpen True if ramp is open, nil on error
---@usage if CheckUnitRampOpen(unit) then ... end
function CheckUnitRampOpen(unit)
    if not unit then
        _HarnessInternal.log.error("CheckUnitRampOpen requires unit", "CheckUnitRampOpen")
        return nil
    end

    local success, isOpen = pcall(function()
        return unit:checkOpenRamp()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check ramp: " .. tostring(isOpen),
            "CheckUnitRampOpen"
        )
        return nil
    end

    return isOpen
end

--- Start disembarking troops
---@param unit table Unit object
---@return boolean success True if disembarking started
---@usage DisembarkUnit(transportUnit)
function DisembarkUnit(unit)
    if not unit then
        _HarnessInternal.log.error("DisembarkUnit requires unit", "DisembarkUnit")
        return false
    end

    local success, result = pcall(function()
        unit:disembarking()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to disembark: " .. tostring(result), "DisembarkUnit")
        return false
    end

    _HarnessInternal.log.info("Started disembarking", "DisembarkUnit")
    return true
end

--- Mark disembarking task
---@param unit table Unit object
---@return boolean success True if marked
---@usage MarkUnitDisembarkingTask(transportUnit)
function MarkUnitDisembarkingTask(unit)
    if not unit then
        _HarnessInternal.log.error(
            "MarkUnitDisembarkingTask requires unit",
            "MarkUnitDisembarkingTask"
        )
        return false
    end

    local success, result = pcall(function()
        unit:markDisembarkingTask()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to mark disembarking: " .. tostring(result),
            "MarkUnitDisembarkingTask"
        )
        return false
    end

    return true
end

--- Check if unit is embarking
---@param unit table Unit object
---@return boolean? embarking True if embarking, nil on error
---@usage if IsUnitEmbarking(unit) then ... end
function IsUnitEmbarking(unit)
    if not unit then
        _HarnessInternal.log.error("IsUnitEmbarking requires unit", "IsUnitEmbarking")
        return nil
    end

    local success, embarking = pcall(function()
        return unit:embarking()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check embarking: " .. tostring(embarking),
            "IsUnitEmbarking"
        )
        return nil
    end

    return embarking
end

-- Aircraft Functions

--- Get unit airbase
---@param unit table Unit object
---@return table? airbase Airbase object or nil
---@usage local airbase = GetUnitAirbase(unit)
function GetUnitAirbase(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitAirbase requires unit", "GetUnitAirbase")
        return nil
    end

    local success, airbase = pcall(function()
        return unit:getAirbase()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get unit airbase: " .. tostring(airbase),
            "GetUnitAirbase"
        )
        return nil
    end

    return airbase
end

--- Check if unit can land on ship
---@param unit table Unit object
---@return boolean? canLand True if can land on ship, nil on error
---@usage if UnitCanShipLanding(unit) then ... end
function UnitCanShipLanding(unit)
    if not unit then
        _HarnessInternal.log.error("UnitCanShipLanding requires unit", "UnitCanShipLanding")
        return nil
    end

    local success, canLand = pcall(function()
        return unit:canShipLanding()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check ship landing: " .. tostring(canLand),
            "UnitCanShipLanding"
        )
        return nil
    end

    return canLand
end

--- Check if unit has carrier capabilities
---@param unit table Unit object
---@return boolean? hasCarrier True if has carrier capabilities, nil on error
---@usage if UnitHasCarrier(unit) then ... end
function UnitHasCarrier(unit)
    if not unit then
        _HarnessInternal.log.error("UnitHasCarrier requires unit", "UnitHasCarrier")
        return nil
    end

    local success, hasCarrier = pcall(function()
        return unit:hasCarrier()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check carrier: " .. tostring(hasCarrier),
            "UnitHasCarrier"
        )
        return nil
    end

    return hasCarrier
end

--- Check if a unit is a known supercarrier type
---@param unit table Unit object
---@return boolean isSuperCarrier True if unit is a supercarrier type
---@usage if IsSuperCarrier(unit) then ... end
function IsSuperCarrier(unit)
    if not unit then
        _HarnessInternal.log.error("IsSuperCarrier requires unit", "IsSuperCarrier")
        return false
    end

    local success, typeName = pcall(function()
        return unit:getTypeName()
    end)
    if not success or not typeName then
        return false
    end

    local superCarrierTypes = {
        ["CVN_71"] = true,
        ["CVN_72"] = true,
        ["CVN_73"] = true,
        ["CVN_74"] = true,
        ["CVN_75"] = true,
        ["Forrestal"] = true,
    }

    return superCarrierTypes[typeName] == true
end

--- Get nearest cargo for aircraft
---@param unit table Unit object
---@return table cargos Array of cargo objects
---@usage local cargos = GetUnitNearestCargosForAircraft(unit)
function GetUnitNearestCargosForAircraft(unit)
    if not unit then
        _HarnessInternal.log.error(
            "GetUnitNearestCargosForAircraft requires unit",
            "GetUnitNearestCargosForAircraft"
        )
        return {}
    end

    local success, cargos = pcall(function()
        return unit:getNearestCargosForAircraft()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get aircraft cargos: " .. tostring(cargos),
            "GetUnitNearestCargosForAircraft"
        )
        return {}
    end

    return cargos or {}
end

--- Get unit fuel low state
---@param unit table Unit object
---@return number? threshold Fuel low threshold or nil on error
---@usage local lowFuel = GetUnitFuelLowState(unit)
function GetUnitFuelLowState(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitFuelLowState requires unit", "GetUnitFuelLowState")
        return nil
    end

    local success, threshold = pcall(function()
        return unit:getFuelLowState()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get fuel low state: " .. tostring(threshold),
            "GetUnitFuelLowState"
        )
        return nil
    end

    return threshold
end

--- Show old carrier menu
---@param unit table Unit object
---@return boolean success True if shown
---@usage ShowUnitCarrierMenu(unit)
function ShowUnitCarrierMenu(unit)
    if not unit then
        _HarnessInternal.log.error("ShowUnitCarrierMenu requires unit", "ShowUnitCarrierMenu")
        return false
    end

    local success, result = pcall(function()
        unit:OldCarrierMenuShow()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to show carrier menu: " .. tostring(result),
            "ShowUnitCarrierMenu"
        )
        return false
    end

    return true
end

-- Other Functions

--- Get draw argument value
---@param unitOrName string|table Unit name or object
---@param arg number Animation argument number
---@return number? value Draw argument value or nil on error
---@usage local gearPos = GetUnitDrawArgument(unit, 0) -- Landing gear
function GetUnitDrawArgument(unitOrName, arg)
    if type(arg) ~= "number" or arg ~= arg or arg < 0 or arg >= math.huge or arg % 1 ~= 0 then
        _HarnessInternal.log.error(
            "Invalid draw argument ID: " .. tostring(arg),
            "GetUnitDrawArgument"
        )
        return nil
    end
    local values = GetUnitDrawArguments(unitOrName, { arg })
    return values and values[arg] or nil
end

--- Read multiple external-model draw arguments
---@param unitOrName string|table Unit name or object
---@param argumentIds table Array of numeric draw-argument IDs
---@return table? values Values keyed by argument ID
---@return boolean complete True only when every argument returned a number
function GetUnitDrawArguments(unitOrName, argumentIds)
    local unit = UnitInternal.resolve(unitOrName, "getDrawArgumentValue", "GetUnitDrawArguments")
    if not unit or type(argumentIds) ~= "table" then
        _HarnessInternal.log.error(
            "GetUnitDrawArguments requires a unit and argument ID array",
            "GetUnitDrawArguments"
        )
        return nil, false
    end

    local keyCount = 0
    for key in pairs(argumentIds) do
        keyCount = keyCount + 1
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            _HarnessInternal.log.error(
                "GetUnitDrawArguments requires an array",
                "GetUnitDrawArguments"
            )
            return nil, false
        end
    end
    if keyCount ~= #argumentIds then
        _HarnessInternal.log.error(
            "GetUnitDrawArguments requires a contiguous array",
            "GetUnitDrawArguments"
        )
        return nil, false
    end

    for _, argumentId in ipairs(argumentIds) do
        if
            type(argumentId) ~= "number"
            or argumentId ~= argumentId
            or argumentId < 0
            or argumentId >= math.huge
            or argumentId % 1 ~= 0
        then
            _HarnessInternal.log.error(
                "Invalid draw argument ID: " .. tostring(argumentId),
                "GetUnitDrawArguments"
            )
            return nil, false
        end
    end

    local values = {}
    local complete = true
    for _, argumentId in ipairs(argumentIds) do
        local success, value = pcall(unit.getDrawArgumentValue, unit, argumentId)
        if
            success
            and type(value) == "number"
            and value == value
            and value > -math.huge
            and value < math.huge
        then
            values[argumentId] = value
        else
            complete = false
            _HarnessInternal.log.error(
                "Failed draw argument " .. tostring(argumentId) .. ": " .. tostring(value),
                "GetUnitDrawArguments"
            )
        end
    end
    return values, complete
end

--- Get unit communicator
---@param unit table Unit object
---@return table? communicator Communicator object or nil on error
---@usage local comm = GetUnitCommunicator(unit)
function GetUnitCommunicator(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitCommunicator requires unit", "GetUnitCommunicator")
        return nil
    end

    local success, communicator = pcall(function()
        return unit:getCommunicator()
    end)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get communicator: " .. tostring(communicator),
            "GetUnitCommunicator"
        )
        return nil
    end

    return communicator
end

--- Get unit seats
---@param unit table Unit object
---@return table? seats Seats info or nil on error
---@usage local seats = GetUnitSeats(unit)
function GetUnitSeats(unit)
    if not unit then
        _HarnessInternal.log.error("GetUnitSeats requires unit", "GetUnitSeats")
        return nil
    end

    local success, seats = pcall(function()
        return unit:getSeats()
    end)
    if not success then
        _HarnessInternal.log.error("Failed to get seats: " .. tostring(seats), "GetUnitSeats")
        return nil
    end

    return seats
end
