<#
.SYNOPSIS
    Behaviour tests for the windowed frontend. Changes nothing, needs no desktop.

.DESCRIPTION
    The GUI has two halves, and both are testable without a screen:

      * the projection in Ui.Logic.ps1 (Get-Ui*) is pure, so its rows, counts,
        detail text, search results, plan facts and chrome strings can be checked
        exactly;
      * Initialize-GuiForm builds a real control tree but never shows it, so the
        shape of the window -- five pages behind a rail, choosing separate from
        running -- can be asserted headlessly.

    What this cannot cover, and does not pretend to: how the window looks, and
    whether the event wiring responds to a real mouse. Both are verified by hand in
    a real session, the same way the console key loop is.

    The important check here is parity. Two frontends drawing the same state is an
    invariant, not a hope: the tick marks the GUI lists must be the tick marks the
    console frame draws, for the same state. That check is then tested against a
    state it must reject, so a clean result cannot come from a comparison that
    detects nothing. The search checks carry the same tripwire: a filter that was
    ignored must be able to make them fail.

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
Write-Head 'the plan in numbers (the page that runs it)'
$facts = Get-UiPlanFact -State $state
Check 'the plan facts count the whole plan' ($facts.total -eq (Get-TuiSelectedCount -State $state)) ("{0}" -f $facts.total)
Check 'the plan facts group the plan into areas' ((@($facts.groups | Measure-Object -Property count -Sum).Sum) -eq $facts.total) ("{0} areas" -f $facts.groups.Count)
Check 'every area in the plan has a name and a count' (@($facts.groups | Where-Object { -not $_.name -or $_.count -le 0 }).Count -eq 0) 'no anonymous group'
$independentRemoves = @($cat.actions | Where-Object { $state.Selected.ContainsKey($_.id) -and $_.PSObject.Properties['target'].Value -in @('appx', 'onedrive') }).Count
Check 'the plan facts count the same software removals the catalog does' ($facts.removes -eq $independentRemoves) ("{0}" -f $facts.removes)
Check 'the plan facts flag what to read twice' ($facts.risky -eq ($facts.removes + $facts.deletes)) ("removes={0} deletes={1}" -f $facts.removes, $facts.deletes)
$emptyState = Initialize-TuiState -Catalog $cat -Language 'en'
$emptyState.Selected = @{}
$emptyFacts = Get-UiPlanFact -State $emptyState
Check 'an empty plan reports zero and no areas' ($emptyFacts.total -eq 0 -and @($emptyFacts.groups).Count -eq 0) 'the run button is disabled on this'

# ---------------------------------------------------------------------------
Write-Head 'the window names the machine honestly'
# Windows 11 writes ProductName = "Windows 10 Pro" into the registry. A window that
# repeats that tells the user something false about their own computer, so the build
# number wins. This is the check that would have caught the overview page claiming
# "Windows 10 Pro · build 26200".
$win11 = Format-GuiWindowsName -ProductName 'Windows 10 Pro' -Build '26200' -Release '25H2'
Check 'a Windows 11 build is not called Windows 10' ($win11 -eq 'Windows 11 Pro · 25H2 · build 26200') $win11
$win10 = Format-GuiWindowsName -ProductName 'Windows 10 Home' -Build '19045' -Release '22H2'
Check 'a Windows 10 build keeps its name' ($win10 -eq 'Windows 10 Home · 22H2 · build 19045') $win10
Check 'a machine that will not answer still gets a name' ((Format-GuiWindowsName) -eq 'Windows') 'best effort'
Check 'a build with no release name simply leaves it out' ((Format-GuiWindowsName -ProductName 'Windows 11 Pro' -Build '22631') -eq 'Windows 11 Pro · build 22631') 'build 22631'

