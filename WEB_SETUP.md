# J-OS Web v1

1. 압축을 저장소 최상위 폴더에 풉니다. 기존 `src` 폴더와 병합합니다.
2. 가상환경을 활성화합니다.

```powershell
.\.venv\Scripts\Activate.ps1
pip install -r requirements-web.txt
.\run-web.ps1
```

3. 브라우저에서 접속합니다.

- 대시보드: http://127.0.0.1:8000
- 거래 관리: http://127.0.0.1:8000/transactions
- 거래 등록: http://127.0.0.1:8000/transactions/new

기존 `data/finance/transactions.json`을 그대로 사용합니다.
웹에서 수입·지출 등록, 검색, 수정, 삭제가 가능합니다.
