<#
.SYNOPSIS
    Behaviour tests for the windowed frontend. Changes nothing, needs no desktop.

.DESCRIPTION
    The GUI has two halves, and both are testable without a screen:

      * the projection in Ui.Logic.ps1 (Get-Ui*) is pure, so its rows, counts,
        detail text and chrome strings can be checked exactly;
      * Initialize-GuiForm builds a real control tree but never shows it, so the
        shape of the window can be asserted headlessly.

    What this cannot cover, and does not pretend to: how the window looks, and
    whether the event wiring responds to a real mouse. Both are verified by hand in
    a real session, the same way the console key loop is.

    The important check here is parity. Two frontends drawing the same state is an
    invariant, not a hope: the tick marks the GUI lists must be the tick marks the
    console frame draws, for the same state. That check is then tested against a
    state it must reject, so a clean result cannot come from a comparison that
    detects nothing.

.EXAMPLE
    .\tests\Test-Gui.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$logic = Join-Path $root 'src/lib/Ui.Logic.ps1'
$render = Join-Path $root 'src/lib/Tui.Render.ps1'
$guiPath = Join-Path $root 'src/gui/WinCleanKit.gui.ps1'
$engine = Join-Path $root 'src/WinCleanKit.ps1'
$catalogPath = Join-Path $root 'catalog/catalog.json'

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

Check 'the shared logic layer exists' (Test-Path $logic) $logic
Check 'the GUI layer exists' (Test-Path $guiPath) $guiPath
Check 'the console renderer exists' (Test-Path $render) '(needed for the parity check)'

# ---------------------------------------------------------------------------
Write-Head 'loading the layers'
. $logic
. $render
. $guiPath
$cat = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json

$state = Initialize-TuiState -Catalog $cat -Language 'en'

# ---------------------------------------------------------------------------
Write-Head 'the view model'
$groups = @(Get-UiGroupRow -State $state)
Check 'one row per category' ($groups.Count -eq $cat.categories.Count) ("{0} rows" -f $groups.Count)
$sumTotal = @($groups | Measure-Object -Property total -Sum).Sum
$sumTicked = @($groups | Measure-Object -Property selected -Sum).Sum
$catalogTicked = @($cat.actions | Where-Object { $_.default }).Count
Check 'the per-category totals add up to the whole catalog' ($sumTotal -eq $cat.actions.Count) ("{0}" -f $sumTotal)
Check 'the per-category ticks match the catalog default set' ($sumTicked -eq $catalogTicked) ("{0} of {1}" -f $sumTicked, $catalogTicked)
Check 'exactly one category is marked as current' (@($groups | Where-Object { $_.current }).Count -eq 1)
Check 'a category row carries a localised name' ([bool]$groups[0].name)

$rows = @(Get-UiActionRow -State $state)
$firstGroup = @($cat.actions | Where-Object { $_.category -eq $groups[0].id }).Count
Check 'the action list shows the focused category' ($rows.Count -eq $firstGroup) ("{0} of {1}" -f $rows.Count, $firstGroup)
$tickedRows = @($rows | Where-Object { $_.checked }).Count
Check 'tick state comes from the selection, not the catalog' ($tickedRows -eq $groups[0].selected) ("{0}" -f $tickedRows)
Check 'the row ids are the catalog ids' (@($rows | Where-Object { -not ($cat.actions.id -contains $_.id) }).Count -eq 0) 'every row resolves'

$summary = Get-UiSummary -State $state
Check 'the summary counts the whole selection' ($summary.selected -eq 45 -and $summary.total -eq 74) $summary.title
Check 'the summary is the console header wording' ($summary.title -eq 'plan: 45 actions') $summary.title

$catDetail = Get-UiDetail -State $state
Check 'the category detail names the category' ($catDetail.kind -eq 'category' -and $catDetail.title.StartsWith('[')) $catDetail.title
Check 'the category detail explains the category' ([bool]$catDetail.body)
$state.Pane = 'detail'
$actDetail = Get-UiDetail -State $state
Check 'the action detail names the action' ($actDetail.kind -eq 'action' -and [bool]$actDetail.title) $actDetail.title
Check 'the action detail explains what it touches' ($actDetail.touches -like 'Touches: *' -and [bool]$actDetail.body) $actDetail.touches
Check 'the action detail states whether it is on by default' ($actDetail.defaultLine -like 'Default: *') $actDetail.defaultLine

