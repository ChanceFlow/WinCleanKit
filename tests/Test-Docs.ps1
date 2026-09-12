<#
.SYNOPSIS
    Verifies the bilingual documentation contract.

.DESCRIPTION
    Requires no modules and changes nothing. Enforces two rules:

      1. Every Markdown link between documents resolves to a file that exists.
      2. Every document that should be bilingual HAS both language versions, and
         each links to the other from its language switcher line.

    Without this, "the docs are bilingual" decays the moment someone adds a page
    and forgets the counterpart. Deliberate exceptions are listed in $NoTranslation
    with a reason, so a missing translation is a decision rather than an oversight.

.EXAMPLE
    .\tests\Test-Docs.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

# Documents intentionally available in one language only, with the reason.
$NoTranslation = @{
    'CHANGELOG.md'          = 'A changelog is a technical log; per-language copies drift and mislead.'
    'localization/README.md' = 'This page is about translations, so it exists only in English.'
    'docs/LINTING.md'       = 'Linting notes are aimed at contributors; English only by decision.'
    # Contributor-facing templates that GitHub renders as forms, not documents.
    '.github/pull_request_template.md' = 'A GitHub PR template; English is the lingua franca for PR prose.'
    # This page contains a copyable language-switcher template inside a fenced code
    # block. Extracting markdown links from a code fence is not meaningful.
    'CONTRIBUTING.zh-CN.md' = 'Contains a copyable link template inside a code block.'
}

$pass = 0
$fail = 0
function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) { $script:pass++; Write-Host ("  [PASS] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" })) -ForegroundColor Green }
    else     { $script:fail++; Write-Host ("  [FAIL] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" })) -ForegroundColor Red }
}

Write-Host ''
Write-Host '=== Markdown files ===' -ForegroundColor Cyan

$docs = @(Get-ChildItem $root -Recurse -File -Filter '*.md' |
          Where-Object { $_.FullName -notmatch '\\\.git\\' } | Sort-Object FullName)
Write-Host ("  {0} file(s)" -f $docs.Count)

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '=== 1. every relative link resolves ===' -ForegroundColor Cyan

$linkRe = [regex]'\]\(([^)\s#]+?)(#[^)\s]*)?\)'
$broken = New-Object System.Collections.Generic.List[string]
$linkCount = 0

