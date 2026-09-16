@echo off
rem ===========================================================================
rem  WinCleanKit - interactive front-end
rem  https://github.com/ChanceFlow/WinCleanKit  (also mirrored on Gitea)
rem
rem  This .bat is only the user interface: elevation, menus, choice tracking and
rem  confirmation. All system changes are performed by src\WinCleanKit.ps1, which
rem  is data-driven from catalog\catalog.json.
rem
rem  License: MIT
rem ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion
rem The explicit <nul matters: chcp discards whatever is on the standard input
rem stream when it runs, so a session whose input is a file or a pipe would lose
rem its first lines -- the numbered menu then reads end-of-input immediately.
rem chcp needs no input, so handing it the null device keeps the real stream
rem intact. This is also why the interactive reads further down survive.
chcp 65001 <nul >nul 2>&1
title WinCleanKit

rem This file lives in the src folder, so the repository root is its parent.
rem The root is derived with the full-path modifier of a for variable rather than
rem from the current directory, whose trailing backslash differs between a drive
rem root and a subdirectory.
rem
rem The script path is captured into a variable FIRST, before the working
rem directory changes. cmd resolves a relative script name at the moment each
rem parameter is expanded, by joining it with the *current* directory -- not the
rem directory this file was called from. When run.bat calls the relative
rem "src\WinCleanKit.bat", the first expansion of the directory part yields
rem <root>\src\ while the current directory is still <root>; after the cd below,
rem the same expansion would yield <root>\src\src\. Reading it once at the top
rem removes that whole class of bug. Keep this comment free of parameter
rem substitution syntax: cmd expands those even inside rem, and a stray one is a
rem syntax error at parse time.
set "WCK_SRC=%~dp0"
set "WCK_BATSELF=%~f0"
cd /d "%WCK_SRC%"
for %%I in ("%WCK_SRC%..") do set "WCK_ROOT=%%~fI"
set "WCK_ENGINE=%WCK_ROOT%\src\WinCleanKit.ps1"
set "WCK_MENU=%WCK_ROOT%\src\menu\menu.ps1"
set "WCK_TMP=%TEMP%\wck-%RANDOM%%RANDOM%"

set "WCK_STATE=%WCK_TMP%\state"
set "WCK_PLUS=%WCK_STATE%\plus.txt"
set "WCK_MINUS=%WCK_STATE%\minus.txt"
set "WCK_LANG=zh"
set "WCK_UILANG=zh"

if not exist "%WCK_TMP%" mkdir "%WCK_TMP%" >nul 2>&1
if not exist "%WCK_STATE%" mkdir "%WCK_STATE%" >nul 2>&1

rem --- pick a PowerShell host -------------------------------------------------
set "WCK_PS="
where pwsh.exe >nul 2>&1 && set "WCK_PS=pwsh.exe"
if not defined WCK_PS (
    where powershell.exe >nul 2>&1 && set "WCK_PS=powershell.exe"
)
if not defined WCK_PS (
    echo.
    echo   [X] PowerShell was not found on this system.
    echo       WinCleanKit needs Windows PowerShell 5.1 or PowerShell 7+.
    echo.
    pause
    exit /b 1
)

