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

:: Se tiver o JAR compilado e JavaFX SDK, inicia direto sem depender do Maven
if exist "bin\client.jar" if exist "bin\core.jar" (
    set "JFX_PATH="
    if exist ".tools\javafx-sdk-21\lib" set "JFX_PATH=%~dp0.tools\javafx-sdk-21\lib"
    if defined JFX_PATH (
        echo [BRABO7X] Iniciando jogo instantaneamente via JAR compilado...
        "!JAVA_CMD!" --module-path "!JFX_PATH!" --add-modules javafx.controls,javafx.fxml,javafx.graphics --add-opens javafx.graphics/com.sun.javafx.application=ALL-UNNAMED -cp "bin\core.jar;bin\client.jar" controllers.TikTokMain
        if not errorlevel 1 exit /b 0
    )
)

:: Fallback via Maven
set "MVN_CMD="
where mvn >nul 2>nul && set "MVN_CMD=mvn"
if not defined MVN_CMD if exist "%~dp0.tools\apache-maven\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven\bin\mvn.cmd"
if not defined MVN_CMD if exist "%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd"

if defined MVN_CMD (
    echo [BRABO7X] Executando arena via Maven...
    call "!MVN_CMD!" -pl client javafx:run -Dbrabo7x.tiktok=true
    if errorlevel 1 (
        call "!MVN_CMD!" clean install -DskipTests
        call "!MVN_CMD!" -pl client javafx:run -Dbrabo7x.tiktok=true
    )
)

if errorlevel 1 (
    echo.
    echo [ERRO] Ocorreu uma falha ao abrir a arena.
    pause
    exit /b 1
)
exit /b 0
