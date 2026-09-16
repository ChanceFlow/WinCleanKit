<#
.SYNOPSIS
    WinCleanKit - the windowed frontend.

.DESCRIPTION
    A WinForms shell over the shared state machine in src/lib/Ui.Logic.ps1. It draws
    a state and writes back a state; every decision -- what is ticked, what the plan
    is, what a row means -- belongs to the logic layer, and every change to the
    machine belongs to the engine. This file owns only the window.

    The window is laid out as five pages behind a navigation rail, because that is
    how the tools people already use for this job are laid out, and because it
    matches what the user is actually doing:

        overview  where am I, what does this do, what happens if I just press the
                  recommended set (the answer to "I do not want to read 74 rows")
        choose    the catalog, one area at a time or as search results, with the
                  explanation for whatever has focus
        apply     the plan as a list of what will change, then the run, its progress
                  and its output in the same place
        restore   the backups previous runs left on the Desktop, and the way back
        about     version, licence, where the files are, keyboard

    Choosing and running are deliberately *different pages*: the button that changes
    the machine is not on the page where you tick things, and it is not the form's
    AcceptButton either. Enter cannot change this computer.

    WinForms, not WPF, and no installer: the whole download stays a folder of text
    with nothing to fetch and nothing to trust beyond the scripts the user can read.
    The window follows the Windows light/dark preference and can be forced with
    -GuiTheme or WCK_GUI_THEME.

.NOTES
    Part of WinCleanKit. Dot-sourced by src/WinCleanKit.ps1 when -Gui is used.
    Changes nothing itself: no registry, no service, no package, no scheduled task.
#>

# --------------------------------------------------------------------------
# Chrome strings. The catalog owns every word the user reads about an action;
# these are the few that belong to the window itself.
# --------------------------------------------------------------------------
$script:GuiText = @{
    'title'        = @{ en = 'WinCleanKit';                            zh = 'WinCleanKit' }
    'language'     = @{ en = 'Language';                               zh = '语言' }
    'languageNow'  = @{ en = 'Language: {0}';                          zh = '语言：{0}' }
    'ok'           = @{ en = 'OK';                                     zh = '确定' }
    'cancel'       = @{ en = 'Cancel';                                 zh = '取消' }

    # --- the rail ---------------------------------------------------------
    'navOverview'      = @{ en = 'Overview';                           zh = '概览' }
    'navOverviewHint'  = @{ en = 'What this does';                     zh = '这是在做什么' }
    'navChoose'        = @{ en = 'Choose';                             zh = '选择' }
    'navChooseHint'    = @{ en = '{0} ticked';                         zh = '已勾选 {0} 项' }
    'navApply'         = @{ en = 'Apply';                              zh = '执行' }
    'navApplyHint'     = @{ en = 'Review and run';                     zh = '检查并执行' }
    'navRestore'       = @{ en = 'Restore';                            zh = '还原' }
    'navRestoreHint'   = @{ en = '{0} backup(s)';                      zh = '{0} 个备份' }
    'navAbout'         = @{ en = 'About';                              zh = '关于' }
    'navAboutHint'     = @{ en = 'Version, licence';                   zh = '版本与许可' }
    'navKeys'          = @{ en = 'Ctrl+1-5 switch pages';              zh = 'Ctrl+1-5 切换页面' }

    # --- overview ---------------------------------------------------------
    'homeTitle'    = @{ en = "This PC advertises to you.`nYou can stop it."; zh = "这台电脑一直在向你推销。`n你可以让它停下。" }
    'homeLead'     = @{ en = 'Everything below is a setting Windows already has. WinCleanKit turns the ones you pick off, and writes a restore script first so you can put them back.'; zh = '下面的每一项都是 Windows 本来就有的设置。WinCleanKit 只关掉你勾选的那些，并在动手之前写好还原脚本，随时可以改回来。' }
    'homeFacts'    = @{ en = "{0}    ·    {1} changes in {2} areas";  zh = "{0}    ·    {1} 条改动，分 {2} 个分类" }
    'homeUse'      = @{ en = 'Use the recommended set ({0})';          zh = '使用推荐设置（{0} 项）' }
    'homeUseHint'  = @{ en = 'Ticks the safe, widely wanted changes and shows you the list before anything runs.'; zh = '勾选那些安全、多数人都想要的改动，然后先把清单给你看，再执行。' }
    'homePick'     = @{ en = 'Choose them myself';                     zh = '我自己挑' }
    'homeSafety'   = @{ en = "No installer, no service, no background process. The window closes and WinCleanKit is gone.`nNothing is deleted except the app packages and caches you tick; your files are never touched.`nEvery run leaves a restore script on your Desktop."; zh = "没有安装器、没有后台服务、没有常驻进程，窗口关掉它就不存在了。`n除了你勾选的预装应用和缓存，不会删任何东西；你的文件永远不会被动。`n每次执行都会在桌面留下一份还原脚本。" }
    'homeLastRun'  = @{ en = 'Last run: {0}';                          zh = '上次执行：{0}' }
    'homeNever'    = @{ en = 'Nothing has been applied from this window yet.'; zh = '这个窗口还没有执行过任何改动。' }

    # --- choose -----------------------------------------------------------
    'search'       = @{ en = 'Search';                                 zh = '搜索' }
    'searchHint'   = @{ en = 'Search {0} changes by name, area or what they touch'; zh = '按名称、分类或触及的内容搜索这 {0} 条改动' }
    'searchEmpty'  = @{ en = 'Nothing matches that.';                  zh = '没有匹配的改动。' }
    'chooseCount'  = @{ en = '{0} of {1} ticked';                      zh = '已勾选 {0}/{1} 项' }
    'chooseNext'   = @{ en = 'Next: review';                           zh = '下一步：检查' }
    'selectAll'    = @{ en = 'Tick this area';                         zh = '勾选本类' }
    'selectNone'   = @{ en = 'Untick this area';                       zh = '取消本类' }
    'listEmpty'    = @{ en = 'This area has no changes.';              zh = '这个分类下没有条目。' }

    # --- apply ------------------------------------------------------------
    'applyTitle'   = @{ en = 'This is what will change';               zh = '将要执行的改动' }
    'applyFacts'   = @{ en = '{0} changes: registry {1}, services {2}, scheduled tasks {3}, software {4}'; zh = '{0} 条改动：注册表 {1}、服务 {2}、计划任务 {3}、软件 {4}' }
    'applyRisky'   = @{ en = '{0} of them uninstall an app or delete a cache -- read the list before running.'; zh = '其中 {0} 项会卸载应用或删除缓存 —— 执行前请先看清单。' }
    'applyNothing' = @{ en = 'Nothing is ticked. Go back and choose at least one change.'; zh = '还没有勾选任何项目。返回去至少选一项。' }
    'applyBack'    = @{ en = 'Back to choosing';                       zh = '返回选择' }
    'applyLog'     = @{ en = 'Output';                                 zh = '输出' }
    'applyLogIdle' = @{ en = 'The run output appears here.';            zh = '执行时的输出会显示在这里。' }
    'preview'      = @{ en = 'Preview';                                zh = '预览' }
    'runIt'        = @{ en = 'Apply {0} changes';                      zh = '执行这 {0} 项' }

    # --- restore ----------------------------------------------------------
    'restoreTitle' = @{ en = 'Undo a previous run';                    zh = '撤销以前某一次执行' }
    'restoreLead'  = @{ en = 'Every run writes a restore script to your Desktop. Pick the run you want to undo; nothing else is touched.'; zh = '每次执行都会在桌面写一份还原脚本。选你要撤销的那一次，其它东西不会被动。' }
    'restoreNone'  = @{ en = 'No backup yet. One is written to your Desktop before the first change.'; zh = '还没有备份。第一次改动之前会写到桌面。' }
    'restoreRun'   = @{ en = 'Undo this run';                          zh = '撤销这一次' }
    'restoreOpen'  = @{ en = 'Open folder';                            zh = '打开文件夹' }
    'restoring'    = @{ en = 'Restoring...';                           zh = '正在还原...' }
    'restorePick'  = @{ en = 'Restore which run?';                     zh = '要撤销哪一次？' }
    'restorePath'  = @{ en = 'Folder: {0}';                            zh = '文件夹：{0}' }

    # --- about ------------------------------------------------------------
    'aboutTitle'   = @{ en = 'About';                                  zh = '关于' }
    'aboutBody'    = @{ en = "WinCleanKit {0}`n`nMIT licence. No installer, no service, no telemetry of its own.`nEvery change is one you ticked; the engine applies it and writes a restore script to your Desktop first.`n`nProject home: {1}`n`nEsc closes this window  ·  F1 this page  ·  F5 preview  ·  F9 apply`nCtrl+F search  ·  Ctrl+L language  ·  Ctrl+A tick the area  ·  Ctrl+N untick the area  ·  Ctrl+1-5 pages"; zh = "WinCleanKit {0}`n`nMIT 许可。没有安装器、没有后台服务、自身不收集任何遥测。`n每条改动都由你勾选；引擎负责执行，并在动手之前把还原脚本写到桌面。`n`n项目主页：{1}`n`nEsc 关闭窗口  ·  F1 本页  ·  F5 预览  ·  F9 执行`nCtrl+F 搜索  ·  Ctrl+L 语言  ·  Ctrl+A 勾选本类  ·  Ctrl+N 取消本类  ·  Ctrl+1-5 切换页面" }

    # --- run state --------------------------------------------------------
    'planTitle'    = @{ en = 'Changes that will be applied';           zh = '将要执行的改动' }
    'nothing'      = @{ en = 'Nothing is ticked.';                     zh = '没有勾选任何项目。' }
    'confirmTitle' = @{ en = 'Apply these changes?';                   zh = '确认执行这些改动？' }
    'confirmBody'  = @{ en = 'A restore script is written to your Desktop first, and you can undo everything from there.'; zh = '会先在桌面写好还原脚本，之后可以从那里一键撤销全部改动。' }
    'confirmDry'   = @{ en = 'Dry run: nothing will be written and no restore script will be made.'; zh = '试运行：不会写入任何东西，也不会生成还原脚本。' }
    'applying'     = @{ en = 'Applying...';                            zh = '正在执行...' }
    'applyingDry'  = @{ en = 'Dry run: walking the plan, changing nothing...'; zh = '试运行：逐条走一遍，但不改任何东西...' }
    'ready'        = @{ en = 'Nothing changes until you press Apply.';  zh = '在你按「执行」之前，不会改动任何东西。' }
    'statusLabel'  = @{ en = 'Status';                                 zh = '状态' }
    'progressLabel' = @{ en = 'Progress';                              zh = '进度' }
    'applyHint'    = @{ en = 'Applies the ticked changes. A restore script is written to your Desktop first.'; zh = '执行已勾选的改动。动手之前会先在桌面写好还原脚本。' }
    'done'         = @{ en = 'Done: {0} applied, {1} skipped, {2} failed.'; zh = '完成：成功 {0} 项，跳过 {1} 项，失败 {2} 项。' }
    'doneGeneric'  = @{ en = 'Done.';                                  zh = '完成。' }
    'doneFolder'   = @{ en = 'Backup folder: {0}';                     zh = '备份文件夹：{0}' }
    'closeBusy'    = @{ en = 'A run is still going. Wait for it to finish.'; zh = '还在执行中，请等它跑完。' }
}

# Shared state. A handler runs in its own scope, so anything it must hand to the
# next handler lives here rather than in a local variable. The name avoids every
# parameter of src/WinCleanKit.ps1: this file is dot-sourced into that script's
# scope, and assigning to a variable the engine declared as [switch] throws.
# Read by the engine after the session ends, whatever the outcome: "the window
# already ran the engine" is the one thing it must not guess.
$script:UiApplied = $false

