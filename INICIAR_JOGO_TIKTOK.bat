@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Clash Royale LIVE Arena

echo ============================================================
echo           BRABO7X - ABRINDO JOGO CLASH ROYALE
echo ============================================================
echo.

:: Localizar Java
set "JAVA_CMD="
for /d %%d in ("%~dp0.tools\jdk-21" "%ProgramFiles%\Eclipse Adoptium\jdk-21*" "%ProgramFiles%\Java\jdk-21*") do (
    if exist "%%d\bin\java.exe" if not defined JAVA_CMD set "JAVA_CMD=%%d\bin\java.exe"
)
if not defined JAVA_CMD (
    where java >nul 2>nul && set "JAVA_CMD=java"
)
if not defined JAVA_CMD (
    echo [ERRO] Java nao encontrado. Execute o "INSTALAR_TUDO_AUTOMATICO.bat".
    pause & exit /b 1
)
for %%F in ("!JAVA_CMD!") do set "JAVA_HOME=%%~dpF.."
set "PATH=!JAVA_HOME!\bin;!PATH!"

:: Localizar Maven
set "MVN_CMD="
where mvn >nul 2>nul && set "MVN_CMD=mvn"
if not defined MVN_CMD if exist "%~dp0.tools\apache-maven\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven\bin\mvn.cmd"
if not defined MVN_CMD if exist "%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd"
if not defined MVN_CMD (
    echo [ERRO] Maven nao encontrado. Execute o "INSTALAR_TUDO_AUTOMATICO.bat".
    pause & exit /b 1
)

echo [BRABO7X] Abrindo Arena com JavaFX...
call "!MVN_CMD!" -pl client javafx:run -Dbrabo7x.tiktok=true
if errorlevel 1 (
    echo.
    echo [AVISO] Compilando modulos do jogo antes de iniciar...
    call "!MVN_CMD!" clean install -DskipTests
    call "!MVN_CMD!" -pl client javafx:run -Dbrabo7x.tiktok=true
)

if errorlevel 1 (
    echo.
    echo [ERRO] Ocorreu uma falha ao abrir a arena.
    pause
    exit /b 1
)
exit /b 0
