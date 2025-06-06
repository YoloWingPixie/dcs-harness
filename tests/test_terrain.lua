-- test_terrain.lua
local lu = require('luaunit')

-- Setup test environment
package.path = package.path .. ';../src/?.lua'
require('mock_dcs')
require('_header')
require('logger')
require('vector')
require('terrain')

TestTerrain = {}

function TestTerrain:setUp()
    -- Save original mock functions
    self.original_getHeight = land.getHeight
    self.original_isVisible = land.isVisible
    self.original_getSurfaceType = land.getSurfaceType
    self.original_getIP = land.getIP
    self.original_profile = land.profile
    self.original_getClosestPointOnRoads = land.getClosestPointOnRoads
    self.original_findPathOnRoads = land.findPathOnRoads
end

function TestTerrain:tearDown()
    -- Restore original mock functions
    land.getHeight = self.original_getHeight
    land.isVisible = self.original_isVisible
    land.getSurfaceType = self.original_getSurfaceType
    land.getIP = self.original_getIP
    land.profile = self.original_profile
    land.getClosestPointOnRoads = self.original_getClosestPointOnRoads
    land.findPathOnRoads = self.original_findPathOnRoads
end

-- GetTerrainHeight tests
function TestTerrain:testGetTerrainHeight_Vec3Input()
    local position = {x = 1000, y = 500, z = 2000}
    local height = GetTerrainHeight(position)
    lu.assertEquals(height, 100.0)
end

function TestTerrain:testGetTerrainHeight_Vec2Input()
    local position = {x = 1000, y = 2000}
    local height = GetTerrainHeight(position)
    lu.assertEquals(height, 100.0)
end

function TestTerrain:testGetTerrainHeight_NilInput()
    local height = GetTerrainHeight(nil)
    lu.assertEquals(height, 0)
end

function TestTerrain:testGetTerrainHeight_InvalidInput()
    local height = GetTerrainHeight("not a position")
    lu.assertEquals(height, 0)
end

function TestTerrain:testGetTerrainHeight_EmptyTable()
    local height = GetTerrainHeight({})
    lu.assertEquals(height, 100) -- Empty table converts to Vec2(0,0) which is valid
end

function TestTerrain:testGetTerrainHeight_APIError()
    land.getHeight = function(vec2)
        error("API error")
    end
    local position = {x = 1000, y = 2000}
    local height = GetTerrainHeight(position)
    lu.assertEquals(height, 0)
end

function TestTerrain:testGetTerrainHeight_NilReturn()
    land.getHeight = function(vec2)
        return nil
    end
    local position = {x = 1000, y = 2000}
    local height = GetTerrainHeight(position)
    lu.assertEquals(height, 0)
end

-- GetAGL tests
function TestTerrain:testGetAGL_ValidPosition()
    local position = {x = 1000, y = 500, z = 2000}
    local agl = GetAGL(position)
    lu.assertEquals(agl, 400)  -- 500 - 100
end

function TestTerrain:testGetAGL_OnGround()
    local position = {x = 1000, y = 100, z = 2000}
    local agl = GetAGL(position)
    lu.assertEquals(agl, 0)
end

function TestTerrain:testGetAGL_BelowGround()
    local position = {x = 1000, y = 50, z = 2000}
    local agl = GetAGL(position)
    lu.assertEquals(agl, -50)
end

function TestTerrain:testGetAGL_InvalidInput()
    local agl = GetAGL({x = 1000, y = 2000})  -- Vec2 instead of Vec3
    lu.assertEquals(agl, 0)
end

function TestTerrain:testGetAGL_NilInput()
    local agl = GetAGL(nil)
    lu.assertEquals(agl, 0)
end

-- SetAGL tests
function TestTerrain:testSetAGL_ValidInputs()
    local position = {x = 1000, y = 999, z = 2000}
    local newPos = SetAGL(position, 200)
    lu.assertEquals(newPos.x, 1000)
    lu.assertEquals(newPos.y, 300)  -- 100 + 200
    lu.assertEquals(newPos.z, 2000)
end

function TestTerrain:testSetAGL_ZeroAGL()
    local position = {x = 1000, y = 500, z = 2000}
    local newPos = SetAGL(position, 0)
    lu.assertEquals(newPos.y, 100)
end

function TestTerrain:testSetAGL_NegativeAGL()
    local position = {x = 1000, y = 500, z = 2000}
    local newPos = SetAGL(position, -50)
    lu.assertEquals(newPos.y, 50)  -- 100 - 50
end

