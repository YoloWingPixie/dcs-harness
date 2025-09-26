-- test_zone.lua
local lu = require("luaunit")
require("test_utils")

-- Setup test environment
package.path = package.path .. ";../src/?.lua"

-- Create isolated test suite
TestZone = CreateIsolatedTestSuite("TestZone", {})

function TestZone:setUp()
    -- Load required modules
    require("mock_dcs")
    require("_header")

    -- Ensure _HarnessInternal has required fields before loading logger
    if not _HarnessInternal.loggers then
        _HarnessInternal.loggers = {}
    end
    if not _HarnessInternal.defaultNamespace then
        _HarnessInternal.defaultNamespace = "Harness"
    end

    require("logger")

    -- Ensure internal logger is created
    if not _HarnessInternal.log then
        _HarnessInternal.log = HarnessLogger("Harness")
    end

    require("cache")
    require("vector")
    require("unit")
    require("group")
    require("zone")

    -- Clear cache data but preserve functions
    if _HarnessInternal.cache then
        _HarnessInternal.cache.units = {}
        _HarnessInternal.cache.groups = {}
        _HarnessInternal.cache.controllers = {}
        _HarnessInternal.cache.airbases = {}
        _HarnessInternal.cache.stats = { hits = 0, misses = 0, evictions = 0 }
    end

    -- Save original mock functions
    self.original_getZone = trigger.misc.getZone
    self.original_getByName = Unit.getByName
    self.original_getGroupByName = Group.getByName
    self.original_getGroups = coalition.getGroups

    -- Create mock zone data
    self.mockZones = {
        ["LZ Alpha"] = {
            point = { x = 1000, y = 0, z = 2000 },
            radius = 500,
        },
        ["LZ Bravo"] = {
            point = { x = 3000, y = 0, z = 4000 },
            radius = 1000,
        },
        ["Small Zone"] = {
            point = { x = 0, y = 0, z = 0 },
            radius = 100,
        },
    }

    -- Override getZone to use mock data
    trigger.misc.getZone = function(name)
        return self.mockZones[name]
    end
end

function TestZone:tearDown()
    -- Restore original mock functions
    trigger.misc.getZone = self.original_getZone
    Unit.getByName = self.original_getByName
    Group.getByName = self.original_getGroupByName
    coalition.getGroups = self.original_getGroups
end

-- GetZone tests
function TestZone:testGetZone_ValidZone()
    local zone = GetZone("LZ Alpha")
    lu.assertNotNil(zone)
    lu.assertEquals(zone.radius, 500)
    lu.assertEquals(zone.point.x, 1000)
end

function TestZone:testGetZone_NonExistentZone()
    local zone = GetZone("Non Existent")
    lu.assertNil(zone)
end

function TestZone:testGetZone_NilName()
    local zone = GetZone(nil)
    lu.assertNil(zone)
end

function TestZone:testGetZone_InvalidType()
    local zone = GetZone(12345)
    lu.assertNil(zone)
end

function TestZone:testGetZone_EmptyString()
    local zone = GetZone("")
    lu.assertNil(zone)
end

function TestZone:testGetZone_APIError()
    trigger.misc.getZone = function(name)
        error("API error")
    end
    local zone = GetZone("LZ Alpha")
    lu.assertNil(zone)
end

-- GetZonePosition tests
function TestZone:testGetZonePosition_ValidZone()
    local pos = GetZonePosition("LZ Alpha")
    lu.assertNotNil(pos)
    lu.assertEquals(pos.x, 1000)
    lu.assertEquals(pos.y, 0)
    lu.assertEquals(pos.z, 2000)
end

function TestZone:testGetZonePosition_NonExistentZone()
    local pos = GetZonePosition("Non Existent")
    lu.assertNil(pos)
end

function TestZone:testGetZonePosition_NilName()
    local pos = GetZonePosition(nil)
    lu.assertNil(pos)
end

-- GetZoneRadius tests
function TestZone:testGetZoneRadius_ValidZone()
    local radius = GetZoneRadius("LZ Alpha")
    lu.assertEquals(radius, 500)
