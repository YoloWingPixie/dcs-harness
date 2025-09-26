--[[
    Controller Module - DCS World Controller API Wrappers
    
    This module provides validated wrapper functions for DCS controller operations,
    including AI tasking, commands, and behavior management.
]]
require("logger")

--- Enum aliases for tooltip-friendly options
---@alias ROEAir "WEAPON_FREE"|"OPEN_FIRE_WEAPON_FREE"|"OPEN_FIRE"|"RETURN_FIRE"|"WEAPON_HOLD"
---@alias ROEGround "OPEN_FIRE"|"RETURN_FIRE"|"WEAPON_HOLD"
---@alias ROENaval "OPEN_FIRE"|"RETURN_FIRE"|"WEAPON_HOLD"
---@alias ReactionOnThreat "NO_REACTION"|"PASSIVE_DEFENCE"|"EVADE_FIRE"|"BYPASS_AND_ESCAPE"|"ALLOW_ABORT_MISSION"
---@alias MissileAttackMode "MAX_RANGE"|"NEZ_RANGE"|"HALF_WAY_RMAX_NEZ"|"TARGET_THREAT_EST"|"RANDOM_RANGE"
---@alias AlarmState "AUTO"|"GREEN"|"RED"
--- Sets a task for the controller
---@param controller table The controller object
---@param task table The task table to set
---@return boolean? success Returns true if successful, nil on error
---@usage SetControllerTask(controller, {id="Mission", params={...}})
function SetControllerTask(controller, task)
    if not controller then
        _HarnessInternal.log.error(
            "SetControllerTask requires valid controller",
            "Controller.SetTask"
        )
        return nil
    end

    if not task or type(task) ~= "table" then
        _HarnessInternal.log.error(
            "SetControllerTask requires valid task table",
            "Controller.SetTask"
        )
        return nil
    end

    local success, result = pcall(controller.setTask, controller, task)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set controller task: " .. tostring(result),
            "Controller.SetTask"
        )
        return nil
    end

    return true
end

--- Resets the controller's current task
---@param controller table The controller object
---@return boolean? success Returns true if successful, nil on error
---@usage ResetControllerTask(controller)
function ResetControllerTask(controller)
    if not controller then
        _HarnessInternal.log.error(
            "ResetControllerTask requires valid controller",
            "Controller.ResetTask"
        )
        return nil
    end

    local success, result = pcall(controller.resetTask, controller)
    if not success then
        _HarnessInternal.log.error(
            "Failed to reset controller task: " .. tostring(result),
            "Controller.ResetTask"
        )
        return nil
    end

    return true
end

--- Pushes a task onto the controller's task queue
---@param controller table The controller object
---@param task table The task table to push
---@return boolean? success Returns true if successful, nil on error
---@usage PushControllerTask(controller, {id="EngageTargets", params={...}})
function PushControllerTask(controller, task)
    if not controller then
        _HarnessInternal.log.error(
            "PushControllerTask requires valid controller",
            "Controller.PushTask"
        )
        return nil
    end

    if not task or type(task) ~= "table" then
        _HarnessInternal.log.error(
            "PushControllerTask requires valid task table",
            "Controller.PushTask"
        )
        return nil
    end

    local success, result = pcall(controller.pushTask, controller, task)
    if not success then
        _HarnessInternal.log.error(
            "Failed to push controller task: " .. tostring(result),
            "Controller.PushTask"
        )
        return nil
    end

    return true
end

--- Pops a task from the controller's task queue
---@param controller table The controller object
---@return boolean? success Returns true if successful, nil on error
---@usage PopControllerTask(controller)
function PopControllerTask(controller)
    if not controller then
        _HarnessInternal.log.error(
            "PopControllerTask requires valid controller",
            "Controller.PopTask"
        )
        return nil
    end

    local success, result = pcall(controller.popTask, controller)
    if not success then
        _HarnessInternal.log.error(
            "Failed to pop controller task: " .. tostring(result),
            "Controller.PopTask"
        )
        return nil
    end

    return true
end

--- Checks if the controller has any tasks
---@param controller table The controller object
---@return boolean? hasTask Returns true if controller has tasks, false if not, nil on error
---@usage local hasTasks = hasControllerTask(controller)
function HasControllerTask(controller)
    if not controller then
        _HarnessInternal.log.error(
            "HasControllerTask requires valid controller",
            "Controller.HasTask"
        )
        return nil
    end

    local success, result = pcall(controller.hasTask, controller)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check controller task: " .. tostring(result),
            "Controller.HasTask"
        )
        return nil
    end

    return result
end

--- Sets a command for the controller
---@param controller table The controller object
---@param command table The command table to set
---@return boolean? success Returns true if successful, nil on error
---@usage SetControllerCommand(controller, {id="Script", params={...}})
function SetControllerCommand(controller, command)
    if not controller then
        _HarnessInternal.log.error(
            "SetControllerCommand requires valid controller",
            "Controller.SetCommand"
        )
        return nil
    end

    if not command or type(command) ~= "table" then
        _HarnessInternal.log.error(
            "SetControllerCommand requires valid command table",
            "Controller.SetCommand"
        )
        return nil
    end

    local success, result = pcall(controller.setCommand, controller, command)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set controller command: " .. tostring(result),
            "Controller.SetCommand"
        )
        return nil
    end

    return true
