-- test_trigger.lua
local lu = require("luaunit")

TestTrigger = {}

function TestTrigger:setUp()
    -- Reset mock state before each test
    trigger.action._called = {}
    trigger.action._callCount = 0

    -- Ensure logger is initialized
    if not _HarnessInternal.log then
        _HarnessInternal.log = HarnessLogger("Harness")
    end
end

function TestTrigger:testOutText()
    local result = OutText("Hello World", 15, true)
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "outText")
    lu.assertEquals(trigger.action._called[1].args[1], "Hello World")
    lu.assertEquals(trigger.action._called[1].args[2], 15)
    lu.assertEquals(trigger.action._called[1].args[3], true)

    -- Test with invalid text
    local result2 = OutText(nil)
    lu.assertNil(result2)

    -- Test with defaults
    local result3 = OutText("Test")
    lu.assertEquals(result3, true)
    lu.assertEquals(trigger.action._called[2].args[2], 10) -- default displayTime
    lu.assertEquals(trigger.action._called[2].args[3], false) -- default clearView
end

function TestTrigger:testOutTextForCoalition()
    local result = OutTextForCoalition(2, "Blue message", 20, false)
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "outTextForCoalition")
    lu.assertEquals(trigger.action._called[1].args[1], 2)
    lu.assertEquals(trigger.action._called[1].args[2], "Blue message")

    -- Test with invalid coalition
    local result2 = OutTextForCoalition(nil, "Test")
    lu.assertNil(result2)

    -- Test with invalid text
    local result3 = OutTextForCoalition(1, nil)
    lu.assertNil(result3)
end

function TestTrigger:testExplosion()
    local pos = { x = 1000, y = 100, z = 2000 }
    local result = Explosion(pos, 500)
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "explosion")
    lu.assertEquals(trigger.action._called[1].args[1], pos)
    lu.assertEquals(trigger.action._called[1].args[2], 500)

    -- Test with invalid position
    local result2 = Explosion({ x = 100 }, 500)
    lu.assertNil(result2)

    -- Test with invalid power
    local result3 = Explosion(pos, -10)
    lu.assertNil(result3)
end

function TestTrigger:testSmoke()
    local pos = { x = 1000, y = 0, z = 2000 }
    local result = Smoke(pos, 1, 5, "smoke1")
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "smoke")
    lu.assertEquals(trigger.action._called[1].args[1], pos)
    lu.assertEquals(trigger.action._called[1].args[2], 1)
    lu.assertEquals(trigger.action._called[1].args[3], 5)
    lu.assertEquals(trigger.action._called[1].args[4], "smoke1")

    -- Test with invalid position
    local result2 = Smoke(nil, 1)
    lu.assertNil(result2)
end

function TestTrigger:testIlluminationBomb()
    local pos = { x = 1000, y = 500, z = 2000 }
    local result = IlluminationBomb(pos, 2000000)
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "illuminationBomb")

    -- Test with default power
    local result2 = IlluminationBomb(pos)
    lu.assertEquals(result2, true)
    lu.assertEquals(trigger.action._called[2].args[2], 1000000) -- default power
end

function TestTrigger:testSignalFlare()
    local pos = { x = 1000, y = 100, z = 2000 }
    local result = SignalFlare(pos, 1, math.rad(45))
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "signalFlare")

    -- Test with default azimuth
    local result2 = SignalFlare(pos, 1)
    lu.assertEquals(result2, true)
    lu.assertEquals(trigger.action._called[2].args[3], 0) -- default azimuth
end

function TestTrigger:testRadioTransmission()
    local pos = { x = 1000, y = 100, z = 2000 }
    local result = RadioTransmission("sounds/message.ogg", pos, 0, true, 124000000, 100, "radio1")
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "radioTransmission")

    -- Test with defaults
    local result2 = RadioTransmission("test.ogg", pos)
    lu.assertEquals(result2, true)
    lu.assertEquals(trigger.action._called[2].args[3], 0) -- default modulation
    lu.assertEquals(trigger.action._called[2].args[5], 124000000) -- default frequency
    lu.assertEquals(trigger.action._called[2].args[6], 100) -- default power
end

function TestTrigger:testMarkToAll()
    local pos = { x = 1000, y = 0, z = 2000 }
    local result = MarkToAll(1001, "Target", pos, true, "Important")
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "markToAll")
    lu.assertEquals(trigger.action._called[1].args[1], 1001)
    lu.assertEquals(trigger.action._called[1].args[2], "Target")

    -- Test with empty text
    local result2 = MarkToAll(1002, nil, pos)
    lu.assertEquals(result2, true)
    lu.assertEquals(trigger.action._called[2].args[2], "") -- default empty text
end

function TestTrigger:testLineToAll()
    local start = { x = 1000, y = 0, z = 2000 }
    local endPos = { x = 2000, y = 0, z = 3000 }
    local color = { r = 1, g = 0, b = 0, a = 1 }

    local result = LineToAll(2001, start, endPos, color, 1, false, "Line")
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "lineToAll")
    -- Back-compat call uses coalition=-1
    lu.assertEquals(trigger.action._called[1].args[1], -1)
    lu.assertEquals(trigger.action._called[1].args[2], 2001)
    lu.assertEquals(trigger.action._called[1].args[3], start)
    lu.assertEquals(trigger.action._called[1].args[4], endPos)
end