end

function TestZone:testGetZoneRadius_LargeZone()
    local radius = GetZoneRadius("LZ Bravo")
    lu.assertEquals(radius, 1000)
end

function TestZone:testGetZoneRadius_NonExistentZone()
    local radius = GetZoneRadius("Non Existent")
    lu.assertNil(radius)
end

-- IsInZone tests
function TestZone:testIsInZone_InsideZone()
    local position = { x = 1200, y = 50, z = 2100 } -- 223.6 units from center
    local inZone = IsInZone(position, "LZ Alpha")
    lu.assertTrue(inZone)
end

function TestZone:testIsInZone_OutsideZone()
    local position = { x = 2000, y = 50, z = 3000 } -- 1414 units from center
    local inZone = IsInZone(position, "LZ Alpha")
    lu.assertFalse(inZone)
end

function TestZone:testIsInZone_OnBoundary()
    local position = { x = 1500, y = 50, z = 2000 } -- Exactly 500 units from center
    local inZone = IsInZone(position, "LZ Alpha")
    lu.assertTrue(inZone) -- Should be inclusive
end

function TestZone:testIsInZone_CenterOfZone()
    local position = { x = 1000, y = 50, z = 2000 }
    local inZone = IsInZone(position, "LZ Alpha")
    lu.assertTrue(inZone)
end

function TestZone:testIsInZone_InvalidPosition()
    local inZone = IsInZone("not a position", "LZ Alpha")
    lu.assertFalse(inZone)
end

function TestZone:testIsInZone_NonExistentZone()
    local position = { x = 1000, y = 50, z = 2000 }
    local inZone = IsInZone(position, "Non Existent")
    lu.assertFalse(inZone)
end

-- IsUnitInZone tests
function TestZone:testIsUnitInZone_UnitInside()
    -- Mock unit at position inside zone
    local mockUnit = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 1100, y = 50, z = 2050 } }
        end,
        getName = function(self)
            return "TestUnit"
        end,
    }
    Unit.getByName = function(name)
        if name == "TestUnit" then
            return mockUnit
        end
        return nil
    end

    local inZone = IsUnitInZone("TestUnit", "LZ Alpha")
    lu.assertTrue(inZone)
end

function TestZone:testIsUnitInZone_UnitOutside()
    -- Clear cache to ensure clean state
    ClearUnitCache()

    -- Mock unit at position outside zone
    local mockUnit = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 2000, y = 50, z = 3000 } }
        end, -- Outside zone (LZ Alpha center is 1000,0,2000 with radius 500)
        getName = function(self)
            return "OutsideUnit"
        end,
    }
    Unit.getByName = function(name)
        if name == "OutsideUnit" then
            return mockUnit
        end
        return nil
    end

    local inZone = IsUnitInZone("OutsideUnit", "LZ Alpha")
    lu.assertFalse(inZone)
end

function TestZone:testIsUnitInZone_NonExistentUnit()
    Unit.getByName = function(name)
        return nil
    end
    local inZone = IsUnitInZone("NonExistent", "LZ Alpha")
    lu.assertFalse(inZone)
end

function TestZone:testIsUnitInZone_NonExistentZone()
    local mockUnit = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 1100, y = 50, z = 2050 } }
        end,
        getName = function(self)
            return "TestUnit"
        end,
    }
    Unit.getByName = function(name)
        if name == "TestUnit" then
            return mockUnit
        end
        return nil
    end

    local inZone = IsUnitInZone("TestUnit", "Non Existent")
    lu.assertFalse(inZone)
end

