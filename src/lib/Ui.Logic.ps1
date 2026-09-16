<#
.SYNOPSIS
    WinCleanKit UI - pure logic layer, shared by both frontends.

.DESCRIPTION
    Everything about the interactive UI that can be decided without a screen lives
    here, as pure functions over a plain hashtable. The console TUI
    (Tui.Render.ps1 + Tui.Input.ps1) and the WinForms frontend (gui/) both drive
    this same state; only their drawing differs:

      * navigation   (move the cursor, change mode, switch pane)
      * selection    (toggle an action, a category, or the whole catalog)
      * layout math  (scroll windows, truncation, progress)
      * projection   (Get-Ui* : the same facts as control contents, for the GUI)

    No console API is touched in this file. That is deliberate: it is the reason
    the behaviour can be tested at all. The keyboard loop in Tui.Input.ps1 and the
    event wiring in gui/WinCleanKit.gui.ps1 are thin glue around these functions,
    and tests/Test-Tui.ps1 + tests/Test-Gui.ps1 exercise the logic without needing
    a terminal or a desktop.

    State shape (a plain hashtable, so tests can construct one by hand):

        Catalog   object[]  actions from catalog.json
        Groups    object[]  one entry per category: id, name, zh, count
        Selected  hashtable id -> $true for every selected action
        Mode      string    list | detail | help
        ListIndex int       cursor in the category pane
        DetailIndex int     cursor in the action pane
        Pane      string    list | detail   (which pane has focus)
        Language  string    en | zh
        Message   string    transient status line
        ScrollTop int       first visible row of the action pane

.NOTES
    Part of WinCleanKit. Imports nothing and writes nothing.
#>

Set-StrictMode -Version 2.0

# --------------------------------------------------------------------------
# Text helpers shared by every frontend
#
# These two were in the console renderer until the GUI arrived. Both are pure
# string work over catalog objects, and both frontends need exactly the same
# wording, so they live here rather than being copied.
# --------------------------------------------------------------------------

function Get-TuiText {
    <#
      Localise a catalog object, preferring the Chinese field when asked for it.
    #>
    [CmdletBinding()]
    param($Object, [string]$Base, [string]$Language)
    if ($Language -eq 'zh') {
        $alt = "${Base}_zh"
        if ($Object.PSObject.Properties.Name -contains $alt -and $Object.$alt) { return $Object.$alt }
    }
    return $Object.$Base
}

function Get-TuiTargetLine {
    <#
      One line describing what an action actually does, so the detail pane answers
      "what will this touch?" without the user opening the catalog.
    #>
    [CmdletBinding()]
    param($Action)
    switch ($Action.target) {
        'registry'   { return ("{0}\{1}\{2} = {3}" -f $Action.hive, $Action.key, $Action.name, $Action.value) }
        'service'    { return ("service {0} -> {1}" -f $Action.name, $Action.startType) }
        'task'       { return ("task {0}{1}" -f $Action.path, $Action.name) }
        'appx'       { return ("uninstall {0} + revoke provisioning" -f $Action.name) }
        'path-clean' { return ("delete cache: " + (($Action.paths | ForEach-Object { Split-Path $_ -Leaf }) -join ', ')) }
        'onedrive'   { return 'remove OneDrive client, block reinstall (data folder untouched)' }
        default      { return $Action.target }
    }
}



function Select-Default {
    <#
      The selection the interface opens with: the actions the catalog marks
      `default`. It mirrors the engine's own starting set exactly, so the screen
      and an unattended run agree on what "the basics" means.

      Everything else is opt-in, which is the whole point: there is no tier to pick
      first, and nothing re-adds an action the user has turned off.
    #>
    [CmdletBinding()]
    param($Catalog)
    $selected = @{}
    foreach ($a in $Catalog.actions) {
        if ($a.PSObject.Properties.Name -contains 'default' -and [bool]$a.default) {
            $selected[$a.id] = $true
        }
    }
    return $selected
}