$plan = @(Get-UiPlanText -State $state)
Check 'the preview text groups the plan' (($plan -join "`n") -match 'Ads & suggestions' -and $plan.Count -gt 40) ("{0} lines" -f $plan.Count)
Check 'the preview text totals the plan' ($plan[-1] -eq 'Total: 45 action(s)') $plan[-1]

# ---------------------------------------------------------------------------
Write-Head 'every chrome string exists in both languages'
$missing = @($script:GuiText.Keys | Where-Object { -not $script:GuiText[$_].en -or -not $script:GuiText[$_].zh })
Check 'no chrome string is missing a language' ($missing.Count -eq 0) (($missing) -join ', ')
$example = @($script:GuiText.Keys)[0]
Check 'a chrome string resolves per language' ((Get-GuiText -Key $example -Language 'en') -ne '' -and (Get-GuiText -Key $example -Language 'zh') -ne '') $example

# ---------------------------------------------------------------------------
Write-Head 'the language switch reaches every projection'
$zhState = Select-TuiLanguage -State $state -Language 'zh'
$zhGroups = @(Get-UiGroupRow -State $zhState)
$zhRows = @(Get-UiActionRow -State $zhState)
Check 'the language switch renames the categories' ($zhGroups[0].name -ne $groups[0].name) ("{0} -> {1}" -f $groups[0].name, $zhGroups[0].name)
Check 'the language switch retitles the actions' ($zhRows[0].title -ne $rows[0].title) $zhRows[0].title
$zhState.Pane = 'detail'
Check 'the language switch translates the detail body' ((Get-UiDetail -State $zhState).body -ne $actDetail.body) 'the explanation follows the language'
Check 'the language switch relabels the buttons' ((Get-GuiText -Key 'apply' -Language 'zh') -ne (Get-GuiText -Key 'apply' -Language 'en')) '执行...'
Check 'the summary follows the language' ((Get-UiSummary -State $zhState).title -eq '计划: 45 项') (Get-UiSummary -State $zhState).title

# ---------------------------------------------------------------------------
Write-Head 'cross-frontend parity'
# The GUI lists ticks; the console frame draws them. Same state, same ticks -- and
# the comparison is checked against a state it must reject, so a pass means
# something.
function Test-GuiConsoleParity {
    <#
      Do the two frontends say the same thing about the same selection? The GUI
      lists ticks; the console frame draws them; the ids the engine receives come
      from the same state either way, and this is what keeps that true.
    #>
    param($GuiState, $ConsoleState)

    $frame = Get-TuiFrame -State $ConsoleState -Width 100 -Height 60
    $text = $frame -join "`n"
    $guiRows = @(Get-UiActionRow -State $GuiState)
    foreach ($row in $guiRows) {
        $mark = if ($row.checked) { '[x]' } else { '[ ]' }
        if ($text -notmatch [regex]::Escape($mark + ' ' + $row.title)) { return $false }
    }
    $drawn = ([regex]::Matches($text, '\[x\] ')).Count
    $listed = @($guiRows | Where-Object { $_.checked }).Count
    return ($drawn -eq $listed)
}

Check 'the two frontends agree on the same state' (Test-GuiConsoleParity -GuiState $state -ConsoleState $state) 'ticks, titles and counts'

# A comparison that cannot fail proves nothing: hand it two states that must
# disagree -- the GUI side with one focused action unticked, the console side with
# it ticked. If this passes, the check above only reported that it did not crash.
$one = @($state.Selected.Keys | Where-Object { $_ -like ($groups[0].id + '.*') })[0]
$broken = Initialize-TuiState -Catalog $cat -Language 'en'
$broken.Selected.Remove($one)
Check 'the self-test action is one the focused list shows' ([bool]$one) $one
Check 'the parity check rejects two frontends that disagree' (-not (Test-GuiConsoleParity -GuiState $broken -ConsoleState $state)) ("unticked $one on the GUI side only")

