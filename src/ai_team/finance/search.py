from __future__ import annotations

import json
from datetime import date
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[3]
TRANSACTIONS_FILE = (
    PROJECT_ROOT
    / "data"
    / "finance"
    / "transactions.json"
)


def load_transactions() -> list[dict[str, Any]]:
    """거래 JSON 파일을 읽어 거래 목록을 반환합니다."""

    if not TRANSACTIONS_FILE.exists():
        return []

    try:
        with TRANSACTIONS_FILE.open(
            "r",
            encoding="utf-8",
        ) as file:
            data = json.load(file)

    except json.JSONDecodeError as error:
        raise ValueError(
            "거래 파일의 JSON 형식이 올바르지 않습니다.\n"
            f"파일: {TRANSACTIONS_FILE}\n"
            f"위치: {error.lineno}번째 줄, "
            f"{error.colno}번째 칸"
        ) from error

    transactions = data.get("transactions", [])

    if not isinstance(transactions, list):
        return []

    return transactions


def normalize_text(value: Any) -> str:
    """검색 비교용 문자열로 변환합니다."""

    if value is None:
        return ""

    return str(value).strip().lower()


def normalize_amount(value: Any) -> int:
    """금액을 안전하게 정수로 변환합니다."""

    if isinstance(value, bool):
        return 0

    if isinstance(value, (int, float)):
        return int(value)

    if isinstance(value, str):
        cleaned = (
            value
            .replace(",", "")
            .replace("원", "")
            .strip()
        )

        try:
            return int(cleaned)
        except ValueError:
            return 0

    return 0


def matches_month(
    transaction: dict[str, Any],
    month_text: str | None,
) -> bool:
    """거래가 YYYY-MM 검색 조건에 맞는지 확인합니다."""

    if not month_text:
        return True

    transaction_date = normalize_text(
        transaction.get("date")
    )

    return transaction_date.startswith(
        month_text.strip()
    )


def matches_type(
    transaction: dict[str, Any],
    transaction_type: str | None,
) -> bool:
    """수입 또는 지출 유형 조건을 확인합니다."""

    if not transaction_type:
        return True

    return normalize_text(
        transaction.get("type")
    ) == normalize_text(transaction_type)


def matches_category(
    transaction: dict[str, Any],
    category: str | None,
) -> bool:
    """카테고리 부분 일치 여부를 확인합니다."""

    if not category:
        return True

    return normalize_text(category) in normalize_text(
        transaction.get("category")
    )


def matches_budget_group(
    transaction: dict[str, Any],
    budget_group: str | None,
) -> bool:
    """예산 그룹 조건을 확인합니다."""

    if not budget_group:
        return True

    return normalize_text(
        transaction.get("budget_group")
    ) == normalize_text(budget_group)


def matches_payment_method(
    transaction: dict[str, Any],
    payment_method: str | None,
) -> bool:
    """결제수단 부분 일치 여부를 확인합니다."""

    if not payment_method:
        return True

    return normalize_text(
        payment_method
    ) in normalize_text(
        transaction.get("payment_method")
    )


def matches_keyword(
    transaction: dict[str, Any],
    keyword: str | None,
) -> bool:
    """거래의 주요 문자 필드에서 키워드를 검색합니다."""

    if not keyword:
        return True

    keyword_normalized = normalize_text(keyword)

    searchable_fields = [
        transaction.get("date"),
        transaction.get("type"),
        transaction.get("budget_group"),
        transaction.get("category"),
        transaction.get("description"),
        transaction.get("payment_method"),
    ]

    return any(
        keyword_normalized in normalize_text(field)
        for field in searchable_fields
    )


def matches_amount_range(
    transaction: dict[str, Any],
    minimum_amount: int | None,
    maximum_amount: int | None,
) -> bool:
    """최소·최대 금액 조건을 확인합니다."""

    amount = normalize_amount(
        transaction.get("amount", 0)
    )

    if (
        minimum_amount is not None
        and amount < minimum_amount
    ):
        return False

    if (
        maximum_amount is not None
        and amount > maximum_amount
    ):
        return False

    return True


def search_transactions(
    transactions: list[dict[str, Any]],
    *,
    month: str | None = None,
    transaction_type: str | None = None,
    category: str | None = None,
    budget_group: str | None = None,
    payment_method: str | None = None,
    keyword: str | None = None,
    minimum_amount: int | None = None,
    maximum_amount: int | None = None,
) -> list[dict[str, Any]]:
    """
    거래 목록을 여러 조건으로 검색합니다.

    모든 조건은 동시에 적용됩니다.
    입력하지 않은 조건은 검색에서 제외됩니다.
    """

    results: list[dict[str, Any]] = []

    for transaction in transactions:
        if not matches_month(transaction, month):
            continue

        if not matches_type(
            transaction,
            transaction_type,
        ):
            continue

        if not matches_category(
            transaction,
            category,
        ):
            continue

        if not matches_budget_group(
            transaction,
            budget_group,
        ):
            continue

        if not matches_payment_method(
            transaction,
            payment_method,
        ):
            continue

        if not matches_keyword(
            transaction,
            keyword,
        ):
            continue

        if not matches_amount_range(
            transaction,
            minimum_amount,
            maximum_amount,
        ):
            continue

        results.append(transaction)

    return sorted(
        results,
        key=lambda transaction: (
            normalize_text(transaction.get("date")),
            normalize_text(transaction.get("created_at")),
        ),
        reverse=True,
    )


