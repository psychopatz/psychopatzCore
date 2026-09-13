from __future__ import annotations

import queue
import threading
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk

from ..core.config import (
    SETTING_DARK_MODE,
    SETTING_IDENTIFIER_EDITING,
    SETTING_UPLOADER_PATH,
    SETTING_WORKSHOP_ROOT,
    default_database_path,
    default_log_dir,
    default_workshop_root,
    first_existing_uploader,
)
from ..core.discovery import discover_profiles
from ..core.models import ModProfile, UpdateSelection
from ..persistence.database import SettingsDatabase
from ..services.logging import EventLogger
from ..services.uploader import (
    BackendError,
    SelectiveBackendUnavailable,
    StockSteamUploader,
    validate,
)
from ..services.workshop import WorkshopItem, fetch_workshop_item, open_workshop_page
from .editor import ModEditor
from .log_panel import LiveLogPanel
from .project_list import ProjectList
from .settings_dialog import SettingsDialog
from .state import UIStateStore
from .theme import apply_theme
from .widgets import CollapsibleSection, ScrollableFrame


class WorkshopApplication(tk.Tk):
    """Application shell coordinating independent UI components and services."""

    def __init__(self) -> None:
        super().__init__()
        self.title("Project Zomboid Workshop Uploader")
        self.minsize(900, 600)
        self.database = SettingsDatabase(default_database_path())
        self.ui_state = UIStateStore(self.database)
        self.identifier_editing_enabled = self.database.get_setting(
            SETTING_IDENTIFIER_EDITING, "0"
        ).strip().lower() in {"1", "true", "yes", "on"}
        self.dark_mode_enabled = self.database.get_setting(
            SETTING_DARK_MODE, "0"
        ).strip().lower() in {"1", "true", "yes", "on"}
        apply_theme(self, self.dark_mode_enabled)
        self._restore_or_choose_geometry()

        self.events: queue.Queue[dict[str, object]] = queue.Queue()
        self.logger = EventLogger(self.database, default_log_dir(), self.events.put)
        self.profiles: dict[str, ModProfile] = {}
        self.current_key: str | None = None
        self._steam_fetching = False

        self.current_mod_var = tk.StringVar(value="No mod selected")
        self.status_var = tk.StringVar(value="Ready")
        self._build_ui()
        self.after(100, self._drain_events)
        self.protocol("WM_DELETE_WINDOW", self._close)
        self._scan()

    def _restore_or_choose_geometry(self) -> None:
        saved = self.ui_state.get("window_geometry")
        if saved:
            self.geometry(saved)
            return
        self.update_idletasks()
        screen_width = self.winfo_screenwidth()
        screen_height = self.winfo_screenheight()
        width = min(1400, max(900, int(screen_width * 0.88)))
        height = min(900, max(600, int(screen_height * 0.84)))
        self.geometry(f"{width}x{height}")

    def _build_ui(self) -> None:
        toolbar = ttk.Frame(self, padding=(8, 8, 8, 4))
        toolbar.pack(fill="x")
        toolbar.columnconfigure(1, weight=1)
        ttk.Label(toolbar, text="Current mod:").grid(row=0, column=0, sticky="w")
        ttk.Label(toolbar, textvariable=self.current_mod_var).grid(row=0, column=1, sticky="w", padx=6)
        ttk.Button(toolbar, text="Refresh", command=self._scan).grid(row=0, column=2, padx=(6, 0))
        self.fetch_steam_button = ttk.Button(toolbar, text="Fetch Steam data", command=self._fetch_steam_data)
        self.fetch_steam_button.grid(
            row=0, column=3, padx=(6, 0)
        )
        ttk.Button(toolbar, text="Open Workshop page", command=self._open_workshop_page).grid(
            row=0, column=4, padx=(6, 0)
        )
        ttk.Button(toolbar, text="Settings…", command=self._open_settings).grid(
            row=0, column=5, padx=(6, 0)
        )

        body = ttk.PanedWindow(self, orient="horizontal")
        body.pack(fill="both", expand=True, padx=8, pady=(0, 4))

        left = ttk.Frame(body, padding=6)
        left.columnconfigure(0, weight=1)
        left.rowconfigure(0, weight=1)
        self.project_list = ProjectList(left, self._select_profile)
        self.project_list.grid(row=0, column=0, sticky="nsew")
        self.project_list.set_dark_mode(self.dark_mode_enabled)

        right = ttk.Frame(body, padding=6)
        right.columnconfigure(0, weight=1)
        right.rowconfigure(0, weight=1)
        self.editor_scroll = ScrollableFrame(right)
        self.editor_scroll.grid(row=0, column=0, sticky="nsew")
        self.editor = ModEditor(
            self.editor_scroll.content,
            get_section_state=self._get_section_state,
            set_section_state=self._set_section_state,
            on_update_selection_changed=self._persist_update_selection,
            dark_mode=self.dark_mode_enabled,
        )
        self.editor.set_identifier_editing_enabled(self.identifier_editing_enabled)
        self.editor.pack(fill="x", expand=False)

        self.log_section = CollapsibleSection(
            self.editor_scroll.content,
            "Live process log",
            expanded=self._get_section_state("global", "log", False),
            on_toggle=lambda expanded: self._set_section_state("global", "log", expanded),
        )
        self.log_section.pack(fill="x", pady=(0, 8))
        self.log_panel = LiveLogPanel(self.log_section.body)
        self.log_panel.pack(fill="both", expand=True)
        self.log_panel.set_dark_mode(self.dark_mode_enabled)
        self.editor_scroll.set_dark_mode(self.dark_mode_enabled)
        self.log_section.body.configure(height=180)
        self.log_section.body.pack_propagate(False)

        actions = ttk.Frame(right, padding=(0, 6, 0, 0))
        actions.grid(row=1, column=0, sticky="ew")
        ttk.Button(actions, text="Save profile", command=self._save_profile).pack(side="left")
        ttk.Button(actions, text="Validate plan", command=self._validate_plan).pack(side="left", padx=6)
        ttk.Button(actions, text="Dry run", command=self._dry_run).pack(side="left")
        ttk.Button(actions, text="Upload", command=self._upload).pack(side="right")

        body.add(left, weight=1)
        body.add(right, weight=4)
        ttk.Label(self, textvariable=self.status_var, relief="sunken", anchor="w").pack(fill="x", side="bottom")

    def _get_section_state(self, scope: str, section: str, default: bool) -> bool:
        return self.ui_state.get_bool(f"{scope}/section/{section}", default)

    def _set_section_state(self, scope: str, section: str, expanded: bool) -> None:
        self.ui_state.set_bool(f"{scope}/section/{section}", expanded)

    def _scan(self) -> None:
        root = Path(self.database.get_setting(SETTING_WORKSHOP_ROOT, str(default_workshop_root()))).expanduser()
        discovered = discover_profiles(root)
        self.profiles = {}
        for profile in discovered:
            saved = self.database.load_profile(profile.key)
            if saved is not None and self._is_legacy_truncated_description(saved.description, profile.description):
                # Older builds overwrote repeated description= keys and saved
                # only the final line. Repair that exact shape from the local
                # Workshop source without replacing an intentional edit.
                saved.description = profile.description
                self.database.save_profile(saved)
                self.logger.emit(
                    "INFO",
                    "migration",
                    "Repaired truncated cached Workshop description.",
                    mod=profile.name,
                    key=profile.key,
                )
            self.profiles[profile.key] = saved or profile
        self.project_list.set_projects(
            (profile.key, f"{profile.name}  [{profile.key}]") for profile in self.profiles.values()
        )
        self.status_var.set(f"Found {len(discovered)} Workshop project(s) under {root}")
        self.logger.emit("INFO", "scan", "Workshop scan completed.", root=str(root), count=len(discovered))

        preferred = self.ui_state.get("selected_profile")
        selected = preferred if preferred in self.profiles else (discovered[0].key if discovered else None)
        self.project_list.select_key(selected)
        if selected is None:
            self.current_key = None
            self.current_mod_var.set("No mod selected")

    @staticmethod
    def _is_legacy_truncated_description(saved: str, discovered: str) -> bool:
        """Identify the previous repeated-key parser's exact last-line output."""

        if not saved or "\n" not in discovered or len(discovered) <= len(saved):
            return False
        return discovered.rsplit("\n", 1)[-1] == saved

    def _select_profile(self, key: str) -> None:
        if key not in self.profiles:
            return
        if self.current_key == key:
            return
        if self.current_key is not None and self.editor.dirty:
            if not messagebox.askyesno(
                "Discard unsaved changes?",
                "The current mod has unsaved changes. Switch projects and discard them?",
                parent=self,
            ):
                self.project_list.select_key(self.current_key)
                return

        profile = self.profiles[key]
        self.current_key = key
        self.editor.set_profile(profile)
        saved_selection = self.ui_state.get_json(f"{UIStateStore.profile_scope(key)}/updates", None)
        self.editor.set_update_selection(saved_selection)
        self.editor.mark_clean()
        self.ui_state.set("selected_profile", key)
        self.current_mod_var.set(profile.name)
        self.status_var.set(f"Editing {profile.name}")

    def _collect(self) -> ModProfile:
        if not self.current_key:
            raise BackendError("Select a Workshop project first.")
        return self.editor.collect_profile(self.profiles[self.current_key])

    def _save_profile(self) -> ModProfile | None:
        try:
            profile = self._collect()
            if not self._confirm_identifier_change(profile.key):
                return None
            self.profiles[profile.key] = profile
            self.database.save_profile(profile)
            self._persist_update_selection()
            self.project_list.update_label(profile.key, f"{profile.name}  [{profile.key}]")
            self.editor.mark_clean()
            self.current_mod_var.set(profile.name)
            self.logger.emit("INFO", "profile", "Profile saved.", mod=profile.name, key=profile.key)
            self.status_var.set(f"Saved profile: {profile.name}")
            return profile
        except (BackendError, OSError, ValueError) as exc:
            self.logger.emit("ERROR", "profile", str(exc))
            messagebox.showerror("Profile error", str(exc), parent=self)
            return None

    def _validate_plan(self) -> tuple[ModProfile, UpdateSelection] | None:
        try:
            profile = self._collect()
            selection = self.editor.selection()
            validation = validate(profile, selection)
            for warning in validation.warnings:
                self.logger.emit("WARNING", "validate", warning)
            for error in validation.errors:
                self.logger.emit("ERROR", "validate", error)
            if validation.ok:
                if selection.is_full_update:
                    capability = "full stock backend"
                else:
                    uploader = StockSteamUploader(
                        Path(self.database.get_setting(SETTING_UPLOADER_PATH)).expanduser(),
                        self.logger,
                    )
                    capability = (
                        "selective backend available"
                        if uploader.selective_available
                        else "selective backend unavailable"
                    )
                self.logger.emit("INFO", "validate", "Plan is valid.", fields=selection.fields, execution=capability)
                self.status_var.set(f"Valid plan: {', '.join(selection.fields)} ({capability})")
                return profile, selection
            self.status_var.set(f"Plan has {len(validation.errors)} error(s)")
            return None
        except (BackendError, OSError, ValueError) as exc:
            self.logger.emit("ERROR", "validate", str(exc))
            self.status_var.set(str(exc))
            return None

    def _dry_run(self) -> None:
        plan = self._validate_plan()
        if not plan:
            return
        profile, selection = plan
        uploader = StockSteamUploader(
            Path(self.database.get_setting(SETTING_UPLOADER_PATH)).expanduser(),
            self.logger,
        )
        uploader.dry_run(profile, selection)

    def _persist_update_selection(self) -> None:
        if not self.current_key:
            return
        selection = self.editor.selection()
        self.ui_state.set_json(
            f"{UIStateStore.profile_scope(self.current_key)}/updates",
            {
                **{
                    name: bool(getattr(selection, name))
                    for name in ("content", "preview", "title", "description", "tags", "visibility")
                },
                "change_note": selection.change_note,
            },
        )

    def _open_workshop_page(self) -> None:
        try:
            profile = self._collect()
            if profile.workshopid is None or profile.workshopid <= 0:
                raise BackendError("A valid Workshop ID is required to open the Workshop page.")
            open_workshop_page(profile.workshopid)
            self.logger.emit(
                "INFO", "workshop", "Opened Workshop page.", workshopid=profile.workshopid
            )
        except (BackendError, OSError, ValueError) as exc:
            self.logger.emit("ERROR", "workshop", str(exc))
            messagebox.showerror("Workshop page", str(exc), parent=self)

    def _fetch_steam_data(self) -> None:
        if self._steam_fetching:
            self.status_var.set("A Steam metadata fetch is already running…")
            return
        try:
            profile = self._collect()
            if profile.workshopid is None or profile.workshopid <= 0:
                raise BackendError("A valid Workshop ID is required to fetch Steam data.")
        except (BackendError, OSError, ValueError) as exc:
            self.logger.emit("ERROR", "workshop", str(exc))
            messagebox.showerror("Fetch Steam data", str(exc), parent=self)
            return

        key = profile.key
        self._steam_fetching = True
        self.fetch_steam_button.configure(state="disabled")
        self.status_var.set(f"Fetching Steam data for {profile.title} (up to 6 seconds)…")
        self.logger.emit(
            "INFO", "workshop", "Fetching Workshop metadata.", workshopid=profile.workshopid
        )
        thread = threading.Thread(
            target=self._fetch_worker,
            args=(key, profile.workshopid),
            daemon=True,
        )
        thread.start()

    def _fetch_worker(self, key: str, workshopid: int | None) -> None:
        try:
            if workshopid is None:
                raise BackendError("A valid Workshop ID is required to fetch Steam data.")
            item = fetch_workshop_item(workshopid)
            self.events.put({"steam_item": item, "profile_key": key})
        except Exception as exc:
            self.logger.emit("ERROR", "workshop", str(exc), workshopid=workshopid)
            self.events.put({"ui_status": "Steam data fetch failed; see live log."})
        finally:
            self.events.put({"steam_fetch_done": True})

    def _apply_fetched_item(self, key: str, item: WorkshopItem) -> None:
        if key != self.current_key or key not in self.profiles:
            return
        self.editor.apply_workshop_metadata(
            item.title,
            item.description,
            item.tags,
            item.visibility,
        )
        self.profiles[key] = self.editor.collect_profile(self.profiles[key])
        self.project_list.update_label(key, f"{item.title}  [{key}]")
        self.current_mod_var.set(item.title)
        self.logger.emit(
            "INFO",
            "workshop",
            "Steam Workshop metadata loaded into the editor; review and save it.",
            workshopid=item.published_file_id,
            preview_url=item.preview_url,
            file_url=item.file_url,
        )
        self.status_var.set("Steam data loaded; review the fields and save the profile.")

    def _upload(self) -> None:
        plan = self._validate_plan()
        if not plan:
            return
        profile, selection = plan
        if not self._confirm_identifier_change(profile.key):
            return
        uploader_path = Path(self.database.get_setting(SETTING_UPLOADER_PATH)).expanduser()
        uploader = StockSteamUploader(uploader_path, self.logger)
        if not selection.is_full_update:
            if not uploader.selective_available:
                error = SelectiveBackendUnavailable(
                    "The installed SteamUploader backend does not expose selective updates."
                )
                self.logger.emit("ERROR", "upload", str(error), fields=selection.fields)
                messagebox.showwarning(
                    "Selective backend required",
                    "No upload was started. Install a SteamUploader build with the selective update command.",
                    parent=self,
                )
                return
        if not messagebox.askyesno(
            "Confirm Workshop upload",
            f"Upload the selected fields for {profile.title}?",
            parent=self,
        ):
            self.logger.emit("INFO", "upload", "User cancelled upload.")
            return
        self.database.save_profile(profile)
        self.profiles[profile.key] = profile
        self.status_var.set("Uploading…")
        self.logger.emit("INFO", "upload", "Upload approved by user.", mod=profile.name, fields=selection.fields)
        thread = threading.Thread(
            target=self._upload_worker,
            args=(profile, selection, uploader_path),
            daemon=True,
        )
        thread.start()

    def _confirm_identifier_change(self, key: str) -> bool:
        if not self.editor.identifier_editing_enabled:
            return True
        previous = self.profiles.get(key)
        if previous is None or not self.editor.identifiers_changed(previous):
            return True
        return messagebox.askyesno(
            "Confirm identifier change",
            "App ID or Workshop ID was changed. Continue with this unsafe identifier edit?",
            parent=self,
        )

    def _upload_worker(self, profile: ModProfile, selection: UpdateSelection, uploader_path: Path) -> None:
        try:
            uploader = StockSteamUploader(uploader_path, self.logger)
            result = uploader.upload(profile, selection)
            self.events.put({"ui_status": f"Uploader exited with code {result.exit_code}"})
        except Exception as exc:  # worker boundary: report every failure to the visible log
            self.logger.emit("ERROR", "upload", str(exc))
            self.events.put({"ui_status": "Upload failed; see live log."})

    def _open_settings(self) -> None:
        SettingsDialog(
            self,
            self.database,
            self.database.get_setting(SETTING_WORKSHOP_ROOT, str(default_workshop_root())),
            self.database.get_setting(
                SETTING_UPLOADER_PATH,
                str(first_existing_uploader() or ""),
            ),
            self.identifier_editing_enabled,
            self.dark_mode_enabled,
            self._settings_saved,
        )

    def _settings_saved(
        self,
        workshop_root: str,
        uploader_path: str,
        identifier_editing: bool,
        dark_mode: bool,
    ) -> None:
        self.identifier_editing_enabled = identifier_editing
        self.dark_mode_enabled = dark_mode
        apply_theme(self, self.dark_mode_enabled)
        self.editor.set_identifier_editing_enabled(identifier_editing)
        self.editor.set_dark_mode(self.dark_mode_enabled)
        self.project_list.set_dark_mode(self.dark_mode_enabled)
        self.editor_scroll.set_dark_mode(self.dark_mode_enabled)
        self.log_panel.set_dark_mode(self.dark_mode_enabled)
        self.logger.emit(
            "INFO",
            "settings",
            "Application settings saved.",
            workshop_root=workshop_root,
            uploader_path=uploader_path,
            identifier_editing=identifier_editing,
            dark_mode=dark_mode,
        )
        self.status_var.set("Settings saved")
        self._scan()

    def _drain_events(self) -> None:
        while True:
            try:
                event = self.events.get_nowait()
            except queue.Empty:
                break
            if "steam_item" in event:
                self._apply_fetched_item(
                    str(event.get("profile_key", "")),
                    event["steam_item"],
                )
            if event.get("steam_fetch_done"):
                self._steam_fetching = False
                self.fetch_steam_button.configure(state="normal")
            if "steam_item" in event:
                continue
            if event.get("steam_fetch_done"):
                continue
            if "ui_status" in event:
                self.status_var.set(str(event["ui_status"]))
            else:
                self.log_panel.append(event)
        self.after(100, self._drain_events)

    def _close(self) -> None:
        self._persist_update_selection()
        self.ui_state.set("window_geometry", self.geometry())
        self.database.close()
        self.destroy()
