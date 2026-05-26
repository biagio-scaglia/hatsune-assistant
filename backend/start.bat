@echo off
title Hatsune Assistant Backend Runner
echo ==========================================================
echo    * Hatsune Assistant - Avvio Backend FastAPI *
echo ==========================================================
echo.

:: Sposta la directory di lavoro sul percorso dello script
cd /d "%~dp0"

:: Porta di default per il server
set SERVER_PORT=8000

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

:: 4. Controlla se la porta e' gia' occupata e libera se necessario
echo [INFO] Verifica che la porta %SERVER_PORT% sia libera...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%SERVER_PORT% " ^| findstr "LISTENING"') do (
    echo [WARN] La porta %SERVER_PORT% e' gia' occupata dal processo PID %%a.
    echo [INFO] Terminazione del processo in conflitto...
    taskkill /F /PID %%a >nul 2>&1
    if not errorlevel 1 (
        echo [OK] Processo PID %%a terminato. Porta %SERVER_PORT% liberata.
    ) else (
        echo [WARN] Impossibile terminare il processo PID %%a. Tentativo di avvio comunque...
    )
    :: Breve attesa per rilascio socket
    timeout /t 2 /nobreak >nul
)
echo.

:: 5. Avvio di Uvicorn
echo [INFO] Avvio del server Uvicorn su http://127.0.0.1:%SERVER_PORT% ...
echo [INFO] Swagger docs disponibili su http://127.0.0.1:%SERVER_PORT%/docs
echo.
uvicorn app.main:app --host 127.0.0.1 --port %SERVER_PORT% --reload
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
echo.
echo [ERRORE] Arresto del server o errore di avvio di Uvicorn.
echo [INFO] Possibili cause:
echo   - La porta %SERVER_PORT% e' ancora occupata da un altro processo
echo   - Errore nel codice Python (controlla i log sopra)
echo   - Dipendenze mancanti o incompatibili
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
