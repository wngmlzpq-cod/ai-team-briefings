from __future__ import annotations

import json
import shutil
from dataclasses import asdict
from pathlib import Path
from typing import Any

from jinja2 import Environment, FileSystemLoader, select_autoescape

from .config import CATEGORIES, docs_dir, project_root, templates_dir
from .markdown_renderer import extract_title, is_report_file, render_markdown


class SiteGenerator:
    def __init__(self) -> None:
        self.root = project_root()
        self.docs = docs_dir()
        self.templates = templates_dir()
        self.env = Environment(
            loader=FileSystemLoader(self.templates),
            autoescape=select_autoescape(["html", "xml"]),
            trim_blocks=True,
            lstrip_blocks=True,
        )

    def build(self) -> int:
        self.docs.mkdir(parents=True, exist_ok=True)

        all_categories: list[dict[str, Any]] = []
        total_reports = 0

        for category in CATEGORIES:
            built = self._build_category(category)
            all_categories.append(built)
            total_reports += len(built["reports"])

        self._build_home(all_categories)
        self._write_search_index(all_categories)

        return total_reports

    def _build_category(self, category) -> dict[str, Any]:
        source = self.root / category.source_dir
        destination = self.docs / category.output_dir
        destination.mkdir(parents=True, exist_ok=True)

        report_paths = []
        if source.exists():
            report_paths = sorted(
                (path for path in source.glob("*.md") if is_report_file(path)),
                key=lambda p: p.stem,
                reverse=True,
            )

        reports: list[dict[str, str]] = []

        article_template = self.env.get_template("article.html")

        for md_path in report_paths:
            markdown_text = md_path.read_text(encoding="utf-8-sig")
            title = extract_title(markdown_text, md_path.stem)
            html_body = render_markdown(markdown_text)
            output_name = f"{md_path.stem}.html"

            article_html = article_template.render(
                site_title="AI Team Portal",
                category=category,
                title=title,
                report_date=md_path.stem,
                content=html_body,
            )

            (destination / output_name).write_text(
                article_html,
                encoding="utf-8",
            )

            reports.append(
                {
                    "title": title,
                    "date": md_path.stem,
                    "filename": output_name,
                    "url": f"{category.output_dir}/{output_name}",
                    "category": category.name,
                }
            )

            print(f"Generated: docs/{category.output_dir}/{output_name}")

        category_template = self.env.get_template("category.html")
        category_html = category_template.render(
            site_title="AI Team Portal",
            category=category,
            reports=reports,
        )

        (destination / "index.html").write_text(
            category_html,
            encoding="utf-8",
        )
        print(f"Generated: docs/{category.output_dir}/index.html")

        return {
            "name": category.name,
            "output_dir": category.output_dir,
            "description": category.description,
            "icon": category.icon,
            "reports": reports,
            "latest": reports[0] if reports else None,
        }

    def _build_home(self, categories: list[dict[str, Any]]) -> None:
        home_template = self.env.get_template("home.html")
        home_html = home_template.render(
            site_title="AI Team Portal",
            categories=categories,
        )
        (self.docs / "index.html").write_text(home_html, encoding="utf-8")
        print("Generated: docs/index.html")

    def _write_search_index(self, categories: list[dict[str, Any]]) -> None:
        search_items = [
            report
            for category in categories
            for report in category["reports"]
        ]
        (self.docs / "search-index.json").write_text(
            json.dumps(search_items, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        print("Generated: docs/search-index.json")
