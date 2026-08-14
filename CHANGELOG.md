# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `HeadingVector2D` returns the DCS Vec2 unit vector for a heading.
- `GroundTrackFromVelocity` returns track from horizontal Vec3 velocity above a configurable minimum speed.
- `HeadingFrame2D` creates forward and right axes at a Vec3 origin.
- `ProjectPointToHeadingFrame2D` returns along and lateral position in a heading frame.
- `ProjectVectorToHeadingFrame2D` returns forward and lateral vector components in a heading frame.
- `GetReciprocalRunwayName` calculates the reciprocal designator and swaps L/R suffixes.
- `NormalizeDirectionalRunways` validates raw runway records and emits primary and reciprocal directions.
- `GetDirectionalRunways` protects the `Airbase:getRunways()` compatibility call and normalizes its result.
- `GetRunwayRelativePosition` returns along and lateral position from a runway threshold.
- `GetRunwayRelativeVelocity` returns forward and lateral velocity for a runway.
- `GetRunwayLineupError` returns signed centerline error outside a configurable minimum range.
- `GetRunwayGlidepathAngle` returns threshold glidepath angle outside a configurable minimum range.
- `GetHeadwindComponent` returns the wind component opposing a landing heading.
- `SelectRunwayByHeadwind` returns the first runway with the greatest headwind component.
- `FindNearestRunway` returns the runway with the nearest paved-surface center.
- `GetUnitPosition3` returns one protected and fully validated DCS Position3 value.
- `GetAttitudeFromPosition3` returns heading, pitch, and bank from Position3 axes.
- `AirRelativeVelocity` subtracts wind velocity from ground velocity.
- `GetAerodynamicAngles` returns angle of attack, sideslip, and true airspeed.
- `CalculateIsaAtmosphere` returns International Standard Atmosphere data from 0 through 20 km.
- `GetAirData` returns DCS atmosphere data with an ISA fallback.
- `MachFromTrueAirspeed` returns Mach from true airspeed and temperature.
- `TrueAirspeedToCalibratedAirspeed` converts subsonic true airspeed to calibrated airspeed.
- `GetUnitDrawArguments` reads a caller-supplied argument ID array and reports whether the result is complete.
- `GetAllAirbases` merges world and coalition airbases, deduplicates them by name, and sorts them.
- `FindAirbasesWithin` filters a caller-supplied airbase list by radius.
- `GetAllPlayerUnits` returns name-sorted player units from neutral, red, and blue coalitions.
- `GetPlayerIds` returns the network player ID list.
- `GetPlayerInfos` returns available information for all network player IDs.
- `FindPlayerInfosByName` returns every exact player-name match and accepts a caller-supplied list.
- `GetWorldEventUnit` resolves a named unit from an event initiator or unit field.
- `GetMissionFileCapabilities` reports whether protected mission file access is available.
- `SanitizeFilenameComponent` produces a bounded safe filename component.
- `EnsureMissionDirectory` creates a validated relative directory below `lfs.writedir()`.
- `WriteMissionTextFile` writes a new protected text file without overwriting an existing target.
- `WriteUniqueMissionTextFile` writes the first available name within a bounded numeric suffix range.
- `TimeWeightedStats` creates a constant-size duration-weighted statistics accumulator.
- `TimeWeightedStats:add` accepts one value and positive duration and updates the bounded accumulator.
- `TimeWeightedStats:count` returns the accepted sample count.
- `TimeWeightedStats:duration` returns the total accepted duration.
- `TimeWeightedStats:mean` returns the duration-weighted mean.
- `TimeWeightedStats:rms` returns the duration-weighted root mean square.
- `TimeWeightedStats:min` returns the minimum accepted value.
- `TimeWeightedStats:max` returns the maximum accepted value.
- `TimeWeightedStats:peak` returns the signed greatest-absolute value and its label.
- `TimeWeightedStats:reset` clears all accumulator state.
- `HarnessConstants.AIR_SPECIFIC_HEAT_RATIO` defines the dry-air ratio of specific heats.
- `HarnessConstants.DRY_AIR_GAS_CONSTANT_J_KG_K` defines the dry-air gas constant.
- `HarnessConstants.SEA_LEVEL_PRESSURE_PA` defines standard sea-level pressure.
- `HarnessConstants.SEA_LEVEL_DENSITY_KG_M3` defines standard sea-level density.
- `HarnessConstants.SEA_LEVEL_TEMPERATURE_K` defines standard sea-level temperature.
- `HarnessConstants.AIR_DATA_SOURCE_DCS` identifies DCS atmosphere data.
- `HarnessConstants.AIR_DATA_SOURCE_ISA` identifies calculated ISA data.

