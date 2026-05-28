@echo off
title Hatsune Assistant - Cleanup Strumenti
echo ==========================================================
echo    * Hatsune Assistant - Pulizia Ambiente e Cache *
echo ==========================================================
echo.

:: Sposta la directory alla radice del progetto
cd /d "%~dp0\.."

echo [INFO] Inizio rimozione file temporanei e cache...
echo.

:: 1. Pulizia file audio generati dal backend
echo [INFO] Eliminazione file audio generati (WAV)...
if exist "backend\app\static\generated_audio" (
    powershell -Command "Remove-Item -Path backend/app/static/generated_audio/*.wav -Force -ErrorAction SilentlyContinue"
    echo [OK] Cartella audio ripulita.
)
echo.

:: 2. Pulizia cache Python (__pycache__, *.pyc, celerybeat-schedule)
echo [INFO] Eliminazione file di cache Python e database temporanei di Celery...
powershell -Command "Get-ChildItem -Path backend -Recurse -Directory -Filter '__pycache__' | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue"
powershell -Command "Get-ChildItem -Path backend -Recurse -Filter '*.pyc' | Remove-Item -Force -ErrorAction SilentlyContinue"
if exist "backend\celerybeat-schedule" (
    del /f /q backend\celerybeat-schedule
    echo [OK] File celerybeat-schedule rimosso.
)
echo [OK] Cache Python rimossa.
echo.

:: 3. Pulizia opzionale delle cartelle di build Flutter
echo [INFO] Eliminazione file temporanei di build Flutter (.dart_tool, build)...
if exist "app\flutter_app" (
    powershell -Command "Remove-Item -Path app/flutter_app/.dart_tool, app/flutter_app/build, app/flutter_app/.flutter-plugins-dependencies -Recurse -Force -ErrorAction SilentlyContinue"
    echo [OK] Cartelle di build Flutter rimosse.
)
echo.

echo ==========================================================
echo    [OK] PULIZIA COMPLETATA CON SUCCESSO!
echo ==========================================================
pause
exit /b 0
