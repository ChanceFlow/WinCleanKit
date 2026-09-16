<#
.SYNOPSIS
    WinCleanKit's windowed frontend: a WinForms shell over the shared state layer.

.DESCRIPTION
    The console UI draws characters; this draws controls. Both drive the same state
    machine in Ui.Logic.ps1, so neither contains a decision: ticking a box here
    calls Switch-TuiCurrent, exactly as pressing space does there, and the ids that
    reach the engine are the ones Get-TuiPlan assembled.

    The one thing that differs is where the work runs. The console UI hands its plan
    back and the engine applies it in the same process. A window has to stay
    responsive for 74 actions, so the engine is invoked the way the console TUI
    already invokes it for a preview -- as a child process, with an exact id list
    (-FromFile, which is authoritative), inside a background runspace whose output a
    UI timer drains onto the progress bar. Same script, same journal, same code
    path; only the process boundary differs.

    Event handlers are deliberately thin. They call one function in Ui.Logic.ps1,
    then Sync-GuiView. Shared state lives in $script:Gui, because a handler runs in
    its own scope and a local assignment there would be lost by the next click.

    Why WinForms: it is the only GUI toolkit that ships with Windows itself, so the
    download stays a folder with no installer and no runtime to fetch. The price is a
    mid-2010s look, and the styling below is restrained rather than pretending
    otherwise.

.NOTES
    Part of WinCleanKit. Requires Ui.Logic.ps1 to be loaded first.
#>

# --------------------------------------------------------------------------
# Chrome strings. The catalog owns every word the user reads about an action;
# these are the few that belong to the window itself.
# --------------------------------------------------------------------------
$script:GuiText = @{
    'title'        = @{ en = 'WinCleanKit';                            zh = 'WinCleanKit' }
    'categories'   = @{ en = 'Areas';                                  zh = '分类' }
    'actions'      = @{ en = 'Changes';                                zh = '条目' }
    'apply'        = @{ en = 'Apply...';                               zh = '执行...' }
    'preview'      = @{ en = 'Preview';                                zh = '预览' }
    'restore'      = @{ en = 'Restore...';                             zh = '还原...' }
    'language'     = @{ en = 'Language';                               zh = '语言' }
    'about'        = @{ en = 'About';                                  zh = '关于' }
    'selectAll'    = @{ en = 'Tick this area';                         zh = '勾选本类' }
    'selectNone'   = @{ en = 'Untick this area';                       zh = '取消本类' }
    'ready'        = @{ en = 'Nothing changes until you press Apply.';  zh = '在你按「执行」之前，不会改动任何东西。' }
    'confirmTitle' = @{ en = 'Apply these changes?';                   zh = '确认执行这些改动？' }
    'confirmBody'  = @{ en = 'A restore point is written to your Desktop first, and you can undo everything from there.'; zh = '会先在桌面写好还原点，之后可以从那里一键撤销全部改动。' }
    'applying'     = @{ en = 'Applying...';                            zh = '正在执行...' }
    'applyingDry'  = @{ en = 'Dry run: walking the plan, changing nothing...'; zh = '试运行：逐条走一遍，但不改任何东西...' }
    'confirmDry'   = @{ en = 'Dry run: nothing will be written and no restore point will be made.'; zh = '试运行：不会写入任何东西，也不会生成还原点。' }
    'restoring'    = @{ en = 'Restoring...';                           zh = '正在还原...' }
    'done'         = @{ en = 'Done. Restore folder:';                  zh = '完成。还原文件夹：' }
    'doneGeneric'  = @{ en = 'Done.';                                  zh = '完成。' }
    'nothing'      = @{ en = 'Nothing is ticked.';                     zh = '没有勾选任何项目。' }
    'noRestore'    = @{ en = 'No restore point found on your Desktop yet.'; zh = '桌面上还没有还原点。' }
    'restoreTitle' = @{ en = 'Restore a previous run';                 zh = '还原到以前某一次' }
    'planTitle'    = @{ en = 'Changes that will be applied';           zh = '将要执行的改动' }
    'aboutBody'    = @{ en = "WinCleanKit {0}`n`nA user-first Windows de-bloater. Every change is one you ticked, and a restore point is written before the first of them."; zh = "WinCleanKit {0}`n`n把决定权交给用户的 Windows 减负工具。每条改动都由你勾选，动手之前先写好还原点。" }
    'closeBusy'    = @{ en = 'A run is still going. Wait for it to finish.'; zh = '还在执行中，请等它跑完。' }
}

