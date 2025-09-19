#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://localhost:8080/api/v1}" 
echo "[smoke] Using API base: $API_BASE"

fail(){ echo "[FAIL] $*" >&2; exit 1; }
pass(){ echo "[PASS] $*"; }

echo "[smoke] Health check..."
curl -sf "$API_BASE/health" >/dev/null || fail "Health endpoint not reachable"
pass "Health endpoint reachable"

echo "[smoke] Attempting login with johndoe (may fail if password unknown)..."
LOGIN_PAYLOAD='{"username":"johndoe","password":"123456"}'
if curl -s -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -d "$LOGIN_PAYLOAD" "$API_BASE/auth/login" | grep -qE '200|401'; then
  pass "Login endpoint responsive"
else
  fail "Login endpoint not responsive"
fi

echo "[smoke] Done."