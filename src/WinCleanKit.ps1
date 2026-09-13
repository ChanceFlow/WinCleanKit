<#
.SYNOPSIS
    WinCleanKit engine — the part that actually touches Windows.

.DESCRIPTION
    This is a data-driven executor. It never hardcodes what to change: every
    action is read from catalog/catalog.json. Its jobs are:

      1. Resolve a plan from the catalog + user selection (presets, -Only, -Skip).
      2. Show the plan so the user can see exactly what would happen.
      3. Execute it, recording the original state so everything can be undone.
      4. Write a self-contained restore script next to the log.

    It is designed to be driven by the interactive .bat front-end, but works
    perfectly on its own for scripted/unattended use.

.PARAMETER ListCatalog
    Emit the catalog as JSON on stdout (used by the .bat menu) and exit.

.PARAMETER Plan
    Show the resolved plan without changing anything, then exit.

.PARAMETER Apply
    Execute the plan.

.PARAMETER DryRun
    With -Apply, execute nothing but report what would be done.

.PARAMETER Preset
    conservative | balanced | aggressive. Anything outside the preset can be
    added with -Only, removed with -Skip.

.PARAMETER Only
    Action ids or category ids to include (wildcards allowed, e.g. 'ads.*').

.PARAMETER Skip
    Action ids or category ids to exclude. Wins over -Only.

.PARAMETER FromFile
    Path to a file with one action id per line. Merged into -Only. Used by the .bat
    front-end so a long selection never has to survive a command line.

.PARAMETER Select
    Also accept 'ads.telemetry' style bundle prefixes.

.PARAMETER Language
    en | zh. Controls display language. Default en.

.PARAMETER NoPrompt
    Never ask anything. Required for unattended runs.

.PARAMETER EmitJson
    Emit a machine-readable result object on stdout instead of pretty text.

.NOTES
    Part of WinCleanKit. Requires Windows PowerShell 5.1+ or PowerShell 7+.
    Must run elevated for machine-level (HKLM) changes.
#>
[CmdletBinding()]
param(
    [switch]   $ListCatalog,
    [switch]   $Plan,
    [switch]   $Apply,
    [switch]   $DryRun,
    [ValidateSet('conservative', 'balanced', 'aggressive')]
    [string]   $Preset = 'balanced',
    [string[]] $Only = @(),
    [string[]] $Skip = @(),
    [string]   $FromFile = '',
    [ValidateSet('en', 'zh')]
    [string]   $Language = 'en',
    [switch]   $NoPrompt,
    [switch]   $EmitJson,
    [switch]   $ListRestores,
    [string]   $Restore,
    [switch]   $Version,
    [switch]   $Tui,
    [switch]   $NoTui,
    [ValidateSet('conservative', 'balanced', 'aggressive')]
    [string]   $TuiPreset = 'balanced',
    [ValidateSet('en', 'zh')]
    [string]   $TuiLanguage = 'en',
    # Report the interactive outcome as an exit code rather than as text, so a
    # caller can tell "this console cannot draw" (3) from "the user quit" (0).
    # src\WinCleanKit.bat uses that difference to decide whether to fall back.
    [switch]   $TuiExitCode
)

# Version 2.0 (not Latest): catalog entries have optional properties per target
# type, and accessing an absent property must yield $null instead of throwing.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:EngineVersion = '0.1.0'
$script:Root          = Split-Path -Parent $PSScriptRoot
$script:CatalogPath   = Join-Path $script:Root 'catalog/catalog.json'
$script:Lang          = $Language
$script:RiskOrder     = @{ low = 1; medium = 2; high = 3 }

$script:CountOk   = 0
$script:CountSkip = 0
$script:CountFail = 0
$script:Failures  = @()

# --------------------------------------------------------------------------
# Tiny localisation helper. The catalog carries both languages inline.
# --------------------------------------------------------------------------
function L {
    param([Parameter(Mandatory)] $Object, [string]$Base = 'title')
    if ($script:Lang -eq 'zh') {
        $alt = "${Base}_zh"
        if ($Object.PSObject.Properties.Name -contains $alt -and $Object.$alt) { return $Object.$alt }
    }
    $Object.$Base
}

# --------------------------------------------------------------------------
# Terminal design system
#
# One place that decides how the console looks, so every surface stays
# consistent and there is a single point of change:
#
#   * Semantic colour roles instead of ad-hoc colours. "success" means success
#     everywhere; changing the palette is a one-line edit in $script:Ink.
#   * Display-width-aware padding. Chinese characters occupy two terminal
#     columns but count as one character, so PowerShell's own "{0,-20}" leaves
#     CJK tables ragged. Format-Text measures visual width instead.
#   * Colours degrade to plain text when output is a file, a pipe, or CI, so
#     logs stay clean and colour is never the only way state is conveyed.
#   * Nothing here emits ANSI escapes: the 16 console colours behave the same
#     in conhost, Windows Terminal and PowerShell 7.
# --------------------------------------------------------------------------

