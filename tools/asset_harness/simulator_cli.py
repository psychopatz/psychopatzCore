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

from asset_harness.simulator import RadioSimulator
from asset_harness.simulator.registry import list_project_refs, project_path_for_device
from asset_harness.simulator.render import render_device
from asset_harness.core.render import save_png


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Drive the Psychopatz radio simulator with bounded JSON commands")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list", help="list canonical authored radio pilot projects")

    snapshot = sub.add_parser("snapshot", help="print initial state")
    _add_device_args(snapshot)

    event = sub.add_parser("event", help="apply one or more JSON events")
    _add_device_args(event)
    event.add_argument("--json", action="append", required=True, help="JSON event object; repeat for a sequence")

    scenario = sub.add_parser("scenario", help="apply events from a JSON file")
    _add_device_args(scenario)
    scenario.add_argument("--file", type=Path, required=True)

    render = sub.add_parser("render", help="render the current simulator state to a PNG")
    _add_device_args(render)
    render.add_argument("--out", type=Path, required=True, help="PNG output path")
    render.add_argument("--zoom", type=float, default=1.0)
    render.add_argument("--debug", action="store_true", help="draw LCD and physical hitbox overlays")
    return parser


def _add_device_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--device", default="walkie_1")
    parser.add_argument("--variant", choices=("clean", "worn", "pristine", "damaged"), default="clean")
    parser.add_argument("--project", type=Path, default=None, help="load an explicit modular project JSON")


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
            devices = []
            for project_ref in list_project_refs():
                simulator = RadioSimulator(project_path=project_ref.path, variant="clean")
                device = simulator.device
                devices.append(
                    {
                        "id": project_ref.device_id,
                        "label": project_ref.label,
                        "family": project_ref.family,
                        "full_type": project_ref.full_type,
                        "asset": str(device.asset_path),
                        "asset_exists": device.asset_exists,
                        "source_layout": "single_canvas",
                        "variant_art_status": "modular_project_preview",
                        "project": str(project_ref.path),
                        "controls": [control.id for control in simulator.geometry.controls],
                    }
                )
            return _success({"devices": devices})

        project_path = args.project or project_path_for_device(args.device)
        if project_path is None:
            raise ValueError(
                f"no canonical radio pilot project exists for device {args.device!r}; "
                "pass --project with an authored modular project"
            )
        simulator = RadioSimulator(project_path=project_path, variant=args.variant)
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
        if args.command == "render":
            image, metadata = render_device(simulator, zoom=args.zoom, debug=args.debug)
            output = save_png(image, args.out)
            return _success(
                {
                    "output": str(output),
                    "image_size": list(image.size),
                    "metadata": metadata,
                }
            )
        raise ValueError(f"unsupported command: {args.command}")
    except (OSError, TypeError, ValueError, json.JSONDecodeError) as error:
        return _failure(error)


if __name__ == "__main__":
    raise SystemExit(main())
