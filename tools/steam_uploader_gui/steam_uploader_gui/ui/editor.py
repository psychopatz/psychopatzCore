from __future__ import annotations

import tkinter as tk
from collections.abc import Callable
from pathlib import Path
from tkinter import ttk

from ..core.limits import MAX_CHANGE_NOTE_LENGTH, MAX_DESCRIPTION_LENGTH, MAX_TITLE_LENGTH
from ..core.models import ModProfile, UpdateSelection
from ..features.bbcode.widget import BBCodeEditor
from .widgets import CollapsibleSection, VerticalResizeGrip
from .image_preview import ImagePreview


class ModEditor(ttk.Frame):
    """Responsive, stateful editor for one discovered Workshop project."""

    _SECTION_DEFAULTS = {
        "identifiers": True,
        "metadata": True,
        "description": True,
        "updates": False,
    }

    def __init__(
        self,
        master: object,
        get_section_state: Callable[[str, str, bool], bool],
        set_section_state: Callable[[str, str, bool], None],
        on_update_selection_changed: Callable[[], None] | None = None,
        dark_mode: bool = False,
    ) -> None:
        super().__init__(master)
        self.columnconfigure(0, weight=1)
        self._get_section_state = get_section_state
        self._set_section_state = set_section_state
        self._on_update_selection_changed = on_update_selection_changed
        self._scope = "global"
        self._loading = False
        self._dirty = False
        self._identifier_editing_enabled = False
        self._dark_mode = bool(dark_mode)

        self.appid_var = tk.StringVar()
        self.workshopid_var = tk.StringVar()
        self.mod_root_var = tk.StringVar()
        self.content_var_path = tk.StringVar()
        self.preview_var_path = tk.StringVar()
        self.title_var = tk.StringVar()
        self.visibility_var = tk.StringVar(value="Private")
        self.tags_var = tk.StringVar()
        self.update_content_var = tk.BooleanVar(value=True)
        self.update_preview_var = tk.BooleanVar(value=True)
        self.update_title_var = tk.BooleanVar(value=True)
        self.update_description_var = tk.BooleanVar(value=True)
        self.update_tags_var = tk.BooleanVar(value=True)
        self.update_visibility_var = tk.BooleanVar(value=True)
        self.description_height_var = tk.DoubleVar(value=420)

        self._appid_entry: ttk.Entry
        self._workshopid_entry: ttk.Entry
        self.sections: dict[str, CollapsibleSection] = {}
        self._build()
        self._attach_dirty_tracking()
        self.set_dark_mode(self._dark_mode)

    @property
    def dirty(self) -> bool:
        return self._dirty

    @property
    def identifier_editing_enabled(self) -> bool:
        return self._identifier_editing_enabled

    def set_identifier_editing_enabled(self, enabled: bool) -> None:
        self._identifier_editing_enabled = bool(enabled)
        self._update_identifier_state()

    def set_dark_mode(self, enabled: bool) -> None:
        self._dark_mode = bool(enabled)
        self.description_editor.set_dark_mode(self._dark_mode)
        self.change_note_editor.set_dark_mode(self._dark_mode)
        self.preview_image.set_dark_mode(self._dark_mode)
        self.description_resize_grip.set_dark_mode(self._dark_mode)

    def _build(self) -> None:
        identifiers = self._section("identifiers", "Identifiers and files")
        identifiers.body.columnconfigure(1, weight=1)
        self._appid_entry = self._field(
            identifiers.body, "App ID", self.appid_var, 0, state="readonly"
        )
        self._workshopid_entry = self._field(
            identifiers.body, "Workshop ID", self.workshopid_var, 1, state="readonly"
        )
        self._field(identifiers.body, "Mod root", self.mod_root_var, 2)
        self._field(identifiers.body, "Content directory", self.content_var_path, 3)
        self._field(identifiers.body, "Preview file", self.preview_var_path, 4)
        preview_frame = ttk.LabelFrame(identifiers.body, text="Primary preview")
        preview_frame.grid(row=5, column=0, columnspan=2, sticky="ew", pady=(8, 0))
        self.preview_image = ImagePreview(preview_frame)
        self.preview_image.pack(fill="x", expand=True, padx=6, pady=6)

        metadata = self._section("metadata", "Workshop metadata")
        metadata.body.columnconfigure(1, weight=1)
        self._field(metadata.body, f"Title ({MAX_TITLE_LENGTH} max)", self.title_var, 0)
        self._field(metadata.body, "Tags (; separated)", self.tags_var, 1)
        ttk.Label(metadata.body, text="Visibility").grid(row=2, column=0, sticky="w", pady=3)
        ttk.Combobox(
            metadata.body,
            textvariable=self.visibility_var,
            state="readonly",
            values=("Public", "Friends Only", "Private", "Unlisted"),
        ).grid(row=2, column=1, sticky="ew", pady=3)

        description = self._section("description", "Description / BBCode")
        resize_bar = ttk.Frame(description.body)
        resize_bar.pack(fill="x", pady=(0, 4))
        ttk.Label(resize_bar, text="Panel height").pack(side="left")
        ttk.Scale(
            resize_bar,
            from_=300,
            to=1200,
            variable=self.description_height_var,
            command=self._description_scale_changed,
            length=220,
        ).pack(side="left", padx=(8, 6))
        self.description_height_label = ttk.Label(resize_bar, text="420 px")
        self.description_height_label.pack(side="left")
        self.description_editor = BBCodeEditor(
            description.body,
            max_length=MAX_DESCRIPTION_LENGTH,
            editor_title="Steam Workshop description editor",
            dark_mode=self._dark_mode,
        )
        self.description_editor.pack(fill="both", expand=True)
        description.body.configure(height=420)
        description.body.pack_propagate(False)
        self.description_resize_grip = VerticalResizeGrip(
            description.body,
            self._resize_description,
            min_height=300,
            max_height=1200,
        )
        self.description_resize_grip.pack(side="bottom", anchor="e")

        updates = self._section("updates", "Fields to update")
        checks = [
            ("Content (Contents directory)", self.update_content_var),
            ("Primary preview", self.update_preview_var),
            ("Title", self.update_title_var),
            ("Description", self.update_description_var),
            ("Tags", self.update_tags_var),
            ("Visibility", self.update_visibility_var),
        ]
        for index, (label, variable) in enumerate(checks):
            ttk.Checkbutton(
                updates.body,
                text=label,
                variable=variable,
            ).grid(row=index // 2, column=index % 2, sticky="w", padx=(0, 18), pady=3)
        ttk.Label(
            updates.body,
            text="Change note / BBCode",
        ).grid(row=3, column=0, columnspan=2, sticky="w", pady=(8, 3))
        self.change_note_editor = BBCodeEditor(
            updates.body,
            max_length=MAX_CHANGE_NOTE_LENGTH,
            text_height=6,
            editor_title="Steam Workshop change note editor",
            dark_mode=self._dark_mode,
        )
        self.change_note_editor.grid(row=4, column=0, columnspan=2, sticky="ew")
        updates.body.columnconfigure(1, weight=1)

    def _section(self, key: str, title: str) -> CollapsibleSection:
        section = CollapsibleSection(
            self,
            title,
            expanded=self._SECTION_DEFAULTS[key],
            on_toggle=lambda expanded, section_key=key: self._section_toggled(section_key, expanded),
        )
        section.pack(fill="x", pady=(0, 8))
        self.sections[key] = section
        return section

    def _field(
        self,
        parent: ttk.Frame,
        label: str,
        variable: tk.StringVar,
        row: int,
        state: str = "normal",
    ) -> ttk.Entry:
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", pady=3)
        entry = ttk.Entry(parent, textvariable=variable, state=state)
        entry.grid(row=row, column=1, sticky="ew", pady=3)
        return entry

    def _attach_dirty_tracking(self) -> None:
        variables = (
            self.appid_var,
            self.workshopid_var,
            self.mod_root_var,
            self.content_var_path,
            self.preview_var_path,
            self.title_var,
            self.visibility_var,
            self.tags_var,
            self.update_content_var,
            self.update_preview_var,
            self.update_title_var,
            self.update_description_var,
            self.update_tags_var,
            self.update_visibility_var,
        )
        for variable in variables:
            variable.trace_add("write", self._mark_dirty_from_variable)
        for variable in (
            self.update_content_var,
            self.update_preview_var,
            self.update_title_var,
            self.update_description_var,
            self.update_tags_var,
            self.update_visibility_var,
        ):
            variable.trace_add("write", self._persist_selection_from_variable)
        self.preview_var_path.trace_add("write", self._preview_path_changed)
        self.description_editor.source.bind("<KeyRelease>", self._mark_dirty_from_event, add="+")
        self.description_editor.source.bind("<<Paste>>", self._mark_dirty_from_event, add="+")
        self.description_editor.source.bind("<<BBCodeChanged>>", self._mark_dirty_from_event, add="+")
        self.change_note_editor.source.bind("<KeyRelease>", self._mark_dirty_from_event, add="+")
        self.change_note_editor.source.bind("<<Paste>>", self._mark_dirty_from_event, add="+")
        self.change_note_editor.source.bind("<<BBCodeChanged>>", self._mark_dirty_from_event, add="+")
        self.change_note_editor.source.bind("<KeyRelease>", self._persist_selection_from_event, add="+")
        self.change_note_editor.source.bind("<<Paste>>", self._persist_selection_from_event, add="+")
        self.change_note_editor.source.bind("<<BBCodeChanged>>", self._persist_selection_from_event, add="+")

    def _mark_dirty_from_variable(self, *_args: object) -> None:
        self._mark_dirty()

    def _mark_dirty_from_event(self, _event: object = None) -> None:
        self._mark_dirty()

    def _mark_dirty(self) -> None:
        if not self._loading:
            self._dirty = True

    def _persist_selection_from_variable(self, *_args: object) -> None:
        if not self._loading and self._on_update_selection_changed:
            self._on_update_selection_changed()

    def _persist_selection_from_event(self, _event: object = None) -> None:
        if not self._loading and self._on_update_selection_changed:
            self._on_update_selection_changed()

    def _preview_path_changed(self, *_args: object) -> None:
        if not self._loading:
            value = self.preview_var_path.get().strip()
            self.preview_image.set_path(Path(value).expanduser() if value else None)

    def _resize_description(self, height: int) -> None:
        self.description_height_var.set(height)
        self.description_height_label.configure(text=f"{height} px")
        self.sections["description"].body.configure(height=height)

    def _description_scale_changed(self, value: str) -> None:
        self._resize_description(max(300, min(1200, int(float(value)))))

    def mark_clean(self) -> None:
        self._dirty = False

    def set_profile_scope(self, scope: str) -> None:
        self._scope = scope
        self._loading = True
        for key, section in self.sections.items():
            section.set_expanded(
                self._get_section_state(scope, key, self._SECTION_DEFAULTS[key]),
                notify=False,
            )
        self._update_identifier_state()
        self._loading = False

    def _section_toggled(self, key: str, expanded: bool) -> None:
        self._set_section_state(self._scope, key, expanded)

    def _update_identifier_state(self) -> None:
        state = "normal" if self._identifier_editing_enabled else "readonly"
        self._appid_entry.configure(state=state)
        self._workshopid_entry.configure(state=state)

    def set_profile(self, profile: ModProfile) -> None:
        self.description_editor.close_expanded()
        self.change_note_editor.close_expanded()
        self._loading = True
        self.appid_var.set(str(profile.appid))
        self.workshopid_var.set(str(profile.workshopid or ""))
        self.mod_root_var.set(str(profile.mod_root))
        self.content_var_path.set(str(profile.content_path or ""))
        self.preview_var_path.set(str(profile.preview_path or ""))
        self.title_var.set(profile.title)
        self.tags_var.set(";".join(profile.tags))
        self.visibility_var.set(
            {0: "Public", 1: "Friends Only", 2: "Private", 3: "Unlisted"}.get(
                profile.visibility, "Private"
            )
        )
        self.description_editor.set_source(profile.description)
        self.preview_image.set_path(profile.preview_path)
        self.set_profile_scope(f"profile/{profile.key}")
        self._loading = False
        self.mark_clean()

    def set_update_selection(self, selection: UpdateSelection | dict[str, object] | None) -> None:
        self._loading = True
        if selection is None:
            values: dict[str, object] = {}
        elif isinstance(selection, dict):
            values = selection
        else:
            values = {
                name: bool(getattr(selection, name))
                for name in ("content", "preview", "title", "description", "tags", "visibility")
            }
        for name, variable in (
            ("content", self.update_content_var),
            ("preview", self.update_preview_var),
            ("title", self.update_title_var),
            ("description", self.update_description_var),
            ("tags", self.update_tags_var),
            ("visibility", self.update_visibility_var),
        ):
            variable.set(bool(values.get(name, True)))
        self.change_note_editor.set_source(str(values.get("change_note", "")))
        self._loading = False

    def collect_profile(self, base: ModProfile) -> ModProfile:
        try:
            appid = int(self.appid_var.get().strip())
        except ValueError as exc:
            raise ValueError("App ID must be an integer.") from exc
        workshop_text = self.workshopid_var.get().strip()
        try:
            workshopid = int(workshop_text) if workshop_text else None
        except ValueError as exc:
            raise ValueError("Workshop ID must be an integer.") from exc
        visibility = {"Public": 0, "Friends Only": 1, "Private": 2, "Unlisted": 3}[self.visibility_var.get()]
        return ModProfile(
            key=base.key,
            name=self.title_var.get().strip() or base.name,
            mod_root=Path(self.mod_root_var.get()).expanduser(),
            appid=appid,
            workshopid=workshopid,
            content_path=Path(self.content_var_path.get()).expanduser() if self.content_var_path.get().strip() else None,
            preview_path=Path(self.preview_var_path.get()).expanduser() if self.preview_var_path.get().strip() else None,
            title=self.title_var.get().strip(),
            description=self.description_editor.get_source(),
            visibility=visibility,
            tags=[tag.strip() for tag in self.tags_var.get().split(";") if tag.strip()],
        )

    def identifiers_changed(self, base: ModProfile) -> bool:
        """Return whether the protected identifiers differ from the loaded profile."""

        try:
            appid = int(self.appid_var.get().strip())
            workshop_text = self.workshopid_var.get().strip()
            workshopid = int(workshop_text) if workshop_text else None
        except ValueError:
            return True
        return appid != base.appid or workshopid != base.workshopid

    def selection(self) -> UpdateSelection:
        return UpdateSelection(
            content=self.update_content_var.get(),
            preview=self.update_preview_var.get(),
            title=self.update_title_var.get(),
            description=self.update_description_var.get(),
            tags=self.update_tags_var.get(),
            visibility=self.update_visibility_var.get(),
            change_note=self.change_note_editor.get_source(),
        )

    def apply_workshop_metadata(
        self,
        title: str,
        description: str,
        tags: list[str],
        visibility: int,
    ) -> None:
        """Apply metadata fetched from Steam while leaving local file paths intact."""

        self._loading = True
        self.title_var.set(title)
        self.tags_var.set(";".join(tags))
        self.visibility_var.set(
            {0: "Public", 1: "Friends Only", 2: "Private", 3: "Unlisted"}.get(
                visibility, "Private"
            )
        )
        self.description_editor.set_source(description)
        self._loading = False
        self._dirty = True
