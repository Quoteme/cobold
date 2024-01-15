#!/usr/bin/env python3
"""gendocs : docs-src/index.html x source tree -> _site/index.html.

Substitutes <!--SOURCE:path--> markers in the template with the literal,
HTML-escaped contents of `path`, so the documentation can never drift
from the code it quotes - there is nothing to keep in sync by hand.
"""
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "docs-src" / "index.html"
OUT_DIR = ROOT / "_site"

LANG_BY_SUFFIX = {
    ".cob": "cobol", ".cpy": "cobol", ".c": "c",
    ".nix": "nix", ".sh": "bash", ".dat": "plaintext",
}


def embed_source(path_str: str) -> str:
    path = ROOT / path_str
    lang = LANG_BY_SUFFIX.get(path.suffix, "plaintext")
    text = path.read_text()
    escaped = html.escape(text)
    return f'<pre><code class="language-{lang}">{escaped}</code></pre>'


def main() -> int:
    template = TEMPLATE.read_text()
    out = re.sub(
        r"<!--SOURCE:(.+?)-->",
        lambda m: embed_source(m.group(1)),
        template,
    )
    OUT_DIR.mkdir(exist_ok=True)
    dest = OUT_DIR / "index.html"
    dest.write_text(out)
    print(f"wrote {dest} ({len(out)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
