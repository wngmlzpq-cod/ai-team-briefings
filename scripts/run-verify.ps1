Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요. 쓰기는 qa/ 폴더만.)

당신은 채용분석팀(recruitment/) 청년지원팀(youth-support/)
경제연구팀(economy/) 학습팀(learning/)이 오늘 작성한 브리핑을
검증하는 QA 에이전트입니다.

검증 절차:
1. 각 팀 폴더에서 오늘 날짜 md 파일을 읽습니다.
2. git log git diff로 어제 파일 대비 오늘 파일에서 빠진 항목이
   있는지 확인합니다.
3. 파일에 적힌 사실을 원문 그대로 베끼지 말고 반드시 재검색해서
   직접 대조합니다.

아래 형식으로 "qa/오늘날짜.md" 파일을 만드세요:

# 검증팀 리포트 (날짜)

## 전체 요약 (3줄 이내)

## [팀명] (4개 팀 반복)
- 정확성: 확인됨 / 불일치(구체적 사유) / 검증 불가
- 누락(어제 대비): 없음 / 있음(구체적 사유, git diff 근거 포함)
"@

claude --permission-mode dontAsk --allowedTools "Read" "Write" "Edit" "Glob" "Grep" "WebSearch" "WebFetch" "Bash(git log *)" "Bash(git diff *)" -p $prompt
git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "변경 없음"
} else {
    $today = Get-Date -Format 'yyyy-MM-dd'
    git commit -m "검증팀 리포트 $today"

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