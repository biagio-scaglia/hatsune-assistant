@echo off
title Hatsune Assistant Backend Runner
echo ==========================================================
echo    🌟 Hatsune Assistant - Avvio Backend FastAPI 🌟
echo ==========================================================
echo.

:: Imposta la directory di lavoro sul percorso dello script
cd /d "%~dp0"

:: 1. Verifica la presenza del venv
if not exist "venv" (
    echo [INFO] Ambiente virtuale "venv" non trovato. Creazione in corso...
    python -m venv venv
    if errorlevel 1 (
        echo [ERRORE] Impossibile creare il venv. Verifica che Python sia installato e presente nelle variabili d'ambiente (PATH).
        goto error
    )
    echo [OK] Ambiente virtuale creato.
    echo.
)

:: 2. Attivazione del venv
echo [INFO] Attivazione dell'ambiente virtuale venv...
call venv\Scripts\activate
if errorlevel 1 (
    echo [ERRORE] Impossibile attivare il venv.
    goto error
)
echo [OK] Ambiente venv attivo.
echo.

:: 3. Verifica ed installazione dipendenze nel venv
echo [INFO] Installazione/Verifica delle dipendenze nel venv...
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERRORE] Impossibile installare le dipendenze.
    goto error
)
echo [OK] Dipendenze verificate.
echo.

:: 4. Avvio di Uvicorn
echo [INFO] Avvio del server Uvicorn su http://127.0.0.1:8000 ...
echo [INFO] Swagger docs disponibili su http://127.0.0.1:8000/docs
echo.
uvicorn app.main:app --reload
if errorlevel 1 (
    echo [ERRORE] Arresto del server o errore di avvio.
    goto error
)

goto end

:error
echo.
echo ==========================================================
echo [ERRORE] Il processo e' fallito. Controlla i messaggi sopra.
echo ==========================================================
pause
exit /b 1

:end
pause
exit /b 0
