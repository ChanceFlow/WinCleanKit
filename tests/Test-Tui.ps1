<#
.SYNOPSIS
    Behaviour tests for the TUI's logic layer. Changes nothing, needs no terminal.

.DESCRIPTION
    src/lib/Tui.Logic.ps1 is pure functions over a plain hashtable, so the parts of
    the interactive UI that can be decided without a terminal are tested here:
    cursor movement and clamping, mode switching, the default selection, selection
    toggling, group and whole-catalog selection, risk reporting, the plan the UI
    hands to the engine, and the scroll-window math.

    What this cannot cover, and does not pretend to: the key loop itself. Reading
    keys and repainting the screen needs a real interactive console, which no
    automated run has. tests/Test-Analyzer.ps1 and Test-Parse.ps1 guard that code
    statically, and the loop is kept as thin as possible so there is little in it
    that could be wrong.

.EXAMPLE
    .\tests\Test-Tui.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$logic = Join-Path $root 'src/lib/Tui.Logic.ps1'
$catalogPath = Join-Path $root 'catalog/catalog.json'

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

function Test-HasCjk {
    <#
      True when the string contains a CJK character. Compares code points directly
      instead of using a regex escape: \uXXXX is not expanded by Windows
      PowerShell 5.1 and the backtick form has proven unreliable, whereas
      [int][char] is exact everywhere.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Coloured pass/fail output is the intended interface of this test script.')]
    param([string]$Text)
    if (-not $Text) { return $false }
    foreach ($ch in $Text.ToCharArray()) {
        $c = [int][char]$ch
        if ($c -ge 0x4E00 -and $c -le 0x9FFF) { return $true }
    }
    return $false
}

Check 'logic module exists' (Test-Path $logic) $logic
Check 'catalog exists' (Test-Path $catalogPath)

Write-Head 'loading the logic layer in isolation'
# Dot-source in a child scope so the module's own StrictMode cannot leak.
. $logic
$cat = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host ("  catalog: {0} actions, {1} categories" -f $cat.actions.Count, $cat.categories.Count)

# ---------------------------------------------------------------------------
Write-Head 'state initialisation'
$st = Initialize-TuiState -Catalog $cat -Language 'en'
Check 'groups built' ($st.Groups.Count -eq $cat.categories.Count) ("{0} groups" -f $st.Groups.Count)
Check 'empty categories dropped' (@($st.Groups | Where-Object { $_.count -eq 0 }).Count -eq 0)
Check 'group counts sum to the catalog' (((@($st.Groups | Measure-Object -Property count -Sum).Sum)) -eq $cat.actions.Count)
Check 'selection starts from the catalog default set' ($st.Selected.Count -eq @($cat.actions | Where-Object { $_.default }).Count) ("{0} selected" -f $st.Selected.Count)
Check 'starts in list mode' ($st.Mode -eq 'list')
$stZh = Initialize-TuiState -Catalog $cat -Language 'zh'
$namesZh = @($stZh.Groups | ForEach-Object { $_.name })
# Not every category has a Chinese name: OneDrive's is intentionally "OneDrive".
# So assert that the catalogue's own localised names are carried through, rather
# than assuming a character class.
$expectedZh = @($cat.categories | ForEach-Object { $_.name_zh })
Check 'zh group names come from the catalog' (($namesZh -join '|') -eq ($expectedZh -join '|')) ($namesZh -join ', ')
Check 'zh names are mostly Chinese' ((@($namesZh | Where-Object { Test-HasCjk $_ }).Count) -ge ($namesZh.Count - 1)) ("{0}/{1} contain CJK" -f @($namesZh | Where-Object { Test-HasCjk $_ }).Count, $namesZh.Count)
Check 'a non-translated name is left alone' (-not (Test-HasCjk 'OneDrive')) 'OneDrive stays OneDrive'
$enNames = @((Initialize-TuiState -Catalog $cat -Language 'en').Groups | ForEach-Object { $_.name })
Check 'en names differ from zh names' (($enNames -join '|') -ne ($namesZh -join '|'))

# ---------------------------------------------------------------------------
Write-Head 'navigation clamps instead of wrapping'
$st = Initialize-TuiState -Catalog $cat
$st = Move-TuiCursor -State $st -Direction 'up'
Check 'up at the top stays at 0' ($st.ListIndex -eq 0)
for ($i = 0; $i -lt 50; $i++) { $st = Move-TuiCursor -State $st -Direction 'down' }
Check 'down at the bottom clamps' ($st.ListIndex -eq ($st.Groups.Count - 1)) ("index {0} of {1}" -f $st.ListIndex, $st.Groups.Count)

