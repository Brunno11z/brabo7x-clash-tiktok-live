@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title BRABO7X - Inicializador Completo

echo ============================================================
echo        BRABO7X CLASH ROYALE TIKTOK LIVE INTERATIVO
echo ============================================================
echo.
echo [1/2] Iniciando Painel TikTok no navegador...
start "BRABO7X PAINEL" cmd /k call "%~dp0INICIAR_PAINEL_TIKTOK.bat"

echo.
echo Aguardando 3 segundos...
timeout /t 3 /nobreak >nul

echo.
echo [2/2] Iniciando o Jogo Clash Royale...
echo.
call "%~dp0INICIAR_JOGO_TIKTOK.bat"
