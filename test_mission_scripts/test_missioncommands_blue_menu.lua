-- DCS Harness F10 Menu Demo (BLUE Coalition)
-- Creates a simple hierarchical menu with random/demo commands for BLUE

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) Add a BLUE client group so you can open F10 menu

local function log(txt)
    _HarnessInternal.log.info(txt, "BlueMenu")
end

local function onPing()
    log("PING from BLUE F10 menu")
    MessageToCoalition(coalition.side.BLUE, "[BLUE] PING", 5)
end

local function onShowWind()
    local pos = {x = 0, y = 0, z = 0}
    local w = GetWind(pos)
    log("Wind at origin: " .. (w and ("x="..w.x.." y="..w.y.." z="..w.z) or "nil"))
    MessageToCoalition(coalition.side.BLUE, "Wind logged to dcs.log", 6)
end

local function onMarkCenter()
    local t = timer.getTime() or 0
    local id = 46000 + (math.floor(t) % 999)
    MarkToCoalition(id, "BLUE CENTER", {x=0,y=0,z=0}, coalition.side.BLUE, false)
end

local function onCycleMsg()
    local phrases = {"Alpha", "Bravo", "Charlie", "Delta", "Echo"}
    local t = timer.getTime() or 0
    local idx = (math.floor(t) % #phrases) + 1
    local pick = phrases[idx]
    MessageToCoalition(coalition.side.BLUE, "Random: " .. pick, 6)
end

local function setupBlueMenu()
    local root = AddSubMenuForCoalition(coalition.side.BLUE, {}, "HARNESS BLUE")
    if not root then return end

    local util = AddSubMenuForCoalition(coalition.side.BLUE, root, "Utilities") or root
    local demo = AddSubMenuForCoalition(coalition.side.BLUE, root, "Demo") or root

    local item
    item = CreateMenuItem("Ping"); if item then AddCommandForCoalition(coalition.side.BLUE, util, item, onPing) end
    item = CreateMenuItem("Show Wind"); if item then AddCommandForCoalition(coalition.side.BLUE, util, item, onShowWind) end
    item = CreateMenuItem("Mark Center"); if item then AddCommandForCoalition(coalition.side.BLUE, util, item, onMarkCenter) end

    item = CreateMenuItem("Random Message"); if item then AddCommandForCoalition(coalition.side.BLUE, demo, item, onCycleMsg) end
end

local function main()
    -- No RNG seeding in DCS mission env; avoid math.randomseed
    setupBlueMenu()
    log("=== HARNESS BLUE F10 MENU READY ===")
end

main()