# Shared state. A handler runs in its own scope, so anything it must hand to the
# next handler lives here rather than in a local variable. The name avoids every
# parameter of src/WinCleanKit.ps1: this file is dot-sourced into that script's
# scope, and assigning to a variable the engine declared as [switch] throws.
$script:GuiApp = @{
    State    = $null
    Controls = $null
    Form     = $null
    Version  = '0.0.0'
    Engine   = ''
    DryRun   = $false
    Runner   = $null
    Queue    = $null
    Timer    = $null
    Syncing  = $false
    DpiDone  = $false
}

function Get-GuiText {
    <#
      One chrome string in one language. An unknown key fails loudly instead of
      rendering an empty button.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Language
    )

    if (-not $script:GuiText.ContainsKey($Key)) { throw "unknown GUI string: $Key" }
    $entry = $script:GuiText[$Key]
    if ($Language -eq 'zh') { return $entry.zh }
    return $entry.en
}

function Enable-GuiDpiAwareness {
    <#
      Per-monitor DPI awareness. Without it Windows bitmap-stretches the window at
      125% and every label goes soft. Best effort: a Windows that does not export
      the API keeps working, just blurrier.
    #>
    [CmdletBinding()]
    param()

    if ($script:GuiApp.DpiDone) { return [bool]$script:GuiApp.DpiDone }
    try {
        if (-not ('WinCleanKit.GuiNative' -as [type])) {
            Add-Type -Namespace WinCleanKit -Name GuiNative -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr context);
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
public static bool Enable() {
    try { if (SetProcessDpiAwarenessContext(new IntPtr(-4))) return true; } catch { }
    try { return SetProcessDPIAware(); } catch { }
    return false;
}
'@ -ErrorAction Stop
        }
        $script:GuiApp.DpiDone = [WinCleanKit.GuiNative]::Enable()
    } catch {
        $script:GuiApp.DpiDone = $false
    }
    return [bool]$script:GuiApp.DpiDone
}