$script:Ink = @{
    brand    = 'DarkCyan'    # the product frame
    accent   = 'Cyan'        # section headings
    success  = 'Green'       # ok
    caution  = 'Yellow'      # skipped, refused, protected
    danger   = 'Red'         # real failure
    muted    = 'DarkGray'    # hints, paths, de-emphasised detail
    body     = 'Gray'        # default body text
    riskLow  = 'DarkGray'
    riskMed  = 'Yellow'
    riskHigh = 'Red'
}

function Get-Width {
    <#
      Visual width in terminal columns. CJK and full-width punctuation count as
      two columns; combining marks count as zero.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text)
    if (-not $Text) { return 0 }
    $w = 0
    foreach ($ch in $Text.ToCharArray()) {
        $c = [int]$ch
        if (($c -ge 0x1100 -and $c -le 0x115F) -or
            ($c -ge 0x2E80 -and $c -le 0xA4CF) -or
            ($c -ge 0xAC00 -and $c -le 0xD7A3) -or
            ($c -ge 0xF900 -and $c -le 0xFAFF) -or
            ($c -ge 0xFE30 -and $c -le 0xFE6F) -or
            ($c -ge 0xFF00 -and $c -le 0xFF60) -or
            ($c -ge 0xFFE0 -and $c -le 0xFFE6)) { $w += 2 }
        elseif (($c -ge 0x0300 -and $c -le 0x036F)) { }
        else { $w += 1 }
    }
    return $w
}

function Format-Text {
    <#
      Pad or truncate to an exact display width, so columns line up in both
      English and Chinese.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text, [int]$Width)
    if ($null -eq $Text) { $Text = '' }
    $w = Get-Width $Text
    if ($w -gt $Width) {
        # Truncate on a display-width budget and mark the cut.
        $out = ''
        $used = 0
        foreach ($ch in $Text.ToCharArray()) {
            $c = Get-Width ([string]$ch)
            if (($used + $c) -gt ($Width - 1)) { break }
            $out += $ch
            $used += $c
        }
        return $out + [char]0x2026
    }
    return $Text + (' ' * ($Width - $w))
}

# Colour only when a human is watching: not redirected, not a pipe, not CI.
$script:UseColour = $true
if ($Host.Name -eq 'ServerRemoteHost' -or -not [Environment]::UserInteractive) { $script:UseColour = $false }
try {
    if ([Console]::IsOutputRedirected) { $script:UseColour = $false }
} catch {
    # Some hosts (notably a few ISE versions) throw from IsOutputRedirected.
    # Swallowing it is deliberate: an unavailable check must not stop the tool,
    # and the safe default is simply to keep the current colour setting.
    $null = $_
}
if ($env:NO_COLOR) { $script:UseColour = $false }

function Get-Ink {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Role)
    if (-not $script:UseColour) { return $null }
    if ($script:Ink.ContainsKey($Role)) { return $script:Ink[$Role] }
    return $script:Ink['body']
}

function Write-Ink {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text, [string]$Role = 'body', [switch]$NoNewline)
    $colour = Get-Ink $Role
    if ($colour) { Write-Host $Text -ForegroundColor $colour -NoNewline:$NoNewline }
    else         { Write-Host $Text -NoNewline:$NoNewline }
}

# --- The single status vocabulary used by every surface --------------------
# Text markers carry the meaning on their own, so nothing depends on colour.
$script:Tag = @{
    ok      = '[ok]  '
    dry     = '[dry] '
    skip    = '[--]  '
    warn    = '[!!]  '
    fail    = '[XX]  '
}
$script:TagRole = @{
    ok = 'success'; dry = 'accent'; skip = 'muted'; warn = 'caution'; fail = 'danger'
}
function Write-Status {
    param([string]$Kind, [string]$Text)
    if (-not $script:Tag.ContainsKey($Kind)) { $Kind = 'skip' }
    Write-Ink ('  ' + $script:Tag[$Kind]) $script:TagRole[$Kind] -NoNewline
    Write-Ink $Text
}

# --- Progress: long runs should never look frozen -------------------------
$script:ProgressTotal = 0
$script:ProgressIndex = 0
function Initialize-Progress {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([int]$Total)
    $script:ProgressTotal = $Total
    $script:ProgressIndex = 0
}
function Get-ProgressPrefix {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param()
    $script:ProgressIndex++
    if ($script:ProgressTotal -le 0) { return '' }
    $pct = [int](100 * $script:ProgressIndex / $script:ProgressTotal)
    return ('[{0,3}/{1}] {2,3}%  ' -f $script:ProgressIndex, $script:ProgressTotal, $pct)
}

