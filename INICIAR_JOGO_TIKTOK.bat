@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Clash LIVE Jogo Arena

echo ============================================================
echo           BRABO7X - CARREGANDO ARENA CLASH ROYALE
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
    echo [ERRO] Java JDK 21 nao foi encontrado no sistema.
    echo Execute primeiro o arquivo "INSTALAR_TUDO_AUTOMATICO.bat" para instalar o Java.
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
        echo [BRABO7X] Maven nao encontrado localmente. Baixando Maven oficial...
        if not exist "%~dp0.tools" mkdir "%~dp0.tools"
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $u='https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip'; $z='%~dp0.tools\maven.zip'; Invoke-WebRequest -Uri $u -OutFile $z; Expand-Archive -Path $z -DestinationPath '%~dp0.tools' -Force; Remove-Item $z -Force"
        if exist "%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd" set "MVN=%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd"
    )
)

echo [BRABO7X] Compilando e iniciando a janela da Arena JavaFX...
"%MVN%" -pl client -am javafx:run -Dbrabo7x.tiktok=true
if errorlevel 1 goto :game_error
exit /b 0

:game_error
echo.
echo ============================================================
echo [ERRO] Ocorreu uma falha ao iniciar o jogo.
echo Tentando compilar o projeto do zero para reparar...
echo ============================================================
"%MVN%" clean compile -pl client -am
if errorlevel 1 (
    echo.
    echo Falha na compilacao. Verifique se o JDK 21 esta configurado corretamente.
    echo Dica: Execute o "INSTALAR_TUDO_AUTOMATICO.bat" novamente.
    pause
    exit /b 1
)
"%MVN%" -pl client javafx:run -Dbrabo7x.tiktok=true
pause
exit /b 0
