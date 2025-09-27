# Harness

Harness is a drop-in, single-file thin wrapper for the DCS Mission Scripting Environment. It exposes the native API through pcall-guarded wrappers with structured logging and predictable error handling, plus a few performance-neutral helpers (read-through caching, standard data structures, drawing) so you can use the engine directly with greater safety and observability.

Harness is not intended to be a replacement for a mission scripting framework. The intent is, is that you get the functions you find yourself making for every mission without adopting background schedulers, databases, or hidden loops. Harness does nothing unless you ask it to, avoids mission halts on exceptions, and keeps calls fast by staying thin and close to the underlying API. A small read-through cache prevents hammering the engine on repeated lookups, and the whole library ships as a single file you can inject into any script.

## Quickstart

### Prerequisites

- Task (`https://taskfile.dev`) in PATH
- Lua in PATH (for running tests)
- Python 3.13 in PATH (for builds)

### Common tasks

```bash
# List available tasks
task help

# Run all tests
task test

# Run a single test file (path is relative to tests/)
task test:single -- test_vector.lua

# Watch mode (reruns tests on changes)
task test:watch

# Format source (vendored Stylua) / check formatting
task format
task format:check

# Lint sources (requires luacheck)
task lint

# Build developer artifact (formats first)
task build

# Build CI/CD artifact (no format step)
task build:cd

# Test coverage (requires luacov)
task coverage

# CI pipeline locally (format:check, lint, test, build:cd)
task ci
```

### Build artifact

After a successful build you will have:

- `dist/harness.lua` — the single-file library to include in your mission/mod

## Use in a mission/mod

Include `dist/harness.lua` before your script so its functions are available when your code runs.