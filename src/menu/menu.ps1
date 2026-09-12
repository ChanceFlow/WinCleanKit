<#
.SYNOPSIS
    Menu helper for the WinCleanKit .bat front-end.

.DESCRIPTION
    The interactive UI lives in WinCleanKit.bat, but batch is a terrible language
    for reading JSON and doing set arithmetic. So this helper does the thinking and
    prints plain pipe-delimited lines that batch can parse with `for /f`.

    It never changes the system. It only reads the catalog and the user's
    plus/minus choice files and reports what the plan currently looks like.

.OUTPUT FORMAT
    show   :  id|name|count|risk      (one line per category)  then  TOTAL|n
    cat    :  id|title|risk|sel       (one line per action in that category)
    items  :  n|id|title|risk|cat|sel (numbered list across everything)
    sel    :  id                    (one line per effectively-selected action)
    line   :  summary|actions|risk|plus|minus
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('main', 'cat', 'items', 'sel', 'summary', 'cats')]
    [string] $Mode,
    [string] $Preset   = 'balanced',
    [string] $Lang     = 'en',
    [string] $PlusFile = '',
    [string] $MinusFile = '',
    [string] $Category = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root        = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$catalogPath = Join-Path $root 'catalog/catalog.json'
if (-not (Test-Path $catalogPath)) { throw "catalog.json not found at $catalogPath" }
$catalog = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json

$riskOrder = @{ low = 1; medium = 2; high = 3 }
$riskLabel = if ($Lang -eq 'zh') { @{ low = '低'; medium = '中'; high = '高' } }
             else                { @{ low = 'low'; medium = 'MED'; high = 'HIGH' } }

function L {
    param($Object, [string]$Base = 'title')
    if ($Lang -eq 'zh') {
        $alt = "${Base}_zh"
        if ($Object.PSObject.Properties.Name -contains $alt -and $Object.$alt) { return $Object.$alt }
    }
    return $Object.$Base
}

function Read-IdFile([string]$Path) {
    $set = @{}
    if ($Path -and (Test-Path $Path)) {
        foreach ($line in (Get-Content $Path -Encoding UTF8)) {
            $t = $line.Trim()
            if ($t) { $set[$t] = $true }
        }
    }
    return $set
}

$plus  = Read-IdFile $PlusFile
$minus = Read-IdFile $MinusFile

# --- Effective selection: preset, then +plus, then -minus --------------------
$effective = [ordered]@{}
foreach ($a in $catalog.actions) {
    $inPreset = ($a.PSObject.Properties.Name -contains 'presets' -and $a.presets -and ($a.presets -contains $Preset))
    if ($inPreset) { $effective[$a.id] = $true }
}
foreach ($id in $plus.Keys)  { $effective[$id] = $true }
foreach ($id in $minus.Keys) { if ($effective.Contains($id)) { $effective.Remove($id) } }

switch ($Mode) {

    'cats' {
        foreach ($c in $catalog.categories) {
            $n = @($catalog.actions | Where-Object { $_.category -eq $c.id -and $effective.Contains($_.id) }).Count
            '{0}|{1}|{2}|{3}' -f $c.id, (L $c 'name'), $n, $c.risk
        }
    }

    'main' {
        foreach ($c in $catalog.categories) {
            $n = @($catalog.actions | Where-Object { $_.category -eq $c.id -and $effective.Contains($_.id) }).Count
            '{0}|{1}|{2}|{3}' -f $c.id, (L $c 'name'), $n, $c.risk
        }
        $maxRisk = 0
        foreach ($a in $catalog.actions) {
            if ($effective.Contains($a.id)) {
                $r = $riskOrder[$a.risk]
                if ($r -gt $maxRisk) { $maxRisk = $r }
            }
        }
        'TOTAL|{0}|{1}' -f $effective.Count, $maxRisk
    }

    'cat' {
        foreach ($a in $catalog.actions) {
            if ($a.category -ne $Category) { continue }
            $sel = if ($effective.Contains($a.id)) { 1 } else { 0 }
            '{0}|{1}|{2}|{3}' -f $a.id, (L $a 'title'), $riskLabel[$a.risk], $sel
        }
    }

    'items' {
        $i = 0
        foreach ($a in $catalog.actions) {
            $i++
            $sel = if ($effective.Contains($a.id)) { 1 } else { 0 }
            '{0}|{1}|{2}|{3}|{4}|{5}' -f $i, $a.id, (L $a 'title'), $riskLabel[$a.risk], $a.category, $sel
        }
    }

    'sel' {
        foreach ($a in $catalog.actions) {
            if ($effective.Contains($a.id)) { $a.id }
        }
    }

    'summary' {
        $maxRisk = 0
        foreach ($a in $catalog.actions) {
            if ($effective.Contains($a.id)) {
                $r = $riskOrder[$a.risk]
                if ($r -gt $maxRisk) { $maxRisk = $r }
            }
        }
        'summary|{0}|{1}|{2}|{3}' -f $effective.Count, $maxRisk, $plus.Count, $minus.Count
    }
}
