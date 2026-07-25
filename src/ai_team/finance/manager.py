from pathlib import Path
import json
from datetime import datetime


PROJECT_ROOT = Path(__file__).resolve().parents[3]

TRANSACTIONS_FILE = (
    PROJECT_ROOT
    / "data"
    / "finance"
    / "transactions.json"
)


def load_transactions():
    """거래내역을 JSON 파일에서 불러옵니다."""

    if not TRANSACTIONS_FILE.exists():
        return {"transactions": []}

    try:
        with open(
            TRANSACTIONS_FILE,
            "r",
            encoding="utf-8",
        ) as file:
            data = json.load(file)

    except json.JSONDecodeError:
        print("거래내역 파일의 JSON 형식이 올바르지 않습니다.")
        return {"transactions": []}

    if not isinstance(data, dict):
        return {"transactions": []}

    if "transactions" not in data:
        data["transactions"] = []

    return data


def save_transactions(data):
    """거래내역을 JSON 파일에 저장합니다."""

    TRANSACTIONS_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with open(
        TRANSACTIONS_FILE,
        "w",
        encoding="utf-8",
    ) as file:
        json.dump(
            data,
            file,
            ensure_ascii=False,
            indent=4,
        )


def translate_transaction_type(transaction_type):
    """영문 거래 유형을 한글로 변환합니다."""

    type_names = {
        "expense": "지출",
        "income": "수입",
    }

    return type_names.get(
        transaction_type,
        transaction_type,
    )


def show_single_transaction(transaction, index=None):
    """거래 한 건을 출력합니다."""

    if index is not None:
        print(f"\n[{index}]")

    print(f"날짜      : {transaction.get('date', '')}")
    print(
        "유형      : "
        f"{translate_transaction_type(transaction.get('type', ''))}"
    )
    print(f"카테고리  : {transaction.get('category', '')}")
    print(f"내용      : {transaction.get('description', '')}")
    print(f"금액      : {transaction.get('amount', 0):,}원")
    print(f"결제수단  : {transaction.get('payment_method', '')}")


def show_transactions(transactions=None):
    """전체 거래내역을 출력합니다."""

    if transactions is None:
        data = load_transactions()
        transactions = data.get("transactions", [])

    print("\n==============================")
    print("거래내역")
    print("==============================")

    if not transactions:
        print("등록된 거래가 없습니다.")
        return False

    for index, transaction in enumerate(
        transactions,
        start=1,
    ):
        show_single_transaction(
            transaction,
            index,
        )

    return True


def input_transaction_number(transactions, action_name):
    """수정하거나 삭제할 거래 번호를 입력받습니다."""

    while True:
        number_text = input(
            f"\n{action_name}할 거래 번호 (0=취소): "
        ).strip()

        if not number_text.isdigit():
            print("거래 번호는 숫자로 입력해주세요.")
            continue

        number = int(number_text)

        if number == 0:
            return None

        if number < 1 or number > len(transactions):
            print("존재하지 않는 거래 번호입니다.")
            continue

        return number - 1


def input_valid_date(current_date):
    """YYYY-MM-DD 형식의 날짜를 입력받습니다."""

    while True:
        new_date = input(
            f"새 날짜 [{current_date}]: "
        ).strip()

        if not new_date:
            return current_date

        try:
            datetime.strptime(
                new_date,
                "%Y-%m-%d",
            )
            return new_date

        except ValueError:
            print("날짜는 YYYY-MM-DD 형식으로 입력해주세요.")


def input_transaction_type(current_type):
    """지출 또는 수입 유형을 입력받습니다."""

    while True:
        print(
            "\n현재 유형:",
            translate_transaction_type(current_type),
        )
        print("1. 지출")
        print("2. 수입")
        print("0. 변경하지 않음")

        choice = input("선택: ").strip()

        if choice == "1":
            return "expense"

        if choice == "2":
            return "income"

        if choice == "0":
            return current_type

        print("0, 1, 2 중 하나를 입력해주세요.")


def input_text_value(label, current_value):
    """문자열 항목의 새 값을 입력받습니다."""

    new_value = input(
        f"새 {label} [{current_value}]: "
    ).strip()

    if not new_value:
        return current_value

    return new_value


def input_amount(current_amount):
    """0원 이상의 금액을 입력받습니다."""

    while True:
        amount_text = input(
            f"새 금액 [{current_amount:,}원]: "
        ).strip()

        if not amount_text:
            return current_amount

        amount_text = (
            amount_text
            .replace(",", "")
            .replace("원", "")
            .strip()
        )

        if not amount_text.isdigit():
            print("금액은 0 이상의 숫자로 입력해주세요.")
            continue

        return int(amount_text)


