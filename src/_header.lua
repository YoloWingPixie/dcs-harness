-- Version
HARNESS_VERSION = "1.0.0"

-- Internal namespace for logger
_HarnessInternal = _HarnessInternal or {}

-- Shared constants
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
    ISA_SEA_LEVEL_TEMP_K = 288.15,
    ISA_TEMP_LAPSE_RATE = 0.0065,
    ISA_DENSITY_EXPONENT = 4.2559,
}