function Initialize-TuiState {
    <#
      Build the initial state. Groups are precomputed so navigation never has to
      filter the catalog, and the counts they carry are what the list pane shows.

      Pass -Language 'ask' to open on the language chooser instead of in a language.
      The chooser is bilingual, so it needs no language of its own; the state carries
      'en' underneath it purely so every field is populated.
    #>
    [CmdletBinding()]
    param($Catalog, [string]$Language = 'en')

    $ask = ($Language -eq 'ask')
    $lang = if ($ask) { 'en' } else { $Language }
    $groups = New-Object System.Collections.ArrayList
    foreach ($c in $Catalog.categories) {
        $items = @($Catalog.actions | Where-Object { $_.category -eq $c.id })
        if ($items.Count -eq 0) { continue }
        $name = $c.name
        if ($lang -eq 'zh' -and $c.PSObject.Properties.Name -contains 'name_zh' -and $c.name_zh) { $name = $c.name_zh }
        [void]$groups.Add([pscustomobject]@{
            id    = $c.id
            name  = $name
            count = $items.Count
        })
    }

    return @{
        Catalog     = $Catalog
        Groups      = $groups
        Selected    = (Select-Default -Catalog $Catalog)
        Mode        = $(if ($ask) { 'language' } else { 'list' })
        ListIndex   = 0
        DetailIndex = 0
        Pane        = 'list'
        Language    = $lang
        Message     = ''
        ScrollTop   = 0
        LangIndex   = 0
    }
}

function Get-TuiRenderStamp {
    <#
      Everything a frame is drawn from, as one comparable string.

      The key loop repaints only when this changes, which makes it the single place
      that decides whether what is on screen is stale. It is a function for a
      reason: the hand-written list of fields it replaces is exactly how the
      language toggle came to redraw nothing. `l` rebuilt the state and left the old
      frame on screen, because the language was not one of the fields the loop
      compared -- and the frame is only recomputed when the loop decides the state
      moved. Any state a renderer reads and this does not return is the same bug
      waiting to happen, so tests/Test-Tui.ps1 checks both that each field changes
      the stamp and that the renderer reads nothing outside this list.
    #>
    [CmdletBinding()]
    param($State)

    # The selection is a set, so its size is not enough: an operation that swaps one
    # action for another would leave the count unchanged and, with it, the frame.
    $ids = @($State.Selected.Keys) | Sort-Object
    return (@(
        $State.Mode
        $State.Pane
        $State.Language
        $State.ListIndex
        $State.DetailIndex
        $State.ScrollTop
        $State.LangIndex
        $State.Message
        ($ids -join ',')
    ) -join '|')
}

function Get-TuiLanguageList {
    <#
      The languages the chooser offers, in the order it shows them. The first is
      what the cursor starts on, so it is also the default.
    #>
    [CmdletBinding()]
    param()
    return @('zh', 'en')
}

function Move-TuiLanguageCursor {
    <#
      Move the chooser cursor. Two entries, so it clamps like every other cursor in
      this interface rather than wrapping.
    #>
    [CmdletBinding()]
    param($State, [ValidateSet('up', 'down')][string]$Direction)
    $n = (Get-TuiLanguageList).Count
    if ($Direction -eq 'up') { $State.LangIndex = [Math]::Max(0, $State.LangIndex - 1) }
    else                     { $State.LangIndex = [Math]::Min($n - 1, $State.LangIndex + 1) }
    return $State
}

function Get-TuiLanguageChoice {
    <#
      The language the chooser cursor is on.
    #>
    [CmdletBinding()]
    param($State)
    $langs = Get-TuiLanguageList
    $i = [Math]::Max(0, [Math]::Min($State.LangIndex, $langs.Count - 1))
    return $langs[$i]
}

function Select-TuiLanguageChoice {
    <#
      Resolve the opening chooser: rebuild the state in the chosen language and move
      on to the list view.
    #>
    [CmdletBinding()]
    param($State, [ValidateSet('zh', 'en')][string]$Language)
    $picked = Select-TuiLanguage -State $State -Language $Language
    $picked.Mode = 'list'
    $picked.Pane = 'list'
    return $picked
}

