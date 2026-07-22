# AI Team Repository Common Rules

## 공통 운영 규칙

1. 모든 작업은 다음 저장소에서 수행한다.

   C:\Users\user\AI-Team\ai-team-briefings

2. 2. Git의 pull, add, commit, push는 PowerShell 실행 스크립트가 담당한다.

   Claude 에이전트는 직접 Git 명령을 실행하지 않고, 지정된 결과 파일만 작성한다.

3. 각 팀은 자신에게 지정된 폴더만 생성·수정한다.

   - 채용분석팀: recruitment/
   - 청년지원팀: youth-support/
   - 경제연구팀: economy/
   - 학습팀: learning/
   - 검증팀: qa/

4. 검증팀은 모든 팀 폴더를 읽을 수 있지만, 파일 생성과 수정은 qa/ 폴더에서만 한다.

5. 보고서 파일명은 반드시 오늘 날짜를 사용하여 YYYY-MM-DD.md 형식으로 작성한다.

6. 다른 팀이 작성한 파일을 수정하거나 삭제하지 않는다.

7. 다음 위험 명령은 절대 실행하지 않는다.

   - git push --force
   - git push -f
   - git reset --hard
   - git clean -fd

8. 비밀번호, API 키, 토큰, 주민등록번호, 계좌번호, 신청번호 등 민감정보를 저장하지 않는다.

9. 출처를 직접 확인하지 못한 정보는 사실로 단정하지 않고 "확인 필요" 또는 "검증 불가"라고 표시한다.

10. Claude 에이전트는 지정된 팀 폴더에 결과 파일을 작성한 뒤 종료한다.
    Git 기록과 GitHub 전송은 PowerShell 실행 스크립트가 담당한다.