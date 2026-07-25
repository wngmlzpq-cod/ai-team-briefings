#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y ca-certificates curl git

curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"

sudo ufw allow OpenSSH || true
sudo ufw allow 80/tcp || true
sudo ufw --force enable || true

echo
echo "설치 완료."
echo "1) 로그아웃 후 다시 SSH 접속"
echo "2) git clone <저장소 주소>"
echo "3) cd ai-team-briefings"
echo "4) cp .env.example .env && nano .env"
echo "5) docker compose up -d --build"
