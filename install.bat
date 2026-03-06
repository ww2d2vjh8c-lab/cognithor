@echo off
setlocal enabledelayedexpansion
title Cognithor Installer
color 0F
chcp 65001 >nul 2>&1

:: ============================================================
::  COGNITHOR INSTALLER
::  Installiert Python, Ollama, venv, Abhaengigkeiten, Modelle.
::  Erkennt GPU automatisch und waehlt passenden Modus.
::
::  Nutzung:
::    install.bat              Standard-Installation (GPU auto-detect)
::    install.bat --lite       Lite-Modus erzwingen (nur qwen3:8b)
::    install.bat --full       Alles inkl. Voice + PostgreSQL
::    install.bat --uninstall  venv + Shortcuts entfernen
:: ============================================================

echo.
echo    ____  ___   ____ _   _ ___ _____ _   _  ___  ____
echo   / ___^|/ _ \ / ___^| \ ^| ^|_ _^|_   _^| ^| ^| ^|/ _ \^|  _ \
echo  ^| ^|  _^| ^| ^| ^| ^|  _^|  \^| ^|^| ^|  ^| ^| ^| ^|_^| ^| ^| ^| ^| ^|_^) ^|
echo  ^| ^|_^| ^| ^|_^| ^| ^|_^| ^| ^|\  ^|^| ^|  ^| ^| ^|  _  ^| ^|_^| ^|  _ ^<
echo   \____^|\___/ \____^|_^| \_^|___^| ^|_^| ^|_^| ^|_^|\___/^|_^| \_\
echo.
echo                    -- Installer --
echo.

set "JARVIS_HOME=%USERPROFILE%\.jarvis"
set "VENV_DIR=%JARVIS_HOME%\venv"
set "MODE=all"
set "LITE=0"
set "FORCE_LITE=0"
set "VRAM_GB=0"

:: ============================================================
::  Argumente parsen
:: ============================================================
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--lite" (
    set "MODE=all"
    set "LITE=1"
    set "FORCE_LITE=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--full" (
    set "MODE=full"
    shift
    goto :parse_args
)
if /i "%~1"=="--uninstall" (
    goto :uninstall
)
shift
goto :parse_args
:args_done

:: ============================================================
::  0. Repository erkennen oder herunterladen
:: ============================================================
echo   ----------------------------------------------------------
echo     0/10  Repository
echo   ----------------------------------------------------------

set "REPO_ROOT="

:: Pruefen ob install.bat aus einem Repo gestartet wurde
if exist "%~dp0pyproject.toml" (
    findstr /c:"cognithor" "%~dp0pyproject.toml" >nul 2>&1
    if not errorlevel 1 (
        set "REPO_ROOT=%~dp0"
        if "!REPO_ROOT:~-1!"=="\" set "REPO_ROOT=!REPO_ROOT:~0,-1!"
    )
)

:: Pruefen ob CWD ein Repo ist
if "%REPO_ROOT%"=="" (
    if exist "%CD%\pyproject.toml" (
        findstr /c:"cognithor" "%CD%\pyproject.toml" >nul 2>&1
        if not errorlevel 1 (
            set "REPO_ROOT=%CD%"
        )
    )
)

:: Pruefen ob bereits geclont
if "%REPO_ROOT%"=="" (
    if exist "%JARVIS_HOME%\cognithor\pyproject.toml" (
        set "REPO_ROOT=%JARVIS_HOME%\cognithor"
        echo   [OK] Bestehendes Repo: !REPO_ROOT!
    )
)

