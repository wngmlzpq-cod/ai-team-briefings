from __future__ import annotations

import json
import os
from datetime import date, datetime
from pathlib import Path
from typing import Annotated, Any
from uuid import uuid4

from fastapi import FastAPI, Form, HTTPException, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware


WEB_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = Path(__file__).resolve().parents[3]
TRANSACTIONS_FILE = PROJECT_ROOT / "data" / "finance" / "transactions.json"

TEAM_DEFINITIONS = [
    {
        "slug": "recruitment",
        "name": "채용분석팀",
        "purpose": "채용공고 수집·직무 적합도·지원 우선순위 분석",
    },
    {
        "slug": "youth-support",
        "name": "청년지원팀",
        "purpose": "청년정책·지원금·주거·교육 혜택 조사",
    },
    {
        "slug": "economy",
        "name": "경제연구팀",
        "purpose": "시장·산업·경제 흐름과 개인 재무 영향 분석",
    },
    {
        "slug": "learning",
        "name": "학습팀",
        "purpose": "영어·전기·자격증 학습자료와 커리큘럼 관리",
    },
    {
        "slug": "qa",
        "name": "검증팀",
        "purpose": "출처·날짜·수치·중복·오류 검증",
    },
]

app = FastAPI(title="J-OS", version="2.0.0")
@app.middleware("http")
async def login_guard(request: Request, call_next):
    public_paths = {"/login", "/health", "/favicon.ico"}

    if request.url.path.startswith("/static/") or request.url.path in public_paths:
        return await call_next(request)

    if not request.session.get("authenticated", False):
        return RedirectResponse("/login", status_code=303)

    return await call_next(request)


app.add_middleware(
    SessionMiddleware,
    secret_key=os.getenv(
        "JOS_SESSION_SECRET",
        "change-this-before-public-deployment",
    ),
    https_only=os.getenv("JOS_HTTPS_ONLY", "false").lower() == "true",
    same_site="lax",
)
app.mount("/static", StaticFiles(directory=WEB_DIR / "static"), name="static")
templates = Jinja2Templates(directory=WEB_DIR / "templates")


@app.middleware("http")
async def login_guard(request: Request, call_next):
    public_paths = {
        "/login",
        "/health",
        "/favicon.ico",
    }

    if (
        request.url.path.startswith("/static/")
        or request.url.path in public_paths
    ):
        return await call_next(request)

    # SessionMiddleware가 아직 적용되지 않은 경우 예외 방지
    session = request.scope.get("session")

    if session is None:
        return await call_next(request)

    if not session.get("authenticated", False):
        return RedirectResponse("/login", status_code=303)

    return await call_next(request)


def load_transactions() -> list[dict[str, Any]]:
    TRANSACTIONS_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not TRANSACTIONS_FILE.exists():
        save_transactions([])
        return []

    try:
        with TRANSACTIONS_FILE.open("r", encoding="utf-8") as file:
            data = json.load(file)
    except json.JSONDecodeError as error:
        raise HTTPException(
            status_code=500,
            detail=f"거래 데이터 JSON 오류: {error.lineno}줄 {error.colno}칸",
        ) from error

    transactions = data.get("transactions", [])
    return transactions if isinstance(transactions, list) else []


def save_transactions(transactions: list[dict[str, Any]]) -> None:
    TRANSACTIONS_FILE.parent.mkdir(parents=True, exist_ok=True)
    temporary = TRANSACTIONS_FILE.with_suffix(".json.tmp")
    with temporary.open("w", encoding="utf-8") as file:
        json.dump(
            {"transactions": transactions},
            file,
            ensure_ascii=False,
            indent=2,
        )
    os.replace(temporary, TRANSACTIONS_FILE)


def amount(value: Any) -> int:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return int(value)
    try:
        return int(str(value).replace(",", "").replace("원", "").strip())
    except (TypeError, ValueError):
        return 0


def won(value: Any) -> str:
    return f"{amount(value):,}원"


def type_name(value: Any) -> str:
    return {"income": "수입", "expense": "지출"}.get(str(value), "미분류")


def find_index(transactions: list[dict[str, Any]], transaction_id: str) -> int:
    for index, transaction in enumerate(transactions):
        if transaction.get("id") == transaction_id:
            return index
    raise HTTPException(status_code=404, detail="거래를 찾을 수 없습니다.")


def totals(items: list[dict[str, Any]]) -> dict[str, int]:
    income = sum(
        amount(item.get("amount"))
        for item in items
        if item.get("type") == "income"
    )
    expense = sum(
        amount(item.get("amount"))
        for item in items
        if item.get("type") == "expense"
    )
    return {"income": income, "expense": expense, "balance": income - expense}