function Initialize-GuiForm {
    <#
      Build the window and return it with a map of its controls. Declarative on
      purpose: no data is loaded and no events are wired here, so tests/Test-Gui.ps1
      can assert the shape of the interface without ever showing it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $State,
        [string]$Version = '0.0.0'
    )

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [void](Enable-GuiDpiAwareness)
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $lang = $State.Language
    $form = New-Object System.Windows.Forms.Form
    $form.Text = '{0} {1}' -f (Get-GuiText -Key 'title' -Language $lang), $Version
    $form.Size = New-Object System.Drawing.Size(1060, 700)
    $form.MinimumSize = New-Object System.Drawing.Size(880, 560)
    $form.StartPosition = 'CenterScreen'
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $form.KeyPreview = $true

    $main = New-Object System.Windows.Forms.SplitContainer
    $main.Dock = 'Fill'
    $main.Orientation = 'Vertical'
    $main.AccessibleName = (Get-GuiText -Key 'categories' -Language $lang)

    $left = New-Object System.Windows.Forms.SplitContainer
    $left.Dock = 'Fill'
    $left.Orientation = 'Horizontal'

    $categoryList = New-Object System.Windows.Forms.ListBox
    $categoryList.Dock = 'Fill'
    $categoryList.IntegralHeight = $false
    $categoryList.AccessibleName = (Get-GuiText -Key 'categories' -Language $lang)

    $detail = New-Object System.Windows.Forms.TableLayoutPanel
    $detail.Dock = 'Fill'
    $detail.ColumnCount = 1
    $detail.RowCount = 4
    [void]$detail.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$detail.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$detail.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100)))
    [void]$detail.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    $detail.Padding = New-Object System.Windows.Forms.Padding(8)

    $detailTitle = New-Object System.Windows.Forms.Label
    $detailTitle.AutoSize = $true
    $detailTitle.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

    $detailStats = New-Object System.Windows.Forms.Label
    $detailStats.AutoSize = $true
    $detailStats.ForeColor = [System.Drawing.Color]::DimGray

    $detailBody = New-Object System.Windows.Forms.TextBox
    $detailBody.Multiline = $true
    $detailBody.ReadOnly = $true
    $detailBody.ScrollBars = 'Vertical'
    $detailBody.BorderStyle = 'None'
    $detailBody.BackColor = [System.Drawing.SystemColors]::Window
    $detailBody.Dock = 'Fill'
    $detailBody.TabStop = $false

    $detailFoot = New-Object System.Windows.Forms.Label
    $detailFoot.AutoSize = $true
    $detailFoot.ForeColor = [System.Drawing.Color]::DimGray

    [void]$detail.Controls.Add($detailTitle, 0, 0)
    [void]$detail.Controls.Add($detailStats, 0, 1)
    [void]$detail.Controls.Add($detailBody, 0, 2)
    [void]$detail.Controls.Add($detailFoot, 0, 3)

    $left.Panel1.Controls.Add($categoryList)
    $left.Panel2.Controls.Add($detail)
    $main.Panel1.Controls.Add($left)

    $right = New-Object System.Windows.Forms.Panel
    $right.Dock = 'Fill'

    $bulk = New-Object System.Windows.Forms.FlowLayoutPanel
    $bulk.Dock = 'Top'
    $bulk.Height = 38
    $bulk.FlowDirection = 'LeftToRight'
    $bulk.Padding = New-Object System.Windows.Forms.Padding(6, 6, 6, 0)

    $selectAll = New-Object System.Windows.Forms.Button
    $selectAll.Text = Get-GuiText -Key 'selectAll' -Language $lang
    $selectAll.AutoSize = $true
    $selectNone = New-Object System.Windows.Forms.Button
    $selectNone.Text = Get-GuiText -Key 'selectNone' -Language $lang
    $selectNone.AutoSize = $true
    [void]$bulk.Controls.Add($selectAll)
    [void]$bulk.Controls.Add($selectNone)

    $actionList = New-Object System.Windows.Forms.CheckedListBox
    $actionList.Dock = 'Fill'
    $actionList.CheckOnClick = $true
    $actionList.IntegralHeight = $false
    $actionList.AccessibleName = (Get-GuiText -Key 'actions' -Language $lang)

    $right.Controls.Add($actionList)
    $right.Controls.Add($bulk)
    $main.Panel2.Controls.Add($right)

    $footer = New-Object System.Windows.Forms.Panel
    $footer.Dock = 'Bottom'
    $footer.Height = 66

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Dock = 'Bottom'
    $bar.Height = 14

    $status = New-Object System.Windows.Forms.Label
    $status.Dock = 'Top'
    $status.Height = 24
    $status.Text = Get-GuiText -Key 'ready' -Language $lang

    $buttons = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttons.Dock = 'Fill'
    $buttons.FlowDirection = 'LeftToRight'

    $controls = @{
        form = $form; mainSplit = $main; leftSplit = $left
        categoryList = $categoryList; actionList = $actionList
        detail = $detail; detailTitle = $detailTitle; detailStats = $detailStats
        detailBody = $detailBody; detailFoot = $detailFoot
        bulk = $bulk; selectAll = $selectAll; selectNone = $selectNone
        footer = $footer; buttons = $buttons; status = $status; bar = $bar
    }
    foreach ($key in 'preview', 'apply', 'restore', 'language', 'about') {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = Get-GuiText -Key $key -Language $lang
        $b.AutoSize = $true
        $b.Tag = $key
        $controls[$key] = $b
        [void]$buttons.Controls.Add($b)
    }

    $footer.Controls.Add($buttons)
    $footer.Controls.Add($status)
    $footer.Controls.Add($bar)
    $form.Controls.Add($main)
    $form.Controls.Add($footer)

    return @{ Form = $form; Controls = $controls }
}

