-- DCS Harness Spot Visual Test
-- Exercises spot.lua wrappers against live Spot API

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Place a player-capable unit named "HARNESS_JTAC" on BLUE to emit the spot

-- =============================
-- Helpers
-- =============================
local function info(txt, secs)
    OutText("[HARNESS] " .. txt, secs or 8)
end

local function getUnit(name)
    local ok, u = pcall(Unit.getByName, name)
    if ok then
        return u
    end
    return nil
end

-- =============================
-- Main
-- =============================
local function main()
    info("=== HARNESS SPOT VISUAL TEST START ===", 10)

    local jtac = getUnit("HARNESS_JTAC")
    if not jtac then
        info("(Optional) Place unit 'HARNESS_JTAC' to demo laser/IR spots", 10)
        return
    end

    -- Determine a point ahead of the unit to point at
    local pos = jtac:getPosition()
    if not pos or not pos.p then
        info("JTAC position unavailable", 8)
        return
    end
    local ahead = { x = pos.p.x + pos.x.x * 200, y = pos.p.y, z = pos.p.z + pos.x.z * 200 }

    -- Create a laser spot with default code, then adjust code and position
    local laser = CreateLaserSpot(jtac, ahead, nil, 1688)
    if laser then
        info("Laser spot created (1688)", 6)
        local code = GetLaserCode(laser)
        if code then
            info("Laser code readback: " .. tostring(code), 5)
        end

        ScheduleOnce(function()
            SetLaserCode(laser, 1687)
            info("Laser code set to 1687", 5)
        end, nil, 6)

        ScheduleOnce(function()
            local moved = { x = ahead.x + 50, y = ahead.y, z = ahead.z }
            SetSpotPoint(laser, moved)
            info("Laser point moved +50m", 5)
        end, nil, 12)
    end

    -- Create an IR spot at the same location
    local ir = CreateIRSpot(jtac, ahead)
    if ir then
        info("IR spot created", 6)
    end

    -- Cleanup
    ScheduleOnce(function()
        if laser and SpotExists(laser) then
            DestroySpot(laser)
            info("Laser spot destroyed", 5)
        end
        if ir and SpotExists(ir) then
            DestroySpot(ir)
            info("IR spot destroyed", 5)
        end
        info("=== HARNESS SPOT VISUAL TEST DONE ===", 8)
    end, nil, 25)
end

main()
