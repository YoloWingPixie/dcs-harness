-- test_unit.lua
local lu = require("luaunit")
require("test_utils")

-- Setup test environment
package.path = package.path .. ";../src/?.lua"

-- Create isolated test suite
TestUnit = CreateIsolatedTestSuite("TestUnit", {})

function TestUnit:setUp()
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
    require("unit")

    -- Clear cache data but preserve functions
    if _HarnessInternal.cache then
        _HarnessInternal.cache.units = {}
        _HarnessInternal.cache.groups = {}
        _HarnessInternal.cache.controllers = {}
        _HarnessInternal.cache.airbases = {}
        _HarnessInternal.cache.stats = { hits = 0, misses = 0, evictions = 0 }
    end

    -- Save original mock function
    self.original_getByName = Unit.getByName

    -- Create more detailed mock units
    self.mockUnits = {
        ["Player"] = {
            isExist = function(self)
                return true
            end,
            getPosition = function(self)
                return {
                    p = { x = 100, y = 50, z = 200 },
                    x = { x = 1, y = 0, z = 0 },
                    y = { x = 0, y = 1, z = 0 },
                    z = { x = 0, y = 0, z = 1 },
                }
            end,
            getVelocity = function(self)
                return { x = 10, y = 0, z = 5 }
            end,
            getTypeName = function(self)
                return "F-16C"
            end,
            getCoalition = function(self)
                return 2
            end,
            getCountry = function(self)
                return 1
            end,
            getGroup = function(self)
                return {
                    getName = function()
                        return "Aerial-1"
                    end,
                }
            end,
            getPlayerName = function(self)
                return "TestPlayer"
            end,
            getLife = function(self)
                return 0.8
            end,
            getLife0 = function(self)
                return 1.0
            end,
            getFuel = function(self)
                return 0.75
            end,
            inAir = function(self)
                return true
            end,
            getAmmo = function(self)
                return {
                    { desc = { typeName = "AIM-120C" }, count = 4 },
                    { desc = { typeName = "AIM-9X" }, count = 2 },
                }
            end,
            getName = function(self)
                return "Player"
            end,
        },
        ["Ground-1"] = {
            isExist = function(self)
                return true
            end,
            getPosition = function(self)
                return {
                    p = { x = 5000, y = 100, z = 6000 },
                    x = { x = 0.866, y = 0, z = 0.5 },
                    y = { x = 0, y = 1, z = 0 },
                    z = { x = -0.5, y = 0, z = 0.866 },
                }
            end,
            getVelocity = function(self)
                return { x = 5, y = 0, z = 0 }
            end,
            getTypeName = function(self)
                return "M1A2"
            end,
            getCoalition = function(self)
                return 2
            end,
            getCountry = function(self)
                return 1
            end,
            getGroup = function(self)
                return {
                    getName = function()
                        return "Armor-1"
                    end,
                }
            end,
            getPlayerName = function(self)
                return nil
            end,
            getLife = function(self)
                return 0.5
            end,
            getLife0 = function(self)
                return 1.0
            end,
            getFuel = function(self)
                return 0.3
            end,
            inAir = function(self)
                return false
            end,
            getAmmo = function(self)
                return {}
            end,
            getName = function(self)
                return "Ground-1"
            end,
        },
        ["Destroyed"] = {
            isExist = function(self)
                return false
            end,
            getPosition = function(self)
                error("Unit does not exist")
            end,
            getVelocity = function(self)
                error("Unit does not exist")
            end,
            getTypeName = function(self)
                return "F-16C"
            end,
            getName = function(self)
                return "Destroyed"
            end,
        },
    }

    -- Override getByName to use mock units
    Unit.getByName = function(name)
        return self.mockUnits[name]
    end
end

function TestUnit:tearDown()
    -- Restore original mock function
    Unit.getByName = self.original_getByName
end

-- GetUnit tests
function TestUnit:testGetUnit_ValidUnit()
    local unit = GetUnit("Player")
    lu.assertNotNil(unit)
    lu.assertEquals(unit:getName(), "Player")
end

function TestUnit:testGetUnit_NonExistentUnit()
    local unit = GetUnit("NonExistent")
    lu.assertNil(unit)
end

function TestUnit:testGetUnit_NilName()
    local unit = GetUnit(nil)
    lu.assertNil(unit)
end

function TestUnit:testGetUnit_InvalidType()
    local unit = GetUnit(12345)
    lu.assertNil(unit)
end

