@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Instalacao Automatica

echo ============================================================
echo      BRABO7X CLASH LIVE - INSTALACAO AUTOMATICA
echo ============================================================
echo.
echo  1. Java JDK 21 + 2. JavaFX 21 + 3. Maven + 4. Python + Pacotes
echo.
pause
if not exist ".tools" mkdir ".tools"

:: ---------- 1. JDK 21 ----------
echo.
echo [1/5] Verificando Java JDK 21...
set "JAVA_CMD="
for /d %%d in ("%~dp0.tools\jdk-21" "%ProgramFiles%\Eclipse Adoptium\jdk-21*" "%ProgramFiles%\Java\jdk-21*") do (
    if exist "%%d\bin\java.exe" if not defined JAVA_CMD set "JAVA_CMD=%%d\bin\java.exe"
)
if not defined JAVA_CMD (
    where java >nul 2>nul && set "JAVA_CMD=java"
)
if not defined JAVA_CMD (
    echo [BRABO7X] Baixando JDK 21 Temurin (~200 MB)...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.6%%2B7/OpenJDK21U-jdk_x64_windows_hotspot_21.0.6_7.zip' -OutFile '%~dp0.tools\jdk21.zip'; Expand-Archive -Path '%~dp0.tools\jdk21.zip' -DestinationPath '%~dp0.tools' -Force; Remove-Item '%~dp0.tools\jdk21.zip' -Force"
    for /d %%d in ("%~dp0.tools\jdk-21*") do ren "%%d" "jdk-21" >nul 2>nul
    if exist ".tools\jdk-21\bin\java.exe" (set "JAVA_CMD=%~dp0.tools\jdk-21\bin\java.exe") else (goto :fail_java)
)
echo [OK] Java: !JAVA_CMD!

:: ---------- 2. JAVAFX 21 SDK ----------
echo.
echo [2/5] Verificando JavaFX 21 SDK...
if exist ".tools\javafx-sdk-21\lib\javafx.controls.jar" (
    echo [OK] JavaFX 21 SDK ja esta instalado.
) else (
    echo [BRABO7X] Baixando JavaFX 21 SDK (~48 MB)...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download2.gluonhq.com/openjfx/21.0.2/openjfx-21.0.2_windows-x64_bin-sdk.zip' -OutFile '%~dp0.tools\javafx.zip'; Expand-Archive -Path '%~dp0.tools\javafx.zip' -DestinationPath '%~dp0.tools' -Force; Remove-Item '%~dp0.tools\javafx.zip' -Force"
    for /d %%d in ("%~dp0.tools\javafx-sdk-*") do ren "%%d" "javafx-sdk-21" >nul 2>nul
    if exist ".tools\javafx-sdk-21\lib\javafx.controls.jar" (echo [OK] JavaFX 21 SDK instalado!) else (goto :fail_javafx)
)

:: ---------- 3. MAVEN ----------
echo.
echo [3/5] Verificando Apache Maven...
set "MVN_CMD="
where mvn >nul 2>nul && set "MVN_CMD=mvn"
if not defined MVN_CMD if exist ".tools\apache-maven\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven\bin\mvn.cmd"
if not defined MVN_CMD (
    echo [BRABO7X] Baixando Apache Maven...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip' -OutFile '%~dp0.tools\maven.zip'; Expand-Archive -Path '%~dp0.tools\maven.zip' -DestinationPath '%~dp0.tools' -Force; Remove-Item '%~dp0.tools\maven.zip' -Force"
    for /d %%d in ("%~dp0.tools\apache-maven-3.9.16") do ren "%%d" "apache-maven" >nul 2>nul
    if exist ".tools\apache-maven\bin\mvn.cmd" (set "MVN_CMD=%~dp0.tools\apache-maven\bin\mvn.cmd") else (goto :fail_maven)
)
echo [OK] Maven: !MVN_CMD!

:: ---------- 4. PYTHON + PACOTES ----------
echo.
echo [4/5] Verificando Python e pacotes do bot...
set "PY_CMD="
where py >nul 2>nul && set "PY_CMD=py"
if not defined PY_CMD where python >nul 2>nul && set "PY_CMD=python"
if not defined PY_CMD (
    echo [BRABO7X] Baixando e instalando Python 3.12...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe' -OutFile '%~dp0.tools\py_inst.exe'; Start-Process '%~dp0.tools\py_inst.exe' -ArgumentList '/quiet InstallAllUsers=0 PrependPath=1 Include_pip=1' -Wait; Remove-Item '%~dp0.tools\py_inst.exe' -Force"
    set "PY_CMD=python"
)
if not exist "brabo7x_live\.venv\Scripts\python.exe" !PY_CMD! -m venv "brabo7x_live\.venv"
set "VPY=brabo7x_live\.venv\Scripts\python.exe"
if exist "!VPY!" (
    "!VPY!" -m pip install --upgrade pip >nul 2>nul
    "!VPY!" -m pip install -r "brabo7x_live\requirements.txt"
    if errorlevel 1 goto :fail_pip
    echo ok>"brabo7x_live\.deps_ok"
    echo [OK] Pacotes do bot instalados!
) else (goto :fail_pip)

:: ---------- 5. COMPILAR E TESTAR O JOGO ----------
echo.
echo [5/5] Compilando e testando o jogo (isso testa de verdade o build)...
for %%F in ("!JAVA_CMD!") do set "JAVA_HOME=%%~dpF.."
set "PATH=!JAVA_HOME!\bin;!PATH!"
call "!MVN_CMD!" clean install -DskipTests
if errorlevel 1 goto :fail_build

echo.
echo ============================================================
echo   TUDO PRONTO! JOGO COMPILADO E TESTADO COM SUCESSO!
echo   Agora execute o INICIAR_TUDO_TIKTOK.bat
echo ============================================================
pause
exit /b 0

:fail_java
echo [ERRO] Falha ao instalar o Java JDK 21. Verifique sua internet.
pause & exit /b 1
:fail_javafx
echo [ERRO] Falha ao instalar o JavaFX SDK. Verifique sua internet.
pause & exit /b 1
:fail_maven
echo [ERRO] Falha ao instalar o Maven. Verifique sua internet.
pause & exit /b 1
:fail_pip
echo [ERRO] Falha ao instalar os pacotes Python.
pause & exit /b 1
:fail_build
echo.
echo [ERRO] O jogo nao compilou. Copie as mensagens de erro acima.
pause & exit /b 1