function TestTrigger:testCircleToAll()
    local center = { x = 1000, y = 0, z = 2000 }
    local color = { r = 1, g = 0, b = 0, a = 1 }
    local fillColor = { r = 1, g = 0, b = 0, a = 0.3 }

    local result = CircleToAll(3001, center, 500, color, fillColor, 1, false, "Zone")
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "circleToAll")
    lu.assertEquals(trigger.action._called[1].args[1], -1)
    lu.assertEquals(trigger.action._called[1].args[2], 3001)
    lu.assertEquals(trigger.action._called[1].args[3], center)
    lu.assertEquals(trigger.action._called[1].args[4], 500)
end
function TestTrigger:testTextToAll()
    local pos = { x = 1000, y = 0, z = 2000 }
    local result = TextToAll(
        4001,
        "Hello",
        pos,
        { r = 1, g = 1, b = 1, a = 1 },
        { r = 0, g = 0, b = 0, a = 0.25 },
        18,
        true,
        "msg"
    )
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "textToAll")
    -- Verify DCS ordering: (coalition, id, point, color, fillColor, fontSize, readOnly, text)
    lu.assertEquals(trigger.action._called[1].args[1], -1)
    lu.assertEquals(trigger.action._called[1].args[2], 4001)
    lu.assertEquals(trigger.action._called[1].args[3], pos)
    lu.assertEquals(trigger.action._called[1].args[8], "Hello")
end

function TestTrigger:testActivateGroup()
    -- Ensure we start with a clean state
    trigger.action._called = {}
    trigger.action._callCount = 0

    local mockGroup = { id = 1, name = "TestGroup" }
    local result = TriggerActivateGroup(mockGroup)
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._callCount, 1)
    lu.assertEquals(trigger.action._called[1].func, "activateGroup")
    lu.assertEquals(trigger.action._called[1].args[1], mockGroup)

    -- Test with nil group
    local result2 = TriggerActivateGroup(nil)
    lu.assertNil(result2)
end

function TestTrigger:testMarkupToAll()
    -- Test Line (shapeId = 1)
    local point1 = { x = 1000, y = 0, z = 2000 }
    local point2 = { x = 2000, y = 0, z = 3000 }
    local color = { 1, 0, 0, 1 }
    local fillColor = { 1, 0, 0, 0.3 }

    local result =
        MarkupToAll(1, -1, 5001, point1, point2, color, fillColor, 1, false, "Line Shape")
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "markupToAll")
    lu.assertEquals(trigger.action._called[1].args[1], 1) -- shapeId
    lu.assertEquals(trigger.action._called[1].args[2], -1) -- coalition
    lu.assertEquals(trigger.action._called[1].args[3], 5001) -- id
    lu.assertEquals(trigger.action._called[1].args[4], point1)
    lu.assertEquals(trigger.action._called[1].args[5], point2)

    -- Test Circle (shapeId = 2)
    local result2 = MarkupToAll(2, 0, 5002, point1, 500, color, fillColor, 1, false, "Circle Shape")
    lu.assertEquals(result2, true)
    lu.assertEquals(trigger.action._called[2].args[1], 2)
    lu.assertEquals(trigger.action._called[2].args[5], 500) -- radius

    -- Test Freeform (shapeId = 7) with multiple points
    local point3 = { x = 2000, y = 0, z = 2000 }
    local point4 = { x = 1500, y = 0, z = 1500 }
    local point5 = { x = 1000, y = 0, z = 1500 }
    local point6 = { x = 500, y = 0, z = 2000 }

    local result3 = MarkupToAll(
        7,
        1,
        5003,
        point1,
        point2,
        point3,
        point4,
        point5,
        point6,
        { 0, 0.6, 0.6, 1 },
        { 0.8, 0.8, 0.8, 0.3 },
        4
    )
    lu.assertEquals(result3, true)
    lu.assertEquals(trigger.action._called[3].args[1], 7) -- freeform
    lu.assertEquals(trigger.action._called[3].args[9], point6) -- 6th point (shapeId, coalition, id, point1-6)

    -- Test invalid shapeId
    local result4 = MarkupToAll(0, -1, 5004, point1)
    lu.assertNil(result4)

    local result5 = MarkupToAll(8, -1, 5005, point1)
    lu.assertNil(result5)

    -- Test invalid coalition
    local result6 = MarkupToAll(1, nil, 5006, point1)
    lu.assertNil(result6)

    -- Test invalid id
    local result7 = MarkupToAll(1, -1, nil, point1)
    lu.assertNil(result7)

    -- Test invalid point1
    local result8 = MarkupToAll(1, -1, 5008, { x = 100 }) -- missing y and z
    lu.assertNil(result8)
end

function TestTrigger:testGroupMovementControl()
    local mockGroup = { id = 1, name = "TestGroup" }

    -- Test stop moving
    local result = GroupStopMoving(mockGroup)
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "groupStopMoving")

    -- Test continue moving
    local result2 = GroupContinueMoving(mockGroup)
    lu.assertEquals(result2, true)
    lu.assertEquals(trigger.action._called[2].func, "groupContinueMoving")
end

function TestTrigger:testGroupAIControl()
    local mockGroup = { id = 1, name = "TestGroup" }

    -- Test AI on
    local result = SetGroupAIOn(mockGroup)
    lu.assertEquals(result, true)
    lu.assertEquals(trigger.action._called[1].func, "setGroupAIOn")

    -- Test AI off
    local result2 = SetGroupAIOff(mockGroup)
    lu.assertEquals(result2, true)
    lu.assertEquals(trigger.action._called[2].func, "setGroupAIOff")
end