:: Repo herunterladen
if "%REPO_ROOT%"=="" (
    echo   Kein lokales Repository gefunden.
    echo.

    :: Versuch 1: git clone
    where git >nul 2>&1
    if not errorlevel 1 (
        echo   Cloning via git ...
        if not exist "%JARVIS_HOME%" mkdir "%JARVIS_HOME%"
        git clone https://github.com/Alex8791-cyber/cognithor.git "%JARVIS_HOME%\cognithor" --quiet 2>nul
        if not errorlevel 1 (
            set "REPO_ROOT=%JARVIS_HOME%\cognithor"
            echo   [OK] Repository geclont: !REPO_ROOT!
        ) else (
            echo   [WARNUNG] git clone fehlgeschlagen.
        )
    )

    :: Versuch 2: PowerShell ZIP-Download
    if "!REPO_ROOT!"=="" (
        echo   Lade Repository als ZIP herunter ...
        if not exist "%JARVIS_HOME%" mkdir "%JARVIS_HOME%"
        powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/Alex8791-cyber/cognithor/archive/refs/heads/main.zip' -OutFile '%JARVIS_HOME%\cognithor.zip' -UseBasicParsing; Expand-Archive -Path '%JARVIS_HOME%\cognithor.zip' -DestinationPath '%JARVIS_HOME%' -Force; if (Test-Path '%JARVIS_HOME%\cognithor-main') { if (Test-Path '%JARVIS_HOME%\cognithor') { Remove-Item '%JARVIS_HOME%\cognithor' -Recurse -Force }; Rename-Item '%JARVIS_HOME%\cognithor-main' 'cognithor' }; Remove-Item '%JARVIS_HOME%\cognithor.zip' -Force; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }" 2>nul
        if not errorlevel 1 (
            if exist "%JARVIS_HOME%\cognithor\pyproject.toml" (
                set "REPO_ROOT=%JARVIS_HOME%\cognithor"
                echo   [OK] Repository heruntergeladen: !REPO_ROOT!
            )
        )
    )

    if "!REPO_ROOT!"=="" (
        echo   [FEHLER] Repository konnte nicht heruntergeladen werden!
        echo.
        echo   Bitte manuell herunterladen:
        echo   https://github.com/Alex8791-cyber/cognithor/archive/refs/heads/main.zip
        echo   Entpacken und install.bat aus dem Ordner starten.
        echo.
        pause
        exit /b 1
    )
)

if "%REPO_ROOT%"=="" (
    echo   [FEHLER] Kein Repository gefunden!
    pause
    exit /b 1
)

echo   [OK] Repo: %REPO_ROOT%
echo.

:: ============================================================
::  1. Python pruefen / installieren
:: ============================================================
echo   ----------------------------------------------------------
echo     1/10  Python pruefen
echo   ----------------------------------------------------------

set "PYTHON_CMD="

:: Zuerst existierende Python-Installation suchen
where python >nul 2>&1
if not errorlevel 1 (
    python -c "import sys" >nul 2>&1
    if not errorlevel 1 (
        python -c "import sys; exit(0 if sys.version_info >= (3,12) else 1)" 2>nul
        if not errorlevel 1 (
            set "PYTHON_CMD=python"
        )
    )
)

if "%PYTHON_CMD%"=="" (
    where py >nul 2>&1
    if not errorlevel 1 (
        py -c "import sys; exit(0 if sys.version_info >= (3,12) else 1)" 2>nul
        if not errorlevel 1 (
            set "PYTHON_CMD=py"
        )
    )
)

:: Python nicht gefunden oder zu alt -> automatisch installieren
if "%PYTHON_CMD%"=="" (
    echo   Python 3.12+ nicht gefunden. Versuche automatische Installation...
    echo.

    :: Versuch 1: winget
    where winget >nul 2>&1
    if not errorlevel 1 (
        echo   Installiere Python 3.12 via winget ...
        echo   (Das kann 1-2 Minuten dauern.)
        winget install --id Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements --silent 2>nul
        if not errorlevel 1 (
            echo   [OK] Python via winget installiert
            echo.
            echo   WICHTIG: PATH wird aktualisiert...
            :: PATH neu laden
            for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"
            for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
            set "PATH=!SYS_PATH!;!USER_PATH!"

            :: Nochmal suchen
            where python >nul 2>&1
            if not errorlevel 1 (
                python -c "import sys; exit(0 if sys.version_info >= (3,12) else 1)" 2>nul
                if not errorlevel 1 (
                    set "PYTHON_CMD=python"
                )
            )
            if "!PYTHON_CMD!"=="" (
                :: Typische winget-Installationspfade pruefen
                for %%p in (
                    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
                    "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
                    "%ProgramFiles%\Python312\python.exe"
                    "%ProgramFiles%\Python313\python.exe"
                ) do (
                    if exist %%p (
                        set "PYTHON_CMD=%%~p"
                        goto :python_found
                    )
                )
            )
        ) else (
            echo   [WARNUNG] winget-Installation fehlgeschlagen.
        )
    )
)

