--[[
    Trigger Module - DCS World Trigger API Wrappers
    
    This module provides validated wrapper functions for DCS trigger.action operations,
    including messages, explosions, smoke, illumination, and other effects.
]]

--- Displays text message to all players
---@param text string The text message to display
---@param displayTime number? The time in seconds to display (default: 10)
---@param clearView boolean? Whether to clear the previous message (default: false)
---@return boolean? success Returns true if successful, nil on error
---@usage outText("Hello World", 15, true)
function outText(text, displayTime, clearView)
    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("outText requires valid text string", "Trigger.outText")
        return nil
    end

    if not displayTime or type(displayTime) ~= "number" then
        displayTime = 10
    end

    clearView = clearView or false

    local success, result = pcall(trigger.action.outText, text, displayTime, clearView)
    if not success then
        _HarnessInternal.log.error("Failed to display text: " .. tostring(result), "Trigger.outText")
        return nil
    end

    return true
end

--- Displays text message to a specific coalition
---@param coalitionId number The coalition ID (0=neutral, 1=red, 2=blue)
---@param text string The text message to display
---@param displayTime number? The time in seconds to display (default: 10)
---@param clearView boolean? Whether to clear the previous message (default: false)
---@return boolean? success Returns true if successful, nil on error
---@usage outTextForCoalition(coalition.side.BLUE, "Blue team message", 20)
function outTextForCoalition(coalitionId, text, displayTime, clearView)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("outTextForCoalition requires valid coalition ID", "Trigger.outTextForCoalition")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("outTextForCoalition requires valid text string", "Trigger.outTextForCoalition")
        return nil
    end

    if not displayTime or type(displayTime) ~= "number" then
        displayTime = 10
    end

    clearView = clearView or false

    local success, result = pcall(trigger.action.outTextForCoalition, coalitionId, text, displayTime, clearView)
    if not success then
        _HarnessInternal.log.error("Failed to display coalition text: " .. tostring(result), "Trigger.outTextForCoalition")
        return nil
    end

    return true
end

--- Displays text message to a specific group
---@param groupId number The group ID to display message to
---@param text string The text message to display
---@param displayTime number? The time in seconds to display (default: 10)
---@param clearView boolean? Whether to clear the previous message (default: false)
---@return boolean? success Returns true if successful, nil on error
---@usage outTextForGroup(1001, "Group message", 15)
function outTextForGroup(groupId, text, displayTime, clearView)
    if not groupId or type(groupId) ~= "number" then
        _HarnessInternal.log.error("outTextForGroup requires valid group ID", "Trigger.outTextForGroup")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("outTextForGroup requires valid text string", "Trigger.outTextForGroup")
        return nil
    end

    if not displayTime or type(displayTime) ~= "number" then
        displayTime = 10
    end

    clearView = clearView or false

    local success, result = pcall(trigger.action.outTextForGroup, groupId, text, displayTime, clearView)
    if not success then
        _HarnessInternal.log.error("Failed to display group text: " .. tostring(result), "Trigger.outTextForGroup")
        return nil
    end

    return true
end

--- Displays text message to a specific unit
---@param unitId number The unit ID to display message to
---@param text string The text message to display
---@param displayTime number? The time in seconds to display (default: 10)
---@param clearView boolean? Whether to clear the previous message (default: false)
---@return boolean? success Returns true if successful, nil on error
---@usage outTextForUnit(2001, "Unit message", 10)
function outTextForUnit(unitId, text, displayTime, clearView)
    if not unitId or type(unitId) ~= "number" then
        _HarnessInternal.log.error("outTextForUnit requires valid unit ID", "Trigger.outTextForUnit")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("outTextForUnit requires valid text string", "Trigger.outTextForUnit")
        return nil
    end

    if not displayTime or type(displayTime) ~= "number" then
        displayTime = 10
    end

    clearView = clearView or false

    local success, result = pcall(trigger.action.outTextForUnit, unitId, text, displayTime, clearView)
    if not success then
        _HarnessInternal.log.error("Failed to display unit text: " .. tostring(result), "Trigger.outTextForUnit")
        return nil
    end

    return true
end