end

--- Enables or disables the controller
---@param controller table The controller object
---@param onOff boolean True to enable, false to disable
---@return boolean? success Returns true if successful, nil on error
---@usage SetControllerOnOff(controller, false)
function SetControllerOnOff(controller, onOff)
    if not controller then
        _HarnessInternal.log.error(
            "SetControllerOnOff requires valid controller",
            "Controller.SetOnOff"
        )
        return nil
    end

    if type(onOff) ~= "boolean" then
        _HarnessInternal.log.error(
            "SetControllerOnOff requires boolean value",
            "Controller.SetOnOff"
        )
        return nil
    end

    local success, result = pcall(controller.setOnOff, controller, onOff)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set controller on/off: " .. tostring(result),
            "Controller.SetOnOff"
        )
        return nil
    end

    return true
end

--- Sets the altitude for the controller
---@param controller table The controller object
---@param altitude number The altitude in meters
---@param keep boolean? If true, keep this altitude across waypoints
---@param altType string? Altitude type: "BARO" or "RADIO"
---@return boolean? success Returns true if successful, nil on error
---@usage SetControllerAltitude(controller, 5000, true, "BARO")
function SetControllerAltitude(controller, altitude, keep, altType)
    if not controller then
        _HarnessInternal.log.error(
            "SetControllerAltitude requires valid controller",
            "Controller.SetAltitude"
        )
        return nil
    end

    if not altitude or type(altitude) ~= "number" then
        _HarnessInternal.log.error(
            "SetControllerAltitude requires valid altitude",
            "Controller.SetAltitude"
        )
        return nil
    end

    local success, result = pcall(controller.setAltitude, controller, altitude, keep, altType)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set controller altitude: " .. tostring(result),
            "Controller.SetAltitude"
        )
        return nil
    end

    return true
end

--- Sets the speed for the controller
---@param controller table The controller object
---@param speed number The speed in m/s
---@param keep boolean? If true, keep this speed across waypoints
---@return boolean? success Returns true if successful, nil on error
---@usage SetControllerSpeed(controller, 250, true)
function SetControllerSpeed(controller, speed, keep)
    if not controller then
        _HarnessInternal.log.error(
            "SetControllerSpeed requires valid controller",
            "Controller.SetSpeed"
        )
        return nil
    end

    if not speed or type(speed) ~= "number" then
        _HarnessInternal.log.error("SetControllerSpeed requires valid speed", "Controller.SetSpeed")
        return nil
    end

    local success, result = pcall(controller.setSpeed, controller, speed, keep)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set controller speed: " .. tostring(result),
            "Controller.SetSpeed"
        )
        return nil
    end

    return true
end

--- Sets an option for the controller
---@param controller table The controller object
---@param optionId number The option ID
---@param optionValue any The value to set for the option
---@return boolean? success Returns true if successful, nil on error
---@usage SetControllerOption(controller, 0, AI.Option.Air.val.ROE.WEAPON_FREE)
function SetControllerOption(controller, optionId, optionValue)
    if not controller then
        _HarnessInternal.log.error(
            "SetControllerOption requires valid controller",
            "Controller.SetOption"
        )
        return nil
    end

    if not optionId or type(optionId) ~= "number" then
        _HarnessInternal.log.error(
            "SetControllerOption requires valid option ID",
            "Controller.SetOption"
        )
        return nil
    end

    local success, result = pcall(controller.setOption, controller, optionId, optionValue)
    if not success then
        _HarnessInternal.log.error(
            "Failed to set controller option: " .. tostring(result),
            "Controller.SetOption"
        )
        return nil
    end

    return true
end

--- Convenience setters for common controller options
---@param controller table Controller object
---@param value integer|ROEAir|ROEGround|ROENaval ROE value or name
---@param domain string? Domain: "Air" (default), "Ground", or "Naval"
---@return boolean? success Returns true on success, nil on error
function ControllerSetROE(controller, value, domain)
    local d = (domain == "Ground" or domain == "Naval") and domain or "Air"
    local opt = AI and AI.Option and AI.Option[d]
    if not opt or not opt.id or not opt.id.ROE then
        _HarnessInternal.log.error(
            "AI.Option." .. d .. ".id.ROE not available",
            "Controller.SetROE"
        )
        return nil
    end
    if type(value) == "string" and opt.val and opt.val.ROE then
        local upper = string.upper(value)
        value = opt.val.ROE[upper]
    end
    if type(value) ~= "number" then
        _HarnessInternal.log.error(
            "ControllerSetROE requires numeric or valid string ROE",
            "Controller.SetROE"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.ROE, value)
end

