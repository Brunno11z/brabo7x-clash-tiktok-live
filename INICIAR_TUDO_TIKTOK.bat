@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title BRABO7X - Inicializador Completo (Painel + Jogo)

echo ============================================================
echo        BRABO7X CLASH ROYALE TIKTOK LIVE INTERATIVO
echo ============================================================
echo.
echo [1/2] Iniciando o Painel TikTok em segundo plano...
start "BRABO7X PAINEL" cmd /c "%~dp0INICIAR_PAINEL_TIKTOK.bat"

echo.
echo Aguardando 4 segundos para o painel carregar...
timeout /t 4 /nobreak >nul

echo.
echo [2/2] Abrindo a Arena do Jogo Clash Royale...
echo.
call "%~dp0INICIAR_JOGO_TIKTOK.bat"
