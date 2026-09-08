# Harness handoff implementation

All ten items are implemented. Public comments and the [API guide](api.rst) now
explain the tools for mission makers, with short examples and failure handling.
The final forced CI run passed 684 Lua tests and 10 Python tests. Live DCS and
native Windows checks remain pending.

## Purpose and scope

Implement the ten specifications in `medusa-v3/docs/specs/harness` from the sibling
Medusa checkout. The baseline is Harness commit `0c72894`. Medusa adoption,
release operations, and DCS configuration changes are outside this change.

Public API comments and examples address mission makers. They explain the task,
units, results, and failure handling. Algorithm and storage analysis belongs here.

## Contracts and plan

The supplied specifications are the requirements authority. H-COM-001–006 require
compatible public behavior, Lua 5.1, explicit calls and state lifetime, existing
module ownership, no production dependencies, and documented contracts.

1. Implement H-NUM and reproduce H-COORD/H-SAFE failures before correcting the
   native boundaries. Preserve receiver, argument, return, and logging contracts.
2. Implement H-OBJ, H-MISSION, H-SENSOR, H-CPA, and H-AREA with focused tests.
3. Implement H-FILE recovery and H-GRID resumable traversal with failure and
   mutation tests. Rebuild the public artifacts and complete verification.

This plan applies ARCH-002/014, FUNC-001–004/014/019, RQM-001–006,
TEST-003/006/008/019, TASK-004, and DCS-005/006/013/014/031/032.

## Acceptance and verification

| Item | Passing acceptance criteria | Source and evidence |
| --- | --- | --- |
| Resumable GeoGrid | H-GRID-AC-001–003 | [geogrid.lua](../src/geogrid.lua); [cursor tests](../tests/test_geogrid_cursor.lua) cover independent radius results, budgets, limits, mutations, output reuse, close/clear, and memory release. Existing grid tests also pass. |
| Object readers | H-OBJ-AC-001–003 | [object.lua](../src/object.lua); [object tests](../tests/test_object.lua) cover IDs, categories, copied vectors, invalid handles, and lookup/execution failures. Existing unit and boundary tests pass. |
| File replacement | H-FILE-AC-001–003 | [missionfile.lua](../src/missionfile.lua); [failure tests](../tests/test_missionfile_replace.lua) cover every publication/recovery stage, occupied work files, and failed cleanup. [Real-file test](../tests/test_missionfile_real.py) verifies bytes, replacement, and recovery. Existing create-only tests pass. |
| Mission unit index | H-MISSION-AC-001–003 | [mission.lua](../src/mission.lua); [mission tests](../tests/test_mission.lua) cover sparse categories, raw skills, malformed data, duplicates, explicit input, and isolation from later edits. |
| Sensor ranges | H-SENSOR-AC-001–003 | [unit.lua](../src/unit.lua); `TestSensorRanges` in [object tests](../tests/test_object.lua) covers independent fields, missing branches, invalid values, and unchanged input. |
| 3D closest approach | H-CPA-AC-001–003 | [geomath.lua](../src/geomath.lua); `TestCPA3D` in [geometry tests](../tests/test_geometry_handoff.lua) covers horizontal/vertical approach, misses, moving away, the speed threshold, invalid values, and overflow. Existing horizontal tests pass. |
| Circle coverage | H-AREA-AC-001–003 | [geomath.lua](../src/geomath.lua); `TestCircleCoveredArea` in [geometry tests](../tests/test_geometry_handoff.lua) covers analytic overlap, gaps, duplicates, containment, translations, invalid geometry, and overflow. Existing union-area tests pass. |
| Coordinate conversion | H-COORD-AC-001–003 | [coord.lua](../src/coord.lua); [boundary tests](../tests/test_native_boundary.lua) reproduce the lost-longitude defect, then verify tuple results, zero, invalid inputs, and failures. The corrected [native fixture](../tests/mock_dcs.lua) passes existing coordinate tests. |
| Protected wrappers | H-SAFE-AC-001–003 | Source review and [boundary tests](../tests/test_native_boundary.lua) cover throwing lookup and unprintable-error failures, failure returns, arguments, false values, and return positions. Existing wrapper suites pass. |
| Finite number | H-NUM-AC-001–002 | [misc.lua](../src/misc.lua); `TestFiniteNumber` in [misc tests](../tests/test_misc.lua), existing finite-vector tests, and dependency/duplicate-check inspection pass. |

