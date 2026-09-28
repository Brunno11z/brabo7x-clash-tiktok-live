@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title BRABO7X - Instalacao Automatica

echo ============================================================
echo      BRABO7X CLASH LIVE - INSTALACAO AUTOMATICA
echo ============================================================
echo.
echo  Este instalador prepara tudo e testa o jogo no final:
echo   1. Java JDK 21   2. JavaFX 21 SDK   3. Maven
echo   4. Python + pacotes do bot   5. Compilacao do jogo
echo.
echo  NAO FECHE ESTA JANELA ATE VER A MENSAGEM FINAL.
echo.
pause
if not exist ".tools" mkdir ".tools"

:: ==================== 1. JAVA JDK 21 ====================
echo.
echo [1/5] Verificando Java JDK 21...
set "JAVA_CMD="
if exist ".tools\jdk-21\bin\java.exe" set "JAVA_CMD=%~dp0.tools\jdk-21\bin\java.exe"
if defined JAVA_CMD goto java_ok
for /d %%d in ("%ProgramFiles%\Eclipse Adoptium\jdk-21*" "%ProgramFiles%\Java\jdk-21*") do if exist "%%d\bin\java.exe" set "JAVA_CMD=%%d\bin\java.exe"
if defined JAVA_CMD goto java_ok
where java >nul 2>nul
if not errorlevel 1 set "JAVA_CMD=java"
if defined JAVA_CMD goto java_ok

echo [BRABO7X] Java nao encontrado. Baixando JDK 21 Temurin (~200 MB)...
echo            Pode demorar alguns minutos. Aguarde...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.6%%2B7/OpenJDK21U-jdk_x64_windows_hotspot_21.0.6_7.zip' -OutFile 'jdk21.zip'; Write-Host 'Baixado. Extraindo...'; Expand-Archive -Path 'jdk21.zip' -DestinationPath '.tools' -Force; Remove-Item 'jdk21.zip' -Force"
for /d %%d in (".tools\jdk-21*") do if exist "%%d\bin\java.exe" set "JAVA_CMD=%~dp0%%d\bin\java.exe"
if defined JAVA_CMD goto java_ok
echo [ERRO] Falha ao baixar o Java. Verifique sua internet e rode de novo.
pause
exit /b 1

:java_ok
echo [OK] Java: !JAVA_CMD!

:: ==================== 2. JAVAFX 21 SDK ====================
echo.
echo [2/5] Verificando JavaFX 21 SDK...
if exist ".tools\javafx-sdk-21\lib\javafx.controls.jar" goto javafx_ok
echo [BRABO7X] Baixando JavaFX 21 SDK oficial (~48 MB)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://download2.gluonhq.com/openjfx/21.0.2/openjfx-21.0.2_windows-x64_bin-sdk.zip' -OutFile 'javafx.zip'; Write-Host 'Baixado. Extraindo...'; Expand-Archive -Path 'javafx.zip' -DestinationPath '.tools' -Force; Remove-Item 'javafx.zip' -Force"
if exist ".tools\javafx-sdk-21.0.2\lib\javafx.controls.jar" ren ".tools\javafx-sdk-21.0.2" "javafx-sdk-21"
if exist ".tools\javafx-sdk-21\lib\javafx.controls.jar" goto javafx_ok
echo [AVISO] JavaFX SDK nao baixou, mas o jogo pode rodar pelo Maven. Continuando...
goto maven_step

:javafx_ok
echo [OK] JavaFX 21 SDK pronto em .tools\javafx-sdk-21

:: ==================== 3. MAVEN ====================
:maven_step
echo.
echo [3/5] Verificando Apache Maven...
set "MVN_CMD="
if exist ".tools\apache-maven\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven\bin\mvn.cmd"
if defined MVN_CMD goto maven_ok
where mvn >nul 2>nul
if not errorlevel 1 set "MVN_CMD=mvn"
if defined MVN_CMD goto maven_ok

