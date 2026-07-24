param(
    [string]$HtmlPath = "",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-EdgePath {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
    )

    foreach ($path in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path)) {
            return (Resolve-Path $path).Path
        }
    }

    $searchRoots = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application",
        "$env:ProgramFiles\Microsoft\Edge\Application"
    )

    foreach ($root in $searchRoots) {
        if (Test-Path $root) {
            $found = Get-ChildItem $root -Recurse -Filter msedge.exe -ErrorAction SilentlyContinue |
                Sort-Object FullName |
                Select-Object -First 1

            if ($found) {
                return $found.FullName
            }
        }
    }

    throw "Microsoft Edge 실행 파일을 찾지 못했습니다."
}

if ([string]::IsNullOrWhiteSpace($HtmlPath)) {
    $latest = Get-ChildItem (Join-Path $repoRoot "qa\dashboard-*.html") |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latest) {
        throw "qa 폴더에서 dashboard-*.html 파일을 찾지 못했습니다."
    }

    $HtmlPath = $latest.FullName
}
elseif (-not [System.IO.Path]::IsPathRooted($HtmlPath)) {
    $HtmlPath = Join-Path $repoRoot $HtmlPath
}

if (-not (Test-Path $HtmlPath)) {
    throw "HTML 파일이 없습니다: $HtmlPath"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $baseName = [IO.Path]::GetFileNameWithoutExtension($HtmlPath)
    $OutputPath = Join-Path (Split-Path -Parent $HtmlPath) ($baseName + ".png")
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$edge = Resolve-EdgePath
$htmlFullPath = (Resolve-Path $HtmlPath).Path
$fileUri = [System.Uri]::new($htmlFullPath).AbsoluteUri

Write-Host "Edge  : $edge"
Write-Host "HTML  : $HtmlPath"
Write-Host "PNG   : $OutputPath"

$arguments = @(
    "--headless=new"
    "--disable-gpu"
    "--hide-scrollbars"
    "--force-device-scale-factor=1"
    "--window-size=1080,1920"
    "--screenshot=$OutputPath"
    $fileUri
)

$process = Start-Process `
    -FilePath $edge `
    -ArgumentList $arguments `
    -NoNewWindow `
    -Wait `
    -PassThru

if ($process.ExitCode -ne 0) {
    throw "Edge PNG 변환 실패. ExitCode: $($process.ExitCode)"
}

if (-not (Test-Path $OutputPath)) {
    throw "PNG 파일이 생성되지 않았습니다: $OutputPath"
}

Write-Host ""
Write-Host "=== Dashboard PNG created ===" -ForegroundColor Green
Write-Host "Input : $HtmlPath"
Write-Host "Output: $OutputPath"
Write-Host ""
