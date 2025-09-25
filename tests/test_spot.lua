local lu = require('luaunit')

TestSpot = {}

function TestSpot:setUp()
    -- Save original Spot if it exists
    self.originalSpot = _G.Spot
    
    -- Mock Spot API
    self.mockSpot = {
        destroy = function() end,
        getPoint = function() return {x = 100, y = 50, z = 200} end,
        setPoint = function() end,
        getCode = function() return 1688 end,
        setCode = function() end,
        isExist = function() return true end,
        getCategory = function() return 1 end
    }
    
    _G.Spot = {
        LaserSpotType = {
            LASER = 0,
            INFRARED = 1
        },
        createLaser = function(source, spotType, code)
            return self.mockSpot
        end,
        createInfraRed = function(source, target)
            return self.mockSpot
        end
    }
end

function TestSpot:tearDown()
    -- Restore original Spot
    _G.Spot = self.originalSpot
end

function TestSpot:testCreateLaserSpot()
    local mockUnit = {name = "JTAC-1"}
    local targetPos = {x = 100, y = 50, z = 200}
    
    -- Test valid laser spot creation
    local spot = CreateLaserSpot(mockUnit, targetPos, nil, 1688)
    lu.assertNotNil(spot)
    
    -- Test invalid inputs
    lu.assertNil(CreateLaserSpot(nil, targetPos, nil, 1688))
    lu.assertNil(CreateLaserSpot(mockUnit, targetPos, nil, nil))
    lu.assertNil(CreateLaserSpot(mockUnit, targetPos, nil, "invalid"))
    lu.assertNil(CreateLaserSpot(mockUnit, targetPos, nil, 1000)) -- Too low
    lu.assertNil(CreateLaserSpot(mockUnit, targetPos, nil, 2000)) -- Too high
end

function TestSpot:testCreateIRSpot()
    local mockUnit = {name = "Aircraft-1"}
    local targetPos = {x = 100, y = 50, z = 200}
    
    -- Test valid IR spot creation
    local spot = CreateIRSpot(mockUnit, targetPos)
    lu.assertNotNil(spot)
    
    -- Test invalid inputs
    lu.assertNil(CreateIRSpot(nil, targetPos))
    lu.assertNil(CreateIRSpot(mockUnit, nil))
    lu.assertNil(CreateIRSpot(mockUnit, "invalid"))
end

function TestSpot:testDestroySpot()
    -- Test valid destroy
    lu.assertTrue(DestroySpot(self.mockSpot))
    
    -- Test invalid input
    lu.assertFalse(DestroySpot(nil))
end

function TestSpot:testGetSpotPoint()
    -- Test valid get
    local point = GetSpotPoint(self.mockSpot)
    lu.assertNotNil(point)
    lu.assertEquals(point.x, 100)
    lu.assertEquals(point.y, 50)
    lu.assertEquals(point.z, 200)
    
    -- Test invalid input
    lu.assertNil(GetSpotPoint(nil))
end

function TestSpot:testSetSpotPoint()
    local newPos = {x = 150, y = 60, z = 250}
    
    -- Test valid set
    lu.assertTrue(SetSpotPoint(self.mockSpot, newPos))
    
    -- Test invalid inputs
    lu.assertFalse(SetSpotPoint(nil, newPos))
    lu.assertFalse(SetSpotPoint(self.mockSpot, nil))
    lu.assertFalse(SetSpotPoint(self.mockSpot, "invalid"))
end

function TestSpot:testLaserCode()
    -- Test get code
    lu.assertEquals(GetLaserCode(self.mockSpot), 1688)
    lu.assertNil(GetLaserCode(nil))
    
    -- Test set code
    lu.assertTrue(SetLaserCode(self.mockSpot, 1511))
    lu.assertFalse(SetLaserCode(nil, 1511))
    lu.assertFalse(SetLaserCode(self.mockSpot, nil))
    lu.assertFalse(SetLaserCode(self.mockSpot, "invalid"))
    lu.assertFalse(SetLaserCode(self.mockSpot, 1000)) -- Too low
    lu.assertFalse(SetLaserCode(self.mockSpot, 2000)) -- Too high
end

function TestSpot:testSpotExists()
    lu.assertTrue(SpotExists(self.mockSpot))
    lu.assertFalse(SpotExists(nil))
    
    -- Test with non-existent spot
    local deadSpot = {
        isExist = function() return false end
    }
    lu.assertFalse(SpotExists(deadSpot))
end

function TestSpot:testGetSpotCategory()
    lu.assertEquals(GetSpotCategory(self.mockSpot), 1)
    lu.assertNil(GetSpotCategory(nil))
end