foreach ($d in $docs) {
    $rel = $d.FullName.Substring($root.Length + 1).Replace('\', '/')
    $baseDir = Split-Path $d.FullName -Parent
    $text = Get-Content $d.FullName -Raw -Encoding UTF8

    foreach ($m in $linkRe.Matches($text)) {
        $target = $m.Groups[1].Value
        # Skip absolute URLs and mailto.
        if ($target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') { continue }
        $linkCount++
        $resolved = [IO.Path]::GetFullPath((Join-Path $baseDir $target))
        if (-not (Test-Path $resolved)) {
            $broken.Add(("{0} -> {1}" -f $rel, $target))
        }
    }
}
Check ('all {0} relative links resolve' -f $linkCount) ($broken.Count -eq 0) ("{0} broken" -f $broken.Count)
$broken | Select-Object -First 20 | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '=== 2. bilingual pairs exist and cross-link ===' -ForegroundColor Cyan

$enDocs = @($docs | Where-Object { $_.Name -notmatch '\.zh-CN\.md$' })
$missingZh = New-Object System.Collections.Generic.List[string]
$missingBackLink = New-Object System.Collections.Generic.List[string]
$pairs = 0

foreach ($en in $enDocs) {
    $rel = $en.FullName.Substring($root.Length + 1).Replace('\', '/')
    if ($NoTranslation.ContainsKey($rel)) { continue }

    $zhName = [IO.Path]::GetFileNameWithoutExtension($en.Name) + '.zh-CN.md'
    $zhPath = Join-Path (Split-Path $en.FullName -Parent) $zhName

    if (-not (Test-Path $zhPath)) {
        $missingZh.Add($rel)
        continue
    }
    $pairs++

    # English must link to its Chinese counterpart.
    $enText = Get-Content $en.FullName -Raw -Encoding UTF8
    if ($enText -notmatch [regex]::Escape($zhName)) {
        $missingBackLink.Add("$rel (does not link to $zhName)")
    }
    # Chinese must link back to the English original.
    $zhText = Get-Content $zhPath -Raw -Encoding UTF8
    if ($zhText -notmatch [regex]::Escape($en.Name)) {
        $missingBackLink.Add("$zhName (does not link back to $($en.Name))")
    }
}

Check "every translatable document has a .zh-CN.md" ($missingZh.Count -eq 0) ("{0} missing" -f $missingZh.Count)
$missingZh | ForEach-Object { Write-Host "         missing: $_" -ForegroundColor Red }
Check "both directions link to each other" ($missingBackLink.Count -eq 0) ("{0} one-way" -f $missingBackLink.Count)
$missingBackLink | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
Write-Host ("  {0} bilingual pair(s)" -f $pairs)

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '=== 3. language switcher is near the top of every bilingual file ===' -ForegroundColor Cyan

$headless = New-Object System.Collections.Generic.List[string]
foreach ($d in $docs) {
    $rel = $d.FullName.Substring($root.Length + 1).Replace('\', '/')
    if ($NoTranslation.ContainsKey($rel)) { continue }
    # 30 lines, not 8: the READMEs put a banner and a fenced code block above the
    # switcher. Fences are tracked below so a link inside a code block is ignored.
    $lines = Get-Content $d.FullName -Encoding UTF8 | Select-Object -First 30
    # Accept either "**English** · [中文](x.zh-CN.md)" or "[English](x.md) · [中文](...)".
    # The first token may be bold text rather than a self-link, and a fenced code
    # block may contain a link template, so track fences and require only the middle
    # dot plus a .md link.
    $hasSwitcher = $false
    $inFence = $false
    foreach ($l in $lines) {
        if ($l -match '^\s*```') { $inFence = -not $inFence; continue }
        if (-not $inFence -and $l.Contains([char]0x00B7) -and $l -match '\]\([^)]+\.md') {
            $hasSwitcher = $true
            break
        }
    }
    if (-not $hasSwitcher) { $headless.Add($rel) }
}
Check 'every bilingual file declares its languages up top' ($headless.Count -eq 0) ("{0} without" -f $headless.Count)
$headless | ForEach-Object { Write-Host "         no switcher: $_" -ForegroundColor Red }

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '=== 4. no internal addresses in tracked content ===' -ForegroundColor Cyan

# Anything that looks like a private endpoint must not appear in a public repository.
# The pattern is assembled from fragments so that this file does not itself contain a
# literal private address: an auditor grepping the repository for address-shaped text
# should get zero hits, and defining the rule must not be the exception.
#
# Ports are matched by explicit range rather than as "any 4-5 digit number", so that
# ordinary prose such as an HTTPS 443 reference or a version number is not flagged.
function Get-PrivateAddressPattern {
    $octet = '[0-9]' + '{1,3}'
    $dot   = '[.]'
    $port  = ':(4[0-9]' + '{3}|8[0-9]' + '{3}|2[0-9]' + '{4})'
    $parts = @(
        ('\b' + '10'    + $dot + $octet + $dot + $octet + $dot + $octet + '\b'),
        ('\b' + '192'   + $dot + '168'   + $dot + $octet + $dot + $octet + '\b'),
        ('\b' + '172'   + $dot + '(1[6-9]|2[0-9]|3[01])' + $dot + $octet + $dot + $octet + '\b'),
        $port
    )
    return ($parts -join '|')
}
$offenders = New-Object System.Collections.Generic.List[string]

foreach ($f in (Get-ChildItem $root -Recurse -File |
                Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Extension -in '.md', '.ps1', '.psm1', '.psd1', '.bat', '.cmd', '.json', '.yml', '.yaml', '.txt' })) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    $text = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($text -and $text -match (Get-PrivateAddressPattern)) {
        $offenders.Add($rel)
    }
}
Check 'no private network addresses in tracked files' ($offenders.Count -eq 0) ("{0} file(s)" -f $offenders.Count)
$offenders | ForEach-Object { Write-Host "         contains a private address: $_" -ForegroundColor Red }

Write-Host ''
if ($fail -eq 0) { Write-Host ("ALL PASSED  ({0} checks, {1} links verified)" -f $pass, $linkCount) -ForegroundColor Green }
else             { Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
