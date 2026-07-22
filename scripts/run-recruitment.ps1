Set-Location "C:\Users\user\AI-Team\ai-team-briefings"
git pull --rebase origin main

$today = Get-Date -Format 'yyyy-MM-dd'

$prompt = @"
(저장소 루트의 CLAUDE.md 공통 규칙을 따르세요.)

당신은 전기·전자·산업·조선해양 분야의 엔지니어 채용을 분석하는 전문 리서처입니다.

사용자는 전기차 충전시설 설계·시공관리 경력과 선박 시운전, 선박 성능 모니터링
시스템(HS4 SPMS), SFOC 계산 및 데이터 연동 업무 경험이 있으며,
현재 전기공학과 야간 과정에 재학 중입니다.

다음 직무를 우선순위로 검색하세요.

1. 전기설계, 전장설계, 제어설계, 자동화, 계장 엔지니어
2. 선박·조선·해양·플랜트 분야 전기·전자 엔지니어
3. 선박 시운전, 커미셔닝, 서비스 엔지니어, 필드 서비스 엔지니어
4. 선박엔진, 성능 모니터링, 에너지 효율, 데이터 분석 관련 엔지니어
5. 전기차 충전시설 설계, 시공관리, 기술지원 관련 직무
6. 외국계 기업의 주니어 또는 경력 전환이 가능한 엔지니어 직무

사람인, 잡코리아, 원티드, 링크드인, 기업 채용 홈페이지와 해외·외국계 채용정보를
확인하고, 최근 24시간 이내 신규 공고와 현재 지원 가능한 공고를 우선 조사하세요.

[검색 기간 확장 원칙]

최근 24시간 이내 신규 공고를 최우선으로 검색하되,
최근 30일 이내 등록된 현재 지원 가능한 공고도 반드시 함께 확인하세요.

검색 결과를 다음 두 항목으로 구분하세요.

1. 최근 24시간 이내 신규 공고
2. 최근 30일 이내 등록된 현재 지원 가능한 주요 공고

최근 24시간 이내 공고가 아니라는 이유만으로
현재 지원 가능한 우수 공고를 제외하지 마세요.

직무명에 '엔지니어', '전기', '전장', '설계', '시운전', '커미셔닝',
'서비스 엔지니어', '필드 서비스', '자동화', '제어', '계장',
'조선', '선박', '해양', '플랜트'가 포함된 공고를 중점적으로 확인하세요.

단순 생산직, 단순 조립직, 영업 중심 직무, 사용자 경력과 연관성이 낮은
IT 개발자 직무는 제외하세요.

[추가 필수 검색 직무]

Engineer뿐만 아니라 다음 Technician 직무도 반드시 검색하세요.

- Field Service Technician
- Electrical Technician
- Electrical/I&C Technician
- I&C Technician
- Instrumentation & Control Technician
- Commissioning Technician
- Service Technician
- Turbine Technician

Technician이라는 명칭만으로 단순 생산직 또는 단순 조립직으로 판단하지 마세요.
전기, 계장, 제어, 시운전, 발전설비, 터빈, 선박 및 산업설비와 관련된
현장 기술직은 사용자의 엔지니어 경력과 연결되는 직무로 평가하세요.

[필수 검색 채널 및 우선순위]

LinkedIn Jobs를 반드시 별도 검색하세요. 다른 사이트 검색만으로 작업을 끝내지 마세요.

LinkedIn에서는 다음 직무명을 한국어와 영어로 각각 검색하세요.

- Electrical Engineer / 전기 엔지니어
- Electrical Design Engineer / 전기설계 엔지니어
- Electrical & Instrumentation Engineer / 전기·계장 엔지니어
- Automation Engineer / 자동화 엔지니어
- Control Engineer / 제어 엔지니어
- Commissioning Engineer / 시운전·커미셔닝 엔지니어
- Field Service Engineer / 필드 서비스 엔지니어
- Marine Engineer / 선박 엔지니어
- Marine Electrical Engineer / 선박 전기 엔지니어
- Shipbuilding Engineer / 조선 엔지니어
- Performance Engineer / 성능 엔지니어
- Energy Efficiency Engineer / 에너지 효율 엔지니어
- Technical Support Engineer / 기술지원 엔지니어

검색 지역은 대한민국 전체를 대상으로 하되 다음 지역을 우선 확인하세요.

- 부산
- 경남
- 거제
- 창원
- 울산
- 서울·경기
- 해외 또는 외국계 기업의 한국 근무 직무

WebSearch에서는 다음과 같은 LinkedIn 전용 검색도 반드시 수행하세요.

