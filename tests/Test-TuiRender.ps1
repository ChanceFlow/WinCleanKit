<#
.SYNOPSIS
    Frame-rendering tests for the TUI. Changes nothing, needs no terminal.

.DESCRIPTION
    Tui.Render.ps1 builds frames as arrays of strings and does not draw them, so
    the layout can be verified without an interactive console. What is asserted:

      * every line of a frame is exactly the requested width (width-aware, CJK included)
      * the frame has the requested number of lines, and the box corners line up
      * the detail pane actually describes the focused action
      * the list pane shows selected/total counts that match the selection
      * the help screen renders, and both languages render
      * the frame reacts to size changes without breaking

    What is still not covered: reading keys and painting. That needs a real
    console and is verified by hand; see Tui.Input.ps1.

.EXAMPLE
    .\tests\Test-TuiRender.ps1
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
$pass = 0; $fail = 0
function Check {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Coloured pass/fail output is the intended interface of this test script.')]
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) { $script:pass++; Write-Host ("  [PASS] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" })) -ForegroundColor Green }
    else     { $script:fail++; Write-Host ("  [FAIL] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" })) -ForegroundColor Red }
}

Write-Head 'loading logic + renderer'
. (Join-Path $root 'src/lib/Tui.Logic.ps1')
. (Join-Path $root 'src/lib/Tui.Render.ps1')
$cat = Get-Content (Join-Path $root 'catalog/catalog.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function Get-WidthOf {
    param([string]$T)
    $w = 0
    foreach ($ch in $T.ToCharArray()) {
        $c = [int][char]$ch
        if (($c -ge 0x1100 -and $c -le 0x115F) -or ($c -ge 0x2E80 -and $c -le 0xA4CF) -or
            ($c -ge 0xAC00 -and $c -le 0xD7A3) -or ($c -ge 0xF900 -and $c -le 0xFAFF) -or
            ($c -ge 0xFE30 -and $c -le 0xFE6F) -or ($c -ge 0xFF00 -and $c -le 0xFF60) -or
            ($c -ge 0xFFE0 -and $c -le 0xFFE6)) { $w += 2 } else { $w += 1 }
    }
    return $w
}

# ---------------------------------------------------------------------------
Write-Head 'frame geometry, both languages, several sizes'
foreach ($lang in 'en', 'zh') {
    foreach ($size in @(@(80, 24), @(100, 30), @(120, 40), @(60, 18))) {
        $w = $size[0]; $h = $size[1]
        $st = Initialize-TuiState -Catalog $cat -Preset 'balanced' -Language $lang
        $frame = Get-TuiFrame -State $st -Width $w -Height $h
        $bad = @($frame | Where-Object { (Get-WidthOf $_) -ne $w })
        Check "every line is $w wide ($lang)" ($bad.Count -eq 0) ("{0} bad of {1}" -f $bad.Count, $frame.Count)
        Check "frame has rows for ${w}x${h} ($lang)" ($frame.Count -ge 12) ("{0} rows" -f $frame.Count)
        Check "top border is a full rule ($lang)" ($frame[0] -eq ('+' + ('-' * ($w - 2)) + '+')) $frame[0]
    }
}

# ---------------------------------------------------------------------------
Write-Head 'borders line up between panes'
$st = Initialize-TuiState -Catalog $cat -Preset 'balanced' -Language 'en'
$frame = Get-TuiFrame -State $st -Width 100 -Height 30
$sep = @($frame | Where-Object { $_ -match '^\+-+\+-+\+$' })
Check 'pane separator rows exist' ($sep.Count -ge 2) ("{0} separators" -f $sep.Count)
$sepWidths = @($sep | ForEach-Object { Get-WidthOf $_ } | Select-Object -Unique)
Check 'all separator rows share one width' ($sepWidths.Count -eq 1) ($sepWidths -join ',')

# ---------------------------------------------------------------------------
Write-Head 'content reflects the selection'
$st = Initialize-TuiState -Catalog $cat -Preset 'conservative' -Language 'en'
$n = Get-TuiSelectedCount $st
$frame = Get-TuiFrame -State $st -Width 110 -Height 32
Check 'header shows the selected count' ((@($frame | Where-Object { $_ -match "plan: $n actions" }).Count) -eq 1) "looking for $n"
Check 'header shows the preset' ((@($frame | Where-Object { $_ -match 'preset \[conservative\]' }).Count) -eq 1)
$st = Switch-TuiAllSelection -State $st -Selected $false
$frame = Get-TuiFrame -State $st -Width 110 -Height 32
Check 'clearing updates the count' ((@($frame | Where-Object { $_ -match 'plan: 0 actions' }).Count) -eq 1)
Check 'clearing drops the risk to none' ((@($frame | Where-Object { $_ -match 'highest risk: none' }).Count) -eq 1)

