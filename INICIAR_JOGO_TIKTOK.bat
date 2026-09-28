@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Clash LIVE Arena

echo ============================================================
echo           BRABO7X - INICIANDO JOGO CLASH ROYALE
echo ============================================================
echo.

:: Detectar Java
set "JAVA_BIN="
where java >nul 2>nul
if %errorlevel%==0 (
    set "JAVA_BIN=java"
) else (
    for /d %%d in ("%~dp0.tools\jdk-21" "%ProgramFiles%\Eclipse Adoptium\jdk-21*" "%ProgramFiles%\Java\jdk-21*" "%LOCALAPPDATA%\Programs\Eclipse Adoptium\jdk-21*") do (
        if exist "%%d\bin\java.exe" (
            set "JAVA_BIN=%%d\bin\java.exe"
            set "JAVA_HOME=%%d"
            set "PATH=%%d\bin;!PATH!"
        )
    )
)

if not defined JAVA_BIN (
    echo.
    echo [ERRO] Java JDK 21 nao foi encontrado.
    echo Execute primeiro o arquivo "INSTALAR_TUDO_AUTOMATICO.bat".
    echo.
    pause
    exit /b 1
)

:: Detectar Maven
set "MVN=mvn"
where mvn >nul 2>nul
if errorlevel 1 (
    if exist "%~dp0.tools\apache-maven\bin\mvn.cmd" (
        set "MVN=%~dp0.tools\apache-maven\bin\mvn.cmd"
    ) else if exist "%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd" (
        set "MVN=%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd"
    ) else (
        echo [BRABO7X] Maven nao encontrado. Execute o "INSTALAR_TUDO_AUTOMATICO.bat".
        pause
        exit /b 1
    )
)

echo [BRABO7X] Executando arena JavaFX...
"%MVN%" -pl client javafx:run -Dbrabo7x.tiktok=true
if errorlevel 1 (
    echo.
    echo [AVISO] Falha ao rodar diretamente. Compilando modulos e tentando novamente...
    "%MVN%" clean compile -pl client -am
    "%MVN%" -pl client javafx:run -Dbrabo7x.tiktok=true
)

if errorlevel 1 (
    echo.
    echo ============================================================
    echo [ERRO] O jogo nao conseguiu inicializar.
    echo Verifique o log de erro acima antes de fechar esta janela.
    echo ============================================================
    pause
    exit /b 1
)

exit /b 0
