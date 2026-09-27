@echo off
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

for %%I in ("%SCRIPT_DIR%.") do set "PROJECT_NAME=%%~nxI"

echo ========================================
echo Gerando %PROJECT_NAME%.love...
echo ========================================
echo.

set "SEVENZIP=C:\Program Files\7-Zip\7z.exe"
if not exist "%SEVENZIP%" set "SEVENZIP=C:\Program Files (x86)\7-Zip\7z.exe"
if not exist "%SEVENZIP%" set "SEVENZIP=7z"

set "LIST_FILE=%TEMP%\%PROJECT_NAME%_filelist_%RANDOM%.txt"

REM Lista arquivos atuais (incluindo modificados e novos) respeitando o .gitignore
git ls-files --cached --others --exclude-standard > "%LIST_FILE%"

if errorlevel 1 (
    echo.
    echo ERRO: falha ao consultar arquivos com git
    if exist "%LIST_FILE%" del "%LIST_FILE%"
    pause
    exit /b 1
)

if exist "%PROJECT_NAME%.zip" del "%PROJECT_NAME%.zip"
if exist "%PROJECT_NAME%.love" del "%PROJECT_NAME%.love"

"%SEVENZIP%" a -tzip "%PROJECT_NAME%.zip" @"%LIST_FILE%" ^
-xr!*.bat ^
-xr!.git*

set ZIP_ERROR=%ERRORLEVEL%
if exist "%LIST_FILE%" del "%LIST_FILE%"

if %ZIP_ERROR% neq 0 (
    echo.
    echo ERRO: nao foi possivel gerar %PROJECT_NAME%.love
    pause
    exit /b 1
)

ren "%PROJECT_NAME%.zip" "%PROJECT_NAME%.love"

echo.
echo ========================================
echo %PROJECT_NAME%.love gerado com sucesso!
echo ========================================

pause