function Sync-GuiView {
    <#
      Push the state into the controls. Every handler ends here, which is why no
      handler holds a decision: a Ui.Logic.ps1 function has already changed the
      state, and this only draws what it says.

      -SelectionOnly is the path a checkbox takes. It rebuilds everything except the
      action list itself, because clearing a CheckedListBox from inside its own
      ItemCheck event corrupts it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Controls,
        [Parameter(Mandatory)] $State,
        [string]$Version = '',
        [switch]$SelectionOnly
    )

    $lang = $State.Language
    $script:GuiApp.Syncing = $true
    try {
        $summary = Get-UiSummary -State $State
        $Controls.form.Text = '{0} {1}   {2}' -f (Get-GuiText -Key 'title' -Language $lang), $Version, $summary.title

        $Controls.categoryList.BeginUpdate()
        try {
            $Controls.categoryList.Items.Clear()
            foreach ($row in Get-UiGroupRow -State $State) {
                [void]$Controls.categoryList.Items.Add(('{0,3}/{1,-3}  {2}' -f $row.selected, $row.total, $row.name))
            }
            if ($State.ListIndex -lt $Controls.categoryList.Items.Count) {
                $Controls.categoryList.SelectedIndex = $State.ListIndex
            }
        } finally { $Controls.categoryList.EndUpdate() }

        if (-not $SelectionOnly) {
            $Controls.actionList.BeginUpdate()
            try {
                $Controls.actionList.Items.Clear()
                foreach ($row in Get-UiActionRow -State $State) {
                    [void]$Controls.actionList.Items.Add($row.title, $row.checked)
                }
                if ($Controls.actionList.Items.Count -gt 0) {
                    $Controls.actionList.SelectedIndex = [Math]::Min($State.DetailIndex, $Controls.actionList.Items.Count - 1)
                }
            } finally { $Controls.actionList.EndUpdate() }
        }

        $detail = Get-UiDetail -State $State
        if ($detail) {
            $Controls.detailTitle.Text = $detail.title
            $Controls.detailStats.Text = $detail.stats
            $Controls.detailBody.Text = $detail.body
            $Controls.detailFoot.Text = (@($detail.touches, $detail.defaultLine) | Where-Object { $_ }) -join '    '
        } else {
            $Controls.detailTitle.Text = ''
            $Controls.detailStats.Text = ''
            $Controls.detailBody.Text = ''
            $Controls.detailFoot.Text = ''
        }

        $Controls.selectAll.Text = Get-GuiText -Key 'selectAll' -Language $lang
        $Controls.selectNone.Text = Get-GuiText -Key 'selectNone' -Language $lang
        foreach ($key in 'preview', 'apply', 'restore', 'language', 'about') {
            $Controls[$key].Text = Get-GuiText -Key $key -Language $lang
        }
    } finally {
        $script:GuiApp.Syncing = $false
    }
}

