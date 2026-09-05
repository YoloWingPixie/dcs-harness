Harness 1.0 API reference
=========================

Coordinate types
----------------

Vec2 and Vec3 use the DCS fields.

.. list-table:: Vector fields
   :header-rows: 1

   * - Type
     - Fields
     - Meaning
   * - ``Vec2``
     - ``{x, y}``
     - Ground plane. X is north and Y is east.
   * - ``Vec3``
     - ``{x, y, z}``
     - World point or vector. X is north, Y is altitude or vertical component, and Z is east.

Heading zero points along positive world X. Heading 90 points east. ``Vec2`` and ``Vec3`` instances add methods and operators but retain the native DCS field layout.

Vector and terrain functions
----------------------------

::

   IsFiniteVec2(value) -> boolean
   IsFiniteVec3(value) -> boolean
   Bearing(from, to) -> headingDeg|nil
   BearingBetween(from, to) -> headingDeg|nil
   FromBearingDistance(origin, headingDeg, distanceM) -> Vec2|Vec3|nil
   DisplacePoint2D(point, headingDeg, distanceM) -> Vec2|Vec3|nil
   GetWindHeading(position) -> headingDeg|nil
   GetTerrainHeight(position) -> heightM
   GetSurfaceType(position) -> surfaceType|nil
   GetAGL(position) -> aglM
   SetAGL(position, aglM) -> Vec3
   GetClosestRoadPoint(position, roadType?) -> Vec2|nil
   FindRoadPath(from, to, roadType?) -> Vec2[]

``IsFiniteVec2`` and ``IsFiniteVec3`` accept plain tables or vector instances with finite numeric coordinates. They return ``false`` for malformed vectors, NaN, and positive or negative infinity in any coordinate. Vec2 requires numeric X/Y and no Z component. Vec3 requires numeric X/Y/Z. ``IsVec2`` and ``IsVec3`` retain their structural checks and accept non-finite numeric coordinates.

``ToVec2`` normalizes a Vec2 or projects Vec3 X/Z to Vec2 X/Y. Terrain calls use this projection before calling ``land.getHeight`` or ``land.getSurfaceType``. Terrain height keeps the established zero fallback. Invalid surface queries return ``nil``.

``Bearing`` and displacement accept DCS Vec2 or Vec3 values. They use these equations:

::

   heading = NormalizeAngle(deg(atan2(eastDelta, xDelta)))
   xDelta = cos(rad(heading)) * distance
   eastDelta = sin(rad(heading)) * distance

Road functions keep the native numeric DCS argument order and return DCS Vec2 values.

Mission commands
----------------

::

   AddCommand(path, menuItem, handler, argument) -> Path|nil
   AddCommandForCoalition(coalitionId, path, menuItem, handler, argument) -> Path|nil
   AddCommandForGroup(groupId, path, menuItem, handler, argument) -> Path|nil
   AddSubMenu(path, name) -> Path|nil
   AddSubMenuForCoalition(coalitionId, path, name) -> Path|nil
   AddSubMenuForGroup(groupId, path, name) -> Path|nil

``menuItem.name`` must be a non-empty string. ``path`` may be a native DCS Path or ``nil`` for a root item. The wrappers keep the Harness-facing order above and forward native calls as caption, path, handler, and argument, with the applicable coalition or group ID first. Removal wrappers accept ``nil`` paths where the DCS root-removal API permits them.

Unit identifiers and kinematics
-------------------------------

::

   GetUnitID(unitOrName) -> integer|nil
   GetUnitVelocity(unitOrName) -> Vec3|nil
   OutTextForUnit(unitId, text, displayTime, clearView) -> true|nil
   GetUnitPosition3(unitOrName) -> Position3|nil
   GetAttitudeFromPosition3(position3) -> attitude|nil
   GetUnitDrawArguments(unitOrName, argumentIds) -> values|nil, complete

Unit names resolve through ``GetUnit``. ID functions normalize numeric strings and accept only positive integral values. ``OutTextForUnit`` does not fall back to group text.

``GetUnitPosition3`` validates all four DCS Position3 vectors:

.. code-block:: lua

   {
       p = Vec3,
       x = Vec3,
       y = Vec3,
       z = Vec3,
   }

The attitude record is:

.. code-block:: lua

   {
       headingDeg = number,
       pitchDeg = number,
       bankDeg = number,
   }

