import re
from pathlib import Path

import markdown


DATE_FILE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def is_report_file(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() == ".md" and bool(
        DATE_FILE_PATTERN.fullmatch(path.stem)
    )


def extract_title(markdown_text: str, fallback: str) -> str:
    for line in markdown_text.splitlines():
        stripped = line.strip()
        if stripped.startswith("# "):
            return stripped[2:].strip() or fallback
    return fallback


def render_markdown(markdown_text: str) -> str:
    return markdown.markdown(
        markdown_text,
        extensions=[
            "extra",
            "sane_lists",
            "tables",
            "fenced_code",
        ],
        output_format="html5",
    )
