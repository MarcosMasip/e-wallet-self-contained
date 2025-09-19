Param(
    [switch]$Rebuild
)

function Write-Info($msg) { Write-Host "[e-wallet] $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERR] $msg" -ForegroundColor Red }

Write-Info "Checking prerequisites..."
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Write-Err "Docker is required"; exit 1 }

# Determine compose command
$composeCmd = "docker compose"
try { docker compose version | Out-Null } catch {
  if (Get-Command docker-compose -ErrorAction SilentlyContinue) { $composeCmd = "docker-compose" } else { Write-Err "docker compose not found"; exit 1 }
}

if (-not (Test-Path .env)) {
  Copy-Item .env.example .env
  Write-Ok ".env created"
}

# Generate jwt_secret if empty
$envContent = Get-Content .env
if ($envContent -match '^jwt_secret=$') {
  $secret = [guid]::NewGuid().ToString("N") + [guid]::NewGuid().ToString("N")
  (Get-Content .env) -replace '^jwt_secret=.*', "jwt_secret=$secret" | Set-Content .env
  Write-Ok "Generated jwt_secret"
}

Write-Info "Building images..."
if ($Rebuild) { & $composeCmd -f docker-compose.local.yml build --no-cache } else { & $composeCmd -f docker-compose.local.yml build }

Write-Info "Starting services..."
& $composeCmd -f docker-compose.local.yml up -d

Write-Info "Waiting for backend health (timeout ~120s)..."
$attempts = 60
while ($attempts -gt 0) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing http://localhost:8080/actuator/health -TimeoutSec 3
    if ($resp.StatusCode -eq 200) { Write-Ok "Backend healthy"; break }
  } catch { }
  Start-Sleep -s 2
  $attempts--
}
if ($attempts -eq 0) { Write-Warn "Backend not confirmed healthy; continuing" }

Write-Info "Checking frontend..."
try { Invoke-WebRequest -UseBasicParsing http://localhost:3000 -TimeoutSec 3 | Out-Null; Write-Ok "Frontend reachable" } catch { Write-Warn "Frontend not responding yet" }

Write-Host @"
============================================================
 e-wallet stack is up!
------------------------------------------------------------
Frontend: http://localhost:3000
Backend API: http://localhost:8080/swagger-ui.html (if enabled)
Health: http://localhost:8080/actuator/health

Demo Users (from migrations):
  johndoe / (preset bcrypt hash password) - actual plaintext password TBD
  lindacalvin / (same) 
  jeffreytaylor / (same)

Use: $composeCmd -f docker-compose.local.yml logs -f backend  to view logs.
============================================================
"@

exit 0