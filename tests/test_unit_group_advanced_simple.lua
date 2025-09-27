local lu = require("luaunit")

TestAdvancedFunctions = {}

function TestAdvancedFunctions:testAllFunctionsExist()
    -- Test that all advanced unit functions exist
    lu.assertIsFunction(GetUnitID)
    lu.assertIsFunction(GetUnitNumber)
    lu.assertIsFunction(GetUnitCallsign)
    lu.assertIsFunction(GetUnitObjectID)
    lu.assertIsFunction(GetUnitCategoryEx)
    lu.assertIsFunction(GetUnitDesc)
    lu.assertIsFunction(GetUnitForcesName)
    lu.assertIsFunction(IsUnitActive)
    lu.assertIsFunction(GetUnitController)

    -- Sensor functions
    lu.assertIsFunction(GetUnitSensors)
    lu.assertIsFunction(UnitHasSensors)
    lu.assertIsFunction(GetUnitRadar)
    lu.assertIsFunction(EnableUnitEmissions)

    -- Cargo functions
    lu.assertIsFunction(GetUnitNearestCargos)
    lu.assertIsFunction(GetUnitCargosOnBoard)
    lu.assertIsFunction(GetUnitDescentCapacity)
    lu.assertIsFunction(GetUnitDescentOnBoard)
    lu.assertIsFunction(LoadUnitCargo)
    lu.assertIsFunction(UnloadUnitCargo)
    lu.assertIsFunction(OpenUnitRamp)
    lu.assertIsFunction(CheckUnitRampOpen)
    lu.assertIsFunction(DisembarkUnit)
    lu.assertIsFunction(MarkUnitDisembarkingTask)
    lu.assertIsFunction(IsUnitEmbarking)

    -- Aircraft functions
    lu.assertIsFunction(GetUnitAirbase)
    lu.assertIsFunction(UnitCanShipLanding)
    lu.assertIsFunction(UnitHasCarrier)
    lu.assertIsFunction(GetUnitNearestCargosForAircraft)
    lu.assertIsFunction(GetUnitFuelLowState)
    lu.assertIsFunction(ShowUnitCarrierMenu)

    -- Other functions
    lu.assertIsFunction(GetUnitDrawArgument)
    lu.assertIsFunction(GetUnitCommunicator)
    lu.assertIsFunction(GetUnitSeats)

    -- Test that all advanced group functions exist
    lu.assertIsFunction(GetGroupName)
    lu.assertIsFunction(GetGroupUnit)
    lu.assertIsFunction(GetGroupCategoryEx)
    lu.assertIsFunction(EnableGroupEmissions)
    lu.assertIsFunction(DestroyGroup)
    lu.assertIsFunction(IsGroupEmbarking)
    lu.assertIsFunction(MarkGroup)
end

function TestAdvancedFunctions:testNilHandling()
    -- Test that all functions handle nil gracefully

    -- Unit functions should return nil or false
    lu.assertNil(GetUnitID(nil))
    lu.assertNil(GetUnitNumber(nil))
    lu.assertNil(GetUnitCallsign(nil))
    lu.assertNil(GetUnitObjectID(nil))
    lu.assertNil(GetUnitCategoryEx(nil))
    lu.assertNil(GetUnitDesc(nil))
    lu.assertNil(GetUnitForcesName(nil))
    lu.assertFalse(IsUnitActive(nil))
    lu.assertNil(GetUnitController(nil))

    lu.assertNil(GetUnitSensors(nil))
    lu.assertFalse(UnitHasSensors(nil, 1))
    local active, target = GetUnitRadar(nil)
    lu.assertFalse(active)
    lu.assertNil(target)
    lu.assertFalse(EnableUnitEmissions(nil, true))

    lu.assertEquals(#GetUnitNearestCargos(nil), 0)
    lu.assertEquals(#GetUnitCargosOnBoard(nil), 0)
    lu.assertNil(GetUnitDescentCapacity(nil))
    lu.assertNil(GetUnitDescentOnBoard(nil))
    lu.assertFalse(LoadUnitCargo(nil, {}))
    lu.assertFalse(UnloadUnitCargo(nil))
    lu.assertFalse(OpenUnitRamp(nil))
    lu.assertNil(CheckUnitRampOpen(nil))
    lu.assertFalse(DisembarkUnit(nil))
    lu.assertFalse(MarkUnitDisembarkingTask(nil))
    lu.assertNil(IsUnitEmbarking(nil))

    lu.assertNil(GetUnitAirbase(nil))
    lu.assertNil(UnitCanShipLanding(nil))
    lu.assertNil(UnitHasCarrier(nil))
    lu.assertEquals(#GetUnitNearestCargosForAircraft(nil), 0)
    lu.assertNil(GetUnitFuelLowState(nil))
    lu.assertFalse(ShowUnitCarrierMenu(nil))

    lu.assertNil(GetUnitDrawArgument(nil, 0))
    lu.assertNil(GetUnitCommunicator(nil))
    lu.assertNil(GetUnitSeats(nil))

    -- Group functions
    lu.assertNil(GetGroupName(nil))
    lu.assertNil(GetGroupUnit(nil, 1))
    lu.assertNil(GetGroupCategoryEx(nil))
    lu.assertFalse(EnableGroupEmissions(nil, true))
    lu.assertFalse(DestroyGroup(nil))
    lu.assertNil(IsGroupEmbarking(nil))
    lu.assertFalse(MarkGroup(nil, { x = 0, y = 0, z = 0 }, "text"))
end
