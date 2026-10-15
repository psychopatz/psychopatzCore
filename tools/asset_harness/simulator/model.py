"""Deterministic radio state and command reducer."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Mapping

from ..core.modular import render_modular
from ..core.project import load_project, project_workspace
from .catalog import ControlSpec, DeviceGeometry, DeviceSpec, get_device, normalize_variant, with_semantic_controls


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
    page_stack: list[str] = field(default_factory=lambda: ["home"])
    menu_index: int = 0
    battery: int = 82
    transmitting: bool = False
    ptt_held: bool = False
    pressed_controls: list[str] = field(default_factory=list)
    knobs: dict[str, int] = field(default_factory=lambda: {"volume": 5, "channel": 1})
    leds: dict[str, str] = field(default_factory=lambda: {"pwr": "off", "rx": "off", "tx": "off"})
    closed: bool = False
    clock_ms: int = 0
    last_event: str = "reset"
    event_log: list[dict[str, Any]] = field(default_factory=list)


class RadioSimulator:
    """Owns all mutable simulator state and exposes command/query methods."""

    def __init__(self, device_id: str = "walkie_1", *, variant: str = "clean", project_path: Path | None = None) -> None:
        self.project_path = Path(project_path).expanduser().resolve() if project_path is not None else None
        self.project = load_project(self.project_path) if self.project_path is not None else None
        if self.project is not None:
            device_id = str(self.project.get("project_id") or device_id)
        self.state = RadioState(device_id=device_id, variant=normalize_variant(variant))
        self._validate_state()

    @property
    def device(self) -> DeviceSpec:
        if self.project is not None:
            device = self.project.get("device") or {}
            canvas = self.project.get("canvas") or {}
            chassis = (self.project.get("modular") or {}).get("chassis") or {}
            source = chassis.get("pristine") or {}
            image_value = source.get("image") if isinstance(source, Mapping) else None
            asset_path = Path(image_value) if image_value else None
            if asset_path is not None and not asset_path.is_absolute() and self.project_path is not None:
                asset_path = project_workspace(self.project_path, self.project) / asset_path
            if asset_path is None:
                asset_path = project_workspace(self.project_path, self.project) / "__missing_modular_chassis__.png"
            return DeviceSpec(
                id=str(self.project.get("project_id") or self.state.device_id),
                label=str(self.project.get("project_id") or self.state.device_id),
                family=str(device.get("family") or "walkie"),
                full_type=str(device.get("fullType") or ""),
                asset_path=asset_path or Path("."),
                lcd_rect=tuple((self.project.get("lcd") or {}).get("aperture") or (0, 0, int(canvas.get("width", 1)), int(canvas.get("height", 1)))),
                screen_content_rect=tuple((self.project.get("lcd") or {}).get("content") or (0, 0, int(canvas.get("width", 1)), int(canvas.get("height", 1)))),
                screen_sprite="screen_panel_green_compact",
                controls=self.geometry.controls if hasattr(self, "state") else (),
                source_width=int(canvas.get("width", 1)),
                source_height=int(canvas.get("height", 1)),
                source_layout="single_canvas",
            )
        return get_device(self.state.device_id)

    @property
    def geometry(self) -> DeviceGeometry:
        """Return hitboxes and screen bounds for the active artwork half."""

        if self.project is not None:
            lcd = self.project.get("lcd") or {}
            canvas = self.project.get("canvas") or {}
            aperture = tuple(lcd.get("aperture") or (0, 0, int(canvas.get("width", 1)), int(canvas.get("height", 1))))
            content = tuple(lcd.get("content") or aperture)
            controls: list[ControlSpec] = []
            for component_id, component in sorted(((self.project.get("modular") or {}).get("components") or {}).items()):
                if not isinstance(component, Mapping):
                    continue
                rect = component.get("hitbox") or component.get("rect")
                if rect is None:
                    continue
                controls.append(ControlSpec(
                    id=str(component_id),
                    label=str(component.get("label") or component_id),
                    action=self._semantic_action(component.get("action") or component_id),
                    rect=tuple(int(value) for value in rect),
                    kind=str(component.get("kind") or "momentary"),
                    detents=int(component.get("detents") or 0),
                ))
            return with_semantic_controls(DeviceGeometry(
                tuple(int(value) for value in aperture),
                tuple(int(value) for value in content),
                "screen_panel_green_compact",
                tuple(controls),
            ))
        return self.device.geometry_for(self.state.variant)

    @staticmethod
    def _semantic_action(value: Any) -> str:
        normalized = str(value).strip()
        aliases = {
            "BACK": "back", "HOME": "home", "MENU": "menu", "UP": "previous",
            "DOWN": "next", "LEFT": "previous", "RIGHT": "next", "SELECT": "select",
            "OK": "select", "POWER": "power_toggle", "PTT": "transmit_toggle",
            "TUNE": "channel_up", "VOLUME": "volume_up", "SCAN": "signal_cycle",
        }
        return aliases.get(normalized.upper(), normalized.lower())

    def modular_state_selection(self) -> dict[str, str]:
        if self.project is None:
            return {}
        selected: dict[str, str] = {}
        for component_id, component in sorted(((self.project.get("modular") or {}).get("components") or {}).items()):
            if not isinstance(component, Mapping):
                continue
            states = component.get("states") or {}
            kind = str(component.get("kind") or "")
            if kind in {"power", "switch"}:
                candidate = "on" if self.state.powered else "off"
            elif kind in {"hold", "ptt"}:
                candidate = "held" if self.state.ptt_held else "idle"
            elif component_id in self.state.pressed_controls:
                candidate = "pressed" if "pressed" in states else "idle"
            elif kind in {"led"}:
                led_id = str(component_id).strip().lower()
                led_alias = {
                    "pwr": "pwr",
                    "power": "pwr",
                    "pwr_led": "pwr",
                    "rx": "rx",
                    "rx_led": "rx",
                    "tx": "tx",
                    "tx_led": "tx",
                }.get(led_id, led_id)
                candidate = self.state.leds.get(led_alias, "off")
            else:
                candidate = "idle"
            if candidate not in states:
                candidate = next(iter(states), candidate)
            selected[str(component_id)] = candidate
        return selected

    def reset(self, *, device_id: str | None = None, variant: str | None = None) -> dict[str, Any]:
        next_device = device_id or self.state.device_id
        next_variant = normalize_variant(variant or self.state.variant)
        if self.project is None:
            get_device(next_device)
        elif device_id and device_id != self.state.device_id:
            raise ValueError("a project-backed simulator cannot switch device IDs")
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
            {
                "id": control.id,
                "label": control.label,
                "action": control.action,
                "kind": control.kind,
                "detents": control.detents or None,
                "pressed": control.id in self.state.pressed_controls,
            }
            for control in self.geometry.controls
        ]
        state["hardware"] = {
            "pressed_controls": list(self.state.pressed_controls),
            "ptt_held": self.state.ptt_held,
            "knobs": dict(self.state.knobs),
            "leds": dict(self.state.leds),
            "closed": self.state.closed,
        }
        state["screen"] = self.screen_lines()
        return {"schema_version": SCHEMA_VERSION, "state": state}

    def screen_lines(self) -> list[str]:
        if self.state.closed:
            return ["CLOSED", "", "Press Power to reopen"]
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
        if self.state.page == "contact_detail":
            contact = CONTACTS[self.state.menu_index % len(CONTACTS)]
            return [header, "CONTACT", contact, "Back"]
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
            elif event_type in {"pointer_down", "down"}:
                self._pointer_down(event)
            elif event_type in {"pointer_up", "up"}:
                self._pointer_up(event)
            elif event_type in {"pointer_move", "move"}:
                self._pointer_move(event)
            elif event_type in {"pointer_cancel", "cancel"}:
                self._pointer_cancel(event)
            elif event_type == "wheel":
                self._wheel(event)
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
        control = self._control(value)
        action = control.action if control else {
            "power": "power_toggle",
            "ok": "select",
            "ptt": "transmit_toggle",
        }.get(value, value)
        if control is None and action not in {item.action for item in self.geometry.controls} and action not in {
            "back", "home", "menu", "select", "previous", "next", "power_toggle",
            "signal_cycle", "transmit_toggle", "volume_up", "volume_down", "channel_up", "channel_down",
        }:
            raise ValueError(f"unknown control or action: {value}")
        # ``press`` is the legacy discrete convenience.  It still traverses
        # the same down/up visual lifecycle for a hold control, but ends in a
        # released state before the command returns.
        if control is not None and self._is_hold_control(control):
            self._pointer_down({"control": control.id})
            self._pointer_up({"control": control.id})
        else:
            self._apply_action(action)

    def _control(self, value: str):
        return next((item for item in self.geometry.controls if item.id == value), None)

    @staticmethod
    def _is_hold_control(control: Any) -> bool:
        return control.kind in {"hold", "ptt"} or control.action in {"transmit_toggle", "ptt"}

    @staticmethod
    def _is_rotary_control(control: Any) -> bool:
        return control.kind in {"rotary", "knob"} or int(getattr(control, "detents", 0) or 0) > 0

    def _pointer_down(self, event: Mapping[str, Any]) -> None:
        control_id = str(event.get("control", "")).strip()
        control = self._control(control_id)
        if control is None:
            raise ValueError(f"unknown control: {control_id}")
        if control_id not in self.state.pressed_controls:
            self.state.pressed_controls.append(control_id)
        if self._is_hold_control(control):
            if not self.state.powered:
                return
            self.state.ptt_held = True
            self.state.transmitting = True
            self.state.leds["tx"] = "on"

    def _pointer_up(self, event: Mapping[str, Any]) -> None:
        control_id = str(event.get("control", "")).strip()
        control = self._control(control_id)
        if control is None:
            raise ValueError(f"unknown control: {control_id}")
        was_pressed = control_id in self.state.pressed_controls
        self.state.pressed_controls = [item for item in self.state.pressed_controls if item != control_id]
        if self._is_hold_control(control):
            self.state.ptt_held = False
            self.state.transmitting = False
            self.state.leds["tx"] = "off"
        elif was_pressed and not self._is_rotary_control(control):
            self._apply_action(control.action)

    def _pointer_move(self, event: Mapping[str, Any]) -> None:
        control_id = str(event.get("control", "")).strip()
        control = self._control(control_id)
        if control is None:
            raise ValueError(f"unknown control: {control_id}")
        if control_id not in self.state.pressed_controls:
            raise ValueError(f"pointer move requires captured control: {control_id}")
        if not self._is_rotary_control(control):
            return
        delta_value = event.get("delta", event.get("steps", event.get("dx", event.get("dy", 0))))
        self._wheel({"control": control_id, "delta": delta_value})

    def _pointer_cancel(self, event: Mapping[str, Any]) -> None:
        self.state.pressed_controls = []
        self.state.ptt_held = False
        self.state.transmitting = False
        self.state.leds["tx"] = "off"

    def _wheel(self, event: Mapping[str, Any]) -> None:
        control_id = str(event.get("control", "")).strip()
        control = self._control(control_id)
        if control is None:
            raise ValueError(f"unknown rotary control: {control_id}")
        try:
            delta = int(event.get("delta", event.get("steps", 0)))
        except (TypeError, ValueError) as error:
            raise ValueError("wheel delta must be an integer") from error
        if delta < -16 or delta > 16:
            raise ValueError("wheel delta must be between -16 and 16")
        if not self.state.powered or delta == 0:
            return
        action = control.action
        if action in {"volume_up", "volume_down"}:
            direction = 1 if delta > 0 else -1
            for _ in range(abs(delta)):
                self._apply_action("volume_up" if direction > 0 else "volume_down")
            self.state.knobs["volume"] = self.state.volume
            return
        if action in {"channel_up", "channel_down"}:
            direction = 1 if delta > 0 else -1
            for _ in range(abs(delta)):
                self._apply_action("channel_up" if direction > 0 else "channel_down")
            self.state.knobs["channel"] = self.state.channel
            return
        raise ValueError(f"control is not rotary: {control_id}")

    def _click(self, event: Mapping[str, Any]) -> None:
        try:
            x = float(event["x"])
            y = float(event["y"])
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError("click requires numeric x and y in source-crop coordinates") from error
        for control in self.geometry.controls:
            left, top, width, height = control.rect
            if left <= x <= left + width and top <= y <= top + height:
                if self._is_hold_control(control):
                    self._pointer_down({"control": control.id})
                    self._pointer_up({"control": control.id})
                else:
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
                self.state.ptt_held = False
                self.state.leds["pwr"] = "off"
                self.state.leds["tx"] = "off"
            elif field_name == "powered":
                self.state.leds["pwr"] = "on"
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
            if field_name in {"volume", "channel"}:
                self.state.knobs[field_name] = value
            return
        if field_name == "signal":
            value = str(event.get("value", "")).strip().lower()
            if value not in {"none", "search", "found"}:
                raise ValueError("signal must be none, search, or found")
            self.state.signal = value
            return
        if field_name == "page":
            value = str(event.get("value", "")).strip().lower()
            if value not in {"home", "contacts", "contact_detail", "settings"}:
                raise ValueError("page must be home, contacts, or settings")
            self.state.page = value
            self.state.page_stack = ["home"] if value == "home" else ["home", value]
            self.state.menu_index = 0
            return
        if field_name == "leds":
            value = event.get("value")
            if not isinstance(value, Mapping):
                raise ValueError("leds requires an object of indicator states")
            allowed = {"off", "on", "blink", "pulse"}
            for key, indicator in value.items():
                indicator_value = str(indicator).lower()
                if indicator_value not in allowed:
                    raise ValueError(f"invalid LED state: {indicator_value}")
                self.state.leds[str(key)] = indicator_value
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
            if self.state.closed:
                self.state.closed = False
                self.state.powered = True
                self.state.leds["pwr"] = "on"
                return
            self.state.powered = not self.state.powered
            self.state.leds["pwr"] = "on" if self.state.powered else "off"
            if not self.state.powered:
                self.state.transmitting = False
                self.state.ptt_held = False
                self.state.leds["tx"] = "off"
            return
        if not self.state.powered:
            return
        if action == "volume_up":
            self.state.volume = min(10, self.state.volume + 1)
            self.state.knobs["volume"] = self.state.volume
            return
        if action == "volume_down":
            self.state.volume = max(0, self.state.volume - 1)
            self.state.knobs["volume"] = self.state.volume
            return
        if action == "channel_up":
            self.state.channel = 1 if self.state.channel >= 99 else self.state.channel + 1
            self.state.knobs["channel"] = self.state.channel
            return
        if action == "channel_down":
            self.state.channel = 99 if self.state.channel <= 1 else self.state.channel - 1
            self.state.knobs["channel"] = self.state.channel
            return
        if action == "signal_cycle":
            sequence = ("none", "search", "found")
            self.state.signal = sequence[(sequence.index(self.state.signal) + 1) % len(sequence)]
            return
        if action == "transmit_toggle":
            self.state.transmitting = not self.state.transmitting if self.state.powered else False
            self.state.ptt_held = self.state.transmitting
            self.state.leds["tx"] = "on" if self.state.transmitting else "off"
            return
        if action == "menu":
            self.state.page = "home"
            self.state.page_stack = ["home"]
            self.state.menu_index = 0
            return
        if action == "back":
            if len(self.state.page_stack) > 1:
                self.state.page_stack.pop()
                self.state.page = self.state.page_stack[-1]
            else:
                self.state.closed = True
            self.state.menu_index = 0
            return
        if action == "home":
            self.state.page = "home"
            self.state.page_stack = ["home"]
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
        if self.state.page == "contact_detail":
            return ("Back",)
        if self.state.page == "settings":
            return ("Volume", "Channel", "Signal", "Back")
        return ("Back",)

    def _select_current(self) -> None:
        items = self._current_items()
        selected = items[self.state.menu_index % len(items)]
        if self.state.page == "home":
            self.state.page = "contacts" if selected == "Contacts" else "settings"
            self.state.page_stack = ["home", self.state.page]
            self.state.menu_index = 0
            return
        if self.state.page == "contacts":
            self.state.page = "contact_detail"
            self.state.page_stack.append("contact_detail")
            self.state.menu_index = 0
            return
        if self.state.page == "contact_detail":
            self._apply_action("back")
            return
        if self.state.page == "settings":
            if selected == "Volume":
                self.state.volume = 0 if self.state.volume else 5
                self.state.knobs["volume"] = self.state.volume
            elif selected == "Channel":
                self.state.channel = 1 if self.state.channel >= 99 else self.state.channel + 1
                self.state.knobs["channel"] = self.state.channel
            elif selected == "Signal":
                self._apply_action("signal_cycle")
            else:
                self._apply_action("back")

    def _menu_lines(self, items: tuple[str, ...]) -> list[str]:
        return [f"> {item}" if index == self.state.menu_index else f"  {item}" for index, item in enumerate(items)]

    def _compact_state(self) -> dict[str, Any]:
        return {
            "powered": self.state.powered,
            "volume": self.state.volume,
            "channel": self.state.channel,
            "signal": self.state.signal,
            "page": self.state.page,
            "page_stack": list(self.state.page_stack),
            "menu_index": self.state.menu_index,
            "transmitting": self.state.transmitting,
            "ptt_held": self.state.ptt_held,
            "pressed_controls": list(self.state.pressed_controls),
            "knobs": dict(self.state.knobs),
            "leds": dict(self.state.leds),
            "closed": self.state.closed,
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
        if self.state.page not in {"home", "contacts", "contact_detail", "settings"}:
            raise ValueError("invalid simulator page")
        if not self.state.page_stack or self.state.page_stack[-1] != self.state.page:
            raise ValueError("page stack does not end at the current page")
        if self.state.ptt_held and not self.state.transmitting:
            raise ValueError("PTT hold requires transmitting state")

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
            page_stack=list(value.get("page_stack") or [value["page"]]),
            menu_index=value["menu_index"],
            battery=value["battery"],
            transmitting=value["transmitting"],
            ptt_held=bool(value.get("ptt_held", False)),
            pressed_controls=list(value.get("pressed_controls") or []),
            knobs=dict(value.get("knobs") or {"volume": value["volume"], "channel": value["channel"]}),
            leds=dict(value.get("leds") or {"pwr": "on" if value["powered"] else "off", "rx": "off", "tx": "off"}),
            closed=bool(value.get("closed", False)),
            clock_ms=value["clock_ms"],
            last_event=value["last_event"],
            event_log=list(value.get("event_log", [])),
        )
