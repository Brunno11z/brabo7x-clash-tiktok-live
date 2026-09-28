@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Servidor Painel TikTok LIVE

set "PY_CMD="
where py >nul 2>nul
if %errorlevel%==0 (
    set "PY_CMD=py -3.12"
) else (
    where python >nul 2>nul
    if %errorlevel%==0 set "PY_CMD=python"
)

if not defined PY_CMD (
    for /d %%d in ("%LOCALAPPDATA%\Programs\Python\Python312*" "%ProgramFiles%\Python312*") do (
        if exist "%%d\python.exe" set "PY_CMD=%%d\python.exe"
    )
)

if not exist "brabo7x_live\.venv\Scripts\python.exe" (
    echo [BRABO7X] Criando ambiente Python local...
    if not defined PY_CMD (
        echo [ERRO] Python 3.12 nao encontrado.
        echo Execute o "INSTALAR_TUDO_AUTOMATICO.bat" para instalar o Python automaticamente.
        pause
        exit /b 1
    )
    !PY_CMD! -m venv "brabo7x_live\.venv"
)

set "VPY=brabo7x_live\.venv\Scripts\python.exe"
if not exist "brabo7x_live\.deps_ok" (
    echo [BRABO7X] Instalando dependencias na primeira execucao (isso pode demorar 1 minuto)...
    "%VPY%" -m pip install --upgrade pip
    "%VPY%" -m pip install -r "brabo7x_live\requirements.txt"
    if errorlevel 1 goto :dep_error
    echo ok>"brabo7x_live\.deps_ok"
)

echo.
echo ============================================================
echo   [OK] PAINEL STUDIO INICIADO COM SUCESSO!
echo   Abrindo no navegador: http://127.0.0.1:8765
echo   (Mantenha esta janela aberta enquanto a live estiver ativa)
echo ============================================================
echo.

start "" "http://127.0.0.1:8765"
"%VPY%" "brabo7x_live\app.py"
pause
exit /b 0

:dep_error
echo.
echo [ERRO] Falha ao instalar as dependencias Python.
pause
exit /b 1
