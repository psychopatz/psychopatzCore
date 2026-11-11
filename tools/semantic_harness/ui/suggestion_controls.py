"""Manage the bounded button surface for semantic suggestions."""

from __future__ import annotations

from typing import Any


def ensure_suggestion_buttons(app: Any, count: int) -> None:
    while len(app.suggestion_buttons) < count:
        index = len(app.suggestion_buttons)
        button = app._ttk.Button(
            app.suggestion_buttons_frame,
            text="",
            command=lambda index=index: app.click_suggestion(index),
        )
        button.grid(
            row=index // 3,
            column=index % 3,
            sticky="ew",
            padx=3,
            pady=3,
        )
        app.suggestion_buttons.append(button)


def refresh_suggestion_controls(app: Any, enabled: bool) -> None:
    for index, button in enumerate(app.suggestion_buttons):
        row = app.suggestion_rows[index] if index < len(app.suggestion_rows) else None
        if row:
            button.grid()
        else:
            button.grid_remove()
        button.configure(
            state=(
                "normal"
                if enabled
                and app.suggestion_interactive
                and row
                and row.get("enabled") is True
                else "disabled"
            )
        )
