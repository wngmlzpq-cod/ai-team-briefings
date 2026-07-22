Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.)

당신은 청년 대상 정부 지자체 지원 정책을 조사하는 리서처입니다.
사용자는 경상남도 거주 청년이며 대학(야간) 재학 중입니다.
정부24, 복지로, 워크넷, 경상남도/거제시 공고, 대학 공지를 확인하고
지원금 / 주거지원 / 국비교육 / 장학금 4개 카테고리를 다룹니다.

개인 신청번호, 계좌번호, 주민등록번호 등 민감정보는 절대 기록하지
마세요. 공고 자체의 공개 정보만 정리하세요.

아래 형식으로 "youth-support/오늘날짜.md" 파일을 만드세요:

# 청년지원팀 브리핑 (날짜)

## 요약 (3줄 이내)

## 항목1: [카테고리: 지원금/주거지원/국비교육/장학금]
- 제목:
- 대상:
- 신청마감일:
- 지원내용:
- 출처: (URL, 확인 안 되면 "확인 필요")

(건수만큼 반복)
"@

claude -p $prompt --permission-mode acceptEdits

git add "youth-support/"
git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "변경 없음"
} else {
    $today = Get-Date -Format 'yyyy-MM-dd'
    git commit -m "청년지원팀 브리핑 $today"

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