--[[
    Controller Module - DCS World Controller API Wrappers
    
    This module provides validated wrapper functions for DCS controller operations,
    including AI tasking, commands, and behavior management.
]]

--- Sets a task for the controller
---@param controller table The controller object
---@param task table The task table to set
---@return boolean? success Returns true if successful, nil on error
---@usage setControllerTask(controller, {id="Mission", params={...}})
function setControllerTask(controller, task)
    if not controller then
        _HarnessInternal.log.error("setControllerTask requires valid controller", "Controller.setTask")
        return nil
    end

    if not task or type(task) ~= "table" then
        _HarnessInternal.log.error("setControllerTask requires valid task table", "Controller.setTask")
        return nil
    end

    local success, result = pcall(controller.setTask, controller, task)
    if not success then
        _HarnessInternal.log.error("Failed to set controller task: " .. tostring(result), "Controller.setTask")
        return nil
    end

    return true
end

--- Resets the controller's current task
---@param controller table The controller object
---@return boolean? success Returns true if successful, nil on error
---@usage resetControllerTask(controller)
function resetControllerTask(controller)
    if not controller then
        _HarnessInternal.log.error("resetControllerTask requires valid controller", "Controller.resetTask")
        return nil
    end

    local success, result = pcall(controller.resetTask, controller)
    if not success then
        _HarnessInternal.log.error("Failed to reset controller task: " .. tostring(result), "Controller.resetTask")
        return nil
    end

    return true
end

--- Pushes a task onto the controller's task queue
---@param controller table The controller object
---@param task table The task table to push
---@return boolean? success Returns true if successful, nil on error
---@usage pushControllerTask(controller, {id="EngageTargets", params={...}})
function pushControllerTask(controller, task)
    if not controller then
        _HarnessInternal.log.error("pushControllerTask requires valid controller", "Controller.pushTask")
        return nil
    end

    if not task or type(task) ~= "table" then
        _HarnessInternal.log.error("pushControllerTask requires valid task table", "Controller.pushTask")
        return nil
    end

    local success, result = pcall(controller.pushTask, controller, task)
    if not success then
        _HarnessInternal.log.error("Failed to push controller task: " .. tostring(result), "Controller.pushTask")
        return nil
    end

    return true
end

--- Pops a task from the controller's task queue
---@param controller table The controller object
---@return boolean? success Returns true if successful, nil on error
---@usage popControllerTask(controller)
function popControllerTask(controller)
    if not controller then
        _HarnessInternal.log.error("popControllerTask requires valid controller", "Controller.popTask")
        return nil
    end

    local success, result = pcall(controller.popTask, controller)
    if not success then
        _HarnessInternal.log.error("Failed to pop controller task: " .. tostring(result), "Controller.popTask")
        return nil
    end

    return true
end

--- Checks if the controller has any tasks
---@param controller table The controller object
---@return boolean? hasTask Returns true if controller has tasks, false if not, nil on error
---@usage local hasTasks = hasControllerTask(controller)
function hasControllerTask(controller)
    if not controller then
        _HarnessInternal.log.error("hasControllerTask requires valid controller", "Controller.hasTask")
        return nil
    end

    local success, result = pcall(controller.hasTask, controller)
    if not success then
        _HarnessInternal.log.error("Failed to check controller task: " .. tostring(result), "Controller.hasTask")
        return nil
    end

    return result
end

--- Sets a command for the controller
---@param controller table The controller object
---@param command table The command table to set
---@return boolean? success Returns true if successful, nil on error
---@usage setControllerCommand(controller, {id="Script", params={...}})
function setControllerCommand(controller, command)
    if not controller then
        _HarnessInternal.log.error("setControllerCommand requires valid controller", "Controller.setCommand")
        return nil
    end

    if not command or type(command) ~= "table" then
        _HarnessInternal.log.error("setControllerCommand requires valid command table", "Controller.setCommand")
        return nil
    end

    local success, result = pcall(controller.setCommand, controller, command)
    if not success then
        _HarnessInternal.log.error("Failed to set controller command: " .. tostring(result), "Controller.setCommand")
        return nil
    end

    return true