rem Full path to the chosen host. Inside for /f backticks cmd keeps the quotes it
rem sees around a command name and then looks for a file literally named
rem "powershell.exe", so the unquoted full path is used there instead. Neither
rem path below contains a space.
if /i "%WCK_PS%"=="pwsh.exe" (
    for %%P in (pwsh.exe) do set "WCK_PSFULL=%%~$PATH:P"
) else (
    set "WCK_PSFULL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)
if not defined WCK_PSFULL set "WCK_PSFULL=%WCK_PS%"

rem --- command line -----------------------------------------------------------
rem Read the switches before elevation: the elevated instance is a fresh process,
rem so anything not forwarded on its command line is lost. A user who asked for the
rem accessible menu should not be dropped into the full-screen one, and a user who
rem asked for a language should not be asked for it again.
rem
rem   --gui                 the windowed interface (what run.bat asks for)
rem   --tui                 force the full-screen console interface
rem   --simple / --no-tui   the numbered menu instead of either interface
rem   --lang zh | en        skip the language chooser
rem   --zh / --en           the same thing, spelled short
rem   --lang=zh | --lang=en also accepted
rem
rem With no language switch the TUI opens on its language chooser, which is the
rem only place the language can be picked without knowing how to read it.
set "WCK_SIMPLE="
set "WCK_GUI="
set "WCK_TUI="
set "WCK_TUILANG=ask"
set "WCK_LANGSET="
set "WCK_LANGNEXT="
for %%A in (%*) do (
    if /i "%%A"=="--simple" set "WCK_SIMPLE=1"
    if /i "%%A"=="--no-tui" set "WCK_SIMPLE=1"
    if /i "%%A"=="--gui" set "WCK_GUI=1"
    if /i "%%A"=="--tui" set "WCK_TUI=1"
    if defined WCK_LANGNEXT (
        if /i "%%A"=="zh" set "WCK_LANGSET=zh"
        if /i "%%A"=="en" set "WCK_LANGSET=en"
        set "WCK_LANGNEXT="
    ) else (
        if /i "%%A"=="--lang" set "WCK_LANGNEXT=1"
        if /i "%%A"=="--lang=zh" set "WCK_LANGSET=zh"
        if /i "%%A"=="--lang=en" set "WCK_LANGSET=en"
        if /i "%%A"=="--zh" set "WCK_LANGSET=zh"
        if /i "%%A"=="--en" set "WCK_LANGSET=en"
    )
)
rem WCK_LANG is the language of what the tool reports (the menu data, the plan);
rem WCK_TUILANG is the language the interface opens in, and 'ask' opens the chooser.
if defined WCK_LANGSET (
    set "WCK_TUILANG=%WCK_LANGSET%"
    set "WCK_LANG=%WCK_LANGSET%"
)

net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo   [!] WinCleanKit needs administrator rights to change machine settings.
    echo       Relaunching with elevation...
    echo.
    if /i "%~1"=="--elevated" (
        echo   [X] Elevation was declined or failed. Nothing was changed.
        echo.
        pause
        exit /b 1
    )
    set "WCK_ELEVARGS=--elevated --lang %WCK_TUILANG%"
    if defined WCK_SIMPLE set "WCK_ELEVARGS=--elevated --simple --lang %WCK_TUILANG%"
    if defined WCK_GUI set "WCK_ELEVARGS=--elevated --gui --lang %WCK_TUILANG%"
    if defined WCK_TUI set "WCK_ELEVARGS=--elevated --tui --lang %WCK_TUILANG%"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%WCK_BATSELF%' -Verb RunAs -ArgumentList '!WCK_ELEVARGS!' -ErrorAction Stop" >nul 2>&1
    if errorlevel 1 (
        echo   [X] Could not elevate. Nothing was changed.
        echo.
        pause
    )
    exit /b
)

rem Fail loudly and specifically if the tree is incomplete, rather than letting
rem PowerShell report a confusing path error several steps later.
set "WCK_BAD="
if not exist "%WCK_ENGINE%" set "WCK_BAD=%WCK_ENGINE%"
if not exist "%WCK_MENU%"   set "WCK_BAD=%WCK_MENU%"
if defined WCK_BAD (
    echo.
    echo   [X] A required file is missing:
    echo       %WCK_BAD%
    echo.
    echo       Expected the repository layout:
    echo         WinCleanKit\run.bat
    echo         WinCleanKit\src\WinCleanKit.bat
    echo         WinCleanKit\src\WinCleanKit.ps1
    echo         WinCleanKit\src\menu\menu.ps1
    echo       If you extracted the archive into a folder of the same name,
    echo       move the inner folder up so this file sits at the top level.
    echo.
    pause
    endlocal
    exit /b 1
)
rem Colour variables are defined here, in the main process, because a label called
rem from inside a for /f subprocess fails with "Invalid attempt to call batch label
rem outside of batch script". Everything that renders a header relies on these
rem already being set.
set "C_RESET=[0m"
set "C_BRAND=[36m"
set "C_ACCENT=[96m"
set "C_OK=[92m"
set "C_MUTED=[90m"
set "C_WARN=[93m"

