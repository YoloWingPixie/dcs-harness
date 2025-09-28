-- Tests for id.lua (UUID v4, UUID v7, ULID)
local lu = require("luaunit")
require("test_utils")

-- Ensure src on path
package.path = package.path .. ";../src/?.lua"

TestId = CreateIsolatedTestSuite("TestId", {})

function TestId:setUp()
    require("mock_dcs")
    require("_header")
    -- Logger required by modules
    require("logger")
    -- Stable time for deterministic timestamp fields
    self.savedTimer = {
        getTime = timer.getTime,
    }
    self.fixedTime = 12345.678 -- seconds
    ---@diagnostic disable-next-line: duplicate-set-field
    timer.getTime = function()
        return self.fixedTime
    end

    require("id")
end

function TestId:tearDown()
    timer.getTime = self.savedTimer.getTime
end

local function assertUuidFormat(u)
    -- Lua patterns do not support {n} quantifiers; use explicit %x counts
    local pat = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
    lu.assertStrMatches(u, pat)
end

function TestId:test_uuidv4_format_and_bits()
    local u = NewUUIDv4()
    assertUuidFormat(u)

    -- version must be 4
    local ver = string.sub(u, 15, 15)
    lu.assertEquals(ver, "4")

    -- variant must be 8,9,a,b (10xxxxxx)
    local variantNibble = string.sub(u, 20, 20)
    lu.assertTrue(
        variantNibble == "8" or variantNibble == "9" or variantNibble == "a" or variantNibble == "b"
    )

    -- basic uniqueness
    local seen = {}
    for i = 1, 100 do
        local v = NewUUIDv4()
        lu.assertNil(seen[v])
        seen[v] = true
    end
end

function TestId:test_uuidv7_format_and_bits()
    local u = NewUUIDv7()
    assertUuidFormat(u)

    -- version must be 7
    local ver = string.sub(u, 15, 15)
    lu.assertEquals(ver, "7")

    -- variant must be 8,9,a,b
    local variantNibble = string.sub(u, 20, 20)
    lu.assertTrue(
        variantNibble == "8" or variantNibble == "9" or variantNibble == "a" or variantNibble == "b"
    )

    -- monotonic tendency across different times
    local prev = u
    -- simulate time moving forward
    self.fixedTime = self.fixedTime + 1.0
    local nextu = NewUUIDv7()
    -- They should not be equal
    lu.assertNotEquals(prev, nextu)
end

function TestId:test_ulid_format_alphabet_and_length()
    local u = NewULID()
    lu.assertEquals(#u, 26)
    -- Crockford Base32 alphabet check
    lu.assertStrMatches(u, "^[0-9ABCDEFGHJKMNPQRSTVWXYZ]+$")

    -- basic uniqueness
    local seen = {}
    for i = 1, 100 do
        local v = NewULID()
        lu.assertNil(seen[v])
        seen[v] = true
    end
end

return TestId