function Switch-GuiActionAt {
    <#
      Tick or untick the action at a row of the action list, then redraw.

      This is what the ItemCheck event runs, lifted out of the handler so a test can
      exercise it: a checkbox cannot be clicked without a mouse, and the part that
      matters is the state change, not the click.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [int]$Index)

    $rows = @(Get-UiActionRow -State $script:GuiApp.State)
    if ($Index -lt 0 -or $Index -ge $rows.Count) { return $false }
    $script:GuiApp.State = Switch-TuiAction -State $script:GuiApp.State -Id $rows[$Index].id
    $script:GuiApp.State.DetailIndex = $Index
    $script:GuiApp.State.Pane = 'detail'
    if ($script:GuiApp.Controls) {
        # A click has already flipped the box; any other caller has not. Setting it
        # here keeps the control and the state in step -- under the same guard the
        # view sync uses, because SetItemChecked raises ItemCheck again.
        $checked = $script:GuiApp.State.Selected.ContainsKey($rows[$Index].id)
        $wasSyncing = $script:GuiApp.Syncing
        $script:GuiApp.Syncing = $true
        try { $script:GuiApp.Controls.actionList.SetItemChecked($Index, [bool]$checked) }
        finally { $script:GuiApp.Syncing = $wasSyncing }
        Sync-GuiView -Controls $script:GuiApp.Controls -State $script:GuiApp.State `
            -Version $script:GuiApp.Version -SelectionOnly
    }
    return $true
}

function Initialize-GuiLayout {
    <#
      Give the two splitters their proportions once the window has a real size.

      SplitterDistance is validated against the panes' minimum sizes *and* the
      control's current width, so every value here is checked before it is assigned.
      Returns $false when the window is too small for the proportions, which leaves
      the defaults in place rather than throwing inside an event handler.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Controls,
        [Parameter(Mandatory)] [int]$Width
    )

    try {
        $main = $Controls.mainSplit
        $left = $Controls.leftSplit
        if ($Width -le 0) { return $false }

        $mainDistance = [int]($Width * 0.42)
        if ($mainDistance -lt $main.Panel1MinSize) { return $false }
        if ($mainDistance -gt ($Width - $main.Panel2MinSize)) { return $false }
        $main.SplitterDistance = $mainDistance
        $main.Panel1MinSize = [Math]::Max($main.Panel1MinSize, [Math]::Min(330, [int]($Width * 0.30)))
        $main.Panel2MinSize = [Math]::Max($main.Panel2MinSize, [Math]::Min(380, [int]($Width * 0.28)))

        $height = $main.Panel1.Height
        $leftDistance = [int]($height * 0.42)
        if ($leftDistance -lt $left.Panel1MinSize) { return $false }
        if ($leftDistance -gt ($height - $left.Panel2MinSize)) { return $false }
        $left.SplitterDistance = $leftDistance
        $left.Panel1MinSize = [Math]::Max($left.Panel1MinSize, [Math]::Min(120, [int]($height * 0.20)))
        $left.Panel2MinSize = [Math]::Max($left.Panel2MinSize, [Math]::Min(170, [int]($height * 0.28)))
        return $true
    } catch {
        # The window is mid-layout or too small; the defaults are usable.
        return $false
    }
}

function Get-GuiRestorePoint {
    <#
      The restore folders a previous run left on the Desktop, newest first. Read
      only: this lists what a run wrote, it does not run anything.
    #>
    [CmdletBinding()]
    param()

    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop -or -not (Test-Path $desktop)) { return @() }
    return @(Get-ChildItem -Path $desktop -Directory -Filter 'WinCleanKit-*' -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'Restore-WinCleanKit.ps1') } |
        Sort-Object Name -Descending)
}

function Show-GuiPicker {
    <#
      A one-column list to pick from, used for choosing a restore point.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Owner,
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string[]]$Items
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(470, 340)
    $form.StartPosition = 'CenterParent'
    $form.Font = $Owner.Font

    $list = New-Object System.Windows.Forms.ListBox
    $list.Dock = 'Fill'
    $list.IntegralHeight = $false
    foreach ($i in $Items) { [void]$list.Items.Add($i) }
    if ($list.Items.Count -gt 0) { $list.SelectedIndex = 0 }

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = 'OK'
    $ok.DialogResult = 'OK'
    $ok.Dock = 'Bottom'
    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = 'Cancel'
    $cancel.DialogResult = 'Cancel'
    $cancel.Dock = 'Bottom'

    $form.Controls.Add($list)
    $form.Controls.Add($cancel)
    $form.Controls.Add($ok)
    $form.AcceptButton = $ok
    $form.CancelButton = $cancel

    $result = $form.ShowDialog($Owner)
    $picked = if ($result -eq 'OK') { [string]$list.SelectedItem } else { [string]'' }
    $form.Dispose()
    return $picked
}

function Show-GuiLanguageChooser {
    <#
      The same question the console chooser asks, in a window. Bilingual by
      necessity: it is shown before a language exists.
    #>
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    [void](Enable-GuiDpiAwareness)
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'WinCleanKit'
    $form.Size = New-Object System.Drawing.Size(430, 200)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = '请选择界面语言 / Choose your language'
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(24, 26)

    $zh = New-Object System.Windows.Forms.Button
    $zh.Text = '1  中文'
    $zh.Location = New-Object System.Drawing.Point(24, 74)
    $zh.Size = New-Object System.Drawing.Size(170, 42)
    $zh.DialogResult = 'OK'

    $en = New-Object System.Windows.Forms.Button
    $en.Text = '2  English'
    $en.Location = New-Object System.Drawing.Point(214, 74)
    $en.Size = New-Object System.Drawing.Size(170, 42)
    $en.DialogResult = 'Cancel'

    $form.Controls.Add($label)
    $form.Controls.Add($zh)
    $form.Controls.Add($en)
    $form.AcceptButton = $zh

    $result = $form.ShowDialog()
    $form.Dispose()
    if ($result -eq 'OK') { return 'zh' }
    return 'en'
}

function Invoke-GuiEngine {
    <#
      Run a command line in a background runspace and stream its output into the
      queue the UI timer drains. One helper for both directions: applying the plan
      and running a restore script are the same shape of work.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Command,
        [Parameter(Mandatory)] [string[]]$Arguments,
        [Parameter(Mandatory)] [string]$BusyText
    )

    $controls = $script:GuiApp.Controls
    $controls.preview.Enabled = $false
    $controls.apply.Enabled = $false
    $controls.restore.Enabled = $false
    $controls.language.Enabled = $false
    $controls.bar.Value = 0
    $controls.status.Text = $BusyText

    $ps = [PowerShell]::Create()
    [void]$ps.AddScript({
        param($Command, $Arguments, $Queue)
        # A redirected engine stream is not a console, but say it explicitly: colour
        # written into a queue would surface as escape codes in the status line.
        $env:NO_COLOR = '1'
        $out = & $Command @Arguments 2>&1
        foreach ($l in $out) { $Queue.Enqueue([string]$l) }
    }).AddArgument($Command).AddArgument($Arguments).AddArgument($script:GuiApp.Queue)
    $script:GuiApp.Runner = $ps
    [void]$ps.BeginInvoke()
    $script:GuiApp.Timer.Start()
}

function Show-GuiSession {
    <#
      Run one windowed session.

      Returns $null always: the window owns the whole interaction and runs the engine
      itself. It sets $script:UiApplied when a run happened and $script:UiOutcome for
      the caller (3 = no desktop here, 0 = the window closed), so the caller can tell
      "nothing to do" from "already done".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Catalog,
        [Parameter(Mandatory)] [string]$Engine,
        [string]$Language = 'en',
        [string]$Version = '0.0.0',
        [switch]$DryRun
    )

    if (-not (Test-UiAvailable)) {
        $script:UiOutcome = 3
        Write-Warning 'No desktop is available for a window, so the graphical interface cannot start.'
        return $null
    }

    # A fault in an event handler should not end in the raw .NET dialog: say what
    # happened, keep the window usable, and leave applying to the user. This has to
    # run before the first control exists -- Windows refuses the change afterwards.
    [System.Windows.Forms.Application]::SetUnhandledExceptionMode('CatchException')
    [System.Windows.Forms.Application]::add_ThreadException({
        $ex = $args[-1].Exception
        $status = ''
        if ($script:GuiApp.Controls) { $status = $script:GuiApp.Controls.status.Text }
        $text = '{0}{1}{1}{2}' -f $ex.Message, [Environment]::NewLine, $status
        [void][System.Windows.Forms.MessageBox]::Show($text,
            (Get-GuiText -Key 'title' -Language 'en'), 'OK', 'Error')
    })

    $lang = $Language
    if ($lang -eq 'ask') { $lang = Show-GuiLanguageChooser }

    $script:UiOutcome = 0
    $script:UiApplied = $false
    $script:GuiApp.Syncing = $false
    $script:GuiApp.Version = $Version
    $script:GuiApp.Engine = $Engine
    $script:GuiApp.DryRun = [bool]$DryRun
    $script:GuiApp.State = Initialize-TuiState -Catalog $Catalog -Language $lang

    $built = Initialize-GuiForm -State $script:GuiApp.State -Version $Version
    $script:GuiApp.Form = $built.Form
    $script:GuiApp.Controls = $built.Controls

    $form = $script:GuiApp.Form
    $controls = $script:GuiApp.Controls

    $script:GuiApp.Queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 120
    $script:GuiApp.Timer = $timer

    $timer.Add_Tick({
        $line = ''
        while ($script:GuiApp.Queue.TryDequeue([ref]$line)) {
            if ($line -match '\[\s*(\d+)\s*/\s*(\d+)\s*\]') {
                $script:GuiApp.Controls.bar.Maximum = [int]$Matches[2]
                $script:GuiApp.Controls.bar.Value = [Math]::Min([int]$Matches[1], $script:GuiApp.Controls.bar.Maximum)
            }
            if ($line.Trim()) { $script:GuiApp.Controls.status.Text = $line.Trim() }
        }
        $runner = $script:GuiApp.Runner
        if ($runner -and $runner.InvocationStateInfo.State -in @('Completed', 'Failed', 'Stopped')) {
            $script:GuiApp.Timer.Stop()
            foreach ($key in 'preview', 'apply', 'restore', 'language') {
                $script:GuiApp.Controls[$key].Enabled = $true
            }
            $newest = @(Get-GuiRestorePoint) | Select-Object -First 1
            $lang = $script:GuiApp.State.Language
            $script:GuiApp.Controls.status.Text = if ($newest) {
                '{0} {1}' -f (Get-GuiText -Key 'done' -Language $lang), $newest.Name
            } else {
                Get-GuiText -Key 'doneGeneric' -Language $lang
            }
            $runner.Dispose()
            $script:GuiApp.Runner = $null
        }
    })

    # ---- events ------------------------------------------------------------
    $controls.categoryList.Add_SelectedIndexChanged({
        if ($script:GuiApp.Syncing) { return }
        if ($controls.categoryList.SelectedIndex -lt 0) { return }
        $script:GuiApp.State.ListIndex = $controls.categoryList.SelectedIndex
        $script:GuiApp.State.DetailIndex = 0
        $script:GuiApp.State.Pane = 'list'
        Sync-GuiView -Controls $controls -State $script:GuiApp.State -Version $script:GuiApp.Version
    })

    $controls.actionList.Add_SelectedIndexChanged({
        if ($script:GuiApp.Syncing) { return }
        if ($controls.actionList.SelectedIndex -lt 0) { return }
        $script:GuiApp.State.Pane = 'detail'
        $script:GuiApp.State.DetailIndex = $controls.actionList.SelectedIndex
        Sync-GuiView -Controls $controls -State $script:GuiApp.State -Version $script:GuiApp.Version -SelectionOnly
    })

    # ItemCheck fires before the box flips and rebuilding this control inside its own
    # event corrupts it, so the state change is queued to run right after.
    $controls.actionList.Add_ItemCheck({
        if ($script:GuiApp.Syncing) { return }
        $index = $args[-1].Index
        if ($index -lt 0) { return }
        # ItemCheck fires before the box flips and rebuilding this control inside its
        # own event corrupts it, so the work happens right after the event returns.
        $form.BeginInvoke([Action]{ Switch-GuiActionAt -Index $index }) | Out-Null
    })

    $controls.selectAll.Add_Click({
        $script:GuiApp.State = Switch-TuiGroupSelection -State $script:GuiApp.State -Selected $true
        Sync-GuiView -Controls $script:GuiApp.Controls -State $script:GuiApp.State -Version $script:GuiApp.Version
    })

    $controls.selectNone.Add_Click({
        $script:GuiApp.State = Switch-TuiGroupSelection -State $script:GuiApp.State -Selected $false
        Sync-GuiView -Controls $script:GuiApp.Controls -State $script:GuiApp.State -Version $script:GuiApp.Version
    })

    $controls.preview.Add_Click({
        $text = (Get-UiPlanText -State $script:GuiApp.State) -join [Environment]::NewLine
        if (-not $script:GuiApp.State.Selected.Count) { $text = Get-GuiText -Key 'nothing' -Language $script:GuiApp.State.Language }
        [void][System.Windows.Forms.MessageBox]::Show($form, $text,
            (Get-GuiText -Key 'planTitle' -Language $script:GuiApp.State.Language), 'OK', 'Information')
    })

    $controls.apply.Add_Click({
        $state = $script:GuiApp.State
        $ids = @(Get-TuiPlan -State $state)
        if ($ids.Count -eq 0) {
            [void][System.Windows.Forms.MessageBox]::Show($form, (Get-GuiText -Key 'nothing' -Language $state.Language),
                (Get-GuiText -Key 'title' -Language $state.Language), 'OK', 'Warning')
            return
        }
        $body = Get-GuiText -Key 'confirmBody' -Language $state.Language
        if ($script:GuiApp.DryRun) { $body = Get-GuiText -Key 'confirmDry' -Language $state.Language }
        $question = '{0}{1}{1}{2} {3}' -f $body,
            [Environment]::NewLine, (Get-GuiText -Key 'actions' -Language $state.Language), $ids.Count
        $yes = [System.Windows.Forms.MessageBox]::Show($form, $question,
            (Get-GuiText -Key 'confirmTitle' -Language $state.Language), 'YesNo', 'Question')
        if ($yes -ne 'Yes') { return }

        # -FromFile is the authoritative path: the engine applies exactly these ids
        # and nothing else, which is the same contract the console UI relies on.
        $idFile = Join-Path ([IO.Path]::GetTempPath()) ('wck-' + [Guid]::NewGuid().ToString('N').Substring(0, 8) + '.txt')
        [IO.File]::WriteAllLines($idFile, [string[]]$ids, (New-Object System.Text.UTF8Encoding($false)))
        $script:UiApplied = $true
        $engineArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:GuiApp.Engine,
                        '-Apply', '-NoPrompt', '-FromFile', $idFile, '-Language', $state.Language, '-EmitJson')
        if ($script:GuiApp.DryRun) { $engineArgs += '-DryRun' }
        $busy = Get-GuiText -Key $(if ($script:GuiApp.DryRun) { 'applyingDry' } else { 'applying' }) -Language $state.Language
        Invoke-GuiEngine -Command 'powershell' -BusyText $busy -Arguments $engineArgs
    })

    $controls.restore.Add_Click({
        $points = @(Get-GuiRestorePoint)
        if ($points.Count -eq 0) {
            [void][System.Windows.Forms.MessageBox]::Show($form, (Get-GuiText -Key 'noRestore' -Language $script:GuiApp.State.Language),
                (Get-GuiText -Key 'restoreTitle' -Language $script:GuiApp.State.Language), 'OK', 'Information')
            return
        }
        $picked = Show-GuiPicker -Owner $form -Title (Get-GuiText -Key 'restoreTitle' -Language $script:GuiApp.State.Language) `
            -Items @($points | ForEach-Object { $_.Name })
        if (-not $picked) { return }
        $yes = [System.Windows.Forms.MessageBox]::Show($form, $picked,
            (Get-GuiText -Key 'restoreTitle' -Language $script:GuiApp.State.Language), 'YesNo', 'Warning')
        if ($yes -ne 'Yes') { return }

        $scriptFile = Join-Path (Join-Path ([Environment]::GetFolderPath('Desktop')) $picked) 'Restore-WinCleanKit.ps1'
        Invoke-GuiEngine -Command 'powershell' -BusyText (Get-GuiText -Key 'restoring' -Language $script:GuiApp.State.Language) `
            -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptFile)
    })

    $controls.language.Add_Click({
        $next = if ($script:GuiApp.State.Language -eq 'zh') { 'en' } else { 'zh' }
        $script:GuiApp.State = Select-TuiLanguage -State $script:GuiApp.State -Language $next
        Sync-GuiView -Controls $script:GuiApp.Controls -State $script:GuiApp.State -Version $script:GuiApp.Version
        $controls.status.Text = Get-GuiText -Key 'ready' -Language $script:GuiApp.State.Language
    })

    $controls.about.Add_Click({
        $body = Get-GuiText -Key 'aboutBody' -Language $script:GuiApp.State.Language
        [void][System.Windows.Forms.MessageBox]::Show($form, ($body -f $script:GuiApp.Version),
            (Get-GuiText -Key 'title' -Language $script:GuiApp.State.Language), 'OK', 'Information')
    })

    # A SplitContainer validates SplitterDistance against the pane minimum sizes and
    # against its current width, which is 150px until the form lays out -- so the
    # proportions are applied once the window is on screen.
    $form.Add_Shown({
        [void](Initialize-GuiLayout -Controls $script:GuiApp.Controls -Width $script:GuiApp.Form.ClientSize.Width)
    })

    $form.Add_KeyDown({
        $key = $args[-1]
        switch ($key.KeyCode) {
            'Escape' { $form.Close() }
            'F1'     { $controls.about.PerformClick() }
            'F5'     { $controls.preview.PerformClick() }
            'F9'     { $controls.apply.PerformClick() }
            'L'      { if ($key.Control) { $controls.language.PerformClick() } }
            'A'      { if ($key.Control) { $controls.selectAll.PerformClick() } }
            'N'      { if ($key.Control) { $controls.selectNone.PerformClick() } }
        }
    })

    $form.Add_FormClosing({
        if ($script:GuiApp.Runner) {
            # Closing mid-run would orphan a process that is writing to the system.
            $args[-1].Cancel = $true
            $script:GuiApp.Controls.status.Text = Get-GuiText -Key 'closeBusy' -Language $script:GuiApp.State.Language
        }
    })

    # ---- run ---------------------------------------------------------------
    Sync-GuiView -Controls $controls -State $script:GuiApp.State -Version $Version
    [void]$form.ShowDialog()
    $timer.Dispose()
    $form.Dispose()
    return $null
}
