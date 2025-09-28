local lu = require("luaunit")

TestTerrainGrade = {}

function TestTerrainGrade:setUp()
    self.original_getHeight = land.getHeight
    land.getHeight = function(vec2)
        -- Plane with slope: height = 0.1*x + 0.0*z
        return 0.1 * (vec2.x or 0)
    end
end

function TestTerrainGrade:tearDown()
    land.getHeight = self.original_getHeight
end

function TestTerrainGrade:testGetTerrainGrade_basic()
    local p = { x = 1000, y = 0, z = 2000 }
    local g = GetTerrainGrade(p, 10, 45)
    lu.assertNotNil(g)
    lu.assertAlmostEquals(g.dzdx, 0.1, 1e-3)
    lu.assertAlmostEquals(g.dzdz, 0.0, 1e-3)
    lu.assertAlmostEquals(g.slopeDeg, math.deg(math.atan(0.1)), 1e-2)
end

return TestTerrainGrade


