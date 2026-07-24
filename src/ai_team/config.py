from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Category:
    name: str
    source_dir: str
    output_dir: str
    description: str
    icon: str


CATEGORIES = (
    Category(
        name="Learning",
        source_dir="learning",
        output_dir="learning",
        description="학습 브리핑",
        icon="📚",
    ),
    Category(
        name="Economy",
        source_dir="economy",
        output_dir="economy",
        description="경제 브리핑",
        icon="📈",
    ),
    Category(
        name="Recruitment",
        source_dir="recruitment",
        output_dir="recruitment",
        description="채용 분석",
        icon="💼",
    ),
    Category(
        name="Youth",
        source_dir="youth-support",
        output_dir="youth",
        description="청년지원 정보",
        icon="🏠",
    ),
    Category(
        name="QA",
        source_dir="qa",
        output_dir="qa",
        description="검증 리포트",
        icon="🛠️",
    ),
)


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def templates_dir() -> Path:
    return project_root() / "templates"


def docs_dir() -> Path:
    return project_root() / "docs"