--- Plays a sound file to all players
---@param soundFile string The path to the sound file to play
---@param soundType any? Optional sound type parameter
---@return boolean? success Returns true if successful, nil on error
---@usage outSound("sounds/alarm.ogg")
function outSound(soundFile, soundType)
    if not soundFile or type(soundFile) ~= "string" then
        _HarnessInternal.log.error("outSound requires valid sound file path", "Trigger.outSound")
        return nil
    end

    local success, result = pcall(trigger.action.outSound, soundFile, soundType)
    if not success then
        _HarnessInternal.log.error("Failed to play sound: " .. tostring(result), "Trigger.outSound")
        return nil
    end

    return true
end

--- Plays a sound file to a specific coalition
---@param coalitionId number The coalition ID (0=neutral, 1=red, 2=blue)
---@param soundFile string The path to the sound file to play
---@param soundType any? Optional sound type parameter
---@return boolean? success Returns true if successful, nil on error
---@usage outSoundForCoalition(coalition.side.RED, "sounds/warning.ogg")
function outSoundForCoalition(coalitionId, soundFile, soundType)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("outSoundForCoalition requires valid coalition ID", "Trigger.outSoundForCoalition")
        return nil
    end

    if not soundFile or type(soundFile) ~= "string" then
        _HarnessInternal.log.error("outSoundForCoalition requires valid sound file path", "Trigger.outSoundForCoalition")
        return nil
    end

    local success, result = pcall(trigger.action.outSoundForCoalition, coalitionId, soundFile, soundType)
    if not success then
        _HarnessInternal.log.error("Failed to play coalition sound: " .. tostring(result), "Trigger.outSoundForCoalition")
        return nil
    end

    return true
end

--- Creates an explosion at the specified position
---@param pos table Position table with x, y, z coordinates
---@param power number The explosion power/strength
---@return boolean? success Returns true if successful, nil on error
---@usage explosion({x=1000, y=100, z=2000}, 500)
function explosion(pos, power)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("explosion requires valid position with x, y, z", "Trigger.explosion")
        return nil
    end

    if not power or type(power) ~= "number" or power <= 0 then
        _HarnessInternal.log.error("explosion requires valid power value", "Trigger.explosion")
        return nil
    end

    local success, result = pcall(trigger.action.explosion, pos, power)
    if not success then
        _HarnessInternal.log.error("Failed to create explosion: " .. tostring(result), "Trigger.explosion")
        return nil
    end

    return true
end

--- Creates smoke effect at the specified position
---@param pos table Position table with x, y, z coordinates
---@param smokeColor number Smoke color enum value
---@param density number? Optional smoke density
---@param name string? Optional name for the smoke effect
---@return boolean? success Returns true if successful, nil on error
---@usage smoke({x=1000, y=0, z=2000}, trigger.smokeColor.Red)
function smoke(pos, smokeColor, density, name)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("smoke requires valid position with x, y, z", "Trigger.smoke")
        return nil
    end

    if not smokeColor or type(smokeColor) ~= "number" then
        _HarnessInternal.log.error("smoke requires valid smoke color enum", "Trigger.smoke")
        return nil
    end

    local success, result = pcall(trigger.action.smoke, pos, smokeColor, density, name)
    if not success then
        _HarnessInternal.log.error("Failed to create smoke: " .. tostring(result), "Trigger.smoke")
        return nil
    end

    return true
end

--- Creates a big smoke effect at the specified position
---@param pos table Position table with x, y, z coordinates
---@param smokePreset number Smoke preset enum value
---@param density number? Optional smoke density
---@param name string? Optional name for the smoke effect
---@return boolean? success Returns true if successful, nil on error
---@usage effectSmokeBig({x=1000, y=0, z=2000}, trigger.effectPresets.BigSmoke)
function effectSmokeBig(pos, smokePreset, density, name)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("effectSmokeBig requires valid position with x, y, z", "Trigger.effectSmokeBig")
        return nil
    end

    if not smokePreset or type(smokePreset) ~= "number" then
        _HarnessInternal.log.error("effectSmokeBig requires valid smoke preset enum", "Trigger.effectSmokeBig")
        return nil
    end

    local success, result = pcall(trigger.action.effectSmokeBig, pos, smokePreset, density, name)
    if not success then
        _HarnessInternal.log.error("Failed to create big smoke effect: " .. tostring(result), "Trigger.effectSmokeBig")
        return nil
    end

    return true
