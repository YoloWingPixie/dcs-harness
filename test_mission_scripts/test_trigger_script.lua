-- DCS Harness Trigger Visual Test
-- Minimal, harness-native visual checks using trigger.lua

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Place an optional group named "HARNESS_TEST_GROUP" to exercise group/AI controls

-- =============================
-- Config
-- =============================
local CENTER = { x = 0, y = 0, z = 0 }
local ALT = 0
local NM = 1852
local R = 250
local GRID = 350

-- ID management for trigger marks
local nextId = 45000
local function NextId()
    nextId = nextId + 1
    return nextId
end

-- Color helpers (0..1)
local function rgba(r, g, b, a)
    return { r, g, b, a or 1 }
end

local COLORS = {
    RED = rgba(1, 0, 0),
    GREEN = rgba(0, 1, 0),
    BLUE = rgba(0, 0, 1),
    YELLOW = rgba(1, 1, 0),
    CYAN = rgba(0, 1, 1),
    MAGENTA = rgba(1, 0, 1),
    WHITE = rgba(1, 1, 1),
    GRAY = rgba(0.7, 0.7, 0.7),
}

-- Helpers to query DCS objects when available
local function getGroupByName(name)
    local ok, grp = pcall(Group.getByName, name)
    if ok then
        return grp
    end
    return nil
end

local function getGroupId(grp)
    if not grp then
        return nil
    end
    local ok, id = pcall(grp.getID, grp)
    if ok then
        return id
    end
    return nil
end

local function getFirstUnitId(grp)
    if not grp then
        return nil
    end
    local okU, unit = pcall(grp.getUnit, grp, 1)
    if not okU or not unit then
        return nil
    end
    local okId, id = pcall(unit.getID, unit)
    if okId then
        return id
    end
    return nil
end

-- =============================
-- Sections (focus on functions not covered by shapes visual test)
-- =============================

local function sectionMessages()
    OutText("Harness Visual: Trigger - Messages", 8)

    OutTextForCoalition(2, "Hello BLUE", 8, false)
    OutTextForCoalition(1, "Hello RED", 8, false)

    local demoGroup = getGroupByName("HARNESS_TEST_GROUP")
    local groupId = getGroupId(demoGroup)
    local unitId = getFirstUnitId(demoGroup)

    if type(groupId) == "number" then
        OutTextForGroup(groupId, "Group msg via OutTextForGroup", 8, false)
    else
        OutText("(Tip) Place group 'HARNESS_TEST_GROUP' to demo group/unit messages", 8)
    end

    if type(unitId) == "number" then
        OutTextForUnit(unitId, "Unit msg via OutTextForUnit", 8, false)
    end

    OutSound("sounds/test.ogg")
    OutSoundForCoalition(2, "sounds/test_blue.ogg")
end

local function sectionMarksAndModify()
    OutText("Harness Visual: Trigger - Marks & Modify", 8)

    -- Create a general mark, then modify text/color/fill/font and remove
    local pos = { x = CENTER.x - GRID, y = ALT, z = CENTER.z }
    local id = NextId()
    MarkToAll(id, "CENTER MARK", pos, true, "read-only")
    SetMarkupText(id, "CENTER MARK UPDATED")
    SetMarkupColor(id, COLORS.YELLOW)
    SetMarkupColorFill(id, rgba(0, 0, 0, 0.25))
    SetMarkupFontSize(id, 20)

    -- Create a circle so we can modify its radius
    local circleCenter = { x = CENTER.x - GRID, y = ALT, z = CENTER.z - R }
    local circleId = NextId()
    CircleToAll(
        circleId,
        circleCenter,
        R * 0.6,
        COLORS.GREEN,
        rgba(0, 1, 0, 0.2),
        1,
        true,
        "Radius demo"
    )
    SetMarkupRadius(circleId, R * 0.3)

    -- Coalition/group marks
    local idCoal = NextId()
    MarkToCoalition(
        idCoal,
        "BLUE MARK",
        { x = CENTER.x - GRID, y = ALT, z = CENTER.z + R },
        2,
        true
    )

    local demoGroup = getGroupByName("HARNESS_TEST_GROUP")
    local groupId = getGroupId(demoGroup)
    if type(groupId) == "number" then
        local idGrp = NextId()
        MarkToGroup(
            idGrp,
            "GROUP MARK",
            { x = CENTER.x - GRID, y = ALT, z = CENTER.z + 2 * R },
            groupId,
            false
        )
    end

    -- Clean up demo circle and the first mark
    RemoveMark(circleId)
    RemoveMark(id)
end

local function sectionShapesMinimal()
    -- intentionally left empty to avoid duplicating shapes testing
end

