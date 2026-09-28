@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Instalador Automatico de Dependencias

echo ============================================================
echo      BRABO7X CLASH LIVE - INSTALADOR DE DEPENDENCIAS
echo ============================================================
echo.
echo Este script vai verificar e instalar automaticamente:
echo  1. Java JDK 21 (Eclipse Temurin)
echo  2. Python 3.12
echo  3. Apache Maven
echo  4. Ambiente virtual Python e pacotes do TikTokLive
echo  5. Compilacao inicial do jogo
echo.
pause

if not exist ".tools" mkdir ".tools"

:: -----------------------------------------------------------------
:: 1. VERIFICAR OU INSTALAR JAVA JDK 21
:: -----------------------------------------------------------------
echo.
echo [1/5] Verificando Java JDK 21...
set "JAVA_CMD="

where java >nul 2>nul
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('where java') do (
        if not defined JAVA_CMD set "JAVA_CMD=%%i"
    )
)

if not defined JAVA_CMD (
    for /d %%d in ("%ProgramFiles%\Eclipse Adoptium\jdk-21*" "%ProgramFiles%\Java\jdk-21*" "%LOCALAPPDATA%\Programs\Eclipse Adoptium\jdk-21*") do (
        if exist "%%d\bin\java.exe" set "JAVA_CMD=%%d\bin\java.exe"
    )
)

if not defined JAVA_CMD (
    if exist ".tools\jdk-21\bin\java.exe" set "JAVA_CMD=%~dp0.tools\jdk-21\bin\java.exe"
)

if defined JAVA_CMD (
    echo [OK] Java detectado: "!JAVA_CMD!"
) else (
    echo [BRABO7X] Java JDK 21 nao encontrado. Tentando instalar via Winget...
    where winget >nul 2>nul
    if %errorlevel%==0 (
        winget install --id EclipseAdoptium.Temurin.21.JDK -e --silent --accept-source-agreements --accept-package-agreements
        timeout /t 5 /nobreak >nul
        for /d %%d in ("%ProgramFiles%\Eclipse Adoptium\jdk-21*") do (
            if exist "%%d\bin\java.exe" set "JAVA_CMD=%%d\bin\java.exe"
        )
    )
    
    if not defined JAVA_CMD (
        echo [BRABO7X] Baixando OpenJDK 21 portatil oficial para a pasta .tools...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $u='https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.6%%2B7/OpenJDK21U-jdk_x64_windows_hotspot_21.0.6_7.zip'; $z='%~dp0.tools\jdk21.zip'; Write-Host 'Baixando JDK 21 (pode levar 1-2 min)...'; Invoke-WebRequest -Uri $u -OutFile $z; Expand-Archive -Path $z -DestinationPath '%~dp0.tools' -Force; Remove-Item $z -Force; Get-ChildItem '%~dp0.tools' -Directory -Filter 'jdk-21*' | Rename-Item -NewName 'jdk-21' -Force"
        if exist ".tools\jdk-21\bin\java.exe" (
            set "JAVA_CMD=%~dp0.tools\jdk-21\bin\java.exe"
            echo [OK] JDK 21 portatil configurado com sucesso!
        ) else (
            echo [AVISO] Nao foi possivel baixar o JDK automaticamente. Instale manualmente o Temurin JDK 21 se necessario.
        )
    )
)

:: -----------------------------------------------------------------
:: 2. VERIFICAR OU INSTALAR PYTHON 3.12
:: -----------------------------------------------------------------
echo.
echo [2/5] Verificando Python 3.12...
set "PY_CMD="

where py >nul 2>nul
if %errorlevel%==0 (
    py -3.12 --version >nul 2>nul
    if %errorlevel%==0 set "PY_CMD=py -3.12"
)

if not defined PY_CMD (
    where python >nul 2>nul
    if %errorlevel%==0 (
        python -c "import sys; sys.exit(0 if sys.version_info[0]==3 and sys.version_info[1]>=10 else 1)" >nul 2>nul
        if %errorlevel%==0 set "PY_CMD=python"
    )
)

if not defined PY_CMD (
    for /d %%d in ("%LOCALAPPDATA%\Programs\Python\Python312*" "%ProgramFiles%\Python312*") do (
        if exist "%%d\python.exe" set "PY_CMD=%%d\python.exe"
    )
)