end

--- Enables or disables the controller
---@param controller table The controller object
---@param onOff boolean True to enable, false to disable
---@return boolean? success Returns true if successful, nil on error
---@usage setControllerOnOff(controller, false)
function setControllerOnOff(controller, onOff)
    if not controller then
        _HarnessInternal.log.error("setControllerOnOff requires valid controller", "Controller.setOnOff")
        return nil
    end

    if type(onOff) ~= "boolean" then
        _HarnessInternal.log.error("setControllerOnOff requires boolean value", "Controller.setOnOff")
        return nil
    end

    local success, result = pcall(controller.setOnOff, controller, onOff)
    if not success then
        _HarnessInternal.log.error("Failed to set controller on/off: " .. tostring(result), "Controller.setOnOff")
        return nil
    end

    return true
end

--- Sets the altitude for the controller
---@param controller table The controller object
---@param altitude number The altitude in meters
---@param altitudeType any? Optional altitude type parameter
---@return boolean? success Returns true if successful, nil on error
---@usage setControllerAltitude(controller, 5000)
function setControllerAltitude(controller, altitude, altitudeType)
    if not controller then
        _HarnessInternal.log.error("setControllerAltitude requires valid controller", "Controller.setAltitude")
        return nil
    end

    if not altitude or type(altitude) ~= "number" then
        _HarnessInternal.log.error("setControllerAltitude requires valid altitude", "Controller.setAltitude")
        return nil
    end

    local success, result = pcall(controller.setAltitude, controller, altitude, altitudeType)
    if not success then
        _HarnessInternal.log.error("Failed to set controller altitude: " .. tostring(result), "Controller.setAltitude")
        return nil
    end

    return true
end

--- Sets the speed for the controller
---@param controller table The controller object
---@param speed number The speed in m/s
---@param speedType any? Optional speed type parameter
---@return boolean? success Returns true if successful, nil on error
---@usage setControllerSpeed(controller, 250)
function setControllerSpeed(controller, speed, speedType)
    if not controller then
        _HarnessInternal.log.error("setControllerSpeed requires valid controller", "Controller.setSpeed")
        return nil
    end

    if not speed or type(speed) ~= "number" then
        _HarnessInternal.log.error("setControllerSpeed requires valid speed", "Controller.setSpeed")
        return nil
    end

    local success, result = pcall(controller.setSpeed, controller, speed, speedType)
    if not success then
        _HarnessInternal.log.error("Failed to set controller speed: " .. tostring(result), "Controller.setSpeed")
        return nil
    end

    return true
end

--- Sets an option for the controller
---@param controller table The controller object
---@param optionId number The option ID
---@param optionValue any The value to set for the option
---@return boolean? success Returns true if successful, nil on error
---@usage setControllerOption(controller, 0, AI.Option.Air.val.ROE.WEAPON_FREE)
function setControllerOption(controller, optionId, optionValue)
    if not controller then
        _HarnessInternal.log.error("setControllerOption requires valid controller", "Controller.setOption")
        return nil
    end

    if not optionId or type(optionId) ~= "number" then
        _HarnessInternal.log.error("setControllerOption requires valid option ID", "Controller.setOption")
        return nil
    end

    local success, result = pcall(controller.setOption, controller, optionId, optionValue)
    if not success then
        _HarnessInternal.log.error("Failed to set controller option: " .. tostring(result), "Controller.setOption")
        return nil
    end

    return true
end

