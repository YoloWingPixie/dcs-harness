#!/usr/bin/env python3
"""Export the Harness public API as a LuaLS definition file."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


PUBLIC_FUNCTION_RE = re.compile(r"^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
FUNCTION_SIGNATURE_RE = re.compile(
    r"^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\)\s*$",
    re.DOTALL,
)
CLASS_RE = re.compile(r"^---@class\s+([A-Za-z_][A-Za-z0-9_]*)")
TYPE_DEFINITION_RE = re.compile(r"^---@(?:alias|enum)\s+")
GLOBAL_ASSIGNMENT_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=")
TYPE_ANNOTATION_RE = re.compile(r"^---@type\s+")
PARAM_ANNOTATION_RE = re.compile(r"^---@param\s+([A-Za-z_][A-Za-z0-9_]*)\??\s+")


@dataclass(frozen=True)
class LuaLsFunction:
    name: str
    parameters: tuple[str, ...]
    documentation: tuple[str, ...]


@dataclass(frozen=True)
class LuaLsClass:
    name: str
    annotations: tuple[str, ...]


@dataclass(frozen=True)
class LuaLsGlobal:
    name: str
    annotations: tuple[str, ...]


def _documentation_before(lines: list[str], line_index: int) -> tuple[str, ...]:
    start = line_index
    while start > 0 and lines[start - 1].startswith("---"):
        start -= 1
    return tuple(lines[start:line_index])


def _normalize_documentation(lines: Iterable[str]) -> tuple[str, ...]:
    normalized: list[str] = []
    for line in lines:
        if line.startswith(("---@class", "---@field", "---@alias", "---@enum", "---@type")):
            continue
        if line.startswith("---@usage"):
            normalized.append("--- Usage:" + line[len("---@usage") :])
        else:
            normalized.append(line)
    return tuple(normalized)


def _public_parameters(
    parameters: tuple[str, ...], documentation: tuple[str, ...]
) -> tuple[str, ...]:
    documented = tuple(
        match.group(1)
        for line in documentation
        if (match := PARAM_ANNOTATION_RE.match(line))
    )
    if len(documented) == len(parameters):
        return documented
    return parameters


def _function_at(lines: list[str], line_index: int) -> tuple[LuaLsFunction, int]:
    signature_lines = [lines[line_index].strip()]
    last_index = line_index
    while ")" not in signature_lines[-1]:
        last_index += 1
        if last_index >= len(lines):
            raise ValueError(f"Incomplete function signature at line {line_index + 1}")
        signature_lines.append(lines[last_index].strip())

    signature = " ".join(signature_lines)
    match = FUNCTION_SIGNATURE_RE.match(signature)
    if not match:
        raise ValueError(f"Invalid public function signature at line {line_index + 1}: {signature}")

    parameters = tuple(
        parameter.strip()
        for parameter in match.group(2).split(",")
        if parameter.strip()
    )
    documentation = _normalize_documentation(_documentation_before(lines, line_index))
    return (
        LuaLsFunction(
            name=match.group(1),
            parameters=_public_parameters(parameters, documentation),
            documentation=documentation,
        ),
        last_index,
    )


def _read_sources(src_dir: Path) -> list[tuple[Path, list[str]]]:
    if not src_dir.is_dir():
        raise ValueError(f"Source directory not found: {src_dir}")
    return [
        (path, path.read_text(encoding="utf-8").splitlines())
        for path in sorted(src_dir.rglob("*.lua"))
    ]


def collect_luals_functions(
    sources: Iterable[tuple[Path, list[str]]],
) -> list[LuaLsFunction]:
    functions: list[LuaLsFunction] = []
    names: set[str] = set()
    for path, lines in sources:
        line_index = 0
        while line_index < len(lines):
            if PUBLIC_FUNCTION_RE.match(lines[line_index]):
                function, line_index = _function_at(lines, line_index)
                if function.name in names:
                    raise ValueError(f"Duplicate public function {function.name} in {path}")
                names.add(function.name)
                functions.append(function)
            line_index += 1
    return functions


def collect_luals_types(
    sources: Iterable[tuple[Path, list[str]]],
) -> tuple[list[str], list[LuaLsClass]]:
    aliases: list[str] = []
    classes: list[LuaLsClass] = []
    class_names: set[str] = set()
    for path, lines in sources:
        for line_index, line in enumerate(lines):
            if TYPE_DEFINITION_RE.match(line):
                aliases.append(line)
                continue

            match = CLASS_RE.match(line)
            if not match:
                continue
            name = match.group(1)
            if name == "HarnessInternal":
                continue
            if name in class_names:
                raise ValueError(f"Duplicate LuaLS class {name} in {path}")

            annotations = [line]
            field_index = line_index + 1
            while field_index < len(lines) and lines[field_index].startswith("---@field"):
                annotations.append(lines[field_index])
                field_index += 1
            class_names.add(name)
            classes.append(LuaLsClass(name=name, annotations=tuple(annotations)))
    return aliases, classes


def collect_luals_globals(
    sources: Iterable[tuple[Path, list[str]]],
) -> list[LuaLsGlobal]:
    globals_: list[LuaLsGlobal] = []
    names: set[str] = set()
    for path, lines in sources:
        for line_index, line in enumerate(lines):
            match = GLOBAL_ASSIGNMENT_RE.match(line)
            if not match or match.group(1).startswith("_"):
                continue
            documentation = _documentation_before(lines, line_index)
            annotations = tuple(
                annotation
                for annotation in documentation
                if TYPE_ANNOTATION_RE.match(annotation)
            )
            if not annotations:
                continue

            name = match.group(1)
            if name in names:
                raise ValueError(f"Duplicate annotated public global {name} in {path}")
            names.add(name)
            globals_.append(LuaLsGlobal(name=name, annotations=annotations))
    return globals_


def export_luals_definition(src_dir: Path) -> str:
    sources = _read_sources(src_dir)
    aliases, classes = collect_luals_types(sources)
    globals_ = collect_luals_globals(sources)
    functions = collect_luals_functions(sources)

    output = [
        "---@meta _",
        "--- Generated from Harness source annotations. Do not edit.",
        "",
    ]

    output.extend(aliases)
    if aliases:
        output.append("")

    for class_index, class_ in enumerate(classes, start=1):
        output.extend(class_.annotations)
        output.append(f"local __HarnessLuaLsType{class_index} = {{}}")
        output.append("")

    for global_ in globals_:
        output.extend(global_.annotations)
        output.append(f"{global_.name} = nil")
        output.append("")

    for function in functions:
        output.extend(function.documentation)
        output.append(f"function {function.name}({', '.join(function.parameters)}) end")
        output.append("")

    return "\n".join(output).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Export Harness API for LuaLS")
    parser.add_argument("--src", default="src", help="Source directory to scan")
    parser.add_argument(
        "--output", "-o", default="dist/harness.d.lua", help="Output definition file"
    )
    args = parser.parse_args()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        export_luals_definition(Path(args.src).resolve()),
        encoding="utf-8",
    )
    print(f"LuaLS definition exported to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
