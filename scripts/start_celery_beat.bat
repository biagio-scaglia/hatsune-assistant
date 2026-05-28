@echo off
title Hatsune Assistant - Celery Beat
echo ==========================================================
echo    * Hatsune Assistant - Avvio Celery Beat Scheduler *
echo ==========================================================
echo.

:: Sposta la directory su backend/
cd /d "%~dp0\..\backend"

:: Verifica ed attiva l'ambiente virtuale
if not exist "venv" (
    echo [ERRORE] Ambiente virtuale non trovato in backend/venv.
    echo [INFO] Esegui prima "scripts\bootstrap.bat".
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

:: Avvio Celery Beat
echo [INFO] Avvio Celery Beat Scheduler...
celery -A app.celery_app beat --loglevel=info
if errorlevel 1 (
    echo [ERRORE] Errore o arresto del Celery Beat.
    pause
    exit /b 1
)