rem ===========================================================================
rem  Default path: hand the session to the PowerShell TUI.
rem
rem  cmd cannot read arrow keys, so a full-screen interface is impossible here.
rem  This file therefore does one thing well -- elevation -- and delegates the
rem  interface. Pass --simple (or --no-tui) for the numbered menu further down,
rem  which suits automation, screen readers, and consoles without ANSI support.
rem ===========================================================================
rem  WCK_SIMPLE was already resolved above, before elevation.
rem
rem  Three interfaces, in the order they degrade: the window (--gui), the
rem  full-screen console UI, and the numbered menu. Each reports whether it could
rem  run at all, so a machine with no desktop -- an SSH session, a scheduled task
rem  in session 0 -- drops to the next instead of failing.
if not defined WCK_SIMPLE (
    if defined WCK_GUI if not defined WCK_TUI (
        "%WCK_PS%" -NoProfile -ExecutionPolicy Bypass -File "%WCK_ENGINE%" -Gui -TuiExitCode -TuiLanguage "%WCK_TUILANG%"
        set "WCK_RC=!ERRORLEVEL!"
        if "!WCK_RC!"=="0" (
            endlocal
            exit /b 0
        )
        echo.
        echo   [i] No desktop for the window, so using the full-screen console UI.
        timeout /t 2 >nul 2>&1
    )
    "%WCK_PS%" -NoProfile -ExecutionPolicy Bypass -File "%WCK_ENGINE%" -Tui -TuiExitCode -TuiLanguage "%WCK_TUILANG%"
    set "WCK_RC=!ERRORLEVEL!"
    if "!WCK_RC!"=="0" (
        endlocal
        exit /b 0
    )
    if "!WCK_RC!"=="3" (
        echo.
        echo   [i] No interactive console here, so using the plain menu.
    ) else (
        echo.
        echo   [!] The interactive UI exited with code !WCK_RC!.
    )
    echo       Continuing with the plain numbered menu.
    timeout /t 2 >nul 2>&1
)
goto :main

:psrun
rem %* = arguments passed to the engine
"%WCK_PS%" -NoProfile -ExecutionPolicy Bypass -File "%WCK_ENGINE%" %*
exit /b %ERRORLEVEL%

:menurun
rem %* = arguments passed to the menu helper
"%WCK_PS%" -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" %*
exit /b %ERRORLEVEL%

:toolang
if /i "%WCK_UILANG%"=="zh" (set "WCK_TOOLANG=zh") else (set "WCK_TOOLANG=en")
exit /b 0

:saveans
if defined WCK_ANS set "WCK_ANS=%WCK_ANS:|=/%"
exit /b 0

:ask
rem %~1 = prompt text. Reads one line into WCK_ANS.
rem
rem set /p leaves its target variable untouched when the input stream has ended,
rem so seeding a sentinel first separates "the user pressed Enter" (answer is
rem empty, show the menu again) from "there is no more input at all" (stdin is a
rem file, NUL, or a closed pipe). Without this the numbered menu reprints itself
rem as fast as cmd can loop whenever the input ends, which is what happens under
rem automation, a scheduled task, or an automated test.
rem
rem The end-of-input flag exists because this label is reached through call, and
rem goto does not unwind the call stack: an exit /b from :bye would only return
rem to whichever menu called :ask, which would then loop. Each menu label checks
rem the flag on entry, so the exit unwinds one frame per bounce and ends at
rem :main, where the stack is empty and exit /b really does leave the script.
set "WCK_ANS=__WCK_EOF__"
set /p "WCK_ANS=%~1"
if "!WCK_ANS!"=="__WCK_EOF__" (
    echo.
    echo   [i] 输入已结束，退出。
    set "WCK_EOF=1"
    goto :bye
)
call :saveans
exit /b 0

:appendline
rem %1 = file, %2 = value
>>"%~1" echo %~2
exit /b 0

:removeline
rem %1 = file, %2 = exact value
if not exist "%~1" exit /b 0
set "WCK_RMVAL=%~2"
set "WCK_RMOUT=%~1.new"
if exist "%WCK_RMOUT%" del "%WCK_RMOUT%" >nul 2>&1
for /f "usebackq delims=" %%L in ("%~1") do (
    if not "%%L"=="!WCK_RMVAL!" >>"%WCK_RMOUT%" echo %%L
)
move /y "%WCK_RMOUT%" "%~1" >nul 2>&1
exit /b 0

:hasid
rem %1 = file, %2 = id ; sets WCK_HAS=1/0
set "WCK_HAS=0"
if not exist "%~1" exit /b 0
set "WCK_HAY=%~2"
for /f "usebackq delims=" %%L in ("%~1") do (
    if "%%L"=="!WCK_HAY!" set "WCK_HAS=1"
)
exit /b 0

:countlines
rem %1 = file ; sets WCK_COUNT
set /a WCK_COUNT=0
if not exist "%~1" exit /b 0
for /f "usebackq delims=" %%L in ("%~1") do set /a WCK_COUNT+=1
exit /b 0

