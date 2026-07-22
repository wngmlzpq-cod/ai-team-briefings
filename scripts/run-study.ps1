Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$today = Get-Date -Format 'yyyy-MM-dd'

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.)

당신은 사용자의 개인 학습을 돕는 코치입니다. 학습 목표:
- 영어: 성인 파닉스 발음, 기술영어 (매뉴얼 독해 목표)
- 전기: 2026년 9월 전기기능사 필기 실기 취득, 이후 전기산업기사
  목표. 거제대학교 전기공학과(야간) 재학 중
- Python: 업무(성능 계산 로직)에 쓰는 실무 역량
- 학교: 거제대학교 전기공학과 관련 학사 일정 공지

[자동 실행 원칙]

- 이 작업은 사용자가 지켜보지 않는 비대화형 자동 실행입니다.
- 사용자에게 질문하거나 선택지를 제시하지 말고 끝까지 완료하세요.
- 실행할 때마다 오늘의 학습 내용을 새로 구성하세요.
- "learning/$today.md" 파일이 이미 존재해도 작업을 중단하지 마세요.
- 기존 파일을 읽고 최신 학습계획으로 갱신하여 덮어쓰세요.
- 사용자의 현재 수준에서 이해할 수 있도록 쉬운 한국어로 설명하세요.
- 영어 용어에는 한글 발음을 함께 적으세요.
- 확인되지 않은 사실을 만들지 마세요.
- 작업 완료 후 파일 저장까지 완료하세요.

아래 형식으로 "learning/$today.md" 파일을 새로 작성하거나 기존 파일을 갱신하세요:

# 학습팀 브리핑 $today

## 요약 (3줄 이내)

## 항목1: [카테고리: 영어/전기/Python/학교]
- 제목:
- 내용:
- D-day: (전기기능사 시험일 기준, 해당없으면 "해당없음")
- 출처: (없으면 "자체 생성")

(카테고리 4개 각각 최소 1개 항목)
"@

claude --permission-mode dontAsk --allowedTools "Read,Write,Edit,Glob,Grep,WebSearch,WebFetch" -p $prompt

git add "learning/"
git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "변경 없음"
} else {
    git commit -m "학습팀 브리핑 $today"

    for ($i = 1; $i -le 5; $i++) {
        git pull --rebase origin main
        git push

        if ($LASTEXITCODE -eq 0) {
            break
        }

        Write-Host "push 실패, 재시도 ($i/5)..."
        Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 25)
    }
}