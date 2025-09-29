#!/usr/bin/env python3
"""
Export Harness public API to a Selene standard library YAML.

This script scans Lua sources for globally-exposed functions (defined with
top-level `function Name(...)` definitions) and extracts their argument types
from EmmyLua-style annotations placed immediately above (`---@param`). It then
writes a Selene YAML file declaring those functions as globals so external
projects can type-check when using Harness helpers.

Notes:
- We default all arg types to `any` unless an `---@param` provides a type.
- We do not try to infer return types (Selene does not require them).
- We also declare certain top-level tables as `new-fields` when useful in the
  future; for now we focus on functions only.

Usage:
  python build/scripts/export_harness_selene.py \
    --src src \
    --output dist/harness-selene.yml
"""

from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple

try:
    import yaml  # type: ignore
except Exception as exc:  # noqa: BLE001
    raise RuntimeError(
        "PyYAML is required to export Selene YAML. Add pyyaml to dependencies."
    ) from exc


# Map simple Lua/Emmy types to Selene primitive names
PRIMITIVE_TYPE_MAP: Dict[str, str] = {
    "string": "string",
    "number": "number",
    "integer": "number",
    "bool": "bool",
    "boolean": "bool",
    "table": "table",
    "nil": "nil",
    "any": "any",
    "function": "function",
    "...": "...",
}


PARAM_RE = re.compile(r"^\s*---@param\s+(\w+)\s+([^\s]+)")
FUNC_DEF_RE = re.compile(r"^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")


@dataclass
class ParsedFunction:
    name: str
    arg_types: List[str]


def normalize_arg_type(type_string: str) -> Tuple[str, Any]:
    t = (type_string or "").strip()
    if not t:
        return ("primitive", "any")
    if t == "...":
        return ("primitive", "...")
    # union, tuple, arrays — keep as display
    if "|" in t or "," in t or "[" in t or "]" in t:
        return ("display", {"display": t})
    mapped = PRIMITIVE_TYPE_MAP.get(t.lower())
    if mapped is not None:
        return ("primitive", mapped)
    return ("display", {"display": t})


def build_function_args(param_type_list: Iterable[str]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for t in param_type_list:
        kind, value = normalize_arg_type(t)
        if kind == "primitive":
            out.append({"type": value})
        else:
            out.append({"type": value})
    return out


def parse_lua_public_functions(lua_path: Path) -> List[ParsedFunction]:
    """Parse a Lua file for global functions and associated @param types.

    Strategy:
      - Walk lines, collecting contiguous `---@param` lines and mapping to an
        ordered list of types by their appearance order.
      - When we hit a top-level `function Name(` definition, bind the previously
        collected param type list to this function and reset accumulator.
    """
    try:
        text = lua_path.read_text(encoding="utf-8")
    except Exception:
        return []

    lines = text.splitlines()
    pending_param_types: List[str] = []
    results: List[ParsedFunction] = []

    for line in lines:
        m_param = PARAM_RE.match(line)
        if m_param:
            # We only need the type order, name is not required for Selene
            type_str = m_param.group(2)
            pending_param_types.append(type_str)
            continue

        m_func = re.match(r"^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)", line)
        if m_func:
            fname = m_func.group(1)
            arglist = m_func.group(2).strip()
            argcount = 0
            if arglist:
                # count args; ignore trailing comments/spaces
                # handle varargs ... as single arg
                items = [a.strip() for a in arglist.split(",") if a.strip()]
                argcount = len(items)
            # Use pending param types in order, fill remainder with any
            types_for_args = list(pending_param_types[:argcount])
            while len(types_for_args) < argcount:
                types_for_args.append("any")
            results.append(ParsedFunction(name=fname, arg_types=types_for_args))
            pending_param_types = []
            continue

        # Reset pending when non-annotation non-blank encountered between blocks
        if pending_param_types and not line.strip().startswith("---") and not line.strip().startswith("--"):
            # a new chunk of code started; clear stale params to avoid mismatches
            pending_param_types = []

    return results


def collect_public_functions(src_dir: Path) -> List[ParsedFunction]:
    funcs: List[ParsedFunction] = []
    for p in sorted(src_dir.rglob("*.lua")):
        # Skip internal or header files by convention
        name = p.name.lower()
        if name.startswith("_"):
            continue
        funcs.extend(parse_lua_public_functions(p))
    return funcs


def export_selene_yaml(funcs: List[ParsedFunction]) -> Dict[str, Any]:
    globals_out: Dict[str, Any] = {}
    for f in funcs:
        key = f.name
        globals_out[key] = {"args": build_function_args(f.arg_types)}
    doc: Dict[str, Any] = {
        "base": "lua51",
        "name": "harness",
        "globals": globals_out,
    }
    return doc


def main() -> int:
    parser = argparse.ArgumentParser(description="Export Harness API to Selene YAML")
    parser.add_argument("--src", default="src", help="Source directory to scan")
    parser.add_argument(
        "--output", "-o", default="dist/harness-selene.yml", help="Output YAML file"
    )
    args = parser.parse_args()

    src_dir = Path(args.src).resolve()
    if not src_dir.exists() or not src_dir.is_dir():
        raise SystemExit(f"Source directory not found: {src_dir}")

    funcs = collect_public_functions(src_dir)
    data = export_selene_yaml(funcs)

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)
    print(f"Selene YAML exported to {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())



