-- Mock DCS Environment for Testing
-- This file provides mock implementations of DCS APIs for unit testing

-- Mock global functions and tables
env = {
    info = function(msg) end,
    warning = function(msg) end,
    error = function(msg) end
}

timer = {
    getTime = function() return 1000.0 end,
    getAbsTime = function() return 50000.0 end,
    getTime0 = function() return 43200.0 end,
    scheduleFunction = function(func, args, time) return math.random(1, 1000) end,
    removeFunction = function(timerId) return true end,
    setFunctionTime = function(timerId, newTime) return true end
}

land = {
    getHeight = function(vec2) return 100.0 end,
    isVisible = function(from, to) return true end,
    getSurfaceType = function(vec2) return 1 end,
    getIP = function(origin, direction, maxDistance) return {x = 100, y = 50, z = 200} end,
    profile = function(from, to) return {{x = 0, y = 100}, {x = 100, y = 120}} end,
    getClosestPointOnRoads = function(roadType, x, y) return {x = x, y = 0, z = y} end,
    findPathOnRoads = function(roadType, x1, y1, x2, y2) return {{x = x1, y = 0, z = y1}, {x = x2, y = 0, z = y2}} end
}

coord = {
    LOtoLL = function(vec3) return {latitude = 43.5, longitude = 41.2} end,
    LLtoLO = function(lat, lon, alt) return {x = 1000, y = alt or 0, z = 2000} end,
    LOtoMGRS = function(vec3) return {UTMZone = "37T", MGRSDigraph = "CK", Easting = 12345, Northing = 67890} end,
    MGRStoLO = function(mgrsString) return {x = 1000, y = 0, z = 2000} end
}

trigger = {
    misc = {
        getZone = function(name) return {point = {x = 0, y = 0, z = 0}, radius = 1000} end,
        getUserFlag = function(name) return 0 end
    },
    action = {
        setUserFlag = function(name, value) return true end,
        outText = function(text, time, clear) return true end,
        outTextForCoalition = function(coalition, text, time, clear) return true end,
        outTextForGroup = function(group, text, time, clear) return true end,
        explosion = function(pos, power) return true end,
        smoke = function(pos, color, density, name) return true end,
        effectSmokeBig = function(pos, preset, density, name) return true end,
        signalFlare = function(pos, color, azimuth) return true end,
        illuminationBomb = function(pos, power) return true end
    }
}

Unit = {
    getByName = function(name) 
        return {
            isExist = function(self) return true end,
            getPosition = function(self) return {p = {x = 100, y = 50, z = 200}, x = {x = 1, y = 0, z = 0}} end,
            getVelocity = function(self) return {x = 10, y = 0, z = 5} end,
            getTypeName = function(self) return "F-16C" end,
            getCoalition = function(self) return 2 end,
            getCountry = function(self) return 1 end,
            getGroup = function(self) return {} end,
            getPlayerName = function(self) return "TestPlayer" end,
            getLife = function(self) return 1.0 end,
            getLife0 = function(self) return 1.0 end,
            getFuel = function(self) return 0.8 end,
            inAir = function(self) return true end,
            getAmmo = function(self) return {} end,
            getName = function(self) return name end
        }
    end
}

Group = {
    getByName = function(name)
        return {
            isExist = function(self) return true end,
            getUnits = function(self) return {Unit.getByName("unit1"), Unit.getByName("unit2")} end,
            getSize = function(self) return 2 end,
            getInitialSize = function(self) return 2 end,
            getCoalition = function(self) return 2 end,
            getCategory = function(self) return 0 end,
            getID = function(self) return 1 end,
            getController = function(self) return {} end,
            activate = function(self) return true end,
            getName = function(self) return name end
        }
    end,
    Category = {
        AIRPLANE = 0,
        HELICOPTER = 1,
        GROUND = 2,
        SHIP = 3,
        STRUCTURE = 4
    }
}

coalition = {
    getGroups = function(coalitionId, categoryId) return {} end,
    side = {
        NEUTRAL = 0,
        RED = 1,
        BLUE = 2
    }
}

atmosphere = {
    getWind = function(point) return {x = 5, y = 0, z = 2} end,
    getWindWithTurbulence = function(point) return {x = 5, y = 1, z = 2} end,
    getTemperatureAndPressure = function(point) return {temperature = 15, pressure = 101325} end
}

Airbase = {
    getByName = function(name)
        return {
            getDescriptor = function(self) return {} end,
            getCallsign = function(self) return "Batumi" end,
            getUnit = function(self) return nil end,
            getCategoryName = function(self) return "AIRBASE" end,
            getParking = function(self, available) return {} end,
            getRunways = function(self) return {} end,
            getRadioSilentMode = function(self) return false end,
            setRadioSilentMode = function(self, silent) return true end
        }
    end
}

missionCommands = {
    addCommand = function(path, menuItem, handler, params) return math.random(1, 1000) end,
    addSubMenu = function(path, name) return math.random(1, 1000) end,
    removeItem = function(path) return true end,
    addCommandForCoalition = function(coalition, path, menuItem, handler, params) return math.random(1, 1000) end,
    addSubMenuForCoalition = function(coalition, path, name) return math.random(1, 1000) end,
    removeItemForCoalition = function(coalition, path) return true end,
    addCommandForGroup = function(group, path, menuItem, handler, params) return math.random(1, 1000) end,
    addSubMenuForGroup = function(group, path, name) return math.random(1, 1000) end,
    removeItemForGroup = function(group, path) return true end
}

world = {
    addEventHandler = function(handler) return true end,
    removeEventHandler = function(handler) return true end,
    getPlayer = function() return Unit.getByName("Player") end,
    getAirbases = function(coalition) return {} end,
    searchObjects = function(category, volume, handler) return {} end,
    getMarkPanels = function() return {} end
}

country = {
    id = {
        USA = 1,
        RUSSIA = 2
    }
}

-- Initialize random seed
math.randomseed(os.time())