function TestTerrain:testSetAGL_InvalidPosition()
    local newPos = SetAGL("not a position", 100)
    lu.assertEquals(newPos.x, 0)
    lu.assertEquals(newPos.y, 0)
    lu.assertEquals(newPos.z, 0)
end

function TestTerrain:testSetAGL_InvalidAGL()
    local position = {x = 1000, y = 500, z = 2000}
    local newPos = SetAGL(position, "not a number")
    lu.assertEquals(newPos.x, 0)
    lu.assertEquals(newPos.y, 0)
    lu.assertEquals(newPos.z, 0)
end

-- HasLOS tests
function TestTerrain:testHasLOS_ValidPositions()
    local from = {x = 1000, y = 200, z = 2000}
    local to = {x = 2000, y = 300, z = 3000}
    local hasLOS = HasLOS(from, to)
    lu.assertTrue(hasLOS)
end

function TestTerrain:testHasLOS_NoLineOfSight()
    land.isVisible = function(from, to)
        return false
    end
    local from = {x = 1000, y = 200, z = 2000}
    local to = {x = 2000, y = 300, z = 3000}
    local hasLOS = HasLOS(from, to)
    lu.assertFalse(hasLOS)
end

function TestTerrain:testHasLOS_InvalidFrom()
    local to = {x = 2000, y = 300, z = 3000}
    local hasLOS = HasLOS("not a vec3", to)
    lu.assertFalse(hasLOS)
end

function TestTerrain:testHasLOS_InvalidTo()
    local from = {x = 1000, y = 200, z = 2000}
    local hasLOS = HasLOS(from, "not a vec3")
    lu.assertFalse(hasLOS)
end

function TestTerrain:testHasLOS_APIError()
    land.isVisible = function(from, to)
        error("API error")
    end
    local from = {x = 1000, y = 200, z = 2000}
    local to = {x = 2000, y = 300, z = 3000}
    local hasLOS = HasLOS(from, to)
    lu.assertFalse(hasLOS)
end

-- GetSurfaceType tests
function TestTerrain:testGetSurfaceType_Vec3Input()
    local position = {x = 1000, y = 100, z = 2000}
    local surfaceType = GetSurfaceType(position)
    lu.assertEquals(surfaceType, 1)  -- Default mock returns 1 (land)
end

function TestTerrain:testGetSurfaceType_Vec2Input()
    local position = {x = 1000, y = 2000}
    local surfaceType = GetSurfaceType(position)
    lu.assertEquals(surfaceType, 1)
end

function TestTerrain:testGetSurfaceType_WaterSurface()
    land.getSurfaceType = function(vec2)
        return 3  -- water
    end
    local position = {x = 1000, y = 2000}
    local surfaceType = GetSurfaceType(position)
    lu.assertEquals(surfaceType, 3)
end

function TestTerrain:testGetSurfaceType_NilInput()
    local surfaceType = GetSurfaceType(nil)
    lu.assertNil(surfaceType)
end

function TestTerrain:testGetSurfaceType_InvalidInput()
    local surfaceType = GetSurfaceType("not a position")
    lu.assertNil(surfaceType)
end

function TestTerrain:testGetSurfaceType_APIError()
    land.getSurfaceType = function(vec2)
        error("API error")
    end
    local position = {x = 1000, y = 2000}
    local surfaceType = GetSurfaceType(position)
    lu.assertNil(surfaceType)
end

-- IsOverWater tests
function TestTerrain:testIsOverWater_DeepWater()
    land.getSurfaceType = function(vec2)
        return 3  -- water
    end
    local position = {x = 1000, y = 2000}
    lu.assertTrue(IsOverWater(position))
end

function TestTerrain:testIsOverWater_ShallowWater()
    land.getSurfaceType = function(vec2)
        return 2  -- shallow water
    end
    local position = {x = 1000, y = 2000}
    lu.assertTrue(IsOverWater(position))
end

function TestTerrain:testIsOverWater_Land()
    land.getSurfaceType = function(vec2)
        return 1  -- land
    end
    local position = {x = 1000, y = 2000}
    lu.assertFalse(IsOverWater(position))
end

function TestTerrain:testIsOverWater_InvalidPosition()
    lu.assertFalse(IsOverWater(nil))
end

-- IsOverLand tests
function TestTerrain:testIsOverLand_Land()
    land.getSurfaceType = function(vec2)
        return 1  -- land
    end
    local position = {x = 1000, y = 2000}
    lu.assertTrue(IsOverLand(position))
end