function Write-Head {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text)
    Write-Host ''
    Write-Ink ('  ' + ('-' * 66)) 'brand'
    Write-Ink ("  $Text") 'accent'
    Write-Ink ('  ' + ('-' * 66)) 'brand'
}
function Write-Info {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text)
    Write-Ink "  $Text" 'body'
}
function Write-Dim {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text)
    Write-Ink "  $Text" 'muted'
}
function Write-Good {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text)
    Write-Status 'ok' $Text
}
function Write-Warn2 {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text)
    Write-Status 'warn' $Text
}
function Write-Bad {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Text)
    Write-Status 'fail' $Text
}

function Get-Catalog {
    if (-not (Test-Path $script:CatalogPath)) {
        throw "Catalog not found: $($script:CatalogPath)"
    }
    $raw = Get-Content $script:CatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($raw.schema -ne 1) { throw "Unsupported catalog schema: $($raw.schema)" }
    $raw
}

# --------------------------------------------------------------------------
# Plan resolution
# --------------------------------------------------------------------------
function Test-IdMatch {
    param([string]$Id, [string]$Category, [string[]]$Patterns)
    foreach ($p in $Patterns) {
        if (-not $p) { continue }
        # Accept comma-separated bundles too: 'a.b,c.d'. The .bat front-end and most
        # users naturally write it that way, and PowerShell will not split a single
        # comma-delimited string into an array for us.
        foreach ($one in ($p -split ',')) {
            $pat = $one.Trim()
            if (-not $pat) { continue }
            if ($pat -eq $Id) { return $true }
            if ($pat -eq $Category) { return $true }
            # Wildcards are honoured only when the pattern actually contains one.
            # Without this guard a literal-but-unknown id such as 'no.such.id'
            # matches every id, because '.' is a wildcard for the -like operator.
            if ($pat.IndexOfAny([char[]]'*?[') -ge 0 -and $Id -like $pat) { return $true }
            if ($pat.EndsWith('.*') -and $Id.StartsWith($pat.Substring(0, $pat.Length - 1))) { return $true }
        }
    }
    $false
}

function Resolve-Plan {
    param($Catalog, [string]$PresetName, [string[]]$OnlyList, [string[]]$SkipList)

    $selected = New-Object System.Collections.Generic.List[object]

    foreach ($a in $Catalog.actions) {
        if ($OnlyList.Count -gt 0) {
            # -Only is authoritative: the caller has already resolved the exact set.
            # This is how the .bat front-end sends per-item choices. -Preset is then
            # only a label. Without this, deselecting one item would be silently
            # undone by the preset re-adding it.
            $include = (Test-IdMatch -Id $a.id -Category $a.category -Patterns $OnlyList)
        } else {
            $include = ($a.PSObject.Properties.Name -contains 'presets' -and
                        $a.presets -and
                        ($a.presets -contains $PresetName))
        }
        if (Test-IdMatch -Id $a.id -Category $a.category -Patterns $SkipList) { $include = $false }

        if ($include) { [void]$selected.Add($a) }
    }
    , $selected
}

function Group-PlanByCategory {
    param($Catalog, $Actions)
    $order = @($Catalog.categories | ForEach-Object { $_.id })
    $groups = [ordered]@{}
    foreach ($cid in $order) {
        $items = @($Actions | Where-Object { $_.category -eq $cid })
        if ($items.Count -gt 0) { $groups[$cid] = $items }
    }
    $groups
}

function Get-RiskInk {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param([string]$Risk)
    switch ($Risk) {
        'low'    { return 'riskLow' }
        'medium' { return 'riskMed' }
        'high'   { return 'riskHigh' }
        default  { return 'body' }
    }
}

function Show-Plan {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Interactive console UI: coloured terminal output is the intended interface.')]
    param($Catalog, $Actions)
    $groups = Group-PlanByCategory -Catalog $Catalog -Actions $Actions
    $totalRisk = ($Actions | ForEach-Object { $script:RiskOrder[$_.risk] } | Measure-Object -Maximum).Maximum
    if (-not $totalRisk) { $totalRisk = 0 }

    foreach ($cid in $groups.Keys) {
        $cat = $Catalog.categories | Where-Object { $_.id -eq $cid }
        $items = $groups[$cid]
        Write-Host ''
        # Name padded by display width so the count column lines up in English
        # and Chinese alike; Chinese glyphs are two columns but one character.
        $catName = L $cat 'name'
        $catPad  = if ($script:Lang -eq 'zh') { 26 } else { 30 }
        Write-Ink ("  " + (Format-Text $catName $catPad)) 'accent' -NoNewline
        Write-Ink ("{0} action(s)" -f $items.Count) 'muted'
        foreach ($a in $items) {
            $tag = switch ($a.risk) {
                'low'    { 'low ' }
                'medium' { 'MED ' }
                'high'   { 'HIGH' }
                default  { 'low ' }
            }
            Write-Ink ("    [$tag] ") (Get-RiskInk $a.risk) -NoNewline
            Write-Ink (L $a 'title') 'body'
        }
    }
    Write-Host ''
    Write-Info ("Total actions : {0}" -f $Actions.Count)
    Write-Info ("Highest risk  : {0}" -f @('none', 'low', 'medium', 'high')[$totalRisk])
}