--- Set AI reaction on threat
---@param controller table Controller object
---@param value integer|ReactionOnThreat Reaction value or name (e.g. "EVADE_FIRE")
---@return boolean? success Returns true on success, nil on error
function ControllerSetReactionOnThreat(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.REACTION_ON_THREAT then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.REACTION_ON_THREAT not available",
            "Controller.SetReactionOnThreat"
        )
        return nil
    end
    if type(value) == "string" and opt.val and opt.val.REACTION_ON_THREAT then
        local upper = string.upper(value)
        value = opt.val.REACTION_ON_THREAT[upper]
    end
    if type(value) ~= "number" then
        _HarnessInternal.log.error(
            "ControllerSetReactionOnThreat requires numeric or valid string value",
            "Controller.SetReactionOnThreat"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.REACTION_ON_THREAT, value)
end

--- Set radar usage policy
---@param controller table Controller object
---@param value number Radar usage enum (AI.Option.Air.val.RADAR_USING.*)
---@return boolean? success Returns true on success, nil on error
function ControllerSetRadarUsing(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.RADAR_USING then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.RADAR_USING not available",
            "Controller.SetRadarUsing"
        )
        return nil
    end
    if type(value) ~= "number" then
        _HarnessInternal.log.error(
            "ControllerSetRadarUsing requires numeric enum value",
            "Controller.SetRadarUsing"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.RADAR_USING, value)
end

--- Set flare usage policy
---@param controller table Controller object
---@param value number Flare usage enum (AI.Option.Air.val.FLARE_USING.*)
---@return boolean? success Returns true on success, nil on error
function ControllerSetFlareUsing(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.FLARE_USING then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.FLARE_USING not available",
            "Controller.SetFlareUsing"
        )
        return nil
    end
    if type(value) ~= "number" then
        _HarnessInternal.log.error(
            "ControllerSetFlareUsing requires numeric enum value",
            "Controller.SetFlareUsing"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.FLARE_USING, value)
end

--- Set formation
---@param controller table Controller object
---@param value number Formation enum (AI.Option.Air.val.FORMATION.*)
---@return boolean? success Returns true on success, nil on error
function ControllerSetFormation(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.FORMATION then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.FORMATION not available",
            "Controller.SetFormation"
        )
        return nil
    end
    if type(value) ~= "number" then
        _HarnessInternal.log.error(
            "ControllerSetFormation requires numeric enum value",
            "Controller.SetFormation"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.FORMATION, value)
end

--- Enable/disable RTB on bingo
---@param controller table Controller object
---@param value boolean
---@return boolean? success Returns true on success, nil on error
function ControllerSetRTBOnBingo(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.RTB_ON_BINGO then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.RTB_ON_BINGO not available",
            "Controller.SetRTBOnBingo"
        )
        return nil
    end
    if type(value) ~= "boolean" then
        _HarnessInternal.log.error(
            "ControllerSetRTBOnBingo requires boolean",
            "Controller.SetRTBOnBingo"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.RTB_ON_BINGO, value)
end

--- Enable/disable radio silence
---@param controller table Controller object
---@param value boolean
---@return boolean? success Returns true on success, nil on error
function ControllerSetSilence(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.SILENCE then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.SILENCE not available",
            "Controller.SetSilence"
        )
        return nil
    end
    if type(value) ~= "boolean" then
        _HarnessInternal.log.error("ControllerSetSilence requires boolean", "Controller.SetSilence")
        return nil
    end
    return SetControllerOption(controller, opt.id.SILENCE, value)
end

--- Set alarm state
---@param controller table Controller object
---@param value integer|AlarmState Alarm state value or name (e.g. "RED")
---@param domain string? Domain: "Air" (default) or "Ground"
---@return boolean? success Returns true on success, nil on error
function ControllerSetAlarmState(controller, value, domain)
    local d = (domain == "Air") and domain or "Ground"
    local opt = AI and AI.Option and AI.Option[d]
    if not opt or not opt.id or not opt.id.ALARM_STATE then
        _HarnessInternal.log.error(
            "AI.Option." .. d .. ".id.ALARM_STATE not available",
            "Controller.SetAlarmState"
        )
        return nil
    end
    if type(value) == "string" and opt.val and opt.val.ALARM_STATE then
        local upper = string.upper(value)
        value = opt.val.ALARM_STATE[upper]
    end
    if type(value) ~= "number" then
        _HarnessInternal.log.error(
            "ControllerSetAlarmState requires numeric or valid string value",
            "Controller.SetAlarmState"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.ALARM_STATE, value)
end

