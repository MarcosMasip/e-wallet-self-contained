#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
log(){ echo -e "${BLUE}[native]${NC} $*"; }
ok(){ echo -e "${GREEN}[OK]${NC} $*"; }
err(){ echo -e "${RED}[ERR]${NC} $*" >&2; }

if [[ ! -f .env ]]; then
  cp .env.example .env
fi

if grep -q '^jwt_secret=$' .env; then
  NEW_SECRET=$(openssl rand -hex 16 2>/dev/null || uuidgen | tr -d '-')
  sed -i.bak "s/^jwt_secret=.*/jwt_secret=${NEW_SECRET}/" .env && rm -f .env.bak
fi

# Export variables from .env safely (ignore lines without '=')
set +u
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  export "$key"="${value}"
done < .env
set -u

log "Starting backend (H2 profile)..."
BACKEND_PORT="${BACKEND_PORT:-8080}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"

# Free ports if occupied
for P in "$BACKEND_PORT" "$FRONTEND_PORT"; do
  if lsof -ti tcp:$P >/dev/null 2>&1; then
    log "Port $P in use; terminating process(es)..."
    lsof -ti tcp:$P | xargs kill -9 2>/dev/null || true
    sleep 1
  fi
done
pushd backend >/dev/null
# Ensure mvnw is executable or run via bash
if [[ ! -x ./mvnw ]]; then
  chmod +x ./mvnw 2>/dev/null || true
fi
./mvnw -q -DskipTests dependency:go-offline || true
SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-Dspring.profiles.active=h2 -Dserver.port=$BACKEND_PORT" &
BACKEND_PID=$!
popd >/dev/null

# Wait for backend health
ATTEMPTS=40
until curl -sf http://localhost:$BACKEND_PORT/api/v1/health >/dev/null 2>&1 || (( ATTEMPTS==0 )); do
  sleep 1; ((ATTEMPTS--));
done
if (( ATTEMPTS==0 )); then
  err "Backend failed to become healthy in time"
fi

log "Installing frontend deps if needed..."
if [[ ! -d frontend/node_modules ]]; then
  (cd frontend && yarn install --silent)
fi

log "Starting frontend dev server..."
(
  cd frontend
  export PORT=$FRONTEND_PORT
  export REACT_APP_API_BASE_URL="http://localhost:$BACKEND_PORT/api/v1"
  yarn start --silent
) &
FRONTEND_PID=$!

trap 'echo; log "Stopping..."; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true' INT TERM

ok "Backend PID: $BACKEND_PID (:$BACKEND_PORT) | Frontend PID: $FRONTEND_PID (:$FRONTEND_PORT)"
echo -e "${GREEN}Open http://localhost:$FRONTEND_PORT${NC}"

if [[ -f scripts/smoke.sh ]]; then
  bash scripts/smoke.sh || true
fi

wait $BACKEND_PID
wait $FRONTEND_PID