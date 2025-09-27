# Harness

A pure utility library for DCS World scripting that provides validated wrapper functions around DCS APIs with consistent error handling and logging.

## Features

- **Pure Functions Only** - No scheduled tasks, no recurring actions, no initialization
- **Global Namespace** - All functions are generically named and placed in the global namespace
- **Validated API Calls** - Every DCS API call is wrapped with proper validation and pcall error handling
- **Configurable Logging** - Multiple DCS mods can use the same logger with their own namespace
- **Comprehensive Utilities** - Common patterns for units, groups, vectors, terrain, zones, time, flags, and more

## Installation

### Using Composer (Recommended)

1. Add harness as a dependency in your project
2. The composer will inject harness above your source code automatically

### Manual Installation

1. Download either `harness-global.lua` or `harness-scoped.lua` from the releases
2. Load it before your script in the mission editor

## Building

This project uses lua-composer for building:

```bash
# Build global version (all functions in global namespace)
lua-composer --config .composerrc

# Build scoped version (returns a Harness table)
lua-composer --config .composerrc-scoped
```

## Formatting

We vendor Stylua for consistent Lua formatting:

- Config: `.stylua.toml`
- Ignore: `.styluaignore`
- Binary: `stylua/stylua.exe`

Usage:

```bash
# Format all Lua sources
task format

# Check formatting (CI-safe)
task format:check
```

VS Code:

- Install the "Stylua" extension (`JohnnyMorganz.stylua`)
- Settings are preconfigured to use the vendored binary and format on save

## Usage

### Logger

The global `Log` object is available for all projects:

```lua
-- At the start of your script, set your project's namespace
Log = HarnessLogger("MyProject")

-- Then use Log throughout your code
Log.info("Starting up")
Log.warn("Something might be wrong", "FunctionName")
Log.error("Something went wrong", "FunctionName")
Log.debug("Debug information", "FunctionName")

-- Output: [MyProject]: Starting up
-- Output: [MyProject : FunctionName]: Something went wrong
```

You can also create additional loggers for different components:

```lua
-- Create separate loggers for different parts of your mod
local UILog = HarnessLogger("MyProject.UI")
local NetworkLog = HarnessLogger("MyProject.Network")
```

### Unit Functions

All unit functions validate inputs and handle errors gracefully:

```lua
-- Get unit safely
local unit = GetUnit("Pilot #001")

-- Check if unit exists
if UnitExists("Pilot #001") then
    -- Get unit properties
    local position = GetUnitPosition("Pilot #001")
    local heading = GetUnitHeading("Pilot #001")
    local velocity = GetUnitVelocity("Pilot #001")
    local type = GetUnitType("Pilot #001")
    local coalition = GetUnitCoalition("Pilot #001")
end
```

### Vector Operations

Comprehensive vector math utilities:

```lua
-- Create vectors
local pos1 = Vec3(100, 50, 200)
local pos2 = Vec3(200, 50, 300)

-- Vector operations
local direction = VecSub(pos2, pos1)
local distance = Distance(pos1, pos2)
local bearing = Bearing(pos1, pos2)

-- Get new position from bearing/distance
local newPos = FromBearingDistance(pos1, 45, 1000)
```

### Zone Operations

Work with trigger zones:

```lua
-- Check if unit is in zone
if IsUnitInZone("Pilot #001", "Zone1") then
    -- Do something
end

-- Get random point in zone
local randomPos = RandomPointInZone("Zone1")

-- Get all units in zone
local units = GetUnitsInZone("Zone1", coalition.side.BLUE)
```

### Message Functions

Send messages with validation:

```lua
-- Send to all
MessageToAll("Hello everyone!", 10)

-- Send to coalition
MessageToCoalition(coalition.side.BLUE, "Blue team message", 20)

-- Send to group
local groupId = GetGroupID("Alpha")
if groupId then
    MessageToGroup(groupId, "Group message", 15)
end
```

### Time Functions

Time and scheduling utilities:

```lua
-- Get formatted time
local timeStr = FormatTime(GetTime())  -- "01:23:45"

-- Schedule a function once (not recurring)
local function myFunction(args)
    print("Called with: " .. args.message)
end

local timerId = ScheduleOnce(myFunction, {message = "Hello"}, 10)

-- Cancel if needed
CancelSchedule(timerId)
```

### Flag Operations

User flag utilities:

```lua
-- Basic operations
SetFlag("myFlag", 10)
local value = GetFlag("myFlag")

-- Convenience functions
IncFlag("counter")
ToggleFlag("switch")

-- Comparisons
if IsFlagTrue("active") then
    -- Do something
end

if FlagBetween("score", 10, 20) then
    -- Score is between 10 and 20
end
```

## Function Categories

### Unit Functions
- `GetUnit`, `UnitExists`, `GetUnitPosition`, `GetUnitHeading`, `GetUnitVelocity`
- `GetUnitType`, `GetUnitCoalition`, `GetUnitCountry`, `GetUnitGroup`
- `GetUnitPlayerName`, `GetUnitLife`, `GetUnitFuel`, `IsUnitInAir`

### Group Functions
- `GetGroup`, `GroupExists`, `GetGroupUnits`, `GetGroupSize`
- `GetGroupCoalition`, `GetGroupCategory`, `GetGroupID`
- `ActivateGroup`, `GetCoalitionGroups`

### Vector Functions
- `Vec3`, `Vec2`, `IsVec3`, `IsVec2`, `ToVec3`, `ToVec2`
- `VecAdd`, `VecSub`, `VecScale`, `VecLength`, `VecNormalize`
- `Distance`, `Distance2D`, `Bearing`, `FromBearingDistance`

### Terrain Functions
- `GetTerrainHeight`, `GetAGL`, `SetAGL`, `HasLOS`
- `GetSurfaceType`, `IsOverWater`, `IsOverLand`
- `GetClosestRoadPoint`, `FindRoadPath`

### Zone Functions
- `GetZone`, `GetZonePosition`, `GetZoneRadius`, `IsInZone`
- `IsUnitInZone`, `IsGroupInZone`, `GetUnitsInZone`
- `RandomPointInZone`, `IsInPolygonZone`

### Time Functions
- `GetTime`, `GetAbsTime`, `FormatTime`, `IsNightTime`
- `ScheduleOnce`, `CancelSchedule`, `RescheduleFunction`

### Flag Functions
- `GetFlag`, `SetFlag`, `IncFlag`, `DecFlag`, `ToggleFlag`
- `IsFlagTrue`, `FlagEquals`, `FlagBetween`

### Misc Functions
- `DeepCopy`, `Contains`, `TableSize`, `Clamp`, `Lerp`, `Round`
- `RandomFloat`, `RandomInt`, `RandomChoice`, `Shuffle`
- `SplitString`, `TrimString`, `DegToRad`, `NormalizeAngle`

## Design Philosophy

1. **Validation First** - Every function validates its inputs
2. **Safe API Calls** - All DCS API calls use pcall
3. **Meaningful Returns** - Functions return nil/false on error, not cryptic errors
4. **Consistent Logging** - All errors are logged with function context
5. **No Side Effects** - Pure functions only, no hidden state or scheduling

## License

[Insert your license here]

## Contributing

Contributions are welcome! Please ensure all functions follow the established patterns:
- Validate all inputs
- Use pcall for DCS API calls
- Log errors with context
- Return meaningful values or nil
- Keep functions pure (no scheduling or state)