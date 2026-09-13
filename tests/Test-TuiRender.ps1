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
        # Exact, not "at least": one row more than the terminal and the alternate
        # screen buffer scrolls on every repaint.
        Check "frame has exactly $h rows for ${w}x${h} ($lang)" ($frame.Count -eq $h) ("{0} rows" -f $frame.Count)
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
Write-Head 'exactly one pane shows the focus arrow'
# Both panes used to draw '>' on their cursor row at the same time, so the frame
# showed two focus markers and no way to tell which pane the keyboard was in.
function Get-LeftCell  { param([string]$Line, [int]$LeftWidth) $Line.Substring(1, $LeftWidth) }
function Get-RightCell { param([string]$Line, [int]$LeftWidth) $Line.Substring($LeftWidth + 2) }
function Get-LeftWidth { param([int]$Width) [Math]::Max(24, [int](($Width - 2) * 0.38)) }
function Get-DetailRow {
    # The detail block is the only place the risk tag appears.
    param([string[]]$Frame, [int]$LeftWidth)
    for ($i = 0; $i -lt $Frame.Count; $i++) {
        if ((Get-RightCell $Frame[$i] $LeftWidth) -match '\[(low|medium|high)\]\s*\|?$') { return $i }
    }
    return -1
}
$lw = Get-LeftWidth 100
foreach ($pane in 'list', 'detail') {
    $st = Initialize-TuiState -Catalog $cat -Preset 'balanced' -Language 'en'
    $st.Pane = $pane; $st.Mode = $pane
    $f = Get-TuiFrame -State $st -Width 100 -Height 30
    $marks = @()
    foreach ($line in $f) {
        $l = Get-LeftCell $line $lw
        $r = Get-RightCell $line $lw
        if ($l -match '^>') { $marks += 'left' }
        if ($r -match '^>') { $marks += 'right' }
    }
    Check "pane=$pane has exactly one arrow" ($marks.Count -eq 1) ($marks -join '+')
    $expected = if ($pane -eq 'list') { 'left' } else { 'right' }
    Check "pane=$pane arrow is in the focused pane" ($marks.Count -eq 1 -and $marks[0] -eq $expected) ($marks -join '+')
}

# ---------------------------------------------------------------------------
Write-Head 'the detail block never moves'
# It used to sit directly under the action list, so a category with one action put
# the detail near the top and a long one put it near the middle: the pane had no
# stable shape and the eye had to re-find it on every category change.
$rows = @()
foreach ($case in @(@(0, 0), @(0, 20), @(1, 0), @(2, 0))) {
    $st = Initialize-TuiState -Catalog $cat -Preset 'balanced' -Language 'en'
    $st.ListIndex = $case[0]; $st.DetailIndex = $case[1]
    $f = Get-TuiFrame -State $st -Width 100 -Height 30
    $rows += (Get-DetailRow $f $lw)
}
Check 'detail block found in every case' ((@($rows | Where-Object { $_ -lt 0 })).Count -eq 0) ($rows -join ',')
Check 'detail row is identical for every category and cursor' ((@($rows | Select-Object -Unique)).Count -eq 1) ("rows: " + ($rows -join ','))

# ---------------------------------------------------------------------------
Write-Head 'detail text wraps instead of being cut off'
$w = Get-TuiWrap -Text ('x' * 200) -Width 20 -Max 3
Check 'wrap respects the max row count' ($w.Count -eq 3) ("{0} rows" -f $w.Count)
Check 'wrap respects the width' ((@($w | Where-Object { (Get-WidthOf $_) -gt 20 }).Count) -eq 0) ($w -join '/')
Check 'a cut line is marked with an ellipsis' ($w[2].EndsWith([string][char]0x2026)) $w[2]
$w2 = Get-TuiWrap -Text 'short' -Width 20 -Max 3
Check 'text that fits is not ellipsised' ($w2.Count -eq 1 -and -not $w2[0].EndsWith([string][char]0x2026)) ($w2 -join '/')
$w3 = Get-TuiWrap -Text '' -Width 20 -Max 3
Check 'empty text wraps to nothing' ($w3.Count -eq 0) ("{0} rows" -f $w3.Count)
# Chinese is two columns wide, so a character-count wrap would overflow the pane.
$w4 = Get-TuiWrap -Text ('汉' * 40) -Width 21 -Max 5
Check 'cjk wrap respects the width' ((@($w4 | Where-Object { (Get-WidthOf $_) -gt 21 }).Count) -eq 0) (($w4 | ForEach-Object { Get-WidthOf $_ }) -join ',')

# The rationale must actually reach the screen: no blank rows below a cut sentence.
$st = Initialize-TuiState -Catalog $cat -Preset 'aggressive' -Language 'en'
$st.ListIndex = 0; $st.DetailIndex = 0
$f = Get-TuiFrame -State $st -Width 120 -Height 34
$lw120  = Get-LeftWidth 120
$row    = Get-DetailRow $f $lw120
$rightW = (120 - 2) - $lw120 - 1
$why = Get-TuiText -Object (Get-TuiActionAt $st) -Base 'why' -Language 'en'
$wrapped = Get-TuiWrap -Text $why -Width $rightW -Max 2
Check 'rationale is wrapped across the rows it was given' ($wrapped.Count -ge 1) ("{0} rows, width {1}" -f $wrapped.Count, $rightW)
Check 'wrapped rationale appears verbatim in the frame' ((Get-RightCell $f[$row + 1] $lw120).TrimEnd('|').Trim() -eq $wrapped[0]) $wrapped[0]
Check 'no blank row sits between the rationale rows' ($wrapped.Count -lt 2 -or (Get-RightCell $f[$row + 2] $lw120).Trim().Trim('|') -ne '') 'second rationale row is used'

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
    Check "help frame is exactly 30 rows ($lang)" ($f.Count -eq 30) ("{0} rows" -f $f.Count)
    $joined = $f -join "`n"
    Check "help lists the apply key ($lang)" ($joined -match '\bx\b') 'apply key documented'
    # The help page spans both panes, so its border rules must not carry the
    # junction that joins the vertical divider in the two-pane view.
    $junction = @($f | Where-Object { $_ -match '^\+\-+\+\-+\+$' })
    Check "help border has no pane junction ($lang)" ($junction.Count -eq 0) 'rules span the full inner width'
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
