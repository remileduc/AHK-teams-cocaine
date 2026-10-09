@echo off
setlocal
:: Double-click to recompile teams-cocaine.ahk into teams-cocaine.exe.
:: If teams-cocaine.exe is running it is stopped first and relaunched afterwards.
:: Also run by GitHub Actions, where CI is defined and the pause is skipped.

cd /d "%~dp0"

set "AHK2EXE=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "AHKBASE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
set "SRC=teams-cocaine.ahk"
set "OUT=teams-cocaine.exe"

if not exist "%AHK2EXE%" (
    echo ERROR: Ahk2Exe not found at "%AHK2EXE%".
    echo Install it from the AutoHotkey Dash ^(Compile ^> Install Ahk2Exe^).
    goto :fail
)
if not exist "%AHKBASE%" (
    echo ERROR: AutoHotkey v2 not found at "%AHKBASE%".
    goto :fail
)
if not exist "%SRC%" (
    echo ERROR: "%SRC%" not found next to this script.
    goto :fail
)

echo Validating %SRC% ...
"%AHKBASE%" /validate /ErrorStdOut "%SRC%"
if errorlevel 1 (
    echo.
    echo VALIDATION FAILED.
    goto :fail
)

set "WAS_RUNNING=0"
:: fully qualified path: Git for Windows puts a Unix "find" ahead of the Windows one on PATH
tasklist /FI "IMAGENAME eq %OUT%" /NH 2>nul | "%SystemRoot%\System32\findstr.exe" /I /C:"%OUT%" >nul
if not errorlevel 1 (
    set "WAS_RUNNING=1"
    echo %OUT% is running. Stopping it so the file can be overwritten...
    taskkill /IM "%OUT%" /F >nul
    rem give Windows a moment to release the file handle
    rem (ping instead of timeout: timeout.exe refuses to run when stdin is redirected;
    rem  "rem" instead of "::" because :: breaks inside parenthesized blocks)
    "%SystemRoot%\System32\ping.exe" -n 2 127.0.0.1 >nul
)

echo Compiling %SRC% -^> %OUT% ...
echo.
"%AHK2EXE%" /in "%SRC%" /out "%OUT%" /base "%AHKBASE%" /silent verbose
if errorlevel 1 (
    echo.
    echo BUILD FAILED. The previous %OUT% is untouched.
    if "%WAS_RUNNING%"=="1" (
        echo Relaunching the previous %OUT% ...
        start "" "%OUT%"
    )
    goto :fail
)

echo.
echo Build succeeded.

if "%WAS_RUNNING%"=="1" (
    echo Relaunching %OUT% ...
    start "" "%OUT%"
)

echo.
if not defined CI pause
exit /b 0

:fail
echo.
if not defined CI pause
exit /b 1
