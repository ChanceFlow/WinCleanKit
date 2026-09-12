@echo off
rem ===========================================================================
rem  WinCleanKit - double-click launcher.
rem
rem  The tool itself lives in src\WinCleanKit.bat. This shim exists so that a
rem  user who unzips the repository sees one obvious file to double-click,
rem  instead of having to know that the entry point is under src\.
rem
rem  License: MIT
rem ===========================================================================
setlocal
cd /d "%~dp0"
if not exist "src\WinCleanKit.bat" (
    echo.
    echo   [XX]  src\WinCleanKit.bat is missing.
    echo         Run this file from inside the WinCleanKit folder.
    echo.
    pause
    exit /b 1
)
call "src\WinCleanKit.bat" %*
endlocal