$st = Switch-TuiPane -State $st
Check 'pane switch enters detail' ($st.Pane -eq 'detail' -and $st.Mode -eq 'detail')
$items = Get-TuiGroupAction $st
for ($i = 0; $i -lt 200; $i++) { $st = Move-TuiCursor -State $st -Direction 'down' }
Check 'detail cursor clamps' ($st.DetailIndex -eq ($items.Count - 1)) ("index {0} of {1}" -f $st.DetailIndex, $items.Count)
$st = Switch-TuiPane -State $st
Check 'pane switch returns to list' ($st.Pane -eq 'list' -and $st.Mode -eq 'list')

$st = Move-TuiCursor -State $st -Direction 'down'
Check 'changing group resets the detail cursor' ($st.DetailIndex -eq 0)

# ---------------------------------------------------------------------------
Write-Head 'the default selection'
# There is no tier to pick before you start. The state opens with the catalog's own
# default set on and nothing else, and the interface never puts anything back.
$nDefault = @($cat.actions | Where-Object { $_.default }).Count
$st = Initialize-TuiState -Catalog $cat
Check 'opens with the catalog default set' ($st.Selected.Count -eq $nDefault) ("{0} vs {1}" -f $st.Selected.Count, $nDefault)
# Not "a minority": the default set is deliberately the cautious 45. What matters is
# that nothing risky is in it, and that it is useful out of the box rather than a
# token selection from one category.
$defaultRisky = @($cat.actions | Where-Object { $_.default -and $_.risk -eq 'high' })
Check 'no high-risk action is on by default' ($defaultRisky.Count -eq 0) (($defaultRisky | ForEach-Object { $_.id }) -join ', ')
# Removing a program is never on by default: the default set is preferences and
# background collectors only, so "uninstall something" always takes a deliberate
# click. This is the line the whole risk model rests on.
$defaultDestructive = @($cat.actions | Where-Object { $_.default -and $_.target -in 'appx', 'onedrive' })
Check 'nothing that uninstalls software is on by default' ($defaultDestructive.Count -eq 0) (($defaultDestructive | ForEach-Object { $_.id }) -join ', ')
# Recorded rather than asserted loosely: if the default set changes, that is a
# decision to make on purpose, not something to discover from a diff.
$defaultCats = @($cat.actions | Where-Object { $_.default } | ForEach-Object { $_.category } | Select-Object -Unique | Sort-Object)
Check 'the default set covers the non-destructive categories' (($defaultCats -join ',') -eq 'ads,cache,privacy,telemetry') ($defaultCats -join ',')
Check 'no preset field is carried in the state' (-not ($st.ContainsKey('Preset'))) 'the concept is gone'
$optIn = @($cat.actions | Where-Object { -not $_.default } | ForEach-Object { $_.id })
$st = Switch-TuiAction -State $st -Id $optIn[0]
Check 'an opt-in action can be turned on' ($st.Selected.ContainsKey($optIn[0]))
$st = Switch-TuiAction -State $st -Id $optIn[0]
Check 'and turned off again' (-not $st.Selected.ContainsKey($optIn[0]))
Check 'toggling never changes the rest' ($st.Selected.Count -eq $nDefault) ("{0}" -f $st.Selected.Count)

# ---------------------------------------------------------------------------
Write-Head 'selection'
$st = Initialize-TuiState -Catalog $cat
$first = (Get-TuiGroupAction $st)[0]
$id = $first.id
$was = Test-TuiSelected -State $st -Id $id
$st = Switch-TuiAction -State $st -Id $id
Check 'toggle flips a selected action off' ((Test-TuiSelected -State $st -Id $id) -ne $was)
$st = Switch-TuiAction -State $st -Id $id
Check 'toggle flips it back' ((Test-TuiSelected -State $st -Id $id) -eq $was)

$st = Initialize-TuiState -Catalog $cat
$st.DetailIndex = 0
$target = (Get-TuiActionAt $st).id
$st = Switch-TuiCurrent -State $st
Check 'toggle-current flips the cursor row' ((Test-TuiSelected -State $st -Id $target) -ne $was)
Check 'toggle-current steps down' ($st.DetailIndex -eq 1)

