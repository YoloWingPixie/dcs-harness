local lu = require("luaunit")

require("atmosphere")

TestAtmosphereConvenience = {}

function TestAtmosphereConvenience:test_wind_knots()
    local p = { x = 0, y = 0, z = 0 }
    local w = GetWindKnots(p)
    lu.assertNotNil(w)
    lu.assertEquals(type(w.headingDeg), "number")
    lu.assertEquals(type(w.speedKts), "number")
    lu.assertTrue(w.speedKts >= 0)
    local wt = GetWindWithTurbulenceKnots(p)
    lu.assertNotNil(wt)
    lu.assertEquals(type(wt.headingDeg), "number")
    lu.assertEquals(type(wt.speedKts), "number")
end

function TestAtmosphereConvenience:test_temp_pressure_converted()
    local p = { x = 0, y = 0, z = 0 }
    local c = GetTemperatureC(p)
    local f = GetTemperatureF(p)
    local hPa = GetPressurehPa(p)
    local inHg = GetPressureInHg(p)
    lu.assertEquals(type(c), "number")
    lu.assertEquals(type(f), "number")
    lu.assertEquals(type(hPa), "number")
    lu.assertEquals(type(inHg), "number")
end

return TestAtmosphereConvenience