echo [BRABO7X] Baixando Apache Maven (~10 MB)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip' -OutFile 'maven.zip'; Write-Host 'Baixado. Extraindo...'; Expand-Archive -Path 'maven.zip' -DestinationPath '.tools' -Force; Remove-Item 'maven.zip' -Force"
if exist ".tools\apache-maven-3.9.16\bin\mvn.cmd" ren ".tools\apache-maven-3.9.16" "apache-maven"
if exist ".tools\apache-maven\bin\mvn.cmd" set "MVN_CMD=%~dp0.tools\apache-maven\bin\mvn.cmd"
if defined MVN_CMD goto maven_ok
echo [ERRO] Falha ao baixar o Maven. Verifique sua internet e rode de novo.
pause
exit /b 1

:maven_ok
echo [OK] Maven: !MVN_CMD!

:: ==================== 4. PYTHON + PACOTES ====================
echo.
echo [4/5] Verificando Python...
set "PY_CMD="
where py >nul 2>nul
if not errorlevel 1 set "PY_CMD=py"
if defined PY_CMD goto py_ok
where python >nul 2>nul
if not errorlevel 1 set "PY_CMD=python"
if defined PY_CMD goto py_ok

echo [BRABO7X] Baixando e instalando Python 3.12 silenciosamente...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe' -OutFile 'py_inst.exe'; Write-Host 'Instalando Python...'; Start-Process '.\py_inst.exe' -ArgumentList '/quiet InstallAllUsers=0 PrependPath=1 Include_pip=1' -Wait; Remove-Item 'py_inst.exe' -Force"
where py >nul 2>nul
if not errorlevel 1 set "PY_CMD=py"
if defined PY_CMD goto py_ok
where python >nul 2>nul
if not errorlevel 1 set "PY_CMD=python"
if defined PY_CMD goto py_ok
echo [ERRO] Falha ao instalar o Python. Reinicie o PC e rode de novo.
pause
exit /b 1

:py_ok
echo [OK] Python: !PY_CMD!
if exist "brabo7x_live\.venv\Scripts\python.exe" goto venv_ok
echo [BRABO7X] Criando ambiente virtual do bot...
!PY_CMD! -m venv "brabo7x_live\.venv"

:venv_ok
set "VPY=brabo7x_live\.venv\Scripts\python.exe"
if exist "!VPY!" goto deps_check
echo [ERRO] Nao foi possivel criar o ambiente virtual.
pause
exit /b 1

:deps_check
if exist "brabo7x_live\.deps_ok" goto deps_ok
echo [BRABO7X] Instalando pacotes do bot (FastAPI, TikTokLive e outros)...
"!VPY!" -m pip install --upgrade pip
"!VPY!" -m pip install -r "brabo7x_live\requirements.txt"
if errorlevel 1 goto fail_pip
echo ok>"brabo7x_live\.deps_ok"

:deps_ok
echo [OK] Pacotes do bot instalados!

:: ==================== 5. COMPILAR E TESTAR O JOGO ====================
echo.
echo [5/5] Compilando e testando o jogo de verdade (aguarde)...
set "JAVA_HOME="
if not "!JAVA_CMD!"=="java" for %%F in ("!JAVA_CMD!") do set "JAVA_HOME=%%~dpF.."
if defined JAVA_HOME set "PATH=!JAVA_HOME!\bin;!PATH!"
call "!MVN_CMD!" clean install -DskipTests
if errorlevel 1 goto fail_build

echo.
echo ============================================================
echo    TUDO PRONTO! JOGO COMPILADO E TESTADO COM SUCESSO!
echo    Agora execute o INICIAR_TUDO_TIKTOK.bat
echo ============================================================
pause
exit /b 0

:fail_pip
echo.
echo [ERRO] Falha ao instalar os pacotes Python. Rode de novo.
pause
exit /b 1

:fail_build
echo.
echo [ERRO] O jogo nao compilou. Copie as ultimas mensagens acima.
pause
exit /b 1
