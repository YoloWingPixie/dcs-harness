#!/usr/bin/env python3
"""
Generic Lua concatenation builder for Harness-like projects.

Configuration is supplied via a JSON ".buildrc" file at the project root.
Example .buildrc:
{
  "src_dir": "src",
  "dist_dir": "dist",
  "output": "dist/harness.lua",
  "prepend": ["src/_header.lua"],
  "module_roots": ["src"],
  "strip_requires": true,
  "exclude_globs": ["src/**/_*.lua"]
}

This script requires .buildrc to exist and will fail if required fields are missing.
Required fields: src_dir, dist_dir, output, module_roots.
Optional fields: prepend, strip_requires, exclude_globs.
"""

import json
import os
import re
import sys
from pathlib import Path
from collections import defaultdict
import re as _re2

REQUIRE_RE = re.compile(r"^\s*require\([\"\']([A-Za-z0-9_./-]+)[\"\']\)\s*$")
COMMENT_RE = re.compile(r"^\s*--")
BLANK_RE = re.compile(r"^\s*$")

# Resolve project root as the current working directory to allow generic usage
PROJECT_ROOT = Path.cwd()


def load_config(root: Path) -> dict:
    cfg_path = root / ".buildrc"
    if not cfg_path.exists():
        print("Error: .buildrc not found at project root.", file=sys.stderr)
        sys.exit(2)
    try:
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Failed to parse {cfg_path}: {exc}", file=sys.stderr)
        sys.exit(1)

    required_keys = ["src_dir", "dist_dir", "output", "module_roots"]
    missing = [k for k in required_keys if k not in cfg]
    if missing:
        print(f"Error: .buildrc missing required keys: {', '.join(missing)}", file=sys.stderr)
        sys.exit(2)

    return cfg


def read_project_info_from_pyproject(root: Path) -> tuple[str | None, str | None]:
    pyproject = root / "pyproject.toml"
    if not pyproject.exists():
        return None, None
    try:
        lines = pyproject.read_text(encoding="utf-8").splitlines()
    except Exception:
        return None, None
    in_project = False
    name: str | None = None
    version: str | None = None
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            in_project = stripped.lower() == "[project]"
            continue
        if in_project and stripped.lower().startswith("name"):
            m = re.match(r"name\s*=\s*\"([^\"]+)\"", stripped)
            if m:
                name = m.group(1)
                continue
        if in_project and stripped.lower().startswith("version"):
            m = re.match(r"version\s*=\s*\"([^\"]+)\"", stripped)
            if m:
                version = m.group(1)
                continue
    return name, version


def make_banner_comment(project_name: str | None, version: str | None) -> str:
    if project_name and version:
        return f"-- {project_name}: {version} loading...\n"
    if project_name:
        return f"-- {project_name} loading...\n"
    if version:
        return f"-- version: {version} loading...\n"
    return ""

# Modules treated as project-local if they map to a file under src
# Map 'foo.bar' => 'src/foo/bar.lua', 'foo/bar' => 'src/foo/bar.lua'

def module_to_path(mod: str, module_roots: list[str]) -> Path | None:
    rel = mod.replace(".", "/") + ".lua"
    for root in module_roots:
        p = (PROJECT_ROOT / root / rel).resolve()
        if p.exists():
            return p
    return None


def is_comment(line: str) -> bool:
    return bool(COMMENT_RE.match(line))


def is_blank(line: str) -> bool:
    return bool(BLANK_RE.match(line))


def is_require(line: str) -> str | None:
    m = REQUIRE_RE.match(line)
    return m.group(1) if m else None


def _header_end_index(lines: list[str]) -> int:
    i = 0
    # Skip leading blanks
    while i < len(lines) and is_blank(lines[i]):
        i += 1
    # If starts with block comment, skip until closing ']]'
    if i < len(lines) and "--[[" in lines[i]:
        while i < len(lines) and "]]" not in lines[i]:
            i += 1
        if i < len(lines):
            i += 1  # move past the line containing ']]'
    # After any block header, skip blanks and consecutive line comments (e.g., --- annotations)
    while i < len(lines) and is_blank(lines[i]):
        i += 1
    while i < len(lines) and is_comment(lines[i]):
        i += 1
    while i < len(lines) and is_blank(lines[i]):
        i += 1
    return i


def strip_initial_requires(content: str) -> str:
    lines = content.splitlines(True)
    i = _header_end_index(lines)
    j = i
    # Remove contiguous require lines (and any blank lines between them)
    while j < len(lines) and (is_require(lines[j]) or is_blank(lines[j])):
        j += 1
    if j > i:
        return "".join(lines[:i] + lines[j:])
    return content


