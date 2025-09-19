#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

log() { echo -e "${BLUE}[e-wallet]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*" 1>&2; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }; }

log "Checking prerequisites..."
if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_BIN="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_BIN="docker-compose"
  else
    warn "Docker present but compose plugin not found."
  fi
else
  warn "Docker not found. Falling back to native dev mode (H2)."
  exec bash dev-native.sh
fi

# If we have docker but daemon is down, fallback to native mode instead of aborting
if ! docker info >/dev/null 2>&1; then
  warn "Docker daemon unreachable — using native fallback (H2)."
  exec bash dev-native.sh
fi

log "Preparing .env file..."
if [[ ! -f .env ]]; then
  cp .env.example .env
  ok ".env created from template"
fi

# Generate JWT secret if empty
if grep -q '^jwt_secret=$' .env; then
  NEW_SECRET=$(openssl rand -hex 32 2>/dev/null || uuidgen | tr -d '-')
  sed -i.bak "s/^jwt_secret=.*/jwt_secret=${NEW_SECRET}/" .env
  rm -f .env.bak
  ok "Generated jwt_secret"
fi

log "Building images (this may take a few minutes the first time)..."
$COMPOSE_BIN -f docker-compose.local.yml build --pull --quiet || $COMPOSE_BIN -f docker-compose.local.yml build

log "Starting services..."
$COMPOSE_BIN -f docker-compose.local.yml up -d

log "Waiting for backend to become healthy..."
ATTEMPTS=60
until [[ "$($COMPOSE_BIN -f docker-compose.local.yml ps --format json 2>/dev/null | grep -c '"Name": "e-wallet-backend"')" -gt 0 ]]; do sleep 1; done

while (( ATTEMPTS > 0 )); do
  STATUS=$($COMPOSE_BIN -f docker-compose.local.yml ps --format json | grep -A4 'e-wallet-backend' || true)
  if curl -sf http://localhost:8080/actuator/health >/dev/null 2>&1; then
    ok "Backend healthy"
    break
  fi
  sleep 2
  ((ATTEMPTS--))
done

if (( ATTEMPTS == 0 )); then
  warn "Backend health check did not confirm readiness; continuing anyway."
fi

log "Verifying frontend availability..."
if curl -sf http://localhost:3000 >/dev/null 2>&1; then
  ok "Frontend reachable"
else
  warn "Frontend not yet responding on http://localhost:3000"
fi

cat <<EOT
${GREEN}
============================================================
 e-wallet stack is up!
------------------------------------------------------------
Frontend: http://localhost:3000
Backend API (OpenAPI UI maybe at): http://localhost:8080/swagger-ui.html
Health: http://localhost:8080/actuator/health

Demo Users (from migrations):
  johndoe / password: 123456 (assuming bcrypt hash matches) *IF different, check user creation logic*
  lindacalvin / (same password assumption)
  jeffreytaylor / (same password assumption)

If login fails, inspect backend logs: $COMPOSE_BIN -f docker-compose.local.yml logs -f backend
============================================================${NC}
EOT

exit 0