$script:GuiApp = @{
    State    = $null
    Controls = $null
    Form     = $null
    Version  = '0.0.0'
    Engine   = ''
    Theme    = $null
    Icon     = $null
    DryRun   = $false
    Runner   = $null
    Queue    = $null
    Timer    = $null
    Syncing  = $false
    DpiDone  = $false
    # Window-only state. None of this belongs in the shared state machine: the
    # console frontend has no pages and no search box, and inventing a page for it
    # would be a field every renderer has to ignore.
    Page     = 'home'
    Filter   = ''
    Facts    = ''
    LastRun  = ''
    Restore  = @()
    Result   = @{}
}

# --------------------------------------------------------------------------
# Colour, as semantic roles rather than hexadecimal in the layout code
#
# The console frontend already has one palette in $script:Ink (brand, accent,
# success, caution, danger, muted, body); this is the same vocabulary for a window,
# with a light and a dark set so the window can follow Windows itself. Values come
# from the professional-tool palette the design search returned (navy primary, blue
# accent, green for done, red for failure) with the text-safe variants used for
# *text*: a colour that works as a fill is often too light to read as a label, and
# tests/Test-Gui.ps1 checks every pair it can find for 4.5:1.
#
# The three zones are told apart by surface tone rather than by lines: the rail is
# railBg, the top and bottom bars are card, the working area is window.
# --------------------------------------------------------------------------
$script:GuiPalette = @{
    light = @{
        name        = 'light'
        window      = '#F8FAFC'
        card        = '#FFFFFF'
        text        = '#0F172A'
        muted       = '#475569'
        border      = '#E4E7EB'
        controlBorder = '#64748B'
        brand       = '#1E3A5F'
        onBrand     = '#FFFFFF'
        accent      = '#2563EB'
        onAccent    = '#FFFFFF'
        success     = '#047857'
        caution     = '#B45309'
        danger      = '#B91C1C'
        selection   = '#DBEAFE'
        onSelection = '#0F172A'
        railBg      = '#EDF1F7'
        railActive  = '#DBEAFE'
        onRailActive = '#0F172A'
    }
    dark = @{
        name        = 'dark'
        window      = '#0B1220'
        card        = '#111C2E'
        text        = '#E2E8F0'
        muted       = '#94A3B8'
        border      = '#334155'
        controlBorder = '#94A3B8'
        brand       = '#93C5FD'
        onBrand     = '#0B1220'
        accent      = '#60A5FA'
        onAccent    = '#0B1220'
        success     = '#34D399'
        caution     = '#FBBF24'
        danger      = '#F87171'
        selection   = '#1E3A5F'
        onSelection = '#F8FAFC'
        railBg      = '#0E1729'
        railActive  = '#1E3A5F'
        onRailActive = '#F8FAFC'
    }
}

function Get-GuiTheme {
    <#
      One theme by name, defaulting to the light one so an unknown value cannot
      leave the window unstyled.
    #>
    [CmdletBinding()]
    param([string]$Name = 'light')

    if ($script:GuiPalette.ContainsKey($Name)) { return $script:GuiPalette[$Name] }
    return $script:GuiPalette.light
}

function Get-GuiSystemTheme {
    <#
      Which theme Windows is using for applications. Read-only, and best-effort: a
      machine that will not answer gets the light theme rather than an error.

      WCK_GUI_THEME=light|dark overrides it, which is how the window can be checked
      in the theme the machine is not currently using -- and how a user who runs
      Windows in light mode can ask for the dark window anyway.
    #>
    [CmdletBinding()]
    param()

    $forced = [string]$env:WCK_GUI_THEME
    if ($forced -in @('light', 'dark')) { return $forced }

    try {
        $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $value = (Get-ItemProperty -Path $key -Name 'AppsUseLightTheme' -ErrorAction Stop).AppsUseLightTheme
        if ($value -eq 0) { return 'dark' }
        return 'light'
    } catch {
        return 'light'
    }
}

function Resolve-GuiTheme {
    <#
      Which theme to draw: an explicit request wins, otherwise Windows decides. The
      explicit path exists so the window can be checked in the theme the machine is
      not using, without changing the machine's settings.
    #>
    [CmdletBinding()]
    param([string]$Override = 'system')

    if ($Override -in @('light', 'dark')) { return $Override }
    return Get-GuiSystemTheme
}

function Get-GuiContrast {
    <#
      WCAG relative-luminance contrast ratio between two #rrggbb colours, so a test
      can hold the palette to the thresholds instead of trusting an eye.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Foreground,
        [Parameter(Mandatory)][string]$Background
    )

    $luminance = {
        param([string]$Hex)
        $hex = $Hex.TrimStart('#')
        $parts = @(0, 2, 4 | ForEach-Object { [Convert]::ToInt32($hex.Substring($_, 2), 16) / 255 })
        $linear = @($parts | ForEach-Object {
            if ($_ -le 0.03928) { $_ / 12.92 } else { [Math]::Pow(($_ + 0.055) / 1.055, 2.4) }
        })
        return (0.2126 * $linear[0]) + (0.7152 * $linear[1]) + (0.0722 * $linear[2])
    }

    $a = & $luminance $Foreground
    $b = & $luminance $Background
    $lighter = [Math]::Max($a, $b)
    $darker = [Math]::Min($a, $b)
    return [Math]::Round(($lighter + 0.05) / ($darker + 0.05), 2)
}

function Get-GuiInk {
    <#
      The colour for a semantic role in a theme. Unknown roles are a mistake, not a
      default: the window should never quietly paint something the wrong colour.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Theme,
        [Parameter(Mandatory)][string]$Role
    )

    if (-not $Theme.ContainsKey($Role)) { throw "unknown theme role: $Role" }
    return [System.Drawing.ColorTranslator]::FromHtml([string]$Theme[$Role])
}

function Initialize-GuiIcon {
    <#
      The window icon, drawn rather than shipped: a rounded tile with a check mark.
      Keeping it as code avoids a binary asset in a repository whose whole download
      is text, and it scales to whatever size Windows asks for.
    #>
    [CmdletBinding()]
    param(
        [int]$Size = 32,
        $Theme
    )

    if (-not $Theme) { $Theme = Get-GuiTheme -Name (Get-GuiSystemTheme) }
    # ::new rather than New-Object Type(args): inside a parenthesised argument list
    # PowerShell evaluates the comma operator first, so "0, 0, $Size - 1, $Size - 1"
    # becomes an array minus an int and throws before any constructor runs.
    $bmp = [System.Drawing.Bitmap]::new($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode = 'AntiAlias'
        $g.Clear([System.Drawing.Color]::Transparent)
        $brush = [System.Drawing.SolidBrush]::new((Get-GuiInk -Theme $Theme -Role 'brand'))
        $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $corner = [int]($Size * 0.18)
        $inner = $Size - 1
        $rect = [System.Drawing.Rectangle]::new(0, 0, $inner, $inner)
        $path.AddArc($rect.X, $rect.Y, $corner * 2, $corner * 2, 180, 90)
        $path.AddArc(($rect.Right - $corner * 2), $rect.Y, $corner * 2, $corner * 2, 270, 90)
        $path.AddArc(($rect.Right - $corner * 2), ($rect.Bottom - $corner * 2), $corner * 2, $corner * 2, 0, 90)
        $path.AddArc($rect.X, ($rect.Bottom - $corner * 2), $corner * 2, $corner * 2, 90, 90)
        $path.CloseFigure()
        $g.FillPath($brush, $path)
        $width = [float][Math]::Max(2, $Size * 0.10)
        $pen = [System.Drawing.Pen]::new((Get-GuiInk -Theme $Theme -Role 'onBrand'), $width)
        $pen.StartCap = 'Round'
        $pen.EndCap = 'Round'
        $mark = [System.Drawing.Point[]]@(
            [System.Drawing.Point]::new([int]($Size * 0.26), [int]($Size * 0.52)),
            [System.Drawing.Point]::new([int]($Size * 0.44), [int]($Size * 0.70)),
            [System.Drawing.Point]::new([int]($Size * 0.76), [int]($Size * 0.30))
        )
        $g.DrawLines($pen, $mark)
        $pen.Dispose(); $brush.Dispose(); $path.Dispose()
    } finally {
        $g.Dispose()
    }
    # FromHandle does not own the handle; the caller keeps the icon alive for the
    # process, which is what Show-GuiSession does with it.
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
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

function Get-GuiLink {
    <#
      The project homepage, in one place. The window shows this in About; a
      repository that moves is a one-line change here rather than a search for
      hardcoded URLs.
    #>
    [CmdletBinding()]
    param()
    return 'https://github.com/ChanceFlow/WinCleanKit'
}

function Format-GuiWindowsName {
    <#
      One line naming the Windows this is running on.

      Windows 11 still writes ProductName = "Windows 10 Pro" into the registry, so a
      window that repeats that string tells the user something false about their own
      machine. The build number is the honest answer (22000 and up is Windows 11), and
      the display version ("25H2") is what Microsoft prints. Split from the registry
      read so the rule can be tested without one.
    #>
    [CmdletBinding()]
    param(
        [string]$ProductName = '',
        [string]$Build = '',
        [string]$Release = ''
    )

    $name = ([string]$ProductName).Trim()
    if ($Build -match '^\d+$' -and [int]$Build -ge 22000 -and $name -like 'Windows 10*') {
        $name = $name -replace '^Windows 10', 'Windows 11'
    }
    if (-not $name) { $name = 'Windows' }
    $parts = New-Object System.Collections.Generic.List[string]
    [void]$parts.Add($name)
    if ($Release) { [void]$parts.Add($Release) }
    if ($Build) { [void]$parts.Add("build $Build") }
    return ($parts -join ' · ')
}

function Get-GuiMachineFact {
    <#
      What this machine is, for the overview page. Cached: this is a registry read,
      not something to repeat on every checkbox click. Best effort -- a machine that
      will not answer gets "Windows" rather than an empty line.
    #>
    [CmdletBinding()]
    param()

    if ($script:GuiApp.Facts) { return [string]$script:GuiApp.Facts }
    $os = 'Windows'
    try {
        $key = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $os = Format-GuiWindowsName -ProductName ([string]$key.ProductName) -Build ([string]$key.CurrentBuild) -Release ([string]$key.DisplayVersion)
    } catch {
        # Keep the default; the page still renders.
        $os = 'Windows'
    }
    $script:GuiApp.Facts = $os
    return [string]$script:GuiApp.Facts
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

function Format-GuiButton {
    <#
      One button, in one of three weights. Flat so the palette shows through, with a
      border that keeps the control visible against the card, and a minimum size that
      gives every label room to breathe on the 8px rhythm.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Button,
        [Parameter(Mandatory)] $Theme,
        [ValidateSet('primary', 'caution', 'quiet')][string]$Kind = 'quiet'
    )

    $Button.FlatStyle = 'Flat'
    $Button.UseVisualStyleBackColor = $false
    $Button.FlatAppearance.BorderSize = 1
    # Grow with the label: a fixed minimum clipped "Language: EN" to "Language: E",
    # and the same button has to hold "语言：中文" in the other language.
    $Button.AutoSize = $true
    $Button.AutoSizeMode = 'GrowAndShrink'
    $Button.MinimumSize = New-Object System.Drawing.Size(104, 32)
    $Button.Padding = New-Object System.Windows.Forms.Padding(8, 2, 8, 2)
    $Button.Cursor = 'Hand'

    switch ($Kind) {
        'primary' {
            $Button.BackColor = Get-GuiInk -Theme $Theme -Role 'brand'
            $Button.ForeColor = Get-GuiInk -Theme $Theme -Role 'onBrand'
            $Button.FlatAppearance.BorderColor = Get-GuiInk -Theme $Theme -Role 'brand'
            $Button.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
        }
        'caution' {
            $Button.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
            $Button.ForeColor = Get-GuiInk -Theme $Theme -Role 'caution'
            $Button.FlatAppearance.BorderColor = Get-GuiInk -Theme $Theme -Role 'caution'
        }
        default {
            $Button.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
            $Button.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
            $Button.FlatAppearance.BorderColor = Get-GuiInk -Theme $Theme -Role 'controlBorder'
        }
    }
}

function Format-GuiNavButton {
    <#
      One navigation entry: a fixed-size, left-aligned, two-line button. The active
      page is filled with the railActive role, which is the only place in the window
      where a selected item is shown as a surface rather than a tick.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Button,
        [Parameter(Mandatory)] $Theme,
        [Parameter(Mandatory)][bool]$Active
    )

    $Button.FlatStyle = 'Flat'
    $Button.UseVisualStyleBackColor = $false
    $Button.FlatAppearance.BorderSize = 0
    $Button.AutoSize = $false
    $Button.Size = New-Object System.Drawing.Size(168, 54)
    $Button.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 6)
    $Button.TextAlign = 'MiddleLeft'
    $Button.Padding = New-Object System.Windows.Forms.Padding(12, 0, 6, 0)
    $Button.Cursor = 'Hand'
    $Button.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, $(if ($Active) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }))
    $Button.BackColor = Get-GuiInk -Theme $Theme -Role $(if ($Active) { 'railActive' } else { 'railBg' })
    $Button.ForeColor = Get-GuiInk -Theme $Theme -Role $(if ($Active) { 'onRailActive' } else { 'text' })
    $Button.FlatAppearance.MouseOverBackColor = Get-GuiInk -Theme $Theme -Role $(if ($Active) { 'railActive' } else { 'card' })
}