Run focused suites through `task test:single -- test_runner.lua <suite>`, then
`task --force test` and `task --force ci`. Generate distribution, LuaLS, and Selene
definitions with `task build:cd`. Review the complete diff for H-COM-AC-001/002.

Completed checks:

- `task test:single`: all affected Lua suites passed. The coordinate and native
  lookup defects were observed failing before their fixes.
- `task test:files`: native Lua binary file I/O, publication, and recovery passed
  under an isolated real temporary directory. The lfs metadata adapter uses Python.
- `task test:exports`: five Selene and four LuaLS tests passed. A real Selene
  consumer checks the new functions and `GeoGridQueryStatus.MORE`.
- `task format` and `task --force ci`: passed. CI ran formatting,
  build, lint, all 684 Lua tests, all 10 Python tests, complexity analysis,
  another build, and the Lua 5.1 syntax check. No changed function exceeds the
  complexity warning ceiling. Two existing `_G` lint warnings remain in the
  mission-file capability probe.
- Distribution, LuaLS, and Selene files were generated by the build tasks.

The result satisfies H-COM-001–006 and the local acceptance criteria above.
The implementation follows ARCH-002/014, FUNC-001–004/014/019, TEST-003/006/008/019,
TASK-004, and DCS-005/006/013/014. DCS-031/032 require the pending simulator
comparisons to remain distinct from local fixture evidence.

## Risks and unavailable evidence

The wrapper refactor must preserve meaningful false and nil returns. File
replacement must retain old contents after publication or rollback failure.
GeoGrid traversal must not skip stationary matches when adjacent entries mutate.
Circle coverage must avoid cancellation from subtracting large union areas.

Live DCS object-identity and coordinate comparisons (H-OBJ-AC-004,
H-COORD-AC-004, H-COM-AC-003) are pending a recorded simulator build and mission.
Windows file replacement (H-FILE-AC-004) requires a native Windows runtime check.

Medusa adoption remains a separate change. Its grid adapter still needs the
nearest-visited-distance diagnostic, which this API does not return. Its sensor
adapter must address the existing case where an invalid preferred range suppresses
a valid fallback. Its closest-approach adapter must preserve its distance-first
return order when calling Harness's seconds-first function. Application callback
guards must be reviewed separately from guards around direct Harness calls.

## Implementation analysis

`CircleCoveredArea2D` integrates covered envelope arcs and exposed provider arcs
inside the envelope. It translates and scales around the envelope before computing
arc areas. Its time cost is O(n² log n), peak storage is O(n), and total temporary
allocation is O(n²), where n is the number of provider circles. A containing
provider returns the envelope area directly, without subtracting large unions.

`EstimateCPAToPoint3D` uses constant work and storage. The stationary threshold is
owned by `CPA_STATIONARY_SPEED_SQUARED`; inputs are never changed.

GeoGrid query creation stores the copied position and deduplicated types, without
reading cells. Each continuation charges one unit per cell, type-bucket, or entry
inspection. Clearing previous output takes additional O(output size) work.
The query stores at most O(types + maxResults) copied data. Grid entries form
linked bucket lists. Removal redirects any cursor waiting at that entry before
unlinking it, so stationary entries remain reachable without retained tombstones.
Moves and removals take additional O(retained cursors) work. Cursor state is kept
under weak keys; closing or finishing clears its data references.

The mission unit index takes O(mission size) construction work and storage.
Lookups copy only the selected scalar record and never revisit mission data.