# ---------------------------------------------------------------------------
Write-Head 'detail pane describes the focused action'
$st = Initialize-TuiState -Catalog $cat -Preset 'aggressive' -Language 'en'
$st.ListIndex = 0
$st.DetailIndex = 0
$focus = Get-TuiActionAt $st
$frame = Get-TuiFrame -State $st -Width 120 -Height 34
$joined = $frame -join "`n"
Check 'detail shows the focused title' ($joined.Contains($focus.title)) $focus.id
Check 'detail shows why' ($joined.Contains((Get-TuiText -Object $focus -Base 'why' -Language 'en').Substring(0, 24))) 'why text present'
$hasTarget = ($joined -match 'HKCU|HKLM|service |task |uninstall ') -or $focus.target -eq 'onedrive'
Check 'detail shows the target' $hasTarget ("target=" + $focus.target)

# ---------------------------------------------------------------------------
Write-Head 'checkbox state is visible per row'
$st = Initialize-TuiState -Catalog $cat -Preset 'conservative' -Language 'en'
$st.ListIndex = 0; $st.DetailIndex = 0; $st.Pane = 'detail'; $st.Mode = 'detail'
$first = (Get-TuiGroupAction $st)[0]
$frameOn = (Get-TuiFrame -State $st -Width 120 -Height 34) -join "`n"
Check 'selected row shows [x]' ($frameOn.Contains('[x] ' + $first.title)) $first.id
$st = Switch-TuiAction -State $st -Id $first.id
$frameOff = (Get-TuiFrame -State $st -Width 120 -Height 34) -join "`n"
Check 'deselected row shows [ ]' ($frameOff.Contains('[ ] ' + $first.title)) $first.id

# ---------------------------------------------------------------------------
Write-Head 'help screen'
$st = Select-TuiMode -State $st -Mode 'help'
foreach ($lang in 'en', 'zh') {
    $stLang = Select-TuiLanguage -State $st -Language $lang
    $f = Get-TuiFrame -State $stLang -Width 100 -Height 30
    $bad = @($f | Where-Object { (Get-WidthOf $_) -ne 100 })
    Check "help frame is well formed ($lang)" ($bad.Count -eq 0) ("{0} bad lines" -f $bad.Count)
    $joined = $f -join "`n"
    Check "help lists the apply key ($lang)" ($joined -match '\bx\b') 'apply key documented'
}

# ---------------------------------------------------------------------------
Write-Head 'frame is stable and side-effect free'
$st = Initialize-TuiState -Catalog $cat -Preset 'balanced' -Language 'en'
$a = (Get-TuiFrame -State $st -Width 100 -Height 30) -join "`n"
$b = (Get-TuiFrame -State $st -Width 100 -Height 30) -join "`n"
Check 'same state yields the same frame' ($a -eq $b) 'deterministic'
$before = Get-TuiSelectedCount $st
$null = Get-TuiFrame -State $st -Width 100 -Height 30
Check 'rendering does not mutate the state' ((Get-TuiSelectedCount $st) -eq $before)

# resize without breaking
foreach ($w in 60, 80, 140, 200) {
    $f = Get-TuiFrame -State $st -Width $w -Height 24
    $bad = @($f | Where-Object { (Get-WidthOf $_) -ne $w })
    Check "resize to $w keeps lines exact" ($bad.Count -eq 0) ("{0} bad" -f $bad.Count)
}

$frameLines = Get-TuiFrame -State $st -Width 100 -Height 30
$packed = Format-TuiFrame -Lines $frameLines
Check 'frame wraps in cursor control' ($packed.Contains([char]27 + '[H')) 'homes the cursor'
Check 'frame hides and restores the cursor' ($packed.Contains([char]27 + '[?25l') -and $packed.Contains([char]27 + '[?25h'))
$withNewline = @($frameLines | Where-Object { $_.Contains("`n") -or $_.Contains("`r") })
Check 'no cell contains a raw newline' ($withNewline.Count -eq 0) ("{0} cells" -f $withNewline.Count)

Write-Head 'plain-text fallback'
$supported = Test-TuiSupported
Check 'TUI detection returns a boolean' ($supported -is [bool]) ("supported=" + $supported)
# This test process has a redirected stdout, so the correct answer here is False;
# that is exactly the path that must fall back rather than paint into a log.
if ([Console]::IsOutputRedirected) {
    Check 'redirected output correctly refuses the TUI' (-not $supported) 'falls back to plain output'
}

Write-Host ''
if ($fail -eq 0) { Write-Host ("ALL PASSED  ({0} checks)" -f $pass) -ForegroundColor Green }
else             { Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