--- Enable/disable ground disperse on attack
---@param controller table Controller object
---@param seconds number Dispersal time in seconds (0 disables)
---@return boolean? success Returns true on success, nil on error
---@usage ControllerSetDisperseOnAttack(controller, 120)
function ControllerSetDisperseOnAttack(controller, seconds)
    local opt = AI and AI.Option and AI.Option.Ground
    if not opt or not opt.id or not opt.id.DISPERSE_ON_ATTACK then
        _HarnessInternal.log.error(
            "AI.Option.Ground.id.DISPERSE_ON_ATTACK not available",
            "Controller.SetDisperseOnAttack"
        )
        return nil
    end
    if type(seconds) ~= "number" or seconds < 0 then
        _HarnessInternal.log.error(
            "ControllerSetDisperseOnAttack requires non-negative number of seconds",
            "Controller.SetDisperseOnAttack"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.DISPERSE_ON_ATTACK, seconds)
end

--- Enable/disable RTB on out of ammo
---@param controller table Controller object
---@param value boolean
---@return boolean? success Returns true on success, nil on error
function ControllerSetRTBOnOutOfAmmo(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.RTB_ON_OUT_OF_AMMO then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.RTB_ON_OUT_OF_AMMO not available",
            "Controller.SetRTBOnOutOfAmmo"
        )
        return nil
    end
    if type(value) ~= "boolean" then
        _HarnessInternal.log.error(
            "ControllerSetRTBOnOutOfAmmo requires boolean",
            "Controller.SetRTBOnOutOfAmmo"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.RTB_ON_OUT_OF_AMMO, value)
end

--- Set ECM usage policy
---@param controller table Controller object
---@param value number ECM usage enum (AI.Option.Air.val.ECM_USING.*)
---@return boolean? success Returns true on success, nil on error
function ControllerSetECMUsing(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.ECM_USING then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.ECM_USING not available",
            "Controller.SetECMUsing"
        )
        return nil
    end
    if type(value) ~= "number" then
        _HarnessInternal.log.error(
            "ControllerSetECMUsing requires numeric enum value",
            "Controller.SetECMUsing"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.ECM_USING, value)
end

--- Enable/disable waypoint pass report (ID 14)
---@param controller table Controller object
---@param value boolean
---@return boolean? success Returns true on success, nil on error
function ControllerSetProhibitWPPassReport(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.PROHIBIT_WP_PASS_REPORT then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT not available",
            "Controller.SetProhibitWPPassReport"
        )
        return nil
    end
    if type(value) ~= "boolean" then
        _HarnessInternal.log.error(
            "ControllerSetProhibitWPPassReport requires boolean",
            "Controller.SetProhibitWPPassReport"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.PROHIBIT_WP_PASS_REPORT, value)
end

--- Enable/disable prohibit air-to-air
---@param controller table Controller object
---@param value boolean
---@return boolean? success Returns true on success, nil on error
function ControllerSetProhibitAA(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.PROHIBIT_AA then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.PROHIBIT_AA not available",
            "Controller.SetProhibitAA"
        )
        return nil
    end
    if type(value) ~= "boolean" then
        _HarnessInternal.log.error(
            "ControllerSetProhibitAA requires boolean",
            "Controller.SetProhibitAA"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.PROHIBIT_AA, value)
end

--- Enable/disable prohibit jettison
---@param controller table Controller object
---@param value boolean
---@return boolean? success Returns true on success, nil on error
function ControllerSetProhibitJettison(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.PROHIBIT_JETT then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.PROHIBIT_JETT not available",
            "Controller.SetProhibitJettison"
        )
        return nil
    end
    if type(value) ~= "boolean" then
        _HarnessInternal.log.error(
            "ControllerSetProhibitJettison requires boolean",
            "Controller.SetProhibitJettison"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.PROHIBIT_JETT, value)
end

--- Enable/disable prohibit afterburner
---@param controller table Controller object
---@param value boolean
---@return boolean? success Returns true on success, nil on error
function ControllerSetProhibitAB(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.PROHIBIT_AB then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.PROHIBIT_AB not available",
            "Controller.SetProhibitAB"
        )
        return nil
    end
    if type(value) ~= "boolean" then
        _HarnessInternal.log.error(
            "ControllerSetProhibitAB requires boolean",
            "Controller.SetProhibitAB"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.PROHIBIT_AB, value)
end

--- Enable/disable prohibit air-to-ground
---@param controller table Controller object
---@param value boolean
---@return boolean? success Returns true on success, nil on error
function ControllerSetProhibitAG(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.PROHIBIT_AG then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.PROHIBIT_AG not available",
            "Controller.SetProhibitAG"
        )
        return nil
    end
    if type(value) ~= "boolean" then
        _HarnessInternal.log.error(
            "ControllerSetProhibitAG requires boolean",
            "Controller.SetProhibitAG"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.PROHIBIT_AG, value)
end

--- Set missile attack policy
---@param controller table Controller object
---@param value integer|MissileAttackMode Missile attack enum or name
---@return boolean? success Returns true on success, nil on error
---@usage ControllerSetMissileAttack(controller, "NEZ_RANGE")
function ControllerSetMissileAttack(controller, value)
    local opt = AI and AI.Option and AI.Option.Air
    if not opt or not opt.id or not opt.id.MISSILE_ATTACK then
        _HarnessInternal.log.error(
            "AI.Option.Air.id.MISSILE_ATTACK not available",
            "Controller.SetMissileAttack"
        )
        return nil
    end
    if type(value) == "string" and opt.val and opt.val.MISSILE_ATTACK then
        local upper = string.upper(value)
        value = opt.val.MISSILE_ATTACK[upper]
    end
    if type(value) ~= "number" then
        _HarnessInternal.log.error(
            "ControllerSetMissileAttack requires numeric or valid string enum value",
            "Controller.SetMissileAttack"
        )
        return nil
    end
    return SetControllerOption(controller, opt.id.MISSILE_ATTACK, value)
