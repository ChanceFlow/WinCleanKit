<#
.SYNOPSIS
    Parses every PowerShell file in the repository and reports syntax errors.

.DESCRIPTION
    This is the syntax gate. It uses the PowerShell language parser directly, so
    it needs no modules and no network, and it runs identically on Windows
    PowerShell 5.1 and PowerShell 7+.

    A file that parses here is valid PowerShell. That is a different question from
    style, which is what tests/Test-Analyzer.ps1 covers.

    Non-ASCII text depends on file encoding, which Windows PowerShell 5.1 and
    PowerShell 7 disagree about, so the encoding rules are verified here too:

      * source .ps1  -> UTF-8 WITH BOM   (otherwise 5.1 decodes Chinese as ANSI)
      * front .bat   -> UTF-8 WITHOUT BOM, CRLF  (a BOM would print before @echo off)

.EXAMPLE
    .\tests\Test-Parse.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Write-Head {
    param([string]$Text)
    Write-Host ''
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

$pass = 0
$fail = 0
function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) { $script:pass++; Write-Host ("  [PASS] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" })) -ForegroundColor Green }
    else     { $script:fail++; Write-Host ("  [FAIL] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" })) -ForegroundColor Red }
}

Write-Head 'PowerShell syntax'

$files = @(Get-ChildItem $root -Recurse -File -Include '*.ps1', '*.psm1', '*.psd1' |
           Where-Object { $_.FullName -notmatch '\\\.git\\' } | Sort-Object FullName)

Write-Host ("  {0} file(s)" -f $files.Count)
Write-Host ''

