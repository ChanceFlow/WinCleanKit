<#
.SYNOPSIS
    Frame-rendering tests for the TUI. Changes nothing, needs no terminal.

.DESCRIPTION
    Tui.Render.ps1 builds frames as arrays of strings and does not draw them, so
    the layout can be verified without an interactive console. What is asserted:

      * every line of a frame is exactly the requested width (width-aware, CJK included)
      * the frame has the requested number of lines, and the box corners line up
      * the detail panel actually describes the focused action
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
Write-Head 'the detail panel describes the focused action'
$st = Initialize-TuiState -Catalog $cat -Preset 'aggressive' -Language 'en'
$st.ListIndex = 0
$st.DetailIndex = 0
$st.Pane = 'detail'; $st.Mode = 'detail'
$focus = Get-TuiActionAt $st
$frame = Get-TuiFrame -State $st -Width 120 -Height 34
$joined = $frame -join "`n"
Check 'detail shows the focused title' ($joined.Contains($focus.title)) $focus.id
Check 'detail shows why' ($joined.Contains((Get-TuiText -Object $focus -Base 'why' -Language 'en').Substring(0, 24))) 'why text present'
$hasTarget = ($joined -match 'HKCU|HKLM|service |task |uninstall ') -or $focus.target -eq 'onedrive'
Check 'detail shows the target' $hasTarget ("target=" + $focus.target)

# When the category list is focused on the left, the detail panel shows the
# category's overview rather than jumping straight to a specific action.
$stCat = Initialize-TuiState -Catalog $cat -Preset 'aggressive' -Language 'en'
$stCat.ListIndex = 0
$stCat.Pane = 'list'; $stCat.Mode = 'list'
$frameCat = Get-TuiFrame -State $stCat -Width 120 -Height 34
$joinedCat = $frameCat -join "`n"
Check 'detail shows category title' ($joinedCat.Contains('Ads & suggestions'))
Check 'detail shows category description' ($joinedCat.Contains("Turns off commercial promotions"))