end

-- Removed unsupported options in current DCS builds: PROHIBIT_WP_PASS_REPORT2, DISPERSAL_ON_ATTACK

--- Gets targets detected by the controller
---@param controller table The controller object
---@param detectionType any? Optional detection type filter
---@param categoryFilter any? Optional category filter
---@return table? targets Array of detected target objects or nil on error
---@usage local targets = getControllerDetectedTargets(controller)
function GetControllerDetectedTargets(controller, detectionType, categoryFilter)
    if not controller then
        _HarnessInternal.log.error(
            "GetControllerDetectedTargets requires valid controller",
            "Controller.GetDetectedTargets"
        )
        return nil
    end

    local success, result =
        pcall(controller.getDetectedTargets, controller, detectionType, categoryFilter)
    if not success then
        _HarnessInternal.log.error(
            "Failed to get detected targets: " .. tostring(result),
            "Controller.GetDetectedTargets"
        )
        return nil
    end

    return result
end

--- Makes the controller aware of a target
---@param controller table The controller object
---@param target table The target object
---@param typeKnown boolean? Whether the target type is known
---@param distanceKnown boolean? Whether the target distance is known
---@return boolean? success Returns true if successful, nil on error
---@usage KnowControllerTarget(controller, targetUnit, true, true)
function KnowControllerTarget(controller, target, typeKnown, distanceKnown)
    if not controller then
        _HarnessInternal.log.error(
            "KnowControllerTarget requires valid controller",
            "Controller.KnowTarget"
        )
        return nil
    end

    if not target then
        _HarnessInternal.log.error(
            "KnowControllerTarget requires valid target",
            "Controller.KnowTarget"
        )
        return nil
    end

    local success, result =
        pcall(controller.knowTarget, controller, target, typeKnown, distanceKnown)
    if not success then
        _HarnessInternal.log.error(
            "Failed to know target: " .. tostring(result),
            "Controller.KnowTarget"
        )
        return nil
    end

    return true
end

--- Checks if a target is detected by the controller
---@param controller table The controller object
---@param target table The target object to check
---@param detectionType any? Optional detection type
---@return boolean? isDetected Returns detection status or nil on error
---@usage local detected = isControllerTargetDetected(controller, targetUnit)
function IsControllerTargetDetected(controller, target, detectionType)
    if not controller then
        _HarnessInternal.log.error(
            "IsControllerTargetDetected requires valid controller",
            "Controller.IsTargetDetected"
        )
        return nil
    end

    if not target then
        _HarnessInternal.log.error(
            "IsControllerTargetDetected requires valid target",
            "Controller.IsTargetDetected"
        )
        return nil
    end

    local success, result = pcall(controller.isTargetDetected, controller, target, detectionType)
    if not success then
        _HarnessInternal.log.error(
            "Failed to check target detection: " .. tostring(result),
            "Controller.IsTargetDetected"
        )
        return nil
    end

    return result
end

--- Creates an orbit task for aircraft
---@param pattern string? Orbit pattern (default: "Circle")
---@param point table Position to orbit around
---@param altitude number Orbit altitude in meters
---@param speed number Orbit speed in m/s
---@param taskParams table? Additional task parameters
---@return table task The orbit task table
---@usage local task = createOrbitTask("Circle", {x=1000, y=0, z=2000}, 5000, 250)
function CreateOrbitTask(pattern, point, altitude, speed, taskParams)
    local task = {
        id = "Orbit",
        params = {
            pattern = pattern or "Circle",
            point = point,
            altitude = altitude,
            speed = speed,
        },
    }

    if taskParams then
        for k, v in pairs(taskParams) do
            task.params[k] = v
        end
    end

    return task
end

--- Creates a follow task to follow another group
---@param groupId number The ID of the group to follow
---@param position table? Relative position offset (default: {x=50, y=0, z=50})
---@param lastWaypointIndex number? Last waypoint index to follow to
---@return table? task The follow task table or nil on error
---@usage local task = createFollowTask(1001, {x=100, y=0, z=100})
function CreateFollowTask(groupId, position, lastWaypointIndex)
    if not groupId then
        _HarnessInternal.log.error(
            "CreateFollowTask requires valid group ID",
            "Controller.CreateFollowTask"
        )
        return nil
    end

    local task = {
        id = "follow",
        params = {
            groupId = groupId,
            pos = position or { x = 50, y = 0, z = 50 },
            lastWptIndexFlag = lastWaypointIndex ~= nil,
            lastWptIndex = lastWaypointIndex,
        },
    }

    return task
