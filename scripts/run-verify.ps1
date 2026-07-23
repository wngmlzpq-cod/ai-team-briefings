Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = "C:\Users\user\AI-Team\ai-team-briefings"
$today = Get-Date -Format "yyyy-MM-dd"

Set-Location $repo

function Invoke-ClaudeOrThrow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [string[]]$AllowedTools,

        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage
    )

    & claude --permission-mode dontAsk --allowedTools $AllowedTools -p $Prompt

    if ($LASTEXITCODE -ne 0) {
        throw $ErrorMessage
    }
}

function Read-RepairJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Repair JSON was not created: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $raw = $raw.Trim()

    # Claude가 실수로 Markdown 코드펜스를 붙인 경우 제거
    if ($raw.StartsWith('```')) {
        $raw = $raw -replace '^```(?:json)?\s*', ''
        $raw = $raw -replace '\s*```$', ''
        $raw = $raw.Trim()
    }

    try {
        return $raw | ConvertFrom-Json
    }
    catch {
        throw "Repair JSON parse failed: $($_.Exception.Message)"
    }
}

Write-Host "=== AI-Team self-healing QA started: $today ==="

git pull --rebase origin main
if ($LASTEXITCODE -ne 0) {
    throw "Initial git pull failed."
}

$initialQaPath = Join-Path $repo "qa\$today-initial.md"
$repairJsonPath = Join-Path $repo "qa\$today-repair.json"
$finalQaPath = Join-Path $repo "qa\$today.md"
$finalHtmlPath = Join-Path $repo "qa\$today.html"

# 이전 실행 잔여 파일 제거
Remove-Item -LiteralPath $initialQaPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $repairJsonPath -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# 1단계: 1차 QA 검사 + 재작업 지시 JSON 생성
# ---------------------------------------------------------------------------

$initialPrompt = @"
저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.

당신은 AI-Team의 1차 QA 에이전트입니다.
오늘 날짜는 $today 입니다.

검증 대상:
- 채용분석팀: recruitment/
- 청년지원팀: youth-support/
- 경제연구팀: economy/
- 학습팀: learning/

[권한과 작업 범위]
- 저장소 전체를 읽을 수 있습니다.
- 쓰기/수정은 qa/ 폴더에서만 수행하세요.
- 원본 팀 보고서는 절대 수정하지 마세요.
- git 명령은 실행하지 마세요.
- 사용자에게 질문하지 마세요.

[보고서 날짜 규칙]
- recruitment/$today.md, economy/$today.md, learning/$today.md를 검증하세요.
- 청년지원팀은 월요일이면 youth-support/$today.md를 검증하세요.
- 화요일~일요일이면 youth-support/에서 가장 최근 보고서를 검증하세요.
- 최근 청년지원 보고서가 7일 이내면 정상 대상입니다.
- 최근 7일 이내 파일이 없을 때만 보고서 없음으로 판정하세요.

[검증 내용]
1. 채용공고 및 지원정책의 URL, 모집 상태, 기간, 지역, 경력, 자격조건을 확인하세요.
2. 경제 보고서의 수치, 날짜, 출처를 확인하세요.
3. 학습 보고서가 사용자의 목표(파닉스, 전기·엔지니어링 영어, 전기, Python·AI 자동화)에 맞는지 확인하세요.
4. 항공·항공정비·항공공학은 제외되어야 합니다.
5. git log와 git diff로 이전 보고서 대비 비정상 삭제·누락을 확인하세요.
6. 추측하지 말고 확인되지 않은 것은 확인 필요 또는 검증 불가로 표시하세요.
7. 자동 재작업은 명확한 오류가 있을 때만 요청하세요.
8. 단순한 표현 개선, 취향 차이, 경미한 문장 문제는 자동 재작업 대상으로 지정하지 마세요.

[반드시 생성할 파일 1]
qa/$today-initial.md

형식:
# 1차 QA 검증 리포트 $today

## 전체 요약

## 1. 채용분석팀
- 상태:
- 확인된 오류:
- 확인 필요:
- 검증 근거:
- 자동 재작업 필요 여부:

## 2. 청년지원팀
- 상태:
- 확인된 오류:
- 확인 필요:
- 검증 근거:
- 자동 재작업 필요 여부:

## 3. 경제연구팀
- 상태:
- 확인된 오류:
- 확인 필요:
- 검증 근거:
- 자동 재작업 필요 여부:

## 4. 학습팀
- 상태:
- 확인된 오류:
- 확인 필요:
- 검증 근거:
- 자동 재작업 필요 여부:

[반드시 생성할 파일 2]
qa/$today-repair.json

이 파일은 순수 JSON만 작성하세요. Markdown 코드펜스를 절대 붙이지 마세요.
다음 스키마를 정확히 따르세요.