function TestUnit:testGetUnit_EmptyString()
    local unit = GetUnit("")
    lu.assertNil(unit)
end

function TestUnit:testGetUnit_APIError()
    -- Clear cache first
    ClearUnitCache()

    -- Save original function
    local originalGetByName = Unit.getByName

    -- Override with error function
    Unit.getByName = function(name)
        error("DCS API error")
    end

    local unit = GetUnit("TestErrorUnit")
    lu.assertNil(unit)

    -- Restore original function
    Unit.getByName = originalGetByName
end

-- UnitExists tests
function TestUnit:testUnitExists_ExistingUnit()
    local exists = UnitExists("Player")
    lu.assertTrue(exists)
end

function TestUnit:testUnitExists_DestroyedUnit()
    local exists = UnitExists("Destroyed")
    lu.assertFalse(exists)
end

function TestUnit:testUnitExists_NonExistentUnit()
    local exists = UnitExists("NonExistent")
    lu.assertFalse(exists)
end

function TestUnit:testUnitExists_NilName()
    local exists = UnitExists(nil)
    lu.assertFalse(exists)
end

function TestUnit:testUnitExists_APIError()
    self.mockUnits["ErrorUnit"] = {
        isExist = function(self)
            error("API error")
        end,
        getName = function(self)
            return "ErrorUnit"
        end,
    }
    local exists = UnitExists("ErrorUnit")
    lu.assertFalse(exists)
end

-- GetUnitPosition tests
function TestUnit:testGetUnitPosition_ValidUnit()
    local pos = GetUnitPosition("Player")
    lu.assertNotNil(pos)
    lu.assertEquals(pos.x, 100)
    lu.assertEquals(pos.y, 50)
    lu.assertEquals(pos.z, 200)
end

function TestUnit:testGetUnitPosition_GroundUnit()
    local pos = GetUnitPosition("Ground-1")
    lu.assertNotNil(pos)
    lu.assertEquals(pos.x, 5000)
    lu.assertEquals(pos.y, 100)
    lu.assertEquals(pos.z, 6000)
end

function TestUnit:testGetUnitPosition_NonExistentUnit()
    local pos = GetUnitPosition("NonExistent")
    lu.assertNil(pos)
end

function TestUnit:testGetUnitPosition_DestroyedUnit()
    local pos = GetUnitPosition("Destroyed")
    lu.assertNil(pos)
end

function TestUnit:testGetUnitPosition_InvalidPositionStructure()
    -- Test handling of malformed position data (DCS should never return this, but test defensive coding)
    self.mockUnits["BadPosition"] = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return {}
        end, -- Intentionally missing p field for error testing
        getName = function(self)
            return "BadPosition"
        end,
    }
    local pos = GetUnitPosition("BadPosition")
    lu.assertNil(pos)
end

-- GetUnitHeading tests
function TestUnit:testGetUnitHeading_NorthFacing()
    local heading = GetUnitHeading("Player")
    lu.assertNotNil(heading)
    lu.assertEquals(heading, 0) -- Facing north (x.x=1, x.z=0)
end

function TestUnit:testGetUnitHeading_NortheastFacing()
    local heading = GetUnitHeading("Ground-1")
    lu.assertNotNil(heading)
    lu.assertAlmostEquals(heading, 30, 0.1) -- ~30 degrees
end

function TestUnit:testGetUnitHeading_NonExistentUnit()
    local heading = GetUnitHeading("NonExistent")
    lu.assertNil(heading)
end

function TestUnit:testGetUnitHeading_SouthFacing()
    self.mockUnits["SouthUnit"] = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return {
                p = { x = 0, y = 0, z = 0 },
                x = { x = -1, y = 0, z = 0 }, -- Facing south
            }
        end,
        getName = function(self)
            return "SouthUnit"
        end,
    }
    local heading = GetUnitHeading("SouthUnit")
    lu.assertNotNil(heading)
    lu.assertEquals(heading, 180)
end

function TestUnit:testGetUnitHeading_WestFacing()
    self.mockUnits["WestUnit"] = {
        isExist = function(self)
            return true
        end,
        getPosition = function(self)
            return {
                p = { x = 0, y = 0, z = 0 },
                x = { x = 0, y = 0, z = -1 }, -- Facing west
            }
        end,
        getName = function(self)
            return "WestUnit"
        end,
    }
    local heading = GetUnitHeading("WestUnit")
    lu.assertNotNil(heading)
    lu.assertEquals(heading, 270)
end

