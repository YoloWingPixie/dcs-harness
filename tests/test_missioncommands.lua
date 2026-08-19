local lu = require("luaunit")

TestMissionCommands = {}

function TestMissionCommands:setUp()
    self.original = missionCommands
    self.calls = {}
    local calls = self.calls
    missionCommands = {
        addCommand = function(...)
            calls.globalCommand = { ... }
            return { "global" }
        end,
        addSubMenu = function(...)
            calls.globalSubmenu = { ... }
            return { "global-sub" }
        end,
        removeItem = function(...)
            calls.globalRemove = { ... }
        end,
        addCommandForCoalition = function(...)
            calls.coalitionCommand = { ... }
            return { "coalition" }
        end,
        addSubMenuForCoalition = function(...)
            calls.coalitionSubmenu = { ... }
            return { "coalition-sub" }
        end,
        removeItemForCoalition = function(...)
            calls.coalitionRemove = { ... }
        end,
        addCommandForGroup = function(...)
            calls.groupCommand = { ... }
            return { "group" }
        end,
        addSubMenuForGroup = function(...)
            calls.groupSubmenu = { ... }
            return { "group-sub" }
        end,
        removeItemForGroup = function(...)
            calls.groupRemove = { ... }
        end,
    }
end

function TestMissionCommands:tearDown()
    missionCommands = self.original
end

function TestMissionCommands:testNativeArgumentOrderAndRootPaths()
    local handler = function() end
    local argument = { value = 1 }
    lu.assertEquals(AddCommand(nil, { name = "Global" }, handler, argument), { "global" })
    lu.assertEquals(self.calls.globalCommand, { "Global", nil, handler, argument })
    lu.assertEquals(AddSubMenu(nil, "Global Sub"), { "global-sub" })
    lu.assertEquals(self.calls.globalSubmenu, { "Global Sub", nil })

    lu.assertEquals(
        AddCommandForCoalition(2, nil, { name = "Coalition" }, handler, argument),
        { "coalition" }
    )
    lu.assertEquals(self.calls.coalitionCommand, { 2, "Coalition", nil, handler, argument })
    lu.assertEquals(AddSubMenuForCoalition(2, nil, "Coalition Sub"), { "coalition-sub" })
    lu.assertEquals(self.calls.coalitionSubmenu, { 2, "Coalition Sub", nil })

    lu.assertEquals(AddCommandForGroup(42, nil, { name = "Group" }, handler, argument), { "group" })
    lu.assertEquals(self.calls.groupCommand, { 42, "Group", nil, handler, argument })
    lu.assertEquals(AddSubMenuForGroup(42, nil, "Group Sub"), { "group-sub" })
    lu.assertEquals(self.calls.groupSubmenu, { 42, "Group Sub", nil })

    lu.assertTrue(RemoveItem(nil))
    lu.assertTrue(RemoveItemForCoalition(2, nil))
    lu.assertTrue(RemoveItemForGroup(42, nil))
end

function TestMissionCommands:testRejectsMissingCaption()
    lu.assertNil(AddCommand(nil, {}, function() end))
    lu.assertNil(AddCommandForCoalition(2, nil, { name = "" }, function() end))
    lu.assertNil(AddCommandForGroup(42, nil, {}, function() end))
end

return TestMissionCommands
