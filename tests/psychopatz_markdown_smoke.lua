local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

PsychopatzCore = {}
local Markdown = require "PsychopatzCore/Text/PsychopatzMarkdown"

local document = Markdown.Parse(
    "# Hello **world**\nI *really* mean it. * chuckles*\n- [safe](https://example.invalid)"
)
assert(document.version == Markdown.VERSION, "Markdown version missing")
assert(document.lines[1].kind == "heading", "heading was not classified")
assert(Markdown.LineText(document.lines[1]) == "Hello world", "bold markers remained")
assert(Markdown.LineText(document.lines[2]) == "I really mean it. chuckles",
    "inline emphasis changed the message")
assert(document.lines[3].kind == "list", "list was not classified")
assert(Markdown.LineText(document.lines[3]) == "• safe", "link was not reduced to its label")
assert(Markdown.ToText(document):find("Hello world", 1, true) ~= nil,
    "flattened Markdown text was not available")
assert(Markdown.ToSingleLine("**hello**\n- world") == "hello • world",
    "single-line Markdown projection was not available")

local wrapped = Markdown.Wrap(document, 80, function(value)
    return #value * 8
end)
assert(#wrapped >= 3, "Markdown wrapping lost explicit lines")

print("PsychopatzCore Markdown smoke passed")