--- Gets targets detected by the controller
---@param controller table The controller object
---@param detectionType any? Optional detection type filter
---@param categoryFilter any? Optional category filter
---@return table? targets Array of detected target objects or nil on error
---@usage local targets = getControllerDetectedTargets(controller)
function getControllerDetectedTargets(controller, detectionType, categoryFilter)
    if not controller then
        _HarnessInternal.log.error("getControllerDetectedTargets requires valid controller", "Controller.getDetectedTargets")
        return nil
    end

    local success, result = pcall(controller.getDetectedTargets, controller, detectionType, categoryFilter)
    if not success then
        _HarnessInternal.log.error("Failed to get detected targets: " .. tostring(result), "Controller.getDetectedTargets")
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
---@usage knowControllerTarget(controller, targetUnit, true, true)
function knowControllerTarget(controller, target, typeKnown, distanceKnown)
    if not controller then
        _HarnessInternal.log.error("knowControllerTarget requires valid controller", "Controller.knowTarget")
        return nil
    end

    if not target then
        _HarnessInternal.log.error("knowControllerTarget requires valid target", "Controller.knowTarget")
        return nil
    end

    local success, result = pcall(controller.knowTarget, controller, target, typeKnown, distanceKnown)
    if not success then
        _HarnessInternal.log.error("Failed to know target: " .. tostring(result), "Controller.knowTarget")
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
function isControllerTargetDetected(controller, target, detectionType)
    if not controller then
        _HarnessInternal.log.error("isControllerTargetDetected requires valid controller", "Controller.isTargetDetected")
        return nil
    end

    if not target then
        _HarnessInternal.log.error("isControllerTargetDetected requires valid target", "Controller.isTargetDetected")
        return nil
    end

    local success, result = pcall(controller.isTargetDetected, controller, target, detectionType)
    if not success then
        _HarnessInternal.log.error("Failed to check target detection: " .. tostring(result), "Controller.isTargetDetected")
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
function createOrbitTask(pattern, point, altitude, speed, taskParams)
    local task = {
        id = "Orbit",
        params = {
            pattern = pattern or "Circle",
            point = point,
            altitude = altitude,
            speed = speed
        }
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
function createFollowTask(groupId, position, lastWaypointIndex)
    if not groupId then
        _HarnessInternal.log.error("createFollowTask requires valid group ID", "Controller.createFollowTask")
        return nil
    end

    local task = {
        id = "Follow",
        params = {
            groupId = groupId,
            pos = position or {x = 50, y = 0, z = 50},
            lastWptIndexFlag = lastWaypointIndex ~= nil,
            lastWptIndex = lastWaypointIndex
        }
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
function createEscortTask(groupId, position, lastWaypointIndex, engagementDistance)
    if not groupId then
        _HarnessInternal.log.error("createEscortTask requires valid group ID", "Controller.createEscortTask")
        return nil
    end

    local task = {
        id = "Escort",
        params = {
            groupId = groupId,
            pos = position or {x = 50, y = 0, z = 50},
            lastWptIndexFlag = lastWaypointIndex ~= nil,
            lastWptIndex = lastWaypointIndex,
            engagementDistMax = engagementDistance or 60000
        }
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
function createAttackGroupTask(groupId, weaponType, groupAttack, altitude, attackQty, direction)
    if not groupId then
        _HarnessInternal.log.error("createAttackGroupTask requires valid group ID", "Controller.createAttackGroupTask")
        return nil
    end

    local task = {
        id = "AttackGroup",
        params = {
            groupId = groupId,
            weaponType = weaponType,
            groupAttack = groupAttack or true,
            altitude = altitude,
            attackQty = attackQty,
            direction = direction
        }
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
function createAttackUnitTask(unitId, weaponType, groupAttack, altitude, attackQty, direction)
    if not unitId then
        _HarnessInternal.log.error("createAttackUnitTask requires valid unit ID", "Controller.createAttackUnitTask")
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
            direction = direction
        }
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
function createBombingTask(point, weaponType, groupAttack, altitude, attackQty, direction)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error("createBombingTask requires valid point with x, y, z", "Controller.createBombingTask")
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
            direction = direction
        }
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
function createBombingRunwayTask(runwayId, weaponType, groupAttack, altitude, attackQty, direction)
    if not runwayId then
        _HarnessInternal.log.error("createBombingRunwayTask requires valid runway ID", "Controller.createBombingRunwayTask")
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
            direction = direction
        }
    }
    
    return task
