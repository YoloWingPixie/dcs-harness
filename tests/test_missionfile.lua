local lu = require("luaunit")

TestMissionFile = {}

local function makeEnvironment()
    local state = {
        paths = { ["C:/Saved Games/"] = "directory" },
        writes = {},
        mkdirCalls = {},
        closeCalls = 0,
    }
    local fakeLfs = {
        writedir = function()
            return "C:/Saved Games/"
        end,
        attributes = function(path)
            local mode = state.paths[path]
            return mode and { mode = mode } or nil
        end,
        mkdir = function(path)
            state.paths[path] = "directory"
            table.insert(state.mkdirCalls, path)
            return true
        end,
    }
    local fakeIo = {
        open = function(path, mode)
            if mode ~= "w" then
                error("unexpected mode")
            end
            local file = {}
            function file:write(contents)
                state.writes[path] = contents
                return true
            end
            function file:flush()
                return true
            end
            function file:close()
                state.closeCalls = state.closeCalls + 1
                state.paths[path] = "file"
                return true
            end
            return file
        end,
    }
    return state, fakeIo, fakeLfs
end

function TestMissionFile:setUp()
    self.originalIo = _G.io
    self.originalLfs = _G.lfs
    self.state, _G.io, _G.lfs = makeEnvironment()
end

function TestMissionFile:tearDown()
    _G.io = self.originalIo
    _G.lfs = self.originalLfs
end

function TestMissionFile:testCapabilitiesAndSanitizedEnvironment()
    local capabilities, reason = GetMissionFileCapabilities()
    lu.assertNil(reason)
    lu.assertEquals(capabilities, { writeDirectory = "C:/Saved Games/" })
    _G.io = nil
    capabilities, reason = GetMissionFileCapabilities()
    lu.assertNil(capabilities)
    lu.assertStrContains(reason, "io.open")
end

function TestMissionFile:testFilenameSanitation()
    lu.assertEquals(SanitizeFilenameComponent(" Pilot / One "), "Pilot-One")
    lu.assertEquals(SanitizeFilenameComponent("..", 12), "Unknown")
    lu.assertEquals(SanitizeFilenameComponent("abcdefgh", 5), "abcde")
end

function TestMissionFile:testDirectoryCreationAndConfinement()
    local path, reason = EnsureMissionDirectory("Harness/reports")
    lu.assertNil(reason)
    lu.assertEquals(path, "C:/Saved Games/Harness/reports")
    lu.assertEquals(self.state.mkdirCalls, {
        "C:/Saved Games/Harness",
        "C:/Saved Games/Harness/reports",
    })

    for _, invalid in ipairs({ "", "/absolute", "C:/escape", "../escape", "a//b", "a/./b" }) do
        local result = EnsureMissionDirectory(invalid)
        lu.assertNil(result, invalid)
    end
    lu.assertNil(WriteMissionTextFile("Harness/../escape.txt", "bad"))
end

function TestMissionFile:testWritesAndAllocatesUniqueSuffix()
    local path, reason = WriteMissionTextFile("Harness/report.txt", "first")
    lu.assertNil(reason)
    lu.assertEquals(path, "C:/Saved Games/Harness/report.txt")
    lu.assertEquals(self.state.writes[path], "first")
    lu.assertNil(WriteMissionTextFile("Harness/report.txt", "duplicate"))

    local unique = WriteUniqueMissionTextFile("Harness/report.txt", "second", 2)
    lu.assertEquals(unique, "C:/Saved Games/Harness/report-001.txt")
    lu.assertEquals(self.state.writes[unique], "second")
end

function TestMissionFile:testProtectedWriteFlushAndCloseFailures()
    local closeCalls = 0
    _G.io.open = function()
        return {
            write = function()
                error("write failed")
            end,
            flush = function()
                return true
            end,
            close = function()
                closeCalls = closeCalls + 1
            end,
        }
    end
    lu.assertNil(WriteMissionTextFile("Harness/write-fail.txt", "contents"))
    lu.assertEquals(closeCalls, 1)

    _G.io.open = function()
        return {
            write = function()
                return true
            end,
            flush = function()
                error("flush failed")
            end,
            close = function()
                closeCalls = closeCalls + 1
            end,
        }
    end
    lu.assertNil(WriteMissionTextFile("Harness/flush-fail.txt", "contents"))
    lu.assertEquals(closeCalls, 2)

    _G.io.open = function()
        return {
            write = function()
                return true
            end,
            flush = function()
                return true
            end,
            close = function()
                error("close failed")
            end,
        }
    end
    lu.assertNil(WriteMissionTextFile("Harness/close-fail.txt", "contents"))
end

return TestMissionFile
