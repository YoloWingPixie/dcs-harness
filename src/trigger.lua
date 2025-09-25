--[[
    Trigger Module - DCS World Trigger API Wrappers
    
    This module provides validated wrapper functions for DCS trigger.action operations,
    including messages, explosions, smoke, illumination, and other effects.
]]

require("logger")
require("vector")

-- Internal helpers for colors/fills
local function _normalizeColor(c)
    if type(c) ~= "table" then
        return {r = 1, g = 1, b = 1, a = 1}
    end
    return {
        r = c.r or c[1] or 1,
        g = c.g or c[2] or 1,
        b = c.b or c[3] or 1,
        a = c.a or c[4] or 1
    }
end

local function _defaultFill(color, fill)
    if type(fill) == "table" then
        return {
            r = fill.r or fill[1] or 1,
            g = fill.g or fill[2] or 1,
            b = fill.b or fill[3] or 1,
            a = fill.a or fill[4] or 0.25
        }
    end
    local c = _normalizeColor(color)
    local a = c.a or 1
    return {r = c.r, g = c.g, b = c.b, a = math.max(0.0, math.min(1.0, a * 0.25))}
end

--- Displays text message to all players
---@param text string The text message to display
---@param displayTime number? The time in seconds to display (default: 10)
---@param clearView boolean? Whether to clear the previous message (default: false)
---@return boolean? success Returns true if successful, nil on error
---@usage OutText("Hello World", 15, true)
function OutText(text, displayTime, clearView)
    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("OutText requires valid text string", "Trigger.OutText")
        return nil
    end

    if not displayTime or type(displayTime) ~= "number" then
        displayTime = 10
    end

    clearView = clearView or false

    local success, result = pcall(trigger.action.outText, text, displayTime, clearView)
    if not success then
        _HarnessInternal.log.error("Failed to display text: " .. tostring(result), "Trigger.OutText")
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
---@usage OutTextForCoalition(coalition.side.BLUE, "Blue team message", 20)
function OutTextForCoalition(coalitionId, text, displayTime, clearView)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("OutTextForCoalition requires valid coalition ID", "Trigger.OutTextForCoalition")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("OutTextForCoalition requires valid text string", "Trigger.OutTextForCoalition")
        return nil
    end

    if not displayTime or type(displayTime) ~= "number" then
        displayTime = 10
    end

    clearView = clearView or false

    local success, result = pcall(trigger.action.outTextForCoalition, coalitionId, text, displayTime, clearView)
    if not success then
        _HarnessInternal.log.error("Failed to display coalition text: " .. tostring(result), "Trigger.OutTextForCoalition")
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
---@usage OutTextForGroup(1001, "Group message", 15)
function OutTextForGroup(groupId, text, displayTime, clearView)
    if not groupId or type(groupId) ~= "number" then
        _HarnessInternal.log.error("OutTextForGroup requires valid group ID", "Trigger.OutTextForGroup")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("OutTextForGroup requires valid text string", "Trigger.OutTextForGroup")
        return nil
    end

    if not displayTime or type(displayTime) ~= "number" then
        displayTime = 10
    end

    clearView = clearView or false

    local success, result = pcall(trigger.action.outTextForGroup, groupId, text, displayTime, clearView)
    if not success then
        _HarnessInternal.log.error("Failed to display group text: " .. tostring(result), "Trigger.OutTextForGroup")
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
---@usage OutTextForUnit(2001, "Unit message", 10)
function OutTextForUnit(unitId, text, displayTime, clearView)
    if not unitId or type(unitId) ~= "number" then
        _HarnessInternal.log.error("OutTextForUnit requires valid unit ID", "Trigger.OutTextForUnit")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("OutTextForUnit requires valid text string", "Trigger.OutTextForUnit")
        return nil
    end

    if not displayTime or type(displayTime) ~= "number" then
        displayTime = 10
    end

    clearView = clearView or false

    local success, result = pcall(trigger.action.outTextForUnit, unitId, text, displayTime, clearView)
    if not success then
        _HarnessInternal.log.error("Failed to display unit text: " .. tostring(result), "Trigger.OutTextForUnit")
        return nil
    end

    return true
