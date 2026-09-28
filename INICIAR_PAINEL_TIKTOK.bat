@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Painel TikTok Studio

:: Liberar porta 8765 se estiver presa
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":8765" ^| findstr "LISTENING"') do (
    taskkill /f /pid %%a >nul 2>nul
)

set "VPY=brabo7x_live\.venv\Scripts\python.exe"
if not exist "!VPY!" (
    echo [ERRO] Ambiente Python nao encontrado. Execute o "INSTALAR_TUDO_AUTOMATICO.bat".
    pause & exit /b 1
)

echo ============================================================
echo   [OK] PAINEL TIKTOK STUDIO RODANDO
echo   Acesse: http://127.0.0.1:8765
echo ============================================================
echo.
start "" "http://127.0.0.1:8765"

"!VPY!" "brabo7x_live\app.py"
pause