-- IsGroupInZone tests
function TestZone:testIsGroupInZone_SomeUnitsInside()
    -- Mock group with mixed units
    local mockUnit1 = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 1100, y = 50, z = 2050 } }
        end,
        getName = function(self)
            return "Unit1"
        end,
    }
    local mockUnit2 = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 5000, y = 50, z = 6000 } }
        end,
        getName = function(self)
            return "Unit2"
        end,
    }

    local mockGroup = {
        isExist = function(self)
            return true
        end,
        getUnits = function(self)
            return { mockUnit1, mockUnit2 }
        end,
        getName = function(self)
            return "TestGroup"
        end,
    }

    Group.getByName = function(name)
        if name == "TestGroup" then
            return mockGroup
        end
        return nil
    end

    Unit.getByName = function(name)
        if name == "Unit1" then
            return mockUnit1
        elseif name == "Unit2" then
            return mockUnit2
        end
        return nil
    end

    local inZone = IsGroupInZone("TestGroup", "LZ Alpha")
    lu.assertTrue(inZone) -- At least one unit is in zone
end

function TestZone:testIsGroupInZone_NoUnitsInside()
    -- Clear cache to ensure clean state
    ClearGroupCache()
    ClearUnitCache()

    -- Mock group with all units outside
    local mockUnit1 = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 2000, y = 50, z = 3000 } }
        end, -- Outside zone (LZ Alpha center is 1000,0,2000 with radius 500)
        getName = function(self)
            return "NoInsideUnit1"
        end,
    }
    local mockUnit2 = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 3000, y = 50, z = 4000 } }
        end, -- Way outside zone
        getName = function(self)
            return "NoInsideUnit2"
        end,
    }

    local mockGroup = {
        isExist = function(self)
            return true
        end,
        getUnits = function(self)
            return { mockUnit1, mockUnit2 }
        end,
        getName = function(self)
            return "NoUnitsInsideGroup"
        end,
    }

    Group.getByName = function(name)
        if name == "NoUnitsInsideGroup" then
            return mockGroup
        end
        return nil
    end

    Unit.getByName = function(name)
        if name == "NoInsideUnit1" then
            return mockUnit1
        elseif name == "NoInsideUnit2" then
            return mockUnit2
        end
        return nil
    end

    local inZone = IsGroupInZone("NoUnitsInsideGroup", "LZ Alpha")
    lu.assertFalse(inZone)
end

function TestZone:testIsGroupInZone_NonExistentGroup()
    Group.getByName = function(name)
        return nil
    end
    local inZone = IsGroupInZone("NonExistent", "LZ Alpha")
    lu.assertFalse(inZone)
end

-- IsGroupCompletelyInZone tests
function TestZone:testIsGroupCompletelyInZone_AllUnitsInside()
    -- Mock group with all units inside
    local mockUnit1 = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 1100, y = 50, z = 2050 } }
        end,
        getName = function(self)
            return "Unit1"
        end,
    }
    local mockUnit2 = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 1200, y = 50, z = 2100 } }
        end,
        getName = function(self)
            return "Unit2"
        end,
    }

    local mockGroup = {
        isExist = function(self)
            return true
        end,
        getUnits = function(self)
            return { mockUnit1, mockUnit2 }
        end,
        getName = function(self)
            return "TestGroup"
        end,
    }

    Group.getByName = function(name)
        if name == "TestGroup" then
            return mockGroup
        end
        return nil
    end

    Unit.getByName = function(name)
        if name == "Unit1" then
            return mockUnit1
        elseif name == "Unit2" then
            return mockUnit2
        end
        return nil
    end

    local inZone = IsGroupCompletelyInZone("TestGroup", "LZ Alpha")
    lu.assertTrue(inZone)
end

function TestZone:testIsGroupCompletelyInZone_SomeUnitsOutside()
    -- Clear cache to ensure clean state
    ClearGroupCache()
    ClearUnitCache()

    -- Mock group with mixed units
    local mockUnit1 = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 1200, y = 50, z = 2200 } }
        end, -- Inside zone (within 500 radius of 1000,0,2000)
        getName = function(self)
            return "MixedUnit1"
        end,
    }
    local mockUnit2 = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return { p = { x = 2000, y = 50, z = 3000 } }
        end, -- Outside zone
        getName = function(self)
            return "MixedUnit2"
        end,
    }

    local mockGroup = {
        isExist = function(self)
            return true
        end,
        getUnits = function(self)
            return { mockUnit1, mockUnit2 }
        end,
        getName = function(self)
            return "MixedGroup"
        end,
    }

    Group.getByName = function(name)
        if name == "MixedGroup" then
            return mockGroup
        end
        return nil
    end

    Unit.getByName = function(name)
        if name == "MixedUnit1" then
            return mockUnit1
        elseif name == "MixedUnit2" then
            return mockUnit2
        end
        return nil
    end

    local inZone = IsGroupCompletelyInZone("MixedGroup", "LZ Alpha")
    lu.assertFalse(inZone)