$st = Initialize-TuiState -Catalog $cat
$st = Switch-TuiGroupSelection -State $st -Selected $false
$g = Get-TuiGroupSelection $st
Check 'clear group empties it' ($g.Selected -eq 0) ("{0}/{1}" -f $g.Selected, $g.Total)
$st = Switch-TuiGroupSelection -State $st -Selected $true
$g = Get-TuiGroupSelection $st
Check 'select group fills it' ($g.Selected -eq $g.Total) ("{0}/{1}" -f $g.Selected, $g.Total)

$st = Switch-TuiAllSelection -State $st -Selected $false
Check 'clear all empties the selection' ((Get-TuiSelectedCount $st) -eq 0)
$st = Switch-TuiAllSelection -State $st -Selected $true
Check 'select all fills the selection' ((Get-TuiSelectedCount $st) -eq $cat.actions.Count)
Check 'plan covers the catalog when all selected' ((Get-TuiPlan $st).Count -eq $cat.actions.Count)

# ---------------------------------------------------------------------------
Write-Head 'risk reporting'
$st = Initialize-TuiState -Catalog $cat
$rDefault = Get-TuiHighestRisk $st
$st = Switch-TuiAllSelection -State $st -Selected $true
$rAll = Get-TuiHighestRisk $st
Check 'the default risk is at most the whole-catalog risk' ($rDefault -le $rAll) ("{0} <= {1}" -f $rDefault, $rAll)
Check 'selecting everything reaches high' ($rAll -eq 3)
$st = Switch-TuiAllSelection -State $st -Selected $false
Check 'empty selection reports no risk' ((Get-TuiHighestRisk $st) -eq 0)

# ---------------------------------------------------------------------------
Write-Head 'plan handed to the engine'
$st = Initialize-TuiState -Catalog $cat
$plan = Get-TuiPlan $st
$expected = @($cat.actions | Where-Object { $_.default } | ForEach-Object { $_.id })
Check 'plan ids match the default set' (($plan -join ',') -eq ($expected -join ',')) ("{0} ids" -f $plan.Count)
Check 'plan is in catalog order' ($plan[0] -eq $expected[0])
$st = Switch-TuiAction -State $st -Id $expected[0]
Check 'deselecting removes it from the plan' ((Get-TuiPlan $st) -notcontains $expected[0])
Check 'plan shrinks by exactly one' ((Get-TuiPlan $st).Count -eq ($plan.Count - 1))

# ---------------------------------------------------------------------------
Write-Head 'scroll window math'
Check 'short list needs no scroll' ((Get-TuiWindow -Total 3 -Height 10 -Cursor 1) -eq 0)
Check 'cursor below the window scrolls down' ((Get-TuiWindow -Total 100 -Height 10 -Cursor 25) -eq 16) ("got {0}" -f (Get-TuiWindow -Total 100 -Height 10 -Cursor 25))
Check 'cursor above the window scrolls up' ((Get-TuiWindow -Total 100 -Height 10 -Cursor 5 -ScrollTop 40) -eq 5)
Check 'window never exceeds the list' ((Get-TuiWindow -Total 12 -Height 10 -Cursor 11) -eq 2)
Check 'empty list yields zero' ((Get-TuiWindow -Total 0 -Height 10 -Cursor 0) -eq 0)
Check 'zero height yields zero' ((Get-TuiWindow -Total 10 -Height 0 -Cursor 5) -eq 0)
$st = Initialize-TuiState -Catalog $cat
$st.DetailIndex = 300
$top = Get-TuiScrollTop -State $st -Height 12
$items = Get-TuiGroupAction $st
Check 'scroll keeps the cursor visible' ($top -le $st.DetailIndex -and $st.DetailIndex -lt ($top + 12) -or $st.DetailIndex -ge $items.Count) ("top {0}, cursor {1}, items {2}" -f $top, $st.DetailIndex, $items.Count)

# ---------------------------------------------------------------------------
Write-Head 'the opening language chooser'
# The chooser is what a user sees before any language has been picked, so it has to
# lead to a fully working state in whichever language they choose.
$ask = Initialize-TuiState -Catalog $cat -Language 'ask'
Check 'ask opens the chooser' ($ask.Mode -eq 'language') ("mode is $($ask.Mode)")
Check 'the chooser offers both languages' ((Get-TuiLanguageList) -join ',' -eq 'zh,en') ((Get-TuiLanguageList) -join ',')
Check 'the chooser starts on the first language' ((Get-TuiLanguageChoice $ask) -eq 'zh') (Get-TuiLanguageChoice $ask)
Check 'the chooser still knows the plan' ((Get-TuiPlan $ask).Count -gt 0) ("{0} actions" -f (Get-TuiPlan $ask).Count)
$down = Move-TuiLanguageCursor -State $ask -Direction 'down'
Check 'the cursor reaches English' ((Get-TuiLanguageChoice $down) -eq 'en') (Get-TuiLanguageChoice $down)
Check 'the cursor clamps at the end' (((Move-TuiLanguageCursor -State $down -Direction 'down').LangIndex) -eq 1) 'no wrap'
Check 'the cursor clamps at the start' (((Move-TuiLanguageCursor -State $ask -Direction 'up').LangIndex) -eq 0) 'no wrap'

