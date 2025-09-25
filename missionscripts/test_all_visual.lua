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
local GRID = 6000

-- ID management for trigger marks
local nextId = 40000
local function NextId()
    nextId = nextId + 1
    return nextId
end

-- Color helpers (0..1)
local function rgba(r, g, b, a)
    return {r = r, g = g, b = b, a = a or 1}
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

-- Draw polyline by chaining LineToAll across points (closes polygon if closeLoop)
local function drawPolyline(points3, color, lineType, closeLoop)
    if not points3 or #points3 < 2 then return end
    for i = 1, #points3 - 1 do
        LineToAll(NextId(), points3[i], points3[i + 1], color, lineType or 1, true)
    end
    if closeLoop then
        LineToAll(NextId(), points3[#points3], points3[1], color, lineType or 1, true)
    end
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
    local circ = CreateCircle({x = cCenter.x, z = cCenter.z}, 1200, 48)
    drawPolyline(toVec3(circ, ALTITUDE), COLORS.RED, 1, true)
    label({x = cCenter.x, z = cCenter.z + 1600}, "Circle (outline)")

    -- Rectangle (rotated) via polygon outline
    local rCenter = {x = TEST_CENTER.x - GRID, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local rect = CreateRectangle({x = rCenter.x, z = rCenter.z}, 2800, 1400, 20)
    drawPolyline(toVec3(rect, ALTITUDE), COLORS.GREEN, 1, true)
    label({x = rCenter.x, z = rCenter.z + 1600}, "Rectangle (rot)")

    -- Triangle (outline)
    local tCenter = {x = TEST_CENTER.x, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local tri = CreateTriangle({x = tCenter.x, z = tCenter.z}, 1800, 0)
    drawPolyline(toVec3(tri, ALTITUDE), COLORS.BLUE, 1, true)
    label({x = tCenter.x, z = tCenter.z + 1600}, "Triangle")

    -- Hexagon (outline)
    local hCenter = {x = TEST_CENTER.x + GRID, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local hex = CreateHexagon({x = hCenter.x, z = hCenter.z}, 1500, 0)
    drawPolyline(toVec3(hex, ALTITUDE), COLORS.CYAN, 1, true)
    label({x = hCenter.x, z = hCenter.z + 1600}, "Hexagon")

    -- Star (outline)
    local sCenter = {x = TEST_CENTER.x + GRID * 2, y = ALTITUDE, z = TEST_CENTER.z + GRID * 2}
    local star = CreateStar({x = sCenter.x, z = sCenter.z}, 1600, 800, 5, 0)
    drawPolyline(toVec3(star, ALTITUDE), COLORS.MAGENTA, 1, true)
    label({x = sCenter.x, z = sCenter.z + 1600}, "Star")
end

local function sectionArcsFans()
    OutText("Harness Visual: Arcs & Fans", 10)

    -- Arc (outline)
    local aCenter = {x = TEST_CENTER.x - GRID, y = ALTITUDE, z = TEST_CENTER.z}
    local arc = CreateArc({x = aCenter.x, z = aCenter.z}, 1600, 0, 270, 31)
    drawPolyline(toVec3(arc, ALTITUDE), COLORS.YELLOW, 1, false)
    label({x = aCenter.x, z = aCenter.z + 1800}, "Arc 270°")

    -- Fan (sector outline)
    local fOrigin = {x = TEST_CENTER.x + GRID, y = ALTITUDE, z = TEST_CENTER.z}
    local fan = CreateFan({x = fOrigin.x, z = fOrigin.z}, 45, 70, 3000, 16)
    drawPolyline(toVec3(fan, ALTITUDE), COLORS.RED, 1, true)
    label({x = fOrigin.x, z = fOrigin.z + 1800}, "Fan 70°")
end

local function sectionText()
    OutText("Harness Visual: Text & Marks", 10)

    local pos = {x = TEST_CENTER.x, y = ALTITUDE, z = TEST_CENTER.z - GRID}
    MarkToAll(NextId(), "CENTER", pos, true)
    TextToAll(NextId(), "HARNESS VISUAL TEST", pos, COLORS.WHITE, rgba(0, 0, 0, 0.25), 22, true)

    -- Crosshair
    LineToAll(NextId(), {x = pos.x - 600, y = ALTITUDE, z = pos.z}, {x = pos.x + 600, y = ALTITUDE, z = pos.z}, COLORS.GRAY, 1, true)
    LineToAll(NextId(), {x = pos.x, y = ALTITUDE, z = pos.z - 600}, {x = pos.x, y = ALTITUDE, z = pos.z + 600}, COLORS.GRAY, 1, true)
end

local function main()
    OutText("=== HARNESS VISUAL TEST START ===", 10, true)
    sectionBasic()
    sectionArcsFans()
    sectionText()
    OutText("=== HARNESS VISUAL TEST READY (F10 map) ===", 15)
end

main()