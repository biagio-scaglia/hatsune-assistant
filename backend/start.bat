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

:: 3b. Tentativo installazione dipendenze TTS (Kokoro)
echo [INFO] Tentativo di installazione dipendenze TTS (Kokoro/audio)...
echo [INFO] Nota: Su Python 3.14 o senza compilatore C++, l'installazione di spacy/numpy potrebbe fallire.
echo [INFO] Se fallisce, il backend si avviera' comunque in MODALITA' FALLBACK.
pip install -r requirements-tts.txt
if errorlevel 1 (
    echo.
    echo ==========================================================
    echo [WARNING] Installazione dipendenze Kokoro TTS fallita.
    echo [WARNING] Il backend funzionera' in MODALITA' FALLBACK (solo testo + bip audio).
    echo ==========================================================
    echo.
) else (
    echo [OK] Dipendenze TTS verificate con successo.
    echo.
)

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
