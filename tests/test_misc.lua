-- Unit tests for misc.lua module
local lu = require("luaunit")

TestMisc = {}

-- Test DeepCopy
function TestMisc:testDeepCopy()
    -- Test simple values
    lu.assertEquals(DeepCopy(5), 5)
    lu.assertEquals(DeepCopy("hello"), "hello")
    lu.assertEquals(DeepCopy(true), true)
    lu.assertEquals(DeepCopy(nil), nil)

    -- Test simple table
    local t1 = { a = 1, b = 2, c = 3 }
    local t1_copy = DeepCopy(t1)
    lu.assertEquals(t1_copy, t1)
    lu.assertNotIs(t1_copy, t1) -- Different objects

    -- Test nested table
    local t2 = {
        x = 1,
        y = {
            z = 2,
            w = {
                v = 3,
            },
        },
    }
    local t2_copy = DeepCopy(t2)
    lu.assertEquals(t2_copy, t2)
    lu.assertNotIs(t2_copy.y, t2.y)
    lu.assertNotIs(t2_copy.y.w, t2.y.w)

    -- Modify copy doesn't affect original
    t2_copy.y.z = 999
    lu.assertEquals(t2.y.z, 2)
    lu.assertEquals(t2_copy.y.z, 999)
end

-- Test ShallowCopy
function TestMisc:testShallowCopy()
    -- Test simple values
    lu.assertEquals(ShallowCopy(5), 5)
    lu.assertEquals(ShallowCopy("hello"), "hello")

    -- Test simple table
    local t1 = { a = 1, b = 2, c = 3 }
    local t1_copy = ShallowCopy(t1)
    lu.assertEquals(t1_copy, t1)
    lu.assertNotIs(t1_copy, t1)

    -- Test nested table - inner tables are same reference
    local inner = { x = 1 }
    local t2 = { a = inner, b = 2 }
    local t2_copy = ShallowCopy(t2)
    lu.assertIs(t2_copy.a, t2.a) -- Same reference

    -- Modifying inner table affects both
    t2_copy.a.x = 999
    lu.assertEquals(t2.a.x, 999)
end

-- Test Contains
function TestMisc:testContains()
    local t = { 1, 2, 3, "hello", true }

    lu.assertTrue(Contains(t, 1))
    lu.assertTrue(Contains(t, 3))
    lu.assertTrue(Contains(t, "hello"))
    lu.assertTrue(Contains(t, true))

    lu.assertFalse(Contains(t, 4))
    lu.assertFalse(Contains(t, "world"))
    lu.assertFalse(Contains(t, false))

    -- Test with non-sequential table
    local t2 = { a = 1, b = 2, c = 3 }
    lu.assertTrue(Contains(t2, 2))
    lu.assertFalse(Contains(t2, "a"))

    -- Test invalid input
    lu.assertFalse(Contains(nil, 1))
    lu.assertFalse(Contains("not a table", 1))
end

-- Test ContainsKey
function TestMisc:testContainsKey()
    local t = { a = 1, b = 2, c = nil, [1] = "one" }

    lu.assertTrue(ContainsKey(t, "a"))
    lu.assertTrue(ContainsKey(t, "b"))
    lu.assertFalse(ContainsKey(t, "c")) -- nil value
    lu.assertTrue(ContainsKey(t, 1))
    lu.assertFalse(ContainsKey(t, "d"))

    -- Test invalid input
    lu.assertFalse(ContainsKey(nil, "a"))
    lu.assertFalse(ContainsKey("not a table", "a"))
end

-- Test TableSize
function TestMisc:testTableSize()
    -- Empty table
    lu.assertEquals(TableSize({}), 0)

    -- Sequential table
    lu.assertEquals(TableSize({ 1, 2, 3 }), 3)

    -- Non-sequential table
    lu.assertEquals(TableSize({ a = 1, b = 2, c = 3 }), 3)

    -- Mixed table
    lu.assertEquals(TableSize({ 1, 2, a = 3, b = 4 }), 4)

    -- Table with gaps
    local t = {}
    t[1] = "a"
    t[3] = "c"
    t[10] = "j"
    lu.assertEquals(TableSize(t), 3)

    -- Invalid input
    lu.assertEquals(TableSize(nil), 0)
    lu.assertEquals(TableSize("not a table"), 0)
