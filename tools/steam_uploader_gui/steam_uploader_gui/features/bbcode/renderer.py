from __future__ import annotations

import io
import re
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from collections.abc import Iterable
from pathlib import Path

from PIL import Image

try:
    from PIL import ImageTk
except ImportError:  # Pillow may be installed without its optional Tk bridge.
    ImageTk = None  # type: ignore[assignment]

from .parser import Node, parse
from ...ui.theme import palette


_IMAGE_BYTES_CACHE: dict[str, bytes] = {}
_MAX_CACHED_IMAGES = 32
_IMAGE_SUFFIXES = {".avif", ".bmp", ".gif", ".jpeg", ".jpg", ".png", ".webp"}
_INLINE_URL_RE = re.compile(r"(?:https?://|file://)[^\s<>\[\]]+", re.IGNORECASE)
_STEAM_IMAGE_HOSTS = {
    "images.steamusercontent.com",
    "steamuserimages-a.akamaihd.net",
}


def _looks_like_image_source(value: str) -> bool:
    """Recognize image URLs without probing every ordinary hyperlink."""

    value = value.strip().strip('"').rstrip(".,;!?")
    if not value:
        return False
    parsed = urllib.parse.urlparse(value)
    suffix = Path(parsed.path if parsed.scheme else value).suffix.lower()
    if suffix in _IMAGE_SUFFIXES:
        return True
    hostname = (parsed.hostname or "").lower()
    normalized_path = parsed.path.lower()
    return hostname in _STEAM_IMAGE_HOSTS or "/economy/image/" in normalized_path


def _trim_url_punctuation(value: str) -> tuple[str, str]:
    candidate = value
    while candidate and candidate[-1] in ".,;!?":
        candidate = candidate[:-1]
    return candidate, value[len(candidate):]


def _configure_tags(widget: object) -> None:
    colors = palette(bool(getattr(widget, "_steam_dark_mode", False)))
    widget.tag_configure("b", font=("TkDefaultFont", 10, "bold"))
    widget.tag_configure("i", font=("TkDefaultFont", 10, "italic"))
    widget.tag_configure("u", underline=True)
    widget.tag_configure("strike", overstrike=True)
    widget.tag_configure("heading", font=("TkDefaultFont", 12, "bold"), spacing1=8, spacing3=4)
    widget.tag_configure("quote", lmargin1=18, lmargin2=18, foreground=colors["quote"])
    widget.tag_configure("code", font="TkFixedFont", background=colors["code_bg"])
    widget.tag_configure("link", underline=True, foreground=colors["link"])
    widget.tag_configure("spoiler", background="#333333", foreground="#333333")
    widget.tag_configure("center", justify="center")


def _with_tag(tags: tuple[str, ...], tag: str) -> tuple[str, ...]:
    return tags if tag in tags else tags + (tag,)


def _read_image_source(value: str) -> bytes | None:
    value = value.strip().strip('"')
    if not value:
        return None
    if value in _IMAGE_BYTES_CACHE:
        return _IMAGE_BYTES_CACHE[value]
    parsed = urllib.parse.urlparse(value)
    try:
        if parsed.scheme in {"http", "https"}:
            request = urllib.request.Request(value, headers={"User-Agent": "SteamUploaderGUI/0.1"})
            with urllib.request.urlopen(request, timeout=4) as response:
                raw = response.read(4 * 1024 * 1024 + 1)[: 4 * 1024 * 1024]
        else:
            if parsed.scheme == "file":
                path = Path(urllib.parse.unquote(parsed.path))
            else:
                path = Path(value).expanduser()
            if not path.is_file():
                return None
            raw = path.read_bytes()[: 4 * 1024 * 1024]
    except (OSError, ValueError, urllib.error.URLError):
        return None

    if len(_IMAGE_BYTES_CACHE) >= _MAX_CACHED_IMAGES:
        _IMAGE_BYTES_CACHE.pop(next(iter(_IMAGE_BYTES_CACHE)))
    _IMAGE_BYTES_CACHE[value] = raw
    return raw


def _image_for_widget(widget: object, value: str) -> ImageTk.PhotoImage | None:
    if ImageTk is None:
        return None
    try:
        raw = _read_image_source(value)
        if not raw:
            return None
        with Image.open(io.BytesIO(raw)) as image:
            image.seek(0)
            rendered = image.convert("RGBA")
            scale = min(560 / rendered.width, 320 / rendered.height, 1.0)
            if scale < 1.0:
                rendered = rendered.resize(
                    (max(1, int(rendered.width * scale)), max(1, int(rendered.height * scale))),
                    Image.Resampling.LANCZOS,
                )
            return ImageTk.PhotoImage(rendered)
    except Exception:
        return None


def _plain_text(nodes: Iterable[Node]) -> str:
    """Return the textual part of a URL node without exposing BBCode syntax."""

    parts: list[str] = []
    for node in nodes:
        if node.text is not None:
            parts.append(node.text)
        elif node.tag == "img":
            parts.append(node.argument or _plain_text(node.children))
        else:
            parts.append(_plain_text(node.children))
    return "".join(parts).strip()