# ---------------------------------------------------------------------------
Write-Head 'search'
# The window searches the whole catalog rather than the focused area: 74 rows across
# six areas is past the point where scrolling is a plan.
$second = $groups[1]
$secondAction = @($cat.actions | Where-Object { $_.category -eq $second.id })[0]
$needle = [string]$secondAction.id
$hits = @(Get-UiSearchRow -State $state -Filter $needle)
Check 'search finds an action by its id' ($hits.Count -ge 1 -and @($hits | Where-Object { $_.id -eq $secondAction.id }).Count -eq 1) $needle
Check 'search looks outside the focused area' (@($hits | Where-Object { $_.category -eq $second.id }).Count -ge 1) ("area: {0}" -f $second.id)
Check 'a search result carries its tick state' ($hits[0].checked -eq $state.Selected.ContainsKey($hits[0].id)) 'ticks come from the selection'
Check 'search is case-insensitive' ((@(Get-UiSearchRow -State $state -Filter $needle.ToUpperInvariant())).Count -eq $hits.Count) 'the same rows either way'
$byArea = @(Get-UiSearchRow -State $state -Filter $groups[0].name)
Check 'search matches an area name' ($byArea.Count -eq $groups[0].total) ("{0} of {1}" -f $byArea.Count, $groups[0].total)
Check 'an unmatched search returns nothing' (@(Get-UiSearchRow -State $state -Filter 'zzz-no-such-change').Count -eq 0) 'the window says so instead of showing the area'
Check 'the focused list is what an empty filter gives' (@(Get-UiActionRow -State $state -Filter '').Count -eq $firstGroup) 'the filter defaults to the area'
Check 'the list and the search share one row source' (@(Get-UiActionRow -State $state -Filter $needle).Count -eq $hits.Count) 'so a row index means the same thing to both'
# The tripwire: if a filter were ignored, the list would be the focused area again --
# and that is a number this check can tell apart from the search result.
Check 'the search check would notice a filter that was ignored' ((@(Get-UiActionRow -State $state -Filter 'zzz-no-such-change').Count) -ne $firstGroup) ("0 is not {0}" -f $firstGroup)

$filterState = Initialize-TuiState -Catalog $cat -Language 'en'
$filterState.Pane = 'detail'
$filterDetail = Get-UiDetail -State $filterState -Filter $needle
Check 'the detail under a filter describes an action, not the area' ($filterDetail.kind -eq 'action' -and $filterDetail.id -eq $hits[0].id) $filterDetail.id
Check 'the detail under a filter cannot be empty while a row is listed' ([bool]$filterDetail.body) 'the panel always has something to say'
Check 'an unmatched filter has no detail at all' ($null -eq (Get-UiDetail -State $filterState -Filter 'zzz-no-such-change')) 'nothing to describe'

# ---------------------------------------------------------------------------
Write-Head 'every chrome string exists in both languages'
$missing = @($script:GuiText.Keys | Where-Object { -not $script:GuiText[$_].en -or -not $script:GuiText[$_].zh })
Check 'no chrome string is missing a language' ($missing.Count -eq 0) (($missing) -join ', ')
$example = @($script:GuiText.Keys)[0]
Check 'a chrome string resolves per language' ((Get-GuiText -Key $example -Language 'en') -ne '' -and (Get-GuiText -Key $example -Language 'zh') -ne '') $example

$pageNames = 'home', 'choose', 'apply', 'restore', 'about'
foreach ($pageName in $pageNames) {
    $text = Get-GuiPageText -Name $pageName -State $state -Backups 3
    $lines = @($text -split "`n")
    Check "the rail entry for '$pageName' has a name and a state hint" ($lines.Count -eq 2 -and [bool]$lines[0] -and [bool]$lines[1]) ($lines -join ' / ')
}
Check 'the rail entry for choosing carries the ticked count' ((Get-GuiPageText -Name 'choose' -State $state) -match '45') (Get-GuiPageText -Name 'choose' -State $state)
Check 'the rail entry for restoring carries the backup count' ((Get-GuiPageText -Name 'restore' -State $state -Backups 3) -match '3') (Get-GuiPageText -Name 'restore' -State $state -Backups 3)