end

--- Stops a named smoke effect
---@param name string The name of the smoke effect to stop
---@return boolean? success Returns true if successful, nil on error
---@usage effectSmokeStop("smoke1")
function effectSmokeStop(name)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("effectSmokeStop requires valid smoke effect name", "Trigger.effectSmokeStop")
        return nil
    end

    local success, result = pcall(trigger.action.effectSmokeStop, name)
    if not success then
        _HarnessInternal.log.error("Failed to stop smoke effect: " .. tostring(result), "Trigger.effectSmokeStop")
        return nil
    end

    return true
end

--- Creates an illumination bomb at the specified position
---@param pos table Position table with x, y, z coordinates
---@param power number? The illumination power (default: 1000000)
---@return boolean? success Returns true if successful, nil on error
---@usage illuminationBomb({x=1000, y=500, z=2000}, 2000000)
function illuminationBomb(pos, power)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("illuminationBomb requires valid position with x, y, z", "Trigger.illuminationBomb")
        return nil
    end

    if not power or type(power) ~= "number" or power <= 0 then
        power = 1000000
    end

    local success, result = pcall(trigger.action.illuminationBomb, pos, power)
    if not success then
        _HarnessInternal.log.error("Failed to create illumination bomb: " .. tostring(result), "Trigger.illuminationBomb")
        return nil
    end

    return true
end

--- Fires a signal flare at the specified position
---@param pos table Position table with x, y, z coordinates
---@param flareColor number Flare color enum value
---@param azimuth number? The azimuth direction in radians (default: 0)
---@return boolean? success Returns true if successful, nil on error
---@usage signalFlare({x=1000, y=100, z=2000}, trigger.flareColor.Red, math.rad(45))
function signalFlare(pos, flareColor, azimuth)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("signalFlare requires valid position with x, y, z", "Trigger.signalFlare")
        return nil
    end

    if not flareColor or type(flareColor) ~= "number" then
        _HarnessInternal.log.error("signalFlare requires valid flare color enum", "Trigger.signalFlare")
        return nil
    end

    if not azimuth or type(azimuth) ~= "number" then
        azimuth = 0
    end

    local success, result = pcall(trigger.action.signalFlare, pos, flareColor, azimuth)
    if not success then
        _HarnessInternal.log.error("Failed to create signal flare: " .. tostring(result), "Trigger.signalFlare")
        return nil
    end

    return true
end

--- Starts a radio transmission from a position
---@param filename string The audio file to transmit
---@param pos table Position table with x, y, z coordinates
---@param modulation number? Radio modulation type (default: 0)
---@param loop boolean? Whether to loop the transmission
---@param frequency number? Transmission frequency in Hz (default: 124000000)
---@param power number? Transmission power (default: 100)
---@param name string? Optional name for the transmission
---@return boolean? success Returns true if successful, nil on error
---@usage radioTransmission("sounds/message.ogg", {x=1000, y=100, z=2000}, 0, true, 124000000, 100, "radio1")
function radioTransmission(filename, pos, modulation, loop, frequency, power, name)
    if not filename or type(filename) ~= "string" then
        _HarnessInternal.log.error("radioTransmission requires valid filename", "Trigger.radioTransmission")
        return nil
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("radioTransmission requires valid position with x, y, z", "Trigger.radioTransmission")
        return nil
    end

    if not modulation or type(modulation) ~= "number" then
        modulation = 0
    end

    if not frequency or type(frequency) ~= "number" then
        frequency = 124000000
    end

    if not power or type(power) ~= "number" then
        power = 100
    end

    local success, result = pcall(trigger.action.radioTransmission, filename, pos, modulation, loop, frequency, power, name)
    if not success then
        _HarnessInternal.log.error("Failed to start radio transmission: " .. tostring(result), "Trigger.radioTransmission")
        return nil
    end

    return true
end