def _bind_link(widget: object, url: str) -> str:
    url = url.strip().strip('"')
    if not url:
        return "link"
    tag_name = f"steam-link-{abs(hash(url))}"
    colors = palette(bool(getattr(widget, "_steam_dark_mode", False)))
    widget.tag_configure(tag_name, foreground=colors["link"], underline=True)

    def open_link(_event: object = None) -> str:
        try:
            webbrowser.open(url)
        except OSError:
            pass
        return "break"

    widget.tag_bind(tag_name, "<Button-1>", open_link)
    widget.tag_bind(tag_name, "<Enter>", lambda _event: widget.configure(cursor="hand2"))
    widget.tag_bind(tag_name, "<Leave>", lambda _event: widget.configure(cursor="arrow"))
    return tag_name


def _render_image(
    widget: object,
    value: str,
    tags: tuple[str, ...],
    link_url: str | None = None,
    link_tag: str | None = None,
) -> bool:
    image = _image_for_widget(widget, value)
    if image is None:
        return False
    image_start = widget.index("end-1c")
    widget.image_create("end", image=image, align="baseline")
    image_end = widget.index("end-1c")
    if link_url:
        widget.tag_add(link_tag or "link", image_start, image_end)
    # Steam keeps adjacent [img] tags inline. Any newline in the original
    # BBCode is emitted by its surrounding text node, so do not invent one
    # here or image strips (buttons, badges, and donation links) break apart.
    widget._steam_preview_images.append(image)
    return True


def _render_text(widget: object, value: str, tags: tuple[str, ...]) -> None:
    """Render image-looking URL snippets inline, preserving failed URLs as text."""

    if "code" in tags or not value:
        widget.insert("end", value, tags)
        return
    cursor = 0
    for match in _INLINE_URL_RE.finditer(value):
        raw_url = match.group(0)
        image_url, punctuation = _trim_url_punctuation(raw_url)
        if not _looks_like_image_source(image_url):
            continue
        if match.start() > cursor:
            widget.insert("end", value[cursor:match.start()], tags)
        link_tag = _bind_link(widget, image_url)
        if not _render_image(widget, image_url, tags, image_url, link_tag):
            widget.insert("end", image_url, _with_tag(tags, link_tag))
        if punctuation:
            widget.insert("end", punctuation, tags)
        cursor = match.end()
    if cursor:
        if cursor < len(value):
            widget.insert("end", value[cursor:], tags)
    else:
        widget.insert("end", value, tags)


def _render_nodes(
    widget: object,
    nodes: Iterable[Node],
    tags: tuple[str, ...] = (),
    link_url: str | None = None,
    link_tag: str | None = None,
) -> None:
    for node in nodes:
        if node.text is not None:
            _render_text(widget, node.text, tags)
            continue
        if node.tag == "li":
            widget.insert("end", "• ", tags)
            continue
        if node.tag == "br":
            widget.insert("end", "\n", tags)
            continue
        if node.tag == "hr":
            widget.insert("end", "\n────────────────────────\n", tags)
            continue
        if node.tag == "img":
            value = node.argument or "".join(child.text or "" for child in node.children)
            if not _render_image(widget, value, tags, link_url, link_tag):
                image_tags = _with_tag(tags, link_tag or "link")
                widget.insert("end", f"[image unavailable: {value}]", image_tags)
            continue
        if node.tag == "url":
            target = node.argument or _plain_text(node.children)
            current_link_tag = _bind_link(widget, target) if target else (link_tag or "link")
            link_tags = _with_tag(tags, current_link_tag)
            has_explicit_image = any(child.tag == "img" for child in node.children)
            if target and not has_explicit_image and _looks_like_image_source(target):
                if _render_image(widget, target, tags, target, current_link_tag):
                    label = _plain_text(node.children)
                    if label and label != target:
                        widget.insert("end", label, link_tags)
                    continue
            _render_nodes(widget, node.children, link_tags, target, current_link_tag)
            if node.argument and not node.children:
                widget.insert("end", node.argument, link_tags)
            continue
        if node.tag in {"h1", "h2", "h3"}:
            _render_nodes(widget, node.children, _with_tag(tags, "heading"), link_url, link_tag)
            widget.insert("end", "\n", tags)
            continue
        if node.tag == "quote":
            _render_nodes(widget, node.children, _with_tag(tags, "quote"), link_url, link_tag)
            continue
        if node.tag == "code":
            _render_nodes(widget, node.children, _with_tag(tags, "code"), link_url, link_tag)
            continue
        if node.tag == "spoiler":
            _render_nodes(widget, node.children, _with_tag(tags, "spoiler"), link_url, link_tag)
            continue
        if node.tag == "center":
            _render_nodes(widget, node.children, _with_tag(tags, "center"), link_url, link_tag)
            continue
        tag_map = {"b": "b", "i": "i", "u": "u", "s": "strike", "strike": "strike"}
        _render_nodes(
            widget,
            node.children,
            _with_tag(tags, tag_map.get(node.tag or "", node.tag or "")),
            link_url,
            link_tag,
        )


def render(widget: object, source: str) -> None:
    """Render a safe visual approximation of Steam BBCode into a Tk Text widget."""

    widget.configure(state="normal")
    widget.delete("1.0", "end")
    widget._steam_preview_images = []
    _configure_tags(widget)
    _render_nodes(widget, parse(source).children)
    widget.configure(state="disabled")
