--[[
    Coord Module - DCS World Coordinate API Wrappers

    This module provides validated wrapper functions for DCS coordinate conversions,
    including Lat/Long, MGRS, and XYZ coordinate transformations.
]]

require("logger")
require("vector")

--- Convert local coordinates to latitude/longitude
---@param vec3 table Vec3 position in local coordinates {x, y, z}
---@return table? latlon Table with latitude and longitude fields, nil on error
---@usage local ll = LOtoLL(position)
function LOtoLL(vec3)
    if not vec3 or type(vec3) ~= "table" or not vec3.x or not vec3.y or not vec3.z then
        _HarnessInternal.log.error("LOtoLL requires valid vec3 with x, y, z", "Coord.LOtoLL")
        return nil
    end

    local success, result = pcall(coord.LOtoLL, vec3)
    if not success then
        _HarnessInternal.log.error(
            "Failed to convert LO to LL: " .. tostring(result),
            "Coord.LOtoLL"
        )
        return nil
    end

    return result
end

--- Convert latitude/longitude to local coordinates
---@param latitude number Latitude in degrees
---@param longitude number Longitude in degrees
---@param altitude number? Altitude in meters (default 0)
---@return table? vec3 Vec3 position in local coordinates, nil on error
---@usage local pos = LLtoLO(43.5, 41.2, 1000)
function LLtoLO(latitude, longitude, altitude)
    if not latitude or type(latitude) ~= "number" then
        _HarnessInternal.log.error("LLtoLO requires valid latitude", "Coord.LLtoLO")
        return nil
    end

    if not longitude or type(longitude) ~= "number" then
        _HarnessInternal.log.error("LLtoLO requires valid longitude", "Coord.LLtoLO")
        return nil
    end

    altitude = altitude or 0

    local success, result = pcall(coord.LLtoLO, latitude, longitude, altitude)
    if not success then
        _HarnessInternal.log.error(
            "Failed to convert LL to LO: " .. tostring(result),
            "Coord.LLtoLO"
        )
        return nil
    end

    return result
end

--- Convert local coordinates to MGRS string
---@param vec3 table Vec3 position in local coordinates {x, y, z}
---@return table? mgrs MGRS coordinate table, nil on error
---@usage local mgrs = LOtoMGRS(position)
function LOtoMGRS(vec3)
    if not vec3 or type(vec3) ~= "table" or not vec3.x or not vec3.y or not vec3.z then
        _HarnessInternal.log.error("LOtoMGRS requires valid vec3 with x, y, z", "Coord.LOtoMGRS")
        return nil
    end

    -- DCS does not expose coord.LOtoMGRS; compose LO->LL->MGRS
    local okLL, ll = pcall(coord.LOtoLL, vec3)
    if not okLL or not ll or type(ll.latitude) ~= "number" or type(ll.longitude) ~= "number" then
        _HarnessInternal.log.error("Failed to convert LO to LL: " .. tostring(ll), "Coord.LOtoMGRS")
        return nil
    end

    local okMGRS, mgrs = pcall(coord.LLtoMGRS, ll.latitude, ll.longitude)
    if not okMGRS then
        _HarnessInternal.log.error(
            "Failed to convert LL to MGRS: " .. tostring(mgrs),
            "Coord.LOtoMGRS"
        )
        return nil
    end

    return mgrs
end

--- Convert MGRS string to local coordinates
---@param mgrsString string MGRS coordinate string
---@return table? vec3 Vec3 position in local coordinates, nil on error
---@usage local pos = MGRStoLO("37T CK 12345 67890")
function MGRStoLO(mgrsString)
    if not mgrsString or type(mgrsString) ~= "string" or mgrsString == "" then
        _HarnessInternal.log.error("MGRStoLO requires valid MGRS string", "Coord.MGRStoLO")
        return nil
    end

    -- DCS does not expose coord.MGRStoLO; compose MGRS->LL->LO
    local okLL, ll = pcall(coord.MGRStoLL, mgrsString)
    if not okLL or not ll or type(ll.lat) ~= "number" or type(ll.lon) ~= "number" then
        _HarnessInternal.log.error(
            "Failed to convert MGRS to LL: " .. tostring(ll),
            "Coord.MGRStoLO"
        )
        return nil
    end

    local okLO, lo = pcall(coord.LLtoLO, ll.lat, ll.lon)
    if not okLO then
        _HarnessInternal.log.error("Failed to convert LL to LO: " .. tostring(lo), "Coord.MGRStoLO")
        return nil
    end

    return lo
end

--- Convert decimal degrees to degrees, minutes, seconds
---@param decimal number Coordinate in decimal degrees
---@return number degrees Whole degrees
---@return number minutes Whole minutes
---@return number seconds Seconds (with decimal precision)
---@usage local d, m, s = DecimalToDMS(43.5678)
function DecimalToDMS(decimal)
    if type(decimal) ~= "number" then
        _HarnessInternal.log.error("DecimalToDMS requires number", "Coord.DecimalToDMS")
        return 0, 0, 0
    end

    local abs = math.abs(decimal)
    local degrees = math.floor(abs)
    local minutesDecimal = (abs - degrees) * 60
    local minutes = math.floor(minutesDecimal)
    local seconds = (minutesDecimal - minutes) * 60

    return degrees, minutes, seconds
end

--- Get cardinal orientation strings for latitude and longitude
---@param lat number Latitude in decimal degrees
---@param lon number Longitude in decimal degrees
---@return string latDir "N" or "S"
---@return string lonDir "E" or "W"
---@usage local ns, ew = GetLatLonOrientation(43.5, -39.2)
function GetLatLonOrientation(lat, lon)
    if type(lat) ~= "number" or type(lon) ~= "number" then
        _HarnessInternal.log.error(
            "GetLatLonOrientation requires numeric lat and lon",
            "Coord.GetLatLonOrientation"
        )
        return "N", "E"
    end

    local latDir = lat >= 0 and "N" or "S"
    local lonDir = lon >= 0 and "E" or "W"
    return latDir, lonDir
end

--- Convert lat/lon to formatted MGRS string
---@param lat number Latitude in decimal degrees
---@param lon number Longitude in decimal degrees
---@param precision number? Grid precision (default 5, range 1-5)
---@return string? mgrs Formatted MGRS string, nil on error
---@usage local mgrs = CoordToMGRS(43.5, 41.2)
function CoordToMGRS(lat, lon, precision)
    if type(lat) ~= "number" or type(lon) ~= "number" then
        _HarnessInternal.log.error("CoordToMGRS requires numeric lat and lon", "Coord.CoordToMGRS")
        return nil
    end

    precision = precision or 5
    if precision < 1 then
        precision = 1
    elseif precision > 5 then
        precision = 5
    end

    local success, mgrs = pcall(coord.LLtoMGRS, lat, lon)
    if not success or not mgrs then
        _HarnessInternal.log.error(
            "Failed to convert LL to MGRS: " .. tostring(mgrs),
            "Coord.CoordToMGRS"
        )
        return nil
    end

    local UTMZone = mgrs.UTMZone or ""
    local MGRSDigraph = mgrs.MGRSDigraph or ""
    local Easting = mgrs.Easting or 0
    local Northing = mgrs.Northing or 0

    local eastStr = string.format("%05d", math.floor(Easting))
    local northStr = string.format("%05d", math.floor(Northing))

    eastStr = string.sub(eastStr, 1, precision)
    northStr = string.sub(northStr, 1, precision)

    return UTMZone .. " " .. MGRSDigraph .. " " .. eastStr .. " " .. northStr
end
