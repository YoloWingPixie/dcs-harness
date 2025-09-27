#!/usr/bin/env python3
"""
Tiny helper to stamp HARNESS_VERSION inside dist/harness.lua after the bundle is built.

- Reads [project].version from pyproject.toml
- Replaces first HARNESS_VERSION = "..." if present
- Otherwise inserts a HARNESS_VERSION line near the top (after the first line
  if it starts with a log.info banner, else at the very beginning)
"""
from __future__ import annotations

import re
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
PYPROJECT = ROOT / "pyproject.toml"
DIST = ROOT / "dist" / "harness.lua"


def read_version(pyproject: Path) -> str:
    if not pyproject.exists():
        print("pyproject.toml not found", file=sys.stderr)
        sys.exit(2)
    version: str | None = None
    in_project = False
    for line in pyproject.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if s.startswith("[") and s.endswith("]"):
            in_project = (s.lower() == "[project]")
            continue
        if in_project and s.lower().startswith("version"):
            m = re.match(r"version\s*=\s*\"([^\"]+)\"", s)
            if m:
                version = m.group(1)
                break
    if not version:
        print("version not found in [project] of pyproject.toml", file=sys.stderr)
        sys.exit(2)
    return version


def stamp_version(dist_file: Path, version: str) -> None:
    if not dist_file.exists():
        print(f"dist file not found: {dist_file}", file=sys.stderr)
        sys.exit(2)

    text = dist_file.read_text(encoding="utf-8")

    # Case 1: Replace existing assignment
    pattern = re.compile(r'^\s*HARNESS_VERSION\s*=\s*".*?"\s*$', flags=re.MULTILINE)
    if pattern.search(text):
        new_text = pattern.sub(f'HARNESS_VERSION = "{version}"', text, count=1)
        if new_text != text:
            dist_file.write_text(new_text, encoding="utf-8")
            print(f"Updated HARNESS_VERSION to {version}")
            return

    # Case 2: Inject near the top
    lines = text.splitlines(True)
    insert_idx = 0
    if lines and lines[0].lstrip().startswith("if log and log.info"):
        insert_idx = 1
    lines.insert(insert_idx, f'HARNESS_VERSION = "{version}"\n')
    dist_file.write_text("".join(lines), encoding="utf-8")
    print(f"Inserted HARNESS_VERSION = {version}")


def main() -> int:
    version = read_version(PYPROJECT)
    stamp_version(DIST, version)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
