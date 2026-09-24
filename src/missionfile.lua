--[[
==================================================================================================
    MISSION FILE MODULE
    Capability-gated writes below the DCS Saved Games write directory
==================================================================================================
]]

require("logger")

local MissionFileInternal = {
    targetExistsReason = "target already exists",
    temporarySuffix = ".harness-tmp",
    backupSuffix = ".harness-backup",
    fileNotFoundCode = 2,
}

function MissionFileInternal.failure(caller, reason)
    _HarnessInternal.log.error(reason, caller)
    return nil, reason
end

function MissionFileInternal.probeCapabilities()
    local globalsOk, ioLibrary, lfsLibrary = pcall(function()
        return _G.io, _G.lfs
    end)
    if not globalsOk then
        return nil, "mission file globals are inaccessible"
    end

    local functionsOk, ioOpen, writeDirectory, mkdir, attributes = pcall(function()
        return ioLibrary and ioLibrary.open,
            lfsLibrary and lfsLibrary.writedir,
            lfsLibrary and lfsLibrary.mkdir,
            lfsLibrary and lfsLibrary.attributes
    end)
    if not functionsOk or type(ioOpen) ~= "function" then
        return nil, "io.open unavailable; DCS mission scripting is sanitized"
    end
    if
        type(writeDirectory) ~= "function"
        or type(mkdir) ~= "function"
        or type(attributes) ~= "function"
    then
        return nil, "lfs write-directory functions unavailable; DCS mission scripting is sanitized"
    end

    local directoryOk, directory = pcall(writeDirectory)
    if not directoryOk or type(directory) ~= "string" or directory == "" then
        return nil, "lfs.writedir() did not return a usable directory"
    end
    return {
        open = ioOpen,
        mkdir = mkdir,
        attributes = attributes,
        writeDirectory = directory,
    }
end

--- Report operator-provided mission file capabilities
---@return table? capabilities Write-directory capability
---@return string? reason Unavailability reason
function GetMissionFileCapabilities()
    local capabilities, reason = MissionFileInternal.probeCapabilities()
    if not capabilities then
        return MissionFileInternal.failure("MissionFile.GetMissionFileCapabilities", reason)
    end
    return { writeDirectory = capabilities.writeDirectory }, nil
end

--- Sanitize one filename component
---@param value any Input value
---@param maxLength number? Maximum output length
---@return string sanitized Safe filename component
function SanitizeFilenameComponent(value, maxLength)
    local text = tostring(value or "Unknown")
    text = text:gsub("[%c]", "-")
    text = text:gsub("%s+", "-")
    text = text:gsub("[^%w%._%-]", "-")
    text = text:gsub("%-+", "-")
    text = text:gsub("^[-%.]+", ""):gsub("[-%.]+$", "")
    if text == "" then
        text = "Unknown"
    end
    if
        type(maxLength) == "number"
        and maxLength == maxLength
        and maxLength > 0
        and maxLength < math.huge
    then
        local limit = math.floor(maxLength)
        if #text > limit then
            text = text:sub(1, limit):gsub("[-%.]+$", "")
            if text == "" then
                text = string.sub("Unknown", 1, limit)
            end
        end
    end
    return text
end