def format_won(amount: Any) -> str:
    """금액을 원화 형식으로 변환합니다."""

    return f"{normalize_amount(amount):,}원"


def translate_type(transaction_type: Any) -> str:
    """거래 유형을 한글로 변환합니다."""

    type_text = normalize_text(transaction_type)

    if type_text == "income":
        return "수입"

    if type_text == "expense":
        return "지출"

    return str(transaction_type or "미분류")


def print_transactions(
    transactions: list[dict[str, Any]],
) -> None:
    """검색 결과를 콘솔에 출력합니다."""

    if not transactions:
        print("\n검색 결과가 없습니다.")
        return

    print("\n" + "=" * 70)
    print(f"검색 결과: {len(transactions)}건")
    print("=" * 70)

    total_income = 0
    total_expense = 0

    for index, transaction in enumerate(
        transactions,
        start=1,
    ):
        transaction_type = transaction.get("type")
        amount = normalize_amount(
            transaction.get("amount", 0)
        )

        if transaction_type == "income":
            total_income += amount

        elif transaction_type == "expense":
            total_expense += amount

        print(f"\n[{index}]")
        print(
            f"날짜       : "
            f"{transaction.get('date', '-')}"
        )
        print(
            f"유형       : "
            f"{translate_type(transaction_type)}"
        )
        print(
            f"카테고리   : "
            f"{transaction.get('category') or '미분류'}"
        )
        print(
            f"내용       : "
            f"{transaction.get('description') or '-'}"
        )
        print(
            f"금액       : "
            f"{format_won(amount)}"
        )
        print(
            f"결제수단   : "
            f"{transaction.get('payment_method') or '-'}"
        )

    print("\n" + "-" * 70)
    print(f"수입 합계  : {format_won(total_income)}")
    print(f"지출 합계  : {format_won(total_expense)}")
    print(
        f"수입-지출  : "
        f"{format_won(total_income - total_expense)}"
    )
    print("=" * 70)


def input_optional_amount(
    message: str,
) -> int | None:
    """선택 입력 금액을 반환합니다."""

    value = input(message).strip()

    if not value:
        return None

    cleaned = (
        value
        .replace(",", "")
        .replace("원", "")
        .strip()
    )

    try:
        amount = int(cleaned)

    except ValueError:
        print("금액은 숫자로 입력해야 합니다.")
        return input_optional_amount(message)

    if amount < 0:
        print("금액은 0원 이상이어야 합니다.")
        return input_optional_amount(message)

    return amount


def main() -> None:
    """콘솔 거래 검색 화면을 실행합니다."""

    transactions = load_transactions()

    print("\n" + "=" * 45)
    print("J-OS 거래 검색")
    print("=" * 45)
    print("조건을 입력하지 않고 Enter를 누르면")
    print("해당 조건은 검색에서 제외됩니다.\n")

    month = input(
        "연월 YYYY-MM: "
    ).strip() or None

    print("\n거래 유형")
    print("1. 수입")
    print("2. 지출")
    print("Enter. 전체")

    type_choice = input(
        "선택: "
    ).strip()

    transaction_type = None

    if type_choice == "1":
        transaction_type = "income"

    elif type_choice == "2":
        transaction_type = "expense"

    category = input(
        "카테고리: "
    ).strip() or None

    budget_group = input(
        "예산 그룹: "
    ).strip() or None

    payment_method = input(
        "결제수단: "
    ).strip() or None

    keyword = input(
        "검색어: "
    ).strip() or None

    minimum_amount = input_optional_amount(
        "최소 금액: "
    )

    maximum_amount = input_optional_amount(
        "최대 금액: "
    )

    if (
        minimum_amount is not None
        and maximum_amount is not None
        and minimum_amount > maximum_amount
    ):
        print(
            "\n최소 금액이 최대 금액보다 큽니다."
        )
        return

    results = search_transactions(
        transactions,
        month=month,
        transaction_type=transaction_type,
        category=category,
        budget_group=budget_group,
        payment_method=payment_method,
        keyword=keyword,
        minimum_amount=minimum_amount,
        maximum_amount=maximum_amount,
    )

    print_transactions(results)


if __name__ == "__main__":
    main()