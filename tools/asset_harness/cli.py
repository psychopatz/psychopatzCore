#!/usr/bin/env python3
"""Headless JSON CLI for the Psychopatz Asset Harness."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any, Mapping

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from asset_harness import __version__
from asset_harness.core.animations import render_animation
from asset_harness.core.errors import AssetHarnessError, diagnostic
from asset_harness.core.export import (
    apply_export,
    build_export_plan,
    public_plan,
    used_source_ids,
    verify_export,
)
from asset_harness.core.paths import (
    atomic_write_text,
    ensure_within,
    parse_rect,
    resolve_reference,
)
from asset_harness.core.project import (
    default_project,
    load_project,
    project_id,
    project_revision,
    project_workspace,
    save_project,
)
from asset_harness.core.runtime_manifest import (
    compile_runtime_manifest,
    manifest_json,
)
from asset_harness.core.radio_assets import (
    audit_radio_sources,
    write_radio_audit_artifacts,
    write_radio_manifests,
)
from asset_harness.core.masks import (
    inspect_mask,
    mask_preview,
    register_mask,
    resolve_project_mask,
    validate_mask,
    write_polygon_mask,
    write_masked_extract,
)
from asset_harness.core.modular import (
    render_modular,
    render_modular_contact_sheet,
    set_chassis,
    set_component,
    set_lcd_layers,
    validate_modular,
)
from asset_harness.core.regions import (
    add_proposals,
    detect_source_regions,
    set_region,
    slice_region,
)
from asset_harness.core.render import difference_image, render_image, save_png
from asset_harness.core.responses import (
    artifact_descriptor,
    bound_response,
    envelope,
    sha256_path,
)
from asset_harness.core.source import import_source, inspect_image, load_rgba, register_source
from asset_harness.core.validation import validate_project


REPO_ROOT = Path(__file__).resolve().parents[2]


def _add_output_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--format", choices=("json", "text"), default="json")
    parser.add_argument("--token-budget", type=int, default=6000)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Offline, agent-operated PsychopatzCore PNG and skin authoring harness"
    )
    _add_output_args(parser)
    sub = parser.add_subparsers(dest="command", required=True)

    doctor = sub.add_parser("doctor", help="report local harness capabilities")
    _add_output_args(doctor)
    assets = sub.add_parser("assets", help="inspect canonical radio asset files")
    asset_sub = assets.add_subparsers(dest="asset_command", required=True)
    assets_list = asset_sub.add_parser("list", help="list runtime radio assets")
    assets_list.add_argument("--root", type=Path, default=REPO_ROOT)
    assets_list.add_argument("--family", default=None)
    assets_list.add_argument("--offset", type=int, default=0)
    assets_list.add_argument("--limit", type=int, default=100)
    _add_output_args(assets_list)
    assets_audit = asset_sub.add_parser("audit", help="audit canonical radio sources without modifying them")
    assets_audit.add_argument("--root", type=Path, default=REPO_ROOT)
    assets_audit.add_argument("--family", choices=("walkie", "ham", "manpack"), default=None)
    assets_audit.add_argument("--out", type=Path, default=None, help="optional JSON report path below --root")
    assets_audit.add_argument("--write-manifests", action="store_true", help="write blocked/proposed per-device manifests")
    assets_audit.add_argument("--manifests-root", type=Path, default=None)
    assets_audit.add_argument("--write-artifacts", action="store_true", help="write review-only source and alpha artifacts")
    assets_audit.add_argument("--artifacts-root", type=Path, default=None)
    assets_audit.add_argument("--contact-sheet-columns", type=int, default=4)
    _add_output_args(assets_audit)

    project = sub.add_parser("project", help="create or inspect resumable projects")
    project_sub = project.add_subparsers(dest="project_command", required=True)
    project_init = project_sub.add_parser("init", help="create a project JSON")
    project_init.add_argument("--project", type=Path, required=True)
    project_init.add_argument("--family", default="walkie")
    project_init.add_argument("--model", default="demo")
    project_init.add_argument("--full-type", default=None)
    project_init.add_argument("--width", type=int, default=256)
    project_init.add_argument("--height", type=int, default=432)
    project_init.add_argument("--workspace-root", default=".")
    _add_output_args(project_init)
    project_inspect = project_sub.add_parser("inspect", help="show a bounded project document")
    project_inspect.add_argument("--project", type=Path, required=True)
    _add_output_args(project_inspect)

    source = sub.add_parser("source", help="inspect and register transparent PNG sources")
    source_sub = source.add_subparsers(dest="source_command", required=True)
    source_inspect = source_sub.add_parser("inspect", help="inspect one image without writing")
    source_inspect.add_argument("--input", type=Path, required=True)
    _add_output_args(source_inspect)
    source_register = source_sub.add_parser("register", help="register a source in a project")
    source_register.add_argument("--project", type=Path, required=True)
    source_register.add_argument("--id", required=True)
    source_register.add_argument("--input", required=True)
    source_register.add_argument("--provenance", default="unattributed")
    source_register.add_argument("--approved", action="store_true")
    source_register.add_argument("--allow-external", action="store_true")
    _add_output_args(source_register)
    source_import = source_sub.add_parser("import", help="copy original PNG bytes into the project")
    source_import.add_argument("--project", type=Path, required=True)
    source_import.add_argument("--id", required=True)
    source_import.add_argument("--input", required=True)
    source_import.add_argument("--provenance", default="unattributed")
    source_import.add_argument("--approved", action="store_true")
    _add_output_args(source_import)

    regions = sub.add_parser("regions", help="detect, edit, and slice source rectangles")
    regions_sub = regions.add_subparsers(dest="regions_command", required=True)
    detect = regions_sub.add_parser("detect", help="propose connected alpha regions")
    detect.add_argument("--project", type=Path, required=True)
    detect.add_argument("--source", required=True)
    detect.add_argument("--threshold", type=int, default=1)
    detect.add_argument("--min-area", type=int, default=4)
    detect.add_argument("--padding", type=int, default=0)
    detect.add_argument("--limit", type=int, default=64)
    detect.add_argument("--no-write", action="store_true")
    _add_output_args(detect)
    set_cmd = regions_sub.add_parser("set", help="set an exact manual rectangle")
    set_cmd.add_argument("--project", type=Path, required=True)
    set_cmd.add_argument("--id", required=True)
    set_cmd.add_argument("--source", required=True)
    set_cmd.add_argument("--rect", required=True)
    set_cmd.add_argument("--purpose", default="unknown")
    set_cmd.add_argument("--status", choices=("proposed", "verified", "rejected"), default="verified")
    set_cmd.add_argument("--exclusive", action="store_true")
    _add_output_args(set_cmd)
    slice_cmd = regions_sub.add_parser("slice", help="extract a lossless PNG region")
    slice_cmd.add_argument("--project", type=Path, required=True)
    slice_cmd.add_argument("--id", required=True)
    slice_cmd.add_argument("--out", type=Path, required=True)
    _add_output_args(slice_cmd)

    masks = sub.add_parser("masks", help="register and QA source-space alpha masks")
    masks_sub = masks.add_subparsers(dest="masks_command", required=True)
    mask_import = masks_sub.add_parser("import", help="copy a lossless mask into the project workspace")
    mask_import.add_argument("--project", type=Path, required=True)
    mask_import.add_argument("--id", required=True)
    mask_import.add_argument("--input", required=True)
    mask_import.add_argument("--source", default=None)
    mask_import.add_argument("--method", choices=("alpha", "manual_polygon", "manual_path", "hand_authored", "derived_proposal", "rectangle"), default="hand_authored")
    mask_import.add_argument("--status", choices=("proposed", "verified", "blocked", "rejected"), default="proposed")
    mask_import.add_argument("--provenance", default="unattributed")
    mask_import.add_argument("--bounds", default=None)
    mask_import.add_argument("--forbidden-mask", default=None)
    mask_import.add_argument("--reviewed-by", default=None)
    mask_import.add_argument("--review-artifact", action="append", default=[])
    _add_output_args(mask_import)
    mask_polygon = masks_sub.add_parser("polygon", help="author a bounded source-canvas polygon mask")
    mask_polygon.add_argument("--project", type=Path, required=True)
    mask_polygon.add_argument("--id", required=True)
    mask_polygon.add_argument("--source", required=True)
    mask_polygon.add_argument("--points", required=True, help="semicolon-separated x,y pairs")
    mask_polygon.add_argument("--status", choices=("proposed", "verified", "blocked", "rejected"), default="proposed")
    mask_polygon.add_argument("--provenance", default="manual polygon; pending visual review")
    mask_polygon.add_argument("--forbidden-mask", default=None)
    _add_output_args(mask_polygon)
    mask_inspect = masks_sub.add_parser("inspect", help="inspect a registered mask")
    mask_inspect.add_argument("--project", type=Path, required=True)
    mask_inspect.add_argument("--id", required=True)
    _add_output_args(mask_inspect)
    mask_validate = masks_sub.add_parser("validate", help="validate one registered mask")
    mask_validate.add_argument("--project", type=Path, required=True)
    mask_validate.add_argument("--id", required=True)
    mask_validate.add_argument("--production", action="store_true")
    _add_output_args(mask_validate)
    mask_preview_cmd = masks_sub.add_parser("preview", help="write a full-resolution mask overlay")
    mask_preview_cmd.add_argument("--project", type=Path, required=True)
    mask_preview_cmd.add_argument("--id", required=True)
    mask_preview_cmd.add_argument("--source", required=True)
    mask_preview_cmd.add_argument("--out", type=Path, required=True)
    mask_preview_cmd.add_argument("--color", default="#ff2abf")
    mask_preview_cmd.add_argument("--opacity", type=int, default=120)
    _add_output_args(mask_preview_cmd)
    mask_extract_cmd = masks_sub.add_parser("extract", help="write a lossless alpha-masked component")
    mask_extract_cmd.add_argument("--project", type=Path, required=True)
    mask_extract_cmd.add_argument("--id", required=True)
    mask_extract_cmd.add_argument("--source", required=True)
    mask_extract_cmd.add_argument("--out", type=Path, required=True)
    _add_output_args(mask_extract_cmd)

    modular = sub.add_parser("modular", help="author and render versioned modular radio projects")
    modular_sub = modular.add_subparsers(dest="modular_command", required=True)
    modular_chassis = modular_sub.add_parser("chassis", help="set one independently authored chassis condition")
    modular_chassis_sub = modular_chassis.add_subparsers(dest="modular_chassis_command", required=True)
    modular_chassis_set = modular_chassis_sub.add_parser("set", help="register a pristine or worn chassis")
    modular_chassis_set.add_argument("--project", type=Path, required=True)
    modular_chassis_set.add_argument("--variant", choices=("pristine", "worn"), required=True)
    modular_chassis_set.add_argument("--image", required=True)
    modular_chassis_set.add_argument("--socket-mask", default=None)
    modular_chassis_set.add_argument("--anchors", default=None, help="JSON object of integer anchor coordinates")
    modular_chassis_set.add_argument("--status", choices=("proposed", "verified", "blocked"), default="proposed")
    modular_chassis_set.add_argument("--notes", default=None)
    modular_chassis_set.add_argument("--reviewed-by", default=None)
    modular_chassis_set.add_argument("--review-artifact", action="append", default=[])
    _add_output_args(modular_chassis_set)
    modular_lcd = modular_sub.add_parser("lcd", help="register independent LCD glass/bezel layers")
    modular_lcd_set = modular_lcd.add_subparsers(dest="modular_lcd_command", required=True)
    modular_lcd_register = modular_lcd_set.add_parser("set", help="register LCD matte, glass, and bezel layers")
    modular_lcd_register.add_argument("--project", type=Path, required=True)
    modular_lcd_register.add_argument("--glass", required=True)
    modular_lcd_register.add_argument("--bezel-overlay", required=True)
    modular_lcd_register.add_argument("--matte", default=None)
    modular_lcd_register.add_argument("--status", choices=("proposed", "verified", "blocked"), default="proposed")
    modular_lcd_register.add_argument("--notes", default=None)
    modular_lcd_register.add_argument("--reviewed-by", default=None)
    modular_lcd_register.add_argument("--review-artifact", action="append", default=[])
    _add_output_args(modular_lcd_register)
    modular_component = modular_sub.add_parser("component", help="register keyed states for one physical part")
    modular_component_sub = modular_component.add_subparsers(dest="modular_component_command", required=True)
    modular_component_set = modular_component_sub.add_parser("set", help="register a component and its state images")
    modular_component_set.add_argument("--project", type=Path, required=True)
    modular_component_set.add_argument("--id", required=True)
    modular_component_set.add_argument("--kind", required=True)
    modular_component_set.add_argument("--action", default=None)
    modular_component_set.add_argument("--states", default=None, help="JSON object mapping state names to image paths or objects")
    modular_component_set.add_argument("--states-file", type=Path, default=None)
    modular_component_set.add_argument("--hitbox", default=None)
    modular_component_set.add_argument("--pivot", default=None)
    modular_component_set.add_argument("--detents", type=int, default=None)
    modular_component_set.add_argument("--mask", default=None, help="registered moving-face silhouette mask")
    modular_component_set.add_argument("--socket-mask", default=None)
    modular_component_set.add_argument("--status", choices=("proposed", "verified", "blocked"), default="proposed")
    modular_component_set.add_argument("--notes", default=None)
    modular_component_set.add_argument("--reviewed-by", default=None)
    modular_component_set.add_argument("--review-artifact", action="append", default=[])
    _add_output_args(modular_component_set)
    modular_validate = modular_sub.add_parser("validate", help="validate all modular chassis and component contracts")
    modular_validate.add_argument("--project", type=Path, required=True)
    _add_output_args(modular_validate)
    modular_render = modular_sub.add_parser("render", help="render one modular chassis and keyed state combination")
    modular_render.add_argument("--project", type=Path, required=True)
    modular_render.add_argument("--variant", choices=("pristine", "worn"), default="pristine")
    modular_render.add_argument("--state", action="append", default=[], help="component_id=state; repeatable")
    modular_render.add_argument("--out", type=Path, required=True)
    _add_output_args(modular_render)
    modular_sheet = modular_sub.add_parser("contact-sheet", help="render a bounded state/variant contact sheet")
    modular_sheet.add_argument("--project", type=Path, required=True)
    modular_sheet.add_argument("--out", type=Path, required=True)
    modular_sheet.add_argument("--columns", type=int, default=4)
    modular_sheet.add_argument("--max-combinations", type=int, default=64)
    _add_output_args(modular_sheet)

    layers = sub.add_parser("layers", help="set or remove device-local visual layers")
    layers_sub = layers.add_subparsers(dest="layers_command", required=True)
    layer_set = layers_sub.add_parser("set", help="create or replace one layer")
    layer_set.add_argument("--project", type=Path, required=True)
    layer_set.add_argument("--id", required=True)
    layer_set.add_argument("--source", required=True)
    layer_set.add_argument("--region", default=None)
    layer_set.add_argument("--x", type=int, default=0)
    layer_set.add_argument("--y", type=int, default=0)
    layer_set.add_argument("--z", type=int, default=0)
    layer_set.add_argument("--anchor", default="top_left")
    layer_set.add_argument("--opacity", type=float, default=1.0)
    layer_set.add_argument("--role", default="")
    layer_set.add_argument("--state", action="append", default=[])
    layer_set.add_argument("--variant", action="append", default=[])
    layer_set.add_argument("--clip", default=None)
    layer_set.add_argument("--scale", type=float, default=1.0)
    _add_output_args(layer_set)
    layer_remove = layers_sub.add_parser("remove", help="remove one layer")
    layer_remove.add_argument("--project", type=Path, required=True)
    layer_remove.add_argument("--id", required=True)
    _add_output_args(layer_remove)

    controls = sub.add_parser("controls", help="set configurable physical control hitboxes")
    controls_sub = controls.add_subparsers(dest="controls_command", required=True)
    control_set = controls_sub.add_parser("set", help="create or replace one control")
    control_set.add_argument("--project", type=Path, required=True)
    control_set.add_argument("--id", required=True)
    control_set.add_argument("--rect", required=True)
    control_set.add_argument("--hitbox", default=None)
    control_set.add_argument("--action", required=True)
    control_set.add_argument("--label", default=None)
    _add_output_args(control_set)
    control_remove = controls_sub.add_parser("remove", help="remove one control")
    control_remove.add_argument("--project", type=Path, required=True)
    control_remove.add_argument("--id", required=True)
    _add_output_args(control_remove)

    lcd = sub.add_parser("lcd", help="set measured LCD aperture/backing/content geometry")
    lcd_sub = lcd.add_subparsers(dest="lcd_command", required=True)
    lcd_set = lcd_sub.add_parser("set", help="set LCD geometry")
    lcd_set.add_argument("--project", type=Path, required=True)
    lcd_set.add_argument("--aperture", required=True)
    lcd_set.add_argument("--backing", default=None)
    lcd_set.add_argument("--content", default=None)
    lcd_set.add_argument("--backing-color", default=None)
    _add_output_args(lcd_set)

    variants = sub.add_parser("variants", help="declare clean/scratched/worn/damaged cosmetic states")
    variants_sub = variants.add_subparsers(dest="variants_command", required=True)
    variant_set = variants_sub.add_parser("set", help="declare one variant")
    variant_set.add_argument("--project", type=Path, required=True)
    variant_set.add_argument("--name", required=True)
    variant_set.add_argument("--layer", action="append", default=[])
    variant_set.add_argument("--description", default=None)
    _add_output_args(variant_set)
    variant_list = variants_sub.add_parser("list", help="list declared variants")
    variant_list.add_argument("--project", type=Path, required=True)
    _add_output_args(variant_list)

    render = sub.add_parser("render", help="render a deterministic full-resolution PNG")
    render.add_argument("--project", type=Path, required=True)
    render.add_argument("--state", default=None)
    render.add_argument("--variant", default="pristine")
    render.add_argument("--scale", type=float, default=1.0)
    render.add_argument("--content-color", default=None)
    render.add_argument("--debug", action="store_true")
    render.add_argument("--grid", type=int, default=0)
    render.add_argument("--out", type=Path, default=None)
    _add_output_args(render)

    animation = sub.add_parser("animation", help="define and render bounded animations")
    animation_sub = animation.add_subparsers(dest="animation_command", required=True)
    animation_set = animation_sub.add_parser("set", help="set an animation from JSON frames")
    animation_set.add_argument("--project", type=Path, required=True)
    animation_set.add_argument("--name", required=True)
    animation_set.add_argument("--frames", default=None, help="JSON array of frames")
    animation_set.add_argument("--frames-file", type=Path, default=None)
    _add_output_args(animation_set)
    animation_render = animation_sub.add_parser("render", help="render frames and a contact sheet")
    animation_render.add_argument("--project", type=Path, required=True)
    animation_render.add_argument("--name", required=True)
    animation_render.add_argument("--out", type=Path, default=None)
    animation_render.add_argument("--scale", type=float, default=1.0)
    animation_render.add_argument("--columns", type=int, default=4)
    animation_render.add_argument("--content-color", default=None)
    animation_render.add_argument("--debug", action="store_true")
    _add_output_args(animation_render)

    diff = sub.add_parser("diff", help="write a deterministic pixel difference PNG")
    diff.add_argument("--before", type=Path, required=True)
    diff.add_argument("--after", type=Path, required=True)
    diff.add_argument("--out", type=Path, required=True)
    _add_output_args(diff)

    validate = sub.add_parser("validate", help="validate a project and write a report")
    validate.add_argument("--project", type=Path, required=True)
    validate.add_argument("--report", type=Path, default=None)
    validate.add_argument("--no-report", action="store_true")
    validate.add_argument("--fail-on-warning", action="store_true")
    _add_output_args(validate)

    export = sub.add_parser("export", help="plan, apply, or verify safe runtime exports")
    export_sub = export.add_subparsers(dest="export_command", required=True)
    for name in ("plan", "verify"):
        export_cmd = export_sub.add_parser(name, help=f"export {name}")
        export_cmd.add_argument("--project", type=Path, required=True)
        _add_output_args(export_cmd)
    export_apply = export_sub.add_parser("apply", help="apply a validated export")
    export_apply.add_argument("--project", type=Path, required=True)
    export_apply.add_argument("--approved", action="store_true")
    _add_output_args(export_apply)

    runtime_manifest = sub.add_parser(
        "runtime-manifest",
        help="compile canonical modular radio pilots for the Core Lua runtime",
    )
    runtime_manifest.add_argument(
        "--project-root",
        type=Path,
        default=REPO_ROOT / "tools/asset_harness/projects/radio",
    )
    runtime_manifest.add_argument("--device", default=None)
    runtime_manifest.add_argument("--out", type=Path, required=True)
    _add_output_args(runtime_manifest)

    batch = sub.add_parser("batch", help="run a bounded list of whitelisted CLI argv operations")
    batch.add_argument("--file", type=Path, required=True)
    _add_output_args(batch)
    return parser


def _project_path(args: argparse.Namespace) -> Path:
    return Path(args.project).expanduser().resolve()


def _is_canonical_radio_pilot(path: Path, project: Mapping[str, Any]) -> bool:
    """Keep the legacy generic exporter from creating a second radio runtime."""

    return (
        path.name.endswith("_pilot.json")
        and path.parent.name == "radio"
        and isinstance(project.get("device"), Mapping)
        and isinstance(project.get("modular"), Mapping)
    )


def _output_path(project_path: Path, project: dict[str, Any], value: Path | None, default: str) -> Path:
    workspace = project_workspace(project_path, project)
    target = Path(value) if value is not None else Path(project_path).resolve().parent / "artifacts" / default
    if not target.is_absolute():
        target = workspace / target
    return ensure_within(workspace, target)


def _save_report(path: Path, value: Mapping[str, Any]) -> dict[str, Any]:
    atomic_write_text(path, json.dumps(value, ensure_ascii=True, sort_keys=True, indent=2) + "\n")
    return artifact_descriptor(path, "json")


def _find_layer(project: dict[str, Any], layer_id: str) -> list[dict[str, Any]]:
    return [layer for layer in project.get("layers") or [] if isinstance(layer, dict) and layer.get("id") == layer_id]


def _dispatch(args: argparse.Namespace) -> tuple[str, dict[str, Any] | None, list[dict[str, Any]], list[dict[str, Any]], bool]:
    command = _command_name(args)
    artifacts: list[dict[str, Any]] = []
    diagnostics: list[dict[str, Any]] = []
    truncated = False
    project_value: dict[str, Any] | None = None

    if args.command == "doctor":
        from PIL import Image
        data = {
            "version": __version__,
            "python": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
            "pillow": Image.__version__,
            "headless": True,
            "gui_required": False,
            "pz_headless_harness": "prohibited",
        }
        return command, data, artifacts, diagnostics, truncated

    if args.command == "assets":
        root = Path(args.root).expanduser().resolve()
        if args.asset_command == "audit":
            report = audit_radio_sources(root, family=args.family)
            if args.write_artifacts:
                artifacts_root = args.artifacts_root or root / "tools/asset_harness/workspace/radio/ah-r0"
                artifacts_root = artifacts_root.expanduser().resolve()
                ensure_within(root, artifacts_root)
                artifact_paths = write_radio_audit_artifacts(
                    report,
                    artifacts_root,
                    columns=args.contact_sheet_columns,
                )
                for path in artifact_paths:
                    artifacts.append(artifact_descriptor(path, "radio_audit_artifact"))
            if args.write_manifests:
                manifests_root = args.manifests_root or root / "tools/asset_harness/projects/radio"
                manifests_root = manifests_root.expanduser().resolve()
                ensure_within(root, manifests_root)
                manifest_paths = write_radio_manifests(report, manifests_root)
                for path in manifest_paths:
                    artifacts.append(artifact_descriptor(path, "radio_manifest"))
                for device in report["devices"]:
                    matching = next((path for path in manifest_paths if path.stem == device.get("id")), None)
                    if matching is not None:
                        device.setdefault("verification", {}).setdefault("artifacts", []).append(str(matching))
            if args.out is not None:
                report_path = args.out.expanduser()
                if not report_path.is_absolute():
                    report_path = root / report_path
                report_path = ensure_within(root, report_path)
                artifacts.append(_save_report(report_path, report))
            return command, report, artifacts, diagnostics, False
        roots: list[tuple[str, Path]] = []
        if args.family in (None, "walkie"):
            roots.append(("walkie", root / "Contents/mods/PsychopatzCore/common/media/ui/Radio/WalkieTalkie"))
        if args.family in (None, "ham"):
            roots.append(("ham", root / "Contents/mods/PsychopatzCore/common/media/ui/Radio/Ham"))
        if args.family in (None, "manpack"):
            roots.append(("manpack", root / "Contents/mods/PsychopatzCore/common/media/ui/Radio/ManPack"))
        rows: list[dict[str, Any]] = []
        for family, directory in roots:
            if not directory.exists():
                continue
            for path in sorted(directory.rglob("*.png")):
                rows.append({"family": family, "path": str(path), "bytes": path.stat().st_size, "sha256": sha256_path(path)})
        start = max(0, int(args.offset))
        limit = max(1, min(1000, int(args.limit)))
        return command, {"assets": rows[start:start + limit], "offset": start, "limit": limit, "total": len(rows)}, artifacts, diagnostics, len(rows) > start + limit

    if args.command == "project":
        path = _project_path(args)
        if args.project_command == "init":
            if path.exists():
                raise AssetHarnessError("PROJECT_EXISTS", f"refusing to overwrite project: {path}")
            value = default_project(args.project.stem, family=args.family, model=args.model, width=args.width, height=args.height, full_type=args.full_type, workspace_root=args.workspace_root)
            save_project(path, value)
            return command, {"project": value}, [artifact_descriptor(path, "project")], diagnostics, truncated
        value = load_project(path)
        return command, {"project": value}, artifacts, diagnostics, truncated

    if args.command == "source":
        if args.source_command == "inspect":
            return command, {"source": inspect_image(Path(args.input))}, artifacts, diagnostics, truncated
        path = _project_path(args)
        value = load_project(path)
        if args.source_command == "import":
            metadata = import_source(path, value, args.id, args.input, provenance=args.provenance, approved=args.approved)
        else:
            metadata = register_source(path, value, args.id, args.input, provenance=args.provenance, approved=args.approved, allow_external=args.allow_external)
        save_project(path, value)
        return command, {"source_id": args.id, "source": metadata}, [artifact_descriptor(path, "project")], diagnostics, truncated

    if args.command == "regions":
        path = _project_path(args)
        value = load_project(path)
        if args.regions_command == "detect":
            proposals = detect_source_regions(path, value, args.source, threshold=args.threshold, min_area=args.min_area, padding=args.padding, limit=args.limit)
            added: list[str] = []
            if not args.no_write:
                added = add_proposals(value, args.source, proposals)
                save_project(path, value)
                artifacts.append(artifact_descriptor(path, "project"))
            return command, {"source_id": args.source, "proposals": proposals, "region_ids": added}, artifacts, diagnostics, False
        if args.regions_command == "set":
            result = set_region(value, args.id, args.source, args.rect, purpose=args.purpose, status=args.status, exclusive=args.exclusive)
            save_project(path, value)
            return command, {"region_id": args.id, "region": result}, [artifact_descriptor(path, "project")], diagnostics, False
        output = _output_path(path, value, args.out, f"{args.id}.png")
        slice_region(path, value, args.id, output)
        return command, {"region_id": args.id}, [artifact_descriptor(output, "png")], diagnostics, False

    if args.command == "masks":
        path = _project_path(args)
        value = load_project(path)
        if args.masks_command == "polygon":
            record = write_polygon_mask(
                path,
                value,
                args.id,
                args.source,
                args.points,
                status=args.status,
                provenance=args.provenance,
                forbidden_mask_id=args.forbidden_mask,
            )
            save_project(path, value)
            return command, {"mask_id": args.id, "mask": record}, [artifact_descriptor(path, "project")], diagnostics, False
        if args.masks_command == "import":
            record = register_mask(
                path,
                value,
                args.id,
                args.input,
                source_id=args.source,
                method=args.method,
                status=args.status,
                provenance=args.provenance,
                bounds=args.bounds,
                forbidden_mask_id=args.forbidden_mask,
                review={
                    "reviewed": bool(args.reviewed_by or args.review_artifact),
                    "reviewed_by": args.reviewed_by,
                    "artifacts": list(args.review_artifact),
                },
            )
            save_project(path, value)
            return command, {"mask_id": args.id, "mask": record}, [artifact_descriptor(path, "project")], diagnostics, False
        if args.masks_command == "inspect":
            record, _, mask_path = resolve_project_mask(path, value, args.id)
            return command, {"mask_id": args.id, "mask": record, "inspection": inspect_mask(mask_path)}, artifacts, diagnostics, False
        if args.masks_command == "validate":
            result = validate_mask(path, value, args.id, production=args.production)
            diagnostics.extend(result["diagnostics"])
            if not result["ok"]:
                raise AssetHarnessError("MASK_VALIDATION_FAILED", "mask validation failed", diagnostics=result["diagnostics"])
            return command, {"validation": result["summary"]}, artifacts, diagnostics, False
        source = (value.get("sources") or {}).get(args.source)
        if not isinstance(source, dict):
            raise AssetHarnessError("SOURCE_NOT_REGISTERED", f"source is not registered: {args.source}")
        workspace = project_workspace(path, value)
        source_value = str(source.get("path") or "")
        source_path = resolve_reference(workspace, source_value, allow_external=Path(source_value).is_absolute(), must_exist=True)
        source_image = load_rgba(source_path)
        _, mask_image, _ = resolve_project_mask(path, value, args.id)
        output = _output_path(path, value, args.out, f"{args.id}.png")
        if args.masks_command == "preview":
            image = mask_preview(source_image, mask_image, color=args.color, opacity=args.opacity)
            save_png(image, output)
            return command, {"mask_id": args.id, "source_id": args.source}, [artifact_descriptor(output, "png", width=image.width, height=image.height)], diagnostics, False
        write_masked_extract(source_image, mask_image, output)
        return command, {"mask_id": args.id, "source_id": args.source}, [artifact_descriptor(output, "png", width=source_image.width, height=source_image.height)], diagnostics, False

    if args.command == "modular":
        path = _project_path(args)
        value = load_project(path)
        if args.modular_command == "chassis":
            if args.modular_chassis_command != "set":
                raise AssetHarnessError("COMMAND_UNSUPPORTED", "unsupported modular chassis command")
            anchors = None
            if args.anchors:
                try:
                    anchors = json.loads(args.anchors)
                except json.JSONDecodeError as error:
                    raise AssetHarnessError("INVALID_ANCHORS", "anchors must be a JSON object") from error
                if not isinstance(anchors, dict):
                    raise AssetHarnessError("INVALID_ANCHORS", "anchors must be a JSON object")
            entry = set_chassis(
                value,
                args.variant,
                image=args.image,
                socket_mask=args.socket_mask,
                anchors=anchors,
                status=args.status,
                notes=args.notes,
                review={"reviewed": bool(args.reviewed_by or args.review_artifact), "reviewed_by": args.reviewed_by, "artifacts": list(args.review_artifact)},
            )
            save_project(path, value)
            return command, {"variant": args.variant, "chassis": entry}, [artifact_descriptor(path, "project")], diagnostics, False
        if args.modular_command == "lcd":
            if args.modular_lcd_command != "set":
                raise AssetHarnessError("COMMAND_UNSUPPORTED", "unsupported modular lcd command")
            entry = set_lcd_layers(
                value,
                glass=args.glass,
                bezel_overlay=args.bezel_overlay,
                matte=args.matte,
                status=args.status,
                notes=args.notes,
                review={"reviewed": bool(args.reviewed_by or args.review_artifact), "reviewed_by": args.reviewed_by, "artifacts": list(args.review_artifact)},
            )
            save_project(path, value)
            return command, {"lcd_layers": entry}, [artifact_descriptor(path, "project")], diagnostics, False
        if args.modular_command == "component":
            if args.modular_component_command != "set":
                raise AssetHarnessError("COMMAND_UNSUPPORTED", "unsupported modular component command")
            if bool(args.states) == bool(args.states_file):
                raise AssetHarnessError("COMPONENT_STATES_REQUIRED", "provide exactly one of --states or --states-file")
            raw = args.states if args.states is not None else args.states_file.read_text(encoding="utf-8")
            try:
                states = json.loads(raw)
            except json.JSONDecodeError as error:
                raise AssetHarnessError("COMPONENT_STATES_INVALID", "component states must be valid JSON") from error
            if not isinstance(states, dict):
                raise AssetHarnessError("COMPONENT_STATES_INVALID", "component states must be a JSON object")
            pivot = None
            if args.pivot:
                pivot = parse_rect(args.pivot + ",1,1", name="component pivot")[:2]
            entry = set_component(
                value,
                args.id,
                kind=args.kind,
                action=args.action,
                states=states,
                hitbox=args.hitbox,
                pivot=pivot,
                detents=args.detents,
                mask=args.mask,
                socket_mask=args.socket_mask,
                status=args.status,
                notes=args.notes,
                review={"reviewed": bool(args.reviewed_by or args.review_artifact), "reviewed_by": args.reviewed_by, "artifacts": list(args.review_artifact)},
            )
            save_project(path, value)
            return command, {"component_id": args.id, "component": entry}, [artifact_descriptor(path, "project")], diagnostics, False
        if args.modular_command == "validate":
            result = validate_modular(path, value)
            diagnostics.extend(result["diagnostics"])
            if not result["ok"]:
                raise AssetHarnessError("MODULAR_VALIDATION_FAILED", "modular validation failed", diagnostics=result["diagnostics"])
            return command, {"validation": result["summary"]}, artifacts, diagnostics, False
        if args.modular_command == "render":
            states: dict[str, str] = {}
            for item in args.state:
                if "=" not in item:
                    raise AssetHarnessError("INVALID_COMPONENT_STATE", "--state must be component_id=state")
                component_id, state_name = item.split("=", 1)
                states[component_id] = state_name
            image, metadata = render_modular(path, value, variant=args.variant, states=states)
            output = _output_path(path, value, args.out, f"modular_{args.variant}.png")
            save_png(image, output)
            return command, {"render": metadata}, [artifact_descriptor(output, "png", width=image.width, height=image.height)], diagnostics, False
        if args.modular_command == "contact-sheet":
            if args.columns < 1 or args.columns > 16:
                raise AssetHarnessError("CONTACT_SHEET_INVALID", "columns must be between 1 and 16")
            if args.max_combinations < 1 or args.max_combinations > 64:
                raise AssetHarnessError("CONTACT_SHEET_INVALID", "max combinations must be between 1 and 64")
            sheet, frames = render_modular_contact_sheet(path, value, columns=args.columns, max_combinations=args.max_combinations)
            output = _output_path(path, value, args.out, "modular_contact_sheet.png")
            save_png(sheet, output)
            return command, {"frames": frames, "frame_count": len(frames)}, [artifact_descriptor(output, "png", width=sheet.width, height=sheet.height)], diagnostics, False
        raise AssetHarnessError("COMMAND_UNSUPPORTED", f"unsupported modular command: {args.modular_command}")

    if args.command == "layers":
        path = _project_path(args)
        value = load_project(path)
        layers = value.setdefault("layers", [])
        if args.layers_command == "remove":
            before = len(layers)
            value["layers"] = [layer for layer in layers if not (isinstance(layer, dict) and layer.get("id") == args.id)]
            if len(value["layers"]) == before:
                raise AssetHarnessError("LAYER_NOT_FOUND", f"layer is not defined: {args.id}")
            save_project(path, value)
            return command, {"removed": args.id}, [artifact_descriptor(path, "project")], diagnostics, False
        layer = {
            "id": args.id, "source": args.source, "x": args.x, "y": args.y, "z": args.z,
            "anchor": args.anchor, "opacity": args.opacity, "role": args.role,
            "scale": args.scale,
        }
        if args.region:
            layer["region"] = args.region
        if args.state:
            layer["states"] = args.state
        if args.variant:
            layer["variants"] = args.variant
        if args.clip:
            layer["clip"] = args.clip
        value["layers"] = [item for item in layers if not (isinstance(item, dict) and item.get("id") == args.id)] + [layer]
        save_project(path, value)
        return command, {"layer": layer}, [artifact_descriptor(path, "project")], diagnostics, False

    if args.command == "controls":
        path = _project_path(args)
        value = load_project(path)
        controls = value.setdefault("controls", [])
        if args.controls_command == "remove":
            before = len(controls)
            value["controls"] = [item for item in controls if not (isinstance(item, dict) and item.get("id") == args.id)]
            if len(value["controls"]) == before:
                raise AssetHarnessError("CONTROL_NOT_FOUND", f"control is not defined: {args.id}")
            save_project(path, value)
            return command, {"removed": args.id}, [artifact_descriptor(path, "project")], diagnostics, False
        control = {"id": args.id, "rect": parse_rect(args.rect, name=f"control {args.id}"), "action": args.action}
        if args.hitbox:
            control["hitbox"] = parse_rect(args.hitbox, name=f"control {args.id} hitbox")
        if args.label:
            control["label"] = args.label
        value["controls"] = [item for item in controls if not (isinstance(item, dict) and item.get("id") == args.id)] + [control]
        save_project(path, value)
        return command, {"control": control}, [artifact_descriptor(path, "project")], diagnostics, False

    if args.command == "lcd":
        path = _project_path(args)
        value = load_project(path)
        aperture = parse_rect(args.aperture, name="lcd aperture")
        backing = parse_rect(args.backing, name="lcd backing") if args.backing else list(aperture)
        content = parse_rect(args.content, name="lcd content") if args.content else None
        lcd_value: dict[str, Any] = {"aperture": aperture, "backing": backing}
        if content is not None:
            lcd_value["content"] = content
        if args.backing_color:
            lcd_value["backing_color"] = args.backing_color
        value["lcd"] = lcd_value
        save_project(path, value)
        return command, {"lcd": lcd_value}, [artifact_descriptor(path, "project")], diagnostics, False

    if args.command == "variants":
        path = _project_path(args)
        value = load_project(path)
        declared = value.setdefault("variants", {})
        if args.variants_command == "list":
            return command, {"variants": declared}, artifacts, diagnostics, False
        variant = {"layers": list(args.layer)}
        if args.description:
            variant["description"] = args.description
        declared[args.name] = variant
        save_project(path, value)
        return command, {"name": args.name, "variant": variant}, [artifact_descriptor(path, "project")], diagnostics, False

    if args.command == "render":
        path = _project_path(args)
        value = load_project(path)
        output = _output_path(path, value, args.out, "render.png")
        image, metadata = render_image(path, value, state=args.state, variant=args.variant, scale=args.scale, content_color=args.content_color, debug=args.debug, grid=args.grid)
        save_png(image, output)
        return command, {"render": metadata}, [artifact_descriptor(output, "png", width=image.width, height=image.height)], diagnostics, False

    if args.command == "animation":
        path = _project_path(args)
        value = load_project(path)
        if args.animation_command == "set":
            if bool(args.frames) == bool(args.frames_file):
                raise AssetHarnessError("ANIMATION_INPUT_REQUIRED", "provide exactly one of --frames or --frames-file")
            raw = args.frames if args.frames is not None else Path(args.frames_file).read_text(encoding="utf-8")
            try:
                frames = json.loads(raw)
            except (TypeError, json.JSONDecodeError) as error:
                raise AssetHarnessError("ANIMATION_INVALID", "animation frames must be valid JSON") from error
            if not isinstance(frames, list) or not frames:
                raise AssetHarnessError("ANIMATION_INVALID", "animation frames must be a non-empty JSON array")
            value.setdefault("animations", {})[args.name] = {"frames": frames}
            save_project(path, value)
            return command, {"name": args.name, "frames": frames}, [artifact_descriptor(path, "project")], diagnostics, False
        output = _output_path(path, value, args.out, f"{args.name}_contact_sheet.png")
        sheet, frame_paths, metadata = render_animation(path, value, args.name, output, scale=args.scale, columns=args.columns, content_color=args.content_color, debug=args.debug)
        artifacts.append(artifact_descriptor(sheet, "png", width=sheet.width, height=sheet.height))
        artifacts.extend(artifact_descriptor(frame, "png") for frame in frame_paths)
        return command, {"name": args.name, "frames": metadata}, artifacts, diagnostics, False

    if args.command == "diff":
        from PIL import Image
        before = Path(args.before).expanduser().resolve()
        after = Path(args.after).expanduser().resolve()
        output = Path(args.out).expanduser().resolve()
        allowed_output = False
        for root in (Path.cwd().resolve(), before.parent, after.parent):
            try:
                ensure_within(root, output)
                allowed_output = True
                break
            except AssetHarnessError:
                continue
        if not allowed_output:
            raise AssetHarnessError("PATH_UNSAFE", "difference output must remain beside an input image or below the current directory")
        with Image.open(before) as left, Image.open(after) as right:
            image, metadata = difference_image(left, right)
        save_png(image, output)
        return command, {"difference": metadata}, [artifact_descriptor(output, "png", width=image.width, height=image.height)], diagnostics, False

    if args.command == "validate":
        path = _project_path(args)
        value = load_project(path)
        result = validate_project(path, value)
        if not args.no_report:
            report = _output_path(path, value, args.report, "validation.json")
            artifacts.append(_save_report(report, result))
        errors = [item for item in result["diagnostics"] if item.get("severity") == "error"]
        warnings = [item for item in result["diagnostics"] if item.get("severity") == "warning"]
        if errors or (args.fail_on_warning and warnings):
            raise AssetHarnessError("VALIDATION_FAILED", "project validation failed", diagnostics=result["diagnostics"])
        diagnostics.extend(result["diagnostics"])
        return command, {"validation": result["summary"]}, artifacts, diagnostics, False

    if args.command == "export":
        path = _project_path(args)
        value = load_project(path)
        if _is_canonical_radio_pilot(path, value):
            raise AssetHarnessError(
                "RADIO_EXPORT_RETIRED",
                "canonical radio pilots compile only through the runtime-manifest command; "
                "the generic skin.lua exporter is retired for radio projects",
            )
        if args.export_command == "plan":
            plan = build_export_plan(path, value)
            report_path = _output_path(path, value, None, "export-plan.json")
            report = public_plan(plan)
            artifacts.append(_save_report(report_path, report))
            return command, {"plan": report}, artifacts, diagnostics, False
        if args.export_command == "apply":
            used = used_source_ids(value)
            unapproved = sorted(source_id for source_id in used if not bool((value.get("sources") or {}).get(source_id, {}).get("approved")))
            if unapproved:
                raise AssetHarnessError("SOURCE_NOT_APPROVED", "runtime export requires approved sources", diagnostics=[diagnostic("SOURCE_NOT_APPROVED", f"source is not approved: {source_id}", asset=source_id) for source_id in unapproved])
            plan = apply_export(path, value, approved=args.approved)
            artifacts.extend(artifact_descriptor(Path(item["path"]), item["kind"]) for item in plan["files"])
            return command, {"applied": public_plan(plan)}, artifacts, diagnostics, False
        result = verify_export(path, value)
        if not result["ok"]:
            raise AssetHarnessError("EXPORT_VERIFY_FAILED", "export verification failed", diagnostics=result["diagnostics"])
        return command, {"verification": result["summary"]}, artifacts, result["diagnostics"], False

    if args.command == "runtime-manifest":
        project_root = Path(args.project_root).expanduser().resolve()
        output = Path(args.out).expanduser()
        if not output.is_absolute(): output = REPO_ROOT / output
        output = ensure_within(REPO_ROOT, output)
        manifest = compile_runtime_manifest(project_root, device_id=args.device)
        atomic_write_text(output, manifest_json(manifest))
        artifacts.append(artifact_descriptor(output, "radio_runtime_manifest"))
        return command, {
            "schema_version": manifest["schema_version"],
            "manifest_kind": manifest["manifest_kind"],
            "device_count": len(manifest["devices"]),
            "output": str(output),
        }, artifacts, diagnostics, False

    if args.command == "batch":
        raw = json.loads(Path(args.file).read_text(encoding="utf-8"))
        operations = raw.get("operations") if isinstance(raw, dict) else raw
        if not isinstance(operations, list) or len(operations) > 64:
            raise AssetHarnessError("BATCH_INVALID", "batch must contain at most 64 operations")
        results = []
        allowed = {"doctor", "assets", "project", "source", "regions", "masks", "layers", "controls", "lcd", "variants", "render", "animation", "diff", "validate", "export", "runtime-manifest", "modular"}
        for index, operation in enumerate(operations):
            if not isinstance(operation, dict) or not isinstance(operation.get("argv"), list) or not operation["argv"]:
                raise AssetHarnessError("BATCH_INVALID", f"operation {index} must contain an argv array")
            if str(operation["argv"][0]) not in allowed:
                raise AssetHarnessError("BATCH_COMMAND_NOT_ALLOWED", f"operation {index} is not whitelisted")
            nested = build_parser().parse_args([str(value) for value in operation["argv"]])
            nested.command = str(operation["argv"][0])
            nested_result = _run_parsed(nested)
            results.append(nested_result)
        return command, {"results": results}, artifacts, diagnostics, False

    raise AssetHarnessError("COMMAND_UNSUPPORTED", f"unsupported command: {command}")


def _command_name(args: argparse.Namespace) -> str:
    parts = [str(args.command)]
    for key in ("asset_command", "project_command", "source_command", "regions_command", "masks_command", "layers_command", "controls_command", "lcd_command", "variants_command", "animation_command", "export_command", "modular_command", "modular_chassis_command", "modular_component_command"):
        value = getattr(args, key, None)
        if value:
            parts.append(str(value))
    return " ".join(parts)


def _run_parsed(args: argparse.Namespace) -> dict[str, Any]:
    command = _command_name(args)
    try:
        _, data, artifacts, diagnostics, truncated = _dispatch(args)
        project_value = None
        if hasattr(args, "project") and args.project is not None and Path(args.project).exists():
            try:
                project_value = load_project(Path(args.project))
            except AssetHarnessError:
                project_value = None
        response = envelope(
            command,
            ok=True,
            project_id=project_id(project_value) if project_value else None,
            revision=project_revision(project_value) if project_value else None,
            summary={"artifacts": len(artifacts)},
            diagnostics=diagnostics,
            artifacts=artifacts,
            data=data,
            truncated=truncated,
        )
        return bound_response(response, getattr(args, "token_budget", 6000))
    except AssetHarnessError as error:
        response = envelope(
            command,
            ok=False,
            project_id=None,
            summary={"errors": 1},
            diagnostics=[{"code": error.code, "severity": "error", "message": error.message}, *error.diagnostics],
            artifacts=[],
        )
        return bound_response(response, getattr(args, "token_budget", 6000))
    except Exception as error:
        response = envelope(
            command,
            ok=False,
            summary={"errors": 1},
            diagnostics=[{"code": "INTERNAL_ERROR", "severity": "error", "message": str(error)}],
            artifacts=[],
        )
        return bound_response(response, getattr(args, "token_budget", 6000))


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    response = _run_parsed(args)
    if getattr(args, "format", "json") == "text":
        print(f"{response.get('command')}: {'ok' if response.get('ok') else 'failed'}")
        for item in response.get("diagnostics") or []:
            print(f"{item.get('severity', 'error')}: {item.get('code')}: {item.get('message')}")
    else:
        print(json.dumps(response, ensure_ascii=True, sort_keys=True, indent=2))
    return 0 if response.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
