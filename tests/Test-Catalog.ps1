<#
.SYNOPSIS
    Validates catalog/catalog.json and the PowerShell sources.

.DESCRIPTION
    Pure static validation — it changes nothing and needs no administrator rights.
    Runs on Windows PowerShell 5.1 and PowerShell 7+. Exit code 0 = all good.

.EXAMPLE
    .\tests\Test-Catalog.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$pass = 0; $fail = 0
function Check {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Coloured pass/fail output is the intended interface of this test script.')]
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) { $script:pass++; Write-Host ("  [PASS] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" } else { '' })) -ForegroundColor Green }
    else     { $script:fail++; Write-Host ("  [FAIL] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" } else { '' })) -ForegroundColor Red }
}

Write-Host ''
Write-Host '=== source files parse ===' -ForegroundColor Cyan
foreach ($rel in 'src/WinCleanKit.ps1', 'src/menu/menu.ps1') {
    $p = Join-Path $root $rel
    Check "exists: $rel" (Test-Path $p)
    if (Test-Path $p) {
        $t = $null; $e = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$t, [ref]$e)
        if ($e.Count -gt 0) {
            Check "parses: $rel" $false ("{0} error(s), first: L{1} {2}" -f $e.Count, $e[0].Extent.StartLineNumber, $e[0].Message)
        } else {
            Check "parses: $rel" $true ("{0} tokens" -f $t.Count)
        }
    }
}

Write-Host ''
Write-Host '=== catalog ===' -ForegroundColor Cyan
$catalogPath = Join-Path $root 'catalog/catalog.json'
Check 'catalog.json exists' (Test-Path $catalogPath)
$raw = Get-Content $catalogPath -Raw -Encoding UTF8
$cat = $raw | ConvertFrom-Json
Check 'schema is 1' ($cat.schema -eq 1) "schema=$($cat.schema)"
Check 'has categories' ($cat.categories.Count -gt 0) "count=$($cat.categories.Count)"
Check 'has actions' ($cat.actions.Count -gt 0) "count=$($cat.actions.Count)"

$catIds = @($cat.categories | ForEach-Object { $_.id })
$actIds = @($cat.actions | ForEach-Object { $_.id })

Write-Host ''
Write-Host '--- uniqueness & references ---' -ForegroundColor Cyan
Check 'category ids unique' ((@($catIds | Group-Object | Where-Object Count -gt 1)).Count -eq 0)
Check 'action ids unique' ((@($actIds | Group-Object | Where-Object Count -gt 1)).Count -eq 0)
$orphans = @($cat.actions | Where-Object { $catIds -notcontains $_.category })
Check 'every action references a real category' ($orphans.Count -eq 0) ("orphans: " + (($orphans | ForEach-Object { $_.id }) -join ', '))

Write-Host ''
Write-Host '--- required fields ---' -ForegroundColor Cyan
$validTargets = 'registry', 'service', 'task', 'appx', 'path-clean', 'onedrive'
$fieldErrors = New-Object System.Collections.Generic.List[string]
foreach ($a in $cat.actions) {
    foreach ($f in 'id', 'category', 'target', 'title', 'title_zh', 'why', 'why_zh') {
        if (-not ($a.PSObject.Properties.Name -contains $f) -or -not $a.$f) {
            $fieldErrors.Add("$($a.id): missing $f")
        }
    }
    if ($validTargets -notcontains $a.target) { $fieldErrors.Add("$($a.id): bad target '$($a.target)'") }
    if (-not ($a.PSObject.Properties.Name -contains 'default')) { $fieldErrors.Add("$($a.id): no default flag") }
    # target-specific required fields
    switch ($a.target) {
        'registry' { foreach ($f in 'hive', 'key', 'name', 'type', 'value') {
                        if (-not ($a.PSObject.Properties.Name -contains $f)) { $fieldErrors.Add("$($a.id): registry needs $f") } } }
        'service'  { if (-not $a.name) { $fieldErrors.Add("$($a.id): service needs name") }
                     if (-not $a.startType) { $fieldErrors.Add("$($a.id): service needs startType") } }
        'task'     { foreach ($f in 'path', 'name') {
                        if (-not $a.$f) { $fieldErrors.Add("$($a.id): task needs $f") } } }
        'appx'     { if (-not $a.name) { $fieldErrors.Add("$($a.id): appx needs name") } }
        'path-clean' { if (-not $a.paths -or $a.paths.Count -eq 0) { $fieldErrors.Add("$($a.id): path-clean needs paths") } }
    }
}
Check 'all actions well formed' ($fieldErrors.Count -eq 0) ("{0} problem(s)" -f $fieldErrors.Count)
$fieldErrors | Select-Object -First 10 | ForEach-Object { Write-Host "         $_" -ForegroundColor DarkYellow }