:: Immer noch kein Python?
if "%PYTHON_CMD%"=="" (
    echo.
    echo   [FEHLER] Python 3.12+ konnte nicht installiert werden!
    echo.
    echo   Bitte manuell installieren:
    echo   https://www.python.org/downloads/
    echo.
    echo   WICHTIG: Bei der Installation "Add Python to PATH" ankreuzen!
    echo   Danach dieses Script erneut starten.
    echo.
    pause
    exit /b 1
)

:python_found
for /f "tokens=*" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo   [OK] %%v
echo.

:: ============================================================
::  2. GPU-Erkennung (Auto-Lite)
:: ============================================================
echo   ----------------------------------------------------------
echo     2/10  GPU-Erkennung
echo   ----------------------------------------------------------

set "GPU_NAME=Keine NVIDIA GPU erkannt"
set "VRAM_GB=0"

where nvidia-smi >nul 2>&1
if not errorlevel 1 (
    :: GPU-Name und VRAM auslesen
    for /f "tokens=1,2 delims=," %%a in ('nvidia-smi --query-gpu^=name^,memory.total --format^=csv^,noheader^,nounits 2^>nul') do (
        set "GPU_NAME=%%a"
        set /a "VRAM_MB=%%b" 2>nul
        if !VRAM_MB! gtr 0 (
            set /a "VRAM_GB=!VRAM_MB! / 1024"
        )
    )
)

if %VRAM_GB% gtr 0 (
    echo   [OK] GPU: %GPU_NAME% ^(%VRAM_GB% GB VRAM^)
) else (
    echo   [INFO] Keine NVIDIA GPU erkannt oder nvidia-smi fehlt.
    echo   CPU-Modus -- Lite wird empfohlen.
    if "%FORCE_LITE%"=="0" (
        set "LITE=1"
        echo   [INFO] Lite-Modus automatisch aktiviert.
    )
)

:: Auto-Lite bei wenig VRAM (unter 12 GB -> kein Platz fuer qwen3:32b)
if %VRAM_GB% gtr 0 if %VRAM_GB% lss 12 (
    if "%FORCE_LITE%"=="0" (
        set "LITE=1"
        echo   [INFO] VRAM unter 12 GB -- Lite-Modus automatisch aktiviert.
        echo   (qwen3:8b statt qwen3:32b, spart ~14 GB VRAM)
    )
)

if %VRAM_GB% geq 12 (
    if "%FORCE_LITE%"=="0" (
        echo   [OK] Genug VRAM fuer Standard-Modus ^(qwen3:32b^)
    )
)

:: Modus-Anzeige
echo.
if "%LITE%"=="1" (
    echo   Modus: LITE ^(6 GB VRAM^)
) else if "%MODE%"=="full" (
    echo   Modus: FULL ^(alle Features inkl. Voice^)
) else (
    echo   Modus: STANDARD ^(empfohlen^)
)
echo   Home:  %JARVIS_HOME%
echo.

:: ============================================================
::  3. Admin-Warnung
:: ============================================================
echo %REPO_ROOT% | findstr /i "Program Files" >nul 2>&1
if not errorlevel 1 (
    echo   [WARNUNG] Repo liegt in Program Files.
    echo   Empfehlung: In %USERPROFILE%\cognithor oder C:\cognithor installieren.
    echo.
)

:: ============================================================
::  4. venv erstellen / aktivieren
:: ============================================================
echo   ----------------------------------------------------------
echo     3/10  Virtual Environment
echo   ----------------------------------------------------------

if not exist "%JARVIS_HOME%" mkdir "%JARVIS_HOME%"

if exist "%VENV_DIR%\Scripts\activate.bat" (
    echo   [OK] venv bereits vorhanden: %VENV_DIR%
    call "%VENV_DIR%\Scripts\activate.bat"
) else (
    echo   Erstelle venv in %VENV_DIR% ...
    %PYTHON_CMD% -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo   [FEHLER] venv konnte nicht erstellt werden!
        echo   Versuche: %PYTHON_CMD% -m pip install virtualenv
        pause
        exit /b 1
    )
    call "%VENV_DIR%\Scripts\activate.bat"
    python -m pip install --upgrade pip setuptools wheel --quiet >nul 2>&1
    echo   [OK] venv erstellt und aktiviert
)
echo.