# ---------------------------------------------------------------------------
Write-Head 'the window can be built without being shown'
$winforms = $true
try { Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop } catch { $winforms = $false }
if (-not $winforms) {
    Write-Host '  (skipped: WinForms is not available on this platform)' -ForegroundColor DarkGray
} else {
    $built = Initialize-GuiForm -State $state -Version '9.9.9'
    try {
        $c = $built.Controls
        Check 'the form is titled with the version' ($built.Form.Text -like '*9.9.9*') $built.Form.Text
        Check 'the form has all three panes' ($null -ne $c.mainSplit -and $null -ne $c.leftSplit -and $null -ne $c.actionList) 'split, categories, actions'
        Check 'the action list is a checkbox list' ($c.actionList -is [System.Windows.Forms.CheckedListBox]) 'users tick, they do not type'
Check 'every button is present and labelled' (@(@('preview', 'apply', 'restore', 'language', 'about') | Where-Object { -not $c[$_] -or -not $c[$_].Text }).Count -eq 0) (($c.buttons.Controls | ForEach-Object { $_.Text }) -join ' | ')
        Check 'the progress bar is present' ($c.bar -is [System.Windows.Forms.ProgressBar]) '74 actions need feedback'
        Check 'the detail panel has a place for the explanation' ($null -ne $c.detailBody -and $c.detailBody.ReadOnly) 'read-only: it explains, it does not accept input'
        Check 'controls carry accessible names' (([bool]$c.categoryList.AccessibleName) -and ([bool]$c.actionList.AccessibleName)) 'screen readers need them'
        Sync-GuiView -Controls $c -State $state -Version '9.9.9'
        Check 'filling the form shows every category' ($c.categoryList.Items.Count -eq $cat.categories.Count) ("{0}" -f $c.categoryList.Items.Count)
        Check 'filling the form shows the focused category actions' ($c.actionList.Items.Count -eq $firstGroup) ("{0}" -f $c.actionList.Items.Count)
        Check 'filling the form ticks the default set' ($c.actionList.CheckedItems.Count -eq $tickedRows) ("{0} of {1}" -f $c.actionList.CheckedItems.Count, $rows.Count)
        Check 'filling the form writes the detail text' ([bool]$c.detailBody.Text) ($c.detailTitle.Text)

        # The checkbox path, exercised without a mouse: this is what ItemCheck runs.
        $script:GuiApp.State = $state
        $script:GuiApp.Controls = $c
        $script:GuiApp.Version = '9.9.9'
        $rowsNow = @(Get-UiActionRow -State $state)
        $unticked = @(0..($rowsNow.Count - 1) | Where-Object { -not $rowsNow[$_].checked })[0]
        $before = $state.Selected.Count
        $null = Switch-GuiActionAt -Index $unticked
        Check 'the checkbox path ticks the action' ($state.Selected.Count -eq ($before + 1)) ("{0} -> {1}" -f $before, $state.Selected.Count)
        Check 'the checkbox path updates the control' ($c.actionList.GetItemChecked($unticked)) "row $unticked"
        $null = Switch-GuiActionAt -Index $unticked
        Check 'the checkbox path untickes it again' ($state.Selected.Count -eq $before) ("{0}" -f $state.Selected.Count)
        Check 'an out-of-range row is refused' (-not (Switch-GuiActionAt -Index 999)) 'no crash, no change'
    } finally {
        $built.Form.Dispose()
    }
}

# ---------------------------------------------------------------------------
Write-Head 'the UI layers do not collide with the engine''s parameters'
# Both frontends are dot-sourced into the engine's script scope. A [switch] or
# [string] parameter there type-constrains the variable, so assigning a hashtable to
# it throws at runtime -- and only when that interface is actually used, which is
# how $script:Gui collided with [switch] $Gui and broke -Gui the first time it ran.
$engineSource = Get-Content $engine -Raw -Encoding UTF8
$paramBlock = [regex]::Match($engineSource, '(?s)param\((.*?)\r?\n\)').Groups[1].Value
$engineParams = @([regex]::Matches($paramBlock, '(?m)^\s*\[[^\]]+\]\s*\$(\w+)') | ForEach-Object { $_.Groups[1].Value })
Check 'the engine declares its parameters' ($engineParams.Count -ge 10) ("{0} parameters" -f $engineParams.Count)

