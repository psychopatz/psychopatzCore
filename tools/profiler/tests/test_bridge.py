import json
import tempfile
import time
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from bridge.client import BridgeClient
from bridge.config import BridgeConfig, parse_bridge_config, read_bridge_config, write_bridge_config
from bridge.errors import BridgeBusyError, BridgeProtocolError
from bridge.models import BridgeRequest, BridgeResponse
from bridge.transport import FileBridgeTransport, MAX_REQUEST_BYTES, SLOT_COUNT


class BridgeProtocolTests(unittest.TestCase):
    def test_valid_request_and_response(self):
        request = BridgeRequest("psychopatzcore.bridge", "ping", {})
        payload = request.to_dict()
        self.assertEqual(payload["protocol_version"], 1)
        response = BridgeResponse.from_dict({
            "message_type": "response", "protocol_version": 1,
            "request_id": request.request_id, "runtime_id": "runtime-a",
            "status": "ok", "result": {"alive": True}, "error": None,
        })
        self.assertTrue(response.result["alive"])

    def test_invalid_request_shapes(self):
        with self.assertRaises(BridgeProtocolError):
            BridgeRequest("bad namespace!", "ping").to_dict()
        with self.assertRaises(BridgeProtocolError):
            BridgeRequest("valid.namespace", "ping", protocol_version=9).to_dict()
        with self.assertRaises(BridgeProtocolError):
            BridgeResponse.from_dict({"protocol_version": 1})

    def test_unknown_command_error_shape(self):
        response = BridgeResponse.from_dict({
            "protocol_version": 1, "request_id": "abcdef123456",
            "runtime_id": "r", "status": "error", "result": None,
            "error": {"code": "UNKNOWN_COMMAND", "message": "not registered"},
        })
        self.assertEqual(response.error["code"], "UNKNOWN_COMMAND")


class FileTransportTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.transport = FileBridgeTransport(Path(self.directory.name))
        self.transport.ensure_directories()

    def tearDown(self):
        self.directory.cleanup()

    def test_atomic_submit_response_and_duplicate_protection(self):
        request = BridgeRequest("psychopatzcore.bridge", "ping")
        slot = self.transport.submit(request)
        request_path = self.transport.requests / f"slot-{slot:02d}.json"
        self.assertEqual(json.loads(request_path.read_text())["request_id"], request.request_id)
        response_path = self.transport.responses / f"slot-{slot:02d}.json"
        response_path.write_text(json.dumps({
            "protocol_version": 1, "request_id": request.request_id,
            "runtime_id": "runtime-a", "status": "ok", "result": {}, "error": None,
        }))
        (self.transport.responses / f"slot-{slot:02d}.ready.txt").write_text("ready")
        self.assertEqual(self.transport.read_response(slot, request.request_id).runtime_id, "runtime-a")
        self.transport.release(slot)
        self.assertFalse(request_path.exists())

    def test_two_clients_claim_different_slots(self):
        second = FileBridgeTransport(Path(self.directory.name))
        first_slot = self.transport.submit(BridgeRequest("psychopatzcore.bridge", "ping"))
        second_slot = second.submit(BridgeRequest("psychopatzcore.bridge", "ping"))
        self.assertNotEqual(first_slot, second_slot)
        self.transport.release(first_slot)
        second.release(second_slot)

    def test_partial_malformed_and_stale_response(self):
        request = BridgeRequest("psychopatzcore.bridge", "ping")
        slot = self.transport.submit(request)
        name = f"slot-{slot:02d}"
        (self.transport.responses / f"{name}.ready.txt").write_text("ready")
        with self.assertRaises(BridgeProtocolError):
            self.transport.read_response(slot, request.request_id)
        (self.transport.responses / f"{name}.json").write_text("{")
        with self.assertRaises(BridgeProtocolError):
            self.transport.read_response(slot, request.request_id)
        (self.transport.responses / f"{name}.json").write_text(json.dumps({
            "protocol_version": 1, "request_id": "different1",
            "runtime_id": "old", "status": "ok", "result": {}, "error": None,
        }))
        with self.assertRaises(BridgeProtocolError):
            self.transport.read_response(slot, request.request_id)

    def test_oversized_queue_and_cleanup(self):
        with self.assertRaises(BridgeProtocolError):
            self.transport._atomic_json(self.transport.requests / "large.json",
                                        {"value": "x" * MAX_REQUEST_BYTES}, MAX_REQUEST_BYTES)
        for _ in range(SLOT_COUNT):
            self.transport.submit(BridgeRequest("psychopatzcore.bridge", "ping"))
        with self.assertRaises(BridgeBusyError):
            self.transport.submit(BridgeRequest("psychopatzcore.bridge", "ping"))
        old = time.time() - 3600
        for path in self.transport.requests.iterdir():
            path.touch()
            import os
            os.utime(path, (old, old))
        self.assertEqual(self.transport.cleanup(max_files=2), 2)

    def test_runtime_state_and_unknown_fields(self):
        (self.transport.state / "runtime.json").write_text(json.dumps({
            "protocol_version": 1, "runtime_id": "current", "future": {"ok": True},
            "namespaces": {},
        }))
        (self.transport.state / "runtime.ready.txt").write_text("ready")
        self.assertIsNone(self.transport.read_runtime())
        (self.transport.state / "runtime.ready.txt").write_text("current")
        self.assertEqual(self.transport.read_runtime()["runtime_id"], "current")


class BridgeClientTests(unittest.TestCase):
    def test_submit_is_non_blocking_poll_reconnect_and_timeout(self):
        with tempfile.TemporaryDirectory() as directory:
            transport = FileBridgeTransport(Path(directory))
            client = BridgeClient(transport)
            self.assertIsNone(client.refresh_runtime())
            request_id = client.submit("psychopatzcore.bridge", "ping", timeout_seconds=0.01)
            self.assertIn(request_id, client.pending)
            time.sleep(0.12)
            self.assertEqual(client.poll(), [])
            self.assertEqual(client.failures[request_id], "TIMEOUT")
            transport.ensure_directories()
            (transport.state / "runtime.json").write_text(json.dumps({
                "protocol_version": 1, "runtime_id": "new", "namespaces": {},
            }))
            (transport.state / "runtime.ready.txt").write_text("new")
            self.assertEqual(client.refresh_runtime()["runtime_id"], "new")


class BridgeConfigTests(unittest.TestCase):
    def test_default_off_round_trip_and_fingerprint(self):
        self.assertFalse(parse_bridge_config("").enabled)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bridge.txt"
            config = BridgeConfig(enabled=True, poll_interval_ms=375)
            write_bridge_config(config, path)
            loaded = read_bridge_config(path)
            self.assertEqual(loaded, config)
            self.assertEqual(loaded.fingerprint, "v1|true|file|375")


if __name__ == "__main__":
    unittest.main()