end

function TestZone:testIsGroupCompletelyInZone_EmptyGroup()
    -- Clear cache to ensure clean state
    ClearGroupCache()

    local mockGroup = {
        isExist = function(self)
            return true
        end,
        getUnits = function(self)
            return {}
        end,
        getName = function(self)
            return "EmptyTestGroup"
        end,
    }

    Group.getByName = function(name)
        if name == "EmptyTestGroup" then
            return mockGroup
        end
        return nil
    end

    local inZone = IsGroupCompletelyInZone("EmptyTestGroup", "LZ Alpha")
    lu.assertFalse(inZone) -- Empty group returns false
end

-- RandomPointInZone tests
function TestZone:testRandomPointInZone_DefaultRadius()
    -- Run multiple times to check randomness
    for i = 1, 10 do
        local point = RandomPointInZone("LZ Alpha")
        lu.assertNotNil(point)

        -- Check distance from center
        local dx = point.x - 1000
        local dz = point.z - 2000
        local distance = math.sqrt(dx * dx + dz * dz)

        lu.assertTrue(distance <= 500, "Point should be within zone radius")
        lu.assertEquals(point.y, 0) -- Y should match zone center
    end
end

function TestZone:testRandomPointInZone_InnerOuterRadius()
    -- Run multiple times to check randomness
    for i = 1, 10 do
        local point = RandomPointInZone("LZ Alpha", 200, 400)
        lu.assertNotNil(point)

        -- Check distance from center
        local dx = point.x - 1000
        local dz = point.z - 2000
        local distance = math.sqrt(dx * dx + dz * dz)

        lu.assertTrue(distance >= 200, "Point should be outside inner radius")
        lu.assertTrue(distance <= 400, "Point should be inside outer radius")
    end
end

function TestZone:testRandomPointInZone_ZeroInnerRadius()
    local point = RandomPointInZone("Small Zone", 0, 50)
    lu.assertNotNil(point)

    local dx = point.x - 0
    local dz = point.z - 0
    local distance = math.sqrt(dx * dx + dz * dz)

    lu.assertTrue(distance <= 50)
end

function TestZone:testRandomPointInZone_NonExistentZone()
    local point = RandomPointInZone("Non Existent")
    lu.assertNil(point)
end

-- IsInPolygonZone tests
function TestZone:testIsInPolygonZone_InsideSquare()
    -- Define a square polygon
    local vertices = {
        { x = 0, y = 0, z = 0 },
        { x = 100, y = 0, z = 0 },
        { x = 100, y = 0, z = 100 },
        { x = 0, y = 0, z = 100 },
    }

    -- Test point in center
    local point = { x = 50, y = 0, z = 50 }
    lu.assertTrue(IsInPolygonZone(point, vertices))

    -- Test point near edge
    point = { x = 10, y = 0, z = 10 }
    lu.assertTrue(IsInPolygonZone(point, vertices))
end

function TestZone:testIsInPolygonZone_OutsideSquare()
    local vertices = {
        { x = 0, y = 0, z = 0 },
        { x = 100, y = 0, z = 0 },
        { x = 100, y = 0, z = 100 },
        { x = 0, y = 0, z = 100 },
    }

    -- Test points outside
    local point = { x = -10, y = 0, z = 50 }
    lu.assertFalse(IsInPolygonZone(point, vertices))

    point = { x = 150, y = 0, z = 50 }
    lu.assertFalse(IsInPolygonZone(point, vertices))

    point = { x = 50, y = 0, z = -10 }
    lu.assertFalse(IsInPolygonZone(point, vertices))

    point = { x = 50, y = 0, z = 150 }
    lu.assertFalse(IsInPolygonZone(point, vertices))
