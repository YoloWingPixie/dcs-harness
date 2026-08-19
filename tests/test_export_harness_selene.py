import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "build" / "scripts"))

from export_harness_selene import (
    collect_public_functions,
    export_selene_yaml,
    parse_lua_public_functions,
)


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

    def test_exports_harness_v1_globals(self):
        names = {function.name for function in collect_public_functions(PROJECT_ROOT / "src")}

        expected = {
            "HeadingVector2D",
            "GroundTrackFromVelocity",
            "HeadingFrame2D",
            "ProjectPointToHeadingFrame2D",
            "ProjectVectorToHeadingFrame2D",
            "GetReciprocalRunwayName",
            "NormalizeDirectionalRunways",
            "GetDirectionalRunways",
            "GetRunwayRelativePosition",
            "GetRunwayRelativeVelocity",
            "GetRunwayLineupError",
            "GetRunwayGlidepathAngle",
            "GetHeadwindComponent",
            "SelectRunwayByHeadwind",
            "FindNearestRunway",
            "GetUnitPosition3",
            "GetAttitudeFromPosition3",
            "AirRelativeVelocity",
            "GetAerodynamicAngles",
            "CalculateIsaAtmosphere",
            "GetAirData",
            "MachFromTrueAirspeed",
            "TrueAirspeedToCalibratedAirspeed",
            "GetUnitDrawArguments",
            "GetAllAirbases",
            "FindAirbasesWithin",
            "GetAllPlayerUnits",
            "GetPlayerIds",
            "GetPlayerInfos",
            "FindPlayerInfosByName",
            "GetWorldEventUnit",
            "GetMissionFileCapabilities",
            "SanitizeFilenameComponent",
            "EnsureMissionDirectory",
            "WriteMissionTextFile",
            "WriteUniqueMissionTextFile",
            "TimeWeightedStats",
        }
        self.assertEqual(expected - names, set())
        self.assertNotIn("GetPlayers", names)

    def test_exports_runtime_compatible_signatures(self):
        document = export_selene_yaml(collect_public_functions(PROJECT_ROOT / "src"))
        globals_ = document["globals"]

        self.assertEqual(globals_["ControllerSetROE"]["args"][1], {"type": "any"})
        self.assertEqual(globals_["ControllerSetAlarmState"]["args"][1], {"type": "any"})
        self.assertEqual(
            globals_["GeoGrid"]["args"],
            [
                {"type": "number", "required": False},
                {"type": "table"},
            ],
        )
        self.assertEqual(
            globals_["EventBus"]["args"],
            [{"type": "function", "required": False}],
        )

        executable = "selene.exe" if sys.platform == "win32" else "selene"
        selene = PROJECT_ROOT / "tools" / "selene" / executable
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            (temp_path / "harness.yml").write_text(
                yaml.safe_dump(document, sort_keys=False),
                encoding="utf-8",
            )
            (temp_path / "selene.toml").write_text(
                'std = "harness"\n\n[lints]\nunused_variable = "allow"\n',
                encoding="utf-8",
            )
            (temp_path / "supported_calls.lua").write_text(
                """local controller = {}
ControllerSetROE(controller, "WEAPON_HOLD")
ControllerSetAlarmState(controller, "RED")
local grid = GeoGrid(5000, { "Track", "Battery" })
local bus = EventBus()
""",
                encoding="utf-8",
            )
            result = subprocess.run(
                [str(selene), "supported_calls.lua"],
                cwd=temp_path,
                capture_output=True,
                text=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_does_not_export_lowercase_helpers(self):
        names = {function.name for function in collect_public_functions(PROJECT_ROOT / "src")}

        self.assertEqual({name for name in names if name[:1].islower()}, {"hPaToPa"})

    def test_concatenated_chunk_locals_are_unique(self):
        declarations: dict[str, list[str]] = {}
        pattern = re.compile(r"^local\s+(?:function\s+)?([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)

        for source_path in sorted((PROJECT_ROOT / "src").glob("*.lua")):
            for name in pattern.findall(source_path.read_text(encoding="utf-8")):
                declarations.setdefault(name, []).append(source_path.name)

        self.assertEqual(
            {name: files for name, files in declarations.items() if len(files) > 1},
            {},
        )


if __name__ == "__main__":
    unittest.main()