function Get-TuiGroupAction {
    <#
      Actions belonging to the group under the cursor, in catalog order.
    #>
    [CmdletBinding()]
    param($State)

    if ($State.Groups.Count -eq 0) { return , @() }
    $gid = $State.Groups[$State.ListIndex].id
    , @($State.Catalog.actions | Where-Object { $_.category -eq $gid })
}

function Get-TuiActionAt {
    <#
      The action the detail cursor points at, or $null when the group is empty.
    #>
    [CmdletBinding()]
    param($State)
    $items = Get-TuiGroupAction $State
    if ($items.Count -eq 0) { return $null }
    $i = [Math]::Max(0, [Math]::Min($State.DetailIndex, $items.Count - 1))
    return $items[$i]
}

function Get-TuiSelectedCount {
    [CmdletBinding()]
    param($State)
    return $State.Selected.Count
}

function Test-TuiSelected {
    [CmdletBinding()]
    param($State, [string]$Id)
    return $State.Selected.ContainsKey($Id)
}

function Move-TuiCursor {
    <#
      Move the focused cursor by one step. Clamps rather than wraps: in a list of
      irreversible options, jumping from the last item back to the first is how
      people select the wrong thing.
    #>
    [CmdletBinding()]
    param($State, [ValidateSet('up', 'down')][string]$Direction)

    if ($State.Pane -eq 'list') {
        $n = $State.Groups.Count
        if ($n -eq 0) { return $State }
        if ($Direction -eq 'up')   { $State.ListIndex = [Math]::Max(0, $State.ListIndex - 1) }
        else                       { $State.ListIndex = [Math]::Min($n - 1, $State.ListIndex + 1) }
        # Changing group resets the action cursor, otherwise it can point past the end.
        $State.DetailIndex = 0
        $State.ScrollTop = 0
    } else {
        $items = Get-TuiGroupAction $State
        $n = $items.Count
        if ($n -eq 0) { return $State }
        if ($Direction -eq 'up')   { $State.DetailIndex = [Math]::Max(0, $State.DetailIndex - 1) }
        else                       { $State.DetailIndex = [Math]::Min($n - 1, $State.DetailIndex + 1) }
    }
    return $State
}

function Switch-TuiPane {
    [CmdletBinding()]
    param($State)
    if ($State.Mode -eq 'list') {
        $State.Pane = 'detail'
        $State.Mode = 'detail'
    } else {
        $State.Pane = 'list'
        $State.Mode = 'list'
    }
    return $State
}

function Select-TuiMode {
    [CmdletBinding()]
    param($State, [ValidateSet('list', 'detail', 'help')][string]$Mode)
    $State.Mode = $Mode
    if ($Mode -eq 'list') { $State.Pane = 'list' }
    if ($Mode -eq 'detail') { $State.Pane = 'detail' }
    return $State
}

function Select-TuiLanguage {
    <#
      Switch language. Group labels are derived from the catalog, so they have to
      be rebuilt; the selection and cursors are preserved.
    #>
    [CmdletBinding()]
    param($State, [string]$Language)
    if ($Language -notin @('en', 'zh')) { return $State }
    $rebuilt = Initialize-TuiState -Catalog $State.Catalog -Language $Language
    $rebuilt.Selected    = $State.Selected
    $rebuilt.ListIndex   = [Math]::Min($State.ListIndex, [Math]::Max(0, $rebuilt.Groups.Count - 1))
    $rebuilt.DetailIndex = $State.DetailIndex
    $rebuilt.Message     = $State.Message
    # Where the user is standing is not part of the language. Rebuilding the state
    # resets these to the opening view, so without copying them back, switching
    # language from the detail pane or the help screen would throw the user back
    # to the list -- the one thing a language toggle must never do.
    $rebuilt.Mode        = $State.Mode
    $rebuilt.Pane        = $State.Pane
    $rebuilt.ScrollTop   = $State.ScrollTop
    return $rebuilt
}

