Overview
========

Harness provides validated wrappers around DCS World scripting APIs with consistent error handling and structured logging. It aims to be performance-neutral and avoids introducing heavy abstractions.

Key Principles
--------------

- Validate inputs strictly and convert user-friendly enums to engine constants.
- Use pcall-guarded calls into the DCS API with clear, actionable logging.
- Keep public API names PascalCase and consistent; eliminate magic numbers via constants.
- Prefer early returns and DRY, centralized helpers.

Getting Started
---------------

Refer to the project README for build and usage instructions. This site will expand with API references generated from the source using sphinx-lua.


