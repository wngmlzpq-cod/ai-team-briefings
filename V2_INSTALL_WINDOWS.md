# Windows 기존 프로젝트에 J-OS v2 병합

현재 프로젝트 루트:

```text
C:\Users\user\AI-Team\ai-team-briefings
```

## 1. 기존 서버 종료

PowerShell에서 `Ctrl + C`.

## 2. 압축 내용 병합

이 패키지 안의 파일과 폴더를 프로젝트 루트로 복사합니다.

- `src`는 삭제하지 말고 병합
- 기존 `data`, `recruitment`, `youth-support`, `economy`, `learning`, `qa` 유지
- 같은 이름의 `src\ai_team\web` 파일은 v2로 교체

## 3. 의존성 설치

```powershell
cd C:\Users\user\AI-Team\ai-team-briefings
.\.venv\Scripts\Activate.ps1
pip install -r requirements-web.txt
```

## 4. 로컬 로그인 환경 변수

현재 PowerShell 창에만 적용:

```powershell
$env:JOS_USERNAME="juhee"
$env:JOS_PASSWORD="직접_정한_긴_비밀번호"
$env:JOS_SESSION_SECRET="아주_길고_무작위인_문자열"
```

## 5. 실행

```powershell
python -m uvicorn src.ai_team.web.app:app
```

접속:

```text
http://127.0.0.1:8000
```

## 포함 기능

- J-OS 통합 대시보드
- 재무 대시보드
- 거래 등록·검색·수정·삭제
- AI 팀 관제센터
- 채용분석·청년지원·경제연구·학습·검증 팀
- 각 팀 폴더의 Markdown, TXT, JSON, CSV 보고서 자동 표시
- 로그인 및 로그아웃
- Oracle Cloud Docker 배포 파일
