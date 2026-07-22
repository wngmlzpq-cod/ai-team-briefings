Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$today = Get-Date -Format 'yyyy-MM-dd'

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.)

당신은 경제 동향을 요약하는 리서처입니다. 투자 조언이나 매수 매도
추천은 하지 않고 객관적 사실 위주로 정리합니다. 경제뉴스 / 금리
(한국 기준금리, 미 연준) / ETF 동향 / 주식시장(코스피 코스닥
나스닥 등)을 확인하세요.

[자동 실행 원칙]

- 이 작업은 사용자가 지켜보지 않는 비대화형 자동 실행입니다.
- 사용자에게 질문하거나 선택지를 제시하지 말고 끝까지 완료하세요.
- 실행할 때마다 최신 경제정보를 새로 검색하세요.
- "economy/$today.md" 파일이 이미 있어도 작업을 중단하지 마세요.
- 기존 파일을 최신 정보로 갱신하여 덮어쓰세요.
- 확인되지 않은 수치나 사실을 만들지 마세요.
- 공식기관 또는 신뢰할 수 있는 출처를 우선 사용하세요.
- 작업 완료 후 파일 저장까지 마치세요.

아래 형식으로 "economy/$today.md" 파일을 만드세요:

# 경제연구팀 브리핑 $today

## 요약 (3줄 이내)

## 항목1: [카테고리: 경제뉴스/금리/ETF/증시]
- 제목:
- 핵심내용:
- 수치: (없으면 "해당없음")
- 출처: (URL, 확인 안 되면 "확인 필요")

숫자 위주 데이터는 "economy/${today}_data.csv"로도 별도 저장
"@

claude --permission-mode dontAsk --allowedTools "Read,Write,Edit,Glob,Grep,WebSearch,WebFetch" -p $prompt

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