``GetUnitPosition``, ``GetUnitHeading``, and ``GetUnitOrientation`` derive from the same protected Position3 boundary.

Batch draw arguments use an array of non-negative integral argument IDs. Successful values are keyed by ID:

.. code-block:: lua

   {
       [0] = 1.0,
       [3] = 0.95,
       [5] = 0.97,
   }

Failed reads are omitted and logged. ``complete`` is true only when every requested value is numeric.

Heading-relative geometry
-------------------------

::

   HeadingVector2D(headingDeg) -> Vec2|nil
   GroundTrackFromVelocity(velocity, minSpeedMps?) -> headingDeg|nil
   HeadingFrame2D(origin, headingDeg) -> frame|nil
   ProjectPointToHeadingFrame2D(frame, point) -> alongM, lateralM
   ProjectVectorToHeadingFrame2D(frame, vector) -> forwardMps, lateralMps

``GroundTrackFromVelocity`` defaults to 15 m/s and returns ``nil`` below the threshold. A heading frame is:

.. code-block:: lua

   {
       origin = Vec3,
       headingDeg = number,
       forward = Vec2,
       right = Vec2,
   }

``forward`` is ``Vec2(cos(heading), sin(heading))``. ``right`` uses heading plus 90 degrees. Positive along values are forward. Positive lateral values are right. Point projection subtracts the frame origin. Vector projection does not.

Directional runways
-------------------

::

   GetReciprocalRunwayName(name) -> string
   NormalizeDirectionalRunways(airbaseName, rawRunways, reciprocalSanityDeg?) -> runways|nil
   GetDirectionalRunways(airbase, reciprocalSanityDeg?) -> runways|nil
   GetRunwayRelativePosition(runway, point) -> alongM, lateralM
   GetRunwayRelativeVelocity(runway, velocity) -> forwardMps, lateralMps
   GetRunwayLineupError(runway, point, minRangeM?) -> degrees|nil
   GetRunwayGlidepathAngle(runway, point, thresholdElevationM, minRangeM?) -> degrees|nil
   GetHeadwindComponent(wind, headingDeg) -> mps|nil
   SelectRunwayByHeadwind(runways, wind) -> runway|nil, componentMps|nil
   FindNearestRunway(runways, point) -> runway|nil, distanceM|nil

``reciprocalSanityDeg`` defaults to 60 degrees. Each normalized directional runway is:

.. code-block:: lua

   {
       airbase = airbaseObject,
       airbaseName = string,
       name = string,
       key = airbaseName .. "|" .. name,
       headingDeg = number,
       lengthM = number,
       widthM = number,
       center = Vec3,
       threshold = Vec3,
       departureEnd = Vec3,
       forward = Vec2,
       right = Vec2,
       frame = HeadingFrame2D,
       sourceIndex = number,
       courseAdjusted = boolean,
   }

The raw runway position is the paved-surface center. Threshold and departure end are one half-length behind and ahead of that center. Normalization emits the primary direction and then the reciprocal direction for each valid source record. Reciprocal names swap L and R and retain C. Malformed records are skipped and logged.

``NormalizeDirectionalRunways`` leaves ``airbase`` nil because it has no airbase object input. ``GetDirectionalRunways`` sets that field to its airbase argument.

Lineup and glidepath minimum range defaults to 50 m. Positive lineup error is right of centerline. Headwind is the negative projection of wind onto the landing direction. Headwind and nearest-runway selection keep the first item on an exact tie.

``Airbase:getRunways()`` is an undocumented DCS compatibility boundary. It requires an in-simulator smoke test before release.

Flight and air data
-------------------

::

   AirRelativeVelocity(groundVelocity, windVelocity) -> Vec3|nil
   GetAerodynamicAngles(position3, airVelocity, minSpeedMps?) -> angles|nil
   CalculateIsaAtmosphere(altitudeM) -> airData|nil
   GetAirData(point) -> airData|nil
   MachFromTrueAirspeed(tasMps, temperatureK) -> mach|nil
   TrueAirspeedToCalibratedAirspeed(tasMps, temperatureK, pressurePa) -> casMps|nil

Aerodynamic angle calculations default to a 5 m/s minimum airspeed and return:

.. code-block:: lua

   {
       aoaDeg = number,
       betaDeg = number,
       trueAirspeedMps = number,
   }