{
  "date": "$today",
  "needs_rework": true,
  "teams": [
    {
      "team": "recruitment",
      "target_file": "recruitment/$today.md",
      "severity": "major",
      "auto_repair": true,
      "reasons": [
        "구체적인 오류와 근거"
      ]
    }
  ]
}

규칙:
- team 값은 recruitment, youth-support, economy, learning 중 하나만 사용하세요.
- severity 값은 critical, major, minor 중 하나만 사용하세요.
- auto_repair는 true 또는 false만 사용하세요.
- 자동 재작업은 severity가 critical 또는 major이며, 실제로 수정 가능한 오류일 때만 true로 지정하세요.
- 단순 확인 필요나 외부 사이트 접근 불가는 auto_repair=false로 지정하세요.
- 같은 팀은 teams 배열에 한 번만 넣으세요.
- 오류가 없으면 needs_rework=false, teams=[]로 작성하세요.
- target_file에는 실제 검증한 저장소 상대경로를 넣으세요.
- 보고서가 완전히 누락된 경우에도 생성해야 할 예상 상대경로를 넣고, reasons에 누락 사실을 명시하세요.

두 파일을 모두 작성한 뒤 종료하세요.
"@

Invoke-ClaudeOrThrow `
    -Prompt $initialPrompt `
    -AllowedTools @(
        "Read",
        "Write",
        "Edit",
        "Glob",
        "Grep",
        "WebSearch",
        "WebFetch",
        "Bash(git log *)",
        "Bash(git diff *)"
    ) `
    -ErrorMessage "Initial Claude QA execution failed."

$repairPlan = Read-RepairJson -Path $repairJsonPath

$allowedTeams = @("recruitment", "youth-support", "economy", "learning")
$allowedRoots = @{
    "recruitment"   = "recruitment/"
    "youth-support" = "youth-support/"
    "economy"       = "economy/"
    "learning"      = "learning/"
}

$repairResults = New-Object System.Collections.Generic.List[string]

# ---------------------------------------------------------------------------
# 2단계: 오류 팀별 최대 1회 자동 재작업
# ---------------------------------------------------------------------------

if ($repairPlan.needs_rework -eq $true -and $null -ne $repairPlan.teams) {
    foreach ($item in @($repairPlan.teams)) {
        $team = [string]$item.team
        $targetFile = ([string]$item.target_file).Replace("\", "/")
        $severity = [string]$item.severity
        $autoRepair = [bool]$item.auto_repair
        $reasons = @($item.reasons | ForEach-Object { [string]$_ })

        if ($team -notin $allowedTeams) {
            $repairResults.Add("SKIPPED: 허용되지 않은 팀 이름 '$team'")
            continue
        }

        if (-not $autoRepair) {
            $repairResults.Add("NOT_REQUIRED: $team (자동 수정 대상 아님)")
            continue
        }

        if ($severity -notin @("critical", "major")) {
            $repairResults.Add("SKIPPED: $team (심각도 $severity)")
            continue
        }

        $expectedRoot = $allowedRoots[$team]
        if (-not $targetFile.StartsWith($expectedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $repairResults.Add("SKIPPED: $team 대상 경로가 허용 범위를 벗어남: $targetFile")
            continue
        }

        if ($targetFile.Contains("..")) {
            $repairResults.Add("SKIPPED: $team 대상 경로에 '..' 포함: $targetFile")
            continue
        }

        $reasonText = ($reasons | ForEach-Object { "- $_" }) -join "`n"

        Write-Host ""
        Write-Host "=== Reworking team: $team ==="
        Write-Host "Target: $targetFile"

        $repairPrompt = @"
저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.

당신은 $team 팀의 재작업 담당 에이전트입니다.
오늘 날짜는 $today 입니다.

1차 QA가 다음 보고서에서 중대한 오류를 발견했습니다.

대상 파일:
$targetFile

오류와 재작업 사유:
$reasonText

