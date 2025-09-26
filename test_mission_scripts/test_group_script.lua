-- DCS Harness Group Visual Test
-- Exercises group.lua wrappers for safe, observable behavior

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Place an optional group named "HARNESS_TEST_GROUP" to demo controls

-- =============================
-- Helpers
-- =============================
local function info(txt, secs)
    OutText("[HARNESS] " .. txt, secs or 8)
end

local function getGroupByName(name)
    local ok, grp = pcall(Group.getByName, name)
    if ok then
        return grp
    end
    return nil
end

local function getFirstUnit(grp)
    if not grp then
        return nil
    end
    local ok, u = pcall(grp.getUnit, grp, 1)
    if ok then
        return u
    end
    return nil
end

-- =============================
-- Sections
-- =============================

local function sectionLookupAndBasics()
    info("Group Visual: Lookup & Basics")

    -- Validate wrappers: GetGroup, GroupExists, GetGroupUnits/Size/InitialSize
    local grp = GetGroup("HARNESS_TEST_GROUP")
    if not grp then
        info("(Optional) Place group 'HARNESS_TEST_GROUP' to demo group wrappers", 10)
        return
    end

    local name = GetGroupName(grp) or "?"
    local exists = GroupExists(name)
    local size = GetGroupSize(name)
    local initSize = GetGroupInitialSize(name)
    local coalitionId = GetGroupCoalition(name) or -1
    local categoryId = GetGroupCategory(name) or -1
    local id = GetGroupID(name) or -1

    OutText(
        string.format(
            "Group '%s' exists=%s size=%d init=%d coal=%s cat=%s id=%s",
            tostring(name),
            tostring(exists),
            tonumber(size) or -1,
            tonumber(initSize) or -1,
            tostring(coalitionId),
            tostring(categoryId),
            tostring(id)
        ),
        10
    )

    -- Units list
    local units = GetGroupUnits(name) or {}
    OutText(string.format("Units found: %d", #units), 8)
end

local function sectionControllerAndMessages()
    info("Group Visual: Controller & Messages")

    local grp = GetGroup("HARNESS_TEST_GROUP")
    if not grp then
        return
    end

    -- Controller cache path
    local ctrl = GetGroupController("HARNESS_TEST_GROUP")
    if ctrl then
        info("Controller acquired & cached")
    end

    -- Messaging helpers
    local gid = GetGroupID("HARNESS_TEST_GROUP")
    if gid then
        MessageToGroup(gid, "Hello Group via MessageToGroup", 8)
    end

    -- Coalition broadcast
    local coal = GetGroupCoalition("HARNESS_TEST_GROUP")
    if coal then
        MessageToCoalition(coal, "Hello Coalition via MessageToCoalition", 8)
    end

    -- Global broadcast
    MessageToAll("Hello World via MessageToAll", 8)
end

local function sectionActivationAndEmissions()
    info("Group Visual: Activation & Emissions")

    local name = "HARNESS_TEST_GROUP"
    local grp = GetGroup(name)
    if not grp then
        return
    end

    -- Activate group and toggle emissions
    ActivateGroup(name)
    EnableGroupEmissions(grp, false)
    ScheduleOnce(function()
        info("Re-enabling group emissions", 5)
        EnableGroupEmissions(grp, true)
    end, nil, 20)
end

local function sectionMarkers()
    info("Group Visual: Markers")

    local grp = getGroupByName("HARNESS_TEST_GROUP")
    if not grp then
        return
    end

    local ok, pos = pcall(function()
        local u = getFirstUnit(grp)
        if not u then
            return nil
        end
        local upos = u:getPoint() or (u.getPosition and u:getPosition().p)
        return upos
    end)

    if not ok or not pos then
        info("Couldn't find unit position for marking", 8)
        return
    end

    MarkGroup(grp, { x = pos.x, y = pos.y, z = pos.z }, "HARNESS_TEST_GROUP HERE")
end

local function sectionLifecycle()
    info("Group Visual: Lifecycle (destroy)")

    local grp = getGroupByName("HARNESS_TEST_DESTROY_GROUP")
    if not grp then
        return
    end

    ScheduleOnce(function()
        info("Destroying group in 3..", 3)
    end, nil, 2)

    ScheduleOnce(function()
        DestroyGroup(grp)
        info("Group destroyed (if allowed)", 6)
    end, nil, 5)
end

-- =============================
-- Main
-- =============================
local function main()
    info("=== HARNESS GROUP VISUAL TEST START ===", 10)
    sectionLookupAndBasics()
    sectionControllerAndMessages()
    sectionActivationAndEmissions()
    sectionMarkers()
    -- Destroy last to keep other sections observable
    sectionLifecycle()
    info("=== HARNESS GROUP VISUAL TEST READY ===", 12)
end

main()
