local lu = require("luaunit")

TestGlobalSurface = {}

function TestGlobalSurface:testPrivateNamespacesDoNotEnterGlobalTable()
    local privateNames = {
        "AirbaseInternal",
        "AtmosphereInternal",
        "FlightInternal",
        "GeoMathInternal",
        "MissionFileInternal",
        "TriggerInternal",
        "UnitInternal",
        "VectorInternal",
    }

    for _, name in ipairs(privateNames) do
        lu.assertNil(_G[name], name)
    end
end

function TestGlobalSurface:testRemovedGlobalsStayRemoved()
    lu.assertNil(_G.GetPlayers)
    lu.assertNil(_G.ToDcsVec2)
end
