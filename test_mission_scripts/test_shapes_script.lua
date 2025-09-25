-- DCS Harness Visual Smoke Test
-- Minimal, harness-native visual checks using trigger.lua + shapes.lua

-- Prereqs (Mission Editor):
-- 1) DO SCRIPT FILE dist/harness.lua
-- 2) DO SCRIPT FILE missionscripts/test_all_visual.lua

-- =============================
-- Config
-- =============================
local TEST_CENTER = {x = 0, y = 0, z = 0}
local ALTITUDE = 0
local NM = 1852
local R = 5 * NM -- 5 NM radius => 10 NM diameter
local GRID = 20000

-- ID management for trigger marks
local nextId = 40000
local function NextId()
    nextId = nextId + 1
    return nextId
end

-- Color helpers (0..1)
local function rgba(r, g, b, a)
    return {r, g, b, a or 1}
end

local COLORS = {
    RED = rgba(1, 0, 0),
    GREEN = rgba(0, 1, 0),
    BLUE = rgba(0, 0, 1),
    YELLOW = rgba(1, 1, 0),
    CYAN = rgba(0, 1, 1),
    MAGENTA = rgba(1, 0, 1),
    WHITE = rgba(1, 1, 1),
    GRAY = rgba(0.7, 0.7, 0.7)
}

-- Convert Vec2 list to Vec3 list with altitude
local function toVec3(points2, y)
    return ShapeToVec3(points2, y or ALTITUDE)
end

-- Label helper
local function label(pos, text, size, color)
    TextToAll(NextId(), text, {x = pos.x, y = ALTITUDE, z = pos.z}, color or COLORS.WHITE, nil, size or 16, true)
end

-- =============================
-- Sections
-- =============================

