Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = "C:\Users\user\AI-Team\ai-team-briefings"

Set-Location $repo

git pull --rebase origin main

if ($LASTEXITCODE -ne 0) {
    throw "Initial git pull failed."
}

$today = Get-Date -Format "yyyy-MM-dd"

$prompt = @"
저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.

당신은 다음 네 팀이 오늘 작성한 브리핑을 검증하는 QA 에이전트입니다.

- 채용분석팀: recruitment/
- 청년지원팀: youth-support/
- 경제연구팀: economy/
- 학습팀: learning/

[권한과 작업 범위]

- 읽기는 저장소 전체에서 가능합니다.
- 파일 쓰기와 수정은 qa/ 폴더에서만 수행하세요.
- git add, git commit, git push 등 Git 변경 명령은 실행하지 마세요.
- Git 반영은 PowerShell 스크립트가 처리합니다.
- 사용자에게 질문하거나 선택지를 제시하지 말고 끝까지 완료하세요.

[검증 절차]

1. 각 팀 폴더에서 오늘 날짜인 $today 보고서를 확인하세요.
2. 보고서가 없으면 '보고서 없음'과 '검증 불가'를 명시하세요.
3. 채용공고와 지원정책의 URL, 모집 상태, 신청 기간 및 자격조건을 다시 확인하세요.
4. 경제 보고서의 수치, 날짜, 출처를 확인하세요.
5. 학습 보고서가 사용자의 실제 목표와 일치하는지 확인하세요.
6. 학습 보고서에 항공, 항공정비, 항공공학 등 제외된 주제가 다시 포함되지 않았는지 확인하세요.
7. git log와 git diff를 사용하여 이전 보고서 대비 누락되거나 비정상적으로 삭제된 항목이 있는지 확인하세요.
8. 확인되지 않은 내용을 추측하지 말고 '확인 필요' 또는 '검증 불가'로 표시하세요.
9. 원문을 직접 수정하지 말고 검증 결과만 qa/ 폴더에 작성하세요.

"qa/$today.md" 파일이 이미 존재해도 중단하지 말고 최신 검증 결과로 갱신하세요.

다음 형식으로 "qa/$today.md"를 작성하세요.

# QA 검증 리포트 $today

## 전체 요약

## 1. 채용분석팀
- 보고서 존재 여부:
- 정확성:
- 확인된 오류:
- 확인 필요:
- 누락 여부:
- 검증 근거:

## 2. 청년지원팀
- 보고서 존재 여부:
- 정확성:
- 확인된 오류:
- 확인 필요:
- 누락 여부:
- 검증 근거:

## 3. 경제연구팀
- 보고서 존재 여부:
- 정확성:
- 확인된 오류:
- 확인 필요:
- 누락 여부:
- 검증 근거:

## 4. 학습팀
- 보고서 존재 여부:
- 사용자 목표 일치 여부:
- 제외 주제 포함 여부:
- 확인된 오류:
- 확인 필요:
- 누락 여부:

## 최종 판정
- 통과:
- 부분 통과:
- 재검토 필요:
"@

claude --permission-mode dontAsk `
    --allowedTools "Read" "Write" "Edit" "Glob" "Grep" "WebSearch" "WebFetch" "Bash(git log *)" "Bash(git diff *)" `
    -p $prompt

if ($LASTEXITCODE -ne 0) {
    throw "Claude QA execution failed."
}

# Claude가 수정한 QA 보고서를 Git 스테이징 영역에 추가
git add -- "qa/"

if ($LASTEXITCODE -ne 0) {
    throw "git add failed."
}

# 스테이징된 QA 변경사항 확인
git diff --cached --quiet -- "qa/"
$diffResult = $LASTEXITCODE

if ($diffResult -eq 0) {
    Write-Host "No QA changes."
    exit 0
}

if ($diffResult -ne 1) {
    throw "Failed to inspect staged QA changes."
}

git commit -m "QA verification report $today"

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

Write-Host "QA report committed and pushed successfully."
