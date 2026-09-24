package.path = "../src/?.lua;" .. package.path

local root, python, bridge = arg[1], arg[2], arg[3]
local windows = package.config:sub(1, 1) == "\\"
local function quote(value)
    if windows then
        assert(not value:find('["%%\r\n]'))
        return '"' .. value .. '"'
    end
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function metadata(operation, path)
    local pipe = assert(
        io.popen(quote(python) .. " " .. quote(bridge) .. " " .. operation .. " " .. quote(path))
    )
    local kind, size = pipe:read("*l"), pipe:read("*l")
    pipe:close()
    if kind == "error" then
        return nil, "filesystem metadata error", tonumber(size)
    end
    return { mode = kind, size = tonumber(size) }
end

lfs = {
    writedir = function()
        return root .. "/"
    end,
    attributes = function(path)
        return metadata("stat", path)
    end,
    mkdir = function(path)
        local result, reason = metadata("mkdir", path)
        if not result then
            return nil, reason
        end
        return true
    end,
}
env = { info = function() end, warning = function() end, error = function() end }
require("logger")
require("missionfile")

local function read(path)
    local file = assert(io.open(path, "rb"))
    local contents = file:read("*a")
    assert(file:close())
    return contents
end

local target = root .. "/nested/result.txt"
local path, reason, recovery = ReplaceMissionTextFile("nested/result.txt", "one\nline\r\n\0")
assert(path == target and reason == nil and recovery == nil, reason)
assert(read(target) == "one\nline\r\n\0")
assert(ReplaceMissionTextFile("../outside.txt", "invalid") == nil)
assert(ReplaceMissionTextFile("nested/result.txt", false) == nil)
local savedRename = os.rename
os.rename = nil
assert(ReplaceMissionTextFile("nested/result.txt", "unavailable") == nil)
os.rename = savedRename
assert(read(target) == "one\nline\r\n\0")
assert(WriteMissionTextFile("nested/result.txt", "overwrite") == nil)
assert(read(target) == "one\nline\r\n\0")
assert(
    WriteUniqueMissionTextFile("nested/result.txt", "unique") == root .. "/nested/result-001.txt"
)
assert(ReplaceMissionTextFile("nested/result.txt", "") == target)
assert(read(target) == "")
assert(ReplaceMissionTextFile("nested/result.txt", "old") == target)

local nativeRename = os.rename
local calls = 0
os.rename = function(from, to)
    calls = calls + 1
    if calls == 1 or calls == 3 then
        return nil, "injected publication failure"
    end
    return nativeRename(from, to)
end
path, reason, recovery = ReplaceMissionTextFile("nested/result.txt", "new")
assert(path == nil and type(reason) == "string" and recovery == nil)
assert(read(target) == "old")

calls = 0
os.rename = function(from, to)
    calls = calls + 1
    if calls ~= 2 then
        return nil, "injected rename failure"
    end
    return nativeRename(from, to)
end
path, reason, recovery = ReplaceMissionTextFile("nested/result.txt", "new")
assert(path == nil and type(reason) == "string" and recovery == target .. ".harness-backup")
assert(read(recovery) == "old")
os.rename = nativeRename
assert(nativeRename(recovery, target))
assert(ReplaceMissionTextFile("nested/result.txt", "published\n") == target)
assert(read(target) == "published\n")
