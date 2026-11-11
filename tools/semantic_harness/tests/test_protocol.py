from __future__ import annotations

import unittest

from tools.semantic_harness.transport.protocol import (
    ProtocolError,
    decode_message,
    encode_request,
)


class ProtocolTests(unittest.TestCase):
    def test_request_round_trip(self) -> None:
        encoded = encode_request("request-1", "PING", {"value": "ok"})
        decoded = decode_message(encoded)
        self.assertEqual(decoded["protocolVersion"], 1)
        self.assertEqual(decoded["id"], "request-1")
        self.assertEqual(decoded["command"], "PING")
        self.assertEqual(decoded["payload"]["value"], "ok")

    def test_invalid_request_identity_fails(self) -> None:
        with self.assertRaisesRegex(ProtocolError, "request id"):
            encode_request("", "PING")

    def test_message_size_is_bounded(self) -> None:
        with self.assertRaisesRegex(ProtocolError, "message limit"):
            encode_request("request-1", "PING", {"text": "x" * 200}, max_bytes=64)

    def test_non_object_response_fails(self) -> None:
        with self.assertRaisesRegex(ProtocolError, "JSON object"):
            decode_message("[]")


if __name__ == "__main__":
    unittest.main()