:: ============================================================
::  5. pip install (mit sichtbarem Fortschritt)
:: ============================================================
echo   ----------------------------------------------------------
echo     4/10  Python-Abhaengigkeiten installieren
echo   ----------------------------------------------------------

echo   Installiere cognithor[%MODE%] ...
echo   (Das kann beim ersten Mal 3-5 Minuten dauern. Bitte nicht schliessen!)
echo.

:: Fortschritt: pip ohne --quiet, aber mit --progress-bar on
python -m pip install -e "%REPO_ROOT%[%MODE%]" --disable-pip-version-check --progress-bar on
if errorlevel 1 (
    echo.
    echo   [FEHLER] pip install fehlgeschlagen!
    echo   Versuche manuell:
    echo     cd "%REPO_ROOT%"
    echo     pip install -e ".[all]"
    echo.
    pause
    exit /b 1
)

echo.
echo   [OK] Abhaengigkeiten installiert
echo.

:: ============================================================
::  6. Ollama pruefen / installieren
:: ============================================================
echo   ----------------------------------------------------------
echo     5/10  Ollama pruefen
echo   ----------------------------------------------------------

set "OLLAMA_CMD="
where ollama >nul 2>&1
if not errorlevel 1 (
    set "OLLAMA_CMD=ollama"
    goto :ollama_found
)

:: Standard-Pfade pruefen
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    goto :ollama_found
)
if exist "%ProgramFiles%\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%ProgramFiles%\Ollama\ollama.exe"
    goto :ollama_found
)

:: Ollama nicht gefunden -> automatisch installieren
echo   Ollama nicht gefunden. Versuche automatische Installation...
echo.

:: Versuch 1: winget
where winget >nul 2>&1
if not errorlevel 1 (
    echo   Installiere Ollama via winget ...
    winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements --silent 2>nul
    if not errorlevel 1 (
        echo   [OK] Ollama via winget installiert

        :: PATH neu laden
        for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"
        for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
        set "PATH=!SYS_PATH!;!USER_PATH!"

        :: Erneut suchen
        where ollama >nul 2>&1
        if not errorlevel 1 (
            set "OLLAMA_CMD=ollama"
            goto :ollama_found
        )
        if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
            set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
            goto :ollama_found
        )
    ) else (
        echo   [WARNUNG] winget-Installation fehlgeschlagen.
    )
)

:: Immer noch kein Ollama
if "%OLLAMA_CMD%"=="" (
    echo.
    echo   [WARNUNG] Ollama konnte nicht automatisch installiert werden.
    echo.
    echo   Bitte manuell installieren: https://ollama.com/download
    echo   Nach der Installation dieses Script erneut starten.
    echo.
    goto :skip_models
)

:ollama_found
echo   [OK] Ollama gefunden: %OLLAMA_CMD%

:: Pruefen ob Ollama-Server laeuft
python -c "import urllib.request; urllib.request.urlopen('http://localhost:11434/api/tags', timeout=3)" >nul 2>&1
if errorlevel 1 (
    echo   Ollama-Server wird gestartet...
    start "" /b "%OLLAMA_CMD%" serve >nul 2>&1
    set "WAIT_COUNT=0"
    :wait_ollama
    if !WAIT_COUNT! geq 30 (
        echo   [WARNUNG] Ollama-Server antwortet nicht.
        goto :skip_models
    )
    timeout /t 1 /nobreak >nul 2>&1
    python -c "import urllib.request; urllib.request.urlopen('http://localhost:11434/api/tags', timeout=2)" >nul 2>&1
    if errorlevel 1 (
        set /a WAIT_COUNT+=1
        goto :wait_ollama
    )
    echo   [OK] Ollama-Server gestartet
) else (
    echo   [OK] Ollama-Server laeuft bereits
)
echo.