# --------------------------------------------------------------------------
# Terminal detection (still pure: it inspects the environment, never the screen)
# --------------------------------------------------------------------------

function Test-TuiSupported {
    <#
      Whether a full-screen TUI can be drawn at all.

      A redirected stdout, or a host with no interactive console, cannot be drawn
      into: painting a frame would just dump escape codes into a log. Callers must
      fall back to plain output rather than assuming this succeeds.
    #>
    [CmdletBinding()]
    param()
    try {
        if ([Console]::IsOutputRedirected) { return $false }
        if (-not [Environment]::UserInteractive) { return $false }
        if ($Host.Name -eq 'ServerRemoteHost') { return $false }
    } catch {
        # If any probe is unavailable, assume it cannot be drawn.
        return $false
    }
    return $true
}

# --------------------------------------------------------------------------
# Selection
# --------------------------------------------------------------------------

function Switch-TuiAction {
    <#
      Flip one action. This is the operation the whole redesign exists for, so it
      is a pure function that a test can call directly.
    #>
    [CmdletBinding()]
    param($State, [string]$Id)
    if ($State.Selected.ContainsKey($Id)) { $State.Selected.Remove($Id) | Out-Null }
    else { $State.Selected[$Id] = $true }
    return $State
}

function Switch-TuiCurrent {
    <#
      Flip the action under the cursor and step down one row, so repeated presses
      walk the list while selecting.
    #>
    [CmdletBinding()]
    param($State)
    $a = Get-TuiActionAt $State
    if (-not $a) { return $State }
    $State = Switch-TuiAction -State $State -Id $a.id
    $items = Get-TuiGroupAction $State
    if ($State.DetailIndex -lt ($items.Count - 1)) { $State.DetailIndex++ }
    return $State
}

function Switch-TuiGroupSelection {
    <#
      Select or clear every action in the group under the cursor.
    #>
    [CmdletBinding()]
    param($State, [bool]$Selected)
    foreach ($a in (Get-TuiGroupAction $State)) {
        if ($Selected) { $State.Selected[$a.id] = $true }
        else           { if ($State.Selected.ContainsKey($a.id)) { $State.Selected.Remove($a.id) | Out-Null } }
    }
    return $State
}

function Switch-TuiAllSelection {
    [CmdletBinding()]
    param($State, [bool]$Selected)
    if ($Selected) {
        foreach ($a in $State.Catalog.actions) { $State.Selected[$a.id] = $true }
    } else {
        $State.Selected = @{}
    }
    return $State
}

function Get-TuiGroupSelection {
    <#
      How many actions in the group under the cursor are selected, plus the total.
      The list pane renders this as a progress-style "4/22".
    #>
    [CmdletBinding()]
    param($State)
    $items = Get-TuiGroupAction $State
    $on = 0
    foreach ($a in $items) { if ($State.Selected.ContainsKey($a.id)) { $on++ } }
    return @{ Selected = $on; Total = $items.Count }
}

function Get-TuiPlan {
    <#
      The concrete list of action ids to hand to the engine, in catalog order.
      This is the contract between the UI and the executor.
    #>
    [CmdletBinding()]
    param($State)
    , @($State.Catalog.actions | Where-Object { $State.Selected.ContainsKey($_.id) } | ForEach-Object { $_.id })
}

# --------------------------------------------------------------------------
# Layout math (pure, so the windowing can be tested without a terminal)
# --------------------------------------------------------------------------

function Get-TuiWindow {
    <#
      Which slice of a list of $Total rows fits in $Height rows with the cursor at
      $Cursor, keeping the cursor visible. Returns the first visible index.
    #>
    [CmdletBinding()]
    param([int]$Total, [int]$Height, [int]$Cursor, [int]$ScrollTop = 0)
    if ($Height -le 0 -or $Total -le 0) { return 0 }
    $top = [Math]::Max(0, [Math]::Min($ScrollTop, [Math]::Max(0, $Total - $Height)))
    if ($Cursor -lt $top) { $top = $Cursor }
    if ($Cursor -ge ($top + $Height)) { $top = $Cursor - $Height + 1 }
    return [Math]::Max(0, [Math]::Min($top, [Math]::Max(0, $Total - $Height)))
}

