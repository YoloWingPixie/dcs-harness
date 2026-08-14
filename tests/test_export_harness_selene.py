import sys
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "build" / "scripts"))

from export_harness_selene import parse_lua_public_functions


class ExportHarnessSeleneTests(unittest.TestCase):
    def test_parses_multiline_public_function(self):
        source = """---@param point table
---@param radius number?
function CreateFireAtPointTask(
    point,
    radius
)
end
"""
        with tempfile.TemporaryDirectory() as temp_dir:
            source_path = Path(temp_dir) / "controller.lua"
            source_path.write_text(source, encoding="utf-8")

            functions = parse_lua_public_functions(source_path)

        self.assertEqual(len(functions), 1)
        self.assertEqual(functions[0].name, "CreateFireAtPointTask")
        self.assertEqual(functions[0].arg_types, ["table", "number?"])


if __name__ == "__main__":
    unittest.main()