function Format-GuiChip {
    <#
      One area filter, as a check box drawn as a button. A CheckBox rather than a
      Button because "one of these is current" is a check state, and a screen reader
      and the keyboard both understand that without being told.

      The tick is *not* a selection of the area: it marks the area being shown. That
      matters -- calling it a tick in the automation tree would be a lie, so the
      accessible name says "show" instead.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Chip,
        [Parameter(Mandatory)] $Theme,
        [Parameter(Mandatory)][bool]$Active
    )

    $Chip.Appearance = 'Button'
    $Chip.FlatStyle = 'Flat'
    $Chip.UseVisualStyleBackColor = $false
    # Sized from the renderer that draws it. Appearance=Button under AutoSize
    # measured short on a real screen -- "Privacy  7/10" was painted as "Privacy 7/"
    # -- and MinWidth is a floor, not the answer.
    $Chip.UseMnemonic = $false
    $Chip.AutoSize = $false
    $Chip.MinimumSize = New-Object System.Drawing.Size(92, 28)
    # NoPrefix counts the ampersand it will draw; NoPadding gives the tight text box.
    # The flat-button renderer then wants its own margin on top of that, which is the
    # 40 below -- measured by eye against a screenshot, because no API reports it.
    $flags = [System.Windows.Forms.TextFormatFlags]::NoPrefix -bor [System.Windows.Forms.TextFormatFlags]::NoPadding
    $measure = [System.Windows.Forms.TextRenderer]::MeasureText($Chip.Text, $Chip.Font, [System.Drawing.Size]::Empty, $flags)
    $Chip.Width = [Math]::Max(92, $measure.Width + 40)
    $Chip.Height = 30
    $Chip.Padding = New-Object System.Windows.Forms.Padding(10, 2, 10, 2)
    $Chip.Margin = New-Object System.Windows.Forms.Padding(0, 0, 8, 0)
    $Chip.Cursor = 'Hand'
    $Chip.BackColor = Get-GuiInk -Theme $Theme -Role $(if ($Active) { 'selection' } else { 'card' })
    $Chip.ForeColor = Get-GuiInk -Theme $Theme -Role $(if ($Active) { 'onSelection' } else { 'text' })
    $Chip.FlatAppearance.BorderColor = Get-GuiInk -Theme $Theme -Role $(if ($Active) { 'accent' } else { 'controlBorder' })
    $Chip.FlatAppearance.CheckedBackColor = Get-GuiInk -Theme $Theme -Role 'selection'
    $Chip.FlatAppearance.MouseOverBackColor = Get-GuiInk -Theme $Theme -Role 'selection'
}

function Format-GuiBorderedBox {
    <#
      A one-pixel themed border around a control. WinForms has no themeable border
      colour outside of custom painting, and a FixedSingle frame is always the
      system grey -- which is exactly the hardcoded colour the palette exists to
      avoid. A container painted in the border role with one pixel of padding costs
      nothing and follows the theme.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Child,
        [Parameter(Mandatory)] $Theme
    )

    $wrap = New-Object System.Windows.Forms.Panel
    $wrap.Dock = 'Fill'
    $wrap.Padding = New-Object System.Windows.Forms.Padding(1)
    $wrap.BackColor = Get-GuiInk -Theme $Theme -Role 'border'
    $Child.Dock = 'Fill'
    $Child.BorderStyle = 'None'
    $wrap.Controls.Add($Child)
    return $wrap
}

