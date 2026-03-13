@echo off
setlocal enabledelayedexpansion
title Cognithor Control Center
color 0F

:: ============================================================
::  COGNITHOR ONE-CLICK LAUNCHER
::  Prueft Abhaengigkeiten, bootstrappt beim ersten Start,
::  startet dann die Web-UI.
:: ============================================================

:: UTF-8 fuer Python-Output aktivieren
chcp 65001 >nul 2>&1

echo.
echo    ____  ___   ____ _   _ ___ _____ _   _  ___  ____
echo   / ___^|/ _ \ / ___^| \ ^| ^|_ _^|_   _^| ^| ^| ^|/ _ \^|  _ \
echo  ^| ^|   ^| ^| ^| ^| ^|  _^|  \^| ^|^| ^|  ^| ^| ^| ^|_^| ^| ^| ^| ^| ^|_^) ^|
echo  ^| ^|___^| ^|_^| ^| ^|_^| ^| ^|\  ^|^| ^|  ^| ^| ^|  _  ^| ^|_^| ^|  _ ^<
echo   \____^|\___/ \____^|_^| \_^|___^| ^|_^| ^|_^| ^|_^|\___/^|_^| \_\
echo.

set "REPO_ROOT=%~dp0"
:: Trailing backslash entfernen
if "%REPO_ROOT:~-1%"=="\" set "REPO_ROOT=%REPO_ROOT:~0,-1%"

:: ============================================================
::  1. Python im PATH? (versucht python, dann py Launcher)
:: ============================================================
set "PYTHON_CMD="
where python >nul 2>&1
if not errorlevel 1 (
    REM Teste ob es echtes Python ist, nicht Microsoft Store Stub
    python -c "import sys" >nul 2>&1
    if not errorlevel 1 (
        set "PYTHON_CMD=python"
    )
)

if "%PYTHON_CMD%"=="" (
    where py >nul 2>&1
    if not errorlevel 1 (
        py -c "import sys" >nul 2>&1
        if not errorlevel 1 (
            set "PYTHON_CMD=py"
        )
    )
)

if "%PYTHON_CMD%"=="" (
    echo   Python not found.
    echo.
    :: Pruefen ob winget verfuegbar ist
    where winget >nul 2>&1
    if errorlevel 1 goto :no_winget_python
    echo   Python 3.12 can be installed automatically.
    echo.
    CHOICE /C YN /M "  Install Python 3.12 now? (Y=Yes, N=No)"
    if errorlevel 2 goto :no_winget_python
    echo.
    echo   Installing Python 3.12 via winget...
    winget install --id Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo.
        echo   [WARNING] winget installation failed.
        goto :no_winget_python
    )
    echo.
    echo   Python installed. Refreshing PATH...
    :: PATH aus Registry refreshen (delayed expansion noetig innerhalb Block)
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
    if defined USER_PATH set "PATH=!USER_PATH!;!PATH!"
    if defined SYS_PATH set "PATH=!SYS_PATH!;!PATH!"
    :: Python erneut suchen
    where python >nul 2>&1
    if not errorlevel 1 (
        python -c "import sys" >nul 2>&1
        if not errorlevel 1 set "PYTHON_CMD=python"
    )
    if "!PYTHON_CMD!"=="" (
        where py >nul 2>&1
        if not errorlevel 1 (
            py -c "import sys" >nul 2>&1
            if not errorlevel 1 set "PYTHON_CMD=py"
        )
    )
    if "!PYTHON_CMD!"=="" (
        echo.
        echo   [INFO] Python was installed but is not yet in PATH.
        echo   Please close this window and reopen it.
        echo.
        pause
        exit /b 1
    )
    goto :python_found
)

:no_winget_python
if "%PYTHON_CMD%"=="" (
    echo   [ERROR] Python not found!
    echo.
    echo   Please install Python 3.12+:
    echo   https://www.python.org/downloads/
    echo.
    echo   IMPORTANT: Check "Add Python to PATH" during installation!
    echo.
    pause
    exit /b 1
)
:python_found

:: ============================================================
::  2. Python ^>= 3.12?
:: ============================================================
%PYTHON_CMD% -c "import sys; exit(0 if sys.version_info >= (3,12) else 1)" 2>nul
if errorlevel 1 (
    echo   [ERROR] Python 3.12 or newer is required!
    echo.
    for /f "tokens=*" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo   Installed: %%v
    echo.
    echo   Please upgrade Python:
    echo   https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

:: ============================================================
::  3. Node.js im PATH?
:: ============================================================
set "HAS_NODE=0"
where node >nul 2>&1
if not errorlevel 1 set "HAS_NODE=1"

:: ============================================================
::  4. Bootstrap ausfuehren
:: ============================================================
echo   Starting bootstrap...
echo.

%PYTHON_CMD% "%REPO_ROOT%\scripts\bootstrap_windows.py" --repo-root "%REPO_ROOT%"
if errorlevel 1 (
    echo.
    echo   [ERROR] Bootstrap failed!
    echo   Please check the output above for details.
    echo.
    pause
    exit /b 1
)

:: ============================================================
::  5. UI-Modus waehlen: Vite Dev -> Pre-built -> CLI
:: ============================================================

:: Modus A: Node.js vorhanden -> Vite Dev Server
if "%HAS_NODE%"=="0" goto :check_prebuilt
if not exist "%REPO_ROOT%\ui\node_modules" (
    echo.
    echo   [INFO] node_modules not found. Trying npm install...
    cd /d "%REPO_ROOT%\ui"
    call npm install >nul 2>&1
    if errorlevel 1 goto :check_prebuilt
    cd /d "%REPO_ROOT%"
)

:: ============================================================
::  6a. Web-UI starten (Vite Dev Server)
:: ============================================================
echo.
echo   Starting Web UI (Vite Dev Server)...
echo   Open http://127.0.0.1:5173 in your browser.
echo.
cd /d "%REPO_ROOT%\ui"
call npm run dev
echo.
echo   Web UI stopped.
pause
exit /b 0

:: ============================================================
::  6b. Pre-built UI (kein Node.js, aber ui/dist/ vorhanden)
:: ============================================================
:check_prebuilt
if not exist "%REPO_ROOT%\ui\dist\index.html" goto :cli_fallback
echo.
echo   Node.js not found -- starting pre-built UI.
echo   Backend + UI at http://localhost:8741
echo.
cd /d "%REPO_ROOT%"
start "" http://localhost:8741
%PYTHON_CMD% -m jarvis --no-cli
echo.
echo   Cognithor stopped.
pause
exit /b 0

:: ============================================================
::  6c. CLI-Fallback (kein Node.js, kein Pre-built UI)
:: ============================================================
:cli_fallback
echo.
echo   Node.js not found and no pre-built UI available.
echo   Starting in CLI mode.
echo   For the Web UI, install Node.js 18+: https://nodejs.org/
echo.
echo   ============================================================
cd /d "%REPO_ROOT%"
%PYTHON_CMD% -m jarvis
echo.
echo   Cognithor stopped.
pause