end

--- Plays a sound file to all players
---@param soundFile string The path to the sound file to play
---@param soundType any? Optional sound type parameter
---@return boolean? success Returns true if successful, nil on error
---@usage OutSound("sounds/alarm.ogg")
function OutSound(soundFile, soundType)
    if not soundFile or type(soundFile) ~= "string" then
        _HarnessInternal.log.error("OutSound requires valid sound file path", "Trigger.OutSound")
        return nil
    end

    local success, result = pcall(trigger.action.outSound, soundFile, soundType)
    if not success then
        _HarnessInternal.log.error("Failed to play sound: " .. tostring(result), "Trigger.OutSound")
        return nil
    end

    return true
end

--- Plays a sound file to a specific coalition
---@param coalitionId number The coalition ID (0=neutral, 1=red, 2=blue)
---@param soundFile string The path to the sound file to play
---@param soundType any? Optional sound type parameter
---@return boolean? success Returns true if successful, nil on error
---@usage OutSoundForCoalition(coalition.side.RED, "sounds/warning.ogg")
function OutSoundForCoalition(coalitionId, soundFile, soundType)
    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("OutSoundForCoalition requires valid coalition ID", "Trigger.OutSoundForCoalition")
        return nil
    end

    if not soundFile or type(soundFile) ~= "string" then
        _HarnessInternal.log.error("OutSoundForCoalition requires valid sound file path", "Trigger.OutSoundForCoalition")
        return nil
    end

    local success, result = pcall(trigger.action.outSoundForCoalition, coalitionId, soundFile, soundType)
    if not success then
        _HarnessInternal.log.error("Failed to play coalition sound: " .. tostring(result), "Trigger.OutSoundForCoalition")
        return nil
    end

    return true
end

--- Creates an explosion at the specified position
---@param pos table Position table with x, y, z coordinates
---@param power number The explosion power/strength
---@return boolean? success Returns true if successful, nil on error
---@usage Explosion({x=1000, y=100, z=2000}, 500)
function Explosion(pos, power)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("Explosion requires valid position with x, y, z", "Trigger.Explosion")
        return nil
    end

    if not power or type(power) ~= "number" or power <= 0 then
        _HarnessInternal.log.error("Explosion requires valid power value", "Trigger.Explosion")
        return nil
    end

    local success, result = pcall(trigger.action.explosion, pos, power)
    if not success then
        _HarnessInternal.log.error("Failed to create explosion: " .. tostring(result), "Trigger.Explosion")
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
---@usage Smoke({x=1000, y=0, z=2000}, trigger.smokeColor.Red)
function Smoke(pos, smokeColor, density, name)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("Smoke requires valid position with x, y, z", "Trigger.Smoke")
        return nil
    end

    if not smokeColor or type(smokeColor) ~= "number" then
        _HarnessInternal.log.error("Smoke requires valid smoke color enum", "Trigger.Smoke")
        return nil
    end

    local success, result = pcall(trigger.action.smoke, pos, smokeColor, density, name)
    if not success then
        _HarnessInternal.log.error("Failed to create smoke: " .. tostring(result), "Trigger.Smoke")
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
---@usage EffectSmokeBig({x=1000, y=0, z=2000}, trigger.effectPresets.BigSmoke)
function EffectSmokeBig(pos, smokePreset, density, name)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("EffectSmokeBig requires valid position with x, y, z", "Trigger.EffectSmokeBig")
        return nil
    end

    if not smokePreset or type(smokePreset) ~= "number" then
        _HarnessInternal.log.error("EffectSmokeBig requires valid smoke preset enum", "Trigger.EffectSmokeBig")
        return nil
    end

    local success, result = pcall(trigger.action.effectSmokeBig, pos, smokePreset, density, name)
    if not success then
        _HarnessInternal.log.error("Failed to create big smoke effect: " .. tostring(result), "Trigger.EffectSmokeBig")
        return nil
    end

    return true
end