end

--- Creates a land task at a specific point
---@param point table Landing position with x, y, z coordinates
---@param durationFlag boolean? Whether to use duration (default: false)
---@param duration number? Duration of landing in seconds
---@return table? task The land task table or nil on error
---@usage local task = createLandTask({x=1000, y=0, z=2000}, true, 300)
function createLandTask(point, durationFlag, duration)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error("createLandTask requires valid point with x, y, z", "Controller.createLandTask")
        return nil
    end

    local task = {
        id = "Land",
        params = {
            point = point,
            durationFlag = durationFlag or false,
            duration = duration
        }
    }
    
    return task
end

--- Creates a refueling task
---@return table task The refueling task table
---@usage local task = createRefuelingTask()
function createRefuelingTask()
    local task = {
        id = "Refueling",
        params = {}
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
function createFACAttackGroupTask(groupId, priority, designation, datalink, frequency, modulation, callsign)
    if not groupId then
        _HarnessInternal.log.error("createFACAttackGroupTask requires valid group ID", "Controller.createFACAttackGroupTask")
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
            callsign = callsign
        }
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
function createFireAtPointTask(point, radius, expendQty, expendQtyEnabled, altitude, altitudeEnabled)
    if not point or type(point) ~= "table" or not point.x or not point.y or not point.z then
        _HarnessInternal.log.error("createFireAtPointTask requires valid point with x, y, z", "Controller.createFireAtPointTask")
        return nil
    end

    local task = {
        id = "FireAtPoint",
        params = {
            point = point,
            radius = radius or 50,
            expendQty = expendQty,
            expendQtyEnabled = expendQtyEnabled or false,
            altitude = altitude,
            alt_type = altitudeEnabled and 1 or 0
        }
    }
    
    return task
end

--- Creates a hold task
---@param template any? Template for holding pattern
---@return table task The hold task table
---@usage local task = createHoldTask()
function createHoldTask(template)
    local task = {
        id = "Hold",
        params = {
            templateFlag = template ~= nil,
            template = template
        }
    }
    
    return task
end

--- Creates a go to waypoint task
---@param fromWaypointIndex number Starting waypoint index
---@param toWaypointIndex number Destination waypoint index
---@return table task The go to waypoint task table
---@usage local task = createGoToWaypointTask(1, 5)
function createGoToWaypointTask(fromWaypointIndex, toWaypointIndex)
    local task = {
        id = "GoToWaypoint",
        params = {
            fromWaypointIndex = fromWaypointIndex,
            nWaypointIndx = toWaypointIndex
        }
    }
    
    return task
end

--- Creates a wrapped action task
---@param action table The action table to wrap
---@param stopFlag boolean? Whether to stop after action (default: false)
---@return table? task The wrapped action task table or nil on error
---@usage local task = createWrappedAction({id="Script", params={...}})
function createWrappedAction(action, stopFlag)
    if not action or type(action) ~= "table" then
        _HarnessInternal.log.error("createWrappedAction requires valid action table", "Controller.createWrappedAction")
        return nil
    end

    local task = {
        id = "WrappedAction",
        params = {
            action = action,
            stopFlag = stopFlag or false
        }
    }
    
    return task
end

--- Creates a Rules of Engagement (ROE) option
---@param value number The ROE value
---@return table option The ROE option table
---@usage local option = createROEOption(2) -- WEAPON_FREE
function createROEOption(value)
    return {
        id = 0,
        value = value
    }
end

--- Creates a reaction on threat option
---@param value number The reaction value
---@return table option The reaction option table
---@usage local option = createReactionOnThreatOption(1)
function createReactionOnThreatOption(value)
    return {
        id = 1,
        value = value
    }
end