function Initialize-GuiForm {
    <#
      Build the window and return it with a map of its controls. Declarative on
      purpose: no data is loaded and no events are wired here, so tests/Test-Gui.ps1
      can assert the shape of the interface without ever showing it.

      The frame is a TableLayoutPanel rather than docked panels because docking
      siblings order-dependently is the classic way to end up with a Fill control
      under a bar. Rows are fixed so the geometry cannot drift with content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $State,
        [string]$Version = '0.0.0',
        $Theme
    )

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [void](Enable-GuiDpiAwareness)
    [System.Windows.Forms.Application]::EnableVisualStyles()

    if (-not $Theme) { $Theme = Get-GuiTheme -Name (Get-GuiSystemTheme) }
    $lang = $State.Language
    $ui = New-Object System.Drawing.Font('Segoe UI', 9)
    $lead = New-Object System.Drawing.Font('Segoe UI', 10)
    $h1 = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
    $logFont = New-Object System.Drawing.Font('Consolas', 8.5)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = '{0} {1}' -f (Get-GuiText -Key 'title' -Language $lang), $Version
    $form.Size = New-Object System.Drawing.Size(1120, 760)
    $form.MinimumSize = New-Object System.Drawing.Size(940, 620)
    $form.StartPosition = 'CenterScreen'
    $form.Font = $ui
    $form.KeyPreview = $true
    $form.BackColor = Get-GuiInk -Theme $Theme -Role 'window'
    $form.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'

    $frame = New-Object System.Windows.Forms.TableLayoutPanel
    $frame.Dock = 'Fill'
    $frame.ColumnCount = 2
    $frame.RowCount = 3
    [void]$frame.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Absolute', 192)))
    [void]$frame.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    [void]$frame.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute', 58)))
    [void]$frame.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100)))
    [void]$frame.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute', 60)))

    # ---- top bar ----------------------------------------------------------
    $top = New-Object System.Windows.Forms.TableLayoutPanel
    $top.Dock = 'Fill'
    $top.ColumnCount = 3
    $top.RowCount = 1
    $top.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    [void]$top.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    [void]$top.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
    [void]$top.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))

    $topTitle = New-Object System.Windows.Forms.Label
    $topTitle.AutoSize = $true
    $topTitle.Anchor = 'Left'
    $topTitle.Margin = New-Object System.Windows.Forms.Padding(20, 0, 0, 0)
    $topTitle.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $topTitle.ForeColor = Get-GuiInk -Theme $Theme -Role 'brand'
    $topTitle.Text = Get-GuiText -Key 'title' -Language $lang

    $topPlan = New-Object System.Windows.Forms.Label
    $topPlan.AutoSize = $true
    $topPlan.Anchor = 'Right'
    $topPlan.Margin = New-Object System.Windows.Forms.Padding(0, 0, 12, 0)
    $topPlan.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    $language = New-Object System.Windows.Forms.Button
    $language.Tag = 'language'
    Format-GuiButton -Button $language -Theme $Theme -Kind 'quiet'
    $language.Anchor = 'Right'
    $language.Margin = New-Object System.Windows.Forms.Padding(0, 0, 20, 0)
    $language.AccessibleName = (Get-GuiText -Key 'language' -Language $lang)

    [void]$top.Controls.Add($topTitle, 0, 0)
    [void]$top.Controls.Add($topPlan, 1, 0)
    [void]$top.Controls.Add($language, 2, 0)

    # ---- navigation rail --------------------------------------------------
    $rail = New-Object System.Windows.Forms.FlowLayoutPanel
    $rail.Dock = 'Fill'
    $rail.FlowDirection = 'TopDown'
    $rail.WrapContents = $false
    $rail.Padding = New-Object System.Windows.Forms.Padding(12, 16, 12, 12)
    $rail.BackColor = Get-GuiInk -Theme $Theme -Role 'railBg'

    $pages = @('home', 'choose', 'apply', 'restore', 'about')
    $pageKeys = @{
        home = 'navOverview'; choose = 'navChoose'; apply = 'navApply'
        restore = 'navRestore'; about = 'navAbout'
    }
    $nav = @{}
    $navOrder = New-Object System.Collections.Generic.List[object]
    foreach ($name in $pages) {
        $b = New-Object System.Windows.Forms.Button
        $b.Tag = $name
        $b.AccessibleName = (Get-GuiText -Key $pageKeys[$name] -Language $lang)
        Format-GuiNavButton -Button $b -Theme $Theme -Active $false
        $nav[$name] = $b
        [void]$navOrder.Add($b)
        [void]$rail.Controls.Add($b)
    }

    $railKeys = New-Object System.Windows.Forms.Label
    $railKeys.AutoSize = $true
    $railKeys.MaximumSize = New-Object System.Drawing.Size(168, 0)
    $railKeys.Margin = New-Object System.Windows.Forms.Padding(2, 14, 0, 0)
    $railKeys.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'
    $railKeys.Text = Get-GuiText -Key 'navKeys' -Language $lang
    [void]$rail.Controls.Add($railKeys)

    # ---- content: five pages, one visible --------------------------------
    $content = New-Object System.Windows.Forms.Panel
    $content.Dock = 'Fill'
    $content.Padding = New-Object System.Windows.Forms.Padding(20, 16, 20, 12)
    $content.BackColor = Get-GuiInk -Theme $Theme -Role 'window'

    # --- page: overview
    # Not $home: that is a read-only automatic variable and PowerShell refuses the
    # assignment. The analyzer caught it before the window did.
    $homePanel = New-Object System.Windows.Forms.TableLayoutPanel
    $homePanel.Dock = 'Fill'
    $homePanel.ColumnCount = 1
    $homePanel.RowCount = 6
    [void]$homePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$homePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$homePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$homePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$homePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$homePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))

    $homeTitle = New-Object System.Windows.Forms.Label
    $homeTitle.AutoSize = $true
    $homeTitle.MaximumSize = New-Object System.Drawing.Size(760, 0)
    $homeTitle.Font = $h1
    $homeTitle.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'

    $homeFacts = New-Object System.Windows.Forms.Label
    $homeFacts.AutoSize = $true
    $homeFacts.Margin = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)
    $homeFacts.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    $homeLead = New-Object System.Windows.Forms.Label
    $homeLead.AutoSize = $true
    $homeLead.MaximumSize = New-Object System.Drawing.Size(760, 0)
    $homeLead.Margin = New-Object System.Windows.Forms.Padding(0, 14, 0, 0)
    $homeLead.Font = $lead
    $homeLead.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'

    $homeActions = New-Object System.Windows.Forms.FlowLayoutPanel
    $homeActions.AutoSize = $true
    $homeActions.FlowDirection = 'LeftToRight'
    $homeActions.WrapContents = $false
    $homeActions.Margin = New-Object System.Windows.Forms.Padding(0, 20, 0, 0)

    $homeUse = New-Object System.Windows.Forms.Button
    $homeUse.Tag = 'homeUse'
    Format-GuiButton -Button $homeUse -Theme $Theme -Kind 'primary'
    $homeUse.Margin = New-Object System.Windows.Forms.Padding(0, 0, 10, 0)
    $homeUse.AccessibleDescription = (Get-GuiText -Key 'homeUseHint' -Language $lang)

    $homePick = New-Object System.Windows.Forms.Button
    $homePick.Tag = 'homePick'
    Format-GuiButton -Button $homePick -Theme $Theme -Kind 'quiet'

    $homeSafety = New-Object System.Windows.Forms.Label
    $homeSafety.AutoSize = $true
    $homeSafety.MaximumSize = New-Object System.Drawing.Size(760, 0)
    $homeSafety.Margin = New-Object System.Windows.Forms.Padding(0, 22, 0, 0)
    $homeSafety.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    $homeLastRun = New-Object System.Windows.Forms.Label
    $homeLastRun.AutoSize = $true
    $homeLastRun.Margin = New-Object System.Windows.Forms.Padding(0, 18, 0, 0)
    $homeLastRun.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    [void]$homeActions.Controls.Add($homeUse)
    [void]$homeActions.Controls.Add($homePick)
    [void]$homePanel.Controls.Add($homeTitle, 0, 0)
    [void]$homePanel.Controls.Add($homeFacts, 0, 1)
    [void]$homePanel.Controls.Add($homeLead, 0, 2)
    [void]$homePanel.Controls.Add($homeActions, 0, 3)
    [void]$homePanel.Controls.Add($homeSafety, 0, 4)
    [void]$homePanel.Controls.Add($homeLastRun, 0, 5)

    # --- page: choose
    $choose = New-Object System.Windows.Forms.TableLayoutPanel
    $choose.Dock = 'Fill'
    $choose.ColumnCount = 1
    $choose.RowCount = 4
    [void]$choose.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$choose.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$choose.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100)))
    [void]$choose.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$choose.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))

    $searchWrap = New-Object System.Windows.Forms.Panel
    $searchWrap.Height = 34
    $searchWrap.Dock = 'Fill'
    $searchWrap.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)

    $searchLabel = New-Object System.Windows.Forms.Label
    $searchLabel.AutoSize = $true
    $searchLabel.Text = (Get-GuiText -Key 'search' -Language $lang)
    $searchLabel.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'
    $searchLabel.Location = New-Object System.Drawing.Point(0, 8)

    $searchBox = New-Object System.Windows.Forms.TextBox
    $searchBox.Location = New-Object System.Drawing.Point(70, 4)
    $searchBox.Width = 420
    $searchBox.BorderStyle = 'FixedSingle'
    $searchBox.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $searchBox.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $searchBox.AccessibleName = (Get-GuiText -Key 'search' -Language $lang)

    # No PlaceholderText on .NET Framework, so the hint is a label over the box that
    # gets out of the way as soon as there is text or focus.
    $searchHint = New-Object System.Windows.Forms.Label
    $searchHint.AutoSize = $true
    $searchHint.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $searchHint.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'
    $searchHint.Location = New-Object System.Drawing.Point(75, 7)

    [void]$searchWrap.Controls.Add($searchBox)
    [void]$searchWrap.Controls.Add($searchHint)
    [void]$searchWrap.Controls.Add($searchLabel)
    $searchHint.BringToFront()
    # The box is positioned by hand so the hint can sit inside it. A TextBox laid out
    # while its container still has its design-time width keeps the wrong anchor
    # distance, so its width follows the container instead.
    $searchWrap.Add_Resize({
        if (-not $script:GuiApp.Controls) { return }
        $box = $script:GuiApp.Controls.searchBox
        $box.Width = [Math]::Max(200, $script:GuiApp.Controls.searchWrap.ClientSize.Width - 78)
    })

    $chipBar = New-Object System.Windows.Forms.FlowLayoutPanel
    $chipBar.AutoSize = $true
    $chipBar.FlowDirection = 'LeftToRight'
    $chipBar.WrapContents = $false
    $chipBar.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 12)

    $chips = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $State.Groups.Count; $i++) {
        $chip = New-Object System.Windows.Forms.CheckBox
        $chip.Tag = $i
        $chip.Appearance = 'Button'
        Format-GuiChip -Chip $chip -Theme $Theme -Active $false
        [void]$chips.Add($chip)
        [void]$chipBar.Controls.Add($chip)
    }

    $chooseSplit = New-Object System.Windows.Forms.SplitContainer
    $chooseSplit.Dock = 'Fill'
    $chooseSplit.Orientation = 'Vertical'
    $chooseSplit.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 12)

    $actionList = New-Object System.Windows.Forms.CheckedListBox
    $actionList.Dock = 'Fill'
    $actionList.CheckOnClick = $true
    $actionList.IntegralHeight = $false
    $actionList.BorderStyle = 'FixedSingle'
    $actionList.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $actionList.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $actionList.AccessibleName = (Get-GuiText -Key 'navChoose' -Language $lang)
    $actionList.TabIndex = 1

    $detail = New-Object System.Windows.Forms.TableLayoutPanel
    $detail.Dock = 'Fill'
    $detail.ColumnCount = 1
    $detail.RowCount = 4
    [void]$detail.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$detail.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$detail.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100)))
    [void]$detail.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    $detail.Padding = New-Object System.Windows.Forms.Padding(14, 10, 12, 10)
    $detail.BackColor = Get-GuiInk -Theme $Theme -Role 'card'

    $detailTitle = New-Object System.Windows.Forms.Label
    $detailTitle.AutoSize = $true
    $detailTitle.MaximumSize = New-Object System.Drawing.Size(420, 0)
    $detailTitle.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $detailTitle.ForeColor = Get-GuiInk -Theme $Theme -Role 'brand'

    $detailStats = New-Object System.Windows.Forms.Label
    $detailStats.AutoSize = $true
    # Muted carries secondary information only; the measured pairs in this palette
    # are all at or above 4.5:1, which Test-Gui.ps1 checks.
    $detailStats.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    $detailBody = New-Object System.Windows.Forms.TextBox
    $detailBody.Multiline = $true
    $detailBody.ReadOnly = $true
    $detailBody.ScrollBars = 'Vertical'
    $detailBody.BorderStyle = 'None'
    $detailBody.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $detailBody.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $detailBody.Dock = 'Fill'
    $detailBody.Margin = New-Object System.Windows.Forms.Padding(0, 8, 0, 8)
    $detailBody.TabStop = $false

    $detailFoot = New-Object System.Windows.Forms.Label
    $detailFoot.AutoSize = $true
    $detailFoot.MaximumSize = New-Object System.Drawing.Size(420, 0)
    $detailFoot.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    [void]$detail.Controls.Add($detailTitle, 0, 0)
    [void]$detail.Controls.Add($detailStats, 0, 1)
    [void]$detail.Controls.Add($detailBody, 0, 2)
    [void]$detail.Controls.Add($detailFoot, 0, 3)

    $chooseSplit.Panel1.Controls.Add((Format-GuiBorderedBox -Child $actionList -Theme $Theme))
    $chooseSplit.Panel2.Controls.Add((Format-GuiBorderedBox -Child $detail -Theme $Theme))
    $chooseSplit.Panel2.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)

    $chooseFoot = New-Object System.Windows.Forms.TableLayoutPanel
    $chooseFoot.AutoSize = $true
    $chooseFoot.ColumnCount = 3
    $chooseFoot.RowCount = 1
    [void]$chooseFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
    [void]$chooseFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    [void]$chooseFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))

    $bulk = New-Object System.Windows.Forms.FlowLayoutPanel
    $bulk.AutoSize = $true
    $bulk.FlowDirection = 'LeftToRight'
    $bulk.WrapContents = $false

    $selectAll = New-Object System.Windows.Forms.Button
    $selectAll.Tag = 'selectAll'
    $selectNone = New-Object System.Windows.Forms.Button
    $selectNone.Tag = 'selectNone'
    foreach ($b in $selectAll, $selectNone) {
        Format-GuiButton -Button $b -Theme $Theme -Kind 'quiet'
        $b.Margin = New-Object System.Windows.Forms.Padding(0, 0, 8, 0)
    }
    $selectAll.TabIndex = 2
    $selectNone.TabIndex = 3
    [void]$bulk.Controls.Add($selectAll)
    [void]$bulk.Controls.Add($selectNone)

    $chooseCount = New-Object System.Windows.Forms.Label
    $chooseCount.AutoSize = $true
    $chooseCount.Anchor = 'Right'
    $chooseCount.Margin = New-Object System.Windows.Forms.Padding(0, 0, 12, 0)
    $chooseCount.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    $chooseNext = New-Object System.Windows.Forms.Button
    $chooseNext.Tag = 'chooseNext'
    Format-GuiButton -Button $chooseNext -Theme $Theme -Kind 'primary'
    $chooseNext.Anchor = 'Right'

    [void]$chooseFoot.Controls.Add($bulk, 0, 0)
    [void]$chooseFoot.Controls.Add($chooseCount, 1, 0)
    [void]$chooseFoot.Controls.Add($chooseNext, 2, 0)

    [void]$choose.Controls.Add($searchWrap, 0, 0)
    [void]$choose.Controls.Add($chipBar, 0, 1)
    [void]$choose.Controls.Add($chooseSplit, 0, 2)
    [void]$choose.Controls.Add($chooseFoot, 0, 3)

    # --- page: apply
    $apply = New-Object System.Windows.Forms.TableLayoutPanel
    $apply.Dock = 'Fill'
    $apply.ColumnCount = 1
    $apply.RowCount = 6
    [void]$apply.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$apply.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$apply.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$apply.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 55)))
    [void]$apply.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 45)))
    [void]$apply.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))

    $applyTitle = New-Object System.Windows.Forms.Label
    $applyTitle.AutoSize = $true
    $applyTitle.Font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
    $applyTitle.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $applyTitle.Text = Get-GuiText -Key 'applyTitle' -Language $lang

    $applyFacts = New-Object System.Windows.Forms.Label
    $applyFacts.AutoSize = $true
    $applyFacts.MaximumSize = New-Object System.Drawing.Size(860, 0)
    $applyFacts.Margin = New-Object System.Windows.Forms.Padding(0, 8, 0, 0)
    $applyFacts.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    $applyRisky = New-Object System.Windows.Forms.Label
    $applyRisky.AutoSize = $true
    $applyRisky.MaximumSize = New-Object System.Drawing.Size(860, 0)
    $applyRisky.Margin = New-Object System.Windows.Forms.Padding(0, 6, 0, 10)
    $applyRisky.ForeColor = Get-GuiInk -Theme $Theme -Role 'caution'

    $applyList = New-Object System.Windows.Forms.ListBox
    $applyList.Dock = 'Fill'
    $applyList.IntegralHeight = $false
    $applyList.BorderStyle = 'FixedSingle'
    $applyList.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $applyList.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $applyList.AccessibleName = (Get-GuiText -Key 'applyTitle' -Language $lang)

    $logWrap = New-Object System.Windows.Forms.TableLayoutPanel
    $logWrap.Dock = 'Fill'
    $logWrap.ColumnCount = 1
    $logWrap.RowCount = 2
    $logWrap.Margin = New-Object System.Windows.Forms.Padding(0, 12, 0, 12)
    [void]$logWrap.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$logWrap.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100)))

    $logLabel = New-Object System.Windows.Forms.Label
    $logLabel.AutoSize = $true
    $logLabel.Text = Get-GuiText -Key 'applyLog' -Language $lang
    $logLabel.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'
    $logLabel.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 4)

    $log = New-Object System.Windows.Forms.TextBox
    $log.Multiline = $true
    $log.ReadOnly = $true
    $log.ScrollBars = 'Both'
    $log.WordWrap = $false
    $log.BorderStyle = 'FixedSingle'
    $log.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $log.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $log.Font = $logFont
    $log.Dock = 'Fill'
    $log.TabStop = $false
    $log.AccessibleName = (Get-GuiText -Key 'applyLog' -Language $lang)

    [void]$logWrap.Controls.Add($logLabel, 0, 0)
    [void]$logWrap.Controls.Add($log, 0, 1)

    $applyFoot = New-Object System.Windows.Forms.TableLayoutPanel
    $applyFoot.AutoSize = $true
    $applyFoot.ColumnCount = 3
    $applyFoot.RowCount = 1
    [void]$applyFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
    [void]$applyFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    [void]$applyFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))

    $applyButtons = New-Object System.Windows.Forms.FlowLayoutPanel
    $applyButtons.AutoSize = $true
    $applyButtons.FlowDirection = 'LeftToRight'
    $applyButtons.WrapContents = $false

    $preview = New-Object System.Windows.Forms.Button
    $preview.Tag = 'preview'
    $applyBack = New-Object System.Windows.Forms.Button
    $applyBack.Tag = 'applyBack'
    Format-GuiButton -Button $preview -Theme $Theme -Kind 'quiet'
    Format-GuiButton -Button $applyBack -Theme $Theme -Kind 'quiet'
    $preview.Margin = New-Object System.Windows.Forms.Padding(0, 0, 8, 0)
    $applyBack.Margin = New-Object System.Windows.Forms.Padding(0, 0, 8, 0)
    [void]$applyButtons.Controls.Add($preview)
    [void]$applyButtons.Controls.Add($applyBack)

    $applyResult = New-Object System.Windows.Forms.Label
    $applyResult.AutoSize = $true
    $applyResult.Anchor = 'Right'
    $applyResult.Margin = New-Object System.Windows.Forms.Padding(0, 0, 12, 0)
    $applyResult.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    $runIt = New-Object System.Windows.Forms.Button
    $runIt.Tag = 'runIt'
    # The one action that changes the machine carries the brand colour, so the
    # primary action is identifiable at a glance. It is deliberately not the form's
    # AcceptButton: Enter must not apply anything.
    Format-GuiButton -Button $runIt -Theme $Theme -Kind 'primary'
    $runIt.Anchor = 'Right'
    $runIt.AccessibleDescription = (Get-GuiText -Key 'applyHint' -Language $lang)

    [void]$applyFoot.Controls.Add($applyButtons, 0, 0)
    [void]$applyFoot.Controls.Add($applyResult, 1, 0)
    [void]$applyFoot.Controls.Add($runIt, 2, 0)

    [void]$apply.Controls.Add($applyTitle, 0, 0)
    [void]$apply.Controls.Add($applyFacts, 0, 1)
    [void]$apply.Controls.Add($applyRisky, 0, 2)
    [void]$apply.Controls.Add((Format-GuiBorderedBox -Child $applyList -Theme $Theme), 0, 3)
    [void]$apply.Controls.Add($logWrap, 0, 4)
    [void]$apply.Controls.Add($applyFoot, 0, 5)

    # --- page: restore
    $restore = New-Object System.Windows.Forms.TableLayoutPanel
    $restore.Dock = 'Fill'
    $restore.ColumnCount = 1
    $restore.RowCount = 4
    [void]$restore.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$restore.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$restore.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100)))
    [void]$restore.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))

    $restoreTitle = New-Object System.Windows.Forms.Label
    $restoreTitle.AutoSize = $true
    $restoreTitle.Font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
    $restoreTitle.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $restoreTitle.Text = Get-GuiText -Key 'restoreTitle' -Language $lang

    $restoreLead = New-Object System.Windows.Forms.Label
    $restoreLead.AutoSize = $true
    $restoreLead.MaximumSize = New-Object System.Drawing.Size(860, 0)
    $restoreLead.Margin = New-Object System.Windows.Forms.Padding(0, 8, 0, 12)
    $restoreLead.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'
    $restoreLead.Text = Get-GuiText -Key 'restoreLead' -Language $lang

    $restoreList = New-Object System.Windows.Forms.ListBox
    $restoreList.Dock = 'Fill'
    $restoreList.IntegralHeight = $false
    $restoreList.BorderStyle = 'FixedSingle'
    $restoreList.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $restoreList.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $restoreList.AccessibleName = (Get-GuiText -Key 'restoreTitle' -Language $lang)

    $restoreFoot = New-Object System.Windows.Forms.TableLayoutPanel
    $restoreFoot.AutoSize = $true
    $restoreFoot.ColumnCount = 3
    $restoreFoot.RowCount = 1
    $restoreFoot.Margin = New-Object System.Windows.Forms.Padding(0, 12, 0, 0)
    [void]$restoreFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    [void]$restoreFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
    [void]$restoreFoot.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))

    $restoreDetail = New-Object System.Windows.Forms.Label
    $restoreDetail.AutoSize = $true
    $restoreDetail.Anchor = 'Left'
    $restoreDetail.MaximumSize = New-Object System.Drawing.Size(560, 0)
    $restoreDetail.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'

    $restoreOpen = New-Object System.Windows.Forms.Button
    $restoreOpen.Tag = 'restoreOpen'
    $restoreRun = New-Object System.Windows.Forms.Button
    $restoreRun.Tag = 'restoreRun'
    Format-GuiButton -Button $restoreOpen -Theme $Theme -Kind 'quiet'
    Format-GuiButton -Button $restoreRun -Theme $Theme -Kind 'caution'
    $restoreOpen.Margin = New-Object System.Windows.Forms.Padding(0, 0, 8, 0)

    [void]$restoreFoot.Controls.Add($restoreDetail, 0, 0)
    [void]$restoreFoot.Controls.Add($restoreOpen, 1, 0)
    [void]$restoreFoot.Controls.Add($restoreRun, 2, 0)

    [void]$restore.Controls.Add($restoreTitle, 0, 0)
    [void]$restore.Controls.Add($restoreLead, 0, 1)
    [void]$restore.Controls.Add((Format-GuiBorderedBox -Child $restoreList -Theme $Theme), 0, 2)
    [void]$restore.Controls.Add($restoreFoot, 0, 3)

    # --- page: about
    $about = New-Object System.Windows.Forms.TableLayoutPanel
    $about.Dock = 'Fill'
    $about.ColumnCount = 1
    $about.RowCount = 3
    [void]$about.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
    [void]$about.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100)))
    [void]$about.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))

    $aboutTitle = New-Object System.Windows.Forms.Label
    $aboutTitle.AutoSize = $true
    $aboutTitle.Font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
    $aboutTitle.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $aboutTitle.Text = Get-GuiText -Key 'aboutTitle' -Language $lang

    $aboutBody = New-Object System.Windows.Forms.TextBox
    $aboutBody.Multiline = $true
    $aboutBody.ReadOnly = $true
    $aboutBody.ScrollBars = 'Vertical'
    $aboutBody.BorderStyle = 'None'
    $aboutBody.BackColor = Get-GuiInk -Theme $Theme -Role 'window'
    $aboutBody.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    $aboutBody.Dock = 'Fill'
    $aboutBody.Margin = New-Object System.Windows.Forms.Padding(0, 12, 0, 12)
    $aboutBody.TabStop = $false

    $aboutLink = New-Object System.Windows.Forms.LinkLabel
    $aboutLink.AutoSize = $true
    $aboutLink.Text = Get-GuiLink
    $aboutLink.LinkColor = Get-GuiInk -Theme $Theme -Role 'accent'
    $aboutLink.ActiveLinkColor = Get-GuiInk -Theme $Theme -Role 'accent'
    $aboutLink.VisitedLinkColor = Get-GuiInk -Theme $Theme -Role 'accent'
    $aboutLink.Cursor = 'Hand'
    $aboutLink.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)

    [void]$about.Controls.Add($aboutTitle, 0, 0)
    [void]$about.Controls.Add($aboutBody, 0, 1)
    [void]$about.Controls.Add($aboutLink, 0, 2)

    # --- the pages container
    $homePage = $homePanel
    $choosePage = $choose
    $applyPage = $apply
    $restorePage = $restore
    $aboutPage = $about
    foreach ($p in $homePage, $choosePage, $applyPage, $restorePage, $aboutPage) {
        $p.Dock = 'Fill'
        $p.Visible = $false
        $content.Controls.Add($p)
    }
    $homePage.Visible = $true

    # ---- bottom bar -------------------------------------------------------
    $bottom = New-Object System.Windows.Forms.TableLayoutPanel
    $bottom.Dock = 'Fill'
    $bottom.ColumnCount = 2
    $bottom.RowCount = 2
    $bottom.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $bottom.Padding = New-Object System.Windows.Forms.Padding(20, 8, 20, 8)
    [void]$bottom.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    [void]$bottom.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Absolute', 130)))
    [void]$bottom.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute', 24)))
    [void]$bottom.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute', 16)))

    $status = New-Object System.Windows.Forms.Label
    $status.Dock = 'Fill'
    $status.AutoEllipsis = $true
    $status.TextAlign = 'MiddleLeft'
    $status.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'
    $status.Text = Get-GuiText -Key 'ready' -Language $lang
    $status.AccessibleName = (Get-GuiText -Key 'statusLabel' -Language $lang)

    # A step counter beside the bar: "12/45 · 26%". The bar alone says "somewhere
    # in the middle"; the count says how far, which matters for a 74-action run.
    $progressLabel = New-Object System.Windows.Forms.Label
    $progressLabel.Dock = 'Fill'
    $progressLabel.TextAlign = 'MiddleRight'
    $progressLabel.ForeColor = Get-GuiInk -Theme $Theme -Role 'muted'
    $progressLabel.AccessibleName = (Get-GuiText -Key 'progressLabel' -Language $lang)
    $progressLabel.Text = ''

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Dock = 'Fill'
    $bar.AccessibleName = (Get-GuiText -Key 'progressLabel' -Language $lang)

    [void]$bottom.Controls.Add($status, 0, 0)
    [void]$bottom.Controls.Add($progressLabel, 1, 0)
    [void]$bottom.Controls.Add($bar, 0, 1)
    $bottom.SetColumnSpan($bar, 2)

    [void]$frame.Controls.Add($top, 0, 0)
    $frame.SetColumnSpan($top, 2)
    [void]$frame.Controls.Add($rail, 0, 1)
    [void]$frame.Controls.Add($content, 1, 1)
    [void]$frame.Controls.Add($bottom, 0, 2)
    $frame.SetColumnSpan($bottom, 2)
    $form.Controls.Add($frame)

    $controls = @{
        theme = $Theme
        form = $form; frame = $frame; top = $top; topTitle = $topTitle; topPlan = $topPlan
        language = $language
        rail = $rail; nav = $nav; navOrder = $navOrder; railKeys = $railKeys
        content = $content
        homePage = $homePage; choosePage = $choosePage; applyPage = $applyPage
        restorePage = $restorePage; aboutPage = $aboutPage
        homeTitle = $homeTitle; homeFacts = $homeFacts; homeLead = $homeLead
        homeUse = $homeUse; homePick = $homePick; homeSafety = $homeSafety
        homeLastRun = $homeLastRun
        searchWrap = $searchWrap; searchBox = $searchBox; searchHint = $searchHint
        searchLabel = $searchLabel; chipBar = $chipBar; chips = $chips
        chooseSplit = $chooseSplit; actionList = $actionList
        detail = $detail; detailTitle = $detailTitle; detailStats = $detailStats
        detailBody = $detailBody; detailFoot = $detailFoot
        bulk = $bulk; selectAll = $selectAll; selectNone = $selectNone
        chooseCount = $chooseCount; chooseNext = $chooseNext
        applyTitle = $applyTitle; applyFacts = $applyFacts; applyRisky = $applyRisky
        applyList = $applyList; log = $log; logLabel = $logLabel
        applyResult = $applyResult; preview = $preview; runIt = $runIt; applyBack = $applyBack
        restoreTitle = $restoreTitle; restoreLead = $restoreLead; restoreList = $restoreList
        restoreDetail = $restoreDetail; restoreRun = $restoreRun; restoreOpen = $restoreOpen
        aboutTitle = $aboutTitle; aboutBody = $aboutBody; aboutLink = $aboutLink
        bottom = $bottom; status = $status; progressLabel = $progressLabel; bar = $bar
    }

    return @{ Form = $form; Controls = $controls; Theme = $Theme }
}