# --------------------------------------------------------------------------
# Restore journal
# --------------------------------------------------------------------------
function Initialize-Journal {
    param([string]$PresetName, $Actions)
    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop) { $desktop = $env:USERPROFILE }
    $dir = Join-Path $desktop ("WinCleanKit-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    # Deliberately NOT created here: a dry run must leave no trace on disk. The
    # directory is created lazily by Save-Journal, which a dry run never calls.
    [pscustomobject]@{
        Dir      = $dir
        Log      = Join-Path $dir 'run.log'
        Backup   = Join-Path $dir 'backup.json'
        Restore  = Join-Path $dir 'Restore-WinCleanKit.ps1'
        Records  = (New-Object System.Collections.ArrayList)
        Preset   = $PresetName
        Started  = (Get-Date)
        Actions  = $Actions.Count
    }
}

function Add-Record {
    param($Journal, [string]$Kind, [hashtable]$Data)
    $rec = [pscustomobject]@{ kind = $Kind; at = (Get-Date).ToString('s') }
    foreach ($k in $Data.Keys) { $rec | Add-Member -NotePropertyName $k -NotePropertyValue $Data[$k] -Force }
    [void]$Journal.Records.Add($rec)
}

function Write-Journal {
    param([string]$Log, [string]$Message)
    if (-not $Log) { return }
    # The run directory is created lazily by Save-Journal. Until then (and for the
    # whole of a dry run) there is nowhere to log to, and that is intentional.
    if (-not (Test-Path (Split-Path -Parent $Log))) { return }
    $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Message
    Add-Content -Path $Log -Value $line -Encoding UTF8
}

function Save-Journal {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Private helper invoked once per run after the user confirmed; not a public cmdlet.')]
    param($Journal)
    # This is the only place the run directory is created, so a dry run (which
    # never calls Save-Journal) leaves nothing behind on the Desktop.
    $records = @($Journal.Records)
    if ($records.Count -eq 0) {
        # Nothing recorded means there is nothing to restore from.
        return
    }
    New-Item -ItemType Directory -Path $Journal.Dir -Force | Out-Null
    $records | ConvertTo-Json -Depth 8 | Out-File -FilePath $Journal.Backup -Encoding UTF8

    $restoreScript = @'
<#
    WinCleanKit restore script — generated automatically.
    Reverses every change recorded in backup.json. Safe to run more than once.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Continue'
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$json  = Join-Path $here 'backup.json'
if (-not (Test-Path $json)) { Write-Host "  [XX]  backup.json not found next to this script." -ForegroundColor Red; exit 1 }
$records = Get-Content $json -Raw -Encoding UTF8 | ConvertFrom-Json

$ok = 0; $failed = 0
foreach ($r in $records) {
    try {
        switch ($r.kind) {
            'registry' {
                $path = ('{0}:\{1}' -f $r.hive, $r.key)
                if ($r.existed) {
                    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    New-ItemProperty -Path $path -Name $r.name -Value $r.old -PropertyType $r.type -Force | Out-Null
                } else {
                    Remove-ItemProperty -Path $path -Name $r.name -ErrorAction SilentlyContinue
                }
                Write-Host ("  [ok]  registry  {0}\{1}" -f $r.hive, $r.name) -ForegroundColor Green
            }
            'service' {
                & sc.exe config $r.name start= $r.oldStart | Out-Null
                if ($r.oldStatus -eq 'Running') { Start-Service $r.name -ErrorAction SilentlyContinue }
                Write-Host ("  [ok]  service   {0} -> {1}" -f $r.name, $r.oldStart) -ForegroundColor Green
            }
            'task' {
                Enable-ScheduledTask -TaskPath $r.path -TaskName $r.name -ErrorAction SilentlyContinue | Out-Null
                Write-Host ("  [ok]  task      {0}" -f $r.name) -ForegroundColor Green
            }
            'appx' {
                Write-Host ("  [!!]  app       {0} not restored automatically" -f $r.name) -ForegroundColor Yellow
                Write-Host ("        reinstall it from the Microsoft Store if you want it back.") -ForegroundColor DarkGray
            }
            'path-clean' {
                Write-Host ("  [!!]  cache     {0} (deleted content is not recoverable)" -f $r.path) -ForegroundColor Yellow
            }
            'onedrive' {
                Write-Host "  [!!]  onedrive  reinstall it from https://aka.ms/onedrive" -ForegroundColor Yellow
            }
            default { }
        }
        $ok++
    } catch {
        $failed++
        Write-Host ("  [XX]  FAILED    {0}: {1}" -f $r.kind, $_.Exception.Message) -ForegroundColor Red
    }
}
Write-Host ''
Write-Host ("  Restore finished.  handled={0}  failed={1}" -f $ok, $failed) -ForegroundColor Cyan
if ($failed -gt 0) { exit 2 }
'@
    $restoreScript | Out-File -FilePath $Journal.Restore -Encoding UTF8
}

