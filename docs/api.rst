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

Use ``IsFiniteNumber(value)`` to check a number before using it in a calculation.
It accepts zero, negatives, and fractions. It rejects strings, NaN (an invalid
arithmetic result), and infinity.

Use ``IsFiniteVec2`` or ``IsFiniteVec3`` to check a complete position or velocity.
They return ``false`` if a required coordinate is missing, is not a number, or is
NaN or infinity. Vec2 uses X/Y with no Z field. Vec3 uses X/Y/Z.
The existing ``IsVec2`` and ``IsVec3`` still check only the coordinate types.

.. code-block:: lua

   if IsFiniteVec3(position) then
       local ll = LOtoLL(position)
       if ll then
           env.info(string.format("Latitude %.4f, longitude %.4f", ll.latitude, ll.longitude))
       end
   end

``LOtoLL`` returns both coordinates in a new table. It returns ``nil`` if the
position is invalid, DCS cannot perform the conversion, or either result is
missing. Zero latitude or longitude is valid.

``ToVec2`` normalizes a Vec2 or projects Vec3 X/Z to Vec2 X/Y. Terrain calls use this projection before calling ``land.getHeight`` or ``land.getSurfaceType``. Terrain height keeps the established zero fallback. Invalid surface queries return ``nil``.

``Bearing`` and displacement accept DCS Vec2 or Vec3 values. They use these equations:

::

   heading = NormalizeAngle(deg(atan2(eastDelta, xDelta)))
   xDelta = cos(rad(heading)) * distance
   eastDelta = sin(rad(heading)) * distance

Road functions keep the native numeric DCS argument order and return DCS Vec2 values.

Read a detected unit or weapon
------------------------------

These functions take the object from a detection entry. They work with both units
and weapons. Check for ``nil`` because an object can disappear between reads.

.. code-block:: lua

   local object = detection.object
   local id = GetObjectID(object)
   local category = GetObjectCategory(object)
   local position = GetObjectPoint(object)
   local velocity = GetObjectVelocity(object)

``GetObjectID`` returns the object's ``id_`` value unchanged. It accepts a number
or a nonempty string. This is the ID used by detections. Mission Editor unit IDs
are available through ``MissionUnitIndex`` below.

``GetObjectCategory`` returns an ``Object.Category`` value. Position and velocity
are new ``{x, y, z}`` tables. Position uses meters, with altitude in Y. Velocity
uses meters per second. Invalid numbers cause the reader to return ``nil``.

Read a sensor's listed ranges
-----------------------------

Pass one sensor entry from ``GetUnitSensors`` to read its air-detection ranges.

.. code-block:: lua

   local ranges = ReadSensorAirDetectionRanges(sensor)
   if ranges then
       local headOnRange = ranges.upperHeadOn
       local maximalRange = ranges.maximal
   end

Both fields use meters. Either field can be absent. The function returns ``nil``
when neither range is usable. It leaves out zero, negative values, numeric strings,
NaN, and infinity. A bad head-on range does not remove a usable maximal range.

The function keeps both ranges so your mission can choose which to use. These are
the ranges listed by DCS; a target can still be undetected inside that distance.

Find the closest future distance
-------------------------------

``EstimateCPAToPoint3D`` tells you when a moving object will get closest to a fixed
point, including the difference in altitude. It assumes the object keeps its
current velocity.

.. code-block:: lua

   local position = Vec3(1000, 500, 0)
   local velocity = Vec3(-100, 0, 0)
   local fixedPoint = Vec3(0, 0, 0)
   local seconds, distance = EstimateCPAToPoint3D(position, velocity, fixedPoint)
   -- 10 seconds; closest distance is 500 meters.

The first result is seconds and the second is meters. An object moving away, or
slower than 0.001 m/s, returns zero seconds and its current distance. Invalid
inputs or a failed calculation return ``nil, nil``. Inputs are left unchanged.
The existing horizontal closest-approach functions keep their behavior.

Measure coverage of a circular area
----------------------------------

Use ``CircleCoveredArea2D`` to measure how much of one circle is covered by a list
of other circles. Overlap counts only once. Circle centers use ground X/Y
coordinates, and radii use meters.

.. code-block:: lua

   local areaToCover = { center = { x = 0, y = 0 }, radius = 1000 }
   local coverageCircles = {
       { center = { x = 500, y = 0 }, radius = 800 },
       { center = { x = -500, y = 0 }, radius = 800 },
   }
   local covered = CircleCoveredArea2D(areaToCover, coverageCircles)
   if covered then
       local percentCovered = 100 * covered / (math.pi * areaToCover.radius ^ 2)
   end

The result is square meters, from zero through the area of the first circle.
An empty list or no overlap returns zero. Invalid circles, gaps in the list, or
numbers too large for the calculation return ``nil``. The function leaves all
input tables unchanged and preserves gaps between circles.

The calculation does all its work when called. Your mission controls the number
of circles and how often to calculate coverage.

