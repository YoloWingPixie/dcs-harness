--[[
==================================================================================================
    ID MODULE
    Utilities for generating IDs: UUID v4, UUID v7, and ULID
==================================================================================================
]]

-- Note: module does not depend on logger to remain lightweight and side-effect free

-- Internal PRNG (LCG) with a time- and address-based seed to avoid relying on math.random state
local function _seed32()
    local t = (timer and timer.getTime and timer.getTime()) or 0
    local addr = tonumber((tostring({}):match("0x(%x+)") or "0"), 16) or 0
    local s = math.max(1, math.floor(t * 1e6))
    return ((s % 2147483647) * 1103515245 + (addr % 2147483647) + 12345) % 2147483647
end

local _rng_state = _seed32()

local function _lcg32()
    _rng_state = (1103515245 * _rng_state + 12345) % 2147483648
    return _rng_state
end

local function _rand_byte()
    -- Scale a 31-bit LCG state into a byte
    return math.floor(_lcg32() / 8388608) % 256 -- 2^23
end

local function _to_hex_byte(b)
    local hex = "0123456789abcdef"
    local hi, lo = math.floor(b / 16) + 1, (b % 16) + 1
    return string.sub(hex, hi, hi) .. string.sub(hex, lo, lo)
end

--- Generate a UUID v4 string (random)
---@return string uuid UUID v4 string (lowercase hex)
function NewUUIDv4()
    local b = {}
    for i = 1, 16 do
        b[i] = _rand_byte()
    end
    -- Set version (0100) and variant (10xx)
    b[7] = (b[7] % 16) + 0x40
    b[9] = (b[9] % 64) + 0x80

    local parts =
        {
            _to_hex_byte(b[1]) .. _to_hex_byte(b[2]) .. _to_hex_byte(b[3]) .. _to_hex_byte(b[4]),
            _to_hex_byte(b[5]) .. _to_hex_byte(b[6]),
            _to_hex_byte(b[7]) .. _to_hex_byte(b[8]),
            _to_hex_byte(b[9]) .. _to_hex_byte(b[10]),
            _to_hex_byte(b[11]) .. _to_hex_byte(b[12]) .. _to_hex_byte(b[13]) .. _to_hex_byte(
                b[14]
            ) .. _to_hex_byte(b[15]) .. _to_hex_byte(b[16]),
        }
    return table.concat(parts, "-")
end

--- Generate a UUID v7 string (time-ordered)
---@return string uuid UUID v7 string (lowercase hex)
function NewUUIDv7()
    local ms = math.floor(((timer and timer.getTime and timer.getTime()) or 0) * 1000)
    local b = {}
    -- 48-bit big-endian timestamp
    for i = 6, 1, -1 do
        b[i] = ms % 256
        ms = math.floor(ms / 256)
    end
    -- 10 random bytes
    for i = 7, 16 do
        b[i] = _rand_byte()
    end

    -- Set version (0111) and variant (10xx)
    b[7] = (b[7] % 16) + 0x70
    b[9] = (b[9] % 64) + 0x80

    local parts =
        {
            _to_hex_byte(b[1]) .. _to_hex_byte(b[2]) .. _to_hex_byte(b[3]) .. _to_hex_byte(b[4]),
            _to_hex_byte(b[5]) .. _to_hex_byte(b[6]),
            _to_hex_byte(b[7]) .. _to_hex_byte(b[8]),
            _to_hex_byte(b[9]) .. _to_hex_byte(b[10]),
            _to_hex_byte(b[11]) .. _to_hex_byte(b[12]) .. _to_hex_byte(b[13]) .. _to_hex_byte(
                b[14]
            ) .. _to_hex_byte(b[15]) .. _to_hex_byte(b[16]),
        }
    return table.concat(parts, "-")
end

--- Generate a ULID string (Crockford Base32, 26 chars)
---@return string ulid ULID string
function NewULID()
    local ms = math.floor(((timer and timer.getTime and timer.getTime()) or 0) * 1000)
    local b = {}
    -- 6-byte big-endian timestamp
    for i = 6, 1, -1 do
        b[i] = ms % 256
        ms = math.floor(ms / 256)
    end
    -- 10 bytes randomness
    for i = 7, 16 do
        b[i] = _rand_byte()
    end

    -- Crockford Base32 alphabet
    local alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

    -- Convert 16 bytes to bit array
    local bits = {}
    for i = 1, 16 do
        local v = b[i]
        for j = 7, 0, -1 do
            bits[#bits + 1] = math.floor(v / 2 ^ j) % 2
        end
    end

    -- Pad to 130 bits (ULID encodes to 26 base32 chars)
    bits[#bits + 1] = 0
    bits[#bits + 1] = 0

    local out = {}
    for i = 1, 26 do
        local idx = 0
        for j = 0, 4 do
            idx = idx * 2 + bits[(i - 1) * 5 + j + 1]
        end
        out[i] = string.sub(alphabet, idx + 1, idx + 1)
    end

    return table.concat(out)
end