function Get-TuiScrollTop {
    <#
      The scroll offset that keeps the current detail cursor visible in $Height rows.
    #>
    [CmdletBinding()]
    param($State, [int]$Height)
    $items = Get-TuiGroupAction $State
    return (Get-TuiWindow -Total $items.Count -Height $Height -Cursor $State.DetailIndex -ScrollTop $State.ScrollTop)
}

# --------------------------------------------------------------------------
# View model for a windowed frontend
#
# The console renderer turns state into characters; a windowed frontend turns the
# same state into control contents. Both need the same three facts about a row and
# the same wording in the detail panel, so the projection lives here -- pure, and
# testable without a screen, which is the only way tests/Test-Gui.ps1 can prove the
# two frontends agree.
# --------------------------------------------------------------------------

function Get-UiGroupRow {
    <#
      One row per category: localised name, how many of its actions are ticked, and
      whether the cursor is on it.
    #>
    [CmdletBinding()]
    param($State)

    $rows = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $State.Groups.Count; $i++) {
        $g = $State.Groups[$i]
        $sel = 0
        foreach ($a in $State.Catalog.actions) {
            if ($a.category -eq $g.id -and $State.Selected.ContainsKey($a.id)) { $sel++ }
        }
        [void]$rows.Add([pscustomobject]@{
            index    = $i
            id       = $g.id
            name     = $g.name
            selected = $sel
            total    = $g.count
            current  = ($i -eq $State.ListIndex)
        })
    }
    return $rows.ToArray()
}

function Get-UiSearchRow {
    <#
      Every action whose title, explanation, id or category name contains the search
      text, across the whole catalog rather than the focused category.

      A window is where a user looks for one change by name, and 74 rows across six
      areas is past the point where scrolling is a plan. Matching the category name
      as well is deliberate: typing "app" should find the preinstalled apps, not only
      the actions that happen to spell it out in their title.
    #>
    [CmdletBinding()]
    param($State, [string]$Filter)

    $needle = ([string]$Filter).Trim().ToLowerInvariant()
    $rows = New-Object System.Collections.Generic.List[object]
    if (-not $needle) { return $rows.ToArray() }

    $i = 0
    foreach ($a in $State.Catalog.actions) {
        $title = [string](Get-TuiText -Object $a -Base 'title' -Language $State.Language)
        $why   = [string](Get-TuiText -Object $a -Base 'why' -Language $State.Language)
        $catObj = @($State.Catalog.categories | Where-Object { $_.id -eq $a.category })
        $catName = if ($catObj.Count) { [string](Get-TuiText -Object $catObj[0] -Base 'name' -Language $State.Language) } else { '' }
        $hay = (@($title, $why, [string]$a.id, $catName) -join "`n").ToLowerInvariant()
        if ($hay.Contains($needle)) {
            [void]$rows.Add([pscustomobject]@{
                index    = $i
                id       = $a.id
                title    = $title
                checked  = $State.Selected.ContainsKey($a.id)
                current  = $false
                category = $a.category
            })
            $i++
        }
    }
    return $rows.ToArray()
}

function Get-UiActionRow {
    <#
      The actions of the focused category, in catalog order, with their tick state.

      With -Filter, the rows are the search results instead: the whole catalog, in
      catalog order, restricted to what matches. The two cases share a shape so the
      window can put either one in the same list, and Switch-GuiActionAt can map a
      row back to an id without knowing which it is looking at.
    #>
    [CmdletBinding()]
    param($State, [string]$Filter = '')

    if (([string]$Filter).Trim()) { return Get-UiSearchRow -State $State -Filter $Filter }

    # Not wrapped in @(): Get-TuiGroupAction already returns an array, and wrapping
    # it would count the array itself as one row.
    $items = Get-TuiGroupAction -State $State
    $rows = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $items.Count; $i++) {
        $a = $items[$i]
        [void]$rows.Add([pscustomobject]@{
            index   = $i
            id      = $a.id
            title   = (Get-TuiText -Object $a -Base 'title' -Language $State.Language)
            checked = $State.Selected.ContainsKey($a.id)
            current = ($i -eq [Math]::Max(0, [Math]::Min($State.DetailIndex, $items.Count - 1)))
        })
    }
    return $rows.ToArray()
}

