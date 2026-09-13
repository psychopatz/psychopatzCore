from __future__ import annotations

import unittest

from steam_uploader_gui.features.bbcode.formatting import unicode_prefix
from steam_uploader_gui.features.bbcode.parser import parse
from steam_uploader_gui.features.bbcode.renderer import _looks_like_image_source


class BBCodeParserTests(unittest.TestCase):
    def test_common_nested_tags_are_structured(self) -> None:
        root = parse("[b]Title[/b]\n[quote][i]Body[/i][/quote]")
        self.assertEqual(root.children[0].tag, "b")
        self.assertEqual(root.children[0].children[0].text, "Title")
        quote = root.children[2]
        self.assertEqual(quote.tag, "quote")
        self.assertEqual(quote.children[0].tag, "i")

    def test_unknown_markup_is_preserved_as_text(self) -> None:
        root = parse("[future]keep this[/future]")
        self.assertEqual("".join(node.text or "" for node in root.children), "[future]keep this[/future]")

    def test_linked_images_are_preserved_as_nested_nodes(self) -> None:
        root = parse("[url=https://example.com][img]https://example.com/image.png[/img][/url]")
        link = root.children[0]
        self.assertEqual(link.tag, "url")
        self.assertEqual(link.argument, "https://example.com")
        self.assertEqual(link.children[0].tag, "img")
        self.assertEqual(link.children[0].children[0].text, "https://example.com/image.png")

    def test_unicode_prefix_does_not_split_emoji_sequences(self) -> None:
        self.assertEqual(unicode_prefix("👩‍💻abc", 2), "👩")
        self.assertEqual(unicode_prefix("👍🏽abc", 1), "👍")
        self.assertEqual(unicode_prefix("🇵🇭abc", 1), "")

    def test_crlf_and_explicit_hr_closers_are_not_rendered_as_text(self) -> None:
        root = parse("before\r\n[hr][/hr]\r\nafter")
        self.assertEqual([node.tag for node in root.children if node.tag], ["hr"])
        self.assertEqual(root.children[0].text, "before\n")
        self.assertEqual(root.children[-1].text, "\nafter")

    def test_image_url_detection_handles_steam_cdn_urls_without_extensions(self) -> None:
        self.assertTrue(_looks_like_image_source("https://example.com/banner.png?size=large"))
        self.assertTrue(
            _looks_like_image_source(
                "https://steamuserimages-a.akamaihd.net/ugc/123456789/987654321/"
            )
        )
        self.assertFalse(_looks_like_image_source("https://example.com/workshop/item/123"))


if __name__ == "__main__":
    unittest.main()
