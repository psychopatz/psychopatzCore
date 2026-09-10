import json
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from moddata_reader import GlobalModDataReader, ModDataFormatError


def pz_string(value: str) -> bytes:
    raw = value.encode("utf-8")
    return struct.pack(">h", len(raw)) + raw


def pz_value(value):
    if isinstance(value, str):
        return b"\x00" + pz_string(value)
    if isinstance(value, bool):
        return b"\x03" + bytes((1 if value else 0,))
    if isinstance(value, (int, float)):
        return b"\x01" + struct.pack(">d", float(value))
    if isinstance(value, list):
        return b"\x02" + pz_table([(index, item) for index, item in enumerate(value, 1)])
    if isinstance(value, dict):
        return b"\x02" + pz_table(list(value.items()))
    raise TypeError(value)


def pz_table(entries) -> bytes:
    output = [struct.pack(">i", len(entries))]
    for key, value in entries:
        if isinstance(key, str):
            output.extend((b"\x00", pz_string(key)))
        else:
            output.extend((b"\x01", struct.pack(">d", float(key))))
        output.append(pz_value(value))
    return b"".join(output)


def pz_file(tables, world_version=249) -> bytes:
    output = [struct.pack(">ii", world_version, len(tables))]
    for name, entries in tables:
        block = pz_string(name) + pz_table(entries)
        output.extend((struct.pack(">i", len(block)), block))
    return b"".join(output)


class ModDataReaderTests(unittest.TestCase):
    def write_fixture(self, tables):
        directory = tempfile.TemporaryDirectory()
        path = Path(directory.name) / "global_mod_data.bin"
        path.write_bytes(pz_file(tables))
        self.addCleanup(directory.cleanup)
        return path

    def test_index_and_bounded_chunks_preserve_pz_values(self):
        path = self.write_fixture([
            ("PNC_NPC_npc_1", [
                ("identity", {"name": "Dudley", "age": 42}),
                ("social", {"relationships": {"player": 36.5}}),
                ("alive", True),
                ("items", ["knife", "water"]),
                ("empty", {}),
            ]),
            ("PNC_Core_Global", [("schemaVersion", 3)]),
        ])
        with GlobalModDataReader(path) as reader:
            self.assertEqual(reader.world_version, 249)
            self.assertEqual(reader.table_count, 2)
            self.assertGreater(reader.index[0].block_size, 0)

            first = reader.inspect(npc="npc_1", chunk_index=0, chunk_size=2)
            self.assertEqual(first["chunk"], {"index": 0, "count": 3, "size": 2})
            self.assertEqual(first["data"]["identity"]["name"], "Dudley")
            self.assertEqual(first["data"]["identity"]["age"], 42)
            self.assertFalse(first["truncated"])

            third = reader.inspect(npc="npc_1", chunk_index=2, chunk_size=2)
            self.assertEqual(third["data"], {"empty": {}})

    def test_path_projection_and_numeric_arrays(self):
        path = self.write_fixture([
            ("PNC_NPC_npc_1", [
                ("social", {"relationships": {"player": 36.5}}),
                ("items", ["knife", "water"]),
            ]),
        ])
        with GlobalModDataReader(path) as reader:
            report = reader.inspect(npc="npc_1", path="social.relationships")
            self.assertEqual(report["data"], {
                "social": {"relationships": {"player": 36.5}}
            })

            table = reader.inspect(npc="npc_1", chunk_index=1, chunk_size=1)
            self.assertEqual(table["data"]["items"], ["knife", "water"])

    def test_summary_is_index_only_and_invalid_chunk_fails(self):
        path = self.write_fixture([
            ("PNC_NPC_npc_1", [("name", "Dudley")]),
            ("Other", [("value", 1)]),
        ])
        with GlobalModDataReader(path) as reader:
            summary = reader.summary(prefix="PNC_NPC")
            self.assertEqual(summary["npcIds"], ["npc_1"])
            self.assertNotIn("data", summary)
            with self.assertRaises(ModDataFormatError):
                reader.inspect(npc="npc_1", chunk_index=1, chunk_size=1)

    def test_safe_limits_mark_truncation_without_loading_unbounded_output(self):
        path = self.write_fixture([
            ("PNC_NPC_npc_1", [("values", {str(i): i for i in range(10)})]),
        ])
        with GlobalModDataReader(path) as reader:
            report = reader.inspect(npc="npc_1", max_items=2, max_nodes=50)
            self.assertTrue(report["truncated"])
            self.assertEqual(report["data"]["values"]["_profilerOmittedEntries"], 8)
            self.assertLess(len(json.dumps(report)), 3000)

    def test_cli_exposes_direct_reader_without_snapshot_or_process(self):
        path = self.write_fixture([
            ("PNC_NPC_npc_1", [("social", {"morale": 12.5})]),
        ])
        completed = subprocess.run([
            sys.executable, str(ROOT / "profiler_cli.py"), "persisted",
            "--save", str(path), "--npc", "npc_1",
            "--path", "social", "--token-budget", "1000",
        ], check=True, text=True, capture_output=True)
        parsed = json.loads(completed.stdout)
        self.assertEqual(parsed["source"], "persisted_global_mod_data")
        self.assertEqual(parsed["data"]["social"]["morale"], 12.5)


if __name__ == "__main__":
    unittest.main()
