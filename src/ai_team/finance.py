from __future__ import annotations

import calendar
import json
import math
from datetime import date
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]

BUDGET_FILE = PROJECT_ROOT / "data" / "budget" / "monthly.json"
TRANSACTIONS_FILE = PROJECT_ROOT / "data" / "finance" / "transactions.json"
SETTINGS_FILE = PROJECT_ROOT / "data" / "settings" / "finance.json"


def load_json(file_path: Path) -> dict[str, Any]:
    """JSON 파일을 읽어서 딕셔너리로 반환한다."""
    if not file_path.exists():
        raise FileNotFoundError(f"파일을 찾을 수 없습니다: {file_path}")

    try:
        with file_path.open("r", encoding="utf-8") as file:
            return json.load(file)

    except json.JSONDecodeError as error:
        raise ValueError(
            f"JSON 형식이 올바르지 않습니다.\n"
            f"파일: {file_path}\n"
            f"위치: {error.lineno}번째 줄, {error.colno}번째 칸"
        ) from error


def get_days_in_month(target_date: date) -> int:
    """해당 월의 전체 날짜 수를 반환한다."""
    return calendar.monthrange(target_date.year, target_date.month)[1]


def get_remaining_days(target_date: date) -> int:
    """오늘을 포함하여 이번 달에 남은 날짜 수를 반환한다."""
    days_in_month = get_days_in_month(target_date)
    return days_in_month - target_date.day + 1


def calculate_applicable_budget(
    monthly_amount: int,
    target_date: date,
    budget_start_date: date,
    prorate_first_month: bool,
) -> int:
    """
    해당 월에 실제로 사용할 수 있는 예산을 계산한다.

    재무 관리 시작 월이면 남은 날짜만큼 일할 계산하고,
    이후 월부터는 월 전체 예산을 적용한다.
    """
    is_start_month = (
        target_date.year == budget_start_date.year
        and target_date.month == budget_start_date.month
    )

    if not prorate_first_month or not is_start_month:
        return monthly_amount

    days_in_month = get_days_in_month(target_date)
    remaining_days = get_remaining_days(budget_start_date)

    prorated_amount = monthly_amount * remaining_days / days_in_month

    return math.floor(prorated_amount)


def calculate_used_amount(
    transactions: list[dict[str, Any]],
    budget_group: str,
    target_date: date,
) -> int:
    """해당 월과 예산 그룹의 지출 합계를 계산한다."""
    total = 0

    for transaction in transactions:
        if transaction.get("type") != "expense":
            continue

        if transaction.get("budget_group") != budget_group:
            continue

        transaction_date_text = transaction.get("date")

        if not transaction_date_text:
            continue

        try:
            transaction_date = date.fromisoformat(transaction_date_text)
        except ValueError:
            continue

        is_same_month = (
            transaction_date.year == target_date.year
            and transaction_date.month == target_date.month
        )

        if not is_same_month:
            continue

        amount = transaction.get("amount", 0)

        if isinstance(amount, (int, float)):
            total += int(amount)

    return total


def calculate_status(
    used_amount: int,
    applicable_budget: int,
    warning_threshold_percent: int,
) -> str:
    """예산 사용 상태를 안정, 주의, 초과로 구분한다."""
    if applicable_budget <= 0:
        return "초과" if used_amount > 0 else "안정"

    usage_percent = used_amount / applicable_budget * 100

    if usage_percent > 100:
        return "초과"

    if usage_percent >= warning_threshold_percent:
        return "주의"

    return "안정"


def format_won(amount: int) -> str:
    """금액을 원화 표시 형식으로 변환한다."""
    return f"{amount:,}원"


def build_finance_summary(target_date: date) -> list[dict[str, Any]]:
    """현재 날짜를 기준으로 예산 요약을 생성한다."""
    budget_data = load_json(BUDGET_FILE)
    transactions_data = load_json(TRANSACTIONS_FILE)
    settings_data = load_json(SETTINGS_FILE)

    budget_start_date = date.fromisoformat(
        settings_data["budget_start_date"]
    )

    prorate_first_month = settings_data.get(
        "prorate_first_month",
        True,
    )

    warning_threshold_percent = settings_data.get(
        "warning_threshold_percent",
        80,
    )

    monthly_limits = budget_data.get("monthly_limits", {})
    transactions = transactions_data.get("transactions", [])

    remaining_days = get_remaining_days(target_date)
    summaries: list[dict[str, Any]] = []

    for budget_group, budget_info in monthly_limits.items():
        monthly_amount = int(budget_info["amount"])

        applicable_budget = calculate_applicable_budget(
            monthly_amount=monthly_amount,
            target_date=target_date,
            budget_start_date=budget_start_date,
            prorate_first_month=prorate_first_month,
        )

        used_amount = calculate_used_amount(
            transactions=transactions,
            budget_group=budget_group,
            target_date=target_date,
        )

        remaining_amount = applicable_budget - used_amount

        recommended_daily_amount = (
            math.floor(max(remaining_amount, 0) / remaining_days)
            if remaining_days > 0
            else 0
        )

        status = calculate_status(
            used_amount=used_amount,
            applicable_budget=applicable_budget,
            warning_threshold_percent=warning_threshold_percent,
        )

        summaries.append(
            {
                "budget_group": budget_group,
                "name": budget_info["name"],
                "monthly_budget": monthly_amount,
                "applicable_budget": applicable_budget,
                "used_amount": used_amount,
                "remaining_amount": remaining_amount,
                "recommended_daily_amount": recommended_daily_amount,
                "status": status,
            }
        )

    return summaries


def main() -> None:
    today = date.today()
    summaries = build_finance_summary(today)

    print("=" * 45)
    print(f"J-OS 재무 현황 · {today.isoformat()}")
    print("=" * 45)

    for summary in summaries:
        print(f"\n[{summary['name']}]")
        print(
            f"월 기준 예산        : "
            f"{format_won(summary['monthly_budget'])}"
        )
        print(
            f"이번 달 적용 예산   : "
            f"{format_won(summary['applicable_budget'])}"
        )
        print(
            f"현재 사용 금액      : "
            f"{format_won(summary['used_amount'])}"
        )
        print(
            f"남은 금액           : "
            f"{format_won(summary['remaining_amount'])}"
        )
        print(
            f"오늘 권장 사용 금액 : "
            f"{format_won(summary['recommended_daily_amount'])}"
        )
        print(f"상태                : {summary['status']}")

    print("\n" + "=" * 45)


if __name__ == "__main__":
    main()