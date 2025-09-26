-- DCS Harness StaticObject Visual Test
-- Exercises staticobject.lua wrappers and coalition.addStaticObject flow

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua

local function info(txt, secs)
    OutText("[HARNESS] " .. txt, secs or 8)
end

local function logTable(prefix, tbl)
    local s = TableToString(tbl)
    if _HarnessInternal and _HarnessInternal.log and _HarnessInternal.log.info then
        _HarnessInternal.log.info(prefix .. ": " .. s, "StaticObjectTest")
    else
        env.info("[HARNESS:StaticObjectTest] " .. prefix .. ": " .. s)
    end
end

local function log(txt)
    if _HarnessInternal and _HarnessInternal.log and _HarnessInternal.log.info then
        _HarnessInternal.log.info(txt, "StaticObjectTest")
    else
        env.info("[HARNESS:StaticObjectTest] " .. txt)
    end
end

local function spawnAndVerify()
    -- Choose a safe land point near origin; adjust if needed
    local pos = { x = 918, y = 0, z = 321 }
    local agl = GetAGL(pos) or 0
    pos.y = agl

    -- Build a unique name to avoid interference
    local name = "HARNESS_STATIC_TEST_" .. tostring(math.random(100000, 999999))

    -- DCS interface: CreateStaticObject(countryId, data with name,type,x,y,...)
    local staticData = {
        x = pos.x,
        y = pos.z, -- DCS uses x,y map (z->y)
        type = "Tower Crane", -- Structure example
        category = "Fortifications",
        name = name,
        rate = 100,
        dead = false,
        heading = 0,
    }

    info("Creating static object '" .. name .. "'", 8)
    local created = CreateStaticObject(country.id.USA, staticData)
    if not created then
        info("CreateStaticObject returned nil", 10)
        return
    end

    -- Basic getters
    local got = GetStaticByName(name)
    local exists = got and IsStaticExist(got)
    local id = got and GetStaticID(got)
    local life = got and GetStaticLife(got)
    local cat = got and GetStaticCategory(got)
    local tname = got and GetStaticTypeName(got)
    local coalitionId = got and GetStaticCoalition(got)
    local countryId = got and GetStaticCountry(got)
    local point = got and GetStaticPoint(got)
    local pos3 = got and GetStaticPosition(got)

    log("Exists=" .. tostring(exists) .. " id=" .. tostring(id) .. " life=" .. tostring(life))
    log("Category=" .. tostring(cat) .. " typeName=" .. tostring(tname))
    log("Coalition=" .. tostring(coalitionId) .. " country=" .. tostring(countryId))
    if pos3 then
        logTable("Position", pos3)
    end
    if point then
        logTable("Point", point)
    end

    -- Validate coalition lookup path
    local coalStatics = GetCoalitionStaticObjects(coalition.side.BLUE) or {}
    log("Coalition BLUE static count=" .. tostring(#coalStatics))

    -- Cleanup after delay so it's visible
    if got then
        ScheduleOnce(function()
            info("Destroying static in 3..", 3)
        end, nil, 17)

        ScheduleOnce(function()
            local destroyed = DestroyStaticObject(got)
            info("DestroyStaticObject returned " .. tostring(destroyed), 8)
        end, nil, 20)
    end
end

local function main()
    info("=== HARNESS STATICOBJECT TEST START ===", 10)
    spawnAndVerify()
    info("=== HARNESS STATICOBJECT TEST READY ===", 12)
end

main()
