# ADR 0001: DCS coordinate and compatibility boundaries

- Status: Accepted for implementation; in-simulator release gate pending
- Date: 2026-08-13
- Target: Harness 1.0.0

## Context

Harness is built from separate source files, concatenated into one Lua chunk, and loaded into the DCS Mission Scripting Environment. Public Harness functions are globals. Source-file boundaries do not create Lua module scopes in the generated artifact.

Harness 0.8 used an inconsistent ground-plane convention. Some functions and examples treated positive Z as north. A proposed 1.0 plan also described a Harness-specific Vec2 `{x,z}` that would be converted to a native DCS Vec2 `{x,y}` at selected API boundaries. That representation would not implement the DCS Vec2 contract directly.

The official DCS coordinate contract defines Vec2 with `{x,y}` and Vec3 with `{x,y,z}`. In world coordinates, X points north, Vec3 Y is altitude, and Vec3 Z points east. A ground projection maps Vec3 X to Vec2 X and Vec3 Z to Vec2 Y.

The current official DCS class reference does not document `Airbase:getRunways()`. The working F-16 Landing Trainer uses it, so Harness can expose it only as an explicit compatibility boundary.

## Decision

1. Harness shall implement the DCS vector representations directly.
   - Vec2 is `{x,y}`.
   - Vec3 is `{x,y,z}`.
   - Harness shall not expose a distinct `{x,z}` Vec2 representation.
2. `ToVec2` shall copy a Vec2 or project Vec3 X/Z to Vec2 X/Y.
3. World headings shall use positive X as zero degrees and east as 90 degrees.
   - Vec2 east is positive Y.
   - Vec3 east is positive Z.
4. Harness 1.0 shall intentionally break the affected 0.8 bearing, displacement, wind-heading, road-result, shape, and 2D-query semantics.
5. New private helper sets shall use one uniquely named local table per capability. This prevents helper fields from entering `_G`, avoids generic local-name collisions in the concatenated chunk, and limits chunk-level local variables.
6. `Airbase:getRunways()` shall remain a protected compatibility call.

## Consequences

- Existing callers that use `{x,z}` as a Vec2 must migrate to `{x,y}`.
- Vec3 world points retain `{x,y,z}` and preserve altitude in Y.
- Land APIs and road numeric APIs receive native Vec2 coordinates.
- Heading vectors and runway forward/right vectors are Vec2 values with X and Y fields.
- Local mock tests can verify mapping, validation, ordering, and failure handling. They cannot prove the undocumented runway compatibility call or other in-simulator behavior.

## Standards mapping

This decision applies ARCH-002, ARCH-003, ARCH-005, ARCH-014, ARCH-015, ARCH-027, DCS-002, DCS-005, DCS-008, DCS-013 through DCS-021, and TEST-001 through TEST-019. The project-specific DCS vector contract in this ADR is authoritative where an earlier implementation plan proposed a Harness-specific Vec2 representation.

## In-simulator release gate

Harness 1.0 must not be released until a supported DCS build records the following results. Local mocks are not integration evidence.

| Check | DCS build | Result |
|---|---|---|
| Terrain height at a field above sea level | Not recorded | Not run |
| Positive-X north and positive-Z east world bearing behavior | Not recorded | Not run |
| Global, coalition, and group F10 menus | Not recorded | Not run |
| Unit text using a multiplayer client unit ID | Not recorded | Not run |
| Remote-client Position3, velocity, and draw arguments | Not recorded | Not run |
| Player enumeration for local and remote clients | Not recorded | Not run |
| Directional runways at a single-runway field | Not recorded | Not run |
| Directional runways at a parallel-runway field | Not recorded | Not run |
| Directional runways at an L/R runway pair | Not recorded | Not run |
| Sanitized mission-file failure without mission interruption | Not recorded | Not run |
| Desanitized write confinement below Saved Games | Not recorded | Not run |
| Continued timer and event execution after failed boundary calls | Not recorded | Not run |

## References

- [DCS coordinate types](https://www.digitalcombatsimulator.com/en/support/faq/1256/)
- [DCS singleton APIs](https://www.digitalcombatsimulator.com/en/support/faq/1257/)