--- Stops a named smoke effect
---@param name string The name of the smoke effect to stop
---@return boolean? success Returns true if successful, nil on error
---@usage EffectSmokeStop("smoke1")
function EffectSmokeStop(name)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("EffectSmokeStop requires valid smoke effect name", "Trigger.EffectSmokeStop")
        return nil
    end

    local success, result = pcall(trigger.action.effectSmokeStop, name)
    if not success then
        _HarnessInternal.log.error("Failed to stop smoke effect: " .. tostring(result), "Trigger.EffectSmokeStop")
        return nil
    end

    return true
end

--- Creates an illumination bomb at the specified position
---@param pos table Position table with x, y, z coordinates
---@param power number? The illumination power (default: 1000000)
---@return boolean? success Returns true if successful, nil on error
---@usage IlluminationBomb({x=1000, y=500, z=2000}, 2000000)
function IlluminationBomb(pos, power)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("IlluminationBomb requires valid position with x, y, z", "Trigger.IlluminationBomb")
        return nil
    end

    if not power or type(power) ~= "number" or power <= 0 then
        power = 1000000
    end

    local success, result = pcall(trigger.action.illuminationBomb, pos, power)
    if not success then
        _HarnessInternal.log.error("Failed to create illumination bomb: " .. tostring(result), "Trigger.IlluminationBomb")
        return nil
    end

    return true
end

--- Fires a signal flare at the specified position
---@param pos table Position table with x, y, z coordinates
---@param flareColor number Flare color enum value
---@param azimuth number? The azimuth direction in radians (default: 0)
---@return boolean? success Returns true if successful, nil on error
---@usage SignalFlare({x=1000, y=100, z=2000}, trigger.flareColor.Red, math.rad(45))
function SignalFlare(pos, flareColor, azimuth)
    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("SignalFlare requires valid position with x, y, z", "Trigger.SignalFlare")
        return nil
    end

    if not flareColor or type(flareColor) ~= "number" then
        _HarnessInternal.log.error("SignalFlare requires valid flare color enum", "Trigger.SignalFlare")
        return nil
    end

    if not azimuth or type(azimuth) ~= "number" then
        azimuth = 0
    end

    local success, result = pcall(trigger.action.signalFlare, pos, flareColor, azimuth)
    if not success then
        _HarnessInternal.log.error("Failed to create signal flare: " .. tostring(result), "Trigger.SignalFlare")
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
---@usage RadioTransmission("sounds/message.ogg", {x=1000, y=100, z=2000}, 0, true, 124000000, 100, "radio1")
function RadioTransmission(filename, pos, modulation, loop, frequency, power, name)
    if not filename or type(filename) ~= "string" then
        _HarnessInternal.log.error("RadioTransmission requires valid filename", "Trigger.RadioTransmission")
        return nil
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("RadioTransmission requires valid position with x, y, z", "Trigger.RadioTransmission")
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
        _HarnessInternal.log.error("Failed to start radio transmission: " .. tostring(result), "Trigger.RadioTransmission")
        return nil
    end

    return true
end

--- Stops a named radio transmission
---@param name string The name of the transmission to stop
---@return boolean? success Returns true if successful, nil on error
---@usage StopRadioTransmission("radio1")
function StopRadioTransmission(name)
    if not name or type(name) ~= "string" then
        _HarnessInternal.log.error("StopRadioTransmission requires valid transmission name", "Trigger.StopRadioTransmission")
        return nil
    end

    local success, result = pcall(trigger.action.stopRadioTransmission, name)
    if not success then
        _HarnessInternal.log.error("Failed to stop radio transmission: " .. tostring(result), "Trigger.StopRadioTransmission")
        return nil
    end

    return true
end

--- Sets the radius of an existing map mark
---@param markId number The ID of the mark to modify
---@param radius number The new radius in meters
---@return boolean? success Returns true if successful, nil on error
---@usage SetMarkupRadius(1001, 5000)
function SetMarkupRadius(markId, radius)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("SetMarkupRadius requires valid mark ID", "Trigger.SetMarkupRadius")
        return nil
    end

    if not radius or type(radius) ~= "number" or radius <= 0 then
        _HarnessInternal.log.error("SetMarkupRadius requires valid radius", "Trigger.SetMarkupRadius")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupRadius, markId, radius)
    if not success then
        _HarnessInternal.log.error("Failed to set markup radius: " .. tostring(result), "Trigger.SetMarkupRadius")
        return nil
    end

    return true
