from __future__ import annotations

import json
from datetime import date, datetime
from pathlib import Path
from typing import Any
from uuid import uuid4


PROJECT_ROOT = Path(__file__).resolve().parents[3]

BUDGET_FILE = PROJECT_ROOT / "data" / "budget" / "monthly.json"
TRANSACTIONS_FILE = (
    PROJECT_ROOT / "data" / "finance" / "transactions.json"
)


def load_json(file_path: Path) -> dict[str, Any]:
    """JSON 파일을 읽어 딕셔너리로 반환한다."""
    if not file_path.exists():
        raise FileNotFoundError(
            f"파일을 찾을 수 없습니다: {file_path}"
        )

    try:
        with file_path.open("r", encoding="utf-8") as file:
            return json.load(file)

    except json.JSONDecodeError as error:
        raise ValueError(
            "JSON 형식이 올바르지 않습니다.\n"
            f"파일: {file_path}\n"
            f"위치: {error.lineno}번째 줄, "
            f"{error.colno}번째 칸"
        ) from error


def save_json(
    file_path: Path,
    data: dict[str, Any],
) -> None:
    """딕셔너리를 JSON 파일에 저장한다."""
    file_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with file_path.open("w", encoding="utf-8") as file:
        json.dump(
            data,
            file,
            ensure_ascii=False,
            indent=2,
        )


def select_transaction_type() -> str:
    """거래 유형을 선택한다."""
    while True:
        print("\n거래 유형")
        print("1. 지출")
        print("2. 수입")

        choice = input("번호 입력: ").strip()

        if choice == "1":
            return "expense"

        if choice == "2":
            return "income"

        print("1 또는 2를 입력하세요.")


def select_budget_group(
    monthly_limits: dict[str, Any],
    transaction_type: str,
) -> str | None:
    """지출인 경우 차감할 예산 그룹을 선택한다."""
    if transaction_type == "income":
        return None

    budget_groups = list(monthly_limits.items())

    print("\n차감할 예산")

    for index, (_, budget_info) in enumerate(
        budget_groups,
        start=1,
    ):
        print(
            f"{index}. "
            f"{budget_info['name']}"
        )

    while True:
        choice = input("번호 입력: ").strip()

        if not choice.isdigit():
            print("숫자로 입력하세요.")
            continue

        selected_index = int(choice) - 1

        if 0 <= selected_index < len(budget_groups):
            return budget_groups[selected_index][0]

        print("목록에 있는 번호를 입력하세요.")


def select_category(
    monthly_limits: dict[str, Any],
    budget_group: str | None,
    transaction_type: str,
) -> str:
    """카테고리를 선택하거나 직접 입력한다."""
    if transaction_type == "income":
        category = input(
            "수입 분류 입력 "
            "(예: 아르바이트, 지원금, 기타): "
        ).strip()

        return category or "기타수입"

    if budget_group is None:
        raise ValueError(
            "지출 거래에는 예산 그룹이 필요합니다."
        )

    categories = monthly_limits[budget_group].get(
        "categories",
        [],
    )

    print("\n카테고리")

    for index, category in enumerate(
        categories,
        start=1,
    ):
        print(f"{index}. {category}")

    custom_index = len(categories) + 1
    print(f"{custom_index}. 직접 입력")

    while True:
        choice = input("번호 입력: ").strip()

        if not choice.isdigit():
            print("숫자로 입력하세요.")
            continue

        selected_index = int(choice) - 1

        if 0 <= selected_index < len(categories):
            return categories[selected_index]

        if selected_index == len(categories):
            custom_category = input(
                "카테고리 이름: "
            ).strip()

            if custom_category:
                return custom_category

        print("목록에 있는 번호를 입력하세요.")


def input_amount() -> int:
    """0보다 큰 금액을 입력받는다."""
    while True:
        raw_amount = input(
            "금액 입력 "
            "(쉼표 없이 숫자만): "
        ).strip()

        if not raw_amount.isdigit():
            print("금액은 숫자로 입력하세요.")
            continue

        amount = int(raw_amount)

        if amount <= 0:
            print("0원보다 큰 금액을 입력하세요.")
            continue

        return amount


def input_transaction_date() -> str:
    """거래일을 입력한다. 공란이면 오늘 날짜를 사용한다."""
    while True:
        raw_date = input(
            f"날짜 입력 "
            f"(YYYY-MM-DD, 공란이면 {date.today()}): "
        ).strip()

        if not raw_date:
            return date.today().isoformat()

        try:
            return date.fromisoformat(
                raw_date
            ).isoformat()

        except ValueError:
            print(
                "날짜는 2026-07-25 형식으로 "
                "입력하세요."
            )


def create_transaction() -> dict[str, Any]:
    """사용자 입력을 받아 거래 한 건을 생성한다."""
    budget_data = load_json(BUDGET_FILE)
    monthly_limits = budget_data["monthly_limits"]

    transaction_type = select_transaction_type()

    budget_group = select_budget_group(
        monthly_limits=monthly_limits,
        transaction_type=transaction_type,
    )

    category = select_category(
        monthly_limits=monthly_limits,
        budget_group=budget_group,
        transaction_type=transaction_type,
    )

    description = input(
        "내용 입력: "
    ).strip()

    amount = input_amount()

    payment_method = input(
        "결제수단 입력 "
        "(예: 신한카드, 현금, 계좌이체): "
    ).strip()

    transaction_date = input_transaction_date()

    return {
        "id": uuid4().hex,
        "date": transaction_date,
        "type": transaction_type,
        "budget_group": budget_group,
        "category": category,
        "description": description,
        "amount": amount,
        "payment_method": payment_method,
        "created_at": datetime.now().isoformat(
            timespec="seconds"
        ),
    }


def print_transaction(
    transaction: dict[str, Any],
) -> None:
    """저장 전 거래 내용을 출력한다."""
    transaction_type_name = (
        "지출"
        if transaction["type"] == "expense"
        else "수입"
    )

    print("\n입력 내용 확인")
    print("-" * 40)
    print(f"유형       : {transaction_type_name}")
    print(f"날짜       : {transaction['date']}")
    print(f"분류       : {transaction['category']}")
    print(f"내용       : {transaction['description']}")
    print(f"금액       : {transaction['amount']:,}원")
    print(
        f"결제수단   : "
        f"{transaction['payment_method']}"
    )
    print("-" * 40)


def main() -> None:
    transactions_data = load_json(
        TRANSACTIONS_FILE
    )

    transactions = transactions_data.setdefault(
        "transactions",
        [],
    )

    transaction = create_transaction()
    print_transaction(transaction)

    confirmation = input(
        "저장하시겠습니까? (y/n): "
    ).strip().lower()

    if confirmation != "y":
        print("저장을 취소했습니다.")
        return

    transactions.append(transaction)

    save_json(
        TRANSACTIONS_FILE,
        transactions_data,
    )

    print("\n거래내역을 정상적으로 저장했습니다.")


if __name__ == "__main__":
    main()