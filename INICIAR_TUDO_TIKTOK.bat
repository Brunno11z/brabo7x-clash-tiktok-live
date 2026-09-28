@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title BRABO7X - Inicializador Completo

echo ============================================================
echo         BRABO7X CLASH LIVE - INICIANDO SISTEMA
echo ============================================================
echo.
echo 1. Abrindo Painel Web no navegador (porta 8765)...
start "BRABO7X PAINEL" cmd /c call "%~dp0INICIAR_PAINEL_TIKTOK.bat"

echo 2. Aguardando 3 segundos para o servidor subir...
timeout /t 3 /nobreak >nul

echo 3. Abrindo o jogo Clash Royale...
call "%~dp0INICIAR_JOGO_TIKTOK.bat"