def report_files(team_slug: str) -> list[dict[str, Any]]:
    team_dir = PROJECT_ROOT / team_slug
    if not team_dir.exists():
        return []

    allowed = {".md", ".txt", ".json", ".csv"}
    files: list[dict[str, Any]] = []

    for path in team_dir.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in allowed:
            continue

        stat = path.stat()
        files.append(
            {
                "name": path.name,
                "relative_path": str(path.relative_to(PROJECT_ROOT)).replace("\\", "/"),
                "modified_at": datetime.fromtimestamp(stat.st_mtime),
                "size": stat.st_size,
            }
        )

    return sorted(files, key=lambda item: item["modified_at"], reverse=True)


def safe_report_path(relative_path: str) -> Path:
    candidate = (PROJECT_ROOT / relative_path).resolve()
    root = PROJECT_ROOT.resolve()

    if root not in candidate.parents or not candidate.is_file():
        raise HTTPException(status_code=404, detail="보고서를 찾을 수 없습니다.")

    allowed_roots = {(PROJECT_ROOT / team["slug"]).resolve() for team in TEAM_DEFINITIONS}
    if not any(allowed_root == candidate.parent or allowed_root in candidate.parents for allowed_root in allowed_roots):
        raise HTTPException(status_code=403, detail="허용되지 않은 경로입니다.")

    return candidate


@app.get("/health")
def health():
    return {"status": "ok", "service": "J-OS", "version": "2.0.0"}


@app.get("/login", response_class=HTMLResponse)
def login_form(request: Request):
    if request.session.get("authenticated"):
        return RedirectResponse("/", status_code=303)
    return templates.TemplateResponse(
        request=request,
        name="login.html",
        context={"error": ""},
    )


@app.post("/login")
def login(
    request: Request,
    username: Annotated[str, Form()],
    password: Annotated[str, Form()],
):
    expected_username = os.getenv("JOS_USERNAME", "admin")
    expected_password = os.getenv("JOS_PASSWORD", "change-me-now")

    if username != expected_username or password != expected_password:
        return templates.TemplateResponse(
            request=request,
            name="login.html",
            context={"error": "아이디 또는 비밀번호가 맞지 않습니다."},
            status_code=401,
        )

    request.session["authenticated"] = True
    request.session["username"] = username
    return RedirectResponse("/", status_code=303)


@app.post("/logout")
def logout(request: Request):
    request.session.clear()
    return RedirectResponse("/login", status_code=303)


@app.get("/", response_class=HTMLResponse)
def dashboard(request: Request):
    today = date.today()
    transactions = load_transactions()
    today_items = [item for item in transactions if item.get("date") == today.isoformat()]
    month_items = [
        item for item in transactions
        if str(item.get("date", "")).startswith(today.strftime("%Y-%m"))
    ]

    teams = []
    total_reports = 0
    for definition in TEAM_DEFINITIONS:
        reports = report_files(definition["slug"])
        total_reports += len(reports)
        teams.append({**definition, "report_count": len(reports), "latest": reports[0] if reports else None})

    return templates.TemplateResponse(
        request=request,
        name="dashboard.html",
        context={
            "today": today,
            "day": totals(today_items),
            "month": totals(month_items),
            "today_items": sorted(
                today_items,
                key=lambda item: str(item.get("created_at", "")),
                reverse=True,
            )[:5],
            "teams": teams,
            "total_reports": total_reports,
            "won": won,
            "type_name": type_name,
        },
    )


@app.get("/finance", response_class=HTMLResponse)
def finance_dashboard(request: Request):
    today = date.today()
    transactions = load_transactions()
    today_items = [item for item in transactions if item.get("date") == today.isoformat()]
    month_items = [
        item for item in transactions
        if str(item.get("date", "")).startswith(today.strftime("%Y-%m"))
    ]
    return templates.TemplateResponse(
        request=request,
        name="finance.html",
        context={
            "today": today,
            "today_items": sorted(
                today_items,
                key=lambda item: str(item.get("created_at", "")),
                reverse=True,
            ),
            "day": totals(today_items),
            "month": totals(month_items),
            "won": won,
            "type_name": type_name,
        },
    )


@app.get("/transactions", response_class=HTMLResponse)
def transaction_list(
    request: Request,
    month: str = "",
    transaction_type: str = "",
    keyword: str = "",
):
    items = []
    for item in load_transactions():
        if month and not str(item.get("date", "")).startswith(month):
            continue
        if transaction_type and item.get("type") != transaction_type:
            continue
        if keyword:
            text = " ".join(
                str(item.get(key, ""))
                for key in ("date", "category", "description", "payment_method")
            ).lower()
            if keyword.lower() not in text:
                continue
        items.append(item)

    items.sort(
        key=lambda item: (str(item.get("date", "")), str(item.get("created_at", ""))),
        reverse=True,
    )

    return templates.TemplateResponse(
        request=request,
        name="transactions.html",
        context={
            "items": items,
            "month_filter": month,
            "type_filter": transaction_type,
            "keyword_filter": keyword,
            "won": won,
            "type_name": type_name,
        },
    )