def read_requires(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return []
    lines = text.splitlines()
    reqs: list[str] = []
    idx = _header_end_index(lines)
    # collect contiguous require lines (ignore blanks)
    while idx < len(lines):
        if is_blank(lines[idx]):
            idx += 1
            continue
        mod = is_require(lines[idx])
        if not mod:
            break
        reqs.append(mod)
        idx += 1
    return reqs


def discover_sources(src_dir: Path, exclude_globs: list[str] | None) -> list[Path]:
    files = list(sorted(src_dir.rglob("*.lua")))
    if exclude_globs:
        # simple glob-based exclusion
        excluded: set[Path] = set()
        for pattern in exclude_globs:
            excluded.update(set(src_dir.glob(pattern.replace(src_dir.as_posix() + "/", ""))))
        files = [p for p in files if p not in excluded]
    return files


def build_graph(files: list[Path], module_roots: list[str], header: Path | None) -> tuple[dict[Path, set[Path]], dict[Path, int]]:
    file_set = set(files)
    edges: dict[Path, set[Path]] = {f: set() for f in files if (not header or f != header)}
    indeg: dict[Path, int] = {f: 0 for f in files if (not header or f != header)}

    for f in files:
        if header and f == header:
            continue
        reqs = read_requires(f)
        for mod in reqs:
            dep_path = module_to_path(mod, module_roots)
            if dep_path and dep_path in file_set and (not header or dep_path != header):
                # Direction: dependency -> dependent (so dependency comes first)
                if f not in edges[dep_path]:
                    edges[dep_path].add(f)
                    indeg[f] += 1
            # Non-project requires are ignored for graph purposes
    return edges, indeg


def topo_sort(edges: dict[Path, set[Path]], indeg: dict[Path, int]) -> list[Path]:
    # Kahn's algorithm with stable, locality-preserving selection
    # Order zero-indegree by (directory path, filename)
    def key_fn(p: Path):
        return (str(p.parent), str(p))

    q = [p for p, d in indeg.items() if d == 0]
    q.sort(key=key_fn)
    out: list[Path] = []
    seen = set()

    while q:
        # pop the first (preserves locality)
        u = q.pop(0)
        out.append(u)
        seen.add(u)
        for v in sorted(edges[u], key=key_fn):
            indeg[v] -= 1
            if indeg[v] == 0:
                q.append(v)
                q.sort(key=key_fn)
    # append any leftover nodes (in case of cycles). Maintain input order.
    for p in edges.keys():
        if p not in out:
            out.append(p)
    return out


def write_output(config: dict, order: list[Path]) -> None:
    # Determine output path; allow absolute/relative path in "output"
    raw_output = config["output"]
    output_path = (PROJECT_ROOT / raw_output) if ("/" in raw_output or "\\" in raw_output) else ((PROJECT_ROOT / config["dist_dir"]) / raw_output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    parts: list[str] = []

    proj_name, proj_version = read_project_info_from_pyproject(PROJECT_ROOT)
    banner_comment = make_banner_comment(proj_name, proj_version)
    if banner_comment:
        parts.append(banner_comment)
    # Prepend files (if present), in order
    prepend_list = config.get("prepend")
    if prepend_list:
        for p in prepend_list:
            # Resolve relative to root first, else treat as relative to src_dir
            abs_p = (PROJECT_ROOT / p)
            if not abs_p.exists():
                abs_p = (PROJECT_ROOT / config["src_dir"] / p)
            if abs_p.exists():
                parts.append(f"-- ==== BEGIN: {abs_p.relative_to(PROJECT_ROOT)} ====\n")
                content = abs_p.read_text(encoding="utf-8")
                parts.append(content)
                parts.append(f"\n-- ==== END: {abs_p.relative_to(PROJECT_ROOT)} ====\n\n")

    # Concat sources
    for f in order:
        rel = f.relative_to(PROJECT_ROOT)
        parts.append(f"-- ==== BEGIN: {rel} ====\n")
        content = f.read_text(encoding="utf-8")
        if ("strip_requires" in config) and bool(config["strip_requires"]):
            content = strip_initial_requires(content)
        parts.append(content.rstrip() + "\n")
        parts.append(f"-- ==== END: {rel} ====\n\n")

    final_text = "".join(parts)
    # Safety net: remove any stray non-comment top-level require(...) lines
    if ("strip_requires" in config) and bool(config["strip_requires"]):
        final_text = _re2.sub(
            r"(?m)^(?!\s*--)\s*require\([\"']([A-Za-z0-9_./-]+)[\"']\)\s*(?:--.*)?\r?\n",
            "",
            final_text,
        )
    output_path.write_text(final_text, encoding="utf-8")


def main(argv: list[str]) -> int:
    cfg = load_config(PROJECT_ROOT)
    src_dir = (PROJECT_ROOT / cfg["src_dir"]).resolve()
    files = discover_sources(src_dir, cfg.get("exclude_globs"))
    if not files:
        print(f"No source files found under {src_dir}", file=sys.stderr)
        return 1

    header_path = None
    # If a header is listed in prepend and points under src, exclude from graph
    for p in cfg.get("prepend", []):
        hp = (PROJECT_ROOT / p)
        if not hp.exists():
            hp = (src_dir / p)
        if hp.exists() and hp.is_file() and str(hp).endswith("_header.lua"):
            header_path = hp
            break

    edges, indeg = build_graph(files, cfg["module_roots"], header_path)
    order = topo_sort(edges, indeg)
    write_output(cfg, order)
    raw_output = cfg["output"]
    out = ((PROJECT_ROOT / raw_output) if ("/" in raw_output or "\\" in raw_output) else ((PROJECT_ROOT / cfg["dist_dir"]) / raw_output)).resolve()
    print(f"Built {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
