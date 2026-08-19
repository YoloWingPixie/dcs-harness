import re
import sys
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "build" / "scripts"))

from export_harness_luals import export_luals_definition
from export_harness_selene import collect_public_functions


class ExportHarnessLuaLsTests(unittest.TestCase):
    def test_exports_definition_only_public_contract(self):
        definition = export_luals_definition(PROJECT_ROOT / "src")

        self.assertTrue(definition.startswith("---@meta _\n"))
        self.assertIn(
            '---@alias ROEAir "WEAPON_FREE"|"OPEN_FIRE_WEAPON_FREE"',
            definition,
        )
        self.assertIn("---@class GeoGrid", definition)
        self.assertIn("---@class Vec2", definition)
        self.assertIn("---@class Vec3", definition)
        self.assertIn("---@field add fun(self: GeoGrid", definition)
        self.assertIn("---@param keySelector function?", definition)
        self.assertIn("---@return table? values Values keyed by argument ID", definition)
        self.assertIn(
            "---@return boolean complete True only when every argument returned a number",
            definition,
        )
        self.assertIn("HARNESS_VERSION = nil", definition)
        self.assertIn("HarnessConstants = nil", definition)
        self.assertIn("HarnessWorldEventBus = nil", definition)
        self.assertIn("Log = nil", definition)
        self.assertIn("function LineToAll(markId, startPos, endPos", definition)

        source_names = {
            function.name
            for function in collect_public_functions(PROJECT_ROOT / "src")
        }
        definition_names = set(
            re.findall(
                r"^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
                definition,
                re.MULTILINE,
            )
        )

        self.assertEqual(definition_names, source_names)
        self.assertNotIn("VectorInternal", definition)
        self.assertNotIn("MissionFileInternal", definition)
        self.assertNotIn("_HarnessInternal", definition)
        self.assertNotIn("pcall(", definition)
        self.assertNotIn("require(", definition)

    def test_export_is_deterministic(self):
        first = export_luals_definition(PROJECT_ROOT / "src")
        second = export_luals_definition(PROJECT_ROOT / "src")

        self.assertEqual(first, second)

    def test_preserves_rich_luals_annotations(self):
        source = '''---@alias Mode "FIRST"|"SECOND"

---@class Result
---@field value number
local ResultPrototype = {}

---@param value number
---@return Result
---@overload fun(value: string): Result
function BuildResult(value)
    return { value = value }
end
'''
        with tempfile.TemporaryDirectory() as temp_dir:
            source_dir = Path(temp_dir)
            (source_dir / "result.lua").write_text(source, encoding="utf-8")

            definition = export_luals_definition(source_dir)

        self.assertIn('---@alias Mode "FIRST"|"SECOND"', definition)
        self.assertIn("---@class Result", definition)
        self.assertIn("---@field value number", definition)
        self.assertIn("---@return Result", definition)
        self.assertIn("---@overload fun(value: string): Result", definition)
        self.assertIn("function BuildResult(value) end", definition)
        self.assertNotIn("return { value = value }", definition)

    def test_committed_definition_matches_source(self):
        expected = export_luals_definition(PROJECT_ROOT / "src")
        actual = (PROJECT_ROOT / "dist" / "harness.d.lua").read_text(
            encoding="utf-8"
        )

        self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
