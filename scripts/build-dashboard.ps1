param(
    [string]$QaPath = "",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

function HtmlEncode([string]$Text) {
    if ($null -eq $Text) { return "" }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Get-Section([string]$Content, [string]$Heading) {
    $escaped = [regex]::Escape($Heading)
    $pattern = "(?ms)^##\s+$escaped\s*\r?\n(.*?)(?=^##\s+|\z)"
    $m = [regex]::Match($Content, $pattern)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ""
}

function First-Match([string]$Text, [string]$Pattern, [string]$Default = "-") {
    $m = [regex]::Match($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $Default
}

function Shorten([string]$Text, [int]$Max = 110) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return "-" }
    $clean = ($Text -replace '\s+', ' ').Trim()
    if ($clean.Length -le $Max) { return $clean }
    return $clean.Substring(0, $Max - 1) + "…"
}

if ([string]::IsNullOrWhiteSpace($QaPath)) {
    $latest = Get-ChildItem (Join-Path $repoRoot "qa\*.md") |
        Where-Object { $_.Name -notmatch '-initial\.md$' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latest) {
        throw "qa 폴더에서 최종 QA Markdown 파일을 찾지 못했습니다."
    }
    $QaPath = $latest.FullName
}
elseif (-not [System.IO.Path]::IsPathRooted($QaPath)) {
    $QaPath = Join-Path $repoRoot $QaPath
}

if (-not (Test-Path $QaPath)) {
    throw "QA 파일이 없습니다: $QaPath"
}

$content = Get-Content $QaPath -Raw -Encoding UTF8
$date = First-Match $content '^#\s+QA 검증 리포트\s+(\d{4}-\d{2}-\d{2})' ([IO.Path]::GetFileNameWithoutExtension($QaPath))

$summary = Get-Section $content "전체 요약"
$repairSection = Get-Section $content "자동 재작업 기록"
$finalSection = Get-Section $content "최종 판정"

$overall = First-Match $summary '최종 판정:\s*([^\r\n]+)' "확인 필요"
$remaining = First-Match $summary '남은 주요 문제:\s*([^\r\n]+)' "기록 없음"

$teamDefs = @(
    @{ Key = "채용"; Title = "채용분석팀"; Emoji = "💼"; Heading = "1. 채용분석팀" },
    @{ Key = "청년지원"; Title = "청년지원팀"; Emoji = "🏠"; Heading = "2. 청년지원팀" },
    @{ Key = "경제"; Title = "경제연구팀"; Emoji = "📈"; Heading = "3. 경제연구팀" },
    @{ Key = "학습"; Title = "학습팀"; Emoji = "📚"; Heading = "4. 학습팀" }
)

$teamCards = ""
$normalCount = 0
$reviewCount = 0

foreach ($t in $teamDefs) {
    $section = Get-Section $content $t.Heading
    $status = First-Match $section '최종 상태:\s*([^\r\n]+)' "확인 필요"
    $check = First-Match $section '확인 필요:\s*([^\r\n]+)' "없음"
    $errorText = First-Match $section '남은 오류:\s*([^\r\n]+)' "없음"

    $isNormal = ($status -match '정상|통과') -and ($errorText -match '^없음')
    if ($isNormal) {
        $badgeClass = "ok"
        $badgeText = "정상"
        $normalCount++
    } else {
        $badgeClass = "warn"
        $badgeText = "확인"
        $reviewCount++
    }

    $teamCards += @"
    <section class="team-card">
      <div class="team-head">
        <div class="team-title">$($t.Emoji) $(HtmlEncode $t.Title)</div>
        <span class="badge $badgeClass">$badgeText</span>
      </div>
      <div class="team-status">$(HtmlEncode (Shorten $status 90))</div>
      <div class="team-note">
        <b>확인 필요</b><br>
        $(HtmlEncode (Shorten $check 150))
      </div>
    </section>
"@
}

$repairLines = [regex]::Matches($repairSection, '(?m)^-\s*SUCCESS:\s*([^\r\n]+)') |
    ForEach-Object { $_.Groups[1].Value.Trim() }
$repairCount = @($repairLines).Count
$repairHtml = if ($repairCount -gt 0) {
    ($repairLines | ForEach-Object { "<li>$(HtmlEncode (Shorten $_ 120))</li>" }) -join "`n"
} else {
    "<li>자동 재작업 없음</li>"
}

$passTeams = First-Match $finalSection '통과:\s*([^\r\n]+)' "없음"
$partialTeams = First-Match $finalSection '부분 통과:\s*([^\r\n]+)' "없음"
$reviewTeams = First-Match $finalSection '재검토 필요:\s*([^\r\n]+)' "없음"

$healthClass = if ($overall -match '통과') { "ok" } elseif ($overall -match '부분') { "warn" } else { "danger" }
$healthText = if ($overall -match '통과') { "PASS" } elseif ($overall -match '부분') { "PARTIAL" } else { "CHECK" }

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot ("qa\dashboard-{0}.html" -f $date)
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$html = @"
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=1080, initial-scale=1">
<title>AI-Team QA Dashboard $date</title>
<style>
* { box-sizing: border-box; }
html, body { margin: 0; width: 1080px; height: 1920px; overflow: hidden; }
body {
  font-family: "Malgun Gothic", "Segoe UI", sans-serif;
  background: #f3f5f7;
  color: #14171a;
}
.dashboard {
  width: 1080px;
  height: 1920px;
  padding: 58px 58px 46px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}
.header {
  background: #111827;
  color: white;
  border-radius: 34px;
  padding: 38px 42px;
}
.header-top { display:flex; justify-content:space-between; align-items:flex-start; gap:24px; }
.kicker { font-size: 24px; opacity:.72; letter-spacing:.06em; }
h1 { margin: 10px 0 8px; font-size: 52px; line-height:1.1; }
.date { font-size: 26px; opacity:.8; }
.health {
  min-width: 164px;
  padding: 18px 20px;
  text-align:center;
  border-radius: 24px;
  font-size: 28px;
  font-weight: 800;
}
.health.ok, .badge.ok { background:#d8f7e4; color:#087a3d; }
.health.warn, .badge.warn { background:#fff1c7; color:#9a6200; }
.health.danger, .badge.danger { background:#ffe0e0; color:#ad1f1f; }
.metrics { display:grid; grid-template-columns: repeat(4, 1fr); gap:16px; }
.metric {
  background:white;
  border-radius:26px;
  padding:24px 22px;
  min-height:128px;
  box-shadow:0 8px 30px rgba(17,24,39,.06);
}
.metric .label { font-size:21px; color:#657080; }
.metric .value { margin-top:12px; font-size:38px; font-weight:800; }
.section-title { font-size:28px; font-weight:800; margin:0 0 14px 4px; }
.team-grid { display:grid; grid-template-columns:1fr 1fr; gap:18px; }
.team-card {
  background:white;
  border-radius:28px;
  padding:24px 26px;
  min-height:236px;
  box-shadow:0 8px 30px rgba(17,24,39,.055);
}
.team-head { display:flex; justify-content:space-between; align-items:center; gap:14px; }
.team-title { font-size:27px; font-weight:800; }
.badge { padding:8px 15px; border-radius:999px; font-size:18px; font-weight:800; }
.team-status { margin-top:19px; font-size:22px; line-height:1.45; font-weight:700; }
.team-note {
  margin-top:16px;
  padding-top:15px;
  border-top:1px solid #e7e9ed;
  font-size:19px;
  line-height:1.45;
  color:#4b5563;
}
.bottom-grid { display:grid; grid-template-columns:1.08fr .92fr; gap:18px; }
.panel {
  background:white;
  border-radius:28px;
  padding:25px 28px;
  min-height:272px;
  box-shadow:0 8px 30px rgba(17,24,39,.055);
}
.panel h2 { margin:0 0 16px; font-size:27px; }
.panel ul { margin:0; padding-left:25px; }
.panel li { font-size:20px; line-height:1.55; margin-bottom:10px; }
.final-row { display:grid; gap:12px; }
.final-item {
  background:#f6f7f9;
  border-radius:18px;
  padding:16px 18px;
  font-size:20px;
  line-height:1.4;
}
.issue {
  background:#fff7e7;
  border:1px solid #f4d08c;
  border-radius:26px;
  padding:22px 28px;
  font-size:21px;
  line-height:1.5;
}
.footer {
  margin-top:auto;
  display:flex;
  justify-content:space-between;
  align-items:center;
  color:#6b7280;
  font-size:18px;
  padding:0 6px;
}
</style>
</head>
<body>
<main class="dashboard">
  <header class="header">
    <div class="header-top">
      <div>
        <div class="kicker">AI-TEAM DAILY QUALITY REPORT</div>
        <h1>QA 세로형 대시보드</h1>
        <div class="date">$date</div>
      </div>
      <div class="health $healthClass">$healthText</div>
    </div>
  </header>

  <section class="metrics">
    <div class="metric"><div class="label">정상 팀</div><div class="value">$normalCount / 4</div></div>
    <div class="metric"><div class="label">자동 수정</div><div class="value">$repairCount 건</div></div>
    <div class="metric"><div class="label">재검토 팀</div><div class="value">$reviewCount 건</div></div>
    <div class="metric"><div class="label">최종 판정</div><div class="value">$healthText</div></div>
  </section>

  <section>
    <h2 class="section-title">팀별 검증 상태</h2>
    <div class="team-grid">
      $teamCards
    </div>
  </section>

  <section class="bottom-grid">
    <div class="panel">
      <h2>🔧 자동 재작업</h2>
      <ul>$repairHtml</ul>
    </div>
    <div class="panel">
      <h2>✅ 최종 판정</h2>
      <div class="final-row">
        <div class="final-item"><b>통과</b><br>$(HtmlEncode (Shorten $passTeams 110))</div>
        <div class="final-item"><b>부분 통과</b><br>$(HtmlEncode (Shorten $partialTeams 110))</div>
        <div class="final-item"><b>재검토</b><br>$(HtmlEncode (Shorten $reviewTeams 110))</div>
      </div>
    </div>
  </section>

  <section class="issue">
    <b>⚠ 남은 주요 확인 사항</b><br>
    $(HtmlEncode (Shorten $remaining 230))
  </section>

  <footer class="footer">
    <span>Generated by AI-Team</span>
    <span>Source: $(HtmlEncode ([IO.Path]::GetFileName($QaPath)))</span>
  </footer>
</main>
</body>
</html>
"@

$folder = Split-Path -Parent $OutputPath
if (-not (Test-Path $folder)) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

Set-Content -Path $OutputPath -Value $html -Encoding UTF8

Write-Host ""
Write-Host "=== QA Dashboard HTML created ===" -ForegroundColor Green
Write-Host "Input : $QaPath"
Write-Host "Output: $OutputPath"
Write-Host ""