function Get-GuiPageText {
    <#
      The two lines a rail entry shows: the page name and a state hint under it. Pure
      string work, so the gate can check that a rail entry answers "what is in there
      right now" without building a window.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)] $State,
        [int]$Backups = 0
    )

    $lang = $State.Language
    $key = @{ home = 'navOverview'; choose = 'navChoose'; apply = 'navApply'; restore = 'navRestore'; about = 'navAbout' }[$Name]
    $hintKey = @{ home = 'navOverviewHint'; choose = 'navChooseHint'; apply = 'navApplyHint'; restore = 'navRestoreHint'; about = 'navAboutHint' }[$Name]
    $hint = Get-GuiText -Key $hintKey -Language $lang
    switch ($Name) {
        'choose'  { $hint = $hint -f (Get-TuiSelectedCount -State $State) }
        'restore' { $hint = $hint -f $Backups }
    }
    return ("{0}`n{1}" -f (Get-GuiText -Key $key -Language $lang), $hint)
}

function Test-GuiSearchHintShown {
    <#
      Should the placeholder be drawn? Only while the box is empty and unfocused, so
      it never sits on top of something the user typed.

      A predicate rather than part of the sync because a window that is never shown
      reports Visible = $false for every control, and a test still has to be able to
      see the decision.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Controls)

    return ((-not $Controls.searchBox.Focused) -and (-not $Controls.searchBox.Text))
}

