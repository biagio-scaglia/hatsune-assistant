@echo off
title Hatsune Assistant Backend Runner
echo ==========================================================
echo    * Hatsune Assistant - Avvio Backend FastAPI *
echo ==========================================================
echo.

:: Sposta la directory di lavoro sul percorso dello script
cd /d "%~dp0"

:: 1. Verifica la presenza del venv
if exist "venv" goto venv_exists

echo [INFO] Ambiente virtuale "venv" non trovato. Creazione in corso...
python -m venv venv
if errorlevel 1 goto venv_error
echo [OK] Ambiente virtuale creato.
echo.

:venv_exists
:: 2. Attivazione del venv
echo [INFO] Attivazione dell'ambiente virtuale venv...
call venv\Scripts\activate
if errorlevel 1 goto activate_error
echo [OK] Ambiente venv attivo.
echo.

:: 3. Verifica ed installazione dipendenze nel venv
echo [INFO] Installazione/Verifica delle dipendenze core nel venv...
pip install -r requirements.txt
if errorlevel 1 goto pip_error
echo [OK] Dipendenze core verificate.
echo.

:: 3b. Nota sulle dipendenze TTS (Piper)
echo [INFO] Servizio TTS impostato su Piper (C++ standalone locale).
echo [INFO] Il server si avviera' immediatamente e scarichera' i binari e i modelli in background.
echo [INFO] Fino al termine del download, le richieste TTS useranno la MODALITA' FALLBACK (bip sinusoidale).
echo.

:: 4. Avvio di Uvicorn
echo [INFO] Avvio del server Uvicorn su http://127.0.0.1:8000 ...
echo [INFO] Swagger docs disponibili su http://127.0.0.1:8000/docs
echo.
uvicorn app.main:app --reload
if errorlevel 1 goto uvicorn_error

goto end

:venv_error
echo [ERRORE] Impossibile creare il venv. Verifica che Python sia installato e configurato nel PATH di Windows.
goto error

:activate_error
echo [ERRORE] Impossibile attivare il venv.
goto error

:pip_error
echo [ERRORE] Impossibile installare le dipendenze core.
goto error

:uvicorn_error
echo [ERRORE] Arresto del server o errore di avvio di Uvicorn.
goto error

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
