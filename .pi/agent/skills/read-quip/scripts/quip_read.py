#!/usr/bin/env python3
"""Fetch and extract text from a Quip document using the Quip API."""

from __future__ import annotations

import argparse
import html as html_lib
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from typing import Any

API_BASE = "https://platform.quip.com/1"
TOKEN_ENV_NAMES = ("QUIP_API_TOKEN", "QUIP_TOKEN", "QUIP_ACCESS_TOKEN")


class QuipTextExtractor(HTMLParser):
    BLOCK_TAGS = {
        "address",
        "blockquote",
        "div",
        "dl",
        "dt",
        "dd",
        "fieldset",
        "figcaption",
        "figure",
        "footer",
        "form",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "header",
        "hr",
        "li",
        "main",
        "ol",
        "p",
        "pre",
        "section",
        "table",
        "tbody",
        "td",
        "tfoot",
        "th",
        "thead",
        "tr",
        "ul",
    }

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._href_stack: list[str | None] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        attrs_dict = dict(attrs)
        if tag in self.BLOCK_TAGS or tag == "br":
            self.parts.append("\n")
        if tag == "li":
            self.parts.append("- ")
        if tag == "a":
            self._href_stack.append(attrs_dict.get("href"))

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag == "a" and self._href_stack:
            href = self._href_stack.pop()
            if href:
                self.parts.append(f" ({href})")
        if tag in self.BLOCK_TAGS:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        self.parts.append(data)

    def text(self) -> str:
        text = html_lib.unescape("".join(self.parts))
        # Normalize horizontal whitespace without destroying intentional line breaks.
        text = re.sub(r"[\t\r\f\v ]+", " ", text)
        text = re.sub(r" *\n *", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip()


def token_from_env() -> str:
    for name in TOKEN_ENV_NAMES:
        value = os.environ.get(name)
        if value:
            return value
    raise SystemExit(
        "No Quip token found. Export one of: " + ", ".join(TOKEN_ENV_NAMES)
    )


def quip_id(value: str) -> str:
    value = value.strip()
    parsed = urllib.parse.urlparse(value)
    if parsed.scheme and parsed.netloc:
        parts = [p for p in parsed.path.split("/") if p]
        if not parts:
            raise SystemExit(f"Could not find a Quip id in URL: {value}")
        return parts[-1]
    return value


def fetch_thread(doc: str, token: str) -> dict[str, Any]:
    thread_id = urllib.parse.quote(quip_id(doc), safe="")
    url = f"{API_BASE}/threads/{thread_id}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:1000]
        raise SystemExit(f"Quip API request failed: HTTP {e.code} {e.reason}\n{body}") from e
    except urllib.error.URLError as e:
        raise SystemExit(f"Quip API request failed: {e.reason}") from e


def extract_text(data: dict[str, Any]) -> str:
    title = data.get("thread", {}).get("title")
    html = data.get("html") or data.get("thread", {}).get("html") or ""
    parser = QuipTextExtractor()
    parser.feed(html)
    body = parser.text()
    if title and not body.startswith(str(title)):
        return f"{title}\n\n{body}".strip()
    return body


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("document", help="Quip URL, thread id, or document id")
    parser.add_argument("--output", "-o", help="Write output to this file")
    parser.add_argument("--html", action="store_true", help="Print raw document HTML")
    parser.add_argument("--json", action="store_true", help="Print raw Quip API JSON")
    args = parser.parse_args()

    data = fetch_thread(args.document, token_from_env())

    if args.json:
        output = json.dumps(data, indent=2, sort_keys=True)
    elif args.html:
        output = data.get("html") or data.get("thread", {}).get("html") or ""
    else:
        output = extract_text(data)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
            if not output.endswith("\n"):
                f.write("\n")
        print(f"Wrote {args.output}", file=sys.stderr)
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
