@echo off
title Hatsune Assistant - Bootstrap Sviluppo
echo ==========================================================
echo    * Hatsune Assistant - Inizializzazione Sviluppo *
echo ==========================================================
echo.

:: Sposta la directory di lavoro sulla radice del progetto
cd /d "%~dp0\.."

:: 1. Backend: Inizializzazione Ambiente Virtuale Python
echo [INFO] Verifica ambiente virtuale Python in backend/venv...
if exist "backend\venv" (
    echo [OK] Ambiente virtuale esistente.
) else (
    echo [INFO] Ambiente virtuale non trovato. Creazione in corso...
    python -m venv backend\venv
    if errorlevel 1 goto python_error
    echo [OK] Ambiente virtuale creato.
)
echo.

:: 2. Backend: Installazione Dipendenze Python
echo [INFO] Installazione/Verifica dipendenze backend...
call backend\venv\Scripts\activate
if errorlevel 1 goto activate_error
pip install -r backend\requirements.txt
if errorlevel 1 goto pip_error
echo [OK] Dipendenze backend verificate.
echo.

:: 3. Frontend: Scaricamento Pacchetti Flutter
echo [INFO] Scaricamento dipendenze frontend Flutter...
cd app\flutter_app
call flutter pub get
if errorlevel 1 goto flutter_error
echo [OK] Dipendenze Flutter scaricate con successo.
echo.

echo ==========================================================
echo    [OK] INIZIALIZZAZIONE COMPLETATA CON SUCCESSO!
echo    Usa gli script in "scripts/" per avviare i servizi.
echo ==========================================================
pause
exit /b 0

:python_error
echo [ERRORE] Impossibile creare l'ambiente virtuale. Assicurati che Python sia installato e nel PATH.
pause
exit /b 1

:activate_error
echo [ERRORE] Impossibile attivare l'ambiente virtuale venv.
pause
exit /b 1

:pip_error
echo [ERRORE] Errore durante l'installazione delle dipendenze Python via pip.
pause
exit /b 1

:flutter_error
echo [ERRORE] Errore durante l'esecuzione di "flutter pub get". Assicurati che Flutter SDK sia nel PATH.
pause
exit /b 1
