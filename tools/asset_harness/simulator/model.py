"""Deterministic radio state and command reducer."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Mapping

from .catalog import DeviceGeometry, DeviceSpec, get_device, normalize_variant


SCHEMA_VERSION = 1
MAX_EVENT_LOG = 100
HOME_ITEMS = ("Contacts", "Settings")
CONTACTS = ("Emergency Broadcast", "Valley Station", "Riverside Relay")


@dataclass
class RadioState:
    device_id: str
    variant: str = "clean"
    powered: bool = False
    volume: int = 5
    channel: int = 1
    signal: str = "none"
    page: str = "home"
    menu_index: int = 0
    battery: int = 82
    transmitting: bool = False
    clock_ms: int = 0
    last_event: str = "reset"
    event_log: list[dict[str, Any]] = field(default_factory=list)


class RadioSimulator:
    """Owns all mutable simulator state and exposes command/query methods."""

    def __init__(self, device_id: str = "walkie_1", *, variant: str = "clean") -> None:
        self.state = RadioState(device_id=device_id, variant=normalize_variant(variant))
        self._validate_state()

    @property
    def device(self) -> DeviceSpec:
        return get_device(self.state.device_id)

    @property
    def geometry(self) -> DeviceGeometry:
        """Return hitboxes and screen bounds for the active artwork half."""

        return self.device.geometry_for(self.state.variant)

    def reset(self, *, device_id: str | None = None, variant: str | None = None) -> dict[str, Any]:
        next_device = device_id or self.state.device_id
        next_variant = normalize_variant(variant or self.state.variant)
        get_device(next_device)
        self.state = RadioState(device_id=next_device, variant=next_variant)
        return self.snapshot()

    def snapshot(self) -> dict[str, Any]:
        state = asdict(self.state)
        state["event_log"] = list(self.state.event_log)
        state["device"] = {
            "id": self.device.id,
            "label": self.device.label,
            "family": self.device.family,
            "full_type": self.device.full_type,
            "asset": str(self.device.asset_path),
            "asset_exists": self.device.asset_exists,
        }
        state["available_controls"] = [
            {"id": control.id, "label": control.label, "action": control.action}
            for control in self.geometry.controls
        ]
        state["screen"] = self.screen_lines()
        return {"schema_version": SCHEMA_VERSION, "state": state}

    def screen_lines(self) -> list[str]:
        if not self.state.powered:
            return ["POWER OFF", "", "Press Power"]
        header = f"CH {self.state.channel:02d}  VOL {self.state.volume:02d}"
        if self.state.signal == "found":
            signal = "SIGNAL ███"
        elif self.state.signal == "search":
            signal = "SEARCH ▒▒▒"
        else:
            signal = "NO SIGNAL"
        if self.state.page == "home":
            return [header, signal, *self._menu_lines(HOME_ITEMS)]
        if self.state.page == "contacts":
            return [header, "CONTACTS", *self._menu_lines(CONTACTS)]
        if self.state.page == "settings":
            settings = ("Volume", "Channel", "Signal", "Back")
            return [header, "SETTINGS", *self._menu_lines(settings)]
        return [header, self.state.page.upper(), "Back"]

    def dispatch(self, event: Mapping[str, Any]) -> dict[str, Any]:
        """Apply one bounded command and return the resulting snapshot.

        Commands are validated before mutation.  A failed command leaves the
        previous state intact and is reported as a structured error to callers.
        """

        if not isinstance(event, Mapping):
            raise ValueError("event must be a JSON object")
        event_type = str(event.get("event", event.get("type", ""))).strip().lower()
        if not event_type:
            raise ValueError("event requires an 'event' field")
        before = self.snapshot()
        try:
            if event_type in {"press", "button"}:
                self._press(str(event.get("control", event.get("action", ""))))
            elif event_type in {"click", "hit_test"}:
                self._click(event)
            elif event_type in {"screen_click", "lcd_click"}:
                self._screen_click(event)
            elif event_type in {"set", "set_state"}:
                self._set_state(event)
            elif event_type == "tick":
                self._tick(event)
            elif event_type == "reset":
                self.reset(device_id=event.get("device_id"), variant=event.get("variant"))
            else:
                raise ValueError(f"unknown event type: {event_type}")
            self._validate_state()
        except Exception:
            self.state = self._state_from_snapshot(before)
            raise

        self.state.last_event = event_type
        self.state.event_log.append({"event": dict(event), "state": self._compact_state()})
        if len(self.state.event_log) > MAX_EVENT_LOG:
            del self.state.event_log[:-MAX_EVENT_LOG]
        return self.snapshot()

    def _press(self, control_or_action: str) -> None:
        value = control_or_action.strip()
        if not value:
            raise ValueError("press requires a control or action")
        control = next((item for item in self.geometry.controls if item.id == value), None)
        action = control.action if control else value
        if control is None and action not in {item.action for item in self.geometry.controls} and action not in {
            "back",
            "signal_cycle",
            "transmit_toggle",
        }:
            raise ValueError(f"unknown control or action: {value}")
        self._apply_action(action)

    def _click(self, event: Mapping[str, Any]) -> None:
        try:
            x = float(event["x"])
            y = float(event["y"])
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError("click requires numeric x and y in source-crop coordinates") from error
        for control in self.geometry.controls:
            left, top, width, height = control.rect
            if left <= x <= left + width and top <= y <= top + height:
                self._apply_action(control.action)
                return
        raise ValueError(f"no control at source coordinate ({x:g}, {y:g})")

    def _screen_click(self, event: Mapping[str, Any]) -> None:
        try:
            x = float(event["x"])
            y = float(event["y"])
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError("screen_click requires numeric x and y in source-crop coordinates") from error
        left, top, width, height = self.geometry.lcd_rect
        if not left <= x <= left + width or not top <= y <= top + height:
            raise ValueError(f"screen coordinate is outside the LCD ({x:g}, {y:g})")
        relative = (y - top) / max(1, height)
        if relative < 0.38:
            self._apply_action("previous")
        elif relative > 0.76:
            self._apply_action("next")
        else:
            self._apply_action("select")

    def _set_state(self, event: Mapping[str, Any]) -> None:
        field_name = str(event.get("field", "")).strip()
        if field_name == "variant":
            self.state.variant = normalize_variant(str(event.get("value", "")))
            return
        if field_name in {"powered", "transmitting"}:
            value = event.get("value")
            if not isinstance(value, bool):
                raise ValueError(f"{field_name} requires a boolean value")
            setattr(self.state, field_name, value)
            if field_name == "powered" and not value:
                self.state.transmitting = False
            return
        if field_name in {"volume", "channel", "battery"}:
            try:
                value = int(event.get("value"))
            except (TypeError, ValueError) as error:
                raise ValueError(f"{field_name} requires an integer value") from error
            limits = {"volume": (0, 10), "channel": (1, 99), "battery": (0, 100)}
            minimum, maximum = limits[field_name]
            if not minimum <= value <= maximum:
                raise ValueError(f"{field_name} must be between {minimum} and {maximum}")
            setattr(self.state, field_name, value)
            return
        if field_name == "signal":
            value = str(event.get("value", "")).strip().lower()
            if value not in {"none", "search", "found"}:
                raise ValueError("signal must be none, search, or found")
            self.state.signal = value
            return
        if field_name == "page":
            value = str(event.get("value", "")).strip().lower()
            if value not in {"home", "contacts", "settings"}:
                raise ValueError("page must be home, contacts, or settings")
            self.state.page = value
            self.state.menu_index = 0
            return
        raise ValueError(f"unknown state field: {field_name}")

    def _tick(self, event: Mapping[str, Any]) -> None:
        try:
            milliseconds = int(event.get("ms", event.get("milliseconds", 0)))
        except (TypeError, ValueError) as error:
            raise ValueError("tick requires an integer ms value") from error
        if milliseconds < 0 or milliseconds > 60_000:
            raise ValueError("tick ms must be between 0 and 60000")
        self.state.clock_ms += milliseconds
        if self.state.powered and self.state.signal == "search" and milliseconds >= 200:
            self.state.signal = "found"

    def _apply_action(self, action: str) -> None:
        if action == "power_toggle":
            self.state.powered = not self.state.powered
            if not self.state.powered:
                self.state.transmitting = False
            return
        if not self.state.powered:
            return
        if action == "volume_up":
            self.state.volume = min(10, self.state.volume + 1)
            return
        if action == "volume_down":
            self.state.volume = max(0, self.state.volume - 1)
            return
        if action == "channel_up":
            self.state.channel = 1 if self.state.channel >= 99 else self.state.channel + 1
            return
        if action == "channel_down":
            self.state.channel = 99 if self.state.channel <= 1 else self.state.channel - 1
            return
        if action == "signal_cycle":
            sequence = ("none", "search", "found")
            self.state.signal = sequence[(sequence.index(self.state.signal) + 1) % len(sequence)]
            return
        if action == "transmit_toggle":
            self.state.transmitting = not self.state.transmitting if self.state.powered else False
            return
        if action == "menu":
            self.state.page = "home"
            self.state.menu_index = 0
            return
        if action == "back":
            self.state.page = "home"
            self.state.menu_index = 0
            return
        if action in {"previous", "next"}:
            items = self._current_items()
            delta = -1 if action == "previous" else 1
            self.state.menu_index = (self.state.menu_index + delta) % max(1, len(items))
            return
        if action == "select":
            self._select_current()
            return
        raise ValueError(f"unsupported radio action: {action}")

    def _current_items(self) -> tuple[str, ...]:
        if self.state.page == "home":
            return HOME_ITEMS
        if self.state.page == "contacts":
            return CONTACTS
        if self.state.page == "settings":
            return ("Volume", "Channel", "Signal", "Back")
        return ("Back",)

    def _select_current(self) -> None:
        items = self._current_items()
        selected = items[self.state.menu_index % len(items)]
        if self.state.page == "home":
            self.state.page = "contacts" if selected == "Contacts" else "settings"
            self.state.menu_index = 0
            return
        if self.state.page == "settings":
            if selected == "Volume":
                self.state.volume = 0 if self.state.volume else 5
            elif selected == "Channel":
                self.state.channel = 1 if self.state.channel >= 99 else self.state.channel + 1
            elif selected == "Signal":
                self._apply_action("signal_cycle")
            else:
                self.state.page = "home"
                self.state.menu_index = 0

    def _menu_lines(self, items: tuple[str, ...]) -> list[str]:
        return [f"> {item}" if index == self.state.menu_index else f"  {item}" for index, item in enumerate(items)]

    def _compact_state(self) -> dict[str, Any]:
        return {
            "powered": self.state.powered,
            "volume": self.state.volume,
            "channel": self.state.channel,
            "signal": self.state.signal,
            "page": self.state.page,
            "menu_index": self.state.menu_index,
            "transmitting": self.state.transmitting,
        }

    def _validate_state(self) -> None:
        if self.state.variant not in {"clean", "worn"}:
            raise ValueError("invalid simulator variant")
        if not 0 <= self.state.volume <= 10:
            raise ValueError("volume is outside simulator bounds")
        if not 1 <= self.state.channel <= 99:
            raise ValueError("channel is outside simulator bounds")
        if not 0 <= self.state.battery <= 100:
            raise ValueError("battery is outside simulator bounds")
        if self.state.page not in {"home", "contacts", "settings"}:
            raise ValueError("invalid simulator page")

    @staticmethod
    def _state_from_snapshot(snapshot: Mapping[str, Any]) -> RadioState:
        value = snapshot["state"]
        return RadioState(
            device_id=value["device_id"],
            variant=value["variant"],
            powered=value["powered"],
            volume=value["volume"],
            channel=value["channel"],
            signal=value["signal"],
            page=value["page"],
            menu_index=value["menu_index"],
            battery=value["battery"],
            transmitting=value["transmitting"],
            clock_ms=value["clock_ms"],
            last_event=value["last_event"],
            event_log=list(value.get("event_log", [])),
        )