# ---------------------------------------------------------------------------
Write-Head 'exactly one pane shows the focus arrow'
# Both panes used to draw '>' on their cursor row at the same time, so the frame
# showed two focus markers and no way to tell which pane the keyboard was in.
function Get-LeftCell  { param([string]$Line, [int]$LeftWidth) $Line.Substring(1, $LeftWidth) }
function Get-RightCell { param([string]$Line, [int]$LeftWidth) $Line.Substring($LeftWidth + 2) }
function Get-LeftWidth { param([int]$Width) [Math]::Max(24, [int](($Width - 2) * 0.42)) }
function Get-DetailPanelRow {
    # The panel's first row is its labelled divider. That row depends only on the
    # terminal size, which is exactly what "the panel never moves" means. Anchoring
    # on the risk tag instead would drift: a long title wraps, so the tag moves
    # inside the panel even though the panel itself does not.
    param([string[]]$Frame, [int]$LeftWidth)
    for ($i = 0; $i -lt $Frame.Count; $i++) {
        $l = Get-LeftCell $Frame[$i] $LeftWidth
        if ($l.Trim() -match '^(details|详情)') { return $i }
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
Write-Head 'the detail panel never moves'
# The panel's height depends only on the terminal size, never on the focused action
# or the category, so the boundary between the category list and the panel - and
# everything inside the panel - stays where the eye last found it.
$rows = @()
foreach ($case in @(@(0, 0), @(0, 20), @(1, 0), @(2, 0))) {
    $st = Initialize-TuiState -Catalog $cat -Preset 'balanced' -Language 'en'
    $st.ListIndex = $case[0]; $st.DetailIndex = $case[1]
    $f = Get-TuiFrame -State $st -Width 100 -Height 30
    $rows += (Get-DetailPanelRow $f $lw)
}
Check 'the panel is found in every case' ((@($rows | Where-Object { $_ -lt 0 })).Count -eq 0) ($rows -join ',')
Check 'the panel row is identical for every category and cursor' ((@($rows | Select-Object -Unique)).Count -eq 1) ("rows: " + ($rows -join ','))

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
$st.Pane = 'detail'; $st.Mode = 'detail'
$f = Get-TuiFrame -State $st -Width 120 -Height 34
$lw120 = Get-LeftWidth 120
$panelRow = Get-DetailPanelRow $f $lw120
$why = Get-TuiText -Object (Get-TuiActionAt $st) -Base 'why' -Language 'en'
$whyRows = Get-TuiWrap -Text $why -Width $lw120 -Max 12
Check 'the rationale is rendered inside the detail panel' ($panelRow -ge 0 -and $whyRows.Count -ge 1) ("{0} rows at width {1}" -f $whyRows.Count, $lw120)
# Find the row the rationale actually landed on rather than counting the title
# rows: a long title wraps, and what matters is that the text arrives intact.
$whyRow = -1
for ($i = $panelRow + 1; $i -lt $f.Count; $i++) {
    if ((Get-LeftCell $f[$i] $lw120).Trim() -eq $whyRows[0].Trim()) { $whyRow = $i; break }
}
Check 'the rationale starts verbatim in the frame' ($whyRow -gt $panelRow) ("row {0}, panel starts at {1}" -f $whyRow, $panelRow)
Check 'no blank row sits between the rationale rows' ($whyRows.Count -lt 2 -or ($whyRow -ge 0 -and (Get-LeftCell $f[$whyRow + 1] $lw120).Trim() -ne '')) 'second rationale row is used'

# The right column is a plain list now: it must have no risk tag and no divider
# junction, so nothing in it can change shape when the cursor moves.
$rightHasTag = @($f | Where-Object { (Get-RightCell $_ $lw120) -match '\[(low|medium|high)\]' })
Check 'the action column carries no detail text' ($rightHasTag.Count -eq 0) ("{0} rows" -f $rightHasTag.Count)
$rightListRows = @($f | Where-Object { (Get-RightCell $_ $lw120) -match '^\s*[>\- ]\s*\[[ x]\]' })
Check 'the action column is a list the whole way down' ($rightListRows.Count -ge 20) ("{0} item rows of {1} body rows" -f $rightListRows.Count, (34 - 9))

# ---------------------------------------------------------------------------
Write-Head 'the detail panel sits under the categories'
$f = Get-TuiFrame -State $st -Width 120 -Height 34
$dividerRow = Get-DetailPanelRow $f $lw120
Check 'the panel divider carries a label' ($dividerRow -ge 0) ("row {0}" -f $dividerRow)
Check 'the divider joins the outer border and the vertical divider' ($dividerRow -ge 0 -and $f[$dividerRow][0] -eq '+' -and $f[$dividerRow][$lw120 + 1] -eq '+') 'both ends are junctions'
Check 'the divider is inside the body, with the category column above it' ($dividerRow -gt 5 -and $f[$dividerRow - 1].StartsWith('|')) ("row {0}" -f $dividerRow)
Check 'the action column carries on across the divider' ($dividerRow -ge 0 -and (Get-RightCell $f[$dividerRow] $lw120) -match '\[[ x]\]') 'the list does not break at the divider'

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
Write-Head 'the opening language chooser'
$ask = Initialize-TuiState -Catalog $cat -Preset 'balanced' -Language 'ask'
foreach ($size in @(@(80, 24), @(100, 30), @(120, 40), @(60, 18))) {
    $w = $size[0]; $h = $size[1]
    $f = Get-TuiFrame -State $ask -Width $w -Height $h
    $bad = @($f | Where-Object { (Get-WidthOf $_) -ne $w })
    Check "chooser is $w wide ($w x $h)" ($bad.Count -eq 0) ("{0} bad of {1}" -f $bad.Count, $f.Count)
    Check "chooser is exactly $h rows ($w x $h)" ($f.Count -eq $h) ("{0} rows" -f $f.Count)
}
$f = Get-TuiFrame -State $ask -Width 100 -Height 30
$joined = $f -join "`n"
Check 'the chooser names both languages' ($joined.Contains('中文') -and $joined.Contains('English')) 'both options listed'
Check 'the chooser states the question twice' ($joined.Contains('请选择界面语言') -and $joined.Contains('Choose your language')) 'bilingual'
Check 'the chooser marks the current option' ((@($f | Where-Object { $_ -match '> 1\. 中文' })).Count -eq 1) 'cursor on the first entry'
$askDown = Move-TuiLanguageCursor -State $ask -Direction 'down'
$f2 = Get-TuiFrame -State $askDown -Width 100 -Height 30
Check 'the cursor follows the arrow key' ((@($f2 | Where-Object { $_ -match '> 2\. English' })).Count -eq 1) 'cursor moved'
Check 'the chooser never reaches more rows than the terminal' ($f.Count -le 30) 'no scroll risk'

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
$esc = [char]27

# This is the contract that keeps the screen still. A line feed after the last
# row, or a full-width row reaching the wrap margin, makes the console advance
# past the bottom line, and that advance scrolls the screen -- the interface then
# creeps or jumps on every keypress. So: absolute positioning, no newlines.
Check 'painted frame contains no line feed' (-not ($packed.Contains("`n") -or $packed.Contains("`r"))) 'no CR, no LF'
Check 'painted frame never erases to end of line' (-not $packed.Contains("$esc[K")) 'ESC[K from the last column would rub out that row''s final character'
$perRow = 0
for ($i = 1; $i -le $frameLines.Count; $i++) { if ($packed.Contains("$esc[$i;1H")) { $perRow++ } }
Check 'every row is positioned absolutely' ($perRow -eq $frameLines.Count) ("{0}/{1} rows" -f $perRow, $frameLines.Count)
Check 'the first row is positioned at the top left' ($packed.Contains("$esc[1;1H")) 'row 1 column 1'
Check 'frame hides and restores the cursor' ($packed.Contains("$esc[?25l") -and $packed.Contains("$esc[?25h"))
$withNewline = @($frameLines | Where-Object { $_.Contains("`n") -or $_.Contains("`r") })
Check 'no cell contains a raw newline' ($withNewline.Count -eq 0) ("{0} cells" -f $withNewline.Count)

# The console flags that make drawing a full-width row safe in the first place.
$mode = Get-TuiConsoleMode -Current ([uint32]0x0003)     # ANSI off, wrap on
Check 'console mode enables ANSI' (($mode -band 0x0004) -ne 0) ("0x{0:X}" -f $mode)
Check 'console mode disables newline auto return' (($mode -band 0x0008) -ne 0) ("0x{0:X}" -f $mode)
Check 'console mode clears wrap at end of line' (($mode -band 0x0002) -eq 0) ("0x{0:X}" -f $mode)
Check 'console mode leaves unrelated flags alone' (((Get-TuiConsoleMode -Current ([uint32]0x0010)) -band 0x0010) -ne 0) 'bit 4 preserved'
$mode2 = Get-TuiConsoleMode -Current ([uint32]0x0004)
Check 'console mode is idempotent' ($mode2 -eq (Get-TuiConsoleMode -Current $mode2)) ("0x{0:X}" -f $mode2)

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
