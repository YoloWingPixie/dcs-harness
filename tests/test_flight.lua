local lu = require("luaunit")

TestFlight = {}

local northPosition = {
    p = { x = 10, y = 20, z = 30 },
    x = { x = 1, y = 0, z = 0 },
    y = { x = 0, y = 1, z = 0 },
    z = { x = 0, y = 0, z = 1 },
}

function TestFlight:testPosition3AndAttitude()
    local calls = 0
    local unit = {
        getPosition = function()
            calls = calls + 1
            return northPosition
        end,
    }
    local position = GetUnitPosition3(unit)
    lu.assertEquals(position, northPosition)
    lu.assertEquals(calls, 1)
    local attitude = GetAttitudeFromPosition3(position)
    lu.assertEquals(attitude.headingDeg, 0)
    lu.assertEquals(attitude.pitchDeg, 0)
    lu.assertEquals(attitude.bankDeg, 0)

    local east = {
        p = northPosition.p,
        x = { x = 0, y = 0, z = 1 },
        y = { x = 0, y = 1, z = 0 },
        z = { x = -1, y = 0, z = 0 },
    }
    lu.assertAlmostEquals(GetAttitudeFromPosition3(east).headingDeg, 90, 1e-9)

    local pitched = {
        p = northPosition.p,
        x = { x = math.sqrt(0.5), y = math.sqrt(0.5), z = 0 },
        y = { x = -math.sqrt(0.5), y = math.sqrt(0.5), z = 0 },
        z = { x = 0, y = 0, z = 1 },
    }
    lu.assertAlmostEquals(GetAttitudeFromPosition3(pitched).pitchDeg, 45, 1e-8)

    local banked = {
        p = northPosition.p,
        x = northPosition.x,
        y = { x = 0, y = math.sqrt(0.5), z = -math.sqrt(0.5) },
        z = { x = 0, y = math.sqrt(0.5), z = math.sqrt(0.5) },
    }
    lu.assertAlmostEquals(GetAttitudeFromPosition3(banked).bankDeg, 45, 1e-8)
    lu.assertNil(GetAttitudeFromPosition3({ p = northPosition.p, x = northPosition.x }))
end

function TestFlight:testAirRelativeVelocityAndAerodynamicAngles()
    lu.assertEquals(
        AirRelativeVelocity({ x = 100, y = 5, z = 10 }, { x = 20, y = -1, z = 3 }),
        Vec3(80, 6, 7)
    )
    local level = GetAerodynamicAngles(northPosition, { x = 100, y = 0, z = 0 })
    lu.assertAlmostEquals(level.aoaDeg, 0, 1e-9)
    lu.assertAlmostEquals(level.betaDeg, 0, 1e-9)
    lu.assertAlmostEquals(level.trueAirspeedMps, 100, 1e-9)

    local positiveAoa = GetAerodynamicAngles(northPosition, { x = 100, y = -10, z = 0 })
    lu.assertTrue(positiveAoa.aoaDeg > 0)
    local sideslip = GetAerodynamicAngles(northPosition, { x = 100, y = 0, z = 10 })
    lu.assertTrue(sideslip.betaDeg > 0)
    lu.assertNil(GetAerodynamicAngles(northPosition, { x = 1, y = 0, z = 0 }))
end

function TestFlight:testIsaMachAndCas()
    local seaLevel = CalculateIsaAtmosphere(0)
    lu.assertAlmostEquals(seaLevel.temperatureK, 288.15, 1e-9)
    lu.assertAlmostEquals(seaLevel.pressurePa, 101325, 1e-6)
    lu.assertAlmostEquals(seaLevel.densityKgM3, 1.225, 0.001)
    lu.assertEquals(seaLevel.source, HarnessConstants.AIR_DATA_SOURCE_ISA)

    local transition = CalculateIsaAtmosphere(11000)
    local above = CalculateIsaAtmosphere(11001)
    lu.assertAlmostEquals(transition.temperatureK, above.temperatureK, 0.01)
    lu.assertTrue(above.pressurePa < transition.pressurePa)
    lu.assertNil(CalculateIsaAtmosphere(-1))
    lu.assertNil(CalculateIsaAtmosphere(20001))

    local speedOfSound = seaLevel.speedOfSoundMps
    lu.assertAlmostEquals(MachFromTrueAirspeed(speedOfSound, seaLevel.temperatureK), 1, 1e-9)
    lu.assertAlmostEquals(
        TrueAirspeedToCalibratedAirspeed(100, seaLevel.temperatureK, seaLevel.pressurePa),
        100,
        1e-6
    )
    lu.assertNil(
        TrueAirspeedToCalibratedAirspeed(
            speedOfSound * 1.01,
            seaLevel.temperatureK,
            seaLevel.pressurePa
        )
    )
end

function TestFlight:testGetAirDataPrefersDcsAndFallsBack()
    local original = atmosphere.getTemperatureAndPressure
    atmosphere.getTemperatureAndPressure = function()
        return 280, 90000
    end
    local dcs = GetAirData({ x = 0, y = 1000, z = 0 })
    lu.assertEquals(dcs.source, HarnessConstants.AIR_DATA_SOURCE_DCS)
    lu.assertAlmostEquals(dcs.densityKgM3, 90000 / (287.05 * 280), 1e-9)

    atmosphere.getTemperatureAndPressure = function()
        error("unavailable")
    end
    local fallback = GetAirData({ x = 0, y = 1000, z = 0 })
    lu.assertEquals(fallback.source, HarnessConstants.AIR_DATA_SOURCE_ISA)
    atmosphere.getTemperatureAndPressure = original
end

function TestFlight:testBatchDrawArguments()
    local unit = {
        getDrawArgumentValue = function(_, id)
            if id == 3 then
                error("failed")
            end
            if id == 5 then
                return "invalid"
            end
            return id / 10
        end,
    }
    local values, complete = GetUnitDrawArguments(unit, { 0, 3, 5, 7 })
    lu.assertFalse(complete)
    lu.assertEquals(values[0], 0)
    lu.assertNil(values[3])
    lu.assertNil(values[5])
    lu.assertEquals(values[7], 0.7)
    lu.assertNil(GetUnitDrawArguments(unit, { 1, "bad" }))
end

return TestFlight