### Changed

- Version changed from 0.8.0 to 1.0.0.
- `Vec2` now stores DCS `{x,y}` fields instead of `{x,z}`.
- `IsVec2` now accepts only DCS `{x,y}` values without a Z component.
- `ToVec2` now returns DCS `{x,y}` and maps Vec3 Z to Vec2 Y.
- `ToVec3` now maps Vec2 Y to Vec3 Z and uses its altitude argument for Vec3 Y.
- `VecAdd` now adds Vec2 X/Y components.
- `VecSub` now subtracts Vec2 X/Y components.
- `VecScale` now scales Vec2 X/Y components.
- `VecDiv` now divides Vec2 X/Y components.
- `VecLength` now measures Vec2 X/Y components.
- `VecLength2D` now measures Vec2 X/Y or Vec3 X/Z components.
- `VecDot` now computes Vec2 dot products from X/Y components.
- `Distance2D` now measures Vec2 X/Y or Vec3 X/Z separation.
- `Distance2DSquared` now measures squared Vec2 X/Y or Vec3 X/Z separation.
- `Bearing` now uses positive world X as north and east as 90 degrees.
- `BearingBetween` now delegates to `Bearing`.
- `FromBearingDistance` now displaces X by cosine and east by sine.
- `DisplacePoint2D` now delegates to `FromBearingDistance`.
- `Midpoint` now returns Vec2 X/Y midpoints.
- `VecLerp` now interpolates Vec2 X/Y components.
- `Vec2ToString` now formats Vec2 X/Y fields.
- `Vec2:toVec3` now maps Vec2 Y to Vec3 Z and uses its argument for Vec3 altitude.
- `Vec2:length` now measures X/Y components.
- `Vec2:normalized` now normalizes X/Y components.
- `Vec2:dot` now computes its dot product from X/Y components.
- `Vec2:distanceTo` now measures X/Y separation.
- `Vec2:bearingTo` now uses positive X as north and positive Y as east.
- `Vec2:displace` now displaces X by cosine and Y by sine.
- `Vec2:midpointTo` now returns an X/Y midpoint.
- `Vec2:angleTo` now calculates its angle from X/Y components.
- `Vec2:rotate` now rotates X/Y components.
- `Vec3:toVec2` now projects Vec3 X/Z to Vec2 X/Y.
- `Vec3:bearingTo` now uses positive X as north and positive Z as east.
- `Vec3:displace2D` now displaces X by cosine and Z by sine while preserving altitude.
- `MidPoint` now accepts and returns DCS Vec2 X/Y values or Vec3 values.
- `RotatePoint2D` now rotates DCS Vec2 X/Y or Vec3 X/Z coordinates.
- `NormalizeVector2D` now normalizes DCS Vec2 X/Y or Vec3 X/Z coordinates.
- `DotProduct2D` now uses DCS Vec2 X/Y or Vec3 X/Z components.
- `AngleBetweenVectors2D` now uses DCS Vec2 X/Y or Vec3 X/Z components.
- `PointInPolygon2D` now accepts DCS Vec2 X/Y or Vec3 X/Z points.
- `CircleLineIntersection2D` now accepts and returns DCS Vec2 or Vec3 coordinates.
- `PolygonArea2D` now calculates area from DCS Vec2 X/Y or Vec3 X/Z points.
- `PolygonCentroid2D` now returns a DCS Vec2 or Vec3 centroid matching its input.
- `ConvexHull2D` now reads DCS Vec2 X/Y or Vec3 X/Z points.
- `GetWindHeading` now uses the same DCS world convention as unit heading.
- `GetTerrainHeight` now projects Vec3 X/Z to DCS Vec2 X/Y and rejects malformed tables.
- `GetSurfaceType` now projects Vec3 X/Z to DCS Vec2 X/Y and rejects malformed tables.
- `GetAGL` now gets ground height through the corrected Vec3-to-Vec2 projection.
- `SetAGL` now gets ground height through the corrected Vec3-to-Vec2 projection.
- `GetClosestRoadPoint` now returns a DCS Vec2 `{x,y}`.
- `FindRoadPath` now returns DCS Vec2 `{x,y}` points.
- `AddCommand` now forwards caption before path and returns the native Path.
- `AddCommandForCoalition` now forwards coalition ID, caption, path, handler, and argument.
- `AddCommandForGroup` now forwards group ID, caption, path, handler, and argument.
- `AddSubMenu` now forwards caption before path and returns the native Path.
- `AddSubMenuForCoalition` now forwards coalition ID, caption, and path.
- `AddSubMenuForGroup` now forwards group ID, caption, and path.
- `RemoveItem` now accepts a nil root path.
- `RemoveItemForCoalition` now accepts a nil root path.
- `RemoveItemForGroup` now accepts a nil root path.
- `GetUnitID` now accepts names or unit objects and normalizes positive integral numeric strings.
- `GetUnitVelocity` now accepts names or unit objects and returns a validated Vec3.
- `OutTextForUnit` now normalizes positive integral numeric IDs and numeric strings before the unit-scoped DCS call.
- `GetUnitPosition` now derives from `GetUnitPosition3`.
- `GetUnitHeading` now derives from `GetAttitudeFromPosition3`.
- `GetUnitOrientation` now derives from the protected Position3 boundary.
- `GetUnitPositionAndHeading` now uses one protected Position3 call.
- `GetUnitDrawArgument` now shares unit resolution and argument validation with batch reads.
- `CreateTriangle` now accepts and returns DCS Vec2 values.
- `CreateRectangle` now accepts and returns DCS Vec2 values.
- `CreateSquare` now accepts and returns DCS Vec2 values.
- `CreateOval` now accepts and returns DCS Vec2 values.
- `CreateCircle` now accepts and returns DCS Vec2 values.
- `CreateFan` now accepts and returns DCS Vec2 values.
- `CreateTrapezoid` now accepts and returns DCS Vec2 values.
- `CreatePill` now accepts and returns DCS Vec2 values.
- `CreateStar` now accepts and returns DCS Vec2 values.
- `CreatePolygon` now accepts and returns DCS Vec2 values.
- `CreateHexagon` now accepts and returns DCS Vec2 values.
- `CreateOctagon` now accepts and returns DCS Vec2 values.
- `CreateArc` now accepts and returns DCS Vec2 values.
- `CreateSpiral` now accepts and returns DCS Vec2 values.
- `CreateRing` now accepts and returns DCS Vec2 values.
- `CreateCross` now accepts and returns DCS Vec2 values.
- `ShapeToVec3` now converts plain DCS Vec2 X/Y points to Vec3 X/Z without requiring Harness methods.
- `LineSegmentIntersection2D` now accepts and returns DCS Vec2 values.
- `FindPolygonIntersections` now returns DCS Vec2 intersection points.
- `MergePolygons` now sorts and returns DCS Vec2 polygon points.
- `UnionPolygons` now returns DCS Vec2 polygon points.
- `IntersectPolygons` now returns DCS Vec2 polygon points.
- `DifferencePolygons` now returns DCS Vec2 polygon points.
- `SimplifyPolygon` now measures DCS Vec2 polygon coordinates.
- `PerpendicularDistance2D` now accepts DCS Vec2 values.
- `OffsetPolygon` now accepts and returns DCS Vec2 values.
- `ClipPolygonToPolygon` now accepts and returns DCS Vec2 values.
- `TriangulatePolygon` now triangulates DCS Vec2 X/Y points.
- `PointInTriangle2D` now accepts DCS Vec2 values.
- `GetUnitsInDrawing` now projects unit Vec3 X/Z positions to DCS Vec2 X/Y for containment checks.
- `GetDrawingsAtPoint` now accepts DCS Vec2 or Vec3 points.
- `GetShapesAtPoint` now accepts DCS Vec2 or Vec3 points.
- `IsPointInDrawing` now accepts DCS Vec2 or Vec3 points.
- `IsInZone` now projects unit Vec3 X/Z positions to DCS Vec2 X/Y for cached-zone checks.
- `GetUnitsInZone` now projects unit Vec3 X/Z positions to DCS Vec2 X/Y for containment checks.
- `IsPointInZoneGeometry` now accepts DCS Vec2 or Vec3 points.
- Private helper sets now use uniquely named local tables in the concatenated Lua scope.

### Removed

- Harness-specific `{x,z}` Vec2 representation.
- `GetPlayers` was removed. Use `GetPlayerIds` for IDs or `GetPlayerInfos` for network information records.


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
