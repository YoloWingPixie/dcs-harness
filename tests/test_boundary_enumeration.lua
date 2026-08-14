local lu = require("luaunit")

TestBoundaryEnumeration = {}

local function namedHandle(name, point, exists)
    return {
        getName = function()
            return name
        end,
        getPoint = function()
            return point or { x = 0, y = 0, z = 0 }
        end,
        isExist = exists == nil and nil or function()
            return exists
        end,
    }
end

function TestBoundaryEnumeration:setUp()
    self.originalWorld = world
    self.originalCoalition = coalition
    self.originalNet = net
end

function TestBoundaryEnumeration:tearDown()
    world = self.originalWorld
    coalition = self.originalCoalition
    net = self.originalNet
end

function TestBoundaryEnumeration:testAirbaseEnumerationMergesDeduplicatesAndSorts()
    local alpha = namedHandle("Alpha", { x = 0, y = 0, z = 0 })
    local bravo = namedHandle("Bravo", { x = 100, y = 0, z = 0 })
    local invalid = {
        getName = function()
            error("invalid")
        end,
    }
    world = {
        getAirbases = function()
            return { bravo, invalid }
        end,
    }
    coalition = {
        side = { NEUTRAL = 0, RED = 1, BLUE = 2 },
        getAirbases = function(side)
            if side == 0 then
                return { alpha }
            end
            return { bravo }
        end,
    }

    local airbases = GetAllAirbases()
    lu.assertEquals(airbases, { alpha, bravo })
    local matches = FindAirbasesWithin(airbases, { x = 25, y = 0, z = 0 }, 100)
    lu.assertEquals(#matches, 2)
    lu.assertEquals(matches[1].airbase, alpha)
    lu.assertEquals(matches[1].distanceM, 25)
    lu.assertEquals(matches[2].airbase, bravo)

    world = nil
    local fallback = GetAllAirbases()
    lu.assertEquals(fallback, { alpha, bravo })

    coalition.getAirbases = function()
        error("failure")
    end
    lu.assertNil(GetAllAirbases())
end

function TestBoundaryEnumeration:testPlayerEnumerationRequiresAllCoalitions()
    local alpha = namedHandle("Alpha", nil, true)
    local bravo = namedHandle("Bravo", nil, true)
    local stale = namedHandle("Stale", nil, false)
    coalition = {
        side = { NEUTRAL = 0, RED = 1, BLUE = 2 },
        getPlayers = function(side)
            if side == 0 then
                return { bravo, stale }
            elseif side == 1 then
                return { alpha }
            end
            return { bravo }
        end,
    }
    lu.assertEquals(GetAllPlayerUnits(), { alpha, bravo })

    coalition.getPlayers = function()
        return {}
    end
    lu.assertEquals(GetAllPlayerUnits(), {})

    coalition.getPlayers = function(side)
        if side == 1 then
            error("failed")
        end
        return {}
    end
    lu.assertNil(GetAllPlayerUnits())
end

function TestBoundaryEnumeration:testNetworkApisAndDuplicateNames()
    net = {
        get_player_list = function()
            return { 1, 2, 3 }
        end,
        get_player_info = function(id)
            if id == 2 then
                error("failed")
            end
            return { id = id, name = "Same" }
        end,
    }
    lu.assertEquals(GetPlayerIds(), { 1, 2, 3 })
    local infos = GetPlayerInfos()
    lu.assertEquals(#infos, 2)
    local matches = FindPlayerInfosByName("Same", infos)
    lu.assertEquals(#matches, 2)

    local calls = 0
    net.get_player_list = function()
        calls = calls + 1
        return {}
    end
    lu.assertEquals(FindPlayerInfosByName("Same", infos), matches)
    lu.assertEquals(calls, 0)

    net = nil
    lu.assertNil(GetPlayerIds())
    lu.assertNil(GetPlayerInfos())
end

function TestBoundaryEnumeration:testEventUnitUsesStaleNamedHandle()
    local stale = namedHandle("Stale")
    stale.isExist = function()
        return false
    end
    local fallback = namedHandle("Fallback")
    local unit, name = GetWorldEventUnit({ initiator = stale, unit = fallback })
    lu.assertEquals(unit, stale)
    lu.assertEquals(name, "Stale")

    stale.getName = function()
        error("failed")
    end
    unit, name = GetWorldEventUnit({ initiator = stale, unit = fallback })
    lu.assertEquals(unit, fallback)
    lu.assertEquals(name, "Fallback")
    lu.assertNil(GetWorldEventUnit({}))
end

return TestBoundaryEnumeration