def show_edit_menu(transaction):
    """수정 가능한 항목 메뉴를 출력합니다."""

    print("\n==============================")
    print("거래 수정")
    print("==============================")

    show_single_transaction(transaction)

    print("\n------------------------------")
    print("1. 날짜 수정")
    print("2. 유형 수정")
    print("3. 카테고리 수정")
    print("4. 내용 수정")
    print("5. 금액 수정")
    print("6. 결제수단 수정")
    print("7. 전체 항목 수정")
    print("0. 수정 종료")


def edit_all_fields(transaction):
    """거래의 모든 항목을 순서대로 수정합니다."""

    transaction["date"] = input_valid_date(
        transaction.get("date", "")
    )

    transaction["type"] = input_transaction_type(
        transaction.get("type", "expense")
    )

    transaction["category"] = input_text_value(
        "카테고리",
        transaction.get("category", ""),
    )

    transaction["description"] = input_text_value(
        "내용",
        transaction.get("description", ""),
    )

    transaction["amount"] = input_amount(
        transaction.get("amount", 0)
    )

    transaction["payment_method"] = input_text_value(
        "결제수단",
        transaction.get("payment_method", ""),
    )


def edit_selected_transaction(transaction):
    """선택한 거래를 메뉴 방식으로 수정합니다."""

    changed = False

    while True:
        show_edit_menu(transaction)

        choice = input(
            "\n수정할 항목 선택: "
        ).strip()

        if choice == "0":
            return changed

        if choice == "1":
            transaction["date"] = input_valid_date(
                transaction.get("date", "")
            )
            changed = True

        elif choice == "2":
            transaction["type"] = input_transaction_type(
                transaction.get("type", "expense")
            )
            changed = True

        elif choice == "3":
            transaction["category"] = input_text_value(
                "카테고리",
                transaction.get("category", ""),
            )
            changed = True

        elif choice == "4":
            transaction["description"] = input_text_value(
                "내용",
                transaction.get("description", ""),
            )
            changed = True

        elif choice == "5":
            transaction["amount"] = input_amount(
                transaction.get("amount", 0)
            )
            changed = True

        elif choice == "6":
            transaction["payment_method"] = input_text_value(
                "결제수단",
                transaction.get("payment_method", ""),
            )
            changed = True

        elif choice == "7":
            edit_all_fields(transaction)
            changed = True

        else:
            print("0부터 7까지의 번호를 입력해주세요.")
            continue

        print("\n해당 항목을 수정했습니다.")


def edit_transaction():
    """거래를 선택해 수정합니다."""

    data = load_transactions()
    transactions = data.get("transactions", [])

    if not show_transactions(transactions):
        return

    transaction_index = input_transaction_number(
        transactions,
        "수정",
    )

    if transaction_index is None:
        print("\n거래 수정을 취소했습니다.")
        return

    transaction = transactions[transaction_index]

    changed = edit_selected_transaction(
        transaction
    )

    if not changed:
        print("\n변경된 내용이 없습니다.")
        return

    save_transactions(data)

    print("\n==============================")
    print("거래 수정 완료")
    print("==============================")

    show_single_transaction(transaction)


def delete_transaction():
    """거래를 선택해 삭제합니다."""

    data = load_transactions()
    transactions = data.get("transactions", [])

    if not show_transactions(transactions):
        return

    transaction_index = input_transaction_number(
        transactions,
        "삭제",
    )

    if transaction_index is None:
        print("\n거래 삭제를 취소했습니다.")
        return

    transaction = transactions[transaction_index]

    print("\n삭제 대상 거래")
    print("------------------------------")
    show_single_transaction(transaction)

    while True:
        confirmation = input(
            "\n정말 삭제하시겠습니까? (y/n): "
        ).strip().lower()

        if confirmation == "y":
            deleted_transaction = transactions.pop(
                transaction_index
            )

            save_transactions(data)

            print("\n==============================")
            print("거래 삭제 완료")
            print("==============================")

            show_single_transaction(
                deleted_transaction
            )
            return

        if confirmation == "n":
            print("\n거래 삭제를 취소했습니다.")
            return

        print("y 또는 n을 입력해주세요.")


def show_manager_menu():
    """거래 관리 메뉴를 출력합니다."""

    print("\n==============================")
    print("J-OS 거래 관리")
    print("==============================")
    print("1. 거래 조회")
    print("2. 거래 수정")
    print("3. 거래 삭제")
    print("0. 종료")


def main():
    """거래 관리 프로그램을 실행합니다."""

    while True:
        show_manager_menu()

        choice = input(
            "\n메뉴 선택: "
        ).strip()

        if choice == "1":
            show_transactions()

        elif choice == "2":
            edit_transaction()

        elif choice == "3":
            delete_transaction()

        elif choice == "0":
            print("\n거래 관리를 종료합니다.")
            break

        else:
            print("0부터 3까지의 번호를 입력해주세요.")


if __name__ == "__main__":
    main()