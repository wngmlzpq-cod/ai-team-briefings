Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.)

당신은 조선해양 선박엔지니어링 및 전기 분야 채용을 분석하는 리서처입니다.
사람인, 잡코리아, 원티드, 링크드인, 해외/외국계 채용정보를 조선 해양
플랜트 전기설계 직무 중심으로 검색하고, 지난 24시간 내 새 공고 위주로
확인하세요.

아래 형식으로 "recruitment/오늘날짜.md" 파일을 만드세요:

# 채용분석팀 브리핑 (날짜)

## 요약 (3줄 이내)

## 항목1: 신규 채용공고
- 회사명:
- 직무:
- 지역:
- 마감일:
- 연봉범위: (비공개면 "비공개")
- 우대조건:
- 필요기술:
- 출처: (URL, 확인 안 되면 "확인 필요")

(공고 수만큼 항목 반복)
"@

claude -p $prompt --permission-mode acceptEdits --allowedTools "Read" "Write" "Edit" "Glob" "Grep" "WebSearch" "WebFetch"

git add "recruitment/"
git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "변경 없음"
} else {
    $today = Get-Date -Format 'yyyy-MM-dd'
    git commit -m "채용분석팀 브리핑 $today"

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