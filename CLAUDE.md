# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Harness is a pure utility library for DCS World scripting that provides:
- Validated wrapper functions around DCS APIs with proper error handling
- Consistent logging across multiple DCS mods/applications
- Common utility functions that follow DCS scripting patterns
- No scheduled tasks or initialization actions - pure functions only

## Key Design Principles

1. **Pure Library** - No scheduled tasks, no recurring actions, no init functions
2. **Global Namespace** - All functions are generically named and placed in the global namespace
3. **Shared Logger** - Multiple DCS mods can use the same logger with their own namespace
4. **Validation & Error Handling** - All DCS API calls are wrapped with pcall and proper validation
5. **Consistent Pattern** - All functions follow: validate args → pcall DCS API → log result → return

## Code Architecture

```
Harness/
├── src/
│   ├── _header.lua      -- Header with version and namespace setup
│   ├── logger.lua       -- Configurable logging system
│   ├── unit.lua         -- Unit-related utilities
│   ├── group.lua        -- Group-related utilities
│   ├── vector.lua       -- Vector/coordinate utilities
│   ├── terrain.lua      -- Terrain/land utilities
│   ├── zone.lua         -- Zone utilities
│   ├── time.lua         -- Time and scheduling utilities
│   ├── flag.lua         -- Flag utilities
│   └── misc.lua         -- Miscellaneous utilities
├── build/
│   ├── harness-global.lua    -- Built file with global functions
│   └── harness-scoped.lua    -- Built file with local scope
├── .composerrc              -- Global build configuration
└── .composerrc-scoped       -- Scoped build configuration
```

## Build Process

The project uses two build configurations:

1. **Global Build** (`.composerrc`) - Produces `harness-global.lua` with all functions in global namespace
2. **Scoped Build** (`.composerrc-scoped`) - Produces `harness-scoped.lua` that returns a table

Build commands:
```bash
# Build global version
lua-composer --config .composerrc

# Build scoped version  
lua-composer --config .composerrc-scoped
```

## Module Pattern

Each module follows this pattern:
```lua
-- Validate arguments
if not arg or type(arg) ~= "expectedType" then
    Harness.Logger.error("Function requires valid argument", "ModuleName.FunctionName")
    return nil
end

-- Safe API call
local success, result = pcall(dcs.api.function, arg)
if not success then
    Harness.Logger.error("API call failed: " .. tostring(result), "ModuleName.FunctionName")
    return nil
end

-- Return result
return result
```

## Logger Usage

The logger supports namespaced logging for different mods:
```lua
-- Set up logger for your mod
local myLogger = Harness.Logger.new("MyModName")
myLogger.info("Starting up")
myLogger.error("Something went wrong", "FunctionName")
```

## Current State

The repository contains:
- Basic project structure
- Logger module with namespace support
- Validated wrappers for common DCS APIs
- Comprehensive utility functions from the provided utils file