:: ============================================================
::  7. Modelle pruefen / pullen
:: ============================================================
echo   ----------------------------------------------------------
echo     6/10  Ollama-Modelle
echo   ----------------------------------------------------------

if "%LITE%"=="1" (
    call :ensure_model qwen3:8b
    call :ensure_model nomic-embed-text
) else (
    call :ensure_model qwen3:8b
    call :ensure_model qwen3:32b
    call :ensure_model nomic-embed-text
)
echo.

:skip_models

:: ============================================================
::  8. Verzeichnisstruktur
:: ============================================================
echo   ----------------------------------------------------------
echo     7/10  Verzeichnisstruktur initialisieren
echo   ----------------------------------------------------------

if "%LITE%"=="1" (
    python -m jarvis --lite --init-only >nul 2>&1
) else (
    python -m jarvis --init-only >nul 2>&1
)
if errorlevel 1 (
    if not exist "%JARVIS_HOME%\memory" mkdir "%JARVIS_HOME%\memory"
    if not exist "%JARVIS_HOME%\logs" mkdir "%JARVIS_HOME%\logs"
    if not exist "%JARVIS_HOME%\cache" mkdir "%JARVIS_HOME%\cache"
    echo   [OK] Verzeichnisse manuell erstellt
) else (
    echo   [OK] Verzeichnisstruktur initialisiert
)
echo.

:: ============================================================
::  9. Smoke-Test
:: ============================================================
echo   ----------------------------------------------------------
echo     8/10  Smoke-Test
echo   ----------------------------------------------------------

python -c "import jarvis; print(f'  [OK] jarvis v{jarvis.__version__}')"
if errorlevel 1 (
    echo   [FEHLER] Import-Test fehlgeschlagen!
    echo   Versuche: pip install -e "%REPO_ROOT%[all]"
    pause
    exit /b 1
)
echo.

:: ============================================================
::  10. Desktop-Shortcut
:: ============================================================
echo   ----------------------------------------------------------
echo     9/10  Desktop-Verknuepfung
echo   ----------------------------------------------------------

set "BAT_PATH=%REPO_ROOT%\start_cognithor.bat"
if not exist "%BAT_PATH%" (
    echo   [INFO] start_cognithor.bat nicht gefunden -- Shortcut uebersprungen
    goto :skip_shortcut
)

set "DESKTOP_PATH="
if exist "%USERPROFILE%\Desktop" set "DESKTOP_PATH=%USERPROFILE%\Desktop"
if "%DESKTOP_PATH%"=="" if exist "%USERPROFILE%\OneDrive\Desktop" set "DESKTOP_PATH=%USERPROFILE%\OneDrive\Desktop"
if "%DESKTOP_PATH%"=="" if exist "%USERPROFILE%\OneDrive\Schreibtisch" set "DESKTOP_PATH=%USERPROFILE%\OneDrive\Schreibtisch"
if "%DESKTOP_PATH%"=="" if exist "%USERPROFILE%\Schreibtisch" set "DESKTOP_PATH=%USERPROFILE%\Schreibtisch"

if "%DESKTOP_PATH%"=="" (
    echo   [INFO] Desktop-Ordner nicht gefunden -- Shortcut uebersprungen
    goto :skip_shortcut
)

if exist "%DESKTOP_PATH%\Cognithor.lnk" (
    echo   [OK] Desktop-Verknuepfung bereits vorhanden
    goto :skip_shortcut
)

powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%DESKTOP_PATH%\Cognithor.lnk'); $sc.TargetPath = '%BAT_PATH%'; $sc.WorkingDirectory = '%REPO_ROOT%'; $sc.Description = 'Cognithor Control Center starten'; $sc.WindowStyle = 1; $sc.Save()" >nul 2>&1
if errorlevel 1 (
    echo   [WARNUNG] Desktop-Verknuepfung konnte nicht erstellt werden
) else (
    echo   [OK] Desktop-Verknuepfung erstellt
)

:skip_shortcut
echo.