function Sync-GuiSearchHint {
    <#
      Draw the placeholder label, or get it out of the way.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Controls)

    $Controls.searchHint.Visible = (Test-GuiSearchHintShown -Controls $Controls)
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
    $filter = [string]$script:GuiApp.Filter
    $script:GuiApp.Syncing = $true
    try {
        $summary = Get-UiSummary -State $State
        $Controls.form.Text = '{0} {1}   {2}' -f (Get-GuiText -Key 'title' -Language $lang), $Version, $summary.title
        $Controls.topTitle.Text = Get-GuiText -Key 'title' -Language $lang
        $Controls.topPlan.Text = $summary.title
        $Controls.language.Text = (Get-GuiText -Key 'languageNow' -Language $lang) -f $State.Language.ToUpperInvariant()
        $Controls.language.AccessibleName = (Get-GuiText -Key 'language' -Language $lang)

        # The rail: name, state hint, and which page is on screen.
        $backups = @($script:GuiApp.Restore).Count
        foreach ($name in 'home', 'choose', 'apply', 'restore', 'about') {
            $Controls.nav[$name].Text = Get-GuiPageText -Name $name -State $State -Backups $backups
            Format-GuiNavButton -Button $Controls.nav[$name] -Theme $Controls.theme -Active ($script:GuiApp.Page -eq $name)
        }

        # Overview.
        $Controls.homeTitle.Text = Get-GuiText -Key 'homeTitle' -Language $lang
        $Controls.homeLead.Text = Get-GuiText -Key 'homeLead' -Language $lang
        $Controls.homeSafety.Text = Get-GuiText -Key 'homeSafety' -Language $lang
        $Controls.homeFacts.Text = (Get-GuiText -Key 'homeFacts' -Language $lang) -f (Get-GuiMachineFact), $summary.total, $State.Groups.Count
        $Controls.homeUse.Text = (Get-GuiText -Key 'homeUse' -Language $lang) -f (Get-TuiSelectedCount -State $State)
        $Controls.homePick.Text = Get-GuiText -Key 'homePick' -Language $lang
        $Controls.homeLastRun.Text = if ($script:GuiApp.LastRun) { (Get-GuiText -Key 'homeLastRun' -Language $lang) -f $script:GuiApp.LastRun } else { Get-GuiText -Key 'homeNever' -Language $lang }

        # Choosing: the area chips, with their tick counts, and the search state.
        $groups = @(Get-UiGroupRow -State $State)
        for ($i = 0; $i -lt $Controls.chips.Count; $i++) {
            $row = if ($i -lt $groups.Count) { $groups[$i] } else { $null }
            $chip = $Controls.chips[$i]
            $active = ($i -eq $State.ListIndex) -and (-not $filter.Trim())
            $chip.Text = if ($row) { '{0}  {1}/{2}' -f $row.name, $row.selected, $row.total } else { '' }
            $chip.Checked = $active
            $chip.AccessibleName = if ($row) { '{0} — {1}' -f (Get-GuiText -Key 'search' -Language $lang), $row.name } else { '' }
            Format-GuiChip -Chip $chip -Theme $Controls.theme -Active $active
        }
        $Controls.searchLabel.Text = Get-GuiText -Key 'search' -Language $lang
        $Controls.searchHint.Text = (Get-GuiText -Key 'searchHint' -Language $lang) -f $summary.total
        Sync-GuiSearchHint -Controls $Controls

        if (-not $SelectionOnly) {
            $rows = @(Get-UiActionRow -State $State -Filter $filter)
            $Controls.actionList.BeginUpdate()
            try {
                $Controls.actionList.Items.Clear()
                foreach ($row in $rows) {
                    [void]$Controls.actionList.Items.Add($row.title, $row.checked)
                }
                if ($Controls.actionList.Items.Count -gt 0) {
                    $Controls.actionList.Enabled = $true
                    $Controls.actionList.SelectedIndex = [Math]::Min($State.DetailIndex, $Controls.actionList.Items.Count - 1)
                } else {
                    $empty = if ($filter.Trim()) { 'searchEmpty' } else { 'listEmpty' }
                    [void]$Controls.actionList.Items.Add((Get-GuiText -Key $empty -Language $lang))
                    $Controls.actionList.Enabled = $false
                }
            } finally { $Controls.actionList.EndUpdate() }
        }

        $detail = Get-UiDetail -State $State -Filter $filter
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
        $Controls.chooseCount.Text = (Get-GuiText -Key 'chooseCount' -Language $lang) -f $summary.selected, $summary.total
        $Controls.chooseNext.Text = Get-GuiText -Key 'chooseNext' -Language $lang
        $Controls.chooseNext.Enabled = ($summary.selected -gt 0)

        # Applying: the plan in numbers, the plan as a list, and the run controls.
        $facts = Get-UiPlanFact -State $State
        $Controls.applyTitle.Text = Get-GuiText -Key 'applyTitle' -Language $lang
        $Controls.applyFacts.Text = if ($facts.total) {
            (Get-GuiText -Key 'applyFacts' -Language $lang) -f $facts.total, $facts.kinds['registry'], $facts.kinds['service'], $facts.kinds['task'], ($facts.removes + $facts.deletes)
        } else {
            Get-GuiText -Key 'applyNothing' -Language $lang
        }
        $Controls.applyRisky.Text = if ($facts.total -and $facts.risky) { (Get-GuiText -Key 'applyRisky' -Language $lang) -f $facts.risky } else { '' }
        $Controls.logLabel.Text = Get-GuiText -Key 'applyLog' -Language $lang
        $Controls.preview.Text = Get-GuiText -Key 'preview' -Language $lang
        $Controls.applyBack.Text = Get-GuiText -Key 'applyBack' -Language $lang
        $Controls.runIt.Text = (Get-GuiText -Key 'runIt' -Language $lang) -f $facts.total
        $Controls.runIt.Enabled = ($facts.total -gt 0)

        $applyLines = @(if ($facts.total) { Get-UiPlanText -State $State } else { @() })
        $Controls.applyList.BeginUpdate()
        try {
            $Controls.applyList.Items.Clear()
            # No SelectedIndex: this list is a statement, not a choice, and a
            # highlighted first row reads like one.
            foreach ($line in $applyLines) { [void]$Controls.applyList.Items.Add($line) }
        } finally { $Controls.applyList.EndUpdate() }

        # Restoring: the wording is static, the list is refreshed when the page is shown.
        $Controls.restoreTitle.Text = Get-GuiText -Key 'restoreTitle' -Language $lang
        $Controls.restoreLead.Text = Get-GuiText -Key 'restoreLead' -Language $lang
        $Controls.restoreRun.Text = Get-GuiText -Key 'restoreRun' -Language $lang
        $Controls.restoreOpen.Text = Get-GuiText -Key 'restoreOpen' -Language $lang
        $Controls.restoreRun.Enabled = ($Controls.restoreList.SelectedIndex -ge 0)
        $Controls.restoreOpen.Enabled = ($Controls.restoreList.SelectedIndex -ge 0)

        $Controls.aboutTitle.Text = Get-GuiText -Key 'aboutTitle' -Language $lang
        $Controls.aboutBody.Text = (Get-GuiText -Key 'aboutBody' -Language $lang) -f $Version, (Get-GuiLink)
    } finally {
        $script:GuiApp.Syncing = $false
    }
}

function Show-GuiPage {
    <#
      Put one page on screen: visibility, the rail highlight, the status line and --
      for the restore page -- a fresh look at the Desktop, which is the only page
      whose content lives outside the catalog.

      Returns the pages it left visible, which is one name, or an empty array for a
      page that does not exist. A hidden form reports Visible = $false for every
      child, so this is also how a test can see the switch happen without showing a
      window.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Controls,
        [Parameter(Mandatory)][string]$Name,
        $State,
        [string]$Version = ''
    )

    $names = @('home', 'choose', 'apply', 'restore', 'about')
    if ($names -notcontains $Name) { return @() }
    $script:GuiApp.Page = $Name

    $shown = New-Object System.Collections.Generic.List[string]
    foreach ($n in $names) {
        $visible = ($n -eq $Name)
        $Controls[$n + 'Page'].Visible = $visible
        if ($visible) { [void]$shown.Add($n) }
    }

    if ($Name -eq 'restore') {
        $script:GuiApp.Restore = @(Get-GuiRestoreRow)
        $Controls.restoreList.BeginUpdate()
        try {
            $Controls.restoreList.Items.Clear()
            foreach ($row in $script:GuiApp.Restore) { [void]$Controls.restoreList.Items.Add($row.label) }
            if ($Controls.restoreList.Items.Count -gt 0) { $Controls.restoreList.SelectedIndex = 0 }
        } finally { $Controls.restoreList.EndUpdate() }
        if ($script:GuiApp.Restore.Count -eq 0) {
            [void]$Controls.restoreList.Items.Add((Get-GuiText -Key 'restoreNone' -Language $(if ($State) { $State.Language } else { 'en' })))
        }
    }

    if ($State) {
        if (-not $script:GuiApp.Runner) {
            $Controls.status.Text = Get-GuiText -Key 'ready' -Language $State.Language
            $Controls.status.ForeColor = Get-GuiInk -Theme $Controls.theme -Role 'muted'
        }
        Sync-GuiView -Controls $Controls -State $State -Version $Version
        [void]$Controls.nav[$Name].Focus()
    }
    return $shown.ToArray()
}

