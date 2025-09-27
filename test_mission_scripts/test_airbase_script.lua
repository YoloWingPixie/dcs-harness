-- DCS Harness Airbase Visual Test
-- Exercises airbase.lua wrappers against live Airbase API

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua

local function info(txt, secs)
    OutText("[HARNESS] " .. txt, secs or 8)
end

local function log(txt)
    if _HarnessInternal and _HarnessInternal.log and _HarnessInternal.log.info then
        _HarnessInternal.log.info(txt, "AirbaseTest")
    else
        env.info("[HARNESS:AirbaseTest] " .. txt)
    end
end

local function firstAirbase()
    local airbases = GetWorldAirbases() or {}
    if type(airbases) ~= "table" or #airbases == 0 then
        return nil
    end
    return airbases[1]
end

local function nameOfAirbase(ab)
    local ok, name = pcall(ab.getName, ab)
    if ok and name then
        return name
    end
    return "?"
end

local function showBasics(ab)
    local callsign = GetAirbaseCallsign(ab) or "?"
    local cat = GetAirbaseCategoryName(ab) or "?"
    info(
        string.format(
            "Airbase '%s' callsign='%s' category=%s",
            nameOfAirbase(ab),
            tostring(callsign),
            tostring(cat)
        ),
        10
    )

    local runways = GetAirbaseRunways(ab) or {}
    info(string.format("Runways reported: %d", #runways), 8)
    log("Runways table: " .. TableToString(runways))
end

local function toggleRadioSilent(ab)
    local before = GetAirbaseRadioSilentMode(ab)
    info("RadioSilent before: " .. tostring(before), 6)

    local setOk = SetAirbaseRadioSilentMode(ab, not before)
    if setOk then
        local after = GetAirbaseRadioSilentMode(ab)
        info("RadioSilent after: " .. tostring(after), 6)
        log("Radio silent toggled -> " .. tostring(after))
        -- revert
        SetAirbaseRadioSilentMode(ab, before)
    else
        info("Failed to set RadioSilent", 6)
    end
end

local function main()
    info("=== HARNESS AIRBASE TEST START ===", 10)

    local ab = firstAirbase()
    if not ab then
        info("No airbases returned by world.getAirbases()", 10)
        return
    end

    showBasics(ab)
    toggleRadioSilent(ab)

    info("=== HARNESS AIRBASE TEST READY ===", 12)
end

main()
