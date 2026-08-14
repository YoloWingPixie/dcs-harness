--[[
==================================================================================================
    MISSION FILE MODULE
    Capability-gated writes below the DCS Saved Games write directory
==================================================================================================
]]

require("logger")

local MissionFileInternal = {
    targetExistsReason = "target already exists",
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
            return nil, "lfs.attributes failed for mission directory: " .. tostring(attributes)
        end
        if attributes ~= nil then
            if type(attributes) ~= "table" or attributes.mode ~= "directory" then
                return nil, "mission directory path is occupied by a non-directory"
            end
        else
            local mkdirOk, created, mkdirReason = pcall(capabilities.mkdir, current)
            if not mkdirOk then
                return nil, "lfs.mkdir failed: " .. tostring(created)
            end
            if not created then
                local verifyOk, verified = pcall(capabilities.attributes, current)
                if not verifyOk or type(verified) ~= "table" or verified.mode ~= "directory" then
                    return nil, "lfs.mkdir failed: " .. tostring(mkdirReason or created)
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
    if not closeOk or closeResult == nil then
        return nil, tostring(closeReason or closeResult)
    end
    return true, nil
end

function MissionFileInternal.write(capabilities, absolutePath, contents)
    local openOk, file, openReason = pcall(capabilities.open, absolutePath, "w")
    if not openOk or file == nil then
        return nil, "io.open failed: " .. tostring(openReason or file)
    end

    local writeOk, writeResult, writeReason = pcall(function()
        return file:write(contents)
    end)
    if not writeOk or writeResult == nil then
        MissionFileInternal.close(file)
        return nil, "file write failed: " .. tostring(writeReason or writeResult)
    end

    local flushOk, flushResult, flushReason = pcall(function()
        return file:flush()
    end)
    if not flushOk or flushResult == nil then
        MissionFileInternal.close(file)
        return nil, "file flush failed: " .. tostring(flushReason or flushResult)
    end

    local closed, closeReason = MissionFileInternal.close(file)
    if not closed then
        return nil, "file close failed: " .. tostring(closeReason)
    end
    return absolutePath, nil
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
            "lfs.attributes failed for target: " .. tostring(attributes)
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