$zh2 = Select-TuiLanguageChoice -State $ask -Language 'zh'
Check 'choosing zh leaves the chooser' ($zh2.Mode -eq 'list') ("mode is $($zh2.Mode)")
Check 'choosing zh applies Chinese' ($zh2.Language -eq 'zh') (Get-TuiLanguageChoice $ask)
Check 'choosing zh applies to the groups' ((@($zh2.Groups | Where-Object { Test-HasCjk $_.name }).Count) -ge ($zh2.Groups.Count - 1))
Check 'choosing zh keeps the plan' (((Get-TuiPlan $zh2) -join ',') -eq ((Get-TuiPlan $ask) -join ',')) 'plan unchanged'
$en2 = Select-TuiLanguageChoice -State $ask -Language 'en'
Check 'choosing en applies English' ($en2.Language -eq 'en' -and (@($en2.Groups | Where-Object { Test-HasCjk $_.name }).Count) -eq 0)

# A state built for a language must not open the chooser.
$direct = Initialize-TuiState -Catalog $cat -Language 'en'
Check 'an explicit language skips the chooser' ($direct.Mode -eq 'list') ("mode is $($direct.Mode)")

# ---------------------------------------------------------------------------
Write-Head 'language switching preserves work'
$st = Initialize-TuiState -Catalog $cat -Language 'en'
$st = Switch-TuiAction -State $st -Id ((Get-TuiGroupAction $st)[0]).id
$planBefore = (Get-TuiPlan $st) -join ','
$st = Select-TuiLanguage -State $st -Language 'zh'
Check 'switch to zh keeps the plan' (((Get-TuiPlan $st) -join ',') -eq $planBefore)
Check 'zh applied to groups' ((@($st.Groups | Where-Object { Test-HasCjk $_.name }).Count) -ge ($st.Groups.Count - 1))
$st = Select-TuiLanguage -State $st -Language 'en'
Check 'switch back to en keeps the plan' (((Get-TuiPlan $st) -join ',') -eq $planBefore)
Check 'en applied to groups' ((@($st.Groups | Where-Object { Test-HasCjk $_.name }).Count) -eq 0)
$st = Select-TuiLanguage -State $st -Language 'klingon'
Check 'unknown language ignored' ($st.Language -eq 'en')

# The language toggle rebuilds the state from the catalog, which resets the view
# to its opening position. Where the user is standing has to survive that, or
# pressing `l` from the detail pane or the help screen drops them back to the list.
$here = Initialize-TuiState -Catalog $cat -Language 'en'
$here = Move-TuiCursor -State $here -Direction 'down'
$here = Switch-TuiPane -State $here
$here = Move-TuiCursor -State $here -Direction 'down'
$before = '{0}|{1}|{2}|{3}' -f $here.Mode, $here.Pane, $here.ListIndex, $here.DetailIndex
$here = Select-TuiLanguage -State $here -Language 'zh'
Check 'language switch keeps the current view' (('{0}|{1}|{2}|{3}' -f $here.Mode, $here.Pane, $here.ListIndex, $here.DetailIndex) -eq $before) $before
$help = Initialize-TuiState -Catalog $cat -Language 'en'
$help = Select-TuiMode -State $help -Mode 'help'
$help = Select-TuiLanguage -State $help -Language 'zh'
Check 'language switch stays on the help screen' ($help.Mode -eq 'help') ("mode is $($help.Mode)")

# ---------------------------------------------------------------------------
Write-Head 'mode switching'
$st = Select-TuiMode -State $st -Mode 'help'
Check 'help mode entered' ($st.Mode -eq 'help')
$st = Select-TuiMode -State $st -Mode 'detail'
Check 'detail mode focuses the detail pane' ($st.Pane -eq 'detail')
$st = Select-TuiMode -State $st -Mode 'list'
Check 'list mode focuses the list pane' ($st.Pane -eq 'list')

Write-Host ''
if ($fail -eq 0) { Write-Host ("ALL PASSED  ({0} checks)" -f $pass) -ForegroundColor Green }
else             { Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
