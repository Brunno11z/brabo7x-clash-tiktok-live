@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Servidor Painel TikTok LIVE

echo ============================================================
echo         BRABO7X - INICIANDO PAINEL WEB STUDIO
echo ============================================================
echo.

:: Liberar porta 8765 se estiver presa por processo anterior
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":8765" ^| findstr "LISTENING"') do (
    echo [AVISO] Liberando porta 8765 em uso pelo processo PID %%a...
    taskkill /f /pid %%a >nul 2>nul
)

set "PY_CMD="
where py >nul 2>nul
if %errorlevel%==0 (
    set "PY_CMD=py"
) else (
    where python >nul 2>nul
    if %errorlevel%==0 set "PY_CMD=python"
)

if not defined PY_CMD (
    for /d %%d in ("%LOCALAPPDATA%\Programs\Python\Python3*" "%ProgramFiles%\Python3*") do (
        if exist "%%d\python.exe" set "PY_CMD=%%d\python.exe"
    )
)

if not exist "brabo7x_live\.venv\Scripts\python.exe" (
    echo [BRABO7X] Criando ambiente Python local...
    if not defined PY_CMD (
        echo [ERRO] Python nao encontrado. Execute o "INSTALAR_TUDO_AUTOMATICO.bat".
        pause
        exit /b 1
    )
    !PY_CMD! -m venv "brabo7x_live\.venv"
)

set "VPY=brabo7x_live\.venv\Scripts\python.exe"
if not exist "brabo7x_live\.deps_ok" (
    echo [BRABO7X] Instalando dependencias...
    "%VPY%" -m pip install --upgrade pip
    "%VPY%" -m pip install -r "brabo7x_live\requirements.txt"
    if errorlevel 1 goto :dep_error
    echo ok>"brabo7x_live\.deps_ok"
)

echo.
echo [OK] Painel iniciando! Abrindo navegador em http://127.0.0.1:8765 ...
start "" "http://127.0.0.1:8765"

"%VPY%" "brabo7x_live\app.py"
if errorlevel 1 (
    echo.
    echo [ERRO] O servidor do painel encerrou com falha.
    pause
)
exit /b 0

:dep_error
echo.
echo [ERRO] Falha ao instalar dependencias Python.
pause
exit /b 1