site:linkedin.com/jobs/view "Electrical Engineer" Korea
site:linkedin.com/jobs/view "Commissioning Engineer" Korea
site:linkedin.com/jobs/view "Field Service Engineer" Korea
site:linkedin.com/jobs/view "Marine Engineer" Korea
site:linkedin.com/jobs/view "Marine Electrical Engineer" Korea
site:linkedin.com/jobs/view "Shipbuilding Engineer" Korea
site:linkedin.com/jobs/view "Performance Engineer" Korea
site:linkedin.com/jobs/view "전기 엔지니어" 대한민국
site:linkedin.com/jobs/view "시운전 엔지니어" 대한민국

LinkedIn에서 찾은 공고는 반드시 다음 항목을 확인하세요.

- 회사명
- 정확한 직무명
- 근무지역
- 게시일 또는 등록 시점
- 지원 마감일
- 경력 요구조건
- 영어 요구 수준
- LinkedIn 공고 URL
- 회사 공식 채용 페이지 URL
- 현재 지원 가능 여부

LinkedIn 페이지가 로그인이나 자바스크립트 문제로 열리지 않을 경우에는
확인하지 못한 정보를 추정하거나 만들어내지 마세요.

그 경우 다음 순서로 재확인하세요.

1. 회사 공식 채용 홈페이지
2. 회사명과 직무명을 이용한 별도 웹 검색
3. 잡코리아·사람인·원티드 등 다른 채용 플랫폼
4. 확인할 수 없으면 "LinkedIn 검색 결과에서 발견했으나 상세 검증 필요"라고 표시

LinkedIn에서 현재 지원 가능한 유효 공고가 있으면 최소 3건을 우선 정리하세요.
유효한 공고가 없으면 억지로 채우지 말고
"LinkedIn에서 현재 검증 가능한 신규 공고 없음"이라고 명확하게 기록하세요.

[사용자 적합도 평가]

다음 경험과 연결되는 공고를 높은 적합도로 평가하세요.

- 전기차 충전시설 설계 및 시공관리 경력
- 선박 시운전 및 커미셔닝 경험
- 선박 성능 모니터링 시스템 HS4 SPMS 경험
- SFOC 및 선박 성능지표 계산 경험
- VDR, IAS, CAMS 등 선박 시스템 데이터 연동 경험
- Python, 데이터 분석, 성능 계산 로직 경험
- 전기공학과 야간 재학
- 외국계 선박엔진·전기 엔지니어로의 경력 확장 가능성

단순 생산직, 단순 조립직, 영업 중심 직무 및 관련 없는 소프트웨어 개발직은 제외하세요.

[관심기업 필수 확인]

매 실행 시 지멘스에너지와 Siemens Energy 공식 채용 페이지를 반드시 검색하세요.

다음 검색어를 각각 수행하세요.

site:saramin.co.kr/zf_user/jobs/relay/view "지멘스에너지"
site:saramin.co.kr "지멘스에너지" "Field Service"
site:saramin.co.kr "Electrical/I&C"
site:jobs.siemens-energy.com Korea "Field Service"
site:jobs.siemens-energy.com Korea "Electrical"
site:jobs.siemens-energy.com "Field Service Technician for Electrical/I&C"

사람인에서 발견한 지멘스에너지 공고는
지멘스에너지 공식 채용 페이지에서도 현재 지원 가능 여부를 재확인하세요.

[자동 실행 원칙]

- 이 작업은 사용자가 지켜보지 않는 비대화형 자동 실행입니다.
- 사용자에게 질문하거나 선택지를 제시하지 말고, 끝까지 스스로 완료하세요.
- 실행할 때마다 반드시 웹 검색을 새로 수행하세요.
- "recruitment/$today.md" 파일이 이미 존재하더라도 작업을 중단하지 마세요.
- 기존 파일을 읽은 뒤 최신 검색 결과로 전체 내용을 갱신하여 덮어쓰세요.
- 기존 공고의 모집 상태, 마감일, 출처 URL도 다시 확인하세요.
- 중복 공고는 제거하세요.
- 신규 공고가 없더라도 파일을 갱신하고 "최근 24시간 신규 공고 없음"이라고 기록하세요.
- 확인되지 않은 사실은 만들지 말고 "확인 필요"라고 표시하세요.
- 작업 완료 후 사용자에게 질문하지 말고 파일 저장까지 완료하세요.

아래 형식으로 "recruitment/$today.md" 파일을 새로 작성하거나 기존 파일을 갱신하세요:

# 채용분석팀 브리핑 $today

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
- 출처 플랫폼: (LinkedIn/사람인/잡코리아/원티드/기업 홈페이지)
- 게시일:
- LinkedIn URL: (해당 없으면 "해당없음")
- 공식 채용 URL: (확인되지 않으면 "확인 필요")
- 현재 지원 가능 여부: 지원 가능 / 마감 / 확인 필요
- 사용자 적합도: 높음 / 보통 / 낮음
- 적합도 근거:

(공고 수만큼 항목 반복)
"@

claude --permission-mode dontAsk --allowedTools "Read,Write,Edit,Glob,Grep,WebSearch,WebFetch" -p $prompt

git add "recruitment/"
git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "변경 없음"
} else {
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