:clearchoice
if exist "%WCK_PLUS%" del "%WCK_PLUS%" >nul 2>&1
if exist "%WCK_MINUS%" del "%WCK_MINUS%" >nul 2>&1
exit /b 0

:uiclear
rem Only used on exit now. The header inlines this sequence because calling a label
rem from inside a for /f subprocess is an error.
<nul set /p "=[H[2J[25;1H"
exit /b 0

:setcolours
rem Re-defines the colour variables. They are already set at startup; this exists
rem for clarity and for any future caller outside a for /f subprocess.
set "C_RESET=[0m"
set "C_BRAND=[36m"
set "C_ACCENT=[96m"
set "C_OK=[92m"
set "C_MUTED=[90m"
set "C_WARN=[93m"
exit /b 0

:header
rem Everything is inlined on purpose. The first render of this header happens
rem inside the for /f subprocess that reads the menu data, and calling a label
rem from there fails with "Invalid attempt to call batch label outside of batch
rem script", which printed an error on every screen.
echo.
echo   [H[2J[25;1H
echo   %C_BRAND%--------------------------------------------------------------------%C_RESET%
echo   %C_ACCENT%WinCleanKit%C_RESET%   Windows 11 广告 / 遥测 / 预装清理
echo   %C_BRAND%--------------------------------------------------------------------%C_RESET%
echo   %C_MUTED%语言: %C_RESET%%WCK_UILANG%
exit /b 0

rem ===========================================================================
rem  Category detail  (view only, with a shortcut to toggle the whole category)
rem ===========================================================================
:menu_cat
rem The input stream ended (see :ask): unwind one call frame and quit.
if defined WCK_EOF exit /b 0
set "WCK_CAT=%~1"
call :header
call :toolang
for /f "usebackq tokens=1,2,3 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode cat -Category "%WCK_CAT%"`) do (
    if "%%C"=="1" (echo     [x] %%B) else (echo     [ ] %%B)
)
echo.
echo     T. 切换本类全部
echo     B. 返回
echo.
call :ask "  输入 T 切换 / B 返回: "
if /i "%WCK_ANS%"=="b" exit /b 0
if /i "%WCK_ANS%"=="t" (
    rem If the whole category is currently on, turn it off; otherwise turn it on.
    set "WCK_CATON=0"
    set "WCK_CATOFF=0"
    for /f "usebackq tokens=1,3 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode cat -Category "%WCK_CAT%"`) do (
        if "%%B"=="1" set /a WCK_CATON+=1
        if not "%%B"=="1" set /a WCK_CATOFF+=1
    )
    for /f "usebackq tokens=1,3 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode cat -Category "%WCK_CAT%"`) do (
        if !WCK_CATOFF! GTR 0 (
            rem turn all on
            if "%%B"=="0" (
                call :removeline "%WCK_MINUS%" "%%A"
                call :hasid "%WCK_PLUS%" "%%A"
                if "!WCK_HAS!"=="0" call :appendline "%WCK_PLUS%" "%%A"
            ) else (
                call :removeline "%WCK_MINUS%" "%%A"
            )
        ) else (
            rem turn all off
            if "%%B"=="1" (
                call :removeline "%WCK_PLUS%" "%%A"
                call :hasid "%WCK_MINUS%" "%%A"
                if "!WCK_HAS!"=="0" call :appendline "%WCK_MINUS%" "%%A"
            ) else (
                call :removeline "%WCK_PLUS%" "%%A"
            )
        )
    )
)
goto :menu_cat

:menu_cats
rem The input stream ended (see :ask): unwind one call frame and quit.
if defined WCK_EOF exit /b 0
call :header
call :toolang
echo.
echo   --------------------------------------------------------------------
echo     按分类选择
echo   --------------------------------------------------------------------
for /f "usebackq tokens=1,2,3 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode main`) do (
    if not "%%A"=="TOTAL" (
        if "%%C" GTR 0 (echo     [x] %%A  %%B   已选 %%C 项) else (echo     [ ] %%A  %%B   已选 %%C 项)
    )
)
echo.
echo     输入分类代号查看详情并切换（如 ads）
echo     B. 返回
echo.
call :ask "  代号 / B: "
if /i "%WCK_ANS%"=="b" exit /b 0
set "WCK_FOUNDCAT=0"
for /f "usebackq tokens=1 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode main`) do (
    if /i "%%A"=="%WCK_ANS%" set "WCK_FOUNDCAT=1"
)
if "%WCK_FOUNDCAT%"=="1" call :menu_cat "%WCK_ANS%"
goto :menu_cats

