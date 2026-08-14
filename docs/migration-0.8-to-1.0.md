# Harness 0.8 to 1.0 migration

| Area | Harness 0.8 | Harness 1.0 |
|---|---|---|
| Vec2 | `{x,z}` values were accepted and produced. | Vec2 uses DCS `{x,y}`. Vec3 remains `{x,y,z}`. |
| Bearing | Affected functions treated positive Z as north. | Positive X is north. East is Vec2 positive Y or Vec3 positive Z. |
| Displacement | Heading components followed the old axis interpretation. | `dx=cos(heading)*distance`; east displacement is `sin(heading)*distance`. |
| Wind heading | Wind direction used the old bearing convention. | Wind heading uses `atan2(wind.z, wind.x)`. |
| Terrain | Vec2-like tables could pass through without dimensional projection. | Land calls receive DCS Vec2 `{x,y}`. Empty and malformed tables are rejected. |
| Road results | Road points used `{x,z}`. | Road points use DCS Vec2 `{x,y}`. Native numeric argument order is unchanged. |
| Mission menus | Some wrappers forwarded path and caption in the wrong native order and documented numeric IDs. | Native calls receive caption before path and return native `Path` values. Root `nil` paths are supported. |
| Player lists | `GetPlayers` returned the native player ID list but was described as player information. | `GetPlayers` is removed. Use `GetPlayerIds` for IDs and `GetPlayerInfos` for records. |
