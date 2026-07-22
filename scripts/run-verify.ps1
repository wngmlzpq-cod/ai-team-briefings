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

1. [보고서 날짜 확인 원칙]에 따라 각 팀의 검증 대상 보고서를 확인하세요.
2. 보고서가 없으면 '보고서 없음'과 '검증 불가'를 명시하세요.
3. 채용공고와 지원정책의 URL, 모집 상태, 신청 기간 및 자격조건을 다시 확인하세요.
4. 경제 보고서의 수치, 날짜, 출처를 확인하세요.
5. 학습 보고서가 사용자의 실제 목표와 일치하는지 확인하세요.
6. 학습 보고서에 항공, 항공정비, 항공공학 등 제외된 주제가 다시 포함되지 않았는지 확인하세요.
7. git log와 git diff를 사용하여 이전 보고서 대비 누락되거나 비정상적으로 삭제된 항목이 있는지 확인하세요.
8. 확인되지 않은 내용을 추측하지 말고 '확인 필요' 또는 '검증 불가'로 표시하세요.
9. 원문을 직접 수정하지 말고 검증 결과만 qa/ 폴더에 작성하세요.

[보고서 날짜 확인 원칙]

- 채용분석팀, 경제연구팀, 학습팀은 오늘 날짜인 $today 보고서를 검증하세요.
- 청년지원팀은 매주 월요일에만 새 보고서를 작성합니다.
- 오늘이 월요일이면 youth-support/$today.md를 검증하세요.
- 오늘이 화요일부터 일요일이면 youth-support/ 폴더에서 가장 최근에 생성된 보고서를 검증하세요.
- 최근 청년지원 보고서가 7일 이내라면 정상으로 판단하고, 오늘 파일이 없다는 이유로 결측 처리하지 마세요.
- 최근 7일 이내 보고서가 하나도 없을 때만 '보고서 없음'과 '검증 불가'로 표시하세요.
- 청년지원팀의 누락 비교는 직전 날짜가 아니라 직전 주간 보고서와 비교하세요.

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

[HTML 대시보드 추가 생성]

Markdown 검증 보고서와 별도로 다음 파일도 반드시 작성하세요.

- qa/$today.html

HTML 파일은 사용자가 오전 9시에 가장 먼저 확인하는 최종 통합 대시보드입니다.

다음 조건을 지키세요.

1. UTF-8 한글 HTML로 작성하세요.
2. <meta charset="UTF-8">을 반드시 포함하세요.
3. CSS는 HTML 파일 내부의 <style> 태그에 작성하세요.
4. 외부 CSS, 외부 JavaScript, 외부 폰트와 CDN을 사용하지 마세요.
5. 인터넷 연결이 없어도 파일 자체가 정상적으로 표시되어야 합니다.
6. 사용자가 휴대폰과 PC에서 모두 읽을 수 있도록 반응형으로 작성하세요.
7. 원본 보고서의 내용을 과장하거나 새로 만들어내지 마세요.
8. 검증 결과와 실제 원본 보고서 내용을 기준으로 작성하세요.
9. 각 채용공고·지원정책의 공식 URL은 클릭 가능한 링크로 표시하세요.
10. HTML을 생성한 뒤 사용자에게 질문하지 말고 작업을 완료하세요.

HTML 대시보드는 다음 순서로 구성하세요.

<header>
- AI-Team Daily Dashboard
- 기준 날짜
- 전체 판정
- 최종 업데이트 시각
</header>

<section>
- 채용분석팀 상태
- 청년지원팀 상태
- 경제연구팀 상태
- 학습팀 상태
</section>

각 팀의 상태는 다음 중 하나로 표시하세요.

- 통과
- 부분 통과
- 재검토 필요
- 검증 불가

[오늘 반드시 확인할 내용]

사용자가 실제로 조치해야 할 사항만 최대 5개로 정리하세요.

예:
- 지원 가치가 높은 채용공고
- 마감이 임박한 지원정책
- 잘못되거나 확인이 필요한 정보
- 오늘 학습할 핵심 내용
- 경제지표에서 주의할 변화

[채용분석팀]

다음 내용을 표 형태로 작성하세요.

- 회사명
- 직무명
- 근무지역
- 마감일
- 사용자 적합도
- 검증 상태
- 공식 공고 링크

지원 가치가 높은 공고를 위쪽에 배치하세요.

[청년지원팀]

다음 내용을 표 형태로 작성하세요.

- 정책명
- 지역
- 현재 신청 가능 여부
- 서울 이직·전입 시 가능 여부
- 신청 마감일
- 검증 상태
- 공식 링크

[경제연구팀]

핵심 수치와 변화를 카드 형태로 표시하세요.

- 지표명
- 현재 수치
- 이전 수치
- 변화 방향
- 사용자에게 미치는 의미
- 출처

경제 수치가 없거나 비교할 수 없으면 차트를 억지로 만들지 마세요.

[학습팀]

다음 내용을 표시하세요.

- 오늘의 파닉스 규칙
- 전기·엔지니어링 영어 단어
- 전기 학습 주제
- Python·AI 자동화 주제
- 오늘 완료할 학습 순서

항공·항공정비·항공공학 내용을 포함하지 마세요.

[검증 경고]

오류, 404 링크, 출처 불일치, 자격조건 불명확 등의 문제를 눈에 잘 띄게 표시하세요.

[원본 파일 바로가기]

다음 상대경로를 사용하여 원본 보고서 링크를 제공하세요.

- ../recruitment/$today.md
- ../economy/$today.md
- ../learning/$today.md
- 해당 주의 가장 최근 youth-support 보고서
- ./$today.md

디자인은 화려함보다 가독성과 정확성을 우선하세요.
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