end

--- Creates an escort task to escort another group
---@param groupId number The ID of the group to escort
---@param position table? Relative position offset (default: {x=50, y=0, z=50})
---@param lastWaypointIndex number? Last waypoint index to escort to
---@param engagementDistance number? Maximum engagement distance (default: 60000)
---@return table? task The escort task table or nil on error
---@usage local task = createEscortTask(1001, {x=200, y=0, z=0}, nil, 30000)
function CreateEscortTask(groupId, position, lastWaypointIndex, engagementDistance)
    if not groupId then
        _HarnessInternal.log.error(
            "CreateEscortTask requires valid group ID",
            "Controller.CreateEscortTask"
        )
        return nil
    end

    local task = {
        id = "escort",
        params = {
            groupId = groupId,
            pos = position or { x = 50, y = 0, z = 50 },
            lastWptIndexFlag = lastWaypointIndex ~= nil,
            lastWptIndex = lastWaypointIndex,
            engagementDistMax = engagementDistance or 60000,
        },
    }

    return task
end

--- Creates an attack group task
---@param groupId number The ID of the group to attack
---@param weaponType any? Weapon type to use
---@param groupAttack boolean? Whether to attack as a group (default: true)
---@param altitude number? Attack altitude
---@param attackQty number? Number of attacks
---@param direction number? Attack direction
---@return table? task The attack group task table or nil on error
---@usage local task = createAttackGroupTask(2001, nil, true)
function CreateAttackGroupTask(groupId, weaponType, groupAttack, altitude, attackQty, direction)
    if not groupId then
        _HarnessInternal.log.error(
            "CreateAttackGroupTask requires valid group ID",
            "Controller.CreateAttackGroupTask"
        )
        return nil
    end

    local task = {
        id = "AttackGroup",
        params = {
            groupId = groupId,
            weaponType = weaponType,
            groupAttack = (groupAttack == nil) and true or groupAttack,
            altitude = altitude,
            attackQty = attackQty,
            direction = direction,
        },
    }

    return task
end

--- Creates an attack unit task
---@param unitId number The ID of the unit to attack
---@param weaponType any? Weapon type to use
---@param groupAttack boolean? Whether to attack as a group (default: false)
---@param altitude number? Attack altitude
---@param attackQty number? Number of attacks
---@param direction number? Attack direction
---@return table? task The attack unit task table or nil on error
---@usage local task = createAttackUnitTask(3001)
function CreateAttackUnitTask(unitId, weaponType, groupAttack, altitude, attackQty, direction)
    if not unitId then
        _HarnessInternal.log.error(
            "CreateAttackUnitTask requires valid unit ID",
            "Controller.CreateAttackUnitTask"
        )
        return nil
    end

    local task = {
        id = "AttackUnit",
        params = {
            unitId = unitId,
            weaponType = weaponType,
            groupAttack = groupAttack or false,
            altitude = altitude,
            attackQty = attackQty,
            direction = direction,
        },
    }

    return task
end

--- Creates a bombing task for a specific point
---@param point table Target position with x, y, z coordinates
---@param weaponType any? Weapon type to use
---@param groupAttack boolean? Whether to attack as a group (default: false)
---@param altitude number? Attack altitude
---@param attackQty number? Number of attacks
---@param direction number? Attack direction
---@return table? task The bombing task table or nil on error
---@usage local task = createBombingTask({x=1000, y=0, z=2000})
function CreateBombingTask(point, weaponType, groupAttack, altitude, attackQty, direction)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error(
            "CreateBombingTask requires valid point with x, y, z",
            "Controller.CreateBombingTask"
        )
        return nil
    end

    local task = {
        id = "Bombing",
        params = {
            point = point,
            weaponType = weaponType,
            groupAttack = groupAttack or false,
            altitude = altitude,
            attackQty = attackQty,
            direction = direction,
        },
    }

    return task
end

--- Creates a bombing runway task
---@param runwayId number The runway ID to attack
---@param weaponType any? Weapon type to use
---@param groupAttack boolean? Whether to attack as a group (default: false)
---@param altitude number? Attack altitude
---@param attackQty number? Number of attacks
---@param direction number? Attack direction
---@return table? task The bombing runway task table or nil on error
---@usage local task = createBombingRunwayTask(1)
function CreateBombingRunwayTask(runwayId, weaponType, groupAttack, altitude, attackQty, direction)
    if not runwayId then
        _HarnessInternal.log.error(
            "CreateBombingRunwayTask requires valid runway ID",
            "Controller.CreateBombingRunwayTask"
        )
        return nil
    end

    local task = {
        id = "BombingRunway",
        params = {
            runwayId = runwayId,
            weaponType = weaponType,
            groupAttack = groupAttack or false,
            altitude = altitude,
            attackQty = attackQty,
            direction = direction,
        },
    }

    return task
end