[작업 규칙]
- 대상 팀 폴더와 대상 파일의 기존 내용을 먼저 읽으세요.
- QA가 지적한 각 오류를 공식 출처 또는 신뢰 가능한 1차 출처로 다시 확인하세요.
- 확인된 사실만 반영하여 대상 보고서를 직접 수정하세요.
- 보고서가 누락됐다면 CLAUDE.md와 해당 팀의 기존 보고서 형식을 참고하여 대상 파일을 새로 작성하세요.
- 잘못된 URL, 마감일, 지역, 경력, 자격조건, 수치, 출처를 바로잡으세요.
- 확인할 수 없는 내용은 삭제하거나 '확인 필요'라고 명확히 표시하세요.
- QA 지적과 무관한 정상 내용을 함부로 삭제하지 마세요.
- 사용자의 목표와 무관한 내용을 추가하지 마세요.
- 항공·항공정비·항공공학 내용을 추가하지 마세요.
- 수정 권한은 $expectedRoot 폴더 안으로 제한합니다.
- qa/ 파일은 수정하지 마세요.
- git add, git commit, git push를 실행하지 마세요.
- 사용자에게 질문하지 말고 재작업을 한 번 완료한 뒤 종료하세요.
"@

        try {
            Invoke-ClaudeOrThrow `
                -Prompt $repairPrompt `
                -AllowedTools @(
                    "Read",
                    "Write",
                    "Edit",
                    "Glob",
                    "Grep",
                    "WebSearch",
                    "WebFetch"
                ) `
                -ErrorMessage "Claude rework failed for team: $team"

            $repairResults.Add("SUCCESS: $team → $targetFile")
        }
        catch {
            $repairResults.Add("FAILED: $team → $($_.Exception.Message)")
            Write-Warning $_.Exception.Message
        }
    }
}
else {
    $repairResults.Add("NO_REWORK: 1차 QA에서 자동 재작업 대상 없음")
}

$repairSummary = ($repairResults | ForEach-Object { "- $_" }) -join "`n"

# ---------------------------------------------------------------------------
# 3단계: 최종 QA 재검사 + 최종 MD/HTML 생성
# ---------------------------------------------------------------------------

$finalPrompt = @"
저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.

당신은 AI-Team의 최종 QA 에이전트입니다.
오늘 날짜는 $today 입니다.

1차 QA 이후 담당팀별 자동 재작업 결과:
$repairSummary

검증 대상:
- 채용분석팀: recruitment/
- 청년지원팀: youth-support/
- 경제연구팀: economy/
- 학습팀: learning/

[권한과 작업 범위]
- 저장소 전체를 읽을 수 있습니다.
- 쓰기/수정은 qa/ 폴더에서만 수행하세요.
- 팀 원본 보고서는 수정하지 마세요.
- git 명령은 실행하지 마세요.
- 추가 재작업을 요청하거나 수행하지 마세요.
- 사용자에게 질문하지 마세요.

[보고서 날짜 규칙]
- recruitment/$today.md, economy/$today.md, learning/$today.md를 검증하세요.
- 청년지원팀은 월요일이면 youth-support/$today.md를 검증하세요.
- 화요일~일요일이면 youth-support/에서 가장 최근 보고서를 검증하세요.
- 최근 7일 이내 청년지원 보고서는 정상 대상입니다.

[최종 검증]
1. 1차 QA에서 지적된 오류가 실제로 수정됐는지 다시 확인하세요.
2. 채용공고와 지원정책의 공식 URL, 모집 상태, 기간, 지역, 경력, 자격조건을 재확인하세요.
3. 경제 수치, 날짜, 비교 기준, 출처를 재확인하세요.
4. 학습 내용이 파닉스, 전기·엔지니어링 영어, 전기, Python·AI 자동화 목표에 맞는지 확인하세요.
5. 항공·항공정비·항공공학이 포함되지 않았는지 확인하세요.
6. 자동 재작업이 실패했거나 오류가 남았다면 숨기지 말고 '재검토 필요'로 표시하세요.
7. 확인되지 않은 내용은 추측하지 마세요.

[최종 Markdown]
qa/$today.md를 최신 결과로 작성하세요.

형식:
# QA 검증 리포트 $today

## 전체 요약
- 최종 판정:
- 자동 재작업 실행 결과:
- 남은 주요 문제:

## 1. 채용분석팀
- 보고서 존재 여부:
- 최종 상태:
- 정확성:
- 수정 확인:
- 남은 오류:
- 확인 필요:
- 누락 여부:
- 검증 근거:

## 2. 청년지원팀
- 보고서 존재 여부:
- 최종 상태:
- 정확성:
- 수정 확인:
- 남은 오류:
- 확인 필요:
- 누락 여부:
- 검증 근거:

## 3. 경제연구팀
- 보고서 존재 여부:
- 최종 상태:
- 정확성:
- 수정 확인:
- 남은 오류:
- 확인 필요:
- 누락 여부:
- 검증 근거:

## 4. 학습팀
- 보고서 존재 여부:
- 최종 상태:
- 사용자 목표 일치 여부:
- 제외 주제 포함 여부:
- 수정 확인:
- 남은 오류:
- 확인 필요:
- 누락 여부:

## 자동 재작업 기록
$repairSummary

## 최종 판정
- 통과:
- 부분 통과:
- 재검토 필요:

[최종 HTML 대시보드]
qa/$today.html도 반드시 작성하세요.

조건:
1. UTF-8이며 <meta charset="UTF-8">을 포함하세요.
2. CSS는 내부 <style>만 사용하세요.
3. 외부 CSS, JavaScript, 폰트, CDN을 사용하지 마세요.
4. 휴대폰과 PC에서 읽기 쉬운 반응형 구조로 작성하세요.
5. 검증 결과와 실제 원본 내용만 사용하세요.
6. 공식 URL은 클릭 가능한 링크로 표시하세요.
7. 자동 재작업 전후 결과와 아직 남은 오류를 분명히 구분하세요.
8. 최종 상태는 통과, 부분 통과, 재검토 필요, 검증 불가 중 하나로 표시하세요.

HTML 구성:
- 헤더: AI-Team Daily Dashboard, 기준 날짜, 전체 판정, 업데이트 시각
- 팀별 최종 상태 카드
- 오늘 반드시 확인할 내용 최대 5개
- 자동 재작업 결과
- 채용분석 표
- 청년지원 표
- 경제 핵심 수치 카드
- 학습 계획
- 남은 검증 경고
- 원본 파일 바로가기

원본 파일 상대경로:
- ../recruitment/$today.md
- ../economy/$today.md
- ../learning/$today.md
- 검증한 최신 youth-support 파일
- ./$today.md

qa/$today.md와 qa/$today.html을 모두 작성한 뒤 종료하세요.
"@

Invoke-ClaudeOrThrow `
    -Prompt $finalPrompt `
    -AllowedTools @(
        "Read",
        "Write",
        "Edit",
        "Glob",
        "Grep",
        "WebSearch",
        "WebFetch",
        "Bash(git log *)",
        "Bash(git diff *)"
    ) `
    -ErrorMessage "Final Claude QA execution failed."

if (-not (Test-Path -LiteralPath $finalQaPath)) {
    throw "Final QA Markdown was not created: $finalQaPath"
}

if (-not (Test-Path -LiteralPath $finalHtmlPath)) {
    throw "Final QA HTML was not created: $finalHtmlPath"
}

# 세로형 QA 대시보드 HTML 생성
Write-Host ""
Write-Host "Generating vertical QA dashboard HTML..."

& powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot "build-dashboard.ps1") `
    -QaPath $finalQaPath `
    -OutputPath (Join-Path $repo "qa\dashboard-$today.html")

if ($LASTEXITCODE -ne 0) {
    throw "Vertical dashboard HTML generation failed."
}

$dashboardHtmlPath = Join-Path $repo "qa\dashboard-$today.html"

if (-not (Test-Path -LiteralPath $dashboardHtmlPath)) {
    throw "Vertical dashboard HTML was not created: $dashboardHtmlPath"
}

# 세로형 QA 대시보드 PNG 생성
Write-Host "Converting vertical QA dashboard to PNG..."

& powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot "convert-dashboard-to-png.ps1") `
    -HtmlPath $dashboardHtmlPath `
    -OutputPath (Join-Path $repo "qa\dashboard-$today.png")

if ($LASTEXITCODE -ne 0) {
    throw "Vertical dashboard PNG generation failed."
}

$dashboardPngPath = Join-Path $repo "qa\dashboard-$today.png"

if (-not (Test-Path -LiteralPath $dashboardPngPath)) {
    throw "Vertical dashboard PNG was not created: $dashboardPngPath"
}

Write-Host "Dashboard HTML: qa/dashboard-$today.html"
Write-Host "Dashboard PNG : qa/dashboard-$today.png"

# 중간 산출물은 저장소에 남기되, 카카오 전송 대상은 최종 qa/YYYY-MM-DD.md
git add -- "recruitment/" "youth-support/" "economy/" "learning/" "qa/"

if ($LASTEXITCODE -ne 0) {
    throw "git add failed."
}

git diff --cached --quiet
$diffResult = $LASTEXITCODE

if ($diffResult -eq 0) {
    Write-Host "No changes to commit."
    exit 0
}

if ($diffResult -ne 1) {
    throw "Failed to inspect staged changes."
}

git commit -m "Self-healing QA report $today"

if ($LASTEXITCODE -ne 0) {
    throw "git commit failed."
}

$pushSucceeded = $false

for ($attempt = 1; $attempt -le 5; $attempt++) {
    git pull --rebase origin main

    if ($LASTEXITCODE -ne 0) {
        throw "git pull --rebase failed."
    }

    git push origin main

    if ($LASTEXITCODE -eq 0) {
        $pushSucceeded = $true
        break
    }

    Write-Host "Push failed. Retrying ($attempt/5)..."
    Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 25)
}

if (-not $pushSucceeded) {
    throw "QA report push failed after 5 attempts."
}

Write-Host ""
Write-Host "=== Self-healing QA completed successfully ==="
Write-Host "Final Markdown: qa/$today.md"
Write-Host "Final HTML: qa/$today.html"
Write-Host "GitHub push: completed"

