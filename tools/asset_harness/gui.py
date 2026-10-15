#!/usr/bin/env python3
"""Optional local Tk viewer for Asset Harness previews.

The CLI remains the source of truth.  This module is deliberately a thin,
read-only-ish client around the same project/source/render functions so a
developer can inspect PNGs without changing the agent-facing contract.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
TOOLS_ROOT = REPO_ROOT / "tools"
if str(TOOLS_ROOT) not in sys.path:
    sys.path.insert(0, str(TOOLS_ROOT))

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk
except ImportError as error:  # pragma: no cover - exercised by launcher diagnostics
    raise SystemExit(
        "Asset Harness GUI requires Tkinter. Install the OS Tk package or set "
        "PYTHON_BIN to a Python interpreter that can import tkinter."
    ) from error

from PIL import Image, ImageDraw

from asset_harness.core.errors import AssetHarnessError
from asset_harness.core.project import load_project
from asset_harness.core.render import render_image, save_png
from asset_harness.core.source import inspect_image
from asset_harness.core.validation import validate_project


DEFAULT_IMAGE = (
    REPO_ROOT
    / "Contents"
    / "mods"
    / "PsychopatzCore"
    / "common"
    / "media"
    / "ui"
    / "psychopatz"
    / "radio"
    / "shells"
    / "DTA_Walkie_Shells.png"
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="View Psychopatz Asset Harness PNGs and project previews")
    parser.add_argument("--image", type=Path, default=None, help="PNG to open on launch")
    parser.add_argument("--project", type=Path, default=None, help="asset-harness project JSON to load on launch")
    parser.add_argument("--state", default="", help="optional render state when --project is supplied")
    parser.add_argument("--variant", default="pristine", help="project variant when --project is supplied")
    return parser


def _checkerboard(size: tuple[int, int], square: int = 12) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size, (54, 60, 68))
    draw = ImageDraw.Draw(image)
    for y in range(0, height, square):
        for x in range(0, width, square):
            if ((x // square) + (y // square)) % 2:
                draw.rectangle((x, y, min(width - 1, x + square - 1), min(height - 1, y + square - 1)), fill=(72, 79, 88))
    return image


def _composite_for_display(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    rgba = image.convert("RGBA").resize(size, Image.Resampling.LANCZOS)
    background = _checkerboard(size)
    background.paste(rgba, (0, 0), rgba.getchannel("A"))
    return background


class AssetHarnessViewer(tk.Tk):
    """Small optional GUI client; all project operations remain in core modules."""

    def __init__(self, *, image_path: Path | None, project_path: Path | None, state: str, variant: str) -> None:
        super().__init__()
        self.title("Psychopatz Asset Harness")
        self.geometry("1180x760")
        self.minsize(820, 540)

        self.project_path: Path | None = None
        self.project: dict[str, Any] | None = None
        self.current_image: Image.Image | None = None
        self.current_path: Path | None = None
        self.photo: tk.PhotoImage | None = None
        self.state_var = tk.StringVar(value=state)
        self.variant_var = tk.StringVar(value=variant)
        self.zoom_var = tk.DoubleVar(value=1.0)
        self.debug_var = tk.BooleanVar(value=False)
        self.grid_var = tk.BooleanVar(value=False)
        self.status_var = tk.StringVar(value="Ready")

        self._build_ui()
        self.bind("<Control-o>", lambda _event: self.open_image())
        self.bind("<Control-p>", lambda _event: self.open_project())
        self.bind("<Control-s>", lambda _event: self.save_preview())
        self.bind("<F5>", lambda _event: self.render_project())
        self.bind("<Configure>", lambda _event: self._redraw())

        self.after(0, lambda: self._load_initial(image_path=image_path, project_path=project_path))

    def _build_ui(self) -> None:
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)

        toolbar = ttk.Frame(self, padding=(10, 8))
        toolbar.grid(row=0, column=0, sticky="ew")
        toolbar.columnconfigure(9, weight=1)

        ttk.Button(toolbar, text="Open PNG", command=self.open_image).grid(row=0, column=0, padx=(0, 6))
        ttk.Button(toolbar, text="Open Project", command=self.open_project).grid(row=0, column=1, padx=(0, 6))
        ttk.Button(toolbar, text="Render", command=self.render_project).grid(row=0, column=2, padx=(0, 6))
        ttk.Button(toolbar, text="Validate", command=self.validate_project).grid(row=0, column=3, padx=(0, 6))
        ttk.Button(toolbar, text="Save Preview", command=self.save_preview).grid(row=0, column=4, padx=(0, 12))
        ttk.Label(toolbar, text="State").grid(row=0, column=5, padx=(0, 4))
        ttk.Entry(toolbar, textvariable=self.state_var, width=12).grid(row=0, column=6, padx=(0, 8))
        ttk.Label(toolbar, text="Variant").grid(row=0, column=7, padx=(0, 4))
        ttk.Entry(toolbar, textvariable=self.variant_var, width=12).grid(row=0, column=8, padx=(0, 8))
        ttk.Checkbutton(toolbar, text="Debug", variable=self.debug_var).grid(row=0, column=9, sticky="e", padx=(0, 6))
        ttk.Checkbutton(toolbar, text="Grid", variable=self.grid_var).grid(row=0, column=10, sticky="e", padx=(0, 6))
        ttk.Label(toolbar, text="Zoom").grid(row=0, column=11, padx=(4, 4))
        ttk.Scale(toolbar, from_=0.25, to=2.5, variable=self.zoom_var, command=lambda _value: self._redraw(), length=130).grid(row=0, column=12)

        content = ttk.Panedwindow(self, orient=tk.HORIZONTAL)
        content.grid(row=1, column=0, sticky="nsew", padx=10, pady=(0, 10))

        preview_frame = ttk.Frame(content, padding=8)
        preview_frame.columnconfigure(0, weight=1)
        preview_frame.rowconfigure(0, weight=1)
        self.canvas = tk.Canvas(preview_frame, background="#20252b", highlightthickness=1, highlightbackground="#47515c")
        self.canvas.grid(row=0, column=0, sticky="nsew")
        content.add(preview_frame, weight=4)

        details_frame = ttk.Frame(content, padding=(8, 8, 0, 8))
        details_frame.columnconfigure(0, weight=1)
        details_frame.rowconfigure(1, weight=1)
        ttk.Label(details_frame, text="Asset details", font=("TkDefaultFont", 11, "bold")).grid(row=0, column=0, sticky="w", pady=(0, 6))
        self.details = tk.Text(details_frame, width=38, wrap="word", background="#171a1f", foreground="#e6edf3", insertbackground="#e6edf3", relief="flat")
        self.details.grid(row=1, column=0, sticky="nsew")
        self.details.configure(state="disabled")
        content.add(details_frame, weight=1)

        ttk.Label(self, textvariable=self.status_var, relief="sunken", anchor="w", padding=(8, 4)).grid(row=2, column=0, sticky="ew")

    def _load_initial(self, *, image_path: Path | None, project_path: Path | None) -> None:
        if project_path is not None:
            self._load_project(project_path, render=True)
            return
        target = image_path.expanduser().resolve() if image_path is not None else DEFAULT_IMAGE
        if target.exists():
            self._load_image(target)
            return
        self._set_details({"message": "Choose Open PNG or Open Project to begin.", "default_image": str(DEFAULT_IMAGE)})
        self._set_status("No default preview asset was found")

    def _set_status(self, message: str) -> None:
        self.status_var.set(message)

    def _set_details(self, value: Any) -> None:
        rendered = json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True, default=str)
        self.details.configure(state="normal")
        self.details.delete("1.0", tk.END)
        self.details.insert("1.0", rendered)
        self.details.configure(state="disabled")

    def _load_image(self, path: Path) -> None:
        try:
            metadata = inspect_image(path)
            with Image.open(path) as source:
                image = source.convert("RGBA")
        except (AssetHarnessError, OSError) as error:
            self._show_error("Unable to open PNG", error)
            return
        self.current_path = path
        self.current_image = image
        self._set_details({"kind": "png", "path": str(path), "metadata": metadata})
        self._set_status(f"Opened {path.name} ({image.width}×{image.height})")
        self._redraw()

    def _load_project(self, path: Path, *, render: bool) -> None:
        try:
            project = load_project(path)
        except (AssetHarnessError, OSError, ValueError) as error:
            self._show_error("Unable to open project", error)
            return
        self.project_path = path
        self.project = project
        self._set_details({"kind": "project", "path": str(path), "project": project})
        self._set_status(f"Loaded project {path.name}")
        if render:
            self.render_project()

    def open_image(self) -> None:
        filename = filedialog.askopenfilename(
            title="Open PNG",
            filetypes=(("PNG images", "*.png"), ("All files", "*.*")),
        )
        if filename:
            self._load_image(Path(filename))

    def open_project(self) -> None:
        filename = filedialog.askopenfilename(
            title="Open Asset Harness project",
            filetypes=(("Project JSON", "*.json"), ("All files", "*.*")),
        )
        if filename:
            self._load_project(Path(filename).resolve(), render=True)

    def render_project(self) -> None:
        if self.project_path is None or self.project is None:
            self._set_status("Open a project before rendering")
            return
        try:
            image, metadata = render_image(
                self.project_path,
                self.project,
                state=self.state_var.get().strip() or None,
                variant=self.variant_var.get().strip() or "pristine",
                scale=1.0,
                debug=self.debug_var.get(),
                grid=self.grid_var.get(),
            )
        except (AssetHarnessError, OSError, ValueError) as error:
            self._show_error("Unable to render project", error)
            return
        self.current_path = None
        self.current_image = image
        self._set_details({"kind": "render", "project": str(self.project_path), "metadata": metadata})
        self._set_status(f"Rendered {self.project_path.name} ({image.width}×{image.height})")
        self._redraw()

    def validate_project(self) -> None:
        if self.project_path is None or self.project is None:
            self._set_status("Open a project before validating")
            return
        try:
            result = validate_project(self.project_path, self.project)
        except (AssetHarnessError, OSError, ValueError) as error:
            self._show_error("Unable to validate project", error)
            return
        self._set_details({"kind": "validation", "project": str(self.project_path), "result": result})
        errors = sum(1 for item in result.get("diagnostics", []) if item.get("severity") == "error")
        warnings = sum(1 for item in result.get("diagnostics", []) if item.get("severity") == "warning")
        self._set_status(f"Validation complete: {errors} error(s), {warnings} warning(s)")

    def save_preview(self) -> None:
        if self.current_image is None:
            self._set_status("There is no preview to save")
            return
        filename = filedialog.asksaveasfilename(
            title="Save preview PNG",
            defaultextension=".png",
            initialfile="asset-harness-preview.png",
            filetypes=(("PNG images", "*.png"),),
        )
        if not filename:
            return
        try:
            save_png(self.current_image, Path(filename).resolve())
        except (AssetHarnessError, OSError, ValueError) as error:
            self._show_error("Unable to save preview", error)
            return
        self._set_status(f"Saved preview to {filename}")

    def _redraw(self) -> None:
        if not hasattr(self, "canvas") or self.current_image is None:
            return
        self.canvas.update_idletasks()
        available_width = max(120, self.canvas.winfo_width() - 24)
        available_height = max(120, self.canvas.winfo_height() - 24)
        requested = max(0.05, float(self.zoom_var.get()))
        factor = min(requested, available_width / self.current_image.width, available_height / self.current_image.height)
        width = max(1, int(round(self.current_image.width * factor)))
        height = max(1, int(round(self.current_image.height * factor)))
        display = _composite_for_display(self.current_image, (width, height))
        encoded = io.BytesIO()
        display.save(encoded, format="PNG", optimize=False)
        self.photo = tk.PhotoImage(data=base64.b64encode(encoded.getvalue()).decode("ascii"))
        self.canvas.delete("all")
        self.canvas.create_image(self.canvas.winfo_width() // 2, self.canvas.winfo_height() // 2, image=self.photo, anchor="center")
        self.canvas.create_text(12, 12, text=f"{self.current_image.width}×{self.current_image.height}  preview {factor:.2f}×", fill="#d8dee9", anchor="nw")

    def _show_error(self, title: str, error: Exception) -> None:
        self._set_status(f"{title}: {error}")
        messagebox.showerror(title, str(error))


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    app = AssetHarnessViewer(
        image_path=args.image,
        project_path=args.project,
        state=args.state,
        variant=args.variant,
    )
    app.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