rem ===========================================================================
rem  Per-item customisation
rem ===========================================================================
:menu_items
rem The input stream ended (see :ask): unwind one call frame and quit.
if defined WCK_EOF exit /b 0
call :header
call :toolang
echo.
echo   --------------------------------------------------------------------
echo     逐项自定义   [x]=执行  [ ]=跳过
echo   --------------------------------------------------------------------
for /f "usebackq tokens=1,2,3,4,5 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode items`) do (
    if "%%E"=="1" (echo     [x] %%A. %%C) else (echo     [ ] %%A. %%C)
)
echo.
echo     输入编号切换该项;  A. 全部选中此项;  N. 全部取消;  B. 返回
echo.
call :ask "  编号 / A / N / B: "
if /i "%WCK_ANS%"=="b" exit /b 0
if /i "%WCK_ANS%"=="a" (
    call :clearchoice
    goto :menu_items
)
if /i "%WCK_ANS%"=="n" (
    for /f "usebackq tokens=2 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode items`) do call :appendline "%WCK_MINUS%" "%%A"
    goto :menu_items
)
set "WCK_PICKID="
set "WCK_PICKSEL="
for /f "usebackq tokens=1,2,5 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode items`) do (
    if "%%A"=="%WCK_ANS%" (
        set "WCK_PICKID=%%B"
        set "WCK_PICKSEL=%%C"
    )
)
if not defined WCK_PICKID (
    echo     [!] 无效编号
    timeout /t 1 >nul
    goto :menu_items
)
if "%WCK_PICKSEL%"=="1" (
    call :removeline "%WCK_PLUS%" "%WCK_PICKID%"
    call :hasid "%WCK_MINUS%" "%WCK_PICKID%"
    if "!WCK_HAS!"=="0" call :appendline "%WCK_MINUS%" "%WCK_PICKID%"
) else (
    call :removeline "%WCK_MINUS%" "%WCK_PICKID%"
    call :hasid "%WCK_PLUS%" "%WCK_PICKID%"
    if "!WCK_HAS!"=="0" call :appendline "%WCK_PLUS%" "%WCK_PICKID%"
)
goto :menu_items

rem ===========================================================================
rem  Summary bar
rem ===========================================================================
:summarybar
for /f "usebackq tokens=1,2,3,4 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode summary`) do (
    echo     当前计划: 共 %%B 项   ^(手动加 %%C / 手动减 %%D^)
)
exit /b 0

rem ===========================================================================
rem  Preview
rem ===========================================================================
:do_preview
call :header
call :toolang
rem Hand the resolved selection over as a file: it survives any number of items
rem and avoids comma/quote games on the command line.
set "WCK_SELFILE=%WCK_TMP%\selection.txt"
if exist "%WCK_SELFILE%" del "%WCK_SELFILE%" >nul 2>&1
for /f "usebackq delims=" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode sel`) do >>"%WCK_SELFILE%" echo %%A
call :countlines "%WCK_SELFILE%"
if "%WCK_COUNT%"=="0" (
    echo     [!] 当前没有选中任何项目。
    echo.
    pause
    exit /b 0
)
call :psrun -Plan -NoPrompt -FromFile "%WCK_SELFILE%" -Language "%WCK_TOOLANG%"
echo.
pause
exit /b 0

rem ===========================================================================
rem  Apply
rem ===========================================================================
:do_apply
call :header
call :toolang
for /f "usebackq tokens=1,2 delims=|" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode summary`) do (
    echo     即将执行: 共 %%B 项
)
echo.
echo     --------------------------------------------------------------------
echo     安全检查
echo     --------------------------------------------------------------------
echo       * 会先写入一份备份到桌面 WinCleanKit-时间戳\ ，含一键还原脚本
echo       * 不修改 hosts 文件；不触碰你的个人文件、壁纸与 OneDrive 数据目录
echo       * 被卸载的应用可从 Microsoft Store 重新安装
echo.
echo     [1] 先预览（不修改任何东西）
echo     [2] 直接执行
echo     [3] 模拟执行（dry run，不写入但走完整流程）
echo     B. 取消
echo.
call :ask "  选择: "
if defined WCK_EOF exit /b 0
if /i "%WCK_ANS%"=="1" (call :do_preview & exit /b 0)
if /i "%WCK_ANS%"=="b" exit /b 0

