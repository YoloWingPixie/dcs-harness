-- DCS Harness Unit Visual Test
-- Exercises unit.lua wrappers for safe, observable behavior

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Place an optional unit named "HARNESS_TEST_UNIT" or a group "HARNESS_TEST_GROUP"

-- =============================
-- Helpers
-- =============================
local function info(txt, secs)
    OutText("[HARNESS] " .. txt, secs or 8)
end

local function tryGetNamedUnit(name)
    local u = GetUnit(name)
    if u then
        return u
    end
    return nil
end

local function tryGetFirstUnitOfGroup(groupName)
    local okG, grp = pcall(Group.getByName, groupName)
    if not okG or not grp then
        return nil
    end
    local okU, u = pcall(grp.getUnit, grp, 1)
    if okU then
        return u
    end
    return nil
end

local function getDemoUnit()
    -- Prefer explicitly named unit, fallback to first unit of the demo group
    return tryGetNamedUnit("HARNESS_TEST_UNIT") or tryGetFirstUnitOfGroup("HARNESS_TEST_GROUP")
end

local function getUnitName(unit)
    if not unit then
        return nil
    end
    local ok, name = pcall(function()
        return unit:getName()
    end)
    if ok then
        return name
    end
    return nil
end

local function vec3ToString(v)
    if not v then
        return "nil"
    end
    return string.format(
        "{x=%.1f,y=%.1f,z=%.1f}",
        tonumber(v.x) or 0,
        tonumber(v.y) or 0,
        tonumber(v.z) or 0
    )
end

-- =============================
-- Sections
-- =============================

local function sectionLookupAndIdentity()
    info("Unit Visual: Lookup & Identity")

    local unit = getDemoUnit()
    if not unit then
        info("(Tip) Place unit 'HARNESS_TEST_UNIT' or group 'HARNESS_TEST_GROUP'", 12)
        return
    end

    local unitName = getUnitName(unit)
    local exists = false
    if type(unitName) == "string" then
        exists = UnitExists(unitName)
    end
    local id = GetUnitID(unit)
    local numberInGroup = GetUnitNumber(unit)
    local callsign = GetUnitCallsign(unit)
    local objectId = GetUnitObjectID(unit)
    local categoryEx = GetUnitCategoryEx(unit)
    local desc = GetUnitDesc(unit)
    local forces = GetUnitForcesName(unit)
    local active = IsUnitActive(unit)

    OutText(
        string.format(
            "Name=%s exists=%s id=%s num=%s callsign=%s objId=%s catEx=%s active=%s",
            tostring(unitName),
            tostring(exists),
            tostring(id),
            tostring(numberInGroup),
            tostring(callsign),
            tostring(objectId),
            tostring(categoryEx),
            tostring(active)
        ),
        10
    )

    if desc then
        local attrCount = 0
        if type(desc.attributes) == "table" then
            for _ in pairs(desc.attributes) do
                attrCount = attrCount + 1
            end
        end
        _HarnessInternal.log.info(
            string.format(
                "Unit Desc: typeName=%s life=%s attrKeys=%d",
                tostring(desc.typeName),
                tostring(desc.life),
                attrCount
            ),
            "UnitVisual"
        )
        if desc.typeName then
            OutText("TypeName=" .. tostring(desc.typeName), 8)
        end
    end
    if forces then
        OutText("ForcesName=" .. tostring(forces), 6)
    end
end

local function sectionKinematics()
    info("Unit Visual: Position / Heading / Velocity")

    local unit = getDemoUnit()
    if not unit then
        return
    end
    local unitName = getUnitName(unit)

    local pos = GetUnitPosition(unit) -- accepts unit or name
    local heading
    local vel
    if type(unitName) == "string" then
        heading = GetUnitHeading(unitName)
        vel = GetUnitVelocity(unitName)
    end

    OutText("Pos=" .. vec3ToString(pos), 8)
    if heading then
        OutText("Heading(deg)=" .. string.format("%.1f", heading), 6)
    end
    if vel then
        OutText("Vel=" .. vec3ToString(vel), 6)
    end
end

local function sectionAffiliation()
    info("Unit Visual: Coalition / Country / Group")

    local unit = getDemoUnit()
    if not unit then
        return
    end
    local unitName = getUnitName(unit)

    local coal = GetUnitCoalition(unit) -- accepts unit or name
    local country
    local group
    if type(unitName) == "string" then
        country = GetUnitCountry(unitName)
        group = GetUnitGroup(unitName)
    end

    OutText(
        string.format(
            "Coalition=%s Country=%s Group?=%s",
            tostring(coal),
            tostring(country),
            tostring(group ~= nil)
        ),
        8
    )
