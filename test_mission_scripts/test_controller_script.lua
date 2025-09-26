-- DCS Harness Controller Visual Test
-- Exercises controller.lua wrappers on ground and air groups

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Place optional groups named:
--    - "HARNESS_TEST_GROUP" (ground)
--    - "HARNESS_TEST_AIR_GROUP" (air)

-- =============================
-- Helpers
-- =============================
local function getGroupByName(name)
    local ok, grp = pcall(Group.getByName, name)
    if ok then
        return grp
    end
    return nil
end

local function getController(grp)
    if not grp then
        return nil
    end
    local ok, ctrl = pcall(grp.getController, grp)
    if ok then
        return ctrl
    end
    return nil
end

local function info(txt, secs)
    OutText("[HARNESS] " .. txt, secs or 8)
end

-- Feature detection for Air option IDs that may not exist in some versions
local function airOptionIdAvailable(name)
    return AI
        and AI.Option
        and AI.Option.Air
        and AI.Option.Air.id
        and (AI.Option.Air.id[name] ~= nil)
end

-- =============================
-- Air Group Controller Demos
-- =============================
local function sectionAirController()
    info("Controller Visual: AIR options (HARNESS_TEST_AIR_GROUP)")

    local grp = getGroupByName("HARNESS_TEST_AIR_GROUP")
    if not grp then
        info(
            "(Tip) Place an air group named 'HARNESS_TEST_AIR_GROUP' to demo air controller options",
            10
        )
        return
    end
    local ctrl = GetGroupController("HARNESS_TEST_AIR_GROUP")
    if not ctrl then
        info("Could not get controller for HARNESS_TEST_AIR_GROUP", 10)
        return
    end

    -- Safe, high-signal options using string enums and booleans
    ControllerSetROE(ctrl, "WEAPON_FREE")
    ControllerSetReactionOnThreat(ctrl, "EVADE_FIRE")
    ControllerSetMissileAttack(ctrl, "NEZ_RANGE")
    ControllerSetSilence(ctrl, true)
    ControllerSetRTBOnBingo(ctrl, true)
    ControllerSetRTBOnOutOfAmmo(ctrl, true)
    ControllerSetProhibitAA(ctrl, false)
    ControllerSetProhibitAG(ctrl, false)
    ControllerSetProhibitAB(ctrl, true)
    ControllerSetProhibitJettison(ctrl, true)
    ControllerSetProhibitWPPassReport(ctrl, true)

    -- Basic kinematics (air only)
    SetControllerSpeed(ctrl, 150)
    SetControllerAltitude(ctrl, 1200)

    -- Demonstrate task queue with a valid AIR task (Orbit), then pop later
    local orbitPoint = { x = 0, y = 1200, z = 0 }
    local orbit = CreateOrbitTask("Circle", orbitPoint, 1200, 150)
    if orbit then
        PushControllerTask(ctrl, orbit)
    end

    -- Toggle some settings back after 30s for visual confirmation
    ScheduleOnce(function()
        info("[AIR] Toggling Silence OFF, popping last task", 6)
        ControllerSetSilence(ctrl, false)
        PopControllerTask(ctrl)
    end, nil, 30)
end

-- =============================
-- Ground Group Controller Demos
-- =============================
local function sectionGroundController()
    info("Controller Visual: GROUND options (HARNESS_TEST_GROUP)")

    local grp = getGroupByName("HARNESS_TEST_GROUP")
    if not grp then
        info(
            "(Optional) Place a ground group named 'HARNESS_TEST_GROUP' to demo ground controller options",
            10
        )
        return
    end
    local ctrl = GetGroupController("HARNESS_TEST_GROUP")
    if not ctrl then
        info("Could not get controller for HARNESS_TEST_GROUP", 10)
        return
    end

    -- Ground domain examples
    ControllerSetAlarmState(ctrl, "RED")
    ControllerSetROE(ctrl, "OPEN_FIRE")
    ControllerSetDisperseOnAttack(ctrl, 120)

    -- After 10 seconds, set HARNESS_ALARM_STATE_TEST alarm state to RED (auto domain)
    ScheduleOnce(function()
        local ctrlTest = GetGroupController("HARNESS_ALARM_STATE_TEST")
        if ctrlTest then
            ControllerSetAlarmState(ctrlTest, "RED")
            info("[ALARM] Set HARNESS_ALARM_STATE_TEST alarm to RED", 6)
        else
            info("[ALARM] Group HARNESS_ALARM_STATE_TEST not found", 6)
        end
    end, nil, 10)

    -- Demonstrate task queue on ground as well
    PushControllerTask(ctrl, CreateHoldTask())
    ScheduleOnce(function()
        info("[GROUND] Popping Hold task", 5)
        PopControllerTask(ctrl)
    end, nil, 20)
end

-- =============================
-- Main
-- =============================
local function main()
    info("=== HARNESS CONTROLLER VISUAL TEST START ===", 10)
    sectionAirController()
    sectionGroundController()
    info("=== HARNESS CONTROLLER VISUAL TEST READY (observe group behaviors) ===", 12)
end

main()
