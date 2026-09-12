<#
.SYNOPSIS
    Runs PSScriptAnalyzer over the repository. Changes nothing.

.DESCRIPTION
    This is the lint gate used by CI, and it is meant to be run locally before
    opening a pull request. It analyses every PowerShell file in the repository
    (sources, tests, and the analyzer settings themselves) with the repository
    ruleset.

    Findings are split in two:

      * Errors   - always fatal.
      * Warnings - fatal unless suppressed. Suppressions must live in the code as
                   [SuppressMessageAttribute] with a Justification, so the reason
                   is visible where the code is. The ruleset only narrows which
                   rules run, never hides a finding.

.PARAMETER Fix
    Apply PSScriptAnalyzer's automatic fixes where it can. Review the diff.

.PARAMETER Detailed
    Print every finding including Information-severity ones.

.EXAMPLE
    .\tests\Test-Analyzer.ps1

.EXAMPLE
    # One-time setup if the module is missing
    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
#>
[CmdletBinding()]
param(
    [switch]$Fix,
    [switch]$Detailed
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$settings = Join-Path $root '.github/PSScriptAnalyzerSettings.psd1'

function Write-Head([string]$Text) { Write-Host ''; Write-Host "=== $Text ===" -ForegroundColor Cyan }

Write-Head 'PSScriptAnalyzer'

$module = Get-Module -ListAvailable PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if (-not $module) {
    Write-Host '  PSScriptAnalyzer is not installed.' -ForegroundColor Yellow
    Write-Host '  Install it with:' -ForegroundColor Yellow
    Write-Host '      Install-Module PSScriptAnalyzer -Scope CurrentUser -Force' -ForegroundColor Yellow
    Write-Host '  Skipping the lint gate (the parser-based checks in Test-Catalog.ps1 still ran).' -ForegroundColor Yellow
    exit 0
}
Import-Module PSScriptAnalyzer -Force
Write-Host ("  module  : {0}" -f $module.Version)
Write-Host ("  settings: {0}" -f (Split-Path $settings -Leaf))

$files = @(Get-ChildItem $root -Recurse -File -Include '*.ps1', '*.psm1', '*.psd1' |
           Where-Object { $_.FullName -notmatch '\\\.git\\' })
Write-Host ("  files   : {0}" -f $files.Count)

$findings = @()
foreach ($f in $files) {
    $r = Invoke-ScriptAnalyzer -Path $f.FullName -Settings $settings
    if ($r) { $findings += $r }
}

$errors = @($findings | Where-Object Severity -eq 'Error')
$warns  = @($findings | Where-Object Severity -eq 'Warning')
$infos  = @($findings | Where-Object Severity -eq 'Information')

Write-Host ''
Write-Host ("  Error       : {0}" -f $errors.Count) -ForegroundColor $(if ($errors.Count) { 'Red' } else { 'Green' })
Write-Host ("  Warning     : {0}" -f $warns.Count)  -ForegroundColor $(if ($warns.Count) { 'Red' } else { 'Green' })
Write-Host ("  Information : {0}" -f $infos.Count)  -ForegroundColor DarkGray

if ($errors.Count -gt 0) {
    Write-Host ''
    Write-Host '  --- errors ---' -ForegroundColor Red
    $errors | ForEach-Object {
        Write-Host ("  {0}:{1}  {2}" -f $_.ScriptName, $_.Line, $_.Message) -ForegroundColor Red
    }
}
if ($warns.Count -gt 0) {
    Write-Host ''
    Write-Host '  --- warnings ---' -ForegroundColor Red
    $warns | Group-Object RuleName | Sort-Object Count -Descending | ForEach-Object {
        Write-Host ("  {0,-45} {1}" -f $_.Name, $_.Count) -ForegroundColor Red
        $_.Group | Select-Object -First 5 | ForEach-Object {
            Write-Host ("      {0}:{1}  {2}" -f $_.ScriptName, $_.Line, $_.Message) -ForegroundColor DarkGray
        }
    }
}
if ($Detailed -and $infos.Count -gt 0) {
    Write-Host ''
    Write-Host '  --- information ---' -ForegroundColor DarkGray
    $infos | ForEach-Object {
        Write-Host ("  {0}:{1}  {2}  {3}" -f $_.ScriptName, $_.Line, $_.RuleName, $_.Message) -ForegroundColor DarkGray
    }
}

if ($Fix) {
    Write-Head 'applying automatic fixes'
    $fixed = 0
    foreach ($f in $files) {
        $r = Invoke-ScriptAnalyzer -Path $f.FullName -Settings $settings -Fix
        if ($r) { $fixed += @($r).Count; Write-Host ("  fixed {0} issue(s) in {1}" -f @($r).Count, $f.Name) }
    }
    if ($fixed -eq 0) { Write-Host '  nothing to fix' }
    Write-Host '  Review the diff, then re-run without -Fix.' -ForegroundColor Yellow
}

Write-Host ''
if ($errors.Count -eq 0 -and $warns.Count -eq 0) {
    Write-Host 'PSScriptAnalyzer: CLEAN' -ForegroundColor Green
    exit 0
}
Write-Host 'PSScriptAnalyzer: FINDINGS PRESENT' -ForegroundColor Red
exit 1