end

--- Sets the text of an existing map mark
---@param markId number The ID of the mark to modify
---@param text string The new text for the mark
---@return boolean? success Returns true if successful, nil on error
---@usage SetMarkupText(1001, "New target location")
function SetMarkupText(markId, text)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("SetMarkupText requires valid mark ID", "Trigger.SetMarkupText")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("SetMarkupText requires valid text string", "Trigger.SetMarkupText")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupText, markId, text)
    if not success then
        _HarnessInternal.log.error("Failed to set markup text: " .. tostring(result), "Trigger.SetMarkupText")
        return nil
    end

    return true
end

--- Sets the color of an existing map mark
---@param markId number The ID of the mark to modify
---@param color table Color table with r, g, b, a values (0-1)
---@return boolean? success Returns true if successful, nil on error
---@usage SetMarkupColor(1001, {r=1, g=0, b=0, a=1})
function SetMarkupColor(markId, color)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("SetMarkupColor requires valid mark ID", "Trigger.SetMarkupColor")
        return nil
    end

    if not color or type(color) ~= "table" then
        _HarnessInternal.log.error("SetMarkupColor requires valid color table", "Trigger.SetMarkupColor")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupColor, markId, color)
    if not success then
        _HarnessInternal.log.error("Failed to set markup color: " .. tostring(result), "Trigger.SetMarkupColor")
        return nil
    end

    return true
end

--- Sets the fill color of an existing map mark
---@param markId number The ID of the mark to modify
---@param colorFill table Color table with r, g, b, a values (0-1)
---@return boolean? success Returns true if successful, nil on error
---@usage SetMarkupColorFill(1001, {r=0, g=1, b=0, a=0.5})
function SetMarkupColorFill(markId, colorFill)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("SetMarkupColorFill requires valid mark ID", "Trigger.SetMarkupColorFill")
        return nil
    end

    if not colorFill or type(colorFill) ~= "table" then
        _HarnessInternal.log.error("SetMarkupColorFill requires valid color fill table", "Trigger.SetMarkupColorFill")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupColorFill, markId, colorFill)
    if not success then
        _HarnessInternal.log.error("Failed to set markup color fill: " .. tostring(result), "Trigger.SetMarkupColorFill")
        return nil
    end

    return true
end

--- Sets the font size of an existing map mark
---@param markId number The ID of the mark to modify
---@param fontSize number The font size in points
---@return boolean? success Returns true if successful, nil on error
---@usage SetMarkupFontSize(1001, 18)
function SetMarkupFontSize(markId, fontSize)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("SetMarkupFontSize requires valid mark ID", "Trigger.SetMarkupFontSize")
        return nil
    end

    if not fontSize or type(fontSize) ~= "number" or fontSize <= 0 then
        _HarnessInternal.log.error("SetMarkupFontSize requires valid font size", "Trigger.SetMarkupFontSize")
        return nil
    end

    local success, result = pcall(trigger.action.setMarkupFontSize, markId, fontSize)
    if not success then
        _HarnessInternal.log.error("Failed to set markup font size: " .. tostring(result), "Trigger.SetMarkupFontSize")
        return nil
    end

    return true
end

