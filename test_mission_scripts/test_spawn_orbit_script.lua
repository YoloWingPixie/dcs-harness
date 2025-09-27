-- DCS Harness Spawn + Orbit Integration Test
-- Spawns a BLUE aircraft group with an enroute Orbit task (ComboTask)

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua

local function main()
    OutText("=== HARNESS SPAWN+ORBIT TEST START ===", 10, true)

    -- Define a simple BLUE aircraft group orbiting near origin
    local origin = { x = 0, y = 0, z = 0 }

    local NM = 1852
    local orbitAltFeet = 20000
    local orbitAltMeters = FeetToMeters and FeetToMeters(orbitAltFeet) or (orbitAltFeet * 0.3048)
    local orbitSpeedMps = GetSpeedIAS and GetSpeedIAS(300) or ((tonumber(300) or 0) * 0.514444)
    local raceTrackLengthMeters = 30 * NM

    -- Two waypoints define racetrack axis: WP1 at origin, WP2 30NM east
    local wp1 = {
        x = 0,
        y = orbitAltMeters,
        z = 0,
        action = "Turning Point",
        speed = orbitSpeedMps,
        type = "Turning Point",
        ETA = 0,
        ETA_locked = false,
        formation_template = "",
        alt = orbitAltMeters,
        alt_type = "BARO",
        speed_locked = true,
        task = { id = "ComboTask", params = { tasks = {} } },
    }

    local wp2 = {
        x = raceTrackLengthMeters,
        y = orbitAltMeters,
        z = 0,
        action = "Turning Point",
        speed = orbitSpeedMps,
        type = "Turning Point",
        ETA = 0,
        ETA_locked = false,
        formation_template = "",
        alt = orbitAltMeters,
        alt_type = "BARO",
        speed_locked = true,
        task = { id = "ComboTask", params = { tasks = {} } },
    }

    local orbitTask = CreateOrbitTask
            and CreateOrbitTask(
                "Race-Track",
                { x = 0, y = orbitAltMeters, z = 0 },
                orbitAltMeters,
                orbitSpeedMps,
                { point2 = { x = raceTrackLengthMeters, y = orbitAltMeters, z = 0 } }
            )
        or {
            id = "Orbit",
            params = {
                pattern = "Race-Track",
                point = { x = 0, y = orbitAltMeters, z = 0 },
                point2 = { x = raceTrackLengthMeters, y = orbitAltMeters, z = 0 },
                altitude = orbitAltMeters,
                speed = orbitSpeedMps,
            },
        }
    if orbitTask then
        -- Attach Orbit at WP1
        local entry = {
            number = 1,
            auto = false,
            enabled = true,
            id = orbitTask.id,
            params = orbitTask.params,
        }
        wp1.task.params.tasks[#wp1.task.params.tasks + 1] = entry
    end

    local groupData = {
        visible = false,
        taskSelected = true,
        task = "CAP",
        modulation = 0,
        units = {
            {
                type = "F-15C",
                skill = "High",
                y = 0,
                x = 0,
                alt = orbitAltMeters,
                heading = 0,
                payload = {},
                name = "HARNESS_ORBIT_1",
                alt_type = "BARO",
                callsign = { 1, 1, 1 },
                psi = 0,
                onboard_num = "010",
            },
        },
        name = "HARNESS_ORBIT_GROUP",
        communication = true,
        start_time = 0,
        route = { points = { wp1, wp2 } },
        frequency = 251,
    }

    local countryId = (country and country.id and country.id.USA) or 1
    local categoryId = (Group and Group.Category and Group.Category.AIRPLANE) or 0

    local grp = AddCoalitionGroup(countryId, categoryId, groupData)
    if grp then
        OutText("Spawned HARNESS_ORBIT_GROUP with Orbit task", 10)
    else
        OutText("Spawn failed", 10)
    end

    OutText("=== HARNESS SPAWN+ORBIT TEST READY ===", 12)
end

main()