$collisions = New-Object System.Collections.Generic.List[string]
foreach ($file in 'src/lib/Ui.Logic.ps1', 'src/lib/Tui.Render.ps1', 'src/lib/Tui.Input.ps1', 'src/gui/WinCleanKit.gui.ps1') {
    $source = Get-Content (Join-Path $root $file) -Raw -Encoding UTF8
    foreach ($m in [regex]::Matches($source, '(?m)\$script:(\w+)\s*=')) {
        if ($engineParams -contains $m.Groups[1].Value) { [void]$collisions.Add("$file -> `$script:$($m.Groups[1].Value)") }
    }
}
Check 'no UI file assigns to an engine parameter' ($collisions.Count -eq 0) (($collisions) -join '; ')

# ---------------------------------------------------------------------------
Write-Head 'the GUI changes nothing itself'
$guiSource = Get-Content $guiPath -Raw -Encoding UTF8
foreach ($needle in 'Set-ItemProperty', 'New-ItemProperty', 'Remove-ItemProperty', 'New-Item', 'Set-Service', 'Stop-Service', 'Remove-AppxPackage', 'Disable-ScheduledTask', 'reg add', 'reg delete') {
    Check "GUI file contains no '$needle'" (-not ($guiSource -match [regex]::Escape($needle))) 'all changes go through the engine'
}

# ---------------------------------------------------------------------------
Write-Head 'the engine and the launchers know about it'
$engineText = Get-Content $engine -Raw -Encoding UTF8
Check 'the engine takes -Gui' ($engineText -match '(?m)^\s*\[switch\]\s+\$Gui\b') '-Gui'
Check 'the engine runs the GUI session' ($engineText -match 'Show-GuiSession') 'Open-GuiSession'
Check 'the engine loads the GUI only when asked' ($engineText -match 'if \(\$Gui\) \{' -and $engineText -match 'WinCleanKit\.gui\.ps1') 'the console path does not pay for it'
Check 'the engine learns whether a run happened' ($engineText -match '\$script:UiApplied') 'so it does not apply the plan a second time'
Check 'the engine forwards -DryRun to the window' ($engineSource -match '-DryRun:\$DryRun') 'so Apply can be tried safely'

$batText = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes((Join-Path $root 'src/WinCleanKit.bat')))
Check 'the window can run the engine as a dry run' ($guiSource -match "engineArgs \+= '-DryRun'") 'nothing is written and no restore point is made'
Check 'the launcher accepts --gui' ($batText -match '--gui" set "WCK_GUI=1') 'parse'
Check 'the launcher forwards --gui through elevation' ($batText -match 'WCK_GUI set "WCK_ELEVARGS=--elevated --gui') 'otherwise the elevated instance drops it'
Check 'the launcher runs the window before the console' ($batText.IndexOf('-Gui -TuiExitCode') -lt $batText.IndexOf('-Tui -TuiExitCode -TuiLanguage')) 'GUI, then TUI, then the menu'
Check 'the launcher keeps the numbered menu reachable' ($batText -match '--simple" set "WCK_SIMPLE=1') 'accessibility is not a fallback only'

$runText = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes((Join-Path $root 'run.bat')))
Check 'double-clicking asks for the window' ($runText -match 'if not defined WCK_PICKED set "WCK_ARGS=%\* --gui"') 'run.bat'
Check 'an explicit interface is left alone' (($runText -match '--tui"\s+set "WCK_PICKED=1') -and ($runText -match '--simple"\s+set "WCK_PICKED=1')) 'no switch is overridden'

Write-Host ''
if ($fail -eq 0) { Write-Host ("ALL PASSED  ({0} checks)" -f $pass) -ForegroundColor Green }
else             { Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
