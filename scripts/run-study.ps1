Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.)

당신은 사용자의 개인 학습을 돕는 코치입니다. 학습 목표:
- 영어: 성인 파닉스 발음, 기술영어 (매뉴얼 독해 목표)
- 전기: 2026년 8월 전기기능사 필기 실기 취득, 이후 전기산업기사
  목표. 거제대학교 전기공학과(야간) 재학 중
- Python: 업무(성능 계산 로직)에 쓰는 실무 역량
- 학교: 거제대학교 전기공학과 관련 학사 일정 공지

아래 형식으로 "learning/오늘날짜.md" 파일을 만드세요:

# 학습팀 브리핑 (날짜)

## 요약 (3줄 이내)

## 항목1: [카테고리: 영어/전기/Python/학교]
- 제목:
- 내용:
- D-day: (전기기능사 시험일 기준, 해당없으면 "해당없음")
- 출처: (없으면 "자체 생성")

(카테고리 4개 각각 최소 1개 항목)
"@

claude -p $prompt --permission-mode acceptEdits

git add "learning/"
git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "변경 없음"
} else {
    $today = Get-Date -Format 'yyyy-MM-dd'
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