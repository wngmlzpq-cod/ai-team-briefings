$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$python = Join-Path $repoRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $python)) {
    throw "Python virtual environment not found: $python"
}

$env:PYTHONPATH = Join-Path $repoRoot "src"

Push-Location $repoRoot
try {
    & $python -m ai_team.build
}
finally {
    Pop-Location
}