foreach ($f in $files) {
    $rel = $f.FullName.Substring($root.Length + 1)
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors)

    if ($errors.Count -gt 0) {
        Check "parses: $rel" $false ("{0} error(s)" -f $errors.Count)
        $errors | Select-Object -First 10 | ForEach-Object {
            Write-Host ("         line {0}, col {1}: {2}" -f `
                $_.Extent.StartLineNumber, $_.Extent.StartColumnNumber, $_.Message) -ForegroundColor Red
        }
    } else {
        Check "parses: $rel" $true ("{0} tokens" -f $tokens.Count)
    }
}

Write-Head 'Encoding'
# Windows PowerShell 5.1 decodes a BOM-less .ps1 as ANSI, which corrupts Chinese.
$ps1 = @($files | Where-Object Extension -in '.ps1', '.psm1', '.psd1')
foreach ($f in $ps1) {
    $rel = $f.FullName.Substring($root.Length + 1)
    $bytes = [IO.File]::ReadAllBytes($f.FullName)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Check "UTF-8 BOM: $rel" $hasBom 'required so PowerShell 5.1 decodes Unicode correctly'
}

$batPath = Join-Path $root 'src/WinCleanKit.bat'
if (Test-Path $batPath) {
    $batBytes = [IO.File]::ReadAllBytes($batPath)
    $batText = [Text.Encoding]::UTF8.GetString($batBytes)
    Check 'bat has no BOM' (-not ($batBytes[0] -eq 0xEF -and $batBytes[1] -eq 0xBB)) 'a BOM prints as garbage before @echo off'
    Check 'bat uses CRLF' ($batText.Contains("`r`n")) 'cmd requires CRLF'
}

Write-Head 'Batch launcher invariants'
# Two cmd behaviours bit this project and neither is visible in a code review:
#
#   * chcp discards whatever is on the standard input stream. A caller feeding
#     the numbered menu from a file or a pipe therefore lost its first lines and
#     the menu read end-of-input straight away.
#   * a parameter that carries a script path is re-resolved against the *current*
#     directory every time it is expanded, not the directory the file was called
#     from. run.bat calling the relative "src\WinCleanKit.bat" made the callee
#     resolve its own folder a second time after its cd and see src\src.
#
# These checks keep both fixes, and the single end-of-input implementation, in
# place. Comment lines are ignored: rem never expands anything.
function Get-CodeLine {
    param([string]$Path)
    $text = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($Path))
    return @($text -split "`r?`n" | Where-Object { $_ -notmatch '^\s*rem\b' })
}

if (Test-Path $batPath) {
    $batLines = Get-CodeLine $batPath

    $chcp = @($batLines | Where-Object { $_ -match '^\s*chcp\b' })
    Check 'bat: chcp does not eat stdin' (($chcp.Count -ge 1) -and (@($chcp | Where-Object { $_ -match '<nul' }).Count -eq $chcp.Count)) 'chcp must be handed <nul or it discards piped input'

    $cdAt = -1
    for ($i = 0; $i -lt $batLines.Count; $i++) { if ($batLines[$i] -match '^\s*cd\s+/d\b') { $cdAt = $i; break } }
    $late = @()
    for ($i = $cdAt + 1; $i -lt $batLines.Count -and $cdAt -ge 0; $i++) {
        if ($batLines[$i] -match '%~[A-Za-z]*0') { $late += ($i + 1) }
    }
    Check 'bat: script path read before cd' ($cdAt -ge 0 -and $late.Count -eq 0) $(if ($late.Count) { 'expanded after the working directory moves, line(s) ' + ($late -join ', ') } else { 'no script path is expanded after the working directory moves' })

    $label = ''
    $stray = @()
    for ($i = 0; $i -lt $batLines.Count; $i++) {
        if ($batLines[$i] -match '^:([A-Za-z_]\w*)\s*$') { $label = $Matches[1] }
        if ($batLines[$i] -match 'set\s+/p\b' -and $batLines[$i] -notmatch '<nul\s+set\s+/p' -and $label -ne 'ask') {
            $stray += ("line {0} in :{1}" -f ($i + 1), $label)
        }
    }
    Check 'bat: every prompt goes through :ask' ($stray.Count -eq 0) $(if ($stray.Count) { 'stray: ' + ($stray -join ', ') } else { 'end-of-input is detected in exactly one place' })
}

$runPath = Join-Path $root 'run.bat'
if (Test-Path $runPath) {
    $runLines = Get-CodeLine $runPath
    $captured = -1
    $runCdAt = -1
    for ($i = 0; $i -lt $runLines.Count; $i++) {
        if ($captured -lt 0 -and $runLines[$i] -match 'set\s+"[^"]+=[^"]*%~dp0') { $captured = $i }
        if ($runCdAt -lt 0 -and $runLines[$i] -match '^\s*cd\s+/d\b') { $runCdAt = $i }
    }
    Check 'run.bat: folder captured before cd' ($captured -ge 0 -and ($runCdAt -lt 0 -or $captured -lt $runCdAt)) 'otherwise the callee re-resolves a relative path against the new directory'

    $call = @($runLines | Where-Object { $_ -match '^\s*call\s+' -and $_ -match 'WinCleanKit\.bat' })
    Check 'run.bat: launcher called by absolute path' ($call.Count -eq 1 -and $call[0] -notmatch 'call\s+"src\\') 'call "%VAR%src\..." so the callee never resolves itself twice'
}

Write-Head 'Required files present'
# These are load-bearing for CI. .gitignore once excluded the analyzer ruleset with
# a blanket *.psd1, which silently weakened the lint gate in CI but not locally.
foreach ($rel in '.github/PSScriptAnalyzerSettings.psd1', '.github/workflows/ci.yml',
                 '.gitea/workflows/ci.yml', 'catalog/catalog.json', 'src/WinCleanKit.ps1') {
    Check "present: $rel" (Test-Path (Join-Path $root $rel)) 'required for CI or the engine'
}

Write-Head 'Encoding does not mangle non-ASCII text'
# Read a Chinese string back the way PowerShell 5.1 would and confirm it survives.
$engine = Join-Path $root 'src/WinCleanKit.ps1'
if (Test-Path $engine) {
    $roundTrip = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($engine))
    Check 'engine source decodes as UTF-8' ($roundTrip -notmatch '\uFFFD') 'no replacement characters'
}
$catalogPath = Join-Path $root 'catalog/catalog.json'
if (Test-Path $catalogPath) {
    $cat = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $withZh = @($cat.actions | Where-Object { $_.title_zh -match '[\u4e00-\u9fff]' })
    Check 'catalog Chinese titles decode' ($withZh.Count -eq $cat.actions.Count) ("{0}/{1} actions" -f $withZh.Count, $cat.actions.Count)
}

Write-Host ''
if ($fail -eq 0) { Write-Host ("ALL PASSED  ({0} checks)" -f $pass) -ForegroundColor Green }
else             { Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