end

function TestZone:testIsInPolygonZone_ComplexPolygon()
    -- Define a star-shaped polygon
    local vertices = {
        { x = 0, y = 0, z = -100 },
        { x = 30, y = 0, z = -30 },
        { x = 100, y = 0, z = 0 },
        { x = 30, y = 0, z = 30 },
        { x = 0, y = 0, z = 100 },
        { x = -30, y = 0, z = 30 },
        { x = -100, y = 0, z = 0 },
        { x = -30, y = 0, z = -30 },
    }

    -- Test center (should be inside)
    local point = { x = 0, y = 0, z = 0 }
    lu.assertTrue(IsInPolygonZone(point, vertices))

    -- Test outside points
    point = { x = 50, y = 0, z = 50 }
    lu.assertFalse(IsInPolygonZone(point, vertices))
end

function TestZone:testIsInPolygonZone_InvalidInputs()
    local vertices = {
        { x = 0, y = 0, z = 0 },
        { x = 100, y = 0, z = 0 },
        { x = 100, y = 0, z = 100 },
        { x = 0, y = 0, z = 100 },
    }

    -- Invalid point
    lu.assertFalse(IsInPolygonZone("not a point", vertices))
    lu.assertFalse(IsInPolygonZone(nil, vertices))

    -- Invalid vertices
    local point = { x = 50, y = 0, z = 50 }
    lu.assertFalse(IsInPolygonZone(point, "not vertices"))
    lu.assertFalse(IsInPolygonZone(point, nil))
end

function TestZone:testIsInPolygonZone_OnEdge()
    local vertices = {
        { x = 0, y = 0, z = 0 },
        { x = 100, y = 0, z = 0 },
        { x = 100, y = 0, z = 100 },
        { x = 0, y = 0, z = 100 },
    }

    -- Test points exactly on edges
    local point = { x = 50, y = 0, z = 0 } -- On bottom edge
    -- Edge cases can vary by implementation
    local result = IsInPolygonZone(point, vertices)
    lu.assertIsBoolean(result)
end

-- GetUnitsInZone and GetGroupsInZone mock tests
function TestZone:testGetUnitsInZone_MockImplementation()
    -- These functions rely heavily on coalition.getGroups which needs complex mocking
    -- Just test basic functionality
    local units = GetUnitsInZone("LZ Alpha")
    lu.assertNotNil(units)
    lu.assertEquals(type(units), "table")
end

function TestZone:testGetGroupsInZone_MockImplementation()
    local groups = GetGroupsInZone("LZ Alpha")
    lu.assertNotNil(groups)
    lu.assertEquals(type(groups), "table")
end

-- Edge cases
function TestZone:testZone_VeryLargeRadius()
    self.mockZones["Huge Zone"] = {
        point = { x = 0, y = 0, z = 0 },
        radius = 999999,
    }

    local radius = GetZoneRadius("Huge Zone")
    lu.assertEquals(radius, 999999)

    -- Any reasonable position should be inside
    local position = { x = 50000, y = 0, z = 50000 }
    lu.assertTrue(IsInZone(position, "Huge Zone"))
end

function TestZone:testZone_ZeroRadius()
    self.mockZones["Point Zone"] = {
        point = { x = 1000, y = 0, z = 2000 },
        radius = 0,
    }

    -- Only the exact center should be "in" the zone
    local position = { x = 1000, y = 0, z = 2000 }
    lu.assertTrue(IsInZone(position, "Point Zone"))

    -- A reasonable distance away should be outside (avoiding floating point precision issues)
    position = { x = 1001, y = 0, z = 2000 } -- 1 meter away
    lu.assertFalse(IsInZone(position, "Point Zone"))
end

return TestZone
