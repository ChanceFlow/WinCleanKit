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
rem  Capture the folder once, before cd, for the same reason described below:
rem  a parameter carrying a relative script name is re-resolved against the
rem  current directory on every expansion.
set "WCK_HOME=%~dp0"
cd /d "%WCK_HOME%"
if not exist "%WCK_HOME%src\WinCleanKit.bat" (
    echo.
    echo   [XX]  src\WinCleanKit.bat is missing.
    echo         Run this file from inside the WinCleanKit folder.
    echo.
    pause
    exit /b 1
)
rem  The callee is reached through an absolute path on purpose. cmd resolves a
rem  relative script name at the moment a parameter such as the directory part is
rem  expanded, by joining it with the current directory, so a relative call would
rem  make the callee re-resolve its own location from inside src\ and see src\src.
call "%WCK_HOME%src\WinCleanKit.bat" %*
endlocal
