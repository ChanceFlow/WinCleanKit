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
chcp 65001 >nul 2>&1
title WinCleanKit

cd /d "%~dp0"
set "WCK_ROOT=%CD%"
set "WCK_ENGINE=%WCK_ROOT%\src\WinCleanKit.ps1"
set "WCK_MENU=%WCK_ROOT%\src\menu\menu.ps1"
set "WCK_TMP=%TEMP%\wck-%RANDOM%%RANDOM%"
set "WCK_STATE=%WCK_TMP%\state"
set "WCK_PLUS=%WCK_STATE%\plus.txt"
set "WCK_MINUS=%WCK_STATE%\minus.txt"
set "WCK_MODE=balanced"
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

rem --- elevation --------------------------------------------------------------
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
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated' -ErrorAction Stop" >nul 2>&1
    if errorlevel 1 (
        echo   [X] Could not elevate. Nothing was changed.
        echo.
        pause
    )
    exit /b
)

rem ===========================================================================
rem  Helpers
rem ===========================================================================
goto :main

:psrun
rem %* = arguments passed to the engine
"%WCK_PS%" -NoProfile -ExecutionPolicy Bypass -File "%WCK_ENGINE%" %*
exit /b %ERRORLEVEL%

:menurun
rem %* = arguments passed to the menu helper
"%WCK_PS%" -NoProfile -ExecutionPolicy Bypass -File "%WCK_MENU%" -Preset "%WCK_MODE%" -Lang "%WCK_LANG%" -PlusFile "%WCK_PLUS%" -MinusFile "%WCK_MINUS%" %*
exit /b %ERRORLEVEL%

:toolang
if /i "%WCK_UILANG%"=="zh" (set "WCK_TOOLANG=zh") else (set "WCK_TOOLANG=en")
exit /b 0

:riskzh
set "WCK_RISKTXT="
if "%~1"=="1" set "WCK_RISKTXT=低"
if "%~1"=="2" set "WCK_RISKTXT=中"
if "%~1"=="3" set "WCK_RISKTXT=高"
exit /b 0

:saveans
if defined WCK_ANS set "WCK_ANS=%WCK_ANS:|=/%"
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
cls
exit /b 0

:legend
echo   风险等级:  低 = 可逆、无副作用     中 = 有可见取舍     高 = 会删除程序或数据
exit /b 0

:header
call :toolang
call :uiclear
echo.
echo   ====================================================================
echo     WinCleanKit   Windows 11 广告 / 遥测 / 预装清理
echo   ====================================================================
echo     预设: %WCK_MODE%      语言: %WCK_UILANG%
call :legend
exit /b 0

rem ===========================================================================
rem  Preset
rem ===========================================================================
:menu_preset
call :header
echo.
echo   --------------------------------------------------------------------
echo     选择预设
echo   --------------------------------------------------------------------
if /i "%WCK_MODE%"=="conservative" (echo     [x] 1. conservative  仅关闭广告与推荐，最保守) else (echo     [ ] 1. conservative  仅关闭广告与推荐，最保守)
if /i "%WCK_MODE%"=="balanced"     (echo     [x] 2. balanced      广告 + 遥测 + 明确不需要的预装应用) else (echo     [ ] 2. balanced      广告 + 遥测 + 明确不需要的预装应用)
if /i "%WCK_MODE%"=="aggressive"   (echo     [x] 3. aggressive    上面全部 + 有取舍的项目（游戏栏、OneDrive、定位等）) else (echo     [ ] 3. aggressive    上面全部 + 有取舍的项目（游戏栏、OneDrive、定位等）)
echo.
call :summarybar
echo.
echo     B. 返回
echo.
set /p "WCK_ANS=  输入编号: "
call :saveans
if /i "%WCK_ANS%"=="1" set "WCK_MODE=conservative"
if /i "%WCK_ANS%"=="2" set "WCK_MODE=balanced"
if /i "%WCK_ANS%"=="3" set "WCK_MODE=aggressive"
if /i "%WCK_ANS%"=="b" exit /b 0
goto :menu_preset

