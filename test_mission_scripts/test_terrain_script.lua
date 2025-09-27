-- DCS Harness Terrain Visual/Log Test
-- Exercises terrain.lua wrappers against live land API

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Optionally place any unit named "HARNESS_TERRAIN_PROBE" near varied terrain

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
        _HarnessInternal.log.info(msg, "TerrainTest")
    else
        if env and env.info then
            env.info("[HARNESS:TerrainTest] " .. msg)
        end
    end
end

local function idFromTime()
    local t = (timer and timer.getTime and timer.getTime()) or 0
    return 65000 + (math.floor(t) % 999)
end

local function mark(text, pos)
    if not (trigger and trigger.action and trigger.action.markToAll) then
        return
    end
    trigger.action.markToAll(idFromTime(), text, { x = pos.x, y = pos.y or 0, z = pos.z }, true)
end

local function vec3s(v)
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

-- Prefer a sample point from a unit if available, fallback to origin
local function samplePoint()
    local okU, u = pcall(Unit.getByName, "HARNESS_TERRAIN_PROBE")
    if okU and u and u.getPoint then
        local okP, p = pcall(u.getPoint, u)
        if okP and p and p.x and p.y and p.z then
            return p
        end
    end
    return { x = 0, y = 0, z = 0 }
end

local function sectionHeightsAndAGL()
    say("Terrain: Height & AGL", 6)
    local p = samplePoint()
    local h = GetTerrainHeight(p)
    local agl = GetAGL(p)
    log(
        string.format(
            "Height=%.1f AGL=%.1f at %s",
            tonumber(h) or -1,
            tonumber(agl) or -1,
            vec3s(p)
        )
    )
    mark("HEIGHT:" .. tostring(h), { x = p.x, y = p.y, z = p.z })
end

local function sectionSurfaceType()
    say("Terrain: Surface Type & Water/Land", 6)
    local p = samplePoint()
    local surface = GetSurfaceType(p)
    local overWater = IsOverWater(p)
    local overLand = IsOverLand(p)
    log(
        string.format(
            "Surface=%s overWater=%s overLand=%s @ %s",
            tostring(surface),
            tostring(overWater),
            tostring(overLand),
            vec3s(p)
        )
    )
end

local function sectionLOS()
    say("Terrain: Line of Sight", 6)
    local p = samplePoint()
    -- Check LOS 2 km east, at same altitude
    local q = { x = p.x + 2000, y = p.y, z = p.z }
    local visible = HasLOS(p, q)
    log(string.format("LOS %s between %s and %s", tostring(visible), vec3s(p), vec3s(q)))
    mark(visible and "LOS:TRUE" or "LOS:FALSE", q)
end

local function sectionRayIntersection()
    say("Terrain: Ray Intersection (Downward)", 6)
    local p = samplePoint()
    -- Cast ray downward from 1000m above point
    local origin = { x = p.x, y = p.y + 1000, z = p.z }
    local direction = { x = 0, y = -1, z = 0 }
    local hit = GetTerrainIntersection(origin, direction, 5000)
    if hit then
        log("Ray hit at " .. vec3s(hit))
        mark("RAY_HIT", hit)
    else
        log("Ray did not hit within 5km")
    end
end

local function sectionProfile()
    say("Terrain: Profile", 6)
    local p = samplePoint()
    local q = { x = p.x + 3000, y = p.y, z = p.z + 1000 }
    local prof = GetTerrainProfile(p, q)
    if type(prof) == "table" then
        log("Profile points count=" .. tostring(#prof))
        -- Mark ends
        mark("PROF_START", p)
        mark("PROF_END", q)
    else
        log("Profile not returned as table")
    end
end

local function sectionRoads()
    say("Terrain: Roads & Rails", 6)
    local p = samplePoint()
    local nearRoad = GetClosestRoadPoint(p, "roads")
    if nearRoad and nearRoad.x and nearRoad.y then
        local vr = { x = nearRoad.x, y = 0, z = nearRoad.y }
        mark("NEAR_ROAD", vr)
        log(string.format("Closest road near %s -> {x=%.1f,y=%.1f}", vec3s(p), vr.x, vr.z))
    else
        log("Closest road not found")
    end

    -- Pathfinding demo: roads (3 km east)
    local start = { x = p.x, y = 0, z = p.z }
    local dest = { x = p.x + 3000, y = 0, z = p.z }
    local path = FindRoadPath(start, dest, "roads")
    if type(path) == "table" and #path > 0 then
        log("Road path points=" .. tostring(#path))
        -- Mark start/end
        mark("PATH_START", start)
        mark("PATH_END", dest)
    else
        log("Road path not found (roads)")
    end

    -- Rails demo (schema expects 'rails' for findPathOnRoads)
    local pathRails = FindRoadPath(start, dest, "rails")
    if type(pathRails) == "table" then
        log("Rails path points=" .. tostring(#pathRails))
    end
end

local function main()
    say("=== HARNESS TERRAIN TEST START ===", 10)
    sectionHeightsAndAGL()
    sectionSurfaceType()
    sectionLOS()
    sectionRayIntersection()
    sectionProfile()
    sectionRoads()
    say("=== HARNESS TERRAIN TEST READY ===", 12)
end

main()