# --------------------------------------------------------------------------
# Executors — one per catalog target type
# --------------------------------------------------------------------------
function Get-RegOriginal {
    param([string]$Hive, [string]$Key, [string]$Name)
    $path = "$Hive`:\$Key"
    $existed = $false; $old = $null; $type = 'DWord'
    if (Test-Path $path) {
        $k = Get-Item $path
        if ($k.GetValueNames() -contains $Name) {
            $existed = $true; $old = $k.GetValue($Name)
            $type = $k.GetValueKind($Name).ToString()
        }
    }
    [pscustomobject]@{ Path = $path; Existed = $existed; Old = $old; Type = $type }
}

function Invoke-RegistryAction {
    param($Action, $Journal, [switch]$DryRun)
    $orig = Get-RegOriginal -Hive $Action.hive -Key $Action.key -Name $Action.name
    Add-Record $Journal 'registry' @{
        hive = $Action.hive; key = $Action.key; name = $Action.name
        existed = $orig.Existed; old = $orig.Old; type = $Action.type
    }
    if ($DryRun) { return @{ Status = 'would'; Detail = "$($Action.hive)\$($Action.name) = $($Action.value)" } }

    if (-not (Test-Path $orig.Path)) { New-Item -Path $orig.Path -Force | Out-Null }
    New-ItemProperty -Path $orig.Path -Name $Action.name -Value $Action.value `
        -PropertyType $Action.type -Force -ErrorAction Stop | Out-Null

    # Verify by reading back: a few Windows keys accept writes but silently drop them.
    $k = Get-Item $orig.Path -ErrorAction Stop
    if ($k.GetValueNames() -contains $Action.name) {
        return @{ Status = 'ok'; Detail = "$($Action.hive)\$($Action.name) = $($Action.value)" }
    }
    return @{ Status = 'protected'; Detail = "key accepted the write but dropped it" }
}

function Invoke-ServiceAction {
    param($Action, $Journal, [switch]$DryRun)
    $svc = Get-Service -Name $Action.name -ErrorAction SilentlyContinue
    if (-not $svc) { return @{ Status = 'absent'; Detail = 'service not installed' } }

    $oldStart = $svc.StartType.ToString()
    $oldStatus = $svc.Status.ToString()
    Add-Record $Journal 'service' @{ name = $Action.name; oldStart = $oldStart.ToLower(); oldStatus = $oldStatus }

    if ($DryRun) { return @{ Status = 'would'; Detail = "$oldStart -> $($Action.startType)" } }

    if ($svc.Status -eq 'Running' -and $Action.startType -eq 'Disabled') {
        Stop-Service -Name $Action.name -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 300
    }
    & sc.exe config $Action.name start= ($Action.startType.ToLower()) | Out-Null

    $after = Get-Service -Name $Action.name -ErrorAction SilentlyContinue
    if ($after -and $after.StartType.ToString() -eq $Action.startType) {
        return @{ Status = 'ok'; Detail = "$oldStart -> $($Action.startType)" }
    }
    return @{ Status = 'protected'; Detail = "still $($after.StartType)" }
}

function Invoke-TaskAction {
    param($Action, $Journal, [switch]$DryRun)
    $t = Get-ScheduledTask -TaskPath $Action.path -TaskName $Action.name -ErrorAction SilentlyContinue
    if (-not $t) { return @{ Status = 'absent'; Detail = 'task not found' } }

    Add-Record $Journal 'task' @{ path = $Action.path; name = $Action.name; oldState = $t.State.ToString() }
    if ($DryRun) { return @{ Status = 'would'; Detail = "disable $($Action.name)" } }

    try {
        Disable-ScheduledTask -TaskPath $Action.path -TaskName $Action.name -ErrorAction Stop | Out-Null
    } catch {
        return @{ Status = 'protected'; Detail = $_.Exception.Message }
    }
    $after = Get-ScheduledTask -TaskPath $Action.path -TaskName $Action.name
    if ($after.State.ToString() -eq 'Disabled') { return @{ Status = 'ok'; Detail = 'disabled' } }
    return @{ Status = 'protected'; Detail = "still $($after.State)" }
}

function Invoke-AppxAction {
    param($Action, $Journal, [switch]$DryRun)
    $pkgs = @(Get-AppxPackage -Name $Action.name -AllUsers -ErrorAction SilentlyContinue)
    $prov = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
              Where-Object { $_.DisplayName -eq $Action.name })

    if ($pkgs.Count -eq 0 -and $prov.Count -eq 0) {
        return @{ Status = 'absent'; Detail = 'not installed' }
    }
    if ($DryRun) {
        return @{ Status = 'would'; Detail = "uninstall $($pkgs.Count) pkg(s), revoke $($prov.Count) provision(s)" }
    }

    $removed = 0; $revoked = 0; $errors = @()
    foreach ($p in $pkgs) {
        Add-Record $Journal 'appx' @{ name = $Action.name; full = $p.PackageFullName }
        try { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop; $removed++ }
        catch { $errors += $_.Exception.Message }
    }
    foreach ($p in $prov) {
        try { Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null; $revoked++ }
        catch { $errors += $_.Exception.Message }
    }
    $detail = "removed=$removed revoked=$revoked"
    if ($errors.Count -gt 0) { return @{ Status = 'partial'; Detail = "$detail errors=$($errors.Count)" } }
    return @{ Status = 'ok'; Detail = $detail }
}

function Invoke-PathCleanAction {
    param($Action, $Journal, [switch]$DryRun)
    $freed = 0; $count = 0; $touched = 0
    foreach ($raw in $Action.paths) {
        $p = [Environment]::ExpandEnvironmentVariables($raw)
        if (-not (Test-Path $p)) { continue }
        $files = @(Get-ChildItem -Path $p -File -Recurse -ErrorAction SilentlyContinue)
        if ($files.Count -eq 0) { continue }
        $size = ($files | Measure-Object -Property Length -Sum).Sum
        Add-Record $Journal 'path-clean' @{ path = $p; files = $files.Count; bytes = $size }
        if ($DryRun) { $freed += $size; $count += $files.Count; $touched++; continue }
        $files | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        $freed += $size; $count += $files.Count; $touched++
    }
    $mb = [math]::Round($freed / 1MB, 1)
    if ($touched -eq 0) { return @{ Status = 'absent'; Detail = 'nothing cached' } }
    $verb = if ($DryRun) { 'would free' } else { 'freed' }
    return @{ Status = 'ok'; Detail = "$verb $mb MB ($count files)" }
}

function Invoke-OneDriveAction {
    param($Journal, [switch]$DryRun)

    # Safety rail: refuse if the user's Desktop/Documents are redirected into OneDrive.
    $shellFolders = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    foreach ($prop in 'Desktop', 'Personal') {
        $val = [Environment]::ExpandEnvironmentVariables($shellFolders.$prop)
        if ($val -match 'OneDrive') {
            return @{ Status = 'refused'; Detail = "$prop is redirected into OneDrive - fix that first" }
        }
    }

    $binDirs = @("$env:LOCALAPPDATA\Microsoft\OneDrive", "$env:ProgramFiles\Microsoft OneDrive")
    $dataDir = Join-Path $env:USERPROFILE 'OneDrive'

    if ($DryRun) {
        return @{ Status = 'would'; Detail = "remove binaries; keep data folder $dataDir" }
    }

    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Add-Record $Journal 'onedrive' @{ dataDir = $dataDir; action = 'binaries removed' }

    $freed = 0
    foreach ($d in $binDirs) {
        if (-not (Test-Path $d)) { continue }
        $size = (Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue
        $freed += $size
    }
    # Block reinstall + sync at machine level.
    $pol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'
    if (-not (Test-Path $pol)) { New-Item -Path $pol -Force | Out-Null }
    New-ItemProperty -Path $pol -Name 'DisableFileSyncNGSC' -Value 1 -PropertyType DWord -Force | Out-Null

    $mb = [math]::Round($freed / 1MB, 1)
    $kept = if (Test-Path $dataDir) { 'data folder untouched' } else { 'no data folder' }
    return @{ Status = 'ok'; Detail = "removed ${mb}MB, $kept" }
}

function Invoke-Action {
    param($Action, $Journal, [switch]$DryRun)
    switch ($Action.target) {
        'registry'   { Invoke-RegistryAction    -Action $Action -Journal $Journal -DryRun:$DryRun }
        'service'    { Invoke-ServiceAction     -Action $Action -Journal $Journal -DryRun:$DryRun }
        'task'       { Invoke-TaskAction        -Action $Action -Journal $Journal -DryRun:$DryRun }
        'appx'       { Invoke-AppxAction        -Action $Action -Journal $Journal -DryRun:$DryRun }
        'path-clean' { Invoke-PathCleanAction   -Action $Action -Journal $Journal -DryRun:$DryRun }
        'onedrive'   { Invoke-OneDriveAction    -Journal $Journal -DryRun:$DryRun }
        default      { @{ Status = 'unknown'; Detail = "unsupported target '$($Action.target)'" } }
    }
}

# --------------------------------------------------------------------------
# Restore points
# --------------------------------------------------------------------------
function Get-RestorePoints {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification = 'Returns a collection of restore points; a private helper, not a cmdlet.')]
    param()
    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop) { $desktop = $env:USERPROFILE }
    , @(Get-ChildItem -Path $desktop -Directory -Filter 'WinCleanKit-*' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)
}

function Show-RestorePoints {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification = 'Lists a collection of restore points; a private helper, not a cmdlet.')]
    param()
    $points = Get-RestorePoints
    if ($points.Count -eq 0) { Write-Info "No restore points found on the Desktop."; return }
    Write-Head "Restore points"
    foreach ($p in $points) {
        $hasBackup = Test-Path (Join-Path $p.FullName 'backup.json')
        Write-Ink ("  " + (Format-Text $p.Name 34)) 'accent' -NoNewline
        Write-Ink ("  " + $p.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) 'muted'
        Write-Dim ("    restore : {0}" -f $(if ($hasBackup) { Join-Path $p.FullName 'Restore-WinCleanKit.ps1' } else { 'incomplete' }))
    }
}

# --------------------------------------------------------------------------
# UI plumbing for the .bat front-end
# --------------------------------------------------------------------------
function Write-CatalogJson {
    $cat = Get-Catalog
    $cat | ConvertTo-Json -Depth 10
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Interactive mode
# --------------------------------------------------------------------------

function Open-InteractiveSession {
    <#
      Load the TUI libraries and run one interactive session.

      Returns the confirmed plan as a list of action ids, or $null when the user
      quit. Falls back to $null (and says so) when the console cannot support a
      full-screen interface, so the caller can degrade instead of crashing.
    #>
    [CmdletBinding()]
    param([string]$TuiPreset)

    $result = Show-TuiSession -Catalog (Get-Catalog) -Engine $PSCommandPath `
                         -Preset $TuiPreset -Language $TuiLanguage

    if (-not $result) { return $null }
    return $result
}

