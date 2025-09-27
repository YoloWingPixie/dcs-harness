-- DCS Harness Weapon Integration Test
-- Exercises weapon.lua wrappers by observing live SHOT events

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Spawn any unit that can fire; shoot to trigger logs

local function info(txt, secs)
    OutText("[HARNESS] " .. txt, secs or 8)
end

local function log(txt)
    if _HarnessInternal and _HarnessInternal.log and _HarnessInternal.log.info then
        _HarnessInternal.log.info(txt, "WeaponTest")
    else
        env.info("[HARNESS:WeaponTest] " .. txt)
    end
end

local function logTable(prefix, tbl)
    local s = TableToString(tbl)
    log(prefix .. ": " .. s)
end

local function idFromTime()
    local t = (timer and timer.getTime and timer.getTime()) or 0
    return 60000 + (math.floor(t) % 999)
end

local function describeWeapon(w)
    if not w then
        return
    end

    local exists = IsWeaponExist(w)
    local name = GetWeaponName(w)
    local typeName = GetWeaponTypeName(w)
    local desc = GetWeaponDesc(w)
    local category = GetWeaponCategory(w)
    local coalitionId = GetWeaponCoalition(w)
    local countryId = GetWeaponCountry(w)
    local launcher = GetWeaponLauncher(w)
    local target = GetWeaponTarget(w)
    local point = GetWeaponPoint(w)
    local position = GetWeaponPosition(w)
    local velocity = GetWeaponVelocity(w)
    local active = IsWeaponActive(w)

    log(
        string.format(
            "Weapon exists=%s active=%s name=%s type=%s cat=%s coal=%s country=%s",
            tostring(exists),
            tostring(active),
            tostring(name),
            tostring(typeName),
            tostring(category),
            tostring(coalitionId),
            tostring(countryId)
        )
    )

    if desc then
        logTable("Desc", desc)
    end
    if velocity then
        logTable("Velocity", velocity)
    end
    if position and position.p then
        logTable("Position", position)
    end
    if point then
        logTable("Point", point)
    end

    if launcher then
        local okN, launcherName = pcall(launcher.getName, launcher)
        if okN then
            log("Launcher=" .. tostring(launcherName))
        end
    end

    if target then
        local okTN, tname = pcall(target.getName, target)
        log("Target=" .. tostring(okTN and tname or target))
    end

    -- Optional: mark current weapon point on F10 map
    if point and trigger and trigger.action and trigger.action.markToAll then
        trigger.action.markToAll(
            idFromTime(),
            "HARNESS WEAPON",
            { x = point.x or 0, y = point.y or 0, z = point.z or 0 },
            true
        )
    end
end

local function setupShotObserver()
    local handler = CreateWorldEventHandler({
        S_EVENT_SHOT = function(event)
            if not event or not event.weapon then
                return
            end
            info("SHOT observed; inspecting weapon", 6)
            describeWeapon(event.weapon)
        end,
    })
    AddWorldEventHandler(handler)
end

local function main()
    info("=== HARNESS WEAPON TEST START ===", 10)
    setupShotObserver()
    info("Ready: fire any weapon to see logs", 12)
end

main()