function Get-UiSummary {
    <#
      The header a window shows instead of a title bar subtitle: what is ticked,
      and the transient message under it.
    #>
    [CmdletBinding()]
    param($State)

    $zh = ($State.Language -eq 'zh')
    $count = Get-TuiSelectedCount -State $State
    return [pscustomobject]@{
        selected = $count
        total    = $State.Catalog.actions.Count
        title    = ("{0}: {1} {2}" -f $(if ($zh) { '计划' } else { 'plan' }), $count, $(if ($zh) { '项' } else { 'actions' }))
        message  = [string]$State.Message
    }
}

function Get-UiActionDetail {
    <#
      The detail panel for one action: what it does, what it touches, and whether it
      is part of the default set. Shared by the focused-category view and the search
      results, so typing into the box cannot show a different explanation than
      browsing to the same row does.
    #>
    [CmdletBinding()]
    param($Action, [string]$Language = 'en')

    $zh = ($Language -eq 'zh')
    $isDefault = ($Action.PSObject.Properties.Name -contains 'default' -and [bool]$Action.default)
    return [pscustomobject]@{
        kind        = 'action'
        id          = $Action.id
        title       = [string](Get-TuiText -Object $Action -Base 'title' -Language $Language)
        stats       = ''
        body        = [string](Get-TuiText -Object $Action -Base 'why' -Language $Language)
        touches     = ("{0}{1}" -f $(if ($zh) { '触及: ' } else { 'Touches: ' }), (Get-TuiTargetLine -Action $Action))
        defaultLine = $(if ($zh) { '默认: ' + $(if ($isDefault) { '是' } else { '否' }) } else { 'Default: ' + $(if ($isDefault) { 'yes' } else { 'no' }) })
    }
}

function Get-UiDetail {
    <#
      What the detail panel should say about whatever has focus: the category under
      the cursor while the category list is focused, the action otherwise. Same
      wording as the console panel, composed once so the two cannot drift.

      With -Filter the focus is a search result, so the panel always describes an
      action -- there is no category to describe while a search is running.
    #>
    [CmdletBinding()]
    param($State, [string]$Filter = '')

    if (([string]$Filter).Trim()) {
        $found = @(Get-UiSearchRow -State $State -Filter $Filter)
        if ($found.Count -eq 0) { return $null }
        $idx = [Math]::Max(0, [Math]::Min($State.DetailIndex, $found.Count - 1))
        $action = @($State.Catalog.actions | Where-Object { $_.id -eq $found[$idx].id })
        if ($action.Count -eq 0) { return $null }
        return Get-UiActionDetail -Action $action[0] -Language $State.Language
    }

    $zh = ($State.Language -eq 'zh')

    if ($State.Pane -eq 'list') {
        if ($State.Groups.Count -eq 0 -or $State.ListIndex -ge $State.Groups.Count) { return $null }
        $g = $State.Groups[$State.ListIndex]
        $catObj = @($State.Catalog.categories | Where-Object { $_.id -eq $g.id })[0]
        $name = Get-TuiText -Object $catObj -Base 'name' -Language $State.Language
        $sel = 0
        foreach ($a in $State.Catalog.actions) {
            if ($a.category -eq $g.id -and $State.Selected.ContainsKey($a.id)) { $sel++ }
        }
        return [pscustomobject]@{
            kind        = 'category'
            id          = $g.id
            title       = $(if ($zh) { "[分类] $name" } else { "[category] $name" })
            stats       = $(if ($zh) { "勾选: {0}/{1} 项" -f $sel, $g.count } else { "Selected: {0}/{1}" -f $sel, $g.count })
            body        = [string](Get-TuiText -Object $catObj -Base 'description' -Language $State.Language)
            touches     = ''
            defaultLine = ''
        }
    }

    $cur = Get-TuiActionAt -State $State
    if (-not $cur) { return $null }
    return Get-UiActionDetail -Action $cur -Language $State.Language
}