function TestTerrain:testIsOverLand_Road()
    land.getSurfaceType = function(vec2)
        return 4  -- road
    end
    local position = {x = 1000, y = 2000}
    lu.assertTrue(IsOverLand(position))
end

function TestTerrain:testIsOverLand_Runway()
    land.getSurfaceType = function(vec2)
        return 5  -- runway
    end
    local position = {x = 1000, y = 2000}
    lu.assertTrue(IsOverLand(position))
end

function TestTerrain:testIsOverLand_Water()
    land.getSurfaceType = function(vec2)
        return 3  -- water
    end
    local position = {x = 1000, y = 2000}
    lu.assertFalse(IsOverLand(position))
end

-- GetTerrainIntersection tests
function TestTerrain:testGetTerrainIntersection_ValidInputs()
    local origin = {x = 1000, y = 500, z = 2000}
    local direction = {x = 0, y = -1, z = 0}
    local intersection = GetTerrainIntersection(origin, direction, 10000)
    lu.assertNotNil(intersection)
    lu.assertEquals(intersection.x, 100)
    lu.assertEquals(intersection.y, 50)
    lu.assertEquals(intersection.z, 200)
end

function TestTerrain:testGetTerrainIntersection_NoIntersection()
    land.getIP = function(origin, direction, maxDistance)
        return nil
    end
    local origin = {x = 1000, y = 500, z = 2000}
    local direction = {x = 0, y = 1, z = 0}  -- Pointing up
    local intersection = GetTerrainIntersection(origin, direction, 10000)
    lu.assertNil(intersection)
end

function TestTerrain:testGetTerrainIntersection_InvalidOrigin()
    local direction = {x = 0, y = -1, z = 0}
    local intersection = GetTerrainIntersection("not a vec3", direction, 10000)
    lu.assertNil(intersection)
end

function TestTerrain:testGetTerrainIntersection_InvalidDirection()
    local origin = {x = 1000, y = 500, z = 2000}
    local intersection = GetTerrainIntersection(origin, "not a vec3", 10000)
    lu.assertNil(intersection)
end

function TestTerrain:testGetTerrainIntersection_InvalidDistance()
    local origin = {x = 1000, y = 500, z = 2000}
    local direction = {x = 0, y = -1, z = 0}
    local intersection = GetTerrainIntersection(origin, direction, "not a number")
    lu.assertNil(intersection)
end

function TestTerrain:testGetTerrainIntersection_APIError()
    land.getIP = function(origin, direction, maxDistance)
        error("API error")
    end
    local origin = {x = 1000, y = 500, z = 2000}
    local direction = {x = 0, y = -1, z = 0}
    local intersection = GetTerrainIntersection(origin, direction, 10000)
    lu.assertNil(intersection)
end

