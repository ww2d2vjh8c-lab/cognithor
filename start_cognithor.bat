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
echo  ^| ^|  _^| ^| ^| ^| ^|  _^|  \^| ^|^| ^|  ^| ^| ^| ^|_^| ^| ^| ^| ^| ^|_^) ^|
echo  ^| ^|_^| ^| ^|_^| ^| ^|_^| ^| ^|\  ^|^| ^|  ^| ^| ^|  _  ^| ^|_^| ^|  _ ^<
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
    echo   [FEHLER] Python wurde nicht gefunden!
    echo.
    echo   Bitte installiere Python 3.12+:
    echo   https://www.python.org/downloads/
    echo.
    echo   WICHTIG: Bei der Installation "Add Python to PATH" ankreuzen!
    echo.
    pause
    exit /b 1
)

:: ============================================================
::  2. Python ^>= 3.12?
:: ============================================================
%PYTHON_CMD% -c "import sys; exit(0 if sys.version_info >= (3,12) else 1)" 2>nul
if errorlevel 1 (
    echo   [FEHLER] Python 3.12 oder neuer wird benoetigt!
    echo.
    for /f "tokens=*" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo   Installiert: %%v
    echo.
    echo   Bitte upgrade Python:
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
echo   Bootstrap wird gestartet...
echo.

%PYTHON_CMD% "%REPO_ROOT%\scripts\bootstrap_windows.py" --repo-root "%REPO_ROOT%"
if errorlevel 1 (
    echo.
    echo   [FEHLER] Bootstrap fehlgeschlagen!
    echo   Bitte pruefe die Ausgabe oben fuer Details.
    echo.
    pause
    exit /b 1
)

:: ============================================================
::  5. Node.js vorhanden? -> Web-UI, sonst CLI-Fallback
:: ============================================================
if "%HAS_NODE%"=="0" goto :cli_fallback
if not exist "%REPO_ROOT%\ui\node_modules" (
    echo.
    echo   [WARNUNG] node_modules nicht gefunden.
    echo   Versuche npm install...
    cd /d "%REPO_ROOT%\ui"
    call npm install >nul 2>&1
    if errorlevel 1 goto :cli_fallback
    cd /d "%REPO_ROOT%"
)

:: ============================================================
::  6. Web-UI starten
:: ============================================================
echo.
echo   Web-UI wird gestartet...
echo   Oeffne http://localhost:5173 im Browser.
echo.
cd /d "%REPO_ROOT%\ui"
call npm run dev
echo.
echo   Web-UI wurde beendet.
pause
exit /b 0

:: ============================================================
::  CLI-Fallback (kein Node.js oder npm install fehlgeschlagen)
:: ============================================================
:cli_fallback
echo.
echo   Node.js nicht gefunden -- starte im CLI-Modus.
echo   Fuer die Web-UI installiere Node.js 18+: https://nodejs.org/
echo.
echo   ============================================================
cd /d "%REPO_ROOT%"
%PYTHON_CMD% -m jarvis
echo.
echo   Cognithor wurde beendet.
pause
