local lu = require("luaunit")

TestCoalition = {}

function TestCoalition:setUp()
    self.originalGetGroups = coalition.getGroups
    self.mockGroups = {
        ["Aerial-1"] = {
            getName = function()
                return "Aerial-1"
            end,
        },
        ["Ground-1"] = {
            getName = function()
                return "Ground-1"
            end,
        },
        ["Empty-1"] = {},
    }
end

function TestCoalition:tearDown()
    coalition.getGroups = self.originalGetGroups
end

function TestCoalition:testGetCoalitionGroups_ValidCoalition()
    coalition.getGroups = function(coalitionId, categoryId)
        if coalitionId == 2 and categoryId == 0 then
            return { self.mockGroups["Aerial-1"] }
        elseif coalitionId == 1 and categoryId == 2 then
            return { self.mockGroups["Ground-1"] }
        end
        return {}
    end

    local blueAir = GetCoalitionGroups(2, 0)
    lu.assertEquals(#blueAir, 1)
    lu.assertEquals(blueAir[1]:getName(), "Aerial-1")

    local redGround = GetCoalitionGroups(1, 2)
    lu.assertEquals(#redGround, 1)
    lu.assertEquals(redGround[1]:getName(), "Ground-1")
end

function TestCoalition:testGetCoalitionGroups_AllCategories()
    coalition.getGroups = function(coalitionId, categoryId)
        if coalitionId == 2 and not categoryId then
            return { self.mockGroups["Aerial-1"], self.mockGroups["Empty-1"] }
        end
        return {}
    end

    local blueAll = GetCoalitionGroups(2)
    lu.assertEquals(#blueAll, 2)
end

function TestCoalition:testGetCoalitionGroups_EmptyResult()
    coalition.getGroups = function()
        return nil
    end

    local groups = GetCoalitionGroups(2, 0)
    lu.assertNotNil(groups)
    lu.assertEquals(#groups, 0)
end

function TestCoalition:testGetCoalitionGroups_InvalidCoalition()
    local groups = GetCoalitionGroups(nil, 0)
    lu.assertNotNil(groups, "GetCoalitionGroups should return a table, not nil")
    lu.assertEquals(type(groups), "table", "GetCoalitionGroups should return a table")
    lu.assertEquals(#groups, 0)
end

function TestCoalition:testGetCoalitionGroups_InvalidType()
    local groups = GetCoalitionGroups("not a number", 0)
    lu.assertNotNil(groups, "GetCoalitionGroups should return a table, not nil")
    lu.assertEquals(type(groups), "table", "GetCoalitionGroups should return a table")
    lu.assertEquals(#groups, 0)
end

function TestCoalition:testGetCoalitionGroups_APIError()
    coalition.getGroups = function()
        error("API error")
    end

    local groups = GetCoalitionGroups(2, 0)
    lu.assertEquals(#groups, 0)
end

return TestCoalition