function Get-GuiRestoreRow {
    <#
      The restore folders a previous run left on the Desktop, newest first, as rows a
      list can show. A row is a folder, a timestamp and whether it still holds the
      script that would undo the run.
    #>
    [CmdletBinding()]
    param()

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($point in @(Get-GuiRestorePoint)) {
        $script = Join-Path $point.FullName 'Restore-WinCleanKit.ps1'
        [void]$rows.Add([pscustomobject]@{
            name      = $point.Name
            path      = $point.FullName
            script    = $(if (Test-Path $script) { $script } else { '' })
            when      = $point.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            label     = ('{0}    {1}' -f $point.LastWriteTime.ToString('yyyy-MM-dd HH:mm'), $point.Name)
            undoable  = (Test-Path $script)
        })
    }
    return $rows.ToArray()
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

function Switch-GuiActionAt {
    <#
      Tick or untick the action at a row of the action list, then redraw.

      This is what the ItemCheck event runs, lifted out of the handler so a test can
      exercise it: a checkbox cannot be clicked without a mouse, and the part that
      matters is the state change, not the click.

      The row is read with the same filter the list was built with, so a row in a
      search result maps to the action it names rather than to whatever the focused
      category happens to have at that index.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [int]$Index)

    $rows = @(Get-UiActionRow -State $script:GuiApp.State -Filter $script:GuiApp.Filter)
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

function Switch-GuiCategory {
    <#
      Show one area: clear any search, move the category cursor, and redraw. Lifted
      out of the chip handler for the same reason Switch-GuiActionAt is lifted out of
      ItemCheck -- a test can call it.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$Index)

    $state = $script:GuiApp.State
    if ($Index -lt 0 -or $Index -ge $state.Groups.Count) { return $false }
    $wasSyncing = $script:GuiApp.Syncing
    $script:GuiApp.Syncing = $true
    try {
        $script:GuiApp.Filter = ''
        if ($script:GuiApp.Controls) { $script:GuiApp.Controls.searchBox.Text = '' }
    } finally {
        $script:GuiApp.Syncing = $wasSyncing
    }
    $state.ListIndex = $Index
    $state.DetailIndex = 0
    $state.Pane = 'list'
    if ($script:GuiApp.Controls) {
        Sync-GuiView -Controls $script:GuiApp.Controls -State $state -Version $script:GuiApp.Version
    }
    return $true
}

function Switch-GuiSearch {
    <#
      Apply the search text. An empty box means "the focused area"; anything else
      means "the whole catalog, filtered".
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Text)

    $script:GuiApp.Filter = $Text
    $script:GuiApp.State.DetailIndex = 0
    $script:GuiApp.State.Pane = 'detail'
    if ($script:GuiApp.Controls) {
        Sync-GuiView -Controls $script:GuiApp.Controls -State $script:GuiApp.State -Version $script:GuiApp.Version
        Sync-GuiSearchHint -Controls $script:GuiApp.Controls
    }
    return $true
}

function Initialize-GuiLayout {
    <#
      Give the list/detail splitter its proportion once the window has a real size.

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
        $split = $Controls.chooseSplit
        if ($Width -le 0) { return $false }
        $distance = [int]($Width * 0.56)
        if ($distance -lt $split.Panel1MinSize) { return $false }
        if ($distance -gt ($Width - $split.Panel2MinSize)) { return $false }
        $split.SplitterDistance = $distance
        $split.Panel1MinSize = [Math]::Max($split.Panel1MinSize, [Math]::Min(420, [int]($Width * 0.36)))
        $split.Panel2MinSize = [Math]::Max($split.Panel2MinSize, [Math]::Min(300, [int]($Width * 0.24)))
        return $true
    } catch {
        # The window is mid-layout or too small; the defaults are usable.
        return $false
    }
}

function Show-GuiPicker {
    <#
      A one-column list to pick from, used for choosing a restore point.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Owner,
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string[]]$Items,
        [string]$Language = 'en',
        $Theme
    )

    if (-not $Theme) { $Theme = $script:GuiApp.Theme }
    if (-not $Theme) { $Theme = Get-GuiTheme -Name (Get-GuiSystemTheme) }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(520, 360)
    $form.StartPosition = 'CenterParent'
    $form.Font = $Owner.Font
    $form.BackColor = Get-GuiInk -Theme $Theme -Role 'window'
    $form.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'

    $list = New-Object System.Windows.Forms.ListBox
    $list.Dock = 'Fill'
    $list.IntegralHeight = $false
    $list.BorderStyle = 'FixedSingle'
    $list.BackColor = Get-GuiInk -Theme $Theme -Role 'card'
    $list.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'
    foreach ($i in $Items) { [void]$list.Items.Add($i) }
    if ($list.Items.Count -gt 0) { $list.SelectedIndex = 0 }

    $foot = New-Object System.Windows.Forms.FlowLayoutPanel
    $foot.Dock = 'Bottom'
    $foot.Height = 52
    $foot.FlowDirection = 'RightToLeft'
    $foot.Padding = New-Object System.Windows.Forms.Padding(12, 10, 12, 10)
    $foot.BackColor = Get-GuiInk -Theme $Theme -Role 'window'

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = Get-GuiText -Key 'ok' -Language $Language
    $ok.DialogResult = 'OK'
    Format-GuiButton -Button $ok -Theme $Theme -Kind 'primary'
    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = Get-GuiText -Key 'cancel' -Language $Language
    $cancel.DialogResult = 'Cancel'
    Format-GuiButton -Button $cancel -Theme $Theme -Kind 'quiet'
    [void]$foot.Controls.Add($ok)
    [void]$foot.Controls.Add($cancel)

    $form.Controls.Add($list)
    $form.Controls.Add($foot)
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
    param($Theme)

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    [void](Enable-GuiDpiAwareness)
    [System.Windows.Forms.Application]::EnableVisualStyles()

    if (-not $Theme) { $Theme = Get-GuiTheme -Name (Get-GuiSystemTheme) }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'WinCleanKit'
    $form.Size = New-Object System.Drawing.Size(460, 210)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $form.BackColor = Get-GuiInk -Theme $Theme -Role 'window'
    $form.ForeColor = Get-GuiInk -Theme $Theme -Role 'text'

    $label = New-Object System.Windows.Forms.Label
    $label.Text = '请选择界面语言 / Choose your language'
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(24, 26)

    $zh = New-Object System.Windows.Forms.Button
    $zh.Text = '1  中文'
    $zh.Location = New-Object System.Drawing.Point(24, 74)
    $zh.Size = New-Object System.Drawing.Size(190, 46)
    $zh.DialogResult = 'OK'
    Format-GuiButton -Button $zh -Theme $Theme -Kind 'primary'

    $en = New-Object System.Windows.Forms.Button
    $en.Text = '2  English'
    $en.Location = New-Object System.Drawing.Point(230, 74)
    $en.Size = New-Object System.Drawing.Size(190, 46)
    $en.DialogResult = 'Cancel'
    Format-GuiButton -Button $en -Theme $Theme -Kind 'quiet'

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
    $controls.runIt.Enabled = $false
    $controls.preview.Enabled = $false
    $controls.restoreRun.Enabled = $false
    $controls.language.Enabled = $false
    $controls.bar.Value = 0
    $controls.status.Text = $BusyText
    $controls.status.ForeColor = Get-GuiInk -Theme $controls.theme -Role 'text'
    $script:GuiApp.Result = @{}

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

function Add-GuiLog {
    <#
      Append one line to the output box and keep it scrolled to the end. The engine
      prints a line per action plus the summary, so this is what a user reads while
      74 actions run -- and, more often, what they screenshot when one fails.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Controls, [Parameter(Mandatory)][string]$Line)

    if ($Controls.log.TextLength -gt 200000) { $Controls.log.Clear() }
    $Controls.log.AppendText($Line + [Environment]::NewLine)
    $Controls.log.SelectionStart = $Controls.log.TextLength
    $Controls.log.ScrollToCaret()
}