:: ============================================================
::  Zusammenfassung
:: ============================================================
echo   ----------------------------------------------------------
echo     10/10  Zusammenfassung
echo   ----------------------------------------------------------
echo.
echo   [OK] Cognithor erfolgreich installiert!
echo.
echo   Starten:
echo     start_cognithor.bat          Web-UI (empfohlen)
echo     python -m jarvis             CLI-Modus
if "%LITE%"=="1" (
    echo     python -m jarvis --lite     Lite-Modus ^(6 GB VRAM^)
)
echo.
if %VRAM_GB% gtr 0 (
    echo   Erkannte GPU: %GPU_NAME% ^(%VRAM_GB% GB VRAM^)
)
if "%LITE%"=="1" (
    echo   Modell-Modus: LITE ^(qwen3:8b, ~6 GB VRAM^)
) else (
    echo   Modell-Modus: STANDARD ^(qwen3:32b + qwen3:8b^)
)
echo.
echo   Verzeichnisse:
echo     %JARVIS_HOME%\              Home
echo     %JARVIS_HOME%\config.yaml   Konfiguration
echo     %JARVIS_HOME%\memory\       Erinnerungen
echo     %JARVIS_HOME%\logs\         Logs
echo.

pause
exit /b 0

:: ============================================================
::  Hilfsfunktionen
:: ============================================================

:ensure_model
set "MODEL_NAME=%~1"
python -c "import urllib.request, json; data=json.loads(urllib.request.urlopen('http://localhost:11434/api/tags',timeout=5).read()); models=[m['name'] for m in data.get('models',[])]; exit(0 if any('%MODEL_NAME%'.split(':')[0] in m for m in models) else 1)" >nul 2>&1
if not errorlevel 1 (
    echo   [OK] Modell vorhanden: %MODEL_NAME%
    goto :eof
)
echo   Lade Modell: %MODEL_NAME% (kann einige Minuten dauern)...
"%OLLAMA_CMD%" pull %MODEL_NAME%
if errorlevel 1 (
    echo   [WARNUNG] Download fehlgeschlagen: %MODEL_NAME%
    echo   Manuell: ollama pull %MODEL_NAME%
) else (
    echo   [OK] Modell installiert: %MODEL_NAME%
)
goto :eof

:: ============================================================
::  Deinstallation
:: ============================================================
:uninstall
echo.
echo   Deinstallation von Cognithor
echo   ============================
echo.
echo   Dies entfernt:
echo     - Virtual Environment (%VENV_DIR%)
echo     - Desktop-Verknuepfung
echo.
echo   NICHT entfernt:
echo     - Deine Daten in %JARVIS_HOME% (memory, logs, config)
echo     - Ollama und Modelle
echo.
set /p "CONFIRM=Fortfahren? [j/N] "
if /i not "%CONFIRM%"=="j" (
    echo   Abgebrochen.
    pause
    exit /b 0
)

if exist "%VENV_DIR%" (
    rmdir /s /q "%VENV_DIR%"
    echo   [OK] venv entfernt
) else (
    echo   [INFO] Kein venv gefunden
)

set "DESKTOP_PATH="
if exist "%USERPROFILE%\Desktop\Cognithor.lnk" set "DESKTOP_PATH=%USERPROFILE%\Desktop"
if "%DESKTOP_PATH%"=="" if exist "%USERPROFILE%\OneDrive\Desktop\Cognithor.lnk" set "DESKTOP_PATH=%USERPROFILE%\OneDrive\Desktop"
if "%DESKTOP_PATH%"=="" if exist "%USERPROFILE%\OneDrive\Schreibtisch\Cognithor.lnk" set "DESKTOP_PATH=%USERPROFILE%\OneDrive\Schreibtisch"
if "%DESKTOP_PATH%"=="" if exist "%USERPROFILE%\Schreibtisch\Cognithor.lnk" set "DESKTOP_PATH=%USERPROFILE%\Schreibtisch"

if not "%DESKTOP_PATH%"=="" (
    del "%DESKTOP_PATH%\Cognithor.lnk" >nul 2>&1
    echo   [OK] Desktop-Verknuepfung entfernt
)

echo.
echo   [OK] Deinstallation abgeschlossen.
echo   Daten in %JARVIS_HOME% wurden NICHT geloescht.
echo   Zum vollstaendigen Entfernen: rmdir /s /q "%JARVIS_HOME%"
echo.
pause
exit /b 0