-- GetUnitVelocity tests
function TestUnit:testGetUnitVelocity_MovingUnit()
    local vel = GetUnitVelocity("Player")
    lu.assertNotNil(vel)
    lu.assertEquals(vel.x, 10)
    lu.assertEquals(vel.y, 0)
    lu.assertEquals(vel.z, 5)
end

function TestUnit:testGetUnitVelocity_StationaryUnit()
    self.mockUnits["Stationary"] = {
        isExist = function(self)
            return true
        end,
        getVelocity = function(self)
            return { x = 0, y = 0, z = 0 }
        end,
        getName = function(self)
            return "Stationary"
        end,
    }
    local vel = GetUnitVelocity("Stationary")
    lu.assertNotNil(vel)
    lu.assertEquals(vel.x, 0)
    lu.assertEquals(vel.y, 0)
    lu.assertEquals(vel.z, 0)
end

function TestUnit:testGetUnitVelocity_NonExistentUnit()
    local vel = GetUnitVelocity("NonExistent")
    lu.assertNil(vel)
end

function TestUnit:testGetUnitVelocity_APIError()
    self.mockUnits["VelError"] = {
        isExist = function(self)
            return true
        end,
        getVelocity = function(self)
            error("API error")
        end,
        getName = function(self)
            return "VelError"
        end,
    }
    local vel = GetUnitVelocity("VelError")
    lu.assertNil(vel)
end

-- GetUnitType tests
function TestUnit:testGetUnitType_Aircraft()
    local unitType = GetUnitType("Player")
    lu.assertEquals(unitType, "F-16C")
end

function TestUnit:testGetUnitType_GroundUnit()
    local unitType = GetUnitType("Ground-1")
    lu.assertEquals(unitType, "M1A2")
end

function TestUnit:testGetUnitType_NonExistentUnit()
    local unitType = GetUnitType("NonExistent")
    lu.assertNil(unitType)
end

-- GetUnitCoalition tests
function TestUnit:testGetUnitCoalition_BlueUnit()
    local coalition = GetUnitCoalition("Player")
    lu.assertEquals(coalition, 2) -- Blue
end

function TestUnit:testGetUnitCoalition_RedUnit()
    self.mockUnits["RedUnit"] = {
        isExist = function(self)
            return true
        end,
        getCoalition = function(self)
            return 1
        end,
        getName = function(self)
            return "RedUnit"
        end,
    }
    local coalition = GetUnitCoalition("RedUnit")
    lu.assertEquals(coalition, 1)
end

function TestUnit:testGetUnitCoalition_NeutralUnit()
    self.mockUnits["NeutralUnit"] = {
        isExist = function(self)
            return true
        end,
        getCoalition = function(self)
            return 0
        end,
        getName = function(self)
            return "NeutralUnit"
        end,
    }
    local coalition = GetUnitCoalition("NeutralUnit")
    lu.assertEquals(coalition, 0)
end

-- GetUnitCountry tests
function TestUnit:testGetUnitCountry_USA()
    local country = GetUnitCountry("Player")
    lu.assertEquals(country, 1) -- USA
end

function TestUnit:testGetUnitCountry_Russia()
    self.mockUnits["RussianUnit"] = {
        isExist = function(self)
            return true
        end,
        getCountry = function(self)
            return 2
        end,
        getName = function(self)
            return "RussianUnit"
        end,
    }
    local country = GetUnitCountry("RussianUnit")
    lu.assertEquals(country, 2)
end

-- GetUnitGroup tests
function TestUnit:testGetUnitGroup_ValidGroup()
    local group = GetUnitGroup("Player")
    lu.assertNotNil(group)
    lu.assertEquals(group:getName(), "Aerial-1")
end

function TestUnit:testGetUnitController_should_store_group_and_unitnames()
    -- Ensure mock unit supports getController for this test
    self.mockUnits["Player"].getController = function(self)
        return {}
    end

    local unit = GetUnit("Player")
    lu.assertNotNil(unit)
    local _ = GetUnitController(unit)

    local entry = GetCacheTables().controllers["unit:Player"]
    lu.assertNotNil(entry)
    lu.assertEquals(entry.groupName, "Aerial-1")
    lu.assertNotNil(entry.unitNames)
    local found = false
    for i = 1, #entry.unitNames do
        if entry.unitNames[i] == "Player" then
            found = true
            break
        end
    end
    lu.assertTrue(found)
end

function TestUnit:testGetUnitGroup_NonExistentUnit()
    local group = GetUnitGroup("NonExistent")
    lu.assertNil(group)