function Complete-GuiRun {
    <#
      Put the run to bed: read the counts the engine printed as JSON, say what
      happened in the status line and in colour, refresh what changed outside the
      window (the Desktop backups, the overview) and give the buttons back.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Controls)

    $lang = $script:GuiApp.State.Language
    $result = $script:GuiApp.Result
    $ok = if ($result.ContainsKey('ok')) { [int]$result['ok'] } else { -1 }
    $skipped = if ($result.ContainsKey('skipped')) { [int]$result['skipped'] } else { 0 }
    $failed = if ($result.ContainsKey('failed')) { [int]$result['failed'] } else { 0 }

    $script:GuiApp.Restore = @(Get-GuiRestoreRow)
    $script:GuiApp.LastRun = if ($script:GuiApp.Restore.Count) { $script:GuiApp.Restore[0].name } else { '' }

    if ($ok -ge 0) {
        $Controls.status.Text = (Get-GuiText -Key 'done' -Language $lang) -f $ok, $skipped, $failed
        $role = if ($failed -gt 0) { 'danger' } elseif ($skipped -gt 0) { 'caution' } else { 'success' }
    } else {
        $Controls.status.Text = Get-GuiText -Key 'doneGeneric' -Language $lang
        $role = 'muted'
    }
    $Controls.status.ForeColor = Get-GuiInk -Theme $Controls.theme -Role $role
    $Controls.progressLabel.Text = ''
    $Controls.runIt.Enabled = $true
    $Controls.preview.Enabled = $true
    $Controls.language.Enabled = $true
    $Controls.applyResult.Text = if ($result.ContainsKey('journal') -and $result['journal']) {
        (Get-GuiText -Key 'doneFolder' -Language $lang) -f [string]$result['journal']
    } else { '' }
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
        [string]$ThemeOverride = 'system',
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
    # Follow Windows unless the caller asked for a theme: the window should look like
    # the desktop it was opened on.
    $script:GuiApp.Theme = Get-GuiTheme -Name (Resolve-GuiTheme -Override $ThemeOverride)
    if ($lang -eq 'ask') { $lang = Show-GuiLanguageChooser -Theme $script:GuiApp.Theme }

    $script:UiOutcome = 0
    $script:UiApplied = $false
    $script:GuiApp.Syncing = $false
    $script:GuiApp.Version = $Version
    $script:GuiApp.Engine = $Engine
    $script:GuiApp.DryRun = [bool]$DryRun
    $script:GuiApp.Page = 'home'
    $script:GuiApp.Filter = ''
    $script:GuiApp.Facts = ''
    $script:GuiApp.Result = @{}
    $script:GuiApp.State = Initialize-TuiState -Catalog $Catalog -Language $lang
    # What a previous run left behind, read once: the overview and the restore page
    # both want it, and neither should scan the Desktop on every redraw.
    $script:GuiApp.Restore = @(Get-GuiRestoreRow)
    $script:GuiApp.LastRun = if ($script:GuiApp.Restore.Count) { $script:GuiApp.Restore[0].name } else { '' }

    $built = Initialize-GuiForm -State $script:GuiApp.State -Version $Version -Theme $script:GuiApp.Theme
    $script:GuiApp.Form = $built.Form
    $script:GuiApp.Controls = $built.Controls
    # Held for the process lifetime: Icon.FromHandle does not own the handle, so a
    # collected icon would take the window's icon with it.
    $script:GuiApp.Icon = Initialize-GuiIcon -Size 32 -Theme $script:GuiApp.Theme
    $script:GuiApp.Form.Icon = $script:GuiApp.Icon

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
                $done = [int]$Matches[1]
                $total = [int]$Matches[2]
                $script:GuiApp.Controls.bar.Maximum = $total
                $script:GuiApp.Controls.bar.Value = [Math]::Min($done, $script:GuiApp.Controls.bar.Maximum)
                $percent = if ($total -gt 0) { [int](100 * $done / $total) } else { 0 }
                $script:GuiApp.Controls.progressLabel.Text = "$done/$total  $percent%"
            }
            # The engine's JSON summary arrives as one property per line; taking them
            # here is what turns "the newest folder on the Desktop" into
            # "43 applied, 1 skipped, 1 failed".
            if ($line -match '^\s*"(ok|skipped|failed)"\s*:\s*(\d+)') {
                $script:GuiApp.Result[$Matches[1]] = [int]$Matches[2]
            }
            if ($line -match '^\s*"journal"\s*:\s*"([^"]*)"') {
                $script:GuiApp.Result['journal'] = $Matches[1] -replace '\\\\', '\'
            }
            if ($line.Trim()) {
                Add-GuiLog -Controls $script:GuiApp.Controls -Line $line.TrimEnd()
                # The status line carries the action in flight; the log keeps all of it.
                $script:GuiApp.Controls.status.Text = $line.Trim()
            }
        }
        $runner = $script:GuiApp.Runner
        if ($runner -and $runner.InvocationStateInfo.State -in @('Completed', 'Failed', 'Stopped')) {
            $script:GuiApp.Timer.Stop()
            Complete-GuiRun -Controls $script:GuiApp.Controls
            $runner.Dispose()
            $script:GuiApp.Runner = $null
            Sync-GuiView -Controls $script:GuiApp.Controls -State $script:GuiApp.State -Version $script:GuiApp.Version
        }
    })

    # ---- events ------------------------------------------------------------
    foreach ($name in 'home', 'choose', 'apply', 'restore', 'about') {
        $controls.nav[$name].Add_Click({
            $target = [string]$this.Tag
            [void](Show-GuiPage -Controls $script:GuiApp.Controls -Name $target `
                -State $script:GuiApp.State -Version $script:GuiApp.Version)
        })
    }

    for ($i = 0; $i -lt $controls.chips.Count; $i++) {
        $controls.chips[$i].Add_Click({
            if ($script:GuiApp.Syncing) { return }
            $index = [int]$this.Tag
            [void](Switch-GuiCategory -Index $index)
        })
    }

    $controls.searchBox.Add_TextChanged({
        if ($script:GuiApp.Syncing) { return }
        [void](Switch-GuiSearch -Text $controls.searchBox.Text)
    })
    $controls.searchBox.Add_GotFocus({ Sync-GuiSearchHint -Controls $script:GuiApp.Controls })
    $controls.searchBox.Add_LostFocus({ Sync-GuiSearchHint -Controls $script:GuiApp.Controls })

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

    $controls.homeUse.Add_Click({
        # "Just do the sensible thing": the defaults are already what the state opens
        # with, so this takes the user straight to the review page rather than asking
        # them to confirm a list they never saw.
        $script:GuiApp.State.Selected = Select-Default -Catalog $script:GuiApp.State.Catalog
        [void](Show-GuiPage -Controls $script:GuiApp.Controls -Name 'apply' `
            -State $script:GuiApp.State -Version $script:GuiApp.Version)
    })

    $controls.homePick.Add_Click({
        [void](Show-GuiPage -Controls $script:GuiApp.Controls -Name 'choose' `
            -State $script:GuiApp.State -Version $script:GuiApp.Version)
    })

    $controls.chooseNext.Add_Click({
        [void](Show-GuiPage -Controls $script:GuiApp.Controls -Name 'apply' `
            -State $script:GuiApp.State -Version $script:GuiApp.Version)
    })

    $controls.applyBack.Add_Click({
        [void](Show-GuiPage -Controls $script:GuiApp.Controls -Name 'choose' `
            -State $script:GuiApp.State -Version $script:GuiApp.Version)
    })

    $controls.preview.Add_Click({
        $text = (Get-UiPlanText -State $script:GuiApp.State) -join [Environment]::NewLine
        if (-not $script:GuiApp.State.Selected.Count) { $text = Get-GuiText -Key 'nothing' -Language $script:GuiApp.State.Language }
        [void][System.Windows.Forms.MessageBox]::Show($form, $text,
            (Get-GuiText -Key 'planTitle' -Language $script:GuiApp.State.Language), 'OK', 'Information')
    })

    $controls.runIt.Add_Click({
        $state = $script:GuiApp.State
        $ids = @(Get-TuiPlan -State $state)
        if ($ids.Count -eq 0) {
            [void][System.Windows.Forms.MessageBox]::Show($form, (Get-GuiText -Key 'nothing' -Language $state.Language),
                (Get-GuiText -Key 'title' -Language $state.Language), 'OK', 'Warning')
            return
        }
        $body = Get-GuiText -Key 'confirmBody' -Language $state.Language
        if ($script:GuiApp.DryRun) { $body = Get-GuiText -Key 'confirmDry' -Language $state.Language }
        $facts = Get-UiPlanFact -State $state
        $risk = if ($facts.risky) { (Get-GuiText -Key 'applyRisky' -Language $state.Language) -f $facts.risky } else { '' }
        $question = @(
            $body
            ''
            (Get-GuiText -Key 'applyFacts' -Language $state.Language) -f $facts.total, $facts.kinds['registry'], $facts.kinds['service'], $facts.kinds['task'], ($facts.removes + $facts.deletes)
            $risk
        ) -join [Environment]::NewLine
        $yes = [System.Windows.Forms.MessageBox]::Show($form, $question.Trim(),
            (Get-GuiText -Key 'confirmTitle' -Language $state.Language), 'YesNo', 'Question')
        if ($yes -ne 'Yes') { return }

        # -FromFile is the authoritative path: the engine applies exactly these ids
        # and nothing else, which is the same contract the console UI relies on.
        $idFile = Join-Path ([IO.Path]::GetTempPath()) ('wck-' + [Guid]::NewGuid().ToString('N').Substring(0, 8) + '.txt')
        [IO.File]::WriteAllLines($idFile, [string[]]$ids, (New-Object System.Text.UTF8Encoding($false)))
        $script:UiApplied = $true
        $controls.log.Clear()
        $script:GuiApp.Restore = @(Get-GuiRestoreRow)
        $engineArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:GuiApp.Engine,
                        '-Apply', '-NoPrompt', '-FromFile', $idFile, '-Language', $state.Language, '-EmitJson')
        if ($script:GuiApp.DryRun) { $engineArgs += '-DryRun' }
        $busy = Get-GuiText -Key $(if ($script:GuiApp.DryRun) { 'applyingDry' } else { 'applying' }) -Language $state.Language
        Invoke-GuiEngine -Command 'powershell' -BusyText $busy -Arguments $engineArgs
    })

    $controls.restoreList.Add_SelectedIndexChanged({
        if ($script:GuiApp.Syncing) { return }
        $index = $controls.restoreList.SelectedIndex
        $rows = @($script:GuiApp.Restore)
        if ($index -lt 0 -or $index -ge $rows.Count) {
            $controls.restoreDetail.Text = ''
            $controls.restoreRun.Enabled = $false
            $controls.restoreOpen.Enabled = $false
            return
        }
        $controls.restoreDetail.Text = (Get-GuiText -Key 'restorePath' -Language $script:GuiApp.State.Language) -f $rows[$index].path
        $controls.restoreRun.Enabled = [bool]$rows[$index].undoable
        $controls.restoreOpen.Enabled = $true
    })

    $controls.restoreOpen.Add_Click({
        $index = $controls.restoreList.SelectedIndex
        $rows = @($script:GuiApp.Restore)
        if ($index -lt 0 -or $index -ge $rows.Count) { return }
        Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $rows[$index].path + '"')
    })

    $controls.restoreRun.Add_Click({
        $index = $controls.restoreList.SelectedIndex
        $rows = @($script:GuiApp.Restore)
        if ($index -lt 0 -or $index -ge $rows.Count) { return }
        $row = $rows[$index]
        if (-not $row.undoable) { return }
        $yes = [System.Windows.Forms.MessageBox]::Show($form, $row.name,
            (Get-GuiText -Key 'restorePick' -Language $script:GuiApp.State.Language), 'YesNo', 'Warning')
        if ($yes -ne 'Yes') { return }
        $controls.log.Clear()
        Invoke-GuiEngine -Command 'powershell' -BusyText (Get-GuiText -Key 'restoring' -Language $script:GuiApp.State.Language) `
            -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $row.script)
    })

    $controls.language.Add_Click({
        $next = if ($script:GuiApp.State.Language -eq 'zh') { 'en' } else { 'zh' }
        $script:GuiApp.State = Select-TuiLanguage -State $script:GuiApp.State -Language $next
        Sync-GuiView -Controls $script:GuiApp.Controls -State $script:GuiApp.State -Version $script:GuiApp.Version
        $controls.status.Text = Get-GuiText -Key 'ready' -Language $script:GuiApp.State.Language
    })

    $controls.aboutLink.Add_LinkClicked({
        Start-Process -FilePath (Get-GuiLink)
    })

    # A SplitContainer validates SplitterDistance against the pane minimum sizes and
    # against its current width, which is small until the form lays out -- so the
    # proportion is applied once the window is on screen.
    $form.Add_Shown({
        [void](Initialize-GuiLayout -Controls $script:GuiApp.Controls -Width $script:GuiApp.Controls.chooseSplit.Width)
        [void](Show-GuiPage -Controls $script:GuiApp.Controls -Name 'home' `
            -State $script:GuiApp.State -Version $script:GuiApp.Version)
    })

    $form.Add_KeyDown({
        $key = $args[-1]
        switch ($key.KeyCode) {
            'Escape' { $form.Close() }
            'F1'     { $controls.nav['about'].PerformClick() }
            'F5'     { $controls.preview.PerformClick() }
            'F9'     { $controls.runIt.PerformClick() }
            'F'      { if ($key.Control) { [void](Show-GuiPage -Controls $controls -Name 'choose' -State $script:GuiApp.State -Version $script:GuiApp.Version); $controls.searchBox.Focus() } }
            'L'      { if ($key.Control) { $controls.language.PerformClick() } }
            'A'      { if ($key.Control) { $controls.selectAll.PerformClick() } }
            'N'      { if ($key.Control) { $controls.selectNone.PerformClick() } }
            'D1'     { if ($key.Control) { $controls.nav['home'].PerformClick() } }
            'D2'     { if ($key.Control) { $controls.nav['choose'].PerformClick() } }
            'D3'     { if ($key.Control) { $controls.nav['apply'].PerformClick() } }
            'D4'     { if ($key.Control) { $controls.nav['restore'].PerformClick() } }
            'D5'     { if ($key.Control) { $controls.nav['about'].PerformClick() } }
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