local function sectionEffects()
    OutText("Harness Visual: Trigger - Effects", 8)

    local epos = { x = CENTER.x - 2 * R, y = 50, z = CENTER.z }
    Explosion(epos, 500)

    local spos = { x = CENTER.x - 2 * R, y = ALT, z = CENTER.z + R }
    Smoke(spos, 1, 5, "smoke_demo")

    local ibpos = { x = CENTER.x - 2 * R, y = 300, z = CENTER.z - R }
    IlluminationBomb(ibpos, 1500000)

    local fpos = { x = CENTER.x - 2 * R, y = 50, z = CENTER.z - 2 * R }
    SignalFlare(fpos, 1, 0)

    EffectSmokeBig({ x = CENTER.x - 2 * R, y = ALT, z = CENTER.z + 2 * R }, 1, 5, "big_smoke")
    EffectSmokeStop("big_smoke")
end

local function sectionRadio()
    OutText("Harness Visual: Trigger - Radio", 8)
    local rpos = { x = CENTER.x + 2 * R, y = 50, z = CENTER.z }
    RadioTransmission("sounds/message.ogg", rpos, 0, true, 124000000, 100, "radio_demo")
    StopRadioTransmission("radio_demo")
end

local function sectionMarkupToAll()
    OutText("Harness Visual: Trigger - MarkupToAll", 8)
    local p1 = { x = CENTER.x + R, y = ALT, z = CENTER.z + 2 * R }
    local p2 = { x = CENTER.x + 2 * R, y = ALT, z = CENTER.z + 2 * R }
    local p3 = { x = CENTER.x + 2 * R, y = ALT, z = CENTER.z + 3 * R }
    local p4 = { x = CENTER.x + R, y = ALT, z = CENTER.z + 3 * R }

    -- Line: point1, point2, colors
    MarkupToAll(1, -1, NextId(), p1, p2, { 1, 0, 0, 1 }, { 1, 0, 0, 0.2 }, 1, true, "Line shape")

    -- Circle: center point, perimeter point (no numeric radius), colors
    local center = p1
    local perimeter = { x = center.x + (R / 2), y = ALT, z = center.z }
    MarkupToAll(
        2,
        -1,
        NextId(),
        center,
        perimeter,
        { 0, 1, 0, 1 },
        { 0, 1, 0, 0.2 },
        1,
        true,
        "Circle shape"
    )

    -- Rect
    MarkupToAll(3, -1, NextId(), p1, p3, { 0, 0, 1, 1 }, { 0, 0, 1, 0.2 }, 0, true, "Rect shape")

    -- Arrow
    MarkupToAll(4, -1, NextId(), p1, p3, { 1, 0, 1, 1 }, { 1, 0, 1, 0.2 }, 0, true, "Arrow shape")

    -- Text: point, color, fill, fontSize, readOnly, text
    MarkupToAll(5, -1, NextId(), p1, { 1, 1, 1, 1 }, { 0, 0, 0, 0.25 }, 18, true, "FREEFORM")

    -- Quad
    MarkupToAll(
        6,
        -1,
        NextId(),
        p1,
        p2,
        p3,
        p4,
        { 0, 1, 1, 1 },
        { 0, 1, 1, 0.2 },
        0,
        true,
        "Quad shape"
    )

    -- Freeform up to 6 points, then colors and lineType
    MarkupToAll(
        7,
        -1,
        NextId(),
        p1,
        p2,
        p3,
        p4,
        { x = CENTER.x + 1.5 * R, y = ALT, z = CENTER.z + 2.5 * R },
        { x = CENTER.x + R, y = ALT, z = CENTER.z + 2.5 * R },
        { 1, 1, 0, 1 },
        { 1, 1, 0, 0.2 },
        4
    )
end

local function sectionGroupControls()
    OutText("Harness Visual: Trigger - Group/AI Controls", 8)

    local grp = getGroupByName("HARNESS_TEST_GROUP")
    if not grp then
        OutText("(Optional) Place group 'HARNESS_TEST_GROUP' to demo AI/activation controls", 10)
        return
    end

    -- Activate & basic AI toggles
    TriggerActivateGroup(grp)
    SetGroupAIOn(grp)
    GroupStopMoving(grp)
    GroupContinueMoving(grp)

    -- AI task demos using action indices defined in ME (ensure group has Triggered Actions)
    PushAITask(grp, 1)
    SetAITask(grp, 1)

    -- Schedule AI OFF at 00:30, AI ON at 00:40, and Deactivate at 02:00
    ScheduleOnce(function()
        OutText("[HARNESS] Group AI OFF (00:30)", 5)
        SetGroupAIOff(grp)
    end, nil, 30)

    ScheduleOnce(function()
        OutText("[HARNESS] Group AI ON (00:40)", 5)
        SetGroupAIOn(grp)
    end, nil, 40)

    ScheduleOnce(function()
        OutText("[HARNESS] Group Deactivate (02:00)", 5)
        TriggerDeactivateGroup(grp)
    end, nil, 120)

    -- Keep group active for observation; user can stop the mission when done
end

local function main()
    OutText("=== HARNESS TRIGGER VISUAL TEST START ===", 10, true)
    sectionMessages()
    sectionMarksAndModify()
    sectionShapesMinimal()
    sectionEffects()
    sectionRadio()
    sectionMarkupToAll()
    sectionGroupControls()
    OutText("=== HARNESS TRIGGER VISUAL TEST READY (F10 map) ===", 15)
end

main()
