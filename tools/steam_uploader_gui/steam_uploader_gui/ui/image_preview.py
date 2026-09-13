from __future__ import annotations

from pathlib import Path
from tkinter import ttk

from PIL import Image, ImageOps, ImageSequence

try:
    from PIL import ImageTk
except ImportError:  # Pillow may be installed without its optional Tk bridge.
    ImageTk = None  # type: ignore[assignment]

from .theme import palette


class ImagePreview(ttk.Frame):
    """Display a local Workshop preview, including animated GIFs."""

    def __init__(self, master: object, max_size: tuple[int, int] = (480, 270)) -> None:
        super().__init__(master)
        self.max_size = max_size
        self._frames: list[ImageTk.PhotoImage] = []
        self._frame_index = 0
        self._duration_ms = 100
        self._animation_job: str | None = None
        self._path: Path | None = None

        self.columnconfigure(0, weight=1)
        self.preview_label = ttk.Label(self, anchor="center")
        self.preview_label.grid(row=0, column=0, sticky="nsew")
        self.status_label = ttk.Label(self, text="No preview selected")
        self.status_label.grid(row=1, column=0, sticky="w", pady=(4, 0))

    def set_dark_mode(self, enabled: bool) -> None:
        self.status_label.configure(foreground=palette(enabled)["muted"])

    def set_path(self, path: Path | None) -> None:
        self._stop_animation()
        self._frames = []
        self._frame_index = 0
        self._path = path
        self.preview_label.configure(image="")

        if path is None or not path.is_file():
            self.status_label.configure(text="No preview selected")
            return
        if ImageTk is None:
            self.status_label.configure(text="Preview unavailable: Pillow Tk support is not installed")
            return

        try:
            with Image.open(path) as source:
                frames: list[ImageTk.PhotoImage] = []
                frame_count = getattr(source, "n_frames", 1)
                for index, frame in enumerate(ImageSequence.Iterator(source)):
                    if index >= 120:
                        break
                    rendered = ImageOps.contain(frame.convert("RGBA"), self.max_size)
                    frames.append(ImageTk.PhotoImage(rendered))
                self._duration_ms = max(40, int(source.info.get("duration", 100)))
                if not frames:
                    raise ValueError("image contains no frames")
        except Exception as exc:
            self.status_label.configure(text=f"Preview unavailable: {exc}")
            return

        self._frames = frames
        self.preview_label.configure(image=self._frames[0])
        suffix = " (animated GIF)" if len(self._frames) > 1 else ""
        self.status_label.configure(text=f"{path.name}{suffix}")
        if len(self._frames) > 1:
            self._animation_job = self.after(self._duration_ms, self._next_frame)

    def _stop_animation(self) -> None:
        if self._animation_job is not None:
            self.after_cancel(self._animation_job)
            self._animation_job = None

    def _next_frame(self) -> None:
        if not self._frames:
            return
        self._frame_index = (self._frame_index + 1) % len(self._frames)
        self.preview_label.configure(image=self._frames[self._frame_index])
        self._animation_job = self.after(self._duration_ms, self._next_frame)

    def destroy(self) -> None:
        self._stop_animation()
        super().destroy()