if defined PY_CMD (
    echo [OK] Python detectado: !PY_CMD!
) else (
    echo [BRABO7X] Python 3.12 nao detectado. Tentando instalar via Winget...
    where winget >nul 2>nul
    if %errorlevel%==0 (
        winget install --id Python.Python.3.12 -e --silent --accept-source-agreements --accept-package-agreements
        timeout /t 5 /nobreak >nul
        for /d %%d in ("%LOCALAPPDATA%\Programs\Python\Python312*") do (
            if exist "%%d\python.exe" set "PY_CMD=%%d\python.exe"
        )
    )
    if not defined PY_CMD (
        echo [BRABO7X] Baixando instalador oficial do Python 3.12...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe'; $f='%~dp0.tools\python_installer.exe'; Invoke-WebRequest -Uri $u -OutFile $f; Start-Process $f -ArgumentList '/quiet InstallAllUsers=0 PrependPath=1 Include_pip=1' -Wait; Remove-Item $f -Force"
        set "PY_CMD=python"
    )
)

:: -----------------------------------------------------------------
:: 3. VERIFICAR OU INSTALAR APACHE MAVEN
:: -----------------------------------------------------------------
echo.
echo [3/5] Verificando Apache Maven...
set "MVN_CMD="

where mvn >nul 2>nul
if %errorlevel%==0 set "MVN_CMD=mvn"

if not defined MVN_CMD (
    if exist ".tools\apache-maven-3.9.16\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd"
    if exist ".tools\apache-maven\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven\bin\mvn.cmd"
)

if not defined MVN_CMD (
    echo [BRABO7X] Baixando Apache Maven oficial...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $u='https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip'; $z='%~dp0.tools\maven.zip'; Invoke-WebRequest -Uri $u -OutFile $z; Expand-Archive -Path $z -DestinationPath '%~dp0.tools' -Force; Remove-Item $z -Force; if (Test-Path '%~dp0.tools\apache-maven-3.9.16') { Rename-Item '%~dp0.tools\apache-maven-3.9.16' '%~dp0.tools\apache-maven' -Force -ErrorAction SilentlyContinue }"
    if exist ".tools\apache-maven\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven\bin\mvn.cmd"
    if exist ".tools\apache-maven-3.9.16\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven-3.9.16\bin\mvn.cmd"
)
echo [OK] Maven pronto!

:: -----------------------------------------------------------------
:: 4. CONFIGURAR AMBIENTE PYTHON E DEPENDENCIAS
:: -----------------------------------------------------------------
echo.
echo [4/5] Configurando ambiente virtual Python (brabo7x_live)...
if not exist "brabo7x_live\.venv\Scripts\python.exe" (
    !PY_CMD! -m venv "brabo7x_live\.venv"
)

set "VPY=brabo7x_live\.venv\Scripts\python.exe"
if exist "!VPY!" (
    echo Instalando pacotes (FastAPI, TikTokLive, EulerApiSdk, etc.)...
    "!VPY!" -m pip install --upgrade pip
    "!VPY!" -m pip install -r "brabo7x_live\requirements.txt"
    echo ok>"brabo7x_live\.deps_ok"
    echo [OK] Dependencias Python instaladas com sucesso!
) else (
    echo [AVISO] Nao foi possivel criar o venv automaticamente.
)

:: -----------------------------------------------------------------
:: 5. PRE-COMPILAR O JOGO JAVA
:: -----------------------------------------------------------------
echo.
echo [5/5] Pre-compilando modulos do jogo Java (pode levar 1 min)...
if defined JAVA_CMD (
    for %%F in ("!JAVA_CMD!") do set "JAVA_HOME_DIR=%%~dpF.."
    set "JAVA_HOME=!JAVA_HOME_DIR!"
    set "PATH=!JAVA_HOME_DIR!\bin;!PATH!"
)
if defined MVN_CMD (
    call "!MVN_CMD!" -pl client -am compile -DskipTests
)

echo.
echo ============================================================
echo   TUDO PRONTO! INSTALACAO CONCLUIDA COM SUCESSO!
echo ============================================================
echo Agora voce pode clicar em INICIAR_TUDO_TIKTOK.bat
echo ou abrir o painel e o jogo separadamente.
echo.
pause