set "WCK_SELFILE=%WCK_TMP%\selection.txt"
if exist "%WCK_SELFILE%" del "%WCK_SELFILE%" >nul 2>&1
for /f "usebackq delims=" %%A in (`%WCK_PSFULL% -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" -Mode sel`) do >>"%WCK_SELFILE%" echo %%A
call :countlines "%WCK_SELFILE%"
if "%WCK_COUNT%"=="0" (
    echo     [!] 当前没有选中任何项目。
    echo.
    pause
    exit /b 0
)

if /i "%WCK_ANS%"=="3" (
    call :psrun -Apply -DryRun -FromFile "%WCK_SELFILE%" -Language "%WCK_TOOLANG%" -NoPrompt
    echo.
    pause
    exit /b 0
)

echo.
echo     输入 APPLY 确认执行，其他任意键取消:
call :ask "  > "
if defined WCK_EOF exit /b 0
if /i not "%WCK_ANS%"=="APPLY" (
    echo     已取消。
    timeout /t 1 >nul
    exit /b 0
)
call :psrun -Apply -FromFile "%WCK_SELFILE%" -Language "%WCK_TOOLANG%" -NoPrompt
echo.
pause
exit /b 0

rem ===========================================================================
rem  Restore
rem ===========================================================================
:do_restore
call :header
call :toolang
echo.
echo   --------------------------------------------------------------------
echo     还原点（桌面 WinCleanKit-* 目录）
echo   --------------------------------------------------------------------
call :psrun -ListRestores -Language "%WCK_TOOLANG%"
echo.
echo     输入要还原的目录名（完整名称），或 B 返回:
call :ask "  > "
if defined WCK_EOF exit /b 0
if /i "%WCK_ANS%"=="b" exit /b 0
if not defined WCK_ANS exit /b 0
call :psrun -Restore "%WCK_ANS%" -Language "%WCK_TOOLANG%"
echo.
pause
exit /b 0

:do_lang
if /i "%WCK_UILANG%"=="zh" (set "WCK_UILANG=en") else (set "WCK_UILANG=zh")
exit /b 0

:do_about
call :header
echo.
echo   WinCleanKit - 开源 Windows 11 减负工具
echo.
echo   引擎版本 : 见 src\WinCleanKit.ps1
echo   Catalog  : catalog\catalog.json  (所有操作都是数据，可自行增删)
echo   许可证   : MIT
echo.
echo   设计原则
echo     * 用户决策权优先: 基础项默认 + 分类选择 + 逐项开关 + 强制预览
echo     * 全量可回滚: 每次执行在桌面生成备份与一键还原脚本
echo     * 不碰 hosts / 不碰个人文件 / 不碰壁纸与 OneDrive 数据目录
echo     * 只做你选中的事，额外的一项都不做
echo.
pause
exit /b 0

:do_cleanup
if exist "%WCK_TMP%" rd /s /q "%WCK_TMP%" >nul 2>&1
exit /b 0

rem ===========================================================================
rem  Main
rem ===========================================================================
:main
rem The input stream ended (see :ask). This label is reached with an empty call
rem stack, so the exit below leaves the script instead of bouncing again.
if defined WCK_EOF exit /b 0
call :header
echo.
call :summarybar
echo.
echo   --------------------------------------------------------------------
echo     主菜单
echo   --------------------------------------------------------------------
echo     1. 按分类选择          (勾选整个分类)
echo     2. 逐项自定义          (每个动作单独开关，基础项已默认勾选)
echo     3. 预览当前计划        (不修改任何东西)
echo     4. 执行                (会再次确认，先备份)
echo     5. 还原                (从桌面还原点恢复)
echo     6. 切换语言            (当前 %WCK_UILANG%)
echo     7. 关于
echo     0. 退出
echo.
call :ask "  选择: "
if "%WCK_ANS%"=="1" (call :menu_cats   & goto :main)
if "%WCK_ANS%"=="2" (call :menu_items  & goto :main)
if "%WCK_ANS%"=="3" (call :do_preview  & goto :main)
if "%WCK_ANS%"=="4" (call :do_apply    & goto :main)
if "%WCK_ANS%"=="5" (call :do_restore  & goto :main)
if "%WCK_ANS%"=="6" (call :do_lang     & goto :main)
if "%WCK_ANS%"=="7" (call :do_about    & goto :main)
if "%WCK_ANS%"=="0" goto :bye
goto :main

:bye
call :do_cleanup
call :uiclear
echo.
echo   已退出。没有做任何未确认的改动。
echo.
endlocal
exit /b 0
