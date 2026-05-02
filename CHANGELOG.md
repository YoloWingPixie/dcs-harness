# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

### Removed

### Deprecated


## [0.8.0] - 2026-05-01
### Added

- `HarnessConstants` global table consolidating all shared constants
- `GetTacanFrequency` TACAN frequency calculator
- `GetWindHeading` and `GetWindSpeed` atmosphere helpers
- `InverseHeading` reciprocal heading utility
- `ConvertKiasToGroundSpeed` and `ConvertKiasToMps` ISA-based airspeed conversion
- `GetAllShips` and `GetAllAircraftGroups` coalition-wide queries
- `IsSuperCarrier` unit type detection
- `GetUnitHeading` now accepts unit objects in addition to names
- `GetUnitOrientation` and `GetUnitPositionAndHeading` combo queries
- `DecimalToDMS`, `GetLatLonOrientation`, and `CoordToMGRS` coordinate formatting
- `BuildGroundWaypoint` and `GoRoute` ground unit routing helpers
- `IsNotAtMapOrigin` non-origin position guard
- `RingBuffer:reverseIter` newest-to-oldest iteration with early exit

[Unreleased]: https://github.com/YoloWingPixie/dcs-harness/compare/v0.8.0...HEAD
[0.8.0]: https://github.com/YoloWingPixie/dcs-harness/releases/tag/v0.8.0
