$ErrorActionPreference = "Stop"

$repoPath = "C:\Users\user\AI-Team\ai-team-briefings"
$docsPath = Join-Path $repoPath "docs"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Set-Location $repoPath
Add-Type -AssemblyName System.Web

Write-Host "=== AI Team Portal Build Start ==="

$categories = @(
    @{ Name = "Learning"; Source = "learning"; Destination = "learning"; Description = "Daily learning briefings" },
    @{ Name = "Economy"; Source = "economy"; Destination = "economy"; Description = "Economy briefings" },
    @{ Name = "Recruitment"; Source = "recruitment"; Destination = "recruitment"; Description = "Recruitment analysis" },
    @{ Name = "Youth Support"; Source = "youth-support"; Destination = "youth"; Description = "Youth support information" },
    @{ Name = "QA"; Source = "qa"; Destination = "qa"; Description = "Quality assurance reports" }
)

function Convert-InlineMarkdown {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)

    $encoded = [System.Web.HttpUtility]::HtmlEncode($Text)
    $encoded = [regex]::Replace($encoded, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>')
    $encoded = [regex]::Replace($encoded, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    $encoded = [regex]::Replace($encoded, '`([^`]+)`', '<code>$1</code>')
    return $encoded
}

function Convert-MarkdownToHtml {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Markdown)

    $lines = $Markdown -split "`r?`n"
    $output = New-Object System.Collections.Generic.List[string]
    $codeLines = New-Object System.Collections.Generic.List[string]
    $inCodeBlock = $false
    $inUnorderedList = $false
    $inOrderedList = $false

    foreach ($line in $lines) {
        if ($line -match '^```') {
            if (-not $inCodeBlock) {
                if ($inUnorderedList) { $output.Add("</ul>"); $inUnorderedList = $false }
                if ($inOrderedList) { $output.Add("</ol>"); $inOrderedList = $false }
                $inCodeBlock = $true
                $codeLines.Clear()
            }
            else {
                $encodedCode = [System.Web.HttpUtility]::HtmlEncode(($codeLines -join "`n"))
                $output.Add("<pre><code>$encodedCode</code></pre>")
                $inCodeBlock = $false
            }
            continue
        }

        if ($inCodeBlock) { $codeLines.Add($line); continue }

        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($inUnorderedList) { $output.Add("</ul>"); $inUnorderedList = $false }
            if ($inOrderedList) { $output.Add("</ol>"); $inOrderedList = $false }
            continue
        }

        if ($line -match '^\s*---+\s*$') {
            if ($inUnorderedList) { $output.Add("</ul>"); $inUnorderedList = $false }
            if ($inOrderedList) { $output.Add("</ol>"); $inOrderedList = $false }
            $output.Add("<hr>")
            continue
        }

        if ($line -match '^(#{1,6})\s+(.+)$') {
            if ($inUnorderedList) { $output.Add("</ul>"); $inUnorderedList = $false }
            if ($inOrderedList) { $output.Add("</ol>"); $inOrderedList = $false }
            $level = $matches[1].Length
            $content = Convert-InlineMarkdown -Text $matches[2]
            $output.Add("<h$level>$content</h$level>")
            continue
        }

        if ($line -match '^\s*[-*]\s+(.+)$') {
            if ($inOrderedList) { $output.Add("</ol>"); $inOrderedList = $false }
            if (-not $inUnorderedList) { $output.Add("<ul>"); $inUnorderedList = $true }
            $content = Convert-InlineMarkdown -Text $matches[1]
            $output.Add("<li>$content</li>")
            continue
        }

        if ($line -match '^\s*\d+\.\s+(.+)$') {
            if ($inUnorderedList) { $output.Add("</ul>"); $inUnorderedList = $false }
            if (-not $inOrderedList) { $output.Add("<ol>"); $inOrderedList = $true }
            $content = Convert-InlineMarkdown -Text $matches[1]
            $output.Add("<li>$content</li>")
            continue
        }

        if ($inUnorderedList) { $output.Add("</ul>"); $inUnorderedList = $false }
        if ($inOrderedList) { $output.Add("</ol>"); $inOrderedList = $false }

        $paragraph = Convert-InlineMarkdown -Text $line
        $output.Add("<p>$paragraph</p>")
    }

    if ($inCodeBlock) {
        $encodedCode = [System.Web.HttpUtility]::HtmlEncode(($codeLines -join "`n"))
        $output.Add("<pre><code>$encodedCode</code></pre>")
    }
    if ($inUnorderedList) { $output.Add("</ul>") }
    if ($inOrderedList) { $output.Add("</ol>") }

    return ($output -join "`n")
}

