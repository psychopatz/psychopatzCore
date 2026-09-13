from __future__ import annotations

import re
from dataclasses import dataclass, field


@dataclass
class Node:
    tag: str | None = None
    argument: str | None = None
    text: str | None = None
    children: list["Node"] = field(default_factory=list)


_TOKEN = re.compile(r"\[(?P<closing>/)?(?P<tag>[a-zA-Z][\w-]*|\*)(?:=(?P<argument>[^\]]+))?\]")
_KNOWN_TAGS = {
    "b", "i", "u", "s", "strike", "url", "img", "quote", "code", "spoiler",
    "h1", "h2", "h3", "list", "hr", "br", "center", "*",
}
_SELF_CLOSING = {"hr", "br", "*"}


def parse(source: str) -> Node:
    """Parse the common Steam BBCode subset without evaluating any markup."""

    # Workshop text files and Steam responses commonly use CRLF. Tk renders a
    # bare carriage return as a visible control glyph, so normalize before the
    # parser ever creates text nodes.
    source = source.replace("\r\n", "\n").replace("\r", "\n")
    root = Node()
    stack = [root]
    cursor = 0
    for match in _TOKEN.finditer(source):
        if match.start() > cursor:
            stack[-1].children.append(Node(text=source[cursor:match.start()]))
        raw = match.group(0)
        tag = match.group("tag").lower()
        closing = bool(match.group("closing"))
        if tag not in _KNOWN_TAGS:
            stack[-1].children.append(Node(text=raw))
        elif closing and tag in _SELF_CLOSING:
            # Steam accepts both [hr] and [hr][/hr] (and similarly for [br]).
            # The closing half is a no-op rather than visible source text.
            pass
        elif closing:
            if len(stack) > 1 and stack[-1].tag == tag:
                stack.pop()
            else:
                stack[-1].children.append(Node(text=raw))
        elif tag in _SELF_CLOSING:
            stack[-1].children.append(Node(tag="li" if tag == "*" else tag, argument=match.group("argument")))
        else:
            node = Node(tag=tag, argument=match.group("argument"))
            stack[-1].children.append(node)
            stack.append(node)
        cursor = match.end()
    if cursor < len(source):
        stack[-1].children.append(Node(text=source[cursor:]))
    return root
