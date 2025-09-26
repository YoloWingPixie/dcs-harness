-- DCS Harness Coalition Visual Test
-- Exercises coalition.lua wrappers: queries, bullseye/ref points, service providers
--
-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Optionally place BLUE/RED client groups to observe coalition-specific messages

local function say(msg, secs)
    if trigger and trigger.action and trigger.action.outText then
        trigger.action.outText("[HARNESS] " .. msg, secs or 8)
    else
        if env and env.info then
            env.info("[HARNESS] " .. msg)
        end
    end
end

local function log(msg)
    if _HarnessInternal and _HarnessInternal.log and _HarnessInternal.log.info then
        _HarnessInternal.log.info(msg, "CoalitionTest")
    else
        if env and env.info then
            env.info("[HARNESS:CoalitionTest] " .. msg)
        end
    end
end

local function idFromTime()
    local t = (timer and timer.getTime and timer.getTime()) or 0
    return 47000 + (math.floor(t) % 999)
end

local function markAt(pos, text)
    if not (trigger and trigger.action and trigger.action.markToAll) then
        return
    end
    trigger.action.markToAll(
        idFromTime(),
        text or "MARK",
        { x = pos.x, y = pos.y or 0, z = pos.z },
        true
    )
end

-- Return BLUE then RED ids for convenience
local function coalitions()
    local BLUE = (coalition and coalition.side and coalition.side.BLUE) or 2
    local RED = (coalition and coalition.side and coalition.side.RED) or 1
    return BLUE, RED
end

local function safeGetName(obj)
    local ok, name = pcall(obj.getName, obj)
    return ok and name or "?"
end

local function listPlayers(coalId)
    local players = GetCoalitionPlayers(coalId) or {}
    local names = {}
    for i = 1, #players do
        local u = players[i]
        if u then
            names[#names + 1] = safeGetName(u)
        end
    end
    return names
end

local function showBasics()
    say("Coalition: basics & queries", 6)
    local BLUE, RED = coalitions()

    local bluePlayers = listPlayers(BLUE)
    local redPlayers = listPlayers(RED)
    log("BLUE players: " .. tostring(#bluePlayers) .. " -> " .. table.concat(bluePlayers, ", "))
    log("RED players: " .. tostring(#redPlayers) .. " -> " .. table.concat(redPlayers, ", "))

    local blueAirbases = GetCoalitionAirbases(BLUE) or {}
    local redAirbases = GetCoalitionAirbases(RED) or {}
    say(string.format("Airbases BLUE=%d RED=%d", #blueAirbases, #redAirbases), 6)

	-- Use main reference point (bullseye) APIs which are available
	local blueMain = GetCoalitionMainRefPoint(BLUE)
	if blueMain and blueMain.x and blueMain.z then
		markAt({ x = blueMain.x, y = blueMain.y or 0, z = blueMain.z }, "BLUE BULLSEYE")
		say("Marked BLUE bullseye", 6)
	end

	local redMain = GetCoalitionMainRefPoint(RED)
	if redMain and redMain.x and redMain.z then
		markAt({ x = redMain.x, y = redMain.y or 0, z = redMain.z }, "RED BULLSEYE")
	end
end

local function refPointDemo()
    say("Coalition: ref point add/remove", 6)
    local BLUE = coalitions()

    -- Place near origin for visibility
	local ref = { callsign = "HARNESS_REF", _type = 0, point = { x = 1000, y = 0, z = 0 } }
    local ok, created = pcall(AddCoalitionRefPoint, BLUE, ref)
    if not ok or not created then
        log("AddCoalitionRefPoint failed")
        return
    end

	-- Some API versions return a finalizer function; call it if so
	if type(created) == "function" then
		pcall(created)
	end

    local main = GetCoalitionMainRefPoint(BLUE)
    if main and main.x and main.z then
        log(string.format("MainRef BLUE at x=%.1f z=%.1f", main.x, main.z))
    end

    -- Mark the newly created ref point if available via getRefPoints
    local refs = GetCoalitionRefPoints(BLUE) or {}
    for _, rp in ipairs(refs) do
        if rp and (rp.callsign == "HARNESS_REF" or rp.name == "HARNESS_REF") and rp.x and rp.z then
            markAt({ x = rp.x, y = rp.y or 0, z = rp.z }, "HARNESS_REF")
            break
        end
    end

    -- Cleanup after 20s
    ScheduleOnce(function()
        RemoveCoalitionRefPoint(BLUE, "HARNESS_REF")
        say("Removed HARNESS_REF ref point", 5)
    end, nil, 20)
end

local function servicesDemo()
    say("Coalition: service providers query", 6)
    local BLUE = coalitions()
    -- Query a few known service enums if available
    local svc = coalition and coalition.service or {}
    local types = {}
    if type(svc.AWACS) == "number" then
        table.insert(types, svc.AWACS)
    end
    if type(svc.TANKER) == "number" then
        table.insert(types, svc.TANKER)
    end
    for _, typ in ipairs(types) do
        local providers = GetCoalitionServiceProviders(BLUE, typ) or {}
        log("Providers for service " .. tostring(typ) .. ": " .. tostring(#providers))
    end
end

local function main()
    say("=== HARNESS COALITION TEST START ===", 10)
    showBasics()
    refPointDemo()
    servicesDemo()
    say("=== HARNESS COALITION TEST READY ===", 12)
end

main()
