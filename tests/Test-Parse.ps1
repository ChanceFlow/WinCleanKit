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