-- GetTerrainProfile tests
function TestTerrain:testGetTerrainProfile_ValidInputs()
    local from = {x = 1000, y = 200, z = 2000}
    local to = {x = 2000, y = 300, z = 3000}
    local profile = GetTerrainProfile(from, to)
    lu.assertNotNil(profile)
    lu.assertEquals(#profile, 2)
    lu.assertEquals(profile[1].x, 0)
    lu.assertEquals(profile[1].y, 100)
end

function TestTerrain:testGetTerrainProfile_InvalidFrom()
    local to = {x = 2000, y = 300, z = 3000}
    local profile = GetTerrainProfile("not a vec3", to)
    lu.assertEquals(#profile, 0)
end

function TestTerrain:testGetTerrainProfile_InvalidTo()
    local from = {x = 1000, y = 200, z = 2000}
    local profile = GetTerrainProfile(from, "not a vec3")
    lu.assertEquals(#profile, 0)
end

function TestTerrain:testGetTerrainProfile_APIError()
    land.profile = function(from, to)
        error("API error")
    end
    local from = {x = 1000, y = 200, z = 2000}
    local to = {x = 2000, y = 300, z = 3000}
    local profile = GetTerrainProfile(from, to)
    lu.assertEquals(#profile, 0)
end

function TestTerrain:testGetTerrainProfile_NilReturn()
    land.profile = function(from, to)
        return nil
    end
    local from = {x = 1000, y = 200, z = 2000}
    local to = {x = 2000, y = 300, z = 3000}
    local profile = GetTerrainProfile(from, to)
    lu.assertEquals(#profile, 0)
end

-- GetClosestRoadPoint tests
function TestTerrain:testGetClosestRoadPoint_Vec3Input()
    local position = {x = 1000, y = 100, z = 2000}
    local point = GetClosestRoadPoint(position)
    lu.assertNotNil(point)
    lu.assertEquals(point.x, 1000)
    lu.assertEquals(point.y, 0)
    lu.assertEquals(point.z, 2000)
end

function TestTerrain:testGetClosestRoadPoint_Vec2Input()
    local position = {x = 1000, y = 2000}
    local point = GetClosestRoadPoint(position)
    lu.assertNotNil(point)
    lu.assertEquals(point.x, 1000)
    lu.assertEquals(point.y, 0)
    lu.assertEquals(point.z, 2000)
end

function TestTerrain:testGetClosestRoadPoint_RailsType()
    local position = {x = 1000, y = 2000}
    local point = GetClosestRoadPoint(position, "rails")
    lu.assertNotNil(point)
end

function TestTerrain:testGetClosestRoadPoint_NilInput()
    local point = GetClosestRoadPoint(nil)
    lu.assertNil(point)
end

function TestTerrain:testGetClosestRoadPoint_InvalidInput()
    local point = GetClosestRoadPoint("not a position")
    lu.assertNil(point)
end

function TestTerrain:testGetClosestRoadPoint_APIError()
    land.getClosestPointOnRoads = function(roadType, x, y)
        error("API error")
    end
    local position = {x = 1000, y = 2000}
    local point = GetClosestRoadPoint(position)
    lu.assertNil(point)
end

-- FindRoadPath tests
function TestTerrain:testFindRoadPath_ValidInputs()
    local from = {x = 1000, y = 100, z = 2000}
    local to = {x = 3000, y = 150, z = 4000}
    local path = FindRoadPath(from, to)
    lu.assertNotNil(path)
    lu.assertEquals(#path, 2)
    lu.assertEquals(path[1].x, 1000)
    lu.assertEquals(path[2].x, 3000)
end

function TestTerrain:testFindRoadPath_Vec2Inputs()
    local from = {x = 1000, y = 2000}
    local to = {x = 3000, y = 4000}
    local path = FindRoadPath(from, to)
    lu.assertNotNil(path)
    lu.assertEquals(#path, 2)
end

function TestTerrain:testFindRoadPath_RailroadsType()
    local from = {x = 1000, y = 2000}
    local to = {x = 3000, y = 4000}
    local path = FindRoadPath(from, to, "railroads")
    lu.assertNotNil(path)
    -- Should convert "railroads" to "rails"
end

function TestTerrain:testFindRoadPath_NilFrom()
    local to = {x = 3000, y = 4000}
    local path = FindRoadPath(nil, to)
    lu.assertEquals(#path, 0)
end

function TestTerrain:testFindRoadPath_NilTo()
    local from = {x = 1000, y = 2000}
    local path = FindRoadPath(from, nil)
    lu.assertEquals(#path, 0)
end

function TestTerrain:testFindRoadPath_InvalidInputs()
    local path = FindRoadPath("not a position", "not a position")
    lu.assertEquals(#path, 0)
end

function TestTerrain:testFindRoadPath_NoPathFound()
    land.findPathOnRoads = function(roadType, x1, y1, x2, y2)
        return nil
    end
    local from = {x = 1000, y = 2000}
    local to = {x = 3000, y = 4000}
    local path = FindRoadPath(from, to)
    lu.assertEquals(#path, 0)
end

function TestTerrain:testFindRoadPath_APIError()
    land.findPathOnRoads = function(roadType, x1, y1, x2, y2)
        error("API error")
    end
    local from = {x = 1000, y = 2000}
    local to = {x = 3000, y = 4000}
    local path = FindRoadPath(from, to)
    lu.assertEquals(#path, 0)
end

-- Edge cases
function TestTerrain:testTerrainHeight_VeryHighAltitude()
    land.getHeight = function(vec2)
        return 8848  -- Mount Everest height
    end
    local position = {x = 1000, y = 2000}
    local height = GetTerrainHeight(position)
    lu.assertEquals(height, 8848)
end

function TestTerrain:testTerrainHeight_BelowSeaLevel()
    land.getHeight = function(vec2)
        return -430  -- Dead Sea depth
    end
    local position = {x = 1000, y = 2000}
    local height = GetTerrainHeight(position)
    lu.assertEquals(height, -430)
end

function TestTerrain:testSurfaceType_UnknownType()
    land.getSurfaceType = function(vec2)
        return 999  -- Unknown surface type
    end
    local position = {x = 1000, y = 2000}
    local surfaceType = GetSurfaceType(position)
    lu.assertEquals(surfaceType, 999)
    lu.assertFalse(IsOverWater(position))
    lu.assertFalse(IsOverLand(position))
end

return TestTerrain