# ---------------------------------------------------------------------------
Write-Head 'the language switch reaches every projection'
$zhState = Select-TuiLanguage -State $state -Language 'zh'
$zhGroups = @(Get-UiGroupRow -State $zhState)
$zhRows = @(Get-UiActionRow -State $zhState)
Check 'the language switch renames the categories' ($zhGroups[0].name -ne $groups[0].name) ("{0} -> {1}" -f $groups[0].name, $zhGroups[0].name)
Check 'the language switch retitles the actions' ($zhRows[0].title -ne $rows[0].title) $zhRows[0].title
$zhState.Pane = 'detail'
Check 'the language switch translates the detail body' ((Get-UiDetail -State $zhState).body -ne $actDetail.body) 'the explanation follows the language'
Check 'the language switch relabels the buttons' ((Get-GuiText -Key 'runIt' -Language 'zh') -ne (Get-GuiText -Key 'runIt' -Language 'en')) '执行这 N 项'
Check 'the summary follows the language' ((Get-UiSummary -State $zhState).title -eq '计划: 45 项') (Get-UiSummary -State $zhState).title
Check 'the rail follows the language' ((Get-GuiPageText -Name 'choose' -State $zhState) -match '已勾选') (Get-GuiPageText -Name 'choose' -State $zhState)
Check 'a search finds the Chinese titles too' (@(Get-UiSearchRow -State $zhState -Filter $needle).Count -ge 1) 'ids are language independent'
$zhHits = @(Get-UiSearchRow -State $zhState -Filter $zhGroups[1].name)
Check 'a Chinese area name is searchable' ($zhHits.Count -eq $zhGroups[1].total) ("{0} of {1}" -f $zhHits.Count, $zhGroups[1].total)

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
$c = $null
$winforms = $true
try { Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop } catch { $winforms = $false }
if (-not $winforms) {
    Write-Host '  (skipped: WinForms is not available on this platform)' -ForegroundColor DarkGray
} else {
    $built = Initialize-GuiForm -State $state -Version '9.9.9'
    try {
        $c = $built.Controls
        Check 'the form is titled with the version' ($built.Form.Text -like '*9.9.9*') $built.Form.Text
        Check 'the window is five pages' (@($pageNames | Where-Object { -not $c[$_ + 'Page'] }).Count -eq 0) ($pageNames -join ', ')
        Check 'every page is a child of the working area' (@($pageNames | Where-Object { -not $c.content.Controls.Contains($c[$_ + 'Page']) }).Count -eq 0) 'five pages, one visible'
        Check 'every page has a rail entry' ((($c.nav.Keys | Sort-Object) -join ',') -eq 'about,apply,choose,home,restore') (($c.nav.Keys | Sort-Object) -join ', ')
        Check 'the action list is a checkbox list' ($c.actionList -is [System.Windows.Forms.CheckedListBox]) 'users tick, they do not type'
        Check 'the area selector is a row of chips, one per area' ($c.chips.Count -eq $cat.categories.Count -and @($c.chips | Where-Object { $_.Appearance -ne 'Button' }).Count -eq 0) ("{0} chips" -f $c.chips.Count)
        Check 'the search box exists and is named for a screen reader' ($c.searchBox -is [System.Windows.Forms.TextBox] -and [bool]$c.searchBox.AccessibleName) 'typing is how you find one row in 74'
        Check 'the output box is read-only and keeps the engine line breaks' ($c.log.ReadOnly -and -not $c.log.WordWrap) 'a log, not an input'
        Check 'the run button is not on the page where you tick things' (-not $c.choosePage.Contains($c.runIt)) 'choosing and running are separate steps'
        Check 'the undo button lives on the restore page' ($c.restorePage.Contains($c.restoreRun)) 'and not in the footer of everything'
        Check 'the progress bar is present' ($c.bar -is [System.Windows.Forms.ProgressBar]) '74 actions need feedback'
        Check 'the detail panel has a place for the explanation' ($null -ne $c.detailBody -and $c.detailBody.ReadOnly) 'read-only: it explains, it does not accept input'
        Check 'controls carry accessible names' (([bool]$c.actionList.AccessibleName) -and ([bool]$c.runIt.AccessibleDescription) -and ([bool]$c.searchBox.AccessibleName)) 'screen readers need them'
        # Asked of the built form rather than of the source: Enter must not be able
        # to change the machine, which is what an AcceptButton on this form would do.
        Check 'Apply is not the default Enter target' ($null -eq $c.form.AcceptButton) 'no AcceptButton on the session form'
        Check 'the progress bar has a step counter' ($null -ne $c.progressLabel -and -not $c.progressLabel.AutoSize) 'a bar alone does not say how far'

        Sync-GuiView -Controls $c -State $state -Version '9.9.9'
        Check 'every button is present and labelled' (@(@('preview', 'runIt', 'applyBack', 'chooseNext', 'selectAll', 'selectNone', 'homeUse', 'homePick', 'restoreRun', 'restoreOpen', 'language') | Where-Object { -not $c[$_] -or -not $c[$_].Text }).Count -eq 0) ((@('preview', 'runIt', 'chooseNext', 'restoreRun') | ForEach-Object { $c[$_].Text }) -join ' | ')
        Check 'filling the form labels every chip with its own counts' (@($c.chips | Where-Object { $_.Text -notmatch '^\S.*\s+\d+/\d+$' }).Count -eq 0) (($c.chips | ForEach-Object { $_.Text }) -join ' | ')
        # On a real screen Appearance=Button under AutoSize painted "Privacy  7/10" as
        # "Privacy 7/" and ate the ampersand in "Ads & suggestions". Both are checked
        # on a control, because neither is visible in the source.
        $probe = New-Object System.Windows.Forms.CheckBox
        $probe.Text = 'Privacy  7/10'
        Format-GuiChip -Chip $probe -Theme $built.Theme -Active $false
        $narrow = $probe.Width
        $flags = [System.Windows.Forms.TextFormatFlags]::NoPrefix -bor [System.Windows.Forms.TextFormatFlags]::NoPadding
        $need = [System.Windows.Forms.TextRenderer]::MeasureText($probe.Text, $probe.Font, [System.Drawing.Size]::Empty, $flags).Width + $probe.Padding.Horizontal
        Check 'a chip is wide enough for its own text' ($probe.Width -ge $need) ("{0} >= {1}" -f $probe.Width, $need)
        Check 'a chip does not eat an ampersand' (-not $probe.UseMnemonic) 'the catalog has "Ads & suggestions"'
        $probe.Text = 'Telemetry & diagnostics  17/21'
        Format-GuiChip -Chip $probe -Theme $built.Theme -Active $false
        Check 'a longer chip is wider' ($probe.Width -gt $narrow) ("{0} -> {1}" -f $narrow, $probe.Width)
        $probe.Dispose()
        Check 'the plan list is a statement, not a selection' ($c.applyList.SelectedIndex -eq -1) 'nothing highlighted'
        Check 'filling the form shows the focused area actions' ($c.actionList.Items.Count -eq $firstGroup) ("{0}" -f $c.actionList.Items.Count)
        Check 'filling the form ticks the default set' ($c.actionList.CheckedItems.Count -eq $tickedRows) ("{0} of {1}" -f $c.actionList.CheckedItems.Count, $rows.Count)
        Check 'filling the form writes the detail text' ([bool]$c.detailBody.Text) ($c.detailTitle.Text)
        Check 'the language button shows the current language' ($c.language.Text -match 'Language: EN') $c.language.Text
        Check 'the rail marks the page you are on' ($c.nav['home'].Font.Bold -and -not $c.nav['choose'].Font.Bold) 'the active entry is bold'
        Check 'the plan page states the plan in numbers' ($c.applyFacts.Text -match '45') $c.applyFacts.Text
        Check 'the plan page lists the whole plan' ($c.applyList.Items.Count -gt 40) ("{0} lines" -f $c.applyList.Items.Count)
        Check 'the run button says how many changes it will make' ($c.runIt.Text -match '45') $c.runIt.Text
        Check 'the overview offers both the recommended set and the manual path' ([bool]$c.homeUse.Text -and [bool]$c.homePick.Text) ($c.homeUse.Text)

        # Switching pages is a state change of the window, so it is checked here.
        $shown = @(Show-GuiPage -Controls $c -Name 'apply' -State $state -Version '9.9.9')
        Check 'showing a page shows exactly that page' ($shown.Count -eq 1 -and $shown[0] -eq 'apply' -and $script:GuiApp.Page -eq 'apply' -and $c.nav['apply'].Font.Bold) 'one page at a time'
        Check 'the page that was on screen is no longer current' (-not ($shown -contains 'home')) 'the rail follows'
        Check 'an unknown page is refused' (-not (Show-GuiPage -Controls $c -Name 'nope' -State $state -Version '9.9.9')) 'no crash, no blank window'
        $null = Show-GuiPage -Controls $c -Name 'home' -State $state -Version '9.9.9'

        # The search path through the window itself.
        $script:GuiApp.Controls = $c
        $script:GuiApp.State = $state
        $script:GuiApp.Version = '9.9.9'
        $null = Switch-GuiSearch -Text 'zzz-no-such-change'
        Check 'a search with no match says so instead of showing the area' ($c.actionList.Items.Count -eq 1 -and -not $c.actionList.Enabled) ([string]$c.actionList.Items[0])
        Check 'the detail panel empties on a search with no match' (-not $c.detailBody.Text) 'nothing to describe'
        $script:GuiApp.Filter = ''
        $null = Sync-GuiView -Controls $c -State $state -Version '9.9.9'
        Check 'clearing the search brings the area back' ($c.actionList.Items.Count -eq $firstGroup) ("{0}" -f $c.actionList.Items.Count)

        # A row in a search result must tick the action it names -- the index means
        # something different there, which is the bug this check exists for.
        $script:GuiApp.Filter = $needle
        $null = Sync-GuiView -Controls $c -State $state -Version '9.9.9'
        $filteredRows = @(Get-UiActionRow -State $state -Filter $needle)
        $beforeTicked = $state.Selected.Count
        $wasSelected = $state.Selected.ContainsKey($filteredRows[0].id)
        $null = Switch-GuiActionAt -Index 0
        Check 'a row in a search result ticks the action it names' ($state.Selected.ContainsKey($filteredRows[0].id) -ne $wasSelected) $filteredRows[0].id
        $null = Switch-GuiActionAt -Index 0
        Check 'and untickes it again' ($state.Selected.Count -eq $beforeTicked) ("{0}" -f $state.Selected.Count)
        $script:GuiApp.Filter = ''
        $null = Sync-GuiView -Controls $c -State $state -Version '9.9.9'

        $c.searchBox.Text = 'x'
        Check 'the search hint steps aside once there is text' (-not (Test-GuiSearchHintShown -Controls $c)) 'no placeholder over a real query'
        $c.searchBox.Text = ''
        Check 'the search hint comes back when the box is empty' (Test-GuiSearchHintShown -Controls $c) 'the box explains itself'
        Check 'the search hint says what there is to search' ($c.searchHint.Text -match '74') $c.searchHint.Text

        # The checkbox path, exercised without a mouse: this is what ItemCheck runs.
        $rowsNow = @(Get-UiActionRow -State $state)
        $unticked = @(0..($rowsNow.Count - 1) | Where-Object { -not $rowsNow[$_].checked })[0]
        $before = $state.Selected.Count
        $null = Switch-GuiActionAt -Index $unticked
        Check 'the checkbox path ticks the action' ($state.Selected.Count -eq ($before + 1)) ("{0} -> {1}" -f $before, $state.Selected.Count)
        Check 'the checkbox path updates the control' ($c.actionList.GetItemChecked($unticked)) "row $unticked"
        $null = Switch-GuiActionAt -Index $unticked
        Check 'the checkbox path untickes it again' ($state.Selected.Count -eq $before) ("{0}" -f $state.Selected.Count)
        Check 'an out-of-range row is refused' (-not (Switch-GuiActionAt -Index 999)) 'no crash, no change'
        Check 'an out-of-range area is refused' (-not (Switch-GuiCategory -Index 999)) 'no crash, no change'
        $c.searchBox.Text = 'zzz'
        $switched = Switch-GuiCategory -Index 0
        Check 'choosing an area clears the search' ($switched -and $c.searchBox.Text -eq '' -and -not $script:GuiApp.Filter) 'the two filters cannot fight'

        # GDI+ needs no desktop: drawing the icon is testable, and skipping it is how
        # a broken constructor reached a real session instead of a gate.
        $icon = Initialize-GuiIcon -Size 32
        Check 'the icon draws at the size asked for' ($icon.Width -eq 32 -and $icon.Height -eq 32) ("{0}x{1}" -f $icon.Width, $icon.Height)
        $icon.Dispose()
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

# The same class of bug, one level down: PowerShell's own read-only variables. $home
# is a directory, not a place to put a panel, and assigning to it throws the moment
# the window is built -- the headless build above only caught it because it builds
# the whole form. Checking the names statically points at the line instead.
$readOnly = @('home', 'host', 'pid', 'profile', 'args', 'input', 'this', 'matches', 'psitem',
              'psversiontable', 'psscriptroot', 'pscommandpath', 'myinvocation', 'psboundparameters',
              'executioncontext', 'foreach', 'switch', 'stacktrace', 'shellid', 'psculture', 'psuiculture',
              'pshome', 'iswindows', 'islinux', 'ismacos', 'nestedpromptlevel')
$reserved = New-Object System.Collections.Generic.List[string]
foreach ($file in 'src/lib/Ui.Logic.ps1', 'src/lib/Tui.Render.ps1', 'src/lib/Tui.Input.ps1', 'src/gui/WinCleanKit.gui.ps1') {
    $source = Get-Content (Join-Path $root $file) -Raw -Encoding UTF8
    foreach ($m in [regex]::Matches($source, '(?m)^\s*\$(\w+)\s*=')) {
        if ($readOnly -contains $m.Groups[1].Value.ToLowerInvariant()) { [void]$reserved.Add("$file -> `$$($m.Groups[1].Value)") }
    }
}
Check 'no UI file assigns to a read-only automatic variable' ($reserved.Count -eq 0) (($reserved) -join '; ')

# ---------------------------------------------------------------------------
Write-Head 'the palette is complete, readable and the only source of colour'
# A design pass is easy to undo by accident: one hardcoded colour here, one theme
# role missing there. These checks are the reason the palette cannot rot.
$roles = @($script:GuiPalette.light.Keys | Where-Object { $_ -ne 'name' } | Sort-Object)
$darkRoles = @($script:GuiPalette.dark.Keys | Where-Object { $_ -ne 'name' } | Sort-Object)
Check 'both themes define the same roles' (($roles -join ',') -eq ($darkRoles -join ',')) ($roles -join ', ')
Check 'there are roles for text, surface, border and every state' ($roles.Count -ge 17) ("{0} roles" -f $roles.Count)

$badColor = @($script:GuiPalette.Keys | ForEach-Object {
    $theme = $script:GuiPalette[$_]
    foreach ($role in $theme.Keys) {
        if ($role -eq 'name') { continue }
        if ([string]$theme[$role] -notmatch '^#[0-9A-Fa-f]{6}$') { "$_/$role = $($theme[$role])" }
    }
})
Check 'every role is a #rrggbb colour' ($badColor.Count -eq 0) (($badColor) -join '; ')

# WCAG: 4.5:1 is the normal-text threshold. Every one of these pairs is text on a
# surface that the window actually draws.
$pairs = @(
    @('text', 'window'), @('text', 'card'), @('muted', 'card'), @('muted', 'window'),
    @('brand', 'window'), @('text', 'selection'), @('onSelection', 'selection'),
    @('onBrand', 'brand'), @('onAccent', 'accent'), @('success', 'card'),
    @('caution', 'card'), @('danger', 'card'), @('controlBorder', 'card'),
    @('text', 'railBg'), @('muted', 'railBg'), @('onRailActive', 'railActive'),
    @('accent', 'window')
)
$weak = New-Object System.Collections.Generic.List[string]
foreach ($themeName in 'light', 'dark') {
    $theme = $script:GuiPalette[$themeName]
    foreach ($pair in $pairs) {
        $ratio = Get-GuiContrast -Foreground $theme[$pair[0]] -Background $theme[$pair[1]]
        # Borders are not text: 3:1 is the non-text threshold for a visible boundary.
        $floor = if ($pair[0] -eq 'controlBorder') { 3.0 } else { 4.5 }
        if ($ratio -lt $floor) { [void]$weak.Add(("{0}: {1} on {2} = {3} < {4}" -f $themeName, $pair[0], $pair[1], $ratio, $floor)) }
    }
}
Check 'every text pair clears 4.5:1 and every border 3:1' ($weak.Count -eq 0) (($weak | Select-Object -First 3) -join '; ')

$guiSourceForColor = Get-Content $guiPath -Raw -Encoding UTF8
$namedColors = @([regex]::Matches($guiSourceForColor, '\[System\.Drawing\.Color\]::([A-Za-z]+)') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -ne 'Transparent' })
$systemColors = @([regex]::Matches($guiSourceForColor, 'SystemColors\]::'))
Check 'colour comes from the theme, not from named colours' ($namedColors.Count -eq 0 -and $systemColors.Count -eq 0) ("named={0} system={1}" -f ($namedColors -join ','), $systemColors.Count)
$fromHtml = @([regex]::Matches($guiSourceForColor, 'FromHtml')).Count
Check 'hex is translated in exactly one place' ($fromHtml -eq 1) ("{0} call(s)" -f $fromHtml)
Check 'a themed border is drawn, not a system grey frame' ($guiSourceForColor -match 'function Format-GuiBorderedBox') 'FixedSingle is always the system colour'
Check 'the search hint is drawn by the predicate, not by a second rule' ($guiSourceForColor -match 'Test-GuiSearchHintShown -Controls') 'one decision, one place'

Write-Head 'the primary action stays deliberate'
Check 'Esc still closes the window' ($guiSourceForColor -match 'Escape.*Close') 'a keyboard way out'
Check 'buttons carry a minimum size and a hand cursor' (($guiSourceForColor -match 'MinimumSize = New-Object System.Drawing.Size\(104, 32\)') -and ($guiSourceForColor -match "Cursor = 'Hand'")) 'clickable, not tiny'
# A fixed width clipped 'Language: EN' to 'Language: E' on a real screen.
$notAuto = @(@('preview', 'runIt', 'applyBack', 'chooseNext', 'selectAll', 'selectNone', 'homeUse', 'homePick', 'language') | Where-Object { $c -and -not $c[$_].AutoSize })
Check 'buttons grow with their labels' ($notAuto.Count -eq 0) 'no clipped button text'
Check 'the Apply button explains itself to a screen reader' ($guiSourceForColor -match 'AccessibleDescription') 'writes a restore script first'
Check 'the theme can be forced for testing' ($guiSourceForColor -match 'WCK_GUI_THEME') 'light or dark, without changing the machine'
Check 'an explicit theme wins over the system one' ((Resolve-GuiTheme -Override 'dark') -eq 'dark') 'Resolve-GuiTheme'
Check 'an unknown theme falls back to the system' ((Resolve-GuiTheme -Override 'purple') -in @('light', 'dark')) 'never unstyled'
Check 'the engine passes the requested theme to the window' (($engineSource -match 'Open-GuiSession -Theme \$GuiTheme') -and ($engineSource -match '-ThemeOverride \$Theme')) '-GuiTheme -> Open-GuiSession -> Show-GuiSession'
Check 'the window icon is drawn, not shipped' (($guiSourceForColor -match 'function Initialize-GuiIcon') -and (-not ($guiSourceForColor -match '\.ico\b'))) 'no binary asset in a text-only download'
Check 'the restore picker is localised' (($guiSourceForColor -match "Get-GuiText -Key 'ok'") -and (-not ($guiSourceForColor -match "Text = 'OK'"))) 'no English left in a Chinese window'
Check 'the step counter is filled from the engine output' ($guiSourceForColor -match "progressLabel\.Text = ""\`$done/\`$total") 'the same numbers the engine printed'
Check 'the run result is read from the engine summary' (($guiSourceForColor -match 'ok\|skipped\|failed') -and ($guiSourceForColor -match '\$script:GuiApp\.Result\[')) 'applied/skipped/failed, not the newest folder name'
Check 'the log keeps every line the engine prints' ($guiSourceForColor -match 'Add-GuiLog') 'the status line shows one of them'
Check 'the pages are told apart by surface tone, not by lines' (($guiSourceForColor -match "'railBg'") -and ($guiSourceForColor -match 'function Format-GuiNavButton')) 'rail, bars, working area'
Check 'the window remembers what a previous run left behind' ($guiSourceForColor -match 'Get-GuiRestoreRow') 'so the overview can say when it last ran'

Write-Head 'the GUI changes nothing itself'
$guiSource = Get-Content $guiPath -Raw -Encoding UTF8
foreach ($needle2 in 'Set-ItemProperty', 'New-ItemProperty', 'Remove-ItemProperty', 'New-Item', 'Set-Service', 'Stop-Service', 'Remove-AppxPackage', 'Disable-ScheduledTask', 'reg add', 'reg delete') {
    Check "GUI file contains no '$needle2'" (-not ($guiSource -match [regex]::Escape($needle2))) 'all changes go through the engine'
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
Check 'the window can run the engine as a dry run' ($guiSource -match "engineArgs \+= '-DryRun'") 'nothing is written and no restore script is made'
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