--- Creates a land task at a specific point
---@param point table Landing position with x, y, z coordinates
---@param durationFlag boolean? Whether to use duration (default: false)
---@param duration number? Duration of landing in seconds
---@return table? task The land task table or nil on error
---@usage local task = createLandTask({x=1000, y=0, z=2000}, true, 300)
function CreateLandTask(point, durationFlag, duration)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error(
            "createLandTask requires valid point with x, y, z",
            "Controller.CreateLandTask"
        )
        return nil
    end

    local task = {
        id = "land",
        params = {
            point = point,
            durationFlag = durationFlag or false,
            duration = duration,
        },
    }

    return task
end

--- Creates a refueling task
---@return table task The refueling task table
---@usage local task = createRefuelingTask()
function CreateRefuelingTask()
    local task = {
        id = "refueling",
        params = {},
    }

    return task
end

--- Creates a Forward Air Controller (FAC) attack group task
---@param groupId number The ID of the group to designate for attack
---@param priority number? Task priority
---@param designation any? Designation type
---@param datalink boolean? Whether to use datalink
---@param frequency number? Radio frequency
---@param modulation number? Radio modulation
---@param callsign number? Callsign number
---@return table? task The FAC attack group task table or nil on error
---@usage local task = createFACAttackGroupTask(2001)
function CreateFACAttackGroupTask(
    groupId,
    priority,
    designation,
    datalink,
    frequency,
    modulation,
    callsign
)
    if not groupId then
        _HarnessInternal.log.error(
            "createFACAttackGroupTask requires valid group ID",
            "Controller.CreateFACAttackGroupTask"
        )
        return nil
    end

    local task = {
        id = "FAC_AttackGroup",
        params = {
            groupId = groupId,
            priority = priority,
            designation = designation,
            datalink = datalink,
            frequency = frequency,
            modulation = modulation,
            callsign = callsign,
        },
    }

    return task
end

--- Creates a fire at point task for artillery or naval units
---@param point table Target position with x, y, z coordinates
---@param radius number? Radius of fire area (default: 50)
---@param expendQty number? Quantity to expend
---@param expendQtyEnabled boolean? Whether to limit quantity (default: false)
---@param altitude number? Altitude for indirect fire
---@param altitudeEnabled boolean? Whether to use altitude
---@return table? task The fire at point task table or nil on error
---@usage local task = createFireAtPointTask({x=1000, y=0, z=2000}, 100)
function CreateFireAtPointTask(
    point,
    radius,
    expendQty,
    expendQtyEnabled,
    altitude,
    altitudeEnabled
)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error(
            "createFireAtPointTask requires valid point with x, y, z",
            "Controller.CreateFireAtPointTask"
        )
        return nil
    end

    local task = {
        id = "fireAtPoint",
        params = {
            point = point,
            radius = radius or 50,
            expendQty = expendQty,
            expendQtyEnabled = expendQtyEnabled or false,
            altitude = altitude,
            alt_type = altitudeEnabled and 1 or 0,
        },
    }

    return task
end

--- Creates a hold task
---@param template any? Template for holding pattern
---@return table task The hold task table
---@usage local task = createHoldTask()
function CreateHoldTask(template)
    local task = {
        id = "Hold",
        params = {
            templateFlag = template ~= nil,
            template = template,
        },
    }

    return task
end

--- Creates a go to waypoint task
---@param fromWaypointIndex number Starting waypoint index
---@param toWaypointIndex number Destination waypoint index
---@return table task The go to waypoint task table
---@usage local task = createGoToWaypointTask(1, 5)
function CreateGoToWaypointTask(fromWaypointIndex, toWaypointIndex)
    local task = {
        id = "goToWaypoint",
        params = {
            fromWaypointIndex = fromWaypointIndex,
            goToWaypointIndex = toWaypointIndex,
        },
    }

    return task
end

--- Creates a wrapped action task
---@param action table The action table to wrap
---@param stopFlag boolean? Whether to stop after action (default: false)
---@return table? task The wrapped action task table or nil on error
---@usage local task = createWrappedAction({id="Script", params={...}})
function CreateWrappedAction(action, stopFlag)
    if not action or type(action) ~= "table" then
        _HarnessInternal.log.error(
            "createWrappedAction requires valid action table",
            "Controller.CreateWrappedAction"
        )
        return nil
    end

    local task = {
        id = "WrappedAction",
        params = {
            action = action,
            stopFlag = stopFlag or false,
        },
    }

    return task
end

--- Creates a Rules of Engagement (ROE) option
---@param value number The ROE value
---@return table option The ROE option table
---@usage local option = createROEOption(2) -- WEAPON_FREE
-- Deprecated: use ControllerSetROE
function CreateROEOption(value)
    return {
        id = (AI and AI.Option and AI.Option.Air and AI.Option.Air.id and AI.Option.Air.id.ROE)
            or 0,
        value = value,
    }
end

--- Creates a reaction on threat option
---@param value number The reaction value
---@return table option The reaction option table
---@usage local option = createReactionOnThreatOption(1)
-- Deprecated: use ControllerSetReactionOnThreat
function CreateReactionOnThreatOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.REACTION_ON_THREAT
        ) or 1,
        value = value,
    }
end

--- Creates a radar using option
---@param value number The radar usage value
---@return table option The radar option table
---@usage local option = createRadarUsingOption(1)
-- Deprecated: use ControllerSetRadarUsing
function CreateRadarUsingOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.RADAR_USING
        ) or 3,
        value = value,
    }
end

--- Creates a flare using option
---@param value number The flare usage value
---@return table option The flare option table
---@usage local option = createFlareUsingOption(1)
-- Deprecated: use ControllerSetFlareUsing
function CreateFlareUsingOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.FLARE_USING
        ) or 4,
        value = value,
    }
end

--- Creates a formation option
---@param value number The formation value
---@return table option The formation option table
---@usage local option = createFormationOption(1)
-- Deprecated: use ControllerSetFormation
function CreateFormationOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.FORMATION
        ) or 5,
        value = value,
    }
end

--- Creates a Return To Base on bingo fuel option
---@param value boolean The RTB on bingo value
---@return table option The RTB option table
---@usage local option = createRTBOnBingoOption(true)
-- Deprecated: use ControllerSetRTBOnBingo
function CreateRTBOnBingoOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.RTB_ON_BINGO
        ) or 6,
        value = value,
    }
end

--- Creates a radio silence option
---@param value boolean The silence value
---@return table option The silence option table
---@usage local option = createSilenceOption(true)
-- Deprecated: use ControllerSetSilence
function CreateSilenceOption(value)
    return {
        id = (AI and AI.Option and AI.Option.Air and AI.Option.Air.id and AI.Option.Air.id.SILENCE)
            or 7,
        value = value,
    }
end

--- Creates an alarm state option
---@param value number The alarm state value
---@return table option The alarm state option table
---@usage local option = createAlarmStateOption(2)
-- Deprecated: use ControllerSetAlarmState
function CreateAlarmStateOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Ground
            and AI.Option.Ground.id
            and AI.Option.Ground.id.ALARM_STATE
        ) or 9,
        value = value,
    }
end

--- Creates a Return To Base on out of ammo option
---@param value boolean The RTB on out of ammo value
---@return table option The RTB option table
---@usage local option = createRTBOnOutOfAmmoOption(true)
-- Deprecated: use ControllerSetRTBOnOutOfAmmo
function CreateRTBOnOutOfAmmoOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.RTB_ON_OUT_OF_AMMO
        ) or 10,
        value = value,
    }
end

--- Creates an ECM using option
---@param value number The ECM usage value
---@return table option The ECM option table
---@usage local option = createECMUsingOption(1)
-- Deprecated: use ControllerSetECMUsing
function CreateECMUsingOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.ECM_USING
        ) or 13,
        value = value,
    }
end

--- Creates a prohibit waypoint pass report option (ID 19)
---@param value boolean The prohibit value
---@return table option The prohibit option table
---@usage local option = createProhibitWPPassReportOption(true)
-- Deprecated: use ControllerSetProhibitWPPassReport
function CreateProhibitWPPassReportOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT
        ) or 19,
        value = value,
    }
end

--- Creates a prohibit air-to-air option
---@param value boolean The prohibit value
---@return table option The prohibit AA option table
---@usage local option = createProhibitAAOption(false)
-- Deprecated: use ControllerSetProhibitAA
function CreateProhibitAAOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.PROHIBIT_AA
        ) or 14,
        value = value,
    }
end

--- Creates a prohibit jettison option
---@param value boolean The prohibit value
---@return table option The prohibit jettison option table
---@usage local option = createProhibitJettisonOption(true)
-- Deprecated: use ControllerSetProhibitJettison
function CreateProhibitJettisonOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.PROHIBIT_JETT
        ) or 15,
        value = value,
    }
end

--- Creates a prohibit afterburner option
---@param value boolean The prohibit value
---@return table option The prohibit AB option table
---@usage local option = createProhibitABOption(true)
-- Deprecated: use ControllerSetProhibitAB
function CreateProhibitABOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.PROHIBIT_AB
        ) or 16,
        value = value,
    }
end

--- Creates a prohibit air-to-ground option
---@param value boolean The prohibit value
---@return table option The prohibit AG option table
---@usage local option = createProhibitAGOption(false)
-- Deprecated: use ControllerSetProhibitAG
function CreateProhibitAGOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.PROHIBIT_AG
        ) or 17,
        value = value,
    }
end

--- Creates a missile attack option
---@param value number The missile attack value
---@return table option The missile attack option table
---@usage local option = createMissileAttackOption(1)
-- Deprecated: use ControllerSetMissileAttack
function CreateMissileAttackOption(value)
    return {
        id = (
            AI
            and AI.Option
            and AI.Option.Air
            and AI.Option.Air.id
            and AI.Option.Air.id.MISSILE_ATTACK
        ) or 18,
        value = value,
    }
end
