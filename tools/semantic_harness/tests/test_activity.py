"""Focused tests for bounded cross-process activity-log reading."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from semantic_harness.activity import ActivityLog


class ActivityLogTests(unittest.TestCase):
    def test_new_shared_events_reads_history_once_then_only_appends(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "activity.jsonl"
            writer = ActivityLog(path=path, client="writer")
            first = writer.record("worker", "ready", pid=101)
            second = writer.record("worker", "request", command="INPUT")
            reader = ActivityLog(path=path, client="gui")
            seen: set[str] = set()

            initial = reader.new_shared_events(seen)
            seen.update(str(event["eventID"]) for event in initial)
            self.assertEqual(
                [event["eventID"] for event in initial],
                [first["eventID"], second["eventID"]],
            )
            self.assertEqual(reader.new_shared_events(seen), [])

            third = writer.record("worker", "response", command="INPUT")
            appended = reader.new_shared_events(seen)
            self.assertEqual([event["eventID"] for event in appended], [third["eventID"]])

    def test_truncated_shared_file_resets_incremental_cursor(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "activity.jsonl"
            writer = ActivityLog(path=path, client="writer")
            writer.record("worker", "ready", pid=101)
            reader = ActivityLog(path=path, client="gui")
            reader.new_shared_events(set())

            path.write_text("", encoding="utf-8")
            replacement = writer.record("worker", "ready", pid=202)
            replacement_events = reader.new_shared_events(set())
            self.assertEqual(
                [event["eventID"] for event in replacement_events],
                [replacement["eventID"]],
            )


if __name__ == "__main__":
    unittest.main()