File replacement uses one `.harness-tmp` name and one `.harness-backup` name next
to the target. Occupied work files cause failure without overwriting them. Native
rename is tried first; the backup path handles platforms that cannot replace an
existing target by rename. Cleanup errors after publication are logged and do not
change a successful result. Calls require a single writer and do not promise
power-loss durability or atomic visibility across the backup fallback.

Missing-path checks distinguish missing files from other metadata failures using
the errno result provided by [LuaFileSystem](https://raw.githubusercontent.com/lunarmodules/luafilesystem/master/src/lfs.c).
The real-file test uses Python filesystem metadata to provide the small lfs
interface because LuaFileSystem is unavailable locally. Lua itself performs the
binary writes, flushes, closes, renames, and removals.

## Changed files

- [CHANGELOG.md](../CHANGELOG.md)
- [Taskfile.yml](../Taskfile.yml)
- [build/scripts/export_harness_selene.py](../build/scripts/export_harness_selene.py)
- [dist/harness-selene.yml](../dist/harness-selene.yml)
- [dist/harness.d.lua](../dist/harness.d.lua)
- [dist/harness.lua](../dist/harness.lua)
- [docs/api.rst](../docs/api.rst)
- [docs/harness-handoff.md](../docs/harness-handoff.md)
- [src/airbase.lua](../src/airbase.lua)
- [src/atmosphere.lua](../src/atmosphere.lua)
- [src/cache.lua](../src/cache.lua)
- [src/coalition.lua](../src/coalition.lua)
- [src/controller.lua](../src/controller.lua)
- [src/coord.lua](../src/coord.lua)
- [src/drawing.lua](../src/drawing.lua)
- [src/eventbus.lua](../src/eventbus.lua)
- [src/flag.lua](../src/flag.lua)
- [src/geogrid.lua](../src/geogrid.lua)
- [src/geomath.lua](../src/geomath.lua)
- [src/group.lua](../src/group.lua)
- [src/logger.lua](../src/logger.lua)
- [src/misc.lua](../src/misc.lua)
- [src/mission.lua](../src/mission.lua)
- [src/missioncommands.lua](../src/missioncommands.lua)
- [src/missionfile.lua](../src/missionfile.lua)
- [src/net.lua](../src/net.lua)
- [src/object.lua](../src/object.lua)
- [src/spot.lua](../src/spot.lua)
- [src/staticobject.lua](../src/staticobject.lua)
- [src/terrain.lua](../src/terrain.lua)
- [src/time.lua](../src/time.lua)
- [src/trigger.lua](../src/trigger.lua)
- [src/unit.lua](../src/unit.lua)
- [src/vector.lua](../src/vector.lua)
- [src/weapon.lua](../src/weapon.lua)
- [src/world.lua](../src/world.lua)
- [src/zone.lua](../src/zone.lua)
- [tests/fixtures/missionfile_fs.py](../tests/fixtures/missionfile_fs.py)
- [tests/fixtures/missionfile_real.lua](../tests/fixtures/missionfile_real.lua)
- [tests/mock_dcs.lua](../tests/mock_dcs.lua)
- [tests/test_export_harness_selene.py](../tests/test_export_harness_selene.py)
- [tests/test_geogrid_cursor.lua](../tests/test_geogrid_cursor.lua)
- [tests/test_geometry_handoff.lua](../tests/test_geometry_handoff.lua)
- [tests/test_misc.lua](../tests/test_misc.lua)
- [tests/test_mission.lua](../tests/test_mission.lua)
- [tests/test_missionfile_real.py](../tests/test_missionfile_real.py)
- [tests/test_missionfile_replace.lua](../tests/test_missionfile_replace.lua)
- [tests/test_native_boundary.lua](../tests/test_native_boundary.lua)
- [tests/test_object.lua](../tests/test_object.lua)
- [tests/test_runner.lua](../tests/test_runner.lua)
- [tools/selene/dcs.yml](../tools/selene/dcs.yml)
