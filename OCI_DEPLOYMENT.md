# J-OS Oracle Cloud 배포

## 목표

- 집·학교·휴대폰·다른 와이파이에서 접속
- Oracle Cloud의 공인 IP로 접속
- 로그인으로 개인 데이터 보호
- 재부팅 후 자동 실행

## 1. OCI 인스턴스 생성

Oracle Cloud Console에서 Compute → Instances → Create instance.

권장:

- Image: Ubuntu 24.04
- Shape: Always Free eligible 표시가 있는 Ampere A1 Flex
- OCPU: 1
- Memory: 6GB
- Public IPv4 address: 할당
- SSH 키: 생성 후 개인키 다운로드

무료 여부는 생성 화면의 **Always Free eligible** 표기를 직접 확인합니다.

## 2. OCI 네트워크 포트

VCN → Security Lists 또는 Network Security Group에서 Ingress Rule 추가:

- Source CIDR: `0.0.0.0/0`
- Protocol: TCP
- Destination port: `80`

SSH 22번은 가능하면 본인 IP로 제한합니다.

## 3. Windows에서 SSH 접속

```powershell
ssh -i C:\키경로\ssh-key.key ubuntu@공인IP
```

키 권한 오류가 나면 Windows 파일 속성에서 본인만 읽을 수 있게 조정합니다.

## 4. 서버 준비

저장소의 `deploy/oci_setup.sh`를 실행합니다.

```bash
chmod +x deploy/oci_setup.sh
./deploy/oci_setup.sh
```

완료 후 SSH에서 로그아웃하고 다시 접속합니다.

## 5. 환경 변수

```bash
cp .env.example .env
nano .env
```

반드시 변경:

- `JOS_USERNAME`
- `JOS_PASSWORD`
- `JOS_SESSION_SECRET`

세션 비밀키 생성:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

## 6. 실행

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
```

## 7. 접속

```text
http://오라클_공인_IP
```

## 8. 업데이트

```bash
git pull
docker compose up -d --build
```

## 9. 데이터 백업

```bash
tar -czf jos-backup-$(date +%F).tar.gz data recruitment youth-support economy learning qa
```

## 보안 주의

공인 인터넷에 개인 재무 데이터를 공개하므로 로그인 비밀번호를 길고 고유하게 설정해야 합니다.
현재 패키지는 HTTP 80 배포입니다. 도메인을 연결하면 Caddy 또는 Nginx와 Let's Encrypt로 HTTPS를 추가하는 것이 다음 단계입니다.
