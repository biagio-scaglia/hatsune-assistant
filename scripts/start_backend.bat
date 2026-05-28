@echo off
title Hatsune Assistant - Backend Server
echo ==========================================================
echo    * Hatsune Assistant - Avvio Server FastAPI *
echo ==========================================================
echo.

:: Imposta la porta di ascolto
set SERVER_PORT=8000

:: Sposta la directory su backend/
cd /d "%~dp0\..\backend"

:: 1. Verifica ed attiva l'ambiente virtuale
if not exist "venv" (
    echo [ERRORE] Ambiente virtuale non trovato in backend/venv.
    echo [INFO] Esegui prima "scripts\bootstrap.bat" per configurare l'ambiente.
    pause
    exit /b 1
)

echo [INFO] Attivazione ambiente virtuale...
call venv\Scripts\activate
if errorlevel 1 (
    echo [ERRORE] Impossibile attivare il venv.
    pause
    exit /b 1
)

:: 2. Verifica se la porta e' occupata
echo [INFO] Verifica porta %SERVER_PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%SERVER_PORT% " ^| findstr "LISTENING"') do (
    echo [WARN] La porta %SERVER_PORT% e' occupata dal processo PID %%a.
    echo [INFO] Terminazione del processo in conflitto...
    taskkill /F /PID %%a >nul 2>&1
    if not errorlevel 1 (
        echo [OK] Processo PID %%a terminato.
    )
    timeout /t 2 /nobreak >nul
)

:: 3. Esegui migrazioni database
echo [INFO] Esecuzione migrazioni database (Alembic)...
call alembic upgrade head
if errorlevel 1 (
    echo [WARN] Errore durante l'esecuzione di Alembic. Tentativo di avvio del server comunque...
)
echo.

:: 4. Avvio Uvicorn
echo [INFO] Avvio server Uvicorn su http://127.0.0.1:%SERVER_PORT%...
echo [INFO] Swagger docs: http://127.0.0.1:%SERVER_PORT%/docs
echo.
uvicorn app.main:app --host 127.0.0.1 --port %SERVER_PORT% --reload
if errorlevel 1 (
    echo [ERRORE] Errore di arresto o crash del server FastAPI.
    pause
    exit /b 1
)