function New-ArticleHtml {
    param([string]$Title, [string]$CategoryName, [string]$ArticleBody)

    return @"
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title | AI Team Portal</title>
    <link rel="stylesheet" href="../assets/style.css">
</head>
<body>
<header class="portal-header"><a class="home-link" href="../index.html">AI Team Portal</a></header>
<main class="article-container">
<nav class="breadcrumb"><a href="../index.html">Home</a><span>&rsaquo;</span><a href="index.html">$CategoryName</a><span>&rsaquo;</span><span>$Title</span></nav>
<article class="markdown-body">
$ArticleBody
</article>
</main>
<footer><p>AI Team Portal</p></footer>
</body>
</html>
"@
}

function New-CategoryIndexHtml {
    param([string]$Name, [string]$Description, [array]$Items)

    $itemHtml = New-Object System.Collections.Generic.List[string]
    if ($Items.Count -eq 0) {
        $itemHtml.Add('<div class="empty-state">No reports have been generated yet.</div>')
    }
    else {
        foreach ($item in $Items) {
            $itemHtml.Add(@"
<a class="report-item" href="$($item.FileName)">
    <div><strong>$($item.Title)</strong><p>$Description</p></div>
    <span>Open &rarr;</span>
</a>
"@)
        }
    }

    $reportList = $itemHtml -join "`n"

    return @"
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Name | AI Team Portal</title>
    <link rel="stylesheet" href="../assets/style.css">
</head>
<body>
<header><a class="home-link" href="../index.html">AI Team Portal</a><h1>$Name</h1><p>$Description</p></header>
<main class="report-list">
$reportList
</main>
<footer><p>AI Team Portal</p></footer>
</body>
</html>
"@
}

$totalReports = 0

foreach ($category in $categories) {
    $sourcePath = Join-Path $repoPath $category.Source
    $destinationPath = Join-Path $docsPath $category.Destination
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null

    $reportItems = New-Object System.Collections.Generic.List[object]
    $markdownFiles = @(
        Get-ChildItem -Path $sourcePath -Filter "*.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -match '^\d{4}-\d{2}-\d{2}$' } |
        Sort-Object Name -Descending
    )

    foreach ($markdownFile in $markdownFiles) {
        $markdown = Get-Content -Path $markdownFile.FullName -Raw -Encoding UTF8
        $articleBody = Convert-MarkdownToHtml -Markdown $markdown
        $htmlFileName = "$($markdownFile.BaseName).html"
        $htmlPath = Join-Path $destinationPath $htmlFileName
        $articleHtml = New-ArticleHtml -Title $markdownFile.BaseName -CategoryName $category.Name -ArticleBody $articleBody
        [System.IO.File]::WriteAllText($htmlPath, $articleHtml, $utf8NoBom)
        $reportItems.Add([PSCustomObject]@{ Title = $markdownFile.BaseName; FileName = $htmlFileName })
        $totalReports++
        Write-Host "Generated: docs/$($category.Destination)/$htmlFileName"
    }

    $categoryIndex = New-CategoryIndexHtml -Name $category.Name -Description $category.Description -Items $reportItems.ToArray()
    [System.IO.File]::WriteAllText((Join-Path $destinationPath "index.html"), $categoryIndex, $utf8NoBom)
    Write-Host "Generated: docs/$($category.Destination)/index.html"
}

Write-Host ""
Write-Host "=== AI Team Portal Build Complete ==="
Write-Host "Converted reports: $totalReports"
Write-Host "Portal: docs/index.html"