end

-- GetUnitPlayerName tests
function TestUnit:testGetUnitPlayerName_PlayerControlled()
    local playerName = GetUnitPlayerName("Player")
    lu.assertEquals(playerName, "TestPlayer")
end

function TestUnit:testGetUnitPlayerName_AIControlled()
    local playerName = GetUnitPlayerName("Ground-1")
    lu.assertNil(playerName)
end

function TestUnit:testGetUnitPlayerName_EmptyPlayerName()
    self.mockUnits["EmptyPlayer"] = {
        isExist = function(self)
            return true
        end,
        getPlayerName = function(self)
            return ""
        end,
        getName = function(self)
            return "EmptyPlayer"
        end,
    }
    local playerName = GetUnitPlayerName("EmptyPlayer")
    lu.assertEquals(playerName, "")
end

-- GetUnitLife tests
function TestUnit:testGetUnitLife_HealthyUnit()
    local life = GetUnitLife("Player")
    lu.assertEquals(life, 0.8)
end

function TestUnit:testGetUnitLife_DamagedUnit()
    local life = GetUnitLife("Ground-1")
    lu.assertEquals(life, 0.5)
end

function TestUnit:testGetUnitLife_FullHealth()
    self.mockUnits["FullHealth"] = {
        isExist = function(self)
            return true
        end,
        getLife = function(self)
            return 1.0
        end,
        getName = function(self)
            return "FullHealth"
        end,
    }
    local life = GetUnitLife("FullHealth")
    lu.assertEquals(life, 1.0)
end

function TestUnit:testGetUnitLife_NearDeath()
    self.mockUnits["NearDeath"] = {
        isExist = function(self)
            return true
        end,
        getLife = function(self)
            return 0.01
        end,
        getName = function(self)
            return "NearDeath"
        end,
    }
    local life = GetUnitLife("NearDeath")
    lu.assertEquals(life, 0.01)
end

-- GetUnitLife0 tests
function TestUnit:testGetUnitLife0_StandardUnit()
    local maxLife = GetUnitLife0("Player")
    lu.assertEquals(maxLife, 1.0)
end

function TestUnit:testGetUnitLife0_NonStandardMax()
    self.mockUnits["HeavyUnit"] = {
        isExist = function(self)
            return true
        end,
        getLife0 = function(self)
            return 5.0
        end,
        getName = function(self)
            return "HeavyUnit"
        end,
    }
    local maxLife = GetUnitLife0("HeavyUnit")
    lu.assertEquals(maxLife, 5.0)
end

-- GetUnitFuel tests
function TestUnit:testGetUnitFuel_PartialFuel()
    local fuel = GetUnitFuel("Player")
    lu.assertEquals(fuel, 0.75)
end

function TestUnit:testGetUnitFuel_LowFuel()
    local fuel = GetUnitFuel("Ground-1")
    lu.assertEquals(fuel, 0.3)
end

function TestUnit:testGetUnitFuel_FullTank()
    self.mockUnits["FullTank"] = {
        isExist = function(self)
            return true
        end,
        getFuel = function(self)
            return 1.0
        end,
        getName = function(self)
            return "FullTank"
        end,
    }
    local fuel = GetUnitFuel("FullTank")
    lu.assertEquals(fuel, 1.0)
end

function TestUnit:testGetUnitFuel_EmptyTank()
    self.mockUnits["EmptyTank"] = {
        isExist = function(self)
            return true
        end,
        getFuel = function(self)
            return 0.0
        end,
        getName = function(self)
            return "EmptyTank"
        end,
    }
    local fuel = GetUnitFuel("EmptyTank")
    lu.assertEquals(fuel, 0.0)
end

function TestUnit:testGetUnitFuel_ExternalTanks()
    self.mockUnits["ExternalTanks"] = {
        isExist = function(self)
            return true
        end,
        getFuel = function(self)
            return 1.5
        end, -- >1.0 with external tanks
        getName = function(self)
            return "ExternalTanks"
        end,
    }
    local fuel = GetUnitFuel("ExternalTanks")
    lu.assertEquals(fuel, 1.5)
end

-- IsUnitInAir tests
function TestUnit:testIsUnitInAir_FlyingAircraft()
    local inAir = IsUnitInAir("Player")
    lu.assertTrue(inAir)
end

function TestUnit:testIsUnitInAir_GroundUnit()
    local inAir = IsUnitInAir("Ground-1")
    lu.assertFalse(inAir)
end

