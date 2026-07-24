# AI Team v2 설치

1. 이 압축파일의 내용을 저장소 루트에 덮어씁니다.
2. 기존 `docs/assets/style.css`와 `docs/assets/app.js`는 삭제하지 않습니다.
3. 가상환경이 활성화된 터미널에서 실행합니다.

```powershell
python -m pip install -r requirements.txt
.\scripts\build-site.ps1
```

정상 결과:

```text
=== AI Team Portal Build Start ===
Generated: docs/learning/...
Generated: docs/index.html
Generated: docs/search-index.json
=== AI Team Portal Build Complete ===
```