Spread a grid search across calls
--------------------------------

Use these GeoGrid methods when you want to limit search work in each mission
update. Add and update grid entries with the existing ``add`` and ``updatePosition``
methods. Entries can use your own IDs and type names.

.. code-block:: lua

   local grid = GeoGrid(1000, { "Unit" })
   grid:add("Unit", "Radar-1", Vec3(2000, 0, 500))

   local search, reason = grid:beginRadiusQuery(Vec3(), 5000, { "Unit" }, 100)
   local matches = {}

   -- Run this part during each update until the status changes from MORE.
   if search then
       local found, work, status = grid:continueRadiusQuery(search, 50, matches)
       for _, id in ipairs(matches) do
           env.info("Found " .. id)
       end
   end

The search above checks a ground radius of 5,000 meters and returns at most 100
IDs across all calls. Each call uses at most 50 search steps. A step checks a grid
square, an object type in that square, or an entry. A call can return no matches
and still need more work. Zero steps pauses the search.

.. list-table:: Search status
   :header-rows: 1

   * - Status
     - What to do
   * - ``GeoGridQueryStatus.MORE``
     - Process this call's matches, then call again with the same search.
   * - ``GeoGridQueryStatus.DONE``
     - The search finished.
   * - ``GeoGridQueryStatus.LIMIT``
     - The result limit was reached. Other matches may still exist.
   * - ``GeoGridQueryStatus.CLOSED``
     - The search was stopped or the grid was cleared.
   * - ``GeoGridQueryStatus.INVALID``
     - Check the search, step count, and output table. The search must belong to this grid.

Each call clears the previous entries from ``matches`` and reuses the same table.
Finished or stopped searches return no more IDs. A search never returns the same
ID twice. Each returned entry matches when checked, but an object added or moved
during the search may be included or missed.

The center and type list are copied when the search starts. Type lists must have
no gaps and must use types registered with the grid. Invalid inputs or coordinates
too large for the grid return ``nil, reason`` from ``beginRadiusQuery``.
Call ``grid:closeRadiusQuery(search)`` when you no longer need a search.
``grid:clear()`` stops all searches on that grid.

Look up Mission Editor settings
-------------------------------

Build this lookup once during mission setup, then get a unit's settings by its
Mission Editor name. It includes aircraft, helicopters, vehicles, ships, and static
objects from all coalitions.

.. code-block:: lua

   local units, reason = MissionUnitIndex()
   if units then
       local radar = units:get("SAM Radar")
       if radar then
           local skill = radar.skill
           local editorId = radar.unitId
       end
   end

Available fields are ``name``, ``unitId``, ``typeName``, ``skill``, ``category``,
``countryId``, and ``coalition``. Missing or invalid optional fields are left out.
Skill keeps the editor text, including ``Random``, ``Player``, and ``Client``.

``MissionUnitIndex()`` reads ``env.mission``. You can pass another mission table
explicitly. Missing mission data or duplicate unit names return ``nil, reason``.
Unknown names return ``nil`` from ``get``. Each result is a new table you can edit.

Later spawns and changes to the mission table do not update the lookup. Call
``MissionUnitIndex`` again when you want to rebuild it.

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
   ReplaceMissionTextFile(relativePath, contents) -> absolutePath|nil, reason|nil, recoveryPath|nil

The public capability record is:

.. code-block:: lua

   {
       writeDirectory = string,
   }

These tools write below the DCS Saved Games directory returned by
``lfs.writedir()``. Use a path such as ``Reports/status.txt``, with ``/`` between
folders. Absolute paths, drive prefixes, empty folder names, ``.`` and ``..`` are
rejected. File paths cannot contain NUL bytes.

File access must already be available in your mission environment. If the required
``io`` or ``lfs`` functions are missing, the tools return ``nil`` and a reason.
Harness leaves ``MissionScripting.lua`` and your DCS configuration unchanged.

``WriteMissionTextFile`` does not overwrite an existing target. ``WriteUniqueMissionTextFile`` tries the requested name and then ``-001`` through the caller limit, which defaults to 999. Open, write, flush, and close are protected independently.

Use ``ReplaceMissionTextFile`` when you want to update a report at the same path:

.. code-block:: lua

   local path, reason, recoveryPath = ReplaceMissionTextFile(
       "Reports/status.txt",
       "Mission running\n"
   )
   if not path then
       local log = HarnessLogger("MissionReport")
       log.error(reason)
       if recoveryPath then
           log.error("The previous file is at " .. recoveryPath)
       end
   end

The file contains exactly the bytes you supply, including your line endings.
An empty string saves an empty file. The save also requires ``os.rename`` and
``os.remove``. Use one writer for each file path.

If saving fails, the previous contents remain at the original path or at the
returned ``recoveryPath``. Existing ``.harness-tmp`` and ``.harness-backup`` files
are left untouched and cause a conflict. If the new file was saved but cleanup
failed, the save still succeeds and the cleanup problem is logged.

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
