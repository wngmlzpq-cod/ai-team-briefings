"""J-OS 통합 실행 프로그램."""

from src.ai_team.finance import entry
from src.ai_team.finance import manager
from src.ai_team.finance import summary


def pause():
    """기능 실행 후 메인 메뉴로 돌아가기 전에 대기합니다."""

    input("\nEnter 키를 누르면 메인 메뉴로 돌아갑니다.")


def run_module_main(module, module_name):
    """모듈의 main 함수를 안전하게 실행합니다."""

    module_main = getattr(module, "main", None)

    if module_main is None:
        print(
            f"\n{module_name} 모듈에서 "
            "main() 함수를 찾을 수 없습니다."
        )
        return

    try:
        module_main()

    except KeyboardInterrupt:
        print("\n작업이 사용자에 의해 중단되었습니다.")

    except Exception as error:
        print("\n기능 실행 중 오류가 발생했습니다.")
        print(f"오류 종류: {type(error).__name__}")
        print(f"오류 내용: {error}")


def show_main_menu():
    """J-OS 재무 관리 메인 메뉴를 출력합니다."""

    print("\n================================")
    print("J-OS Finance")
    print("개인 재무 관리 시스템")
    print("================================")
    print("1. 거래 등록")
    print("2. 거래 조회")
    print("3. 거래 수정")
    print("4. 거래 삭제")
    print("5. 재무 요약")
    print("6. 거래 관리 메뉴")
    print("0. 프로그램 종료")
    print("================================")


def register_transaction():
    """거래 등록 기능을 실행합니다."""

    print("\n[거래 등록]")

    run_module_main(
        entry,
        "거래 등록",
    )


def view_transactions():
    """전체 거래내역을 출력합니다."""

    print("\n[거래 조회]")

    try:
        manager.show_transactions()

    except Exception as error:
        print("\n거래 조회 중 오류가 발생했습니다.")
        print(f"오류 종류: {type(error).__name__}")
        print(f"오류 내용: {error}")


def edit_transaction():
    """거래 수정 기능을 실행합니다."""

    print("\n[거래 수정]")

    try:
        manager.edit_transaction()

    except Exception as error:
        print("\n거래 수정 중 오류가 발생했습니다.")
        print(f"오류 종류: {type(error).__name__}")
        print(f"오류 내용: {error}")


def delete_transaction():
    """거래 삭제 기능을 실행합니다."""

    print("\n[거래 삭제]")

    try:
        manager.delete_transaction()

    except Exception as error:
        print("\n거래 삭제 중 오류가 발생했습니다.")
        print(f"오류 종류: {type(error).__name__}")
        print(f"오류 내용: {error}")


def show_finance_summary():
    """재무 요약 기능을 실행합니다."""

    print("\n[재무 요약]")

    run_module_main(
        summary,
        "재무 요약",
    )


def open_manager_menu():
    """기존 거래 관리 하위 메뉴를 실행합니다."""

    print("\n[거래 관리 메뉴]")

    try:
        manager.main()

    except Exception as error:
        print("\n거래 관리 메뉴 실행 중 오류가 발생했습니다.")
        print(f"오류 종류: {type(error).__name__}")
        print(f"오류 내용: {error}")


def main():
    """J-OS 통합 프로그램을 실행합니다."""

    while True:
        show_main_menu()

        choice = input("메뉴 선택: ").strip()

        if choice == "1":
            register_transaction()
            pause()

        elif choice == "2":
            view_transactions()
            pause()

        elif choice == "3":
            edit_transaction()
            pause()

        elif choice == "4":
            delete_transaction()
            pause()

        elif choice == "5":
            show_finance_summary()
            pause()

        elif choice == "6":
            open_manager_menu()

        elif choice == "0":
            print("\n================================")
            print("J-OS Finance를 종료합니다.")
            print("================================")
            break

        else:
            print("\n0부터 6까지의 번호를 입력해주세요.")


if __name__ == "__main__":
    main()