local function sectionBasic()
    OutText("Harness Visual: Basic Shapes", 10)

    -- Circle (outline via polyline for maximum compatibility)
    local cCenter = {x = TEST_CENTER.x - GRID * 2, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local circ = CreateCircle({x = cCenter.x, z = cCenter.z}, R, 72)
    do
        local pts = toVec3(circ, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.RED, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.RED, 1, true)
    end
    label({x = cCenter.x, z = cCenter.z + R + 500}, "Circle (outline)")

    -- Rectangle (rotated) via polygon outline
    local rCenter = {x = TEST_CENTER.x - GRID, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local rect = CreateRectangle({x = rCenter.x, z = rCenter.z}, 2 * R, 1 * R, 20)
    do
        local pts = toVec3(rect, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.GREEN, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.GREEN, 1, true)
    end
    label({x = rCenter.x, z = rCenter.z + R + 500}, "Rectangle (rot)")

    -- Triangle (outline)
    local tCenter = {x = TEST_CENTER.x, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local tri = CreateTriangle({x = tCenter.x, z = tCenter.z}, 2 * R, 0)
    do
        local pts = toVec3(tri, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.BLUE, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.BLUE, 1, true)
    end
    label({x = tCenter.x, z = tCenter.z + R + 500}, "Triangle")

    -- Hexagon (outline)
    local hCenter = {x = TEST_CENTER.x + GRID, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local hex = CreateHexagon({x = hCenter.x, z = hCenter.z}, R, 0)
    do
        local pts = toVec3(hex, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.CYAN, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.CYAN, 1, true)
    end
    label({x = hCenter.x, z = hCenter.z + R + 500}, "Hexagon")

    -- Star (outline)
    local sCenter = {x = TEST_CENTER.x + GRID * 2, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local star = CreateStar({x = sCenter.x, z = sCenter.z}, R, 0.5 * R, 5, 0)
    do
        local pts = toVec3(star, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.MAGENTA, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.MAGENTA, 1, true)
    end
    label({x = sCenter.x, z = sCenter.z + R + 500}, "Star")
end

local function sectionArcsFans()
    OutText("Harness Visual: Arcs & Fans", 10)

    -- Arc (outline)
    local aCenter = {x = TEST_CENTER.x - GRID, y = ALTITUDE, z = TEST_CENTER.z}
    local arc = CreateArc({x = aCenter.x, z = aCenter.z}, R, 0, 270, 55)
    do
        local pts = toVec3(arc, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.YELLOW, 1, true)
        end
    end
    label({x = aCenter.x, z = aCenter.z + R + 500}, "Arc 270°")

    -- Fan (sector outline)
    local fOrigin = {x = TEST_CENTER.x + GRID, y = ALTITUDE, z = TEST_CENTER.z}
    local fan = CreateFan({x = fOrigin.x, z = fOrigin.z}, 45, 70, R, 25)
    do
        local pts = toVec3(fan, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.RED, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.RED, 1, true)
    end
    label({x = fOrigin.x, z = fOrigin.z + R + 500}, "Fan 70°")
end

local function sectionPolygons()
    OutText("Harness Visual: Polygons & Ovals", 10)

    -- Square (outline)
    local sqCenter = {x = TEST_CENTER.x - GRID * 2, y = ALTITUDE, z = TEST_CENTER.z + GRID * 3}
    local square = CreateSquare({x = sqCenter.x, z = sqCenter.z}, 2 * R, 15)
    do
        local pts = toVec3(square, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.WHITE, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.WHITE, 1, true)
    end
    label({x = sqCenter.x, z = sqCenter.z + R + 500}, "Square (rot)")

    -- Trapezoid (outline)
    local trapCenter = {x = TEST_CENTER.x - GRID, y = ALTITUDE, z = TEST_CENTER.z + GRID * 3}
    local trap = CreateTrapezoid({x = trapCenter.x, z = trapCenter.z}, 1.0 * R, 2.0 * R, 1.0 * R, 10)
    do
        local pts = toVec3(trap, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.GRAY, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.GRAY, 1, true)
    end
    label({x = trapCenter.x, z = trapCenter.z + R + 500}, "Trapezoid")

    -- Octagon (outline)
    local octCenter = {x = TEST_CENTER.x, y = ALTITUDE, z = TEST_CENTER.z + GRID * 3}
    local oct = CreateOctagon({x = octCenter.x, z = octCenter.z}, R, 0)
    do
        local pts = toVec3(oct, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.MAGENTA, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.MAGENTA, 1, true)
    end
    label({x = octCenter.x, z = octCenter.z + R + 500}, "Octagon")

    -- Pentagon via generic polygon (outline)
    local pentaCenter = {x = TEST_CENTER.x + GRID, y = ALTITUDE, z = TEST_CENTER.z + GRID * 3}
    local penta = CreatePolygon({x = pentaCenter.x, z = pentaCenter.z}, R, 5, 0)
    do
        local pts = toVec3(penta, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.YELLOW, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.YELLOW, 1, true)
    end
    label({x = pentaCenter.x, z = pentaCenter.z + R + 500}, "Pentagon")

    -- Oval (ellipse outline)
    local ovalCenter = {x = TEST_CENTER.x + GRID * 2, y = ALTITUDE, z = TEST_CENTER.z + GRID * 3}
    local oval = CreateOval({x = ovalCenter.x, z = ovalCenter.z}, 1.5 * R, 0.75 * R, 48)
    do
        local pts = toVec3(oval, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.CYAN, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.CYAN, 1, true)
    end
    label({x = ovalCenter.x, z = ovalCenter.z + R + 500}, "Oval")
end

local function sectionSpecial()
    OutText("Harness Visual: Cross, Pill, Ring, Spiral", 10)

    -- Cross (outline)
    local crossCenter = {x = TEST_CENTER.x - GRID * 2, y = ALTITUDE, z = TEST_CENTER.z + GRID * 4}
    local cross = CreateCross({x = crossCenter.x, z = crossCenter.z}, 2.0 * R, 0.4 * R, 0)
    do
        local pts = toVec3(cross, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.WHITE, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.WHITE, 1, true)
    end
    label({x = crossCenter.x, z = crossCenter.z + R + 500}, "Cross")

    -- Pill (outline)
    local pillCenter = {x = TEST_CENTER.x - GRID, y = ALTITUDE, z = TEST_CENTER.z + GRID * 4}
    local pill = CreatePill({x = pillCenter.x, z = pillCenter.z}, 45, 2.5 * R, 0.6 * R, 19)
    do
        local pts = toVec3(pill, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.GREEN, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.GREEN, 1, true)
    end
    label({x = pillCenter.x, z = pillCenter.z + R + 500}, "Pill")

    -- Ring (outline path)
    local ringCenter = {x = TEST_CENTER.x, y = ALTITUDE, z = TEST_CENTER.z + GRID * 4}
    local ring = CreateRing({x = ringCenter.x, z = ringCenter.z}, 1.2 * R, 0.7 * R, 48)
    do
        local pts = toVec3(ring, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.RED, 1, true)
        end
        LineToAll(NextId(), pts[#pts], pts[1], COLORS.RED, 1, true)
    end
    label({x = ringCenter.x, z = ringCenter.z + R + 500}, "Ring")

    -- Spiral (polyline, open)
    local sprCenter = {x = TEST_CENTER.x + GRID, y = ALTITUDE, z = TEST_CENTER.z + GRID * 4}
    local spiral = CreateSpiral({x = sprCenter.x, z = sprCenter.z}, 0.2 * R, 1.2 * R, 3, 48)
    do
        local pts = toVec3(spiral, ALTITUDE)
        for i = 1, #pts - 1 do
            LineToAll(NextId(), pts[i], pts[i + 1], COLORS.MAGENTA, 1, true)
        end
    end
    label({x = sprCenter.x, z = sprCenter.z + R + 500}, "Spiral")
end

local function sectionText()
    OutText("Harness Visual: Text & Marks", 10)

    local pos = {x = TEST_CENTER.x, y = ALTITUDE, z = TEST_CENTER.z - GRID}
    MarkToAll(NextId(), "CENTER", pos, true)
    TextToAll(NextId(), "HARNESS VISUAL TEST", pos, COLORS.WHITE, rgba(0, 0, 0, 0.25), 28, true)

    -- Crosshair
    LineToAll(NextId(), {x = pos.x - R, y = ALTITUDE, z = pos.z}, {x = pos.x + R, y = ALTITUDE, z = pos.z}, COLORS.GRAY, 0, true)
    LineToAll(NextId(), {x = pos.x, y = ALTITUDE, z = pos.z - R}, {x = pos.x, y = ALTITUDE, z = pos.z + R}, COLORS.GRAY, 0, true)
end

local function main()
    OutText("=== HARNESS VISUAL TEST START ===", 10, true)
    sectionBasic()
    sectionArcsFans()
    sectionPolygons()
    sectionSpecial()
    sectionText()
    OutText("=== HARNESS VISUAL TEST READY (F10 map) ===", 15)
end

main()