function TestUnit:testIsUnitInAir_NonExistentUnit()
    local inAir = IsUnitInAir("NonExistent")
    lu.assertFalse(inAir)
end

function TestUnit:testIsUnitInAir_ParkedAircraft()
    self.mockUnits["Parked"] = {
        isExist = function(self)
            return true
        end,
        inAir = function(self)
            return false
        end,
        getName = function(self)
            return "Parked"
        end,
    }
    local inAir = IsUnitInAir("Parked")
    lu.assertFalse(inAir)
end

-- GetUnitAmmo tests
function TestUnit:testGetUnitAmmo_ArmedAircraft()
    local ammo = GetUnitAmmo("Player")
    lu.assertNotNil(ammo)
    lu.assertEquals(#ammo, 2)
    lu.assertEquals(ammo[1].desc.typeName, "AIM-120C")
    lu.assertEquals(ammo[1].count, 4)
    lu.assertEquals(ammo[2].desc.typeName, "AIM-9X")
    lu.assertEquals(ammo[2].count, 2)
end

function TestUnit:testGetUnitAmmo_UnarmedUnit()
    local ammo = GetUnitAmmo("Ground-1")
    lu.assertNotNil(ammo)
    lu.assertEquals(#ammo, 0)
end

function TestUnit:testGetUnitAmmo_NonExistentUnit()
    local ammo = GetUnitAmmo("NonExistent")
    lu.assertNil(ammo)
end

function TestUnit:testGetUnitAmmo_PartiallyExpended()
    self.mockUnits["PartialAmmo"] = {
        isExist = function(self)
            return true
        end,
        getAmmo = function(self)
            return {
                { desc = { typeName = "AGM-65D" }, count = 2 },
                { desc = { typeName = "AIM-9X" }, count = 0 }, -- Expended
            }
        end,
        getName = function(self)
            return "PartialAmmo"
        end,
    }
    local ammo = GetUnitAmmo("PartialAmmo")
    lu.assertNotNil(ammo)
    lu.assertEquals(ammo[1].count, 2)
    lu.assertEquals(ammo[2].count, 0)
end

-- Edge cases
function TestUnit:testUnit_VeryLongName()
    local longName = string.rep("a", 1000)
    self.mockUnits[longName] = {
        isExist = function(self)
            return true
        end,
        getName = function(self)
            return longName
        end,
    }
    local unit = GetUnit(longName)
    lu.assertNotNil(unit)
end

function TestUnit:testUnit_SpecialCharactersInName()
    local specialName = "Unit-123_Test!@#"
    self.mockUnits[specialName] = {
        isExist = function(self)
            return true
        end,
        getTypeName = function(self)
            return "F-16C"
        end,
        getName = function(self)
            return specialName
        end,
    }
    local unitType = GetUnitType(specialName)
    lu.assertEquals(unitType, "F-16C")
end

function TestUnit:testUnit_NegativeLifeValue()
    self.mockUnits["NegativeLife"] = {
        isExist = function(self)
            return true
        end,
        getLife = function(self)
            return -0.1
        end, -- Should not happen but test anyway
        getName = function(self)
            return "NegativeLife"
        end,
    }
    local life = GetUnitLife("NegativeLife")
    lu.assertEquals(life, -0.1)
end

function TestUnit:testUnit_VeryHighSpeed()
    self.mockUnits["Hypersonic"] = {
        isExist = function(self)
            return true
        end,
        getVelocity = function(self)
            return { x = 2000, y = 100, z = 500 }
        end,
        getName = function(self)
            return "Hypersonic"
        end,
    }
    local vel = GetUnitVelocity("Hypersonic")
    lu.assertNotNil(vel)
    lu.assertEquals(vel.x, 2000)
end

-- Convenience getters tests merged here

function TestUnit:test_convenience_speed_and_altitude()
    local name = "Player"
    local mps = GetUnitSpeedMps(name)
    local kts = GetUnitSpeedKnots(name)
    lu.assertEquals(type(mps), "number")
    lu.assertEquals(type(kts), "number")
    lu.assertTrue(mps >= 0)
    lu.assertTrue(kts >= 0)

    local vs = GetUnitVerticalSpeedFeet(name)
    lu.assertEquals(type(vs), "number")

    local msl = GetUnitAltitudeMSLFeet(name)
    local agl = GetUnitAltitudeAGLFeet(name)
    lu.assertEquals(type(msl), "number")
    lu.assertEquals(type(agl), "number")
end

return TestUnit