end

local function sectionLifeFuel()
    info("Unit Visual: Life / Fuel / Air")

    local unit = getDemoUnit()
    if not unit then
        return
    end
    local unitName = getUnitName(unit)
    if type(unitName) ~= "string" then
        return
    end

    local life = GetUnitLife(unitName)
    local life0 = GetUnitLife0(unitName)
    local fuel = GetUnitFuel(unitName)
    local inAir = IsUnitInAir(unitName)

    OutText(
        string.format(
            "Life=%s MaxLife=%s Fuel=%.2f InAir=%s",
            tostring(life),
            tostring(life0),
            tonumber(fuel) or -1,
            tostring(inAir)
        ),
        10
    )
end

local function sectionSensorsRadar()
    info("Unit Visual: Sensors / Radar")

    local unit = getDemoUnit()
    if not unit then
        return
    end

    local sensors = GetUnitSensors(unit)
    if sensors then
        local count = 0
        for _ in pairs(sensors) do
            count = count + 1
        end
        OutText("Sensors table present, keys=" .. tostring(count), 6)
    else
        OutText("Sensors not reported", 6)
    end

    local active, target = GetUnitRadar(unit)
    OutText(
        string.format("Radar active=%s target?=%s", tostring(active), tostring(target ~= nil)),
        8
    )
end

local function sectionControllerAndEmissions()
    info("Unit Visual: Controller Cache & Emissions")

    local unit = getDemoUnit()
    if not unit then
        return
    end

    local ctrl1 = GetUnitController(unit)
    local ctrl2 = GetUnitController(unit) -- should hit cache when name resolvable
    OutText(
        string.format(
            "Controller acquired=%s cachedAgain=%s",
            tostring(ctrl1 ~= nil),
            tostring(ctrl2 ~= nil)
        ),
        6
    )

    EnableUnitEmissions(unit, false)
    ScheduleOnce(function()
        info("Re-enabling unit emissions", 5)
        EnableUnitEmissions(unit, true)
    end, nil, 20)
end

local function sectionAircraftAndCargo()
    info("Unit Visual: Aircraft & Cargo Queries")

    local unit = getDemoUnit()
    if not unit then
        return
    end

    local airbase = GetUnitAirbase(unit)
    local canShip = UnitCanShipLanding(unit)
    local hasCarrier = UnitHasCarrier(unit)
    local lowFuel = GetUnitFuelLowState(unit)

    OutText(
        string.format(
            "Airbase?=%s CanShipLanding=%s HasCarrier=%s FuelLowState=%s",
            tostring(airbase ~= nil),
            tostring(canShip),
            tostring(hasCarrier),
            tostring(lowFuel)
        ),
        8
    )

    local nearCargos = GetUnitNearestCargos(unit)
    local cargosOnBoard = GetUnitCargosOnBoard(unit)
    local capacity = GetUnitDescentCapacity(unit)
    local descentOnBoard = GetUnitDescentOnBoard(unit)

    local n1 = (nearCargos and #nearCargos) or 0
    local n2 = (cargosOnBoard and #cargosOnBoard) or 0
    OutText(
        string.format(
            "NearestCargos=%d OnBoard=%d Capacity=%s DescentOnBoard?=%s",
            n1,
            n2,
            tostring(capacity),
            tostring(descentOnBoard ~= nil)
        ),
        8
    )
end

local function sectionMisc()
    info("Unit Visual: Misc (DrawArg / Communicator / Seats)")

    local unit = getDemoUnit()
    if not unit then
        return
    end

    local draw0 = GetUnitDrawArgument(unit, 0)
    local comm = GetUnitCommunicator(unit)
    local seats = GetUnitSeats(unit)

    OutText(
        string.format(
            "DrawArg0=%s Communicator?=%s Seats?=%s",
            tostring(draw0),
            tostring(comm ~= nil),
            tostring(seats ~= nil)
        ),
        8
    )
end

-- =============================
-- Main
-- =============================
local function main()
    info("=== HARNESS UNIT VISUAL TEST START ===", 10)
    sectionLookupAndIdentity()
    sectionKinematics()
    sectionAffiliation()
    sectionLifeFuel()
    sectionSensorsRadar()
    sectionControllerAndEmissions()
    sectionAircraftAndCargo()
    sectionMisc()
    info("=== HARNESS UNIT VISUAL TEST READY ===", 12)
end

main()
