@echo off
title Hatsune Assistant - Celery Worker
echo ==========================================================
echo    * Hatsune Assistant - Avvio Celery Worker *
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

:: Avvio Celery Worker
echo [INFO] Avvio Celery Worker (Pool: solo per compatibilita' Windows)...
celery -A app.celery_app worker --loglevel=info -P solo
if errorlevel 1 (
    echo [ERRORE] Errore o arresto del Celery Worker.
    pause
    exit /b 1
)
