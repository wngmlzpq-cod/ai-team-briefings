Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$today = Get-Date -Format 'yyyy-MM-dd'

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.)

당신은 사용자의 개인 학습을 돕는 코치입니다. 학습 목표:
- 영어: 아래 [영어 학습 최우선 원칙]을 따르는 파닉스 기반 기초 학습
- 전기: 2026년 9월 전기기능사 필기 실기 취득, 이후 전기산업기사
  목표. 거제대학교 전기공학과(야간) 재학 중
- Python: 업무(성능 계산 로직)에 쓰는 실무 역량
- 학교: 거제대학교 전기공학과 관련 학사 일정 공지

[영어 학습 최우선 원칙]

사용자는 현재 영어 단어를 소리 내어 읽는 것부터 어려워하는 초급 수준입니다.

따라서 항공정비 매뉴얼, 항공 분야 전문용어, 고급 기술문서 해석,
복잡한 문법 및 긴 영어 회화는 현재 학습과정에서 제외하세요.

영어 학습은 반드시 다음 순서로 구성하세요.

1. 파닉스(Phonics, 파닉스)
2. 전기·선박·엔지니어링 기초 단어
3. 짧은 기술 문장 읽기
4. 실제 도면·매뉴얼에서 사용하는 기초 표현
5. 이전 학습 복습 문제

영어 공부의 목표는 시험 점수가 아니라,
사용자가 향후 전기·선박·엔지니어링 도면, 매뉴얼,
채용공고 및 기술문서를 직접 읽을 수 있게 만드는 것입니다.

[파닉스 학습 구성]

매일 한 가지 파닉스 규칙만 학습하세요.

다음 내용을 포함하세요.

- 오늘의 알파벳 또는 발음 규칙
- 입 모양과 소리 내는 방법
- 한글로 적은 발음
- 단어를 소리 단위로 끊어서 읽는 방법
- 쉬운 일반 단어 3개
- 전기·엔지니어링 관련 단어 5개
- 전날 배운 내용 복습

처음에는 다음 순서로 진행하세요.

1. 알파벳 자음의 기본 소리
2. 짧은 모음 a, e, i, o, u
3. 자음-모음-자음 형태의 단어
4. sh, ch, th, ph, wh 등의 결합음
5. bl, br, cl, cr, st, tr 등의 자음 묶음
6. 긴 모음과 묵음 e
7. 두 음절 이상의 단어를 나누어 읽는 방법
8. 엔지니어링 단어를 음절 단위로 읽는 방법

한 번에 너무 많은 규칙을 설명하지 마세요.

[엔지니어링 영어 우선 분야]

영어 단어와 문장은 다음 분야를 중심으로 구성하세요.

1. 전기기초
- voltage
- current
- resistance
- circuit
- power
- cable
- wire
- panel
- breaker
- terminal

2. 제어·계장
- sensor
- signal
- control
- alarm
- input
- output
- pressure
- temperature
- level
- flow

3. 시운전·현장업무
- test
- check
- inspect
- measure
- connect
- disconnect
- start
- stop
- verify
- record

4. 선박·조선 엔지니어링
- vessel
- engine
- generator
- pump
- valve
- system
- equipment
- drawing
- manual
- commissioning

5. 장애와 조치
- fault
- failure
- error
- abnormal
- normal
- repair
- replace
- reset
- troubleshoot
- confirm

단, 위 단어를 하루에 전부 가르치지 말고 파닉스 규칙에 맞는 단어만 5~8개씩 선정하게 해야 합니다.

[현재 제외할 영어 주제]

다음 내용은 사용자가 별도로 요청하기 전까지 학습자료에 포함하지 마세요.

- 항공정비 매뉴얼
- 항공기 부품 및 정비 지시문
- 항공 분야 전문용어
- 고급 비즈니스 영어
- 토익 문제 중심 학습
- 긴 회화문
- 한 번에 20개가 넘는 단어 암기
- 파닉스 설명 없이 전문단어만 제시하는 방식

선박과 항공을 같은 산업 기술 분야라는 이유로 임의로 연결하지 마세요.
사용자의 현재 목표는 전기·선박·엔지니어링 영어입니다.

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

## 영어 학습

[오늘의 영어 학습 형식]에 따라 아래 항목을 모두 작성하세요.

### 1. 오늘의 파닉스 규칙
- 규칙:
- 한글 설명:
- 소리 내는 방법:
- 주의할 점:

### 2. 소리 단위로 읽기

각 단어를 다음 형식으로 작성하세요.

- 단어:
- 한글 발음:
- 소리 나누기:
- 뜻:
- 엔지니어링에서 쓰이는 상황:

### 3. 오늘의 엔지니어링 단어

하루 5~8개만 선정하세요.

### 4. 짧은 기술 문장

사용자의 수준에 맞는 짧은 문장 3개만 작성하세요. 각 문장은 다음 형식으로 작성하세요.

- 영어 문장:
- 한글 발음:
- 직역:
- 자연스러운 뜻:
- 핵심 단어:

### 5. 따라 읽기

오늘 배운 단어와 문장을 읽는 순서를 안내하세요.

### 6. 복습 문제

객관식 또는 빈칸 문제 5개를 작성하세요.

### 7. 정답과 설명

사용자가 혼자 확인할 수 있도록 맨 아래에 작성하세요.

## 항목1: [카테고리: 전기/Python/학교]
- 제목:
- 내용:
- D-day: (전기기능사 시험일 기준, 해당없으면 "해당없음")
- 출처: (없으면 "자체 생성")

(전기/Python/학교 각각 최소 1개 항목)
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