Write-Host ''
Write-Host '--- default selection ---' -ForegroundColor Cyan
# There is no tier to choose before you start: the catalog names one starting set,
# and everything outside it is opt-in.
$defaults = @($cat.actions | Where-Object { $_.default } | ForEach-Object { $_.id })
$optIn    = @($cat.actions | Where-Object { -not $_.default } | ForEach-Object { $_.id })
Write-Host ("  default = {0} actions" -f $defaults.Count)
Write-Host ("  opt-in  = {0} actions" -f $optIn.Count)
Check 'the default selection is not empty' ($defaults.Count -gt 0)
Check 'the default selection is not everything' ($optIn.Count -gt 0) ("{0} opt-in" -f $optIn.Count)
Check 'default and opt-in partition the catalog' (($defaults.Count + $optIn.Count) -eq $cat.actions.Count)
Check 'the two sets do not overlap' ((@($defaults | Where-Object { $optIn -contains $_ })).Count -eq 0)
# The whole point of removing presets is that nothing is implicitly re-added, so the
# set that is on at startup must be the small one.
# The risk label is gone, but the protection it encoded is not: with no `risk` field
# left, the invariant is expressed on what an action actually does.
$destructiveDefault = @($cat.actions | Where-Object { $_.default -and $_.target -in 'appx', 'onedrive' })
Check 'nothing that uninstalls software is on by default' ($destructiveDefault.Count -eq 0) ("found: " + (($destructiveDefault | ForEach-Object { $_.id }) -join ', '))
Check 'the risk field is gone from every action' ((@($cat.actions | Where-Object { $_.PSObject.Properties.Name -contains 'risk' })).Count -eq 0) 'the label was removed on purpose'

Write-Host ''
Write-Host '--- safety invariants ---' -ForegroundColor Cyan
# Nothing may reference the hosts file, and nothing may disable Windows Update.
# NOTE: this script runs under Set-StrictMode 2.0, where touching a property an
# object does not have is a terminating error. Guard every optional property with
# PSObject.Properties before reading it.
function Get-OptProp($Obj, [string]$Name) {
    if ($Obj.PSObject.Properties.Name -contains $Name) { [string]$Obj.$Name } else { '' }
}
$hostsRefs = @()
foreach ($a in $cat.actions) {
    $blob = ''
    foreach ($f in 'key', 'name', 'paths') { $blob += (Get-OptProp $a $f) + ' ' }
    if ($blob -match 'drivers\\etc|hosts') { $hostsRefs += $a }
}
Check 'no action writes to the hosts file' ($hostsRefs.Count -eq 0)
$wuRefs = @($cat.actions | Where-Object {
    $_.target -eq 'service' -and ([string](Get-OptProp $_ 'name')) -in @('wuauserv', 'UsoSvc', 'BITS', 'DoSvc', 'DPS')
})
Check 'no action disables an update/diagnostic service' ($wuRefs.Count -eq 0) ("found: " + (($wuRefs | ForEach-Object { $_.name }) -join ', '))
$wallpaperRefs = @($cat.actions | Where-Object { (Get-OptProp $_ 'paths') -match 'TranscodedWallpaper|Themes\\CachedFiles' })
Check 'no action deletes the wallpaper transcode copy' ($wallpaperRefs.Count -eq 0) ("found: " + (($wallpaperRefs | ForEach-Object { $_.id }) -join ', '))
$hd = @($cat.actions | Where-Object { $_.id -eq 'onedrive.uninstall' })
Check 'OneDrive action exists and is opt-in only' ($hd.Count -eq 1 -and -not $hd[0].default)

Write-Host ''
Write-Host '=== .bat front-end sanity ===' -ForegroundColor Cyan
$batPath = Join-Path $root 'src/WinCleanKit.bat'
Check 'WinCleanKit.bat exists' (Test-Path $batPath)
if (Test-Path $batPath) {
    $batBytes = [IO.File]::ReadAllBytes($batPath)
    $batText  = [Text.Encoding]::UTF8.GetString($batBytes)
    Check 'bat uses CRLF line endings' (($batText -split "`n").Count -gt 1 -and $batText.Contains("`r`n")) 'cmd needs CRLF'
    Check 'bat has no UTF-8 BOM' (-not ($batBytes[0] -eq 0xEF -and $batBytes[1] -eq 0xBB)) 'a BOM would print as garbage before @echo off'
    Check 'bat sets codepage 65001' ($batText -match 'chcp\s+65001') 'needed for Chinese output'
    Check 'bat delegates to the engine' ($batText -match 'WinCleanKit\.ps1') 'bat must not touch the registry itself'
    foreach ($needle in 'reg add', 'reg delete', 'reg.exe') {
        Check "bat contains no '$needle'" (-not ($batText -match [regex]::Escape($needle))) 'all changes go through the catalog-driven engine'
    }
}

Write-Host ''
Write-Host '=== .ps1 encoding (Windows PowerShell 5.1 needs the BOM) ===' -ForegroundColor Cyan
foreach ($rel in 'src/WinCleanKit.ps1', 'src/menu/menu.ps1') {
    $p = Join-Path $root $rel
    if (Test-Path $p) {
        $b = [IO.File]::ReadAllBytes($p)
        Check "$rel has UTF-8 BOM" ($b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) 'without it, Chinese strings decode as ANSI'
    }
}

Write-Host ''
if ($fail -eq 0) { Write-Host ("ALL PASSED  ({0} checks)" -f $pass) -ForegroundColor Green }
else             { Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
