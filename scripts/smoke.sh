#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://localhost:8080/api/v1}" 
echo "[smoke] Using API base: $API_BASE"

fail(){ echo "[FAIL] $*" >&2; exit 1; }
pass(){ echo "[PASS] $*"; }

echo "[smoke] Health check..."
curl -sf "$API_BASE/health" >/dev/null || fail "Health endpoint not reachable"
pass "Health endpoint reachable"

echo "[smoke] Attempting login with johndoe (password=password123)..."
LOGIN_PAYLOAD='{"username":"johndoe","password":"password123"}'
LOGIN_RESPONSE=$(curl -s -w '\n%{http_code}' -H 'Content-Type: application/json' -d "$LOGIN_PAYLOAD" "$API_BASE/auth/login" || true)
LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | head -n1)
LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)

if [ "$LOGIN_CODE" != "200" ]; then
  fail "Login failed (HTTP $LOGIN_CODE): $LOGIN_BODY"
fi

TOKEN=$(echo "$LOGIN_BODY" | grep -Eo '"token"\s*:\s*"[^"]+"' | cut -d '"' -f4 || true)
if [ -z "$TOKEN" ]; then
  fail "Token not found in login response: $LOGIN_BODY"
fi
pass "Login succeeded & token extracted"

echo "[smoke] Calling protected endpoint with token..."
PROTECTED_CODE=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "$API_BASE/auth/me" || true)
if [ "$PROTECTED_CODE" = "200" ]; then
  pass "Protected endpoint accessible"
else
  fail "Protected endpoint failed (HTTP $PROTECTED_CODE)"
fi

echo "[smoke] Done. All checks passed."