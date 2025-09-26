-- DCS Harness World Visual/Log Test
-- Exercises world.lua wrappers: events, search volumes, weather/airbases

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Optionally place an air group named "HARNESS_SEARCH_TARGET" within 100 NM of map center

local function say(msg, secs)
    if trigger and trigger.action and trigger.action.outText then
        trigger.action.outText("[HARNESS] " .. msg, secs or 8)
    else
        env.info("[HARNESS] " .. msg)
    end
end

local function log(msg)
    if _HarnessInternal and _HarnessInternal.log and _HarnessInternal.log.info then
        _HarnessInternal.log.info(msg, "WorldTest")
    else
        env.info("[HARNESS:WorldTest] " .. msg)
    end
end

local function idFromTime()
    local t = (timer and timer.getTime and timer.getTime()) or 0
    return 48000 + (math.floor(t) % 999)
end

-- Create and register a minimal event handler (SHOT, BIRTH, DEAD)
local function setupEvents()
    local handler = CreateWorldEventHandler({
        S_EVENT_SHOT = function(event)
            local n = (
                event.initiator
                and pcall(event.initiator.getName, event.initiator)
                and event.initiator:getName()
            ) or "?"
            log("SHOT by " .. tostring(n))
        end,
        S_EVENT_BIRTH = function(event)
            local n = (
                event.initiator
                and pcall(event.initiator.getName, event.initiator)
                and event.initiator:getName()
            ) or "?"
            log("BIRTH: " .. tostring(n))
        end,
        S_EVENT_DEAD = function(event)
            local n = (
                event.initiator
                and pcall(event.initiator.getName, event.initiator)
                and event.initiator:getName()
            ) or "?"
            log("DEAD: " .. tostring(n))
        end,
    })
    AddWorldEventHandler(handler)
end

-- Search around map origin for the named group/unit
local function searchForTarget()
    local NM = 1852
    local center = { x = 0, y = 0, z = 0 }
    local vol = CreateSphereVolume(center, 100 * NM)
    if not vol then
        say("World: could not create sphere volume", 8)
        return
    end

    local function filter(obj)
        if not obj then
            return false
        end
        local okN, name = pcall(obj.getName, obj)
        if okN and name == "HARNESS_SEARCH_TARGET" then
            return true
        end
        local okG, grp = pcall(obj.getGroup, obj)
        if okG and grp then
            local okGN, gname = pcall(grp.getName, grp)
            if okGN and gname == "HARNESS_SEARCH_TARGET" then
                return true
            end
        end
        return false
    end

    local hits = {}
    local category = (Object and Object.Category and Object.Category.UNIT) or 1
    local res = SearchWorldObjects(category, vol, filter)
    if type(res) == "table" then
        hits = res
    end
    if #hits > 0 then
        say("World: found HARNESS_SEARCH_TARGET (" .. #hits .. ")", 10)
        local okP, pos = pcall(hits[1].getPoint, hits[1])
        if okP and pos then
            log(
                string.format("Found at {x=%.1f,y=%.1f,z=%.1f}", pos.x or 0, pos.y or 0, pos.z or 0)
            )
            if trigger and trigger.action and trigger.action.markToAll then
                trigger.action.markToAll(
                    idFromTime(),
                    "HARNESS_SEARCH_TARGET",
                    { x = pos.x, y = pos.y, z = pos.z },
                    true
                )
            end
        end
    else
        say("World: target not found within 100 NM of origin", 10)
    end
end

local function logWorldInfo()
    local airbases = GetWorldAirbases() or {}
    say("World: airbases=" .. tostring(#airbases), 6)

    local weather = GetWorldWeather()
    if weather then
        log("Weather table present")
    end
end

local function main()
    say("=== HARNESS WORLD TEST START ===", 10)
    setupEvents()
    logWorldInfo()
    searchForTarget()
    say("=== HARNESS WORLD TEST READY ===", 12)
end

main()