--- Stops a named radio transmission
---@param name string The name of the transmission to stop
---@return boolean? success Returns true if successful, nil on error
---@usage stopRadioTransmission("radio1")
function stopRadioTransmission(name)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("stopRadioTransmission requires valid transmission name", "Trigger.stopRadioTransmission")
        return nil
    end

    local success, result = pcall(trigger.action.stopRadioTransmission, name)
    if not success then
        _HarnessInternal.log.error("Failed to stop radio transmission: " .. tostring(result), "Trigger.stopRadioTransmission")
        return nil
    end

    return true
end

--- Sets the radius of an existing map mark
---@param markId number The ID of the mark to modify
---@param radius number The new radius in meters
---@return boolean? success Returns true if successful, nil on error
---@usage setMarkupRadius(1001, 5000)
function setMarkupRadius(markId, radius)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("setMarkupRadius requires valid mark ID", "Trigger.setMarkupRadius")
        return nil
    end

    if not radius or type(radius) ~= "number" or radius <= 0 then
        _HarnessInternal.log.error("setMarkupRadius requires valid radius", "Trigger.setMarkupRadius")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupRadius, markId, radius)
    if not success then
        _HarnessInternal.log.error("Failed to set markup radius: " .. tostring(result), "Trigger.setMarkupRadius")
        return nil
    end

    return true
end

--- Sets the text of an existing map mark
---@param markId number The ID of the mark to modify
---@param text string The new text for the mark
---@return boolean? success Returns true if successful, nil on error
---@usage setMarkupText(1001, "New target location")
function setMarkupText(markId, text)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("setMarkupText requires valid mark ID", "Trigger.setMarkupText")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("setMarkupText requires valid text string", "Trigger.setMarkupText")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupText, markId, text)
    if not success then
        _HarnessInternal.log.error("Failed to set markup text: " .. tostring(result), "Trigger.setMarkupText")
        return nil
    end

    return true
end

--- Sets the color of an existing map mark
---@param markId number The ID of the mark to modify
---@param color table Color table with r, g, b, a values (0-1)
---@return boolean? success Returns true if successful, nil on error
---@usage setMarkupColor(1001, {r=1, g=0, b=0, a=1})
function setMarkupColor(markId, color)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("setMarkupColor requires valid mark ID", "Trigger.setMarkupColor")
        return nil
    end

    if not color or type(color) ~= "table" then
        _HarnessInternal.log.error("setMarkupColor requires valid color table", "Trigger.setMarkupColor")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupColor, markId, color)
    if not success then
        _HarnessInternal.log.error("Failed to set markup color: " .. tostring(result), "Trigger.setMarkupColor")
        return nil
    end

    return true
end

--- Sets the fill color of an existing map mark
---@param markId number The ID of the mark to modify
---@param colorFill table Color table with r, g, b, a values (0-1)
---@return boolean? success Returns true if successful, nil on error
---@usage setMarkupColorFill(1001, {r=0, g=1, b=0, a=0.5})
function setMarkupColorFill(markId, colorFill)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("setMarkupColorFill requires valid mark ID", "Trigger.setMarkupColorFill")
        return nil
    end

    if not colorFill or type(colorFill) ~= "table" then
        _HarnessInternal.log.error("setMarkupColorFill requires valid color fill table", "Trigger.setMarkupColorFill")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupColorFill, markId, colorFill)
    if not success then
        _HarnessInternal.log.error("Failed to set markup color fill: " .. tostring(result), "Trigger.setMarkupColorFill")
        return nil
    end

    return true
end

--- Sets the font size of an existing map mark
---@param markId number The ID of the mark to modify
---@param fontSize number The font size in points
---@return boolean? success Returns true if successful, nil on error
---@usage setMarkupFontSize(1001, 18)
function setMarkupFontSize(markId, fontSize)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("setMarkupFontSize requires valid mark ID", "Trigger.setMarkupFontSize")
        return nil
    end

    if not fontSize or type(fontSize) ~= "number" or fontSize <= 0 then
        _HarnessInternal.log.error("setMarkupFontSize requires valid font size", "Trigger.setMarkupFontSize")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupFontSize, markId, fontSize)
    if not success then
        _HarnessInternal.log.error("Failed to set markup font size: " .. tostring(result), "Trigger.setMarkupFontSize")
        return nil
    end

    return true