# --------------------------------------------------------------------------
# Optional interactive UI
#
# The TUI lives in three library files. They are dot-sourced here, at script
# scope, and only when interactive mode is actually requested: dot-sourcing from
# inside a function would bind every definition to that function's scope, which is
# why the load cannot live in Open-InteractiveSession.
# --------------------------------------------------------------------------
if ($Tui -and -not $NoTui) {
    foreach ($f in 'Tui.Logic.ps1', 'Tui.Render.ps1', 'Tui.Input.ps1') {
        $comp = Join-Path $PSScriptRoot (Join-Path 'lib' $f)
        if (-not (Test-Path $comp)) { throw "TUI component missing: $comp" }
        . $comp
    }
}

try {
    if ($Version) { Write-Output "WinCleanKit engine $script:EngineVersion"; return }
    if ($ListCatalog) { Write-CatalogJson; return }
    if ($ListRestores) { Show-RestorePoints; return }
    if ($Restore) {
        $points = Get-RestorePoints | Where-Object { $_.Name -eq $Restore -or $_.FullName -eq $Restore }
        if (-not $points) { throw "Restore point not found: $Restore" }
        $scriptFile = Join-Path $points[0].FullName 'Restore-WinCleanKit.ps1'
        if (-not (Test-Path $scriptFile)) { throw "No restore script in $($points[0].FullName)" }
        Write-Info "Running restore: $scriptFile"
        & $scriptFile
        return
    }

    # Interactive mode. Runs before any selection is resolved, and hands its
    # result to the same resolution/execution path as every other mode rather than
    # duplicating preview, apply or backup logic.
    if ($Tui -and -not $NoTui) {
        $tuiPlan = Open-InteractiveSession -TuiPreset $TuiPreset
        if (-not $tuiPlan) {
            if ($TuiExitCode) {
                # 3 means "this console cannot draw the TUI"; the front-end then
                # falls back to the numbered menu. 0 means the user quit.
                exit $(if ($script:TuiOutcome) { $script:TuiOutcome } else { 0 })
            }
            Write-Info 'Nothing selected; no changes were made.'
            return
        }
        $Only = @($tuiPlan)
        $Preset = $TuiPreset
        $Language = $TuiLanguage
    }

    $catalog = Get-Catalog

    # -FromFile: one action id per line. The .bat front-end uses this to hand over
    # an already-resolved selection without wrestling with commas and quoting on a
    # 60-item command line.
    if ($FromFile) {
        if (-not (Test-Path $FromFile)) { throw "Selection file not found: $FromFile" }
        $fromFileIds = @(Get-Content $FromFile -Encoding UTF8 |
                         ForEach-Object { $_.Trim() } |
                         Where-Object { $_ -and -not $_.StartsWith('#') })
        if ($fromFileIds.Count -eq 0) { throw "Selection file is empty: $FromFile" }
        if ($Only.Count -eq 0) { $Only = $fromFileIds }
        else { $Only = @($Only) + $fromFileIds }
    }

    $actions = Resolve-Plan -Catalog $catalog -PresetName $Preset -OnlyList $Only -SkipList $Skip

    if ($actions.Count -eq 0) {
        Write-Warn2 "Nothing selected — the resolved plan is empty."
        return
    }

    Write-Head "WinCleanKit $script:EngineVersion"
    Write-Info ("Preset   : {0}" -f $Preset)
    Write-Info ("Selected : {0} action(s)" -f $actions.Count)
    Write-Info ("Mode     : {0}" -f $(if ($Apply -and -not $DryRun) { 'APPLY' } else { 'PREVIEW ONLY' }))
    Show-Plan -Catalog $catalog -Actions $actions

    if ($Plan -or -not $Apply) {
        Write-Host ''
        Write-Warn2 "Preview only — nothing was changed. Add -Apply to execute."
        return
    }

    if (-not $NoPrompt) {
        Write-Host ''
        $answer = Read-Host "  Type APPLY to execute these $($actions.Count) action(s)"
        if ($answer -ne 'APPLY') { Write-Warn2 "Cancelled."; return }
    }

    $journal = Initialize-Journal -PresetName $Preset -Actions $actions
    Write-Host ''
    Write-Head $(if ($DryRun) { 'Dry run' } else { 'Applying changes' })
    if ($DryRun) {
        Write-Info "Dry run: nothing will be written, no backup folder will be created."
    } else {
        Write-Info "Backup / restore : $($journal.Dir)"
    }

    $groups = Group-PlanByCategory -Catalog $catalog -Actions $actions
    # Progress counter: a 74-action run must never look frozen.
    Initialize-Progress -Total $actions.Count
    foreach ($cid in $groups.Keys) {
        $cat = $catalog.categories | Where-Object { $_.id -eq $cid }
        Write-Host ''
        Write-Ink ("  " + (L $cat 'name')) 'accent'
        foreach ($a in $groups[$cid]) {
            $label = L $a 'title'
            try {
                $r = Invoke-Action -Action $a -Journal $journal -WhatIf:$DryRun
                $msg = "{0} — {1}" -f $label, $r.Detail
                # One vocabulary, and the text marker carries the meaning so
                # nothing depends on colour: ok / dry / -- / !! / XX.
                $prefix = Get-ProgressPrefix
                switch ($r.Status) {
                    'ok'        { Write-Status 'ok'   ($prefix + $msg); $script:CountOk++ }
                    'would'     { Write-Status 'dry'  ($prefix + $msg); $script:CountOk++ }
                    'absent'    { Write-Status 'skip' ($prefix + $msg); $script:CountSkip++ }
                    'partial'   { Write-Status 'warn' ($prefix + $msg); $script:CountSkip++ }
                    'refused'   { Write-Status 'warn' ($prefix + $msg); $script:CountSkip++ }
                    'protected' { Write-Status 'warn' ($prefix + $msg); $script:CountSkip++ }
                    default     { Write-Status 'warn' ($prefix + $msg); $script:CountSkip++ }
                }
                Write-Journal -Log $journal.Log -Message "$($r.Status)`t$($a.id)`t$($r.Detail)"
                if ($r.Status -in @('partial', 'refused', 'protected', 'unknown')) {
                    $script:Failures += "$($a.id): $($r.Detail)"
                }
                if ($r.Status -eq 'protected') { $script:CountFail++ }
            } catch {
                Write-Status 'fail' ((Get-ProgressPrefix) + ("{0} — {1}" -f $label, $_.Exception.Message))
                Write-Journal -Log $journal.Log -Message "error`t$($a.id)`t$($_.Exception.Message)"
                $script:CountFail++
                $script:Failures += "$($a.id): $($_.Exception.Message)"
            }
        }
    }

    Write-Host ''
    Write-Head "Summary"
    Write-Info ("Applied / would apply : {0}" -f $script:CountOk)
    Write-Info ("Skipped (N/A or protected) : {0}" -f $script:CountSkip)
    Write-Info ("Failed : {0}" -f $script:CountFail)

    if (-not $DryRun) {
        # Save-Journal creates the run directory and then we can log into it.
        Save-Journal -Journal $journal
        Write-Journal -Log $journal.Log -Message "done ok=$($script:CountOk) skipped=$($script:CountSkip) failed=$($script:CountFail)"
        Write-Info ("Log    : {0}" -f $journal.Log)
        Write-Info ("Restore: {0}" -f $journal.Restore)
        Write-Host ''
        Write-Warn2 "A restore script was written next to the log. Keep that folder until you are happy."
    } else {
        Write-Info "Dry run: no backup folder was created and nothing was changed."
    }

    if ($EmitJson) {
        [pscustomobject]@{
            ok = $script:CountOk; skipped = $script:CountSkip; failed = $script:CountFail
            journal = $journal.Dir; failures = $script:Failures
        } | ConvertTo-Json -Depth 5
    }
}
catch {
    Write-Bad $_.Exception.Message
    exit 1
}