end

-- Test TableKeys
function TestMisc:testTableKeys()
    local t = { a = 1, b = 2, c = 3 }
    local keys = TableKeys(t)

    lu.assertEquals(#keys, 3)
    lu.assertTrue(Contains(keys, "a"))
    lu.assertTrue(Contains(keys, "b"))
    lu.assertTrue(Contains(keys, "c"))

    -- Test mixed keys
    local t2 = { [1] = "one", ["hello"] = "world", [true] = "yes" }
    local keys2 = TableKeys(t2)
    lu.assertEquals(#keys2, 3)
    lu.assertTrue(Contains(keys2, 1))
    lu.assertTrue(Contains(keys2, "hello"))
    lu.assertTrue(Contains(keys2, true))

    -- Invalid input
    lu.assertEquals(TableKeys(nil), {})
    lu.assertEquals(TableKeys("not a table"), {})
end

-- Test TableValues
function TestMisc:testTableValues()
    local t = { a = 1, b = 2, c = 3 }
    local values = TableValues(t)

    lu.assertEquals(#values, 3)
    lu.assertTrue(Contains(values, 1))
    lu.assertTrue(Contains(values, 2))
    lu.assertTrue(Contains(values, 3))

    -- Invalid input
    lu.assertEquals(TableValues(nil), {})
    lu.assertEquals(TableValues("not a table"), {})
end

-- Test MergeTables
function TestMisc:testMergeTables()
    local t1 = { a = 1, b = 2 }
    local t2 = { b = 3, c = 4 }
    local merged = MergeTables(t1, t2)

    lu.assertEquals(merged.a, 1)
    lu.assertEquals(merged.b, 3) -- t2 overwrites t1
    lu.assertEquals(merged.c, 4)

    -- Original tables unchanged
    lu.assertEquals(t1.b, 2)
    lu.assertEquals(t2.b, 3)

    -- Test with nil inputs
    lu.assertEquals(MergeTables(nil, { a = 1 }), { a = 1 })
    lu.assertEquals(MergeTables({ a = 1 }, nil), { a = 1 })
end

-- Test FilterTable
function TestMisc:testFilterTable()
    local t = { a = 1, b = 2, c = 3, d = 4, e = 5 }

    -- Filter even values
    local evens = FilterTable(t, function(v, k)
        return v % 2 == 0
    end)
    lu.assertEquals(TableSize(evens), 2)
    lu.assertEquals(evens.b, 2)
    lu.assertEquals(evens.d, 4)

    -- Filter by key
    local vowels = FilterTable(t, function(v, k)
        return k == "a" or k == "e"
    end)
    lu.assertEquals(TableSize(vowels), 2)
    lu.assertEquals(vowels.a, 1)
    lu.assertEquals(vowels.e, 5)

    -- Invalid input
    lu.assertEquals(
        FilterTable(nil, function()
            return true
        end),
        {}
    )
    lu.assertEquals(FilterTable(t, nil), {})
end

-- Test MapTable
function TestMisc:testMapTable()
    local t = { a = 1, b = 2, c = 3 }

    -- Double values
    local doubled = MapTable(t, function(v, k)
        return v * 2
    end)
    lu.assertEquals(doubled.a, 2)
    lu.assertEquals(doubled.b, 4)
    lu.assertEquals(doubled.c, 6)

    -- Transform to strings
    local strings = MapTable(t, function(v, k)
        return k .. "=" .. v
    end)
    lu.assertEquals(strings.a, "a=1")
    lu.assertEquals(strings.b, "b=2")
    lu.assertEquals(strings.c, "c=3")

    -- Invalid input
    lu.assertEquals(
        MapTable(nil, function(v)
            return v
        end),
        {}
    )
    lu.assertEquals(MapTable(t, nil), {})
end

-- Test Clamp
function TestMisc:testClamp()
    -- Normal cases
    lu.assertEquals(Clamp(5, 0, 10), 5)
    lu.assertEquals(Clamp(-5, 0, 10), 0)
    lu.assertEquals(Clamp(15, 0, 10), 10)

    -- Edge cases
    lu.assertEquals(Clamp(0, 0, 10), 0)
    lu.assertEquals(Clamp(10, 0, 10), 10)

    -- Negative ranges
    lu.assertEquals(Clamp(-5, -10, -1), -5)
    lu.assertEquals(Clamp(0, -10, -1), -1)
    lu.assertEquals(Clamp(-15, -10, -1), -10)

    -- Decimal values
    lu.assertAlmostEquals(Clamp(0.5, 0.1, 0.9), 0.5, 0.0001)
    lu.assertAlmostEquals(Clamp(0.05, 0.1, 0.9), 0.1, 0.0001)
end

-- Test Lerp
function TestMisc:testLerp()
    -- Basic interpolation
    lu.assertEquals(Lerp(0, 10, 0), 0)
    lu.assertEquals(Lerp(0, 10, 0.5), 5)
    lu.assertEquals(Lerp(0, 10, 1), 10)

    -- Negative values
    lu.assertEquals(Lerp(-10, 10, 0.5), 0)
    lu.assertEquals(Lerp(-10, -5, 0.5), -7.5)

    -- Extrapolation
    lu.assertEquals(Lerp(0, 10, 2), 20)
    lu.assertEquals(Lerp(0, 10, -1), -10)
end

-- Test Round
function TestMisc:testRound()
    -- Default (0 decimals)
    lu.assertEquals(Round(3.14159), 3)
    lu.assertEquals(Round(3.5), 4)
    lu.assertEquals(Round(3.49999), 3)
    lu.assertEquals(Round(-3.5), -3)

    -- With decimals
    lu.assertEquals(Round(3.14159, 2), 3.14)
    lu.assertEquals(Round(3.14159, 3), 3.142)
    lu.assertEquals(Round(3.14159, 0), 3)

    -- Edge cases
    lu.assertEquals(Round(0.999, 2), 1.00)
    lu.assertEquals(Round(-0.5, 0), 0) -- Rounds toward positive
end

-- Test RandomFloat
function TestMisc:testRandomFloat()
    -- Test range
    for i = 1, 100 do
        local val = RandomFloat(1.0, 2.0)
        lu.assertTrue(val >= 1.0)
        lu.assertTrue(val <= 2.0)
    end

    -- Test negative range
    for i = 1, 100 do
        local val = RandomFloat(-2.0, -1.0)
        lu.assertTrue(val >= -2.0)
        lu.assertTrue(val <= -1.0)
    end
end

-- Test RandomInt
function TestMisc:testRandomInt()
    -- Test range
    for i = 1, 100 do
        local val = RandomInt(1, 10)
        lu.assertTrue(val >= 1)
        lu.assertTrue(val <= 10)
        lu.assertEquals(val, math.floor(val)) -- Is integer
    end

    -- Test single value
    lu.assertEquals(RandomInt(5, 5), 5)
end

-- Test RandomChoice
function TestMisc:testRandomChoice()
    local choices = { "a", "b", "c", "d", "e" }

    -- Test that it returns valid choices
    for i = 1, 50 do
        local choice = RandomChoice(choices)
        lu.assertTrue(Contains(choices, choice))
    end

    -- Test empty array
    lu.assertNil(RandomChoice({}))

    -- Test invalid input
    lu.assertNil(RandomChoice(nil))
    lu.assertNil(RandomChoice("not a table"))
end

-- Test Shuffle
function TestMisc:testShuffle()
    local arr = { 1, 2, 3, 4, 5 }
    local original = { 1, 2, 3, 4, 5 }

    local shuffled = Shuffle(arr)

    -- Same array reference
    lu.assertIs(shuffled, arr)

    -- Same elements
    lu.assertEquals(#shuffled, 5)
    for i = 1, 5 do
        lu.assertTrue(Contains(shuffled, i))
    end

    -- Usually different order (might occasionally be same)
    -- We can't guarantee it's different, but we can test multiple times
    local different = false
    for attempt = 1, 10 do
        Shuffle(arr)
        for i = 1, 5 do
            if arr[i] ~= original[i] then
                different = true
                break
            end
        end
        if different then
            break
        end
    end
    -- This might rarely fail due to random chance
end

-- Test ShuffledCopy
function TestMisc:testShuffledCopy()
    local arr = { 1, 2, 3, 4, 5 }
    local copy = ShuffledCopy(arr)

    -- Different array
    lu.assertNotIs(copy, arr)

    -- Original unchanged
    lu.assertEquals(arr[1], 1)
    lu.assertEquals(arr[2], 2)

    -- Copy has same elements
    lu.assertEquals(#copy, 5)
    for i = 1, 5 do
        lu.assertTrue(Contains(copy, i))
    end
end

-- Test SplitString
function TestMisc:testSplitString()
    -- Default delimiter (comma)
    local parts = SplitString("a,b,c,d")
    lu.assertEquals(parts, { "a", "b", "c", "d" })

    -- Custom delimiter
    local parts2 = SplitString("one|two|three", "|")
    lu.assertEquals(parts2, { "one", "two", "three" })

    -- Spaces
    local parts3 = SplitString("hello world test", " ")
    lu.assertEquals(parts3, { "hello", "world", "test" })

    -- No delimiter found
    local parts4 = SplitString("hello", ",")
    lu.assertEquals(parts4, { "hello" })

    -- Empty string
    local parts5 = SplitString("", ",")
    lu.assertEquals(parts5, {})

    -- Invalid input
    lu.assertEquals(SplitString(nil), {})
    lu.assertEquals(SplitString(123), {})
end

-- Test TrimString
function TestMisc:testTrimString()
    -- Basic trimming
    lu.assertEquals(TrimString("  hello  "), "hello")
    lu.assertEquals(TrimString("\thello\t"), "hello")
    lu.assertEquals(TrimString("\n\rhello\n\r"), "hello")
    lu.assertEquals(TrimString("   hello   world   "), "hello   world")

    -- No trimming needed
    lu.assertEquals(TrimString("hello"), "hello")

    -- Empty/whitespace only
    lu.assertEquals(TrimString(""), "")
    lu.assertEquals(TrimString("   "), "")

    -- Invalid input
    lu.assertEquals(TrimString(nil), "")
    lu.assertEquals(TrimString(123), "")
end

-- Test StartsWith
function TestMisc:testStartsWith()
    lu.assertTrue(StartsWith("hello world", "hello"))
    lu.assertTrue(StartsWith("hello", ""))
    lu.assertTrue(StartsWith("hello", "hello"))

    lu.assertFalse(StartsWith("hello world", "world"))
    lu.assertFalse(StartsWith("hello", "hello world"))
    lu.assertFalse(StartsWith("Hello", "hello")) -- case sensitive

    -- Invalid input
    lu.assertFalse(StartsWith(nil, "hello"))
    lu.assertFalse(StartsWith("hello", nil))
    lu.assertFalse(StartsWith(123, "hello"))
end

-- Test EndsWith
function TestMisc:testEndsWith()
    lu.assertTrue(EndsWith("hello world", "world"))
    lu.assertFalse(EndsWith("hello", "")) -- Empty suffix edge case
    lu.assertTrue(EndsWith("hello", "hello"))

    lu.assertFalse(EndsWith("hello world", "hello"))
    lu.assertFalse(EndsWith("hello", "hello world"))
    lu.assertFalse(EndsWith("Hello", "HELLO")) -- case sensitive

    -- Invalid input
    lu.assertFalse(EndsWith(nil, "hello"))
    lu.assertFalse(EndsWith("hello", nil))
end

-- Test DegToRad
function TestMisc:testDegToRad()
    lu.assertAlmostEquals(DegToRad(0), 0, 0.0001)
    lu.assertAlmostEquals(DegToRad(90), math.pi / 2, 0.0001)
    lu.assertAlmostEquals(DegToRad(180), math.pi, 0.0001)
    lu.assertAlmostEquals(DegToRad(270), 3 * math.pi / 2, 0.0001)
    lu.assertAlmostEquals(DegToRad(360), 2 * math.pi, 0.0001)

    -- Negative angles
    lu.assertAlmostEquals(DegToRad(-90), -math.pi / 2, 0.0001)
end

-- Test RadToDeg
function TestMisc:testRadToDeg()
    lu.assertAlmostEquals(RadToDeg(0), 0, 0.0001)
    lu.assertAlmostEquals(RadToDeg(math.pi / 2), 90, 0.0001)
    lu.assertAlmostEquals(RadToDeg(math.pi), 180, 0.0001)
    lu.assertAlmostEquals(RadToDeg(3 * math.pi / 2), 270, 0.0001)
    lu.assertAlmostEquals(RadToDeg(2 * math.pi), 360, 0.0001)

    -- Negative angles
    lu.assertAlmostEquals(RadToDeg(-math.pi / 2), -90, 0.0001)
end

-- Test NormalizeAngle
function TestMisc:testNormalizeAngle()
    -- Already normalized
    lu.assertEquals(NormalizeAngle(0), 0)
    lu.assertEquals(NormalizeAngle(90), 90)
    lu.assertEquals(NormalizeAngle(180), 180)
    lu.assertEquals(NormalizeAngle(359), 359)

    -- Positive overflow
    lu.assertEquals(NormalizeAngle(360), 0)
    lu.assertEquals(NormalizeAngle(361), 1)
    lu.assertEquals(NormalizeAngle(720), 0)
    lu.assertEquals(NormalizeAngle(450), 90)

    -- Negative angles
    lu.assertEquals(NormalizeAngle(-1), 359)
    lu.assertEquals(NormalizeAngle(-90), 270)
    lu.assertEquals(NormalizeAngle(-180), 180)
    lu.assertEquals(NormalizeAngle(-360), 0)
    lu.assertEquals(NormalizeAngle(-720), 0)
end

-- Test AngleDiff
function TestMisc:testAngleDiff()
    -- Simple differences
    lu.assertEquals(AngleDiff(0, 90), 90)
    lu.assertEquals(AngleDiff(90, 0), -90)
    lu.assertEquals(AngleDiff(0, 180), 180)
    lu.assertEquals(AngleDiff(180, 0), -180)

    -- Shortest path across 0
    lu.assertEquals(AngleDiff(350, 10), 20)
    lu.assertEquals(AngleDiff(10, 350), -20)

    -- Large angles
    lu.assertEquals(AngleDiff(0, 270), -90) -- Shorter to go backwards
    lu.assertEquals(AngleDiff(270, 0), 90)

    -- Same angle
    lu.assertEquals(AngleDiff(45, 45), 0)
end

-- Test TableToString
function TestMisc:testTableToString()
    -- Simple table
    local t1 = { a = 1, b = 2 }
    local str1 = TableToString(t1)
    lu.assertStrContains(str1, "[a] = 1")
    lu.assertStrContains(str1, "[b] = 2")

    -- Nested table
    local t2 = { x = { y = { z = 3 } } }
    local str2 = TableToString(t2)
    lu.assertStrContains(str2, "[x] =")
    lu.assertStrContains(str2, "[y] =")
    lu.assertStrContains(str2, "[z] = 3")

    -- Non-table input
    lu.assertEquals(TableToString(123), "123")
    lu.assertEquals(TableToString("hello"), "hello")
    lu.assertEquals(TableToString(nil), "nil")
end

return TestMisc