function MissionFileInternal.validateRelativePath(relativePath)
    if type(relativePath) ~= "string" or relativePath == "" then
        return nil, "relative path must be a non-empty string"
    end
    if relativePath:find("%z") then
        return nil, "relative path contains a NUL"
    end
    if
        relativePath:sub(1, 1) == "/"
        or relativePath:sub(1, 1) == "\\"
        or relativePath:match("^%a:")
    then
        return nil, "absolute paths and drive prefixes are not allowed"
    end
    if relativePath:find("\\", 1, true) then
        return nil, "relative paths must use / separators"
    end
    if relativePath:find("//", 1, true) or relativePath:sub(-1) == "/" then
        return nil, "relative path contains an empty component"
    end

    local components = {}
    for component in relativePath:gmatch("[^/]+") do
        if component == "" or component == "." or component == ".." then
            return nil, "relative path contains an invalid component"
        end
        components[#components + 1] = component
    end
    if #components == 0 then
        return nil, "relative path contains no components"
    end
    return components, nil
end

function MissionFileInternal.pathSeparator(writeDirectory)
    if writeDirectory:find("\\", 1, true) and not writeDirectory:find("/", 1, true) then
        return "\\"
    end
    return "/"
end

function MissionFileInternal.appendPath(base, component, separator)
    if base:sub(-1) == "/" or base:sub(-1) == "\\" then
        return base .. component
    end
    return base .. separator .. component
end

function MissionFileInternal.ensureDirectory(capabilities, components)
    local separator = MissionFileInternal.pathSeparator(capabilities.writeDirectory)
    local current = capabilities.writeDirectory
    for _, component in ipairs(components) do
        current = MissionFileInternal.appendPath(current, component, separator)
        local attributesOk, attributes = pcall(capabilities.attributes, current)
        if not attributesOk then
            return nil,
                "lfs.attributes failed for mission directory: " .. _HarnessInternal.safeString(
                    attributes
                )
        end
        if attributes ~= nil then
            if type(attributes) ~= "table" or attributes.mode ~= "directory" then
                return nil, "mission directory path is occupied by a non-directory"
            end
        else
            local mkdirOk, created, mkdirReason = pcall(capabilities.mkdir, current)
            if not mkdirOk then
                return nil, "lfs.mkdir failed: " .. _HarnessInternal.safeString(created)
            end
            if not created then
                local verifyOk, verified = pcall(capabilities.attributes, current)
                if not verifyOk or type(verified) ~= "table" or verified.mode ~= "directory" then
                    return nil,
                        "lfs.mkdir failed: " .. _HarnessInternal.safeString(mkdirReason or created)
                end
            end
        end
    end
    return current, nil
end

--- Ensure a validated directory exists below lfs.writedir()
---@param relativeDirectory string Directory path using / separators
---@return string? absoluteDirectory Absolute created directory
---@return string? reason Failure reason
function EnsureMissionDirectory(relativeDirectory)
    local components, pathReason = MissionFileInternal.validateRelativePath(relativeDirectory)
    if not components then
        return MissionFileInternal.failure("MissionFile.EnsureMissionDirectory", pathReason)
    end
    local capabilities, capabilityReason = MissionFileInternal.probeCapabilities()
    if not capabilities then
        return MissionFileInternal.failure("MissionFile.EnsureMissionDirectory", capabilityReason)
    end
    local directory, reason = MissionFileInternal.ensureDirectory(capabilities, components)
    if not directory then
        return MissionFileInternal.failure("MissionFile.EnsureMissionDirectory", reason)
    end
    return directory, nil
end

function MissionFileInternal.close(file)
    local closeOk, closeResult, closeReason = pcall(function()
        return file:close()
    end)
    if not closeOk or not closeResult then
        return nil, _HarnessInternal.safeString(closeReason or closeResult)
    end
    return true, nil
end

function MissionFileInternal.write(capabilities, absolutePath, contents, mode)
    local openOk, file, openReason = pcall(capabilities.open, absolutePath, mode or "w")
    if not openOk or not file then
        return nil, "io.open failed: " .. _HarnessInternal.safeString(openReason or file), false
    end

    local writeOk, writeResult, writeReason = pcall(function()
        return file:write(contents)
    end)
    if not writeOk or not writeResult then
        MissionFileInternal.close(file)
        return nil,
            "file write failed: " .. _HarnessInternal.safeString(writeReason or writeResult),
            true
    end

    local flushOk, flushResult, flushReason = pcall(function()
        return file:flush()
    end)
    if not flushOk or not flushResult then
        MissionFileInternal.close(file)
        return nil,
            "file flush failed: " .. _HarnessInternal.safeString(flushReason or flushResult),
            true
    end

    local closed, closeReason = MissionFileInternal.close(file)
    if not closed then
        return nil, "file close failed: " .. _HarnessInternal.safeString(closeReason), true
    end
    return absolutePath, nil, true
end

--- Write a new text file below lfs.writedir()
---@param relativePath string File path using / separators
---@param contents string File contents
---@return string? absolutePath Absolute written path
---@return string? reason Failure reason
function WriteMissionTextFile(relativePath, contents)
    local components, pathReason = MissionFileInternal.validateRelativePath(relativePath)
    if not components then
        return MissionFileInternal.failure("MissionFile.WriteMissionTextFile", pathReason)
    end
    if type(contents) ~= "string" then
        return MissionFileInternal.failure(
            "MissionFile.WriteMissionTextFile",
            "contents must be a string"
        )
    end
    local capabilities, capabilityReason = MissionFileInternal.probeCapabilities()
    if not capabilities then
        return MissionFileInternal.failure("MissionFile.WriteMissionTextFile", capabilityReason)
    end

    local parentComponents = {}
    for index = 1, #components - 1 do
        parentComponents[index] = components[index]
    end
    local parentDirectory = capabilities.writeDirectory
    if #parentComponents > 0 then
        parentDirectory, pathReason =
            MissionFileInternal.ensureDirectory(capabilities, parentComponents)
        if not parentDirectory then
            return MissionFileInternal.failure("MissionFile.WriteMissionTextFile", pathReason)
        end
    end

    local absolutePath = MissionFileInternal.appendPath(
        parentDirectory,
        components[#components],
        MissionFileInternal.pathSeparator(capabilities.writeDirectory)
    )
    local attributesOk, attributes = pcall(capabilities.attributes, absolutePath)
    if not attributesOk then
        return MissionFileInternal.failure(
            "MissionFile.WriteMissionTextFile",
            "lfs.attributes failed for target: " .. _HarnessInternal.safeString(attributes)
        )
    end
    if attributes ~= nil then
        return nil, MissionFileInternal.targetExistsReason
    end
    local writtenPath, reason = MissionFileInternal.write(capabilities, absolutePath, contents)
    if not writtenPath then
        return MissionFileInternal.failure("MissionFile.WriteMissionTextFile", reason)
    end
    return writtenPath, nil
end

function MissionFileInternal.suffixedPath(relativePath, suffix)
    if suffix == 0 then
        return relativePath
    end
    local stem, extension = relativePath:match("^(.*)(%.[^%./]+)$")
    if not stem or stem == "" then
        stem = relativePath
        extension = ""
    end
    return string.format("%s-%03d%s", stem, suffix, extension)
end

--- Write a text file using the first available bounded numeric suffix
---@param relativePath string Requested file path
---@param contents string File contents
---@param maxSuffix number? Maximum suffix, default 999
---@return string? absolutePath Absolute written path
---@return string? reason Failure reason
function WriteUniqueMissionTextFile(relativePath, contents, maxSuffix)
    maxSuffix = maxSuffix == nil and 999 or maxSuffix
    if
        type(maxSuffix) ~= "number"
        or maxSuffix ~= maxSuffix
        or maxSuffix < 0
        or maxSuffix >= math.huge
        or maxSuffix % 1 ~= 0
    then
        return MissionFileInternal.failure(
            "MissionFile.WriteUniqueMissionTextFile",
            "maxSuffix must be a non-negative integer"
        )
    end
    for suffix = 0, maxSuffix do
        local absolutePath, reason =
            WriteMissionTextFile(MissionFileInternal.suffixedPath(relativePath, suffix), contents)
        if absolutePath then
            return absolutePath, nil
        end
        if reason ~= MissionFileInternal.targetExistsReason then
            return nil, reason
        end
    end
    return MissionFileInternal.failure(
        "MissionFile.WriteUniqueMissionTextFile",
        "no unique mission filename available within suffix limit"
    )
end

function MissionFileInternal.replacementCapabilities()
    local capabilities, reason = MissionFileInternal.probeCapabilities()
    if not capabilities then
        return nil, reason
    end
    local ok, rename, remove = pcall(function()
        return os.rename, os.remove
    end)
    if not ok or type(rename) ~= "function" or type(remove) ~= "function" then
        return nil, "os.rename and os.remove are required for mission file replacement"
    end
    capabilities.rename, capabilities.remove = rename, remove
    return capabilities
end

function MissionFileInternal.replacementAttributes(capabilities, path)
    local ok, attributes, reason, code = pcall(capabilities.attributes, path)
    if not ok then
        return nil, "lfs.attributes failed: " .. _HarnessInternal.safeString(attributes)
    end
    if attributes == nil and (reason == nil or code == MissionFileInternal.fileNotFoundCode) then
        return nil, nil
    end
    if type(attributes) ~= "table" then
        return nil, "lfs.attributes failed: " .. _HarnessInternal.safeString(reason or attributes)
    end
    return attributes, nil
end

function MissionFileInternal.replacementPaths(capabilities, components)
    local parent = {}
    for index = 1, #components - 1 do
        parent[index] = components[index]
    end
    local directory, reason = MissionFileInternal.ensureDirectory(capabilities, parent)
    if not directory then
        return nil, reason
    end
    local target = MissionFileInternal.appendPath(
        directory,
        components[#components],
        MissionFileInternal.pathSeparator(directory)
    )
    local paths = {
        target = target,
        temporary = target .. MissionFileInternal.temporarySuffix,
        backup = target .. MissionFileInternal.backupSuffix,
    }
    for _, workPath in ipairs({ paths.temporary, paths.backup }) do
        local attributes, attributeReason =
            MissionFileInternal.replacementAttributes(capabilities, workPath)
        if attributeReason then
            return nil, attributeReason
        end
        if attributes then
            return nil, "replacement work file already exists: " .. workPath
        end
    end
    local targetAttributes, targetReason =
        MissionFileInternal.replacementAttributes(capabilities, target)
    if targetReason then
        return nil, targetReason
    end
    if targetAttributes and targetAttributes.mode ~= "file" then
        return nil, "replacement target is not a regular file"
    end
    paths.targetExists = targetAttributes ~= nil
    return paths
end

function MissionFileInternal.rename(capabilities, from, to)
    local ok, renamed, reason = pcall(capabilities.rename, from, to)
    if not ok or not renamed then
        return nil,
            "rename failed from " .. from .. " to " .. to .. ": " .. _HarnessInternal.safeString(
                reason or renamed
            )
    end
    return true
end

function MissionFileInternal.cleanup(capabilities, path)
    local ok, removed, reason = pcall(capabilities.remove, path)
    if not ok or not removed then
        _HarnessInternal.log.error(
            "Replacement cleanup failed for "
                .. path
                .. ": "
                .. _HarnessInternal.safeString(reason or removed),
            "MissionFile.ReplaceMissionTextFile"
        )
    end
end

function MissionFileInternal.publishReplacement(capabilities, paths)
    local published, reason =
        MissionFileInternal.rename(capabilities, paths.temporary, paths.target)
    if published then
        return paths.target
    end
    if not paths.targetExists then
        return nil, reason
    end
    local backedUp, backupReason =
        MissionFileInternal.rename(capabilities, paths.target, paths.backup)
    if not backedUp then
        return nil, backupReason
    end
    published, reason = MissionFileInternal.rename(capabilities, paths.temporary, paths.target)
    if published then
        MissionFileInternal.cleanup(capabilities, paths.backup)
        return paths.target
    end
    local restored, restoreReason =
        MissionFileInternal.rename(capabilities, paths.backup, paths.target)
    if not restored then
        return nil, reason .. "; rollback failed: " .. restoreReason, paths.backup
    end
    return nil, reason
end

--- Save new contents over a mission text file in the DCS Saved Games directory.
--- If saving fails, keep the old file or return the path where it can be recovered.
--- Requires the mission's file-access libraries to be available.
---@param relativePath string File path such as "Reports/status.txt". Use / between folders; missing folders are created.
---@param contents string Text to save exactly as provided. No newline is added.
---@return string? absolutePath The saved file's full path, or nil if saving failed.
---@return string? reason Why the file could not be saved.
---@return string? recoveryPath Where the old file remains if it could not be put back.
---@usage local path, reason, recovery = ReplaceMissionTextFile("Reports/status.txt", reportText)
function ReplaceMissionTextFile(relativePath, contents)
    local caller = "MissionFile.ReplaceMissionTextFile"
    local components, reason = MissionFileInternal.validateRelativePath(relativePath)
    if not components then
        return MissionFileInternal.failure(caller, reason)
    end
    if type(contents) ~= "string" then
        return MissionFileInternal.failure(caller, "contents must be a string")
    end
    local capabilities
    capabilities, reason = MissionFileInternal.replacementCapabilities()
    if not capabilities then
        return MissionFileInternal.failure(caller, reason)
    end
    local paths
    paths, reason = MissionFileInternal.replacementPaths(capabilities, components)
    if not paths then
        return MissionFileInternal.failure(caller, reason)
    end
    local written, created
    written, reason, created =
        MissionFileInternal.write(capabilities, paths.temporary, contents, "wb")
    if not written then
        if created then
            MissionFileInternal.cleanup(capabilities, paths.temporary)
        end
        return MissionFileInternal.failure(caller, reason)
    end
    local attributes
    attributes, reason = MissionFileInternal.replacementAttributes(capabilities, paths.temporary)
    if not attributes or attributes.mode ~= "file" or attributes.size ~= #contents then
        MissionFileInternal.cleanup(capabilities, paths.temporary)
        return MissionFileInternal.failure(
            caller,
            reason or "closed temporary file size does not match contents"
        )
    end
    local published, recovery
    published, reason, recovery = MissionFileInternal.publishReplacement(capabilities, paths)
    if not published then
        MissionFileInternal.cleanup(capabilities, paths.temporary)
        MissionFileInternal.failure(caller, reason)
        return nil, reason, recovery
    end
    return published, nil, nil
end
