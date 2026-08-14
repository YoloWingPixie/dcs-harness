--[[
==================================================================================================
    FLIGHT MODULE
    Aircraft-neutral air-relative kinematics and aerodynamic calculations
==================================================================================================
]]

require("logger")
require("vector")

local FlightInternal = {}

function FlightInternal.validVector(vector)
    return type(vector) == "table"
        and type(vector.x) == "number"
        and vector.x == vector.x
        and vector.x > -math.huge
        and vector.x < math.huge
        and type(vector.y) == "number"
        and vector.y == vector.y
        and vector.y > -math.huge
        and vector.y < math.huge
        and type(vector.z) == "number"
        and vector.z == vector.z
        and vector.z > -math.huge
        and vector.z < math.huge
end

function FlightInternal.isCompletePosition3(value)
    return type(value) == "table"
        and FlightInternal.validVector(value.p)
        and FlightInternal.validVector(value.x)
        and FlightInternal.validVector(value.y)
        and FlightInternal.validVector(value.z)
end

--- Subtract wind velocity from ground velocity
---@param groundVelocity table Vec3 ground velocity
---@param windVelocity table Vec3 wind velocity
---@return table? airVelocity Air-relative Vec3 velocity
function AirRelativeVelocity(groundVelocity, windVelocity)
    if
        not FlightInternal.validVector(groundVelocity)
        or not FlightInternal.validVector(windVelocity)
    then
        _HarnessInternal.log.error(
            "AirRelativeVelocity requires ground and wind Vec3 values",
            "Flight.AirRelativeVelocity"
        )
        return nil
    end
    return Vec3(
        groundVelocity.x - windVelocity.x,
        groundVelocity.y - windVelocity.y,
        groundVelocity.z - windVelocity.z
    )
end

--- Calculate aircraft-neutral angle of attack and sideslip
---@param position3 table DCS Position3 body axes
---@param airVelocity table Vec3 air-relative velocity
---@param minSpeedMps number? Minimum true airspeed, default 5 m/s
---@return table? angles Aerodynamic angles and true airspeed
function GetAerodynamicAngles(position3, airVelocity, minSpeedMps)
    minSpeedMps = minSpeedMps == nil and 5 or minSpeedMps
    if
        not FlightInternal.isCompletePosition3(position3)
        or not FlightInternal.validVector(airVelocity)
        or type(minSpeedMps) ~= "number"
        or minSpeedMps ~= minSpeedMps
        or minSpeedMps < 0
        or minSpeedMps >= math.huge
    then
        _HarnessInternal.log.error(
            "GetAerodynamicAngles requires Position3, Vec3 velocity, and a non-negative threshold",
            "Flight.GetAerodynamicAngles"
        )
        return nil
    end

    local trueAirspeedMps = math.sqrt(
        airVelocity.x * airVelocity.x
            + airVelocity.y * airVelocity.y
            + airVelocity.z * airVelocity.z
    )
    if trueAirspeedMps < minSpeedMps then
        return nil
    end

    local function projection(axis)
        return airVelocity.x * axis.x + airVelocity.y * axis.y + airVelocity.z * axis.z
    end

    local forward = projection(position3.x)
    local up = projection(position3.y)
    local right = projection(position3.z)
    return {
        aoaDeg = math.deg(math.atan2(-up, forward)),
        betaDeg = math.deg(math.atan2(right, forward)),
        trueAirspeedMps = trueAirspeedMps,
    }
end