function Test-UiAvailable {
    <#
      Whether a window can be drawn here at all. An SSH session, a scheduled task
      in session 0, or a machine without the assemblies must be told no before
      anything is created, so the caller can degrade instead of flashing a window
      nobody can see.

      The three inputs are injectable so tests/Test-Gui.ps1 can exercise every
      combination without needing -- or avoiding -- a desktop.
    #>
    [CmdletBinding()]
    param(
        [Nullable[bool]]$UserInteractive,
        [Nullable[bool]]$Windows,
        [Nullable[bool]]$Assemblies
    )

    $interactive = if ($PSBoundParameters.ContainsKey('UserInteractive')) { $UserInteractive } else { [Environment]::UserInteractive }
    $onWindows   = if ($PSBoundParameters.ContainsKey('Windows')) { $Windows } else { ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) }
    if (-not $interactive) { return $false }
    if (-not $onWindows) { return $false }

    if ($PSBoundParameters.ContainsKey('Assemblies')) { return [bool]$Assemblies }
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-UiPlanText {
    <#
      The plan the user is about to apply, as plain text grouped by category --
      what the console `-Plan` view prints and what a windowed frontend shows in
      its preview. Built here so both say the same thing, and so a test can read
      it without a screen.
    #>
    [CmdletBinding()]
    param($State)

    $zh = ($State.Language -eq 'zh')
    $order = @($State.Catalog.categories | ForEach-Object { $_.id })
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($cid in $order) {
        $items = @($State.Catalog.actions | Where-Object { $_.category -eq $cid -and $State.Selected.ContainsKey($_.id) })
        if ($items.Count -eq 0) { continue }
        $catObj = @($State.Catalog.categories | Where-Object { $_.id -eq $cid })[0]
        [void]$lines.Add('')
        [void]$lines.Add(("{0}  ({1})" -f (Get-TuiText -Object $catObj -Base 'name' -Language $State.Language), $items.Count))
        foreach ($a in $items) {
            [void]$lines.Add('    ' + (Get-TuiText -Object $a -Base 'title' -Language $State.Language))
        }
    }
    [void]$lines.Add('')
    $total = Get-TuiSelectedCount -State $State
    [void]$lines.Add($(if ($zh) { "合计: $total 项" } else { "Total: $total action(s)" }))
    return $lines.ToArray()
}

function Get-UiPlanFact {
    <#
      The plan as numbers a window can lay out around: the total, one row per area
      that will actually change, and how many of the ticked actions do something a
      user should think about twice (uninstall software, delete a cache).

      The engine remains the only thing that changes the system. This is what lets a
      window say "45 changes, 2 of them uninstall an app" *before* anyone presses
      anything rather than after.
    #>
    [CmdletBinding()]
    param($State)

    $selected = @($State.Catalog.actions | Where-Object { $State.Selected.ContainsKey($_.id) })

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($c in $State.Catalog.categories) {
        $items = @($selected | Where-Object { $_.category -eq $c.id })
        if ($items.Count -eq 0) { continue }
        [void]$rows.Add([pscustomobject]@{
            id    = $c.id
            name  = [string](Get-TuiText -Object $c -Base 'name' -Language $State.Language)
            count = $items.Count
        })
    }

    $kinds = @{}
    foreach ($kind in 'registry', 'service', 'task', 'appx', 'path-clean', 'onedrive') {
        $kinds[$kind] = @($selected | Where-Object { $_.PSObject.Properties['target'].Value -eq $kind }).Count
    }
    $removes = $kinds['appx'] + $kinds['onedrive']

    return [pscustomobject]@{
        total   = $selected.Count
        groups  = $rows.ToArray()
        kinds   = $kinds
        removes = $removes
        deletes = $kinds['path-clean']
        risky   = $removes + $kinds['path-clean']
    }
}
