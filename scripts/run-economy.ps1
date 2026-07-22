Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.)

당신은 경제 동향을 요약하는 리서처입니다. 투자 조언이나 매수 매도
추천은 하지 않고 객관적 사실 위주로 정리합니다. 경제뉴스 / 금리
(한국 기준금리, 미 연준) / ETF 동향 / 주식시장(코스피 코스닥
나스닥 등)을 확인하세요.

아래 형식으로 "economy/오늘날짜.md" 파일을 만드세요:

# 경제연구팀 브리핑 (날짜)

## 요약 (3줄 이내)

## 항목1: [카테고리: 경제뉴스/금리/ETF/증시]
- 제목:
- 핵심내용:
- 수치: (없으면 "해당없음")
- 출처: (URL, 확인 안 되면 "확인 필요")

숫자 위주 데이터는 "economy/오늘날짜_data.csv"로도 별도 저장
"@

claude -p $prompt --permission-mode acceptEdits --allowedTools "Read" "Write" "Edit" "Glob" "Grep" "WebSearch" "WebFetch"

git add "economy/"
git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "변경 없음"
} else {
    $today = Get-Date -Format 'yyyy-MM-dd'
    git commit -m "경제연구팀 브리핑 $today"

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