Air-relative velocity is ground velocity minus wind velocity. The calculation projects that velocity onto the Position3 forward, up, and right axes. Angle of attack uses ``atan2(-up, forward)``. Sideslip uses ``atan2(right, forward)``.

Air-data records are:

.. code-block:: lua

   {
       temperatureK = number,
       pressurePa = number,
       densityKgM3 = number,
       speedOfSoundMps = number,
       source = HarnessConstants.AIR_DATA_SOURCE_DCS
             or HarnessConstants.AIR_DATA_SOURCE_ISA,
   }

``GetAirData`` prefers protected DCS atmosphere data and falls back to the International Standard Atmosphere (ISA). ISA supports 0 through 20 km, including the troposphere through 11 km and the isothermal layer above it. Values outside that range return ``nil``. Calibrated airspeed uses the subsonic isentropic pitot relation and rejects Mach values above 1.

The related constants are ``AIR_SPECIFIC_HEAT_RATIO``, ``DRY_AIR_GAS_CONSTANT_J_KG_K``, ``SEA_LEVEL_PRESSURE_PA``, ``SEA_LEVEL_DENSITY_KG_M3``, and ``SEA_LEVEL_TEMPERATURE_K``.

Enumeration and multiplayer
---------------------------

::

   GetAllAirbases() -> airbases|nil
   FindAirbasesWithin(airbases, point, radiusM) -> matches|nil
   GetAllPlayerUnits() -> units|nil
   GetPlayerIds() -> playerIds|nil
   GetPlayerInfos() -> playerInfos|nil
   FindPlayerInfosByName(name, playerInfos?) -> matches|nil
   GetWorldEventUnit(event) -> unit|nil, unitName|nil

``GetAllAirbases`` merges protected world and coalition enumeration, deduplicates by protected name, and sorts by name. It does not cache. ``FindAirbasesWithin`` requires the caller-supplied list and returns distance-sorted records:

.. code-block:: lua

   {
       {
           airbase = airbaseObject,
           distanceM = number,
       },
   }

``GetAllPlayerUnits`` queries neutral, red, and blue players without scanning groups. It deduplicates and sorts by protected unit name. Any coalition-query failure returns ``nil``.

``GetPlayerInfos`` omits and logs individual information failures. Exact duplicate names remain distinct records. Supplying ``playerInfos`` to ``FindPlayerInfosByName`` prevents another network query.

``GetWorldEventUnit`` checks ``event.initiator`` and then ``event.unit``. It protects ``getName`` and accepts stale handles with valid names.

Mission files
-------------

::

   GetMissionFileCapabilities() -> capabilities|nil, reason|nil
   SanitizeFilenameComponent(value, maxLength?) -> string
   EnsureMissionDirectory(relativeDirectory) -> absoluteDirectory|nil, reason|nil
   WriteMissionTextFile(relativePath, contents) -> absolutePath|nil, reason|nil
   WriteUniqueMissionTextFile(relativePath, contents, maxSuffix?) -> absolutePath|nil, reason|nil

The public capability record is:

.. code-block:: lua

   {
       writeDirectory = string,
   }

Capabilities require protected access to ``_G.io``, ``_G.lfs``, ``io.open``, ``lfs.writedir``, ``lfs.mkdir``, and ``lfs.attributes``. Harness never modifies ``MissionScripting.lua``. Relative paths use ``/`` and must remain below ``lfs.writedir()``. Absolute paths, drive prefixes, NULs, empty components, ``.`` and ``..`` are rejected.

``WriteMissionTextFile`` does not overwrite an existing target. ``WriteUniqueMissionTextFile`` tries the requested name and then ``-001`` through the caller limit, which defaults to 999. Open, write, flush, and close are protected independently.

Time-weighted statistics
------------------------

::

   TimeWeightedStats() -> stats
   stats:add(value, durationS, label?) -> boolean
   stats:count() -> integer
   stats:duration() -> number
   stats:mean() -> number|nil
   stats:rms() -> number|nil
   stats:min() -> number|nil
   stats:max() -> number|nil
   stats:peak() -> signedValue|nil, label|nil
   stats:reset() -> nil

The accumulator rejects nonnumeric values, NaN values, and nonpositive durations. Mean and root mean square are duration-weighted. Peak tracks the greatest absolute value while preserving its sign and label. State remains constant-size.