end

--- Removes a map mark
---@param markId number The ID of the mark to remove
---@return boolean? success Returns true if successful, nil on error
---@usage removeMark(1001)
function removeMark(markId)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("removeMark requires valid mark ID", "Trigger.removeMark")
        return nil
    end

    local success, result = pcall(trigger.action.removeMark, markId)
    if not success then
        _HarnessInternal.log.error("Failed to remove mark: " .. tostring(result), "Trigger.removeMark")
        return nil
    end

    return true
end

--- Creates a map mark visible to all players
---@param markId number Unique ID for the mark
---@param text string? Text to display (default: "")
---@param pos table Position table with x, y, z coordinates
---@param readOnly boolean? Whether the mark is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage markToAll(1001, "Target", {x=1000, y=0, z=2000}, true)
function markToAll(markId, text, pos, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("markToAll requires valid mark ID", "Trigger.markToAll")
        return nil
    end

    if not text or type(text) ~= "string" then
        text = ""
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("markToAll requires valid position with x, y, z", "Trigger.markToAll")
        return nil
    end

    local success, result = pcall(trigger.action.markToAll, markId, text, pos, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create mark for all: " .. tostring(result), "Trigger.markToAll")
        return nil
    end

    return true
end

--- Creates a map mark visible to a specific coalition
---@param markId number Unique ID for the mark
---@param text string? Text to display (default: "")
---@param pos table Position table with x, y, z coordinates
---@param coalitionId number The coalition ID (0=neutral, 1=red, 2=blue)
---@param readOnly boolean? Whether the mark is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage markToCoalition(1001, "Enemy Base", {x=1000, y=0, z=2000}, coalition.side.RED, true)
function markToCoalition(markId, text, pos, coalitionId, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("markToCoalition requires valid mark ID", "Trigger.markToCoalition")
        return nil
    end

    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("markToCoalition requires valid coalition ID", "Trigger.markToCoalition")
        return nil
    end

    if not text or type(text) ~= "string" then
        text = ""
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("markToCoalition requires valid position with x, y, z", "Trigger.markToCoalition")
        return nil
    end

    local success, result = pcall(trigger.action.markToCoalition, markId, text, pos, coalitionId, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create mark for coalition: " .. tostring(result), "Trigger.markToCoalition")
        return nil
    end

    return true
end

--- Creates a map mark visible to a specific group
---@param markId number Unique ID for the mark
---@param text string? Text to display (default: "")
---@param pos table Position table with x, y, z coordinates
---@param groupId number The group ID
---@param readOnly boolean? Whether the mark is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage markToGroup(1001, "Waypoint", {x=1000, y=0, z=2000}, 501, false)
function markToGroup(markId, text, pos, groupId, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("markToGroup requires valid mark ID", "Trigger.markToGroup")
        return nil
    end

    if not groupId or type(groupId) ~= "number" then
        _HarnessInternal.log.error("markToGroup requires valid group ID", "Trigger.markToGroup")
        return nil
    end

    if not text or type(text) ~= "string" then
        text = ""
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("markToGroup requires valid position with x, y, z", "Trigger.markToGroup")
        return nil
    end

    local success, result = pcall(trigger.action.markToGroup, markId, text, pos, groupId, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create mark for group: " .. tostring(result), "Trigger.markToGroup")
        return nil
    end

    return true
end

--- Draws a line on the map visible to all players
---@param markId number Unique ID for the line
---@param startPos table Start position with x, y, z coordinates
---@param endPos table End position with x, y, z coordinates
---@param color table? Color table with r, g, b, a values (0-1)
---@param lineType number? Line type enum
---@param readOnly boolean? Whether the line is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage lineToAll(1001, {x=1000, y=0, z=2000}, {x=2000, y=0, z=3000}, {r=1, g=0, b=0, a=1})
function lineToAll(markId, startPos, endPos, color, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("lineToAll requires valid mark ID", "Trigger.lineToAll")
        return nil
    end

    if not startPos or type(startPos) ~= "table" or not startPos.x or not startPos.y or not startPos.z then
        _HarnessInternal.log.error("lineToAll requires valid start position with x, y, z", "Trigger.lineToAll")
        return nil
    end

    if not endPos or type(endPos) ~= "table" or not endPos.x or not endPos.y or not endPos.z then
        _HarnessInternal.log.error("lineToAll requires valid end position with x, y, z", "Trigger.lineToAll")
        return nil
    end

    local success, result = pcall(trigger.action.lineToAll, markId, startPos, endPos, color, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create line for all: " .. tostring(result), "Trigger.lineToAll")
        return nil
    end

    return true
end

--- Draws a circle on the map visible to all players
---@param markId number Unique ID for the circle
---@param center table Center position with x, y, z coordinates
---@param radius number Circle radius in meters
---@param color table? Border color with r, g, b, a values (0-1)
---@param fillColor table? Fill color with r, g, b, a values (0-1)
---@param lineType number? Line type enum
---@param readOnly boolean? Whether the circle is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage circleToAll(1001, {x=1000, y=0, z=2000}, 500, {r=1, g=0, b=0, a=1}, {r=1, g=0, b=0, a=0.3})
function circleToAll(markId, center, radius, color, fillColor, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("circleToAll requires valid mark ID", "Trigger.circleToAll")
        return nil
    end

    if not center or type(center) ~= "table" or not center.x or not center.y or not center.z then
        _HarnessInternal.log.error("circleToAll requires valid center position with x, y, z", "Trigger.circleToAll")
        return nil
    end

    if not radius or type(radius) ~= "number" or radius <= 0 then
        _HarnessInternal.log.error("circleToAll requires valid radius", "Trigger.circleToAll")
        return nil
    end

    local success, result = pcall(trigger.action.circleToAll, markId, center, radius, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create circle for all: " .. tostring(result), "Trigger.circleToAll")
        return nil
    end

    return true
end

--- Draws a rectangle on the map visible to all players
---@param markId number Unique ID for the rectangle
---@param startPos table First corner position with x, y, z coordinates
---@param endPos table Opposite corner position with x, y, z coordinates
---@param color table? Border color with r, g, b, a values (0-1)
---@param fillColor table? Fill color with r, g, b, a values (0-1)
---@param lineType number? Line type enum
---@param readOnly boolean? Whether the rectangle is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage rectToAll(1001, {x=1000, y=0, z=2000}, {x=2000, y=0, z=3000}, {r=0, g=1, b=0, a=1})
function rectToAll(markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("rectToAll requires valid mark ID", "Trigger.rectToAll")
        return nil
    end

    if not startPos or type(startPos) ~= "table" or not startPos.x or not startPos.y or not startPos.z then
        _HarnessInternal.log.error("rectToAll requires valid start position with x, y, z", "Trigger.rectToAll")
        return nil
    end

    if not endPos or type(endPos) ~= "table" or not endPos.x or not endPos.y or not endPos.z then
        _HarnessInternal.log.error("rectToAll requires valid end position with x, y, z", "Trigger.rectToAll")
        return nil
    end

    local success, result = pcall(trigger.action.rectToAll, markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create rectangle for all: " .. tostring(result), "Trigger.rectToAll")
        return nil
    end

    return true
end

--- Draws a quadrilateral on the map visible to all players
---@param markId number Unique ID for the quad
---@param point1 table First point with x, y, z coordinates
---@param point2 table Second point with x, y, z coordinates
---@param point3 table Third point with x, y, z coordinates
---@param point4 table Fourth point with x, y, z coordinates
---@param color table? Border color with r, g, b, a values (0-1)
---@param fillColor table? Fill color with r, g, b, a values (0-1)
---@param lineType number? Line type enum
---@param readOnly boolean? Whether the quad is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage quadToAll(1001, {x=1000, y=0, z=2000}, {x=2000, y=0, z=2000}, {x=2000, y=0, z=3000}, {x=1000, y=0, z=3000})
function quadToAll(markId, point1, point2, point3, point4, color, fillColor, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("quadToAll requires valid mark ID", "Trigger.quadToAll")
        return nil
    end

    if not point1 or type(point1) ~= "table" or not point1.x or not point1.y or not point1.z then
        _HarnessInternal.log.error("quadToAll requires valid point1 with x, y, z", "Trigger.quadToAll")
        return nil
    end

    if not point2 or type(point2) ~= "table" or not point2.x or not point2.y or not point2.z then
        _HarnessInternal.log.error("quadToAll requires valid point2 with x, y, z", "Trigger.quadToAll")
        return nil
    end

    if not point3 or type(point3) ~= "table" or not point3.x or not point3.y or not point3.z then
        _HarnessInternal.log.error("quadToAll requires valid point3 with x, y, z", "Trigger.quadToAll")
        return nil
    end

    if not point4 or type(point4) ~= "table" or not point4.x or not point4.y or not point4.z then
        _HarnessInternal.log.error("quadToAll requires valid point4 with x, y, z", "Trigger.quadToAll")
        return nil
    end

    local success, result = pcall(trigger.action.quadToAll, markId, point1, point2, point3, point4, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create quad for all: " .. tostring(result), "Trigger.quadToAll")
        return nil
    end

    return true
end

--- Draws text on the map visible to all players
---@param markId number Unique ID for the text
---@param text string The text to display
---@param pos table Position with x, y, z coordinates
---@param color table? Text color with r, g, b, a values (0-1)
---@param fillColor table? Background color with r, g, b, a values (0-1)
---@param fontSize number? Font size in points
---@param readOnly boolean? Whether the text is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage textToAll(1001, "Objective", {x=1000, y=0, z=2000}, {r=1, g=1, b=1, a=1}, nil, 14)
function textToAll(markId, text, pos, color, fillColor, fontSize, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("textToAll requires valid mark ID", "Trigger.textToAll")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("textToAll requires valid text string", "Trigger.textToAll")
        return nil
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("textToAll requires valid position with x, y, z", "Trigger.textToAll")
        return nil
    end

    local success, result = pcall(trigger.action.textToAll, markId, text, pos, color, fillColor, fontSize, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create text for all: " .. tostring(result), "Trigger.textToAll")
        return nil
    end

    return true
end

--- Draws an arrow on the map visible to all players
---@param markId number Unique ID for the arrow
---@param startPos table Start position with x, y, z coordinates
---@param endPos table End position (arrow points here) with x, y, z coordinates
---@param color table? Arrow color with r, g, b, a values (0-1)
---@param fillColor table? Fill color with r, g, b, a values (0-1)
---@param lineType number? Line type enum
---@param readOnly boolean? Whether the arrow is read-only
---@param message string? Optional message
---@return boolean? success Returns true if successful, nil on error
---@usage arrowToAll(1001, {x=1000, y=0, z=2000}, {x=2000, y=0, z=3000}, {r=1, g=0, b=0, a=1})
function arrowToAll(markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("arrowToAll requires valid mark ID", "Trigger.arrowToAll")
        return nil
    end

    if not startPos or type(startPos) ~= "table" or not startPos.x or not startPos.y or not startPos.z then
        _HarnessInternal.log.error("arrowToAll requires valid start position with x, y, z", "Trigger.arrowToAll")
        return nil
    end

    if not endPos or type(endPos) ~= "table" or not endPos.x or not endPos.y or not endPos.z then
        _HarnessInternal.log.error("arrowToAll requires valid end position with x, y, z", "Trigger.arrowToAll")
        return nil
    end

    local success, result = pcall(trigger.action.arrowToAll, markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create arrow for all: " .. tostring(result), "Trigger.arrowToAll")
        return nil
    end

    return true
end

--- Sets an AI task for a group
---@param group table The group object
---@param aiTask table The AI task table
---@return boolean? success Returns true if successful, nil on error
---@usage setAITask(group, {id="Mission", params={...}})
function setAITask(group, aiTask)
    if not group then
        _HarnessInternal.log.error("setAITask requires valid group", "Trigger.setAITask")
        return nil
    end

    if not aiTask or type(aiTask) ~= "table" then
        _HarnessInternal.log.error("setAITask requires valid AI task table", "Trigger.setAITask")
        return nil
    end

    local success, result = pcall(trigger.action.setAITask, group, aiTask)
    if not success then
        _HarnessInternal.log.error("Failed to set AI task: " .. tostring(result), "Trigger.setAITask")
        return nil
    end

    return true
end

--- Pushes an AI task to a group's task queue
---@param group table The group object
---@param aiTask table The AI task table
---@return boolean? success Returns true if successful, nil on error
---@usage pushAITask(group, {id="EngageTargets", params={...}})
function pushAITask(group, aiTask)
    if not group then
        _HarnessInternal.log.error("pushAITask requires valid group", "Trigger.pushAITask")
        return nil
    end

    if not aiTask or type(aiTask) ~= "table" then
        _HarnessInternal.log.error("pushAITask requires valid AI task table", "Trigger.pushAITask")
        return nil
    end

    local success, result = pcall(trigger.action.pushAITask, group, aiTask)
    if not success then
        _HarnessInternal.log.error("Failed to push AI task: " .. tostring(result), "Trigger.pushAITask")
        return nil
    end

    return true
end

--- Activates a group
---@param group table The group object to activate
---@return boolean? success Returns true if successful, nil on error
---@usage activateGroup(group)
function activateGroup(group)
    if not group then
        _HarnessInternal.log.error("activateGroup requires valid group", "Trigger.activateGroup")
        return nil
    end

    local success, result = pcall(trigger.action.activateGroup, group)
    if not success then
        _HarnessInternal.log.error("Failed to activate group: " .. tostring(result), "Trigger.activateGroup")
        return nil
    end

    return true
end

--- Deactivates a group
---@param group table The group object to deactivate
---@return boolean? success Returns true if successful, nil on error
---@usage deactivateGroup(group)
function deactivateGroup(group)
    if not group then
        _HarnessInternal.log.error("deactivateGroup requires valid group", "Trigger.deactivateGroup")
        return nil
    end

    local success, result = pcall(trigger.action.deactivateGroup, group)
    if not success then
        _HarnessInternal.log.error("Failed to deactivate group: " .. tostring(result), "Trigger.deactivateGroup")
        return nil
    end

    return true
end

--- Enables AI for a group
---@param group table The group object
---@return boolean? success Returns true if successful, nil on error
---@usage setGroupAIOn(group)
function setGroupAIOn(group)
    if not group then
        _HarnessInternal.log.error("setGroupAIOn requires valid group", "Trigger.setGroupAIOn")
        return nil
    end

    local success, result = pcall(trigger.action.setGroupAIOn, group)
    if not success then
        _HarnessInternal.log.error("Failed to set group AI on: " .. tostring(result), "Trigger.setGroupAIOn")
        return nil
    end

    return true
end

--- Disables AI for a group
---@param group table The group object
---@return boolean? success Returns true if successful, nil on error
---@usage setGroupAIOff(group)
function setGroupAIOff(group)
    if not group then
        _HarnessInternal.log.error("setGroupAIOff requires valid group", "Trigger.setGroupAIOff")
        return nil
    end

    local success, result = pcall(trigger.action.setGroupAIOff, group)
    if not success then
        _HarnessInternal.log.error("Failed to set group AI off: " .. tostring(result), "Trigger.setGroupAIOff")
        return nil
    end

    return true
end

--- Stops a group from moving
---@param group table The group object
---@return boolean? success Returns true if successful, nil on error
---@usage groupStopMoving(group)
function groupStopMoving(group)
    if not group then
        _HarnessInternal.log.error("groupStopMoving requires valid group", "Trigger.groupStopMoving")
        return nil
    end

    local success, result = pcall(trigger.action.groupStopMoving, group)
    if not success then
        _HarnessInternal.log.error("Failed to stop group moving: " .. tostring(result), "Trigger.groupStopMoving")
        return nil
    end

    return true
end

--- Resumes movement for a stopped group
---@param group table The group object
---@return boolean? success Returns true if successful, nil on error
---@usage groupContinueMoving(group)
function groupContinueMoving(group)
    if not group then
        _HarnessInternal.log.error("groupContinueMoving requires valid group", "Trigger.groupContinueMoving")
        return nil
    end

    local success, result = pcall(trigger.action.groupContinueMoving, group)
    if not success then
        _HarnessInternal.log.error("Failed to continue group moving: " .. tostring(result), "Trigger.groupContinueMoving")
        return nil
    end

    return true
end