--- Creates a radar using option
---@param value number The radar usage value
---@return table option The radar option table
---@usage local option = createRadarUsingOption(1)
function createRadarUsingOption(value)
    return {
        id = 3,
        value = value
    }
end

--- Creates a flare using option
---@param value number The flare usage value
---@return table option The flare option table
---@usage local option = createFlareUsingOption(1)
function createFlareUsingOption(value)
    return {
        id = 4,
        value = value
    }
end

--- Creates a formation option
---@param value number The formation value
---@return table option The formation option table
---@usage local option = createFormationOption(1)
function createFormationOption(value)
    return {
        id = 5,
        value = value
    }
end

--- Creates a Return To Base on bingo fuel option
---@param value boolean The RTB on bingo value
---@return table option The RTB option table
---@usage local option = createRTBOnBingoOption(true)
function createRTBOnBingoOption(value)
    return {
        id = 6,
        value = value
    }
end

--- Creates a radio silence option
---@param value boolean The silence value
---@return table option The silence option table
---@usage local option = createSilenceOption(true)
function createSilenceOption(value)
    return {
        id = 7,
        value = value
    }
end

--- Creates an alarm state option
---@param value number The alarm state value
---@return table option The alarm state option table
---@usage local option = createAlarmStateOption(2)
function createAlarmStateOption(value)
    return {
        id = 9,
        value = value
    }
end

--- Creates a Return To Base on out of ammo option
---@param value boolean The RTB on out of ammo value
---@return table option The RTB option table
---@usage local option = createRTBOnOutOfAmmoOption(true)
function createRTBOnOutOfAmmoOption(value)
    return {
        id = 10,
        value = value
    }
end

--- Creates an ECM using option
---@param value number The ECM usage value
---@return table option The ECM option table
---@usage local option = createECMUsingOption(1)
function createECMUsingOption(value)
    return {
        id = 13,
        value = value
    }
end

--- Creates a prohibit waypoint pass report option (ID 14)
---@param value boolean The prohibit value
---@return table option The prohibit option table
---@usage local option = createProhibitWPPassReportOption(true)
function createProhibitWPPassReportOption(value)
    return {
        id = 14,
        value = value
    }
end

--- Creates a prohibit air-to-air option
---@param value boolean The prohibit value
---@return table option The prohibit AA option table
---@usage local option = createProhibitAAOption(false)
function createProhibitAAOption(value)
    return {
        id = 15,
        value = value
    }
end

--- Creates a prohibit jettison option
---@param value boolean The prohibit value
---@return table option The prohibit jettison option table
---@usage local option = createProhibitJettisonOption(true)
function createProhibitJettisonOption(value)
    return {
        id = 16,
        value = value
    }
end

--- Creates a prohibit afterburner option
---@param value boolean The prohibit value
---@return table option The prohibit AB option table
---@usage local option = createProhibitABOption(true)
function createProhibitABOption(value)
    return {
        id = 17,
        value = value
    }
end

--- Creates a prohibit air-to-ground option
---@param value boolean The prohibit value
---@return table option The prohibit AG option table
---@usage local option = createProhibitAGOption(false)
function createProhibitAGOption(value)
    return {
        id = 18,
        value = value
    }
end

--- Creates a missile attack option
---@param value number The missile attack value
---@return table option The missile attack option table
---@usage local option = createMissileAttackOption(1)
function createMissileAttackOption(value)
    return {
        id = 19,
        value = value
    }
end

--- Creates a prohibit waypoint pass report option (ID 20)
---@param value boolean The prohibit value
---@return table option The prohibit option table
---@usage local option = createProhibitWPPassReportOption(true)
function createProhibitWPPassReportOption(value)
    return {
        id = 20,
        value = value
    }
end

--- Creates a dispersal on attack option
---@param value boolean The dispersal value
---@return table option The dispersal option table
---@usage local option = createDispersalOnAttackOption(true)
function createDispersalOnAttackOption(value)
    return {
        id = 21,
        value = value
    }
end