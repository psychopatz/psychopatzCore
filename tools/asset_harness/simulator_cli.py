#!/usr/bin/env python3
"""JSON command line client for the offline radio simulator."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from asset_harness.simulator import RadioSimulator, list_devices


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Drive the Psychopatz radio simulator with bounded JSON commands")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list", help="list simulator device definitions")

    snapshot = sub.add_parser("snapshot", help="print initial state")
    _add_device_args(snapshot)

    event = sub.add_parser("event", help="apply one or more JSON events")
    _add_device_args(event)
    event.add_argument("--json", action="append", required=True, help="JSON event object; repeat for a sequence")

    scenario = sub.add_parser("scenario", help="apply events from a JSON file")
    _add_device_args(scenario)
    scenario.add_argument("--file", type=Path, required=True)
    return parser


def _add_device_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--device", default="walkie_1")
    parser.add_argument("--variant", choices=("clean", "worn"), default="clean")


def _success(data: Any) -> int:
    print(json.dumps({"ok": True, "schema_version": 1, "data": data}, ensure_ascii=True, sort_keys=True))
    return 0


def _failure(error: Exception) -> int:
    print(json.dumps({"ok": False, "schema_version": 1, "error": {"type": type(error).__name__, "message": str(error)}}, ensure_ascii=True, sort_keys=True))
    return 1


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "list":
            return _success(
                {
                    "devices": [
                        {
                            "id": spec.id,
                            "label": spec.label,
                            "family": spec.family,
                            "full_type": spec.full_type,
                            "asset": str(spec.asset_path),
                            "asset_exists": spec.asset_exists,
                            "controls": [control.id for control in spec.controls],
                        }
                        for spec in list_devices()
                    ]
                }
            )

        simulator = RadioSimulator(args.device, variant=args.variant)
        if args.command == "snapshot":
            return _success(simulator.snapshot())
        if args.command == "event":
            for raw_event in args.json:
                event = json.loads(raw_event)
                simulator.dispatch(event)
            return _success(simulator.snapshot())
        if args.command == "scenario":
            scenario = json.loads(args.file.read_text(encoding="utf-8"))
            events = scenario.get("events") if isinstance(scenario, dict) else scenario
            if not isinstance(events, list):
                raise ValueError("scenario JSON must be an array or an object with an events array")
            for event in events:
                if not isinstance(event, dict):
                    raise ValueError("each scenario event must be a JSON object")
                simulator.dispatch(event)
            return _success(simulator.snapshot())
        raise ValueError(f"unsupported command: {args.command}")
    except (OSError, TypeError, ValueError, json.JSONDecodeError) as error:
        return _failure(error)


if __name__ == "__main__":
    raise SystemExit(main())
