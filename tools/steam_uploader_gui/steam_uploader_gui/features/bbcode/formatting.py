from __future__ import annotations

import unicodedata


def normalize_line_endings(value: str) -> str:
    """Use the single newline form Tk and Steam previews render consistently."""

    return value.replace("\r\n", "\n").replace("\r", "\n")


def unicode_prefix(value: str, limit: int) -> str:
    """Keep a length-limited Unicode value from ending in a broken sequence.

    Python strings already preserve Unicode scalar values. This extra step avoids
    cutting directly after a combining mark, emoji variation selector, skin-tone
    modifier, zero-width joiner, or the first half of a regional-indicator flag.
    """

    if limit < 0:
        return ""
    if len(value) <= limit:
        return value

    result = value[:limit]
    while result:
        codepoint = ord(result[-1])
        is_combining = (
            unicodedata.combining(result[-1]) != 0
            or codepoint in {0xFE0E, 0xFE0F}
            or 0x1F3FB <= codepoint <= 0x1F3FF
        )
        is_joiner = codepoint == 0x200D
        if is_combining or is_joiner:
            result = result[:-1]
            continue
        break

    regional_count = 0
    for character in reversed(result):
        if 0x1F1E6 <= ord(character) <= 0x1F1FF:
            regional_count += 1
        else:
            break
    if regional_count % 2:
        result = result[:-1]
    return result


def wrap_selection(widget: object, opening: str, closing: str | None = None) -> None:
    """Wrap the current selection, or insert an editable empty BBCode span."""

    closing = closing if closing is not None else opening.replace("[", "[/", 1)
    try:
        start = widget.index("sel.first")
        end = widget.index("sel.last")
        selected = widget.get(start, end)
        widget.delete(start, end)
        widget.insert(start, opening + selected + closing)
        widget.tag_add("sel", start, f"{start}+{len(opening + selected + closing)}c")
    except Exception:
        position = widget.index("insert")
        widget.insert(position, opening + closing)
        widget.mark_set("insert", f"{position}+{len(opening)}c")
    widget.focus_set()
