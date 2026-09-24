import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class MissionFileRealTests(unittest.TestCase):
    def test_native_file_bytes_publication_and_recovery(self):
        fixtures = Path(__file__).resolve().parent / "fixtures"
        with tempfile.TemporaryDirectory(prefix="harness-mission-") as directory:
            result = subprocess.run(
                [
                    os.environ.get("HARNESS_TEST_LUA", "lua"),
                    str(fixtures / "missionfile_real.lua"),
                    Path(directory).as_posix(),
                    sys.executable,
                    str(fixtures / "missionfile_fs.py"),
                ],
                cwd=fixtures.parent,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(
                (Path(directory) / "nested" / "result.txt").read_bytes(),
                b"published\n",
            )
            self.assertEqual(
                sorted(path.name for path in (Path(directory) / "nested").iterdir()),
                ["result-001.txt", "result.txt"],
            )