--- Removes a map mark
---@param markId number The ID of the mark to remove
---@return boolean? success Returns true if successful, nil on error
---@usage RemoveMark(1001)
function RemoveMark(markId)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("RemoveMark requires valid mark ID", "Trigger.RemoveMark")
        return nil
    end

    local success, result = pcall(trigger.action.removeMark, markId)
    if not success then
        _HarnessInternal.log.error("Failed to remove mark: " .. tostring(result), "Trigger.RemoveMark")
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
---@usage MarkToAll(1001, "Target", {x=1000, y=0, z=2000}, true)
function MarkToAll(markId, text, pos, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("MarkToAll requires valid mark ID", "Trigger.MarkToAll")
        return nil
    end

    if not text or type(text) ~= "string" then
        text = ""
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("MarkToAll requires valid position with x, y, z", "Trigger.MarkToAll")
        return nil
    end

    local success, result = pcall(trigger.action.markToAll, markId, text, pos, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create mark for all: " .. tostring(result), "Trigger.MarkToAll")
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
---@usage MarkToCoalition(1001, "Enemy Base", {x=1000, y=0, z=2000}, coalition.side.RED, true)
function MarkToCoalition(markId, text, pos, coalitionId, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("MarkToCoalition requires valid mark ID", "Trigger.MarkToCoalition")
        return nil
    end

    if not coalitionId or type(coalitionId) ~= "number" then
        _HarnessInternal.log.error("MarkToCoalition requires valid coalition ID", "Trigger.MarkToCoalition")
        return nil
    end

    if not text or type(text) ~= "string" then
        text = ""
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("MarkToCoalition requires valid position with x, y, z", "Trigger.MarkToCoalition")
        return nil
    end

    local success, result = pcall(trigger.action.markToCoalition, markId, text, pos, coalitionId, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create mark for coalition: " .. tostring(result), "Trigger.MarkToCoalition")
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
---@usage MarkToGroup(1001, "Waypoint", {x=1000, y=0, z=2000}, 501, false)
function MarkToGroup(markId, text, pos, groupId, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("MarkToGroup requires valid mark ID", "Trigger.MarkToGroup")
        return nil
    end

    if not groupId or type(groupId) ~= "number" then
        _HarnessInternal.log.error("MarkToGroup requires valid group ID", "Trigger.MarkToGroup")
        return nil
    end

    if not text or type(text) ~= "string" then
        text = ""
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("MarkToGroup requires valid position with x, y, z", "Trigger.MarkToGroup")
        return nil
    end

    local success, result = pcall(trigger.action.markToGroup, markId, text, pos, groupId, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create mark for group: " .. tostring(result), "Trigger.MarkToGroup")
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
---@usage LineToAll(1001, {x=1000, y=0, z=2000}, {x=2000, y=0, z=3000}, {r=1, g=0, b=0, a=1})
function LineToAll(markId, startPos, endPos, color, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("LineToAll requires valid mark ID", "Trigger.LineToAll")
        return nil
    end

    if not startPos or type(startPos) ~= "table" or not startPos.x or not startPos.y or not startPos.z then
        _HarnessInternal.log.error("LineToAll requires valid start position with x, y, z", "Trigger.LineToAll")
        return nil
    end

    if not endPos or type(endPos) ~= "table" or not endPos.x or not endPos.y or not endPos.z then
        _HarnessInternal.log.error("LineToAll requires valid end position with x, y, z", "Trigger.LineToAll")
        return nil
    end

    color = _normalizeColor(color)
    -- DCS expects color then fillColor then lineType
    local fillColor = _defaultFill(color)
    local success, result = pcall(trigger.action.lineToAll, markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create line for all: " .. tostring(result), "Trigger.LineToAll")
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
---@usage CircleToAll(1001, {x=1000, y=0, z=2000}, 500, {r=1, g=0, b=0, a=1}, {r=1, g=0, b=0, a=0.3})
function CircleToAll(markId, center, radius, color, fillColor, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("CircleToAll requires valid mark ID", "Trigger.CircleToAll")
        return nil
    end

    if not center or type(center) ~= "table" or not center.x or not center.y or not center.z then
        _HarnessInternal.log.error("CircleToAll requires valid center position with x, y, z", "Trigger.CircleToAll")
        return nil
    end

    if not radius or type(radius) ~= "number" or radius <= 0 then
        _HarnessInternal.log.error("CircleToAll requires valid radius", "Trigger.CircleToAll")
        return nil
    end

    color = _normalizeColor(color)
    fillColor = _defaultFill(color, fillColor)
    local success, result = pcall(trigger.action.circleToAll, markId, center, radius, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create circle for all: " .. tostring(result), "Trigger.CircleToAll")
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
---@usage RectToAll(1001, {x=1000, y=0, z=2000}, {x=2000, y=0, z=3000}, {r=0, g=1, b=0, a=1})
function RectToAll(markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("RectToAll requires valid mark ID", "Trigger.RectToAll")
        return nil
    end

    if not startPos or type(startPos) ~= "table" or not startPos.x or not startPos.y or not startPos.z then
        _HarnessInternal.log.error("RectToAll requires valid start position with x, y, z", "Trigger.RectToAll")
        return nil
    end

    if not endPos or type(endPos) ~= "table" or not endPos.x or not endPos.y or not endPos.z then
        _HarnessInternal.log.error("RectToAll requires valid end position with x, y, z", "Trigger.RectToAll")
        return nil
    end

    local success, result = pcall(trigger.action.rectToAll, markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create rectangle for all: " .. tostring(result), "Trigger.RectToAll")
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
---@usage QuadToAll(1001, {x=1000, y=0, z=2000}, {x=2000, y=0, z=2000}, {x=2000, y=0, z=3000}, {x=1000, y=0, z=3000})
function QuadToAll(markId, point1, point2, point3, point4, color, fillColor, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("QuadToAll requires valid mark ID", "Trigger.QuadToAll")
        return nil
    end

    if not point1 or type(point1) ~= "table" or not point1.x or not point1.y or not point1.z then
        _HarnessInternal.log.error("QuadToAll requires valid point1 with x, y, z", "Trigger.QuadToAll")
        return nil
    end

    if not point2 or type(point2) ~= "table" or not point2.x or not point2.y or not point2.z then
        _HarnessInternal.log.error("QuadToAll requires valid point2 with x, y, z", "Trigger.QuadToAll")
        return nil
    end

    if not point3 or type(point3) ~= "table" or not point3.x or not point3.y or not point3.z then
        _HarnessInternal.log.error("QuadToAll requires valid point3 with x, y, z", "Trigger.QuadToAll")
        return nil
    end

    if not point4 or type(point4) ~= "table" or not point4.x or not point4.y or not point4.z then
        _HarnessInternal.log.error("QuadToAll requires valid point4 with x, y, z", "Trigger.QuadToAll")
        return nil
    end

    local success, result = pcall(trigger.action.quadToAll, markId, point1, point2, point3, point4, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create quad for all: " .. tostring(result), "Trigger.QuadToAll")
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
---@usage TextToAll(1001, "Objective", {x=1000, y=0, z=2000}, {r=1, g=1, b=1, a=1}, nil, 14)
function TextToAll(markId, text, pos, color, fillColor, fontSize, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("TextToAll requires valid mark ID", "Trigger.TextToAll")
        return nil
    end

    if not text or type(text) ~= "string" then
        _HarnessInternal.log.error("TextToAll requires valid text string", "Trigger.TextToAll")
        return nil
    end

    if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
        _HarnessInternal.log.error("TextToAll requires valid position with x, y, z", "Trigger.TextToAll")
        return nil
    end

    color = _normalizeColor(color)
    fillColor = _defaultFill(color, fillColor)
    local success, result = pcall(trigger.action.textToAll, markId, text, pos, color, fillColor, fontSize, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create text for all: " .. tostring(result), "Trigger.TextToAll")
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
---@usage ArrowToAll(1001, {x=1000, y=0, z=2000}, {x=2000, y=0, z=3000}, {r=1, g=0, b=0, a=1})
function ArrowToAll(markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not markId or type(markId) ~= "number" then
        _HarnessInternal.log.error("ArrowToAll requires valid mark ID", "Trigger.ArrowToAll")
        return nil
    end

    if not startPos or type(startPos) ~= "table" or not startPos.x or not startPos.y or not startPos.z then
        _HarnessInternal.log.error("ArrowToAll requires valid start position with x, y, z", "Trigger.ArrowToAll")
        return nil
    end

    if not endPos or type(endPos) ~= "table" or not endPos.x or not endPos.y or not endPos.z then
        _HarnessInternal.log.error("ArrowToAll requires valid end position with x, y, z", "Trigger.ArrowToAll")
        return nil
    end

    local success, result = pcall(trigger.action.arrowToAll, markId, startPos, endPos, color, fillColor, lineType, readOnly, message)
    if not success then
        _HarnessInternal.log.error("Failed to create arrow for all: " .. tostring(result), "Trigger.ArrowToAll")
        return nil
    end

    return true
end

--- Sets an AI task for a group
---@param group table The group object
---@param aiTask table The AI task table
---@return boolean? success Returns true if successful, nil on error
---@usage SetAITask(group, {id="Mission", params={...}})
function SetAITask(group, aiTask)
    if not group then
        _HarnessInternal.log.error("SetAITask requires valid group", "Trigger.SetAITask")
        return nil
    end

    if not aiTask or type(aiTask) ~= "table" then
        _HarnessInternal.log.error("SetAITask requires valid AI task table", "Trigger.SetAITask")
        return nil
    end

    local success, result = pcall(trigger.action.setAITask, group, aiTask)
    if not success then
        _HarnessInternal.log.error("Failed to set AI task: " .. tostring(result), "Trigger.SetAITask")
        return nil
    end

    return true
end

--- Pushes an AI task to a group's task queue
---@param group table The group object
---@param aiTask table The AI task table
---@return boolean? success Returns true if successful, nil on error
---@usage PushAITask(group, {id="EngageTargets", params={...}})
function PushAITask(group, aiTask)
    if not group then
        _HarnessInternal.log.error("PushAITask requires valid group", "Trigger.PushAITask")
        return nil
    end

    if not aiTask or type(aiTask) ~= "table" then
        _HarnessInternal.log.error("PushAITask requires valid AI task table", "Trigger.PushAITask")
        return nil
    end

    local success, result = pcall(trigger.action.pushAITask, group, aiTask)
    if not success then
        _HarnessInternal.log.error("Failed to push AI task: " .. tostring(result), "Trigger.PushAITask")
        return nil
    end

    return true
end

--- Activates a group using trigger action
---@param group table The group object to activate
---@return boolean? success Returns true if successful, nil on error
---@usage TriggerActivateGroup(group)
function TriggerActivateGroup(group)
    if not group then
        _HarnessInternal.log.error("TriggerActivateGroup requires valid group", "Trigger.TriggerActivateGroup")
        return nil
    end

    local success, result = pcall(trigger.action.activateGroup, group)
    if not success then
        _HarnessInternal.log.error("Failed to activate group: " .. tostring(result), "Trigger.TriggerActivateGroup")
        return nil
    end

    return true
end

--- Deactivates a group using trigger action
---@param group table The group object to deactivate
---@return boolean? success Returns true if successful, nil on error
---@usage TriggerDeactivateGroup(group)
function TriggerDeactivateGroup(group)
    if not group then
        _HarnessInternal.log.error("TriggerDeactivateGroup requires valid group", "Trigger.TriggerDeactivateGroup")
        return nil
    end

    local success, result = pcall(trigger.action.deactivateGroup, group)
    if not success then
        _HarnessInternal.log.error("Failed to deactivate group: " .. tostring(result), "Trigger.TriggerDeactivateGroup")
        return nil
    end

    return true
end

--- Enables AI for a group
---@param group table The group object
---@return boolean? success Returns true if successful, nil on error
---@usage SetGroupAIOn(group)
function SetGroupAIOn(group)
    if not group then
        _HarnessInternal.log.error("SetGroupAIOn requires valid group", "Trigger.SetGroupAIOn")
        return nil
    end

    local success, result = pcall(trigger.action.setGroupAIOn, group)
    if not success then
        _HarnessInternal.log.error("Failed to set group AI on: " .. tostring(result), "Trigger.SetGroupAIOn")
        return nil
    end

    return true
end

--- Disables AI for a group
---@param group table The group object
---@return boolean? success Returns true if successful, nil on error
---@usage SetGroupAIOff(group)
function SetGroupAIOff(group)
    if not group then
        _HarnessInternal.log.error("SetGroupAIOff requires valid group", "Trigger.SetGroupAIOff")
        return nil
    end

    local success, result = pcall(trigger.action.setGroupAIOff, group)
    if not success then
        _HarnessInternal.log.error("Failed to set group AI off: " .. tostring(result), "Trigger.SetGroupAIOff")
        return nil
    end

    return true
end

--- Stops a group from moving
---@param group table The group object
---@return boolean? success Returns true if successful, nil on error
---@usage GroupStopMoving(group)
function GroupStopMoving(group)
    if not group then
        _HarnessInternal.log.error("GroupStopMoving requires valid group", "Trigger.GroupStopMoving")
        return nil
    end

    local success, result = pcall(trigger.action.groupStopMoving, group)
    if not success then
        _HarnessInternal.log.error("Failed to stop group moving: " .. tostring(result), "Trigger.GroupStopMoving")
        return nil
    end

    return true
end

--- Resumes movement for a stopped group
---@param group table The group object
---@return boolean? success Returns true if successful, nil on error
---@usage GroupContinueMoving(group)
function GroupContinueMoving(group)
    if not group then
        _HarnessInternal.log.error("GroupContinueMoving requires valid group", "Trigger.GroupContinueMoving")
        return nil
    end

    local success, result = pcall(trigger.action.groupContinueMoving, group)
    if not success then
        _HarnessInternal.log.error("Failed to continue group moving: " .. tostring(result), "Trigger.GroupContinueMoving")
        return nil
    end

    return true
end

--- Creates a shape on the F10 map visible to all players
---@param shapeId number Shape type ID (1=Line, 2=Circle, 3=Rect, 4=Arrow, 5=Text, 6=Quad, 7=Freeform)
---@param coalition number Coalition ID (-1=All, 0=Neutral, 1=Red, 2=Blue)
---@param id number Unique ID for the shape (shared with mark panels)
---@param point1 table First point with x, y, z coordinates
---@param ... any Additional parameters depending on shape type
---@return boolean? success Returns true if successful, nil on error
---@usage MarkupToAll(2, -1, 1001, {x=1000, y=0, z=2000}, 500, {1, 0, 0, 1}, {1, 0, 0, 0.3}, 1, false, "Circle Zone")
---@usage MarkupToAll(7, -1, 1002, point1, point2, point3, point4, point5, point6, {0, .6, .6, 1}, {0.8, 0.8, 0.8, .3}, 4)
function MarkupToAll(shapeId, coalition, id, point1, ...)
    -- Validate shapeId
    if not shapeId or type(shapeId) ~= "number" or shapeId < 1 or shapeId > 7 then
        _HarnessInternal.log.error("MarkupToAll requires valid shape ID (1-7)", "Trigger.MarkupToAll")
        return nil
    end

    -- Validate coalition
    if not coalition or type(coalition) ~= "number" then
        _HarnessInternal.log.error("MarkupToAll requires valid coalition ID", "Trigger.MarkupToAll")
        return nil
    end

    -- Validate id
    if not id or type(id) ~= "number" then
        _HarnessInternal.log.error("MarkupToAll requires valid unique ID", "Trigger.MarkupToAll")
        return nil
    end

    -- Validate point1
    if not point1 or type(point1) ~= "table" or not point1.x or not point1.y or not point1.z then
        _HarnessInternal.log.error("MarkupToAll requires valid first point with x, y, z", "Trigger.MarkupToAll")
        return nil
    end

    local varargs = {...}
    local params = {shapeId, coalition, id, point1}
    
    -- Add all variadic arguments to params
    for i = 1, #varargs do
        table.insert(params, varargs[i])
    end

    -- Call the DCS function with unpacked parameters
    local success, result = pcall(function()
        return trigger.action.markupToAll(unpack(params))
    end)
    
    if not success then
        _HarnessInternal.log.error("Failed to create markup shape: " .. tostring(result), "Trigger.MarkupToAll")
        return nil
    end

    return true
end