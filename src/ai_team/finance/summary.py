from __future__ import annotations

import calendar
import json
import math
from collections import defaultdict
from datetime import date
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[3]

BUDGET_FILE = PROJECT_ROOT / "data" / "budget" / "monthly.json"
TRANSACTIONS_FILE = PROJECT_ROOT / "data" / "finance" / "transactions.json"
SETTINGS_FILE = PROJECT_ROOT / "data" / "settings" / "finance.json"


def load_json(
    file_path: Path,
    default_data: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """JSON 파일을 읽어 딕셔너리로 반환합니다."""

    if not file_path.exists():
        if default_data is not None:
            return default_data

        raise FileNotFoundError(
            f"파일을 찾을 수 없습니다: {file_path}"
        )

    try:
        with file_path.open(
            "r",
            encoding="utf-8",
        ) as file:
            data = json.load(file)

    except json.JSONDecodeError as error:
        raise ValueError(
            "JSON 형식이 올바르지 않습니다.\n"
            f"파일: {file_path}\n"
            f"위치: {error.lineno}번째 줄, "
            f"{error.colno}번째 칸"
        ) from error

    if not isinstance(data, dict):
        raise ValueError(
            f"JSON 최상위 데이터는 객체여야 합니다: {file_path}"
        )

    return data


def get_days_in_month(target_date: date) -> int:
    """대상 월의 전체 날짜 수를 반환합니다."""

    return calendar.monthrange(
        target_date.year,
        target_date.month,
    )[1]


def get_remaining_days(target_date: date) -> int:
    """대상 날짜를 포함한 해당 월의 남은 날짜 수를 반환합니다."""

    days_in_month = get_days_in_month(target_date)

    return days_in_month - target_date.day + 1


def parse_transaction_date(
    transaction: dict[str, Any],
) -> date | None:
    """거래 날짜를 date 객체로 변환합니다."""

    date_text = transaction.get("date")

    if not isinstance(date_text, str):
        return None

    try:
        return date.fromisoformat(date_text)

    except ValueError:
        return None


def is_same_month(
    first_date: date,
    second_date: date,
) -> bool:
    """두 날짜가 같은 연도와 월인지 확인합니다."""

    return (
        first_date.year == second_date.year
        and first_date.month == second_date.month
    )


def normalize_amount(value: Any) -> int:
    """거래 금액을 안전하게 정수로 변환합니다."""

    if isinstance(value, bool):
        return 0

    if isinstance(value, (int, float)):
        return int(value)

    if isinstance(value, str):
        cleaned_value = (
            value
            .replace(",", "")
            .replace("원", "")
            .strip()
        )

        if cleaned_value.isdigit():
            return int(cleaned_value)

    return 0


def calculate_applicable_budget(
    monthly_amount: int,
    target_date: date,
    budget_start_date: date,
    prorate_first_month: bool,
) -> int:
    """
    대상 월에 실제 적용할 기본예산을 계산합니다.

    예산 시작 월이고 첫 달 일할 계산을 사용하는 경우,
    시작일부터 월말까지의 날짜 비율만큼 계산합니다.
    """

    is_start_month = (
        target_date.year == budget_start_date.year
        and target_date.month == budget_start_date.month
    )

    if not prorate_first_month or not is_start_month:
        return monthly_amount

    days_in_month = get_days_in_month(target_date)
    remaining_days = get_remaining_days(budget_start_date)

    prorated_amount = (
        monthly_amount
        * remaining_days
        / days_in_month
    )

    return math.floor(prorated_amount)


def get_monthly_transactions(
    transactions: list[dict[str, Any]],
    target_date: date,
) -> list[dict[str, Any]]:
    """대상 월에 해당하는 거래만 반환합니다."""

    monthly_transactions: list[dict[str, Any]] = []

    for transaction in transactions:
        transaction_date = parse_transaction_date(transaction)

        if transaction_date is None:
            continue

        if not is_same_month(
            transaction_date,
            target_date,
        ):
            continue

        monthly_transactions.append(transaction)

    return monthly_transactions


def calculate_monthly_income(
    monthly_transactions: list[dict[str, Any]],
) -> int:
    """이번 달 전체 수입을 합산합니다."""

    return sum(
        normalize_amount(transaction.get("amount", 0))
        for transaction in monthly_transactions
        if transaction.get("type") == "income"
    )


def calculate_monthly_expense(
    monthly_transactions: list[dict[str, Any]],
) -> int:
    """이번 달 전체 지출을 합산합니다."""

    return sum(
        normalize_amount(transaction.get("amount", 0))
        for transaction in monthly_transactions
        if transaction.get("type") == "expense"
    )


def calculate_used_amount(
    monthly_transactions: list[dict[str, Any]],
    budget_group: str,
) -> int:
    """특정 예산 그룹의 이번 달 지출 합계를 계산합니다."""

    total = 0

    for transaction in monthly_transactions:
        if transaction.get("type") != "expense":
            continue

        if transaction.get("budget_group") != budget_group:
            continue

        total += normalize_amount(
            transaction.get("amount", 0)
        )

    return total


def calculate_status(
    used_amount: int,
    applicable_budget: int,
    warning_threshold_percent: int,
) -> str:
    """예산 사용 상태를 안정, 주의, 초과로 구분합니다."""

    if applicable_budget <= 0:
        return "초과" if used_amount > 0 else "안정"

    usage_percent = (
        used_amount
        / applicable_budget
        * 100
    )

    if usage_percent > 100:
        return "초과"

    if usage_percent >= warning_threshold_percent:
        return "주의"

    return "안정"


def calculate_usage_percent(
    used_amount: int,
    budget_amount: int,
) -> float:
    """예산 사용률을 계산합니다."""

    if budget_amount <= 0:
        return 0.0

    return used_amount / budget_amount * 100


def calculate_category_totals(
    monthly_transactions: list[dict[str, Any]],
    transaction_type: str,
) -> dict[str, int]:
    """수입 또는 지출을 카테고리별로 합산합니다."""

    totals: dict[str, int] = defaultdict(int)

    for transaction in monthly_transactions:
        if transaction.get("type") != transaction_type:
            continue

        category = transaction.get("category")

        if not isinstance(category, str) or not category.strip():
            category = "미분류"

        totals[category] += normalize_amount(
            transaction.get("amount", 0)
        )

    return dict(totals)


def format_won(amount: int) -> str:
    """금액을 원화 표시 형식으로 변환합니다."""

    return f"{amount:,}원"


def format_percent(value: float) -> str:
    """백분율을 소수점 첫째 자리까지 표시합니다."""

    return f"{value:.1f}%"


def build_finance_summary(
    target_date: date,
) -> dict[str, Any]:
    """대상 월의 재무 요약 전체를 생성합니다."""

    budget_data = load_json(
        BUDGET_FILE,
        default_data={"monthly_limits": {}},
    )

    transactions_data = load_json(
        TRANSACTIONS_FILE,
        default_data={"transactions": []},
    )

    settings_data = load_json(
        SETTINGS_FILE,
        default_data={},
    )

    budget_start_date_text = settings_data.get(
        "budget_start_date",
        target_date.replace(day=1).isoformat(),
    )

    try:
        budget_start_date = date.fromisoformat(
            budget_start_date_text
        )

    except (TypeError, ValueError):
        budget_start_date = target_date.replace(day=1)

    prorate_first_month = bool(
        settings_data.get(
            "prorate_first_month",
            True,
        )
    )

    warning_threshold_percent = int(
        settings_data.get(
            "warning_threshold_percent",
            80,
        )
    )

    monthly_limits = budget_data.get(
        "monthly_limits",
        {},
    )

    if not isinstance(monthly_limits, dict):
        monthly_limits = {}

    transactions = transactions_data.get(
        "transactions",
        [],
    )

    if not isinstance(transactions, list):
        transactions = []

    monthly_transactions = get_monthly_transactions(
        transactions=transactions,
        target_date=target_date,
    )

    monthly_income = calculate_monthly_income(
        monthly_transactions
    )

    monthly_expense = calculate_monthly_expense(
        monthly_transactions
    )

    remaining_days = get_remaining_days(target_date)

    budget_summaries: list[dict[str, Any]] = []

    base_monthly_budget_total = 0
    base_applicable_budget_total = 0
    grouped_expense_total = 0

    for budget_group, budget_info in monthly_limits.items():
        if not isinstance(budget_info, dict):
            continue

        monthly_amount = normalize_amount(
            budget_info.get("amount", 0)
        )

        applicable_budget = calculate_applicable_budget(
            monthly_amount=monthly_amount,
            target_date=target_date,
            budget_start_date=budget_start_date,
            prorate_first_month=prorate_first_month,
        )

        used_amount = calculate_used_amount(
            monthly_transactions=monthly_transactions,
            budget_group=budget_group,
        )

        remaining_amount = (
            applicable_budget
            - used_amount
        )

        usage_percent = calculate_usage_percent(
            used_amount=used_amount,
            budget_amount=applicable_budget,
        )

        recommended_daily_amount = (
            math.floor(
                max(remaining_amount, 0)
                / remaining_days
            )
            if remaining_days > 0
            else 0
        )

        status = calculate_status(
            used_amount=used_amount,
            applicable_budget=applicable_budget,
            warning_threshold_percent=warning_threshold_percent,
        )

        base_monthly_budget_total += monthly_amount
        base_applicable_budget_total += applicable_budget
        grouped_expense_total += used_amount

        budget_summaries.append(
            {
                "budget_group": budget_group,
                "name": budget_info.get(
                    "name",
                    budget_group,
                ),
                "monthly_budget": monthly_amount,
                "applicable_budget": applicable_budget,
                "used_amount": used_amount,
                "remaining_amount": remaining_amount,
                "usage_percent": usage_percent,
                "recommended_daily_amount": (
                    recommended_daily_amount
                ),
                "status": status,
            }
        )

    ungrouped_expense = max(
        monthly_expense - grouped_expense_total,
        0,
    )

    total_applicable_budget = (
        base_applicable_budget_total
        + monthly_income
    )

    total_remaining_budget = (
        total_applicable_budget
        - monthly_expense
    )

    total_usage_percent = calculate_usage_percent(
        used_amount=monthly_expense,
        budget_amount=total_applicable_budget,
    )

    net_cash_flow = (
        monthly_income
        - monthly_expense
    )

    expense_by_category = calculate_category_totals(
        monthly_transactions=monthly_transactions,
        transaction_type="expense",
    )

    income_by_category = calculate_category_totals(
        monthly_transactions=monthly_transactions,
        transaction_type="income",
    )

    return {
        "target_year": target_date.year,
        "target_month": target_date.month,
        "base_monthly_budget_total": (
            base_monthly_budget_total
        ),
        "base_applicable_budget_total": (
            base_applicable_budget_total
        ),
        "monthly_income": monthly_income,
        "monthly_expense": monthly_expense,
        "net_cash_flow": net_cash_flow,
        "total_applicable_budget": (
            total_applicable_budget
        ),
        "total_remaining_budget": (
            total_remaining_budget
        ),
        "total_usage_percent": (
            total_usage_percent
        ),
        "remaining_days": remaining_days,
        "ungrouped_expense": ungrouped_expense,
        "budget_summaries": budget_summaries,
        "income_by_category": income_by_category,
        "expense_by_category": expense_by_category,
    }


def print_category_summary(
    title: str,
    category_totals: dict[str, int],
) -> None:
    """카테고리별 합계를 출력합니다."""

    print(f"\n[{title}]")

    if not category_totals:
        print("등록된 내역이 없습니다.")
        return

    sorted_items = sorted(
        category_totals.items(),
        key=lambda item: item[1],
        reverse=True,
    )

    for category, amount in sorted_items:
        print(f"- {category}: {format_won(amount)}")


def print_budget_summary(
    summary: dict[str, Any],
) -> None:
    """예산 그룹별 상세 현황을 출력합니다."""

    print(f"\n[{summary['name']}]")
    print(
        "월 기준 예산          : "
        f"{format_won(summary['monthly_budget'])}"
    )
    print(
        "이번 달 기본 적용예산 : "
        f"{format_won(summary['applicable_budget'])}"
    )
    print(
        "현재 사용 금액        : "
        f"{format_won(summary['used_amount'])}"
    )
    print(
        "남은 금액             : "
        f"{format_won(summary['remaining_amount'])}"
    )
    print(
        "사용률                : "
        f"{format_percent(summary['usage_percent'])}"
    )
    print(
        "오늘 권장 사용 금액    : "
        f"{format_won(summary['recommended_daily_amount'])}"
    )
    print(
        "상태                  : "
        f"{summary['status']}"
    )


def main() -> None:
    """J-OS 월간 재무 현황을 출력합니다."""

    today = date.today()
    finance_summary = build_finance_summary(today)

    print("\n" + "=" * 50)
    print(
        "J-OS 재무 현황 "
        f"· {finance_summary['target_year']}년 "
        f"{finance_summary['target_month']}월"
    )
    print("=" * 50)

    print("\n[이번 달 전체 현황]")
    print(
        "기본 적용예산 합계 : "
        f"{format_won(finance_summary['base_applicable_budget_total'])}"
    )
    print(
        "이번 달 수입 합계  : "
        f"{format_won(finance_summary['monthly_income'])}"
    )
    print(
        "이번 달 적용예산 합계: "
        f"{format_won(finance_summary['total_applicable_budget'])}"
    )
    print(
        "이번 달 지출 합계  : "
        f"{format_won(finance_summary['monthly_expense'])}"
    )
    print(
        "남은 적용예산      : "
        f"{format_won(finance_summary['total_remaining_budget'])}"
    )
    print(
        "전체 예산 사용률   : "
        f"{format_percent(finance_summary['total_usage_percent'])}"
    )
    print(
        "이번 달 수입-지출  : "
        f"{format_won(finance_summary['net_cash_flow'])}"
    )
    print(
        "이번 달 남은 일수  : "
        f"{finance_summary['remaining_days']}일"
    )

    print_category_summary(
        title="수입 출처별 합계",
        category_totals=finance_summary[
            "income_by_category"
        ],
    )

    print_category_summary(
        title="지출 카테고리별 합계",
        category_totals=finance_summary[
            "expense_by_category"
        ],
    )

    print("\n" + "-" * 50)
    print("예산 그룹별 상세 현황")
    print("-" * 50)

    budget_summaries = finance_summary[
        "budget_summaries"
    ]

    if not budget_summaries:
        print("\n등록된 월 예산 그룹이 없습니다.")

    for budget_summary in budget_summaries:
        print_budget_summary(budget_summary)

    ungrouped_expense = finance_summary[
        "ungrouped_expense"
    ]

    if ungrouped_expense > 0:
        print("\n[예산 그룹 미지정 지출]")
        print(
            "금액                  : "
            f"{format_won(ungrouped_expense)}"
        )
        print(
            "안내                  : "
            "거래에 budget_group을 지정해야 "
            "예산 그룹별 현황에 포함됩니다."
        )

    print("\n" + "=" * 50)


if __name__ == "__main__":
    main()