-- DCS Harness Atmosphere Log Test
-- Logs wind, turbulence, temperature, and pressure to DCS log for validation

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua

local function info(txt)
    _HarnessInternal.log.info(txt, "AtmosphereTest")
end

local function fmtVec3(v)
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

local function samplePoint()
    -- Prefer a unit position if available for non-zero local wind; fallback to origin
    local u = GetUnit("HARNESS_TEST_UNIT")
    if u and u.getPoint then
        local ok, point = pcall(function()
            return u:getPoint()
        end)
        if ok and type(point) == "table" and point.x and point.y and point.z then
            return point
        end
    end
    return { x = 0, y = 0, z = 0 }
end

local function logAtmosphere()
    local p = samplePoint()
    local wind = GetWind(p)
    local windT = GetWindWithTurbulence(p)

    info("Wind @ " .. fmtVec3(p) .. ": " .. fmtVec3(wind))
    info("Wind+Turb @ " .. fmtVec3(p) .. ": " .. fmtVec3(windT))

    -- Normalize temperature/pressure return across API variants
    local ret = { GetTemperatureAndPressure(p) }
    if #ret == 0 or ret[1] == nil then
        info("Temp/Pressure: nil")
        return
    end

    if type(ret[1]) == "table" then
        local tp = ret[1]
        local tK = tp
                and (((type(tp.temperatureK) == "number") and tp.temperatureK) or ((type(
                    tp.temperature
                ) == "number") and tp.temperature) or ((type(tp.temp) == "number") and tp.temp) or ((type(
                    tp.t
                ) == "number") and tp.t))
            or nil
        local tC = tp
                and (((type(tp.temperatureC) == "number") and tp.temperatureC) or (tK and (tK - 273.15)))
            or nil
        local pPa = tp
                and (((type(tp.pressurePa) == "number") and tp.pressurePa) or ((type(tp.pressure) == "number") and tp.pressure) or ((type(
                    tp.p
                ) == "number") and tp.p) or ((type(tp.qnh) == "number") and tp.qnh))
            or nil
        local inHg = (
            (type(tp) == "table")
            and (type(tp.pressureInHg) == "number")
            and tp.pressureInHg
        )
            or (pPa and (pPa / 3386.389))
            or nil
        local hPa = (
            (type(tp) == "table")
            and (type(tp.pressurehPa) == "number")
            and tp.pressurehPa
        )
            or (pPa and (pPa / 100.0))
            or nil
        info(
            string.format(
                "Temp=%.2fC (%.2fF) Pressure=%.2finHg (%.1fhPa)",
                (type(tC) == "number" and tC) or -999,
                (type(tC) == "number" and (tC * 9 / 5 + 32)) or -999,
                (type(inHg) == "number" and inHg) or -999,
                (type(hPa) == "number" and hPa) or -999
            )
        )
        return
    end

    if type(ret[1]) == "number" and type(ret[2]) == "number" then
        local tC = ret[1] - 273.15
        local inHg = ret[2] / 3386.389
        local hPa = ret[2] / 100.0
        info(
            string.format(
                "Temp=%.2fC (%.2fF) Pressure=%.2finHg (%.1fhPa)",
                tC,
                (tC * 9 / 5 + 32),
                inHg,
                hPa
            )
        )
        return
    end

    if type(ret[1]) == "number" then
        local tC = ret[1] - 273.15
        -- Fallback: query raw DCS API for pressure if wrapper provided only temperature
        local ok, tRaw, pRaw = pcall(atmosphere.getTemperatureAndPressure, p)
        if ok and type(pRaw) == "number" then
            local inHg = pRaw / 3386.389
            local hPa = pRaw / 100.0
            info(
                string.format(
                    "Temp=%.2fC (%.2fF) Pressure=%.2finHg (%.1fhPa)",
                    tC,
                    (tC * 9 / 5 + 32),
                    inHg,
                    hPa
                )
            )
        else
            info(string.format("Temp=%.2fC (%.2fF) Pressure=N/A", tC, (tC * 9 / 5 + 32)))
        end
        return
    end

    info("Temp/Pressure: unexpected return type")
end

local function main()
    info("=== HARNESS ATMOSPHERE LOG TEST START ===")
    logAtmosphere()
    -- Re-sample a few times for variety
    ScheduleOnce(function()
        logAtmosphere()
    end, nil, 10)
    ScheduleOnce(function()
        logAtmosphere()
    end, nil, 30)
    ScheduleOnce(function()
        logAtmosphere()
    end, nil, 60)
end

main()
