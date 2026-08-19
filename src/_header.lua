-- Version
---@type string
HARNESS_VERSION = "1.0.0-rc2"

-- Internal namespace for logger
_HarnessInternal = _HarnessInternal or {}

-- Shared constants
---@class HarnessConstants
---@field NM_TO_METERS number
---@field METERS_TO_NM number
---@field FEET_TO_METERS number
---@field METERS_TO_FEET number
---@field KM_TO_METERS number
---@field METERS_TO_KM number
---@field MPS_TO_KNOTS number
---@field KNOTS_TO_MPS number
---@field DEG_TO_RAD number
---@field RAD_TO_DEG number
---@field EARTH_RADIUS_M number
---@field SEA_LEVEL_TEMPERATURE_K number
---@field SEA_LEVEL_PRESSURE_PA number
---@field SEA_LEVEL_DENSITY_KG_M3 number
---@field AIR_SPECIFIC_HEAT_RATIO number
---@field DRY_AIR_GAS_CONSTANT_J_KG_K number
---@field ISA_TEMP_LAPSE_RATE number
---@field ISA_DENSITY_EXPONENT number
---@field AIR_DATA_SOURCE_DCS string
---@field AIR_DATA_SOURCE_ISA string
---@field ISA_SEA_LEVEL_TEMP_K number
---@type HarnessConstants
HarnessConstants = {
    -- Distance
    NM_TO_METERS = 1852,
    METERS_TO_NM = 1 / 1852,
    FEET_TO_METERS = 0.3048,
    METERS_TO_FEET = 1 / 0.3048,
    KM_TO_METERS = 1000,
    METERS_TO_KM = 0.001,

    -- Speed
    MPS_TO_KNOTS = 1.943844492,
    KNOTS_TO_MPS = 1 / 1.943844492,

    -- Angles
    DEG_TO_RAD = math.pi / 180,
    RAD_TO_DEG = 180 / math.pi,

    -- Geospatial
    EARTH_RADIUS_M = 6371000,

    -- ISA (International Standard Atmosphere)
    SEA_LEVEL_TEMPERATURE_K = 288.15,
    SEA_LEVEL_PRESSURE_PA = 101325,
    SEA_LEVEL_DENSITY_KG_M3 = 1.225,
    AIR_SPECIFIC_HEAT_RATIO = 1.4,
    DRY_AIR_GAS_CONSTANT_J_KG_K = 287.05,
    ISA_TEMP_LAPSE_RATE = 0.0065,
    ISA_DENSITY_EXPONENT = 4.2559,

    AIR_DATA_SOURCE_DCS = "DCS",
    AIR_DATA_SOURCE_ISA = "ISA",
}

HarnessConstants.ISA_SEA_LEVEL_TEMP_K = HarnessConstants.SEA_LEVEL_TEMPERATURE_K
