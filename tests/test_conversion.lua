local lu = require("luaunit")

require("conversion")

TestConversion = {}

function TestConversion:test_temperature_conversions()
    lu.assertAlmostEquals(CtoK(0), 273.15, 1e-6)
    lu.assertAlmostEquals(KtoC(273.15), 0, 1e-6)
    lu.assertAlmostEquals(CtoF(0), 32, 1e-6)
    lu.assertAlmostEquals(FtoC(32), 0, 1e-6)
    lu.assertAlmostEquals(KtoF(273.15), 32, 1e-6)
    lu.assertAlmostEquals(FtoK(32), 273.15, 1e-6)

    lu.assertAlmostEquals(ConvertTemperature(20, "C", "F"), 68, 1e-6)
    lu.assertAlmostEquals(ConvertTemperature(68, "F", "C"), 20, 1e-6)
    lu.assertAlmostEquals(ConvertTemperature(293.15, "K", "C"), 20, 1e-6)
    lu.assertAlmostEquals(ConvertTemperature(20, "C", "K"), 293.15, 1e-6)
end

function TestConversion:test_pressure_conversions()
    lu.assertAlmostEquals(PaToInHg(3386.389), 1, 1e-6)
    lu.assertAlmostEquals(InHgToPa(1), 3386.389, 1e-6)
    lu.assertAlmostEquals(PaTohPa(1000), 10, 1e-6)
    lu.assertAlmostEquals(hPaToPa(10), 1000, 1e-6)

    lu.assertAlmostEquals(ConvertPressure(101325, "Pa", "hPa"), 1013.25, 1e-2)
    lu.assertAlmostEquals(ConvertPressure(29.92, "inHg", "hPa"), 1013.207, 1e-1)
    lu.assertAlmostEquals(ConvertPressure(1013.25, "hPa", "inHg"), 29.92, 1e-2)
end

function TestConversion:test_distance_conversions()
    lu.assertAlmostEquals(MetersToFeet(1), 3.280839895, 1e-9)
    lu.assertAlmostEquals(FeetToMeters(3.280839895), 1, 1e-9)
    lu.assertAlmostEquals(ConvertDistance(1000, "m", "ft"), 3280.839895, 1e-6)
    lu.assertAlmostEquals(ConvertDistance(3280.839895, "ft", "m"), 1000, 1e-6)
end

function TestConversion:test_speed_conversions()
    lu.assertAlmostEquals(MpsToKnots(1), 1.943844492, 1e-9)
    lu.assertAlmostEquals(KnotsToMps(1.943844492), 1, 1e-9)
    lu.assertAlmostEquals(ConvertSpeed(100, "mps", "knots"), 194.3844492, 1e-6)
    lu.assertAlmostEquals(ConvertSpeed(194.3844492, "knots", "mps"), 100, 1e-6)
    lu.assertAlmostEquals(GetSpeedIAS(300), KnotsToMps(300), 1e-9)
end

return TestConversion
