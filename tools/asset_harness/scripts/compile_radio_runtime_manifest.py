#!/usr/bin/env python3
"""Compile canonical radio pilots into Core's packaged JSON manifest."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT.parent) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT.parent))

from asset_harness.core.errors import AssetHarnessError  # noqa: E402
from asset_harness.core.paths import atomic_write_text  # noqa: E402
from asset_harness.core.runtime_manifest import (  # noqa: E402
    compile_runtime_manifest,
    manifest_json,
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--project-root",
        type=Path,
        default=SCRIPT_ROOT / "projects" / "radio",
        help="directory containing canonical *_pilot.json files",
    )
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--device", default=None, help="compile one project_id/device id")
    args = parser.parse_args()
    try:
        manifest = compile_runtime_manifest(args.project_root, device_id=args.device)
        content = manifest_json(manifest)
        atomic_write_text(args.output, content)
    except (AssetHarnessError, OSError, ValueError) as error:
        print(f"compile failed: {error}", file=sys.stderr)
        return 2
    print(
        f"compiled {len(manifest['devices'])} device(s) to {args.output} "
        f"(schema {manifest['schema_version']})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