rem ===========================================================================
rem  Category detail  (view only, with a shortcut to toggle the whole category)
rem ===========================================================================
:menu_cat
set "WCK_CAT=%~1"
call :header
call :toolang
for /f "usebackq tokens=1,2,3,4 delims=|" %%A in (`call :menurun -Mode cat -Category "%WCK_CAT%"`) do (
    if "%%D"=="1" (echo     [x] %%B   [%%C]) else (echo     [ ] %%B   [%%C])
)
echo.
echo     T. 切换本类全部
echo     B. 返回
echo.
set /p "WCK_ANS=  输入 T 切换 / B 返回: "
call :saveans
if /i "%WCK_ANS%"=="b" exit /b 0
if /i "%WCK_ANS%"=="t" (
    rem If the whole category is currently on, turn it off; otherwise turn it on.
    set "WCK_CATON=0"
    set "WCK_CATOFF=0"
    for /f "usebackq tokens=1,4 delims=|" %%A in (`call :menurun -Mode cat -Category "%WCK_CAT%"`) do (
        if "%%B"=="1" set /a WCK_CATON+=1
        if not "%%B"=="1" set /a WCK_CATOFF+=1
    )
    for /f "usebackq tokens=1,4 delims=|" %%A in (`call :menurun -Mode cat -Category "%WCK_CAT%"`) do (
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
call :header
call :toolang
echo.
echo   --------------------------------------------------------------------
echo     按分类选择
echo   --------------------------------------------------------------------
for /f "usebackq tokens=1,2,3,4 delims=|" %%A in (`call :menurun -Mode main`) do (
    if not "%%A"=="TOTAL" (
        call :riskzh %%D
        if "%%C" GTR 0 (echo     [x] %%A  %%B   [!WCK_RISKTXT!]  已选 %%C 项) else (echo     [ ] %%A  %%B   [!WCK_RISKTXT!]  已选 %%C 项)
    )
)
echo.
echo     输入分类代号查看详情并切换（如 ads）
echo     B. 返回
echo.
set /p "WCK_ANS=  代号 / B: "
call :saveans
if /i "%WCK_ANS%"=="b" exit /b 0
set "WCK_FOUNDCAT=0"
for /f "usebackq tokens=1,3,4 delims=|" %%A in (`call :menurun -Mode main`) do (
    if /i "%%A"=="%WCK_ANS%" set "WCK_FOUNDCAT=1"
)
if "%WCK_FOUNDCAT%"=="1" call :menu_cat "%WCK_ANS%"
goto :menu_cats

rem ===========================================================================
rem  Per-item customisation
rem ===========================================================================
:menu_items
call :header
call :toolang
echo.
echo   --------------------------------------------------------------------
echo     逐项自定义   [x]=执行  [ ]=跳过
echo   --------------------------------------------------------------------
for /f "usebackq tokens=1,2,3,4,5,6 delims=|" %%A in (`call :menurun -Mode items`) do (
    if "%%F"=="1" (echo     [x] %%A. %%C   [%%D]) else (echo     [ ] %%A. %%C   [%%D])
)
echo.
echo     输入编号切换该项;  A. 全部选中此预设;  N. 全部取消;  B. 返回
echo.
set /p "WCK_ANS=  编号 / A / N / B: "
call :saveans
if /i "%WCK_ANS%"=="b" exit /b 0
if /i "%WCK_ANS%"=="a" (
    call :clearchoice
    goto :menu_items
)
if /i "%WCK_ANS%"=="n" (
    for /f "usebackq tokens=2 delims=|" %%A in (`call :menurun -Mode items`) do call :appendline "%WCK_MINUS%" "%%A"
    goto :menu_items
)
set "WCK_PICKID="
set "WCK_PICKSEL="
for /f "usebackq tokens=1,2,6 delims=|" %%A in (`call :menurun -Mode items`) do (
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
for /f "usebackq tokens=1,2,3,4,5 delims=|" %%A in (`call :menurun -Mode summary`) do (
    call :riskzh %%C
    echo     当前计划: 共 %%B 项, 最高风险 [!WCK_RISKTXT!]   ^(手动加 %%D / 手动减 %%E^)
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
for /f "usebackq delims=" %%A in (`call :menurun -Mode sel`) do >>"%WCK_SELFILE%" echo %%A
call :countlines "%WCK_SELFILE%"
if "%WCK_COUNT%"=="0" (
    echo     [!] 当前没有选中任何项目。
    echo.
    pause
    exit /b 0
)
call :psrun -Plan -NoPrompt -Preset "%WCK_MODE%" -FromFile "%WCK_SELFILE%" -Language "%WCK_TOOLANG%"
echo.
pause
exit /b 0

rem ===========================================================================
rem  Apply
rem ===========================================================================
:do_apply
call :header
call :toolang
for /f "usebackq tokens=1,2,3,4,5 delims=|" %%A in (`call :menurun -Mode summary`) do (
    call :riskzh %%C
    echo     即将执行: 共 %%B 项, 最高风险 [!WCK_RISKTXT!]
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
set /p "WCK_ANS=  选择: "
call :saveans
if /i "%WCK_ANS%"=="1" (call :do_preview & exit /b 0)
if /i "%WCK_ANS%"=="b" exit /b 0

set "WCK_SELFILE=%WCK_TMP%\selection.txt"
if exist "%WCK_SELFILE%" del "%WCK_SELFILE%" >nul 2>&1
for /f "usebackq delims=" %%A in (`call :menurun -Mode sel`) do >>"%WCK_SELFILE%" echo %%A
call :countlines "%WCK_SELFILE%"
if "%WCK_COUNT%"=="0" (
    echo     [!] 当前没有选中任何项目。
    echo.
    pause
    exit /b 0
)

if /i "%WCK_ANS%"=="3" (
    call :psrun -Apply -DryRun -Preset "%WCK_MODE%" -FromFile "%WCK_SELFILE%" -Language "%WCK_TOOLANG%" -NoPrompt
    echo.
    pause
    exit /b 0
)

echo.
echo     输入 APPLY 确认执行，其他任意键取消:
set /p "WCK_ANS=  > "
call :saveans
if /i not "%WCK_ANS%"=="APPLY" (
    echo     已取消。
    timeout /t 1 >nul
    exit /b 0
)
call :psrun -Apply -Preset "%WCK_MODE%" -FromFile "%WCK_SELFILE%" -Language "%WCK_TOOLANG%" -NoPrompt
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
set /p "WCK_ANS=  > "
call :saveans
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
echo     * 用户决策权优先: 三档预设 + 分类选择 + 逐项开关 + 强制预览
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
call :header
echo.
call :summarybar
echo.
echo   --------------------------------------------------------------------
echo     主菜单
echo   --------------------------------------------------------------------
echo     1. 选择预设            (conservative / balanced / aggressive)
echo     2. 按分类选择          (勾选整个分类)
echo     3. 逐项自定义          (每个动作单独开关)
echo     4. 预览当前计划        (不修改任何东西)
echo     5. 执行                (会再次确认，先备份)
echo     6. 还原                (从桌面还原点恢复)
echo     7. 切换语言            (当前 %WCK_UILANG%)
echo     8. 关于
echo     0. 退出
echo.
set /p "WCK_ANS=  选择: "
call :saveans
if "%WCK_ANS%"=="1" (call :menu_preset & goto :main)
if "%WCK_ANS%"=="2" (call :menu_cats   & goto :main)
if "%WCK_ANS%"=="3" (call :menu_items  & goto :main)
if "%WCK_ANS%"=="4" (call :do_preview  & goto :main)
if "%WCK_ANS%"=="5" (call :do_apply    & goto :main)
if "%WCK_ANS%"=="6" (call :do_restore  & goto :main)
if "%WCK_ANS%"=="7" (call :do_lang     & goto :main)
if "%WCK_ANS%"=="8" (call :do_about    & goto :main)
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