@app.get("/transactions/new", response_class=HTMLResponse)
def new_transaction(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="transaction_form.html",
        context={
            "title": "거래 등록",
            "action": "/transactions",
            "item": {
                "date": date.today().isoformat(),
                "type": "expense",
                "budget_group": "",
                "category": "",
                "description": "",
                "amount": "",
                "payment_method": "",
            },
        },
    )


@app.post("/transactions")
def create_transaction(
    transaction_date: Annotated[str, Form(alias="date")],
    transaction_type: Annotated[str, Form(alias="type")],
    category: Annotated[str, Form()],
    description: Annotated[str, Form()],
    amount_text: Annotated[str, Form(alias="amount")],
    payment_method: Annotated[str, Form()],
    budget_group: Annotated[str, Form()] = "",
):
    date.fromisoformat(transaction_date)
    value = amount(amount_text)
    if value < 0:
        raise HTTPException(status_code=400, detail="금액은 0원 이상이어야 합니다.")

    transactions = load_transactions()
    transactions.append(
        {
            "id": uuid4().hex,
            "date": transaction_date,
            "type": transaction_type,
            "budget_group": budget_group.strip() or None,
            "category": category.strip(),
            "description": description.strip(),
            "amount": value,
            "payment_method": payment_method.strip(),
            "created_at": datetime.now().isoformat(timespec="seconds"),
        }
    )
    save_transactions(transactions)
    return RedirectResponse("/finance", status_code=303)


@app.get("/transactions/{transaction_id}/edit", response_class=HTMLResponse)
def edit_transaction(request: Request, transaction_id: str):
    transactions = load_transactions()
    item = transactions[find_index(transactions, transaction_id)]
    return templates.TemplateResponse(
        request=request,
        name="transaction_form.html",
        context={
            "title": "거래 수정",
            "action": f"/transactions/{transaction_id}/edit",
            "item": item,
        },
    )


@app.post("/transactions/{transaction_id}/edit")
def update_transaction(
    transaction_id: str,
    transaction_date: Annotated[str, Form(alias="date")],
    transaction_type: Annotated[str, Form(alias="type")],
    category: Annotated[str, Form()],
    description: Annotated[str, Form()],
    amount_text: Annotated[str, Form(alias="amount")],
    payment_method: Annotated[str, Form()],
    budget_group: Annotated[str, Form()] = "",
):
    transactions = load_transactions()
    index = find_index(transactions, transaction_id)
    old = transactions[index]

    transactions[index] = {
        "id": transaction_id,
        "date": transaction_date,
        "type": transaction_type,
        "budget_group": budget_group.strip() or None,
        "category": category.strip(),
        "description": description.strip(),
        "amount": amount(amount_text),
        "payment_method": payment_method.strip(),
        "created_at": old.get("created_at"),
        "updated_at": datetime.now().isoformat(timespec="seconds"),
    }
    save_transactions(transactions)
    return RedirectResponse("/transactions", status_code=303)


@app.post("/transactions/{transaction_id}/delete")
def delete_transaction(transaction_id: str):
    transactions = load_transactions()
    del transactions[find_index(transactions, transaction_id)]
    save_transactions(transactions)
    return RedirectResponse("/transactions", status_code=303)


@app.get("/ai-team", response_class=HTMLResponse)
def ai_team_dashboard(request: Request):
    teams = []
    for definition in TEAM_DEFINITIONS:
        reports = report_files(definition["slug"])
        teams.append({**definition, "reports": reports[:5], "report_count": len(reports)})

    return templates.TemplateResponse(
        request=request,
        name="ai_team.html",
        context={"teams": teams},
    )


@app.get("/ai-team/{team_slug}", response_class=HTMLResponse)
def ai_team_detail(request: Request, team_slug: str):
    definition = next((team for team in TEAM_DEFINITIONS if team["slug"] == team_slug), None)
    if not definition:
        raise HTTPException(status_code=404, detail="AI 팀을 찾을 수 없습니다.")

    return templates.TemplateResponse(
        request=request,
        name="ai_team_detail.html",
        context={
            "team": definition,
            "reports": report_files(team_slug),
        },
    )


@app.get("/reports/view", response_class=HTMLResponse)
def report_view(request: Request, path: str):
    report_path = safe_report_path(path)
    suffix = report_path.suffix.lower()

    if suffix == ".json":
        try:
            content = json.dumps(
                json.loads(report_path.read_text(encoding="utf-8")),
                ensure_ascii=False,
                indent=2,
            )
        except json.JSONDecodeError:
            content = report_path.read_text(encoding="utf-8", errors="replace")
    else:
        content = report_path.read_text(encoding="utf-8", errors="replace")

    return templates.TemplateResponse(
        request=request,
        name="report_view.html",
        context={
            "report_name": report_path.name,
            "report_path": str(report_path.relative_to(PROJECT_ROOT)).replace("\\", "/"),
            "content": content,
        },
    )
