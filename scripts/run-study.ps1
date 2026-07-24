$ErrorActionPreference = "Stop"

$repoPath = "C:\Users\user\AI-Team\ai-team-briefings"
Set-Location $repoPath

Write-Host "=== Learning Agent Start ==="

git pull --rebase origin main

if ($LASTEXITCODE -ne 0) {
    throw "git pull failed."
}

$today = Get-Date -Format "yyyy-MM-dd"
$outputFile = Join-Path $repoPath "learning\$today.md"

$requiredPromptFiles = @(
    "learning\prompts\agent-profile.md",
    "learning\prompts\why-first-method.md",
    "learning\prompts\learning-template.md"
)

foreach ($relativePath in $requiredPromptFiles) {
    $fullPath = Join-Path $repoPath $relativePath

    if (-not (Test-Path $fullPath)) {
        throw "Required prompt file not found: $relativePath"
    }
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "Claude CLI was not found."
}

$profile = Get-Content `
    (Join-Path $repoPath "learning\prompts\agent-profile.md") `
    -Raw `
    -Encoding UTF8

$whyFirstMethod = Get-Content `
    (Join-Path $repoPath "learning\prompts\why-first-method.md") `
    -Raw `
    -Encoding UTF8

$template = Get-Content `
    (Join-Path $repoPath "learning\prompts\learning-template.md") `
    -Raw `
    -Encoding UTF8

$template = $template.Replace("{{DATE}}", $today)

$executionRules = @"
# Execution Instructions

- Follow the repository root CLAUDE.md.
- Use the agent profile, why-first method, and output template below.
- Complete the task without asking the user questions.
- Read the existing file before updating it when it already exists.
- Create or update only this result file:
  learning/$today.md
- Do not modify prompt files, scripts, CLAUDE.md, or another agent's files.
- Use clear Korean suitable for an adult beginner.
- Do not invent schedules, qualifications, facts, or sources.
- Finish only after the result file has been written successfully.
"@

$prompt = @"
$executionRules

---

$profile

---

$whyFirstMethod

---

$template
"@

Write-Host "Generating: learning/$today.md"

claude `
    --permission-mode dontAsk `
    --allowedTools "Read,Write,Edit,Glob,Grep,WebSearch,WebFetch" `
    -p $prompt

if ($LASTEXITCODE -ne 0) {
    throw "Claude learning agent failed."
}

if (-not (Test-Path $outputFile)) {
    throw "Expected learning report was not created: $outputFile"
}

$fileInfo = Get-Item $outputFile

if ($fileInfo.Length -lt 500) {
    throw "Learning report is unexpectedly small: $($fileInfo.Length) bytes"
}

git add `
    "learning/$today.md" `
    "learning/prompts/" `
    "CLAUDE.md" `
    "scripts/run-study.ps1"

git diff --cached --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "No Git changes."
    exit 0
}

git commit -m "Apply why-first learning method $today"

if ($LASTEXITCODE -ne 0) {
    throw "git commit failed."
}

$pushSucceeded = $false

for ($i = 1; $i -le 5; $i++) {
    git pull --rebase origin main

    if ($LASTEXITCODE -ne 0) {
        Write-Host "git pull retry failed ($i/5)."
        Start-Sleep -Seconds 5
        continue
    }

    git push

    if ($LASTEXITCODE -eq 0) {
        $pushSucceeded = $true
        break
    }

    Write-Host "git push failed. Retrying ($i/5)..."
    Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 25)
}

if (-not $pushSucceeded) {
    throw "git push failed after 5 attempts."
}

Write-Host "=== Learning Agent Complete ==="
Write-Host "Output: learning/$today.md"