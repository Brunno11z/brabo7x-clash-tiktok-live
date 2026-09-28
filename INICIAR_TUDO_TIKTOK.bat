@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title BRABO7X - Inicializador Completo

echo ============================================================
echo        BRABO7X CLASH ROYALE TIKTOK LIVE INTERATIVO
echo ============================================================
echo.
echo [Passo 1/2] Iniciando Servidor e Painel Web TikTok...
start "BRABO7X PAINEL" cmd /k call "%~dp0INICIAR_PAINEL_TIKTOK.bat"

echo.
echo Aguardando 3 segundos para o painel carregar...
timeout /t 3 /nobreak >nul

echo.
echo [Passo 2/2] Iniciando o Jogo Clash Royale...
echo.
call "%~dp0INICIAR_JOGO_TIKTOK.bat"
