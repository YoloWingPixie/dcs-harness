local lu = require("luaunit")

TestMissionFileReplace = {}

function TestMissionFileReplace:setUp()
    self.originalIo, self.originalLfs, self.originalOs = io, lfs, os
    self.originalLog = _HarnessInternal.log.error
    self.files, self.directories = {}, { ["/saved/"] = true }
    self.messages = {}
    self.operation, self.failureMode, self.renameCalls = nil, nil, 0
    local suite = self
    local function failure(operation)
        if suite.operation ~= operation then
            return false
        end
        if suite.failureMode == "throw" then
            error(operation .. " failed")
        end
        return true
    end
    local function failedValue()
        if suite.failureMode == "false" then
            return false, "operation failed"
        end
        return nil, "operation failed"
    end
    io = {
        open = function(path, mode)
            if failure("open") then
                return failedValue()
            end
            lu.assertEquals(mode, "wb")
            suite.files[path] = ""
            return {
                write = function(_, contents)
                    if failure("write") then
                        return failedValue()
                    end
                    suite.files[path] = contents
                    return true
                end,
                flush = function()
                    if failure("flush") then
                        return failedValue()
                    end
                    return true
                end,
                close = function()
                    if failure("close") then
                        return failedValue()
                    end
                    return true
                end,
            }
        end,
    }
    lfs = {
        writedir = function()
            return "/saved/"
        end,
        mkdir = function(path)
            suite.directories[path] = true
            return true
        end,
        attributes = function(path)
            if suite.files[path] ~= nil then
                if path:match("%.harness%-tmp$") and failure("size") then
                    return failedValue()
                end
                return {
                    mode = "file",
                    size = #suite.files[path] + (suite.operation == "short" and 1 or 0),
                }
            end
            if suite.directories[path] then
                return { mode = "directory" }
            end
            return nil
        end,
    }
    os = {
        rename = function(from, to)
            suite.renameCalls = suite.renameCalls + 1
            local operation = ({ "initial", "backup", "publish", "restore" })[suite.renameCalls]
            if failure(operation) then
                return failedValue()
            end
            if suite.windows and suite.files[to] ~= nil then
                return nil, "target exists"
            end
            if suite.operation == "restore" and operation == "publish" then
                return nil, "publication failed"
            end
            if suite.files[from] == nil then
                return nil, "source missing"
            end
            suite.files[to], suite.files[from] = suite.files[from], nil
            return true
        end,
        remove = function(path)
            if failure("cleanup") then
                return failedValue()
            end
            suite.files[path] = nil
            return true
        end,
    }
    _HarnessInternal.log.error = function(message)
        suite.messages[#suite.messages + 1] = message
    end
end

function TestMissionFileReplace:tearDown()
    io, lfs, os = self.originalIo, self.originalLfs, self.originalOs
    _HarnessInternal.log.error = self.originalLog
end

function TestMissionFileReplace:testCreateReplaceAndBinaryContents()
    local target = "/saved/reports/result.txt"
    local path, reason, recovery = ReplaceMissionTextFile("reports/result.txt", "first\nline\r\n\0")
    lu.assertEquals(path, target)
    lu.assertNil(reason)
    lu.assertNil(recovery)
    lu.assertEquals(self.files[target], "first\nline\r\n\0")
    lu.assertTrue(self.directories["/saved/reports"])
    path, reason, recovery = ReplaceMissionTextFile("reports/result.txt", "")
    lu.assertEquals(path, target)
    lu.assertNil(reason)
    lu.assertNil(recovery)
    lu.assertEquals(self.files[target], "")
end

function TestMissionFileReplace:testWindowsBackupPublicationAndCleanupFailure()
    self.windows = true
    self.files["/saved/result.txt"] = "old"
    self.operation = "cleanup"
    local path, reason, recovery = ReplaceMissionTextFile("result.txt", "new")
    lu.assertEquals(path, "/saved/result.txt")
    lu.assertNil(reason)
    lu.assertNil(recovery)
    lu.assertEquals(self.files[path], "new")
    lu.assertEquals(self.files[path .. ".harness-backup"], "old")
    lu.assertTrue(#self.messages > 0)
end

function TestMissionFileReplace:testFailuresPreserveOldContentsOrRecoveryCopy()
    for _, mode in ipairs({ "throw", "nil", "false" }) do
        for _, operation in ipairs({
            "open",
            "write",
            "flush",
            "close",
            "size",
            "short",
            "backup",
            "publish",
            "restore",
        }) do
            self.files = { ["/saved/result.txt"] = "old" }
            self.renameCalls, self.windows, self.operation, self.failureMode =
                0, true, operation, mode
            local path, reason, recovery = ReplaceMissionTextFile("result.txt", "new\n")
            lu.assertNil(path, operation)
            lu.assertIsString(reason)
            if operation == "restore" then
                lu.assertEquals(recovery, "/saved/result.txt.harness-backup")
                lu.assertEquals(self.files[recovery], "old")
            else
                lu.assertNil(recovery, operation)
                lu.assertEquals(self.files["/saved/result.txt"], "old", operation)
            end
        end
    end
end

function TestMissionFileReplace:testInitialRenameFailureForNewTarget()
    self.operation = "initial"
    local path, reason, recovery = ReplaceMissionTextFile("new.txt", "contents")
    lu.assertNil(path)
    lu.assertIsString(reason)
    lu.assertNil(recovery)
    lu.assertNil(self.files["/saved/new.txt"])
end

function TestMissionFileReplace:testInvalidPathsContentsCapabilitiesAndOccupiedWorkFiles()
    for _, path in ipairs({
        "",
        "../outside",
        "/absolute",
        "C:/absolute",
        "a//b",
        "a\\b",
        "a/./b",
        "a\0b",
    }) do
        lu.assertNil(ReplaceMissionTextFile(path, "text"))
    end
    for _, contents in ipairs({ false, {}, 1 }) do
        lu.assertNil(ReplaceMissionTextFile("result.txt", contents))
    end
    lu.assertNil(ReplaceMissionTextFile("result.txt", nil))
    lu.assertEquals(self.files, {})
    self.files["/saved/result.txt"] = "old"
    local rename = os.rename
    os.rename = nil
    lu.assertNil(ReplaceMissionTextFile("result.txt", "new"))
    os.rename = rename
    lu.assertEquals(self.files, { ["/saved/result.txt"] = "old" })
    for _, suffix in ipairs({ ".harness-tmp", ".harness-backup" }) do
        self.files["/saved/result.txt" .. suffix] = "unrelated"
        lu.assertNil(ReplaceMissionTextFile("result.txt", "new"))
        lu.assertEquals(self.files["/saved/result.txt" .. suffix], "unrelated")
        self.files["/saved/result.txt" .. suffix] = nil
    end
    lu.assertEquals(self.files["/saved/result.txt"], "old")
end
