@echo off
setlocal enabledelayedexpansion

title TS2D - Build Binary

echo ========================================================
echo               Tactical Strike 2D (TS2D)
echo              Criador de Binarios Windows
echo ========================================================
echo.

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

:: 1. Localizar love.exe e lovec.exe
set "LOVE_EXE="
set "LOVEC_EXE="

if exist "C:\LOVE2D\nightly\love.exe" (
    set "LOVE_EXE=C:\LOVE2D\nightly\love.exe"
    if exist "C:\LOVE2D\nightly\lovec.exe" set "LOVEC_EXE=C:\LOVE2D\nightly\lovec.exe"
)

if not defined LOVE_EXE (
    for /f "delims=" %%I in ('where love.exe 2^>nul') do (
        if not defined LOVE_EXE set "LOVE_EXE=%%I"
    )
    for /f "delims=" %%I in ('where lovec.exe 2^>nul') do (
        if not defined LOVEC_EXE set "LOVEC_EXE=%%I"
    )
)

if not defined LOVE_EXE (
    if exist "%ProgramFiles%\LOVE\love.exe" (
        set "LOVE_EXE=%ProgramFiles%\LOVE\love.exe"
        if exist "%ProgramFiles%\LOVE\lovec.exe" set "LOVEC_EXE=%ProgramFiles%\LOVE\lovec.exe"
    )
)

if not defined LOVE_EXE (
    if exist "%ProgramFiles(x86)%\LOVE\love.exe" (
        set "LOVE_EXE=%ProgramFiles(x86)%\LOVE\love.exe"
        if exist "%ProgramFiles(x86)%\LOVE\lovec.exe" set "LOVEC_EXE=%ProgramFiles(x86)%\LOVE\lovec.exe"
    )
)

if not defined LOVE_EXE (
    echo [ERRO] Nao foi possivel encontrar love.exe no sistema!
    echo Certifique-se de ter o Love2D instalado ou configurado no PATH.
    goto :error
)

echo [1/4] Localizado Love2D em: "!LOVE_EXE!"

:: 2. Verificar pasta build com as DLLs
if not exist "build" (
    echo [ERRO] A pasta 'build' nao foi encontrada!
    goto :error
)

:: 3. Localizar ferramenta de compactacao (7-Zip ou PowerShell)
set "SEVENZIP="
if exist "C:\Program Files\7-Zip\7z.exe" set "SEVENZIP=C:\Program Files\7-Zip\7z.exe"
if not defined SEVENZIP (
    for /f "delims=" %%I in ('where 7z.exe 2^>nul') do (
        if not defined SEVENZIP set "SEVENZIP=%%I"
    )
)

set "LOVE_FILE=%TEMP%\ts2d_build_%RANDOM%.love"
if exist "!LOVE_FILE!" del /f /q "!LOVE_FILE!"

echo [2/4] Compactando arquivos do jogo...

if defined SEVENZIP (
    "!SEVENZIP!" a -tzip "!LOVE_FILE!" ^
        "core" "gfx" "lib" "logos" "maps" "meta" "sfx" "sys" ^
        "conf.lua" "main.lua" "cs2d.png" "cs2d1024px.png" >nul
) else (
    echo    (7-Zip nao encontrado, usando PowerShell Compress-Archive...)
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$dirs = @('core','gfx','lib','logos','maps','meta','sfx','sys');" ^
        "$files = @('conf.lua','main.lua','cs2d.png','cs2d1024px.png');" ^
        "$items = @();" ^
        "foreach ($d in $dirs) { if (Test-Path $d) { $items += (Get-Item $d) } };" ^
        "foreach ($f in $files) { if (Test-Path $f) { $items += (Get-Item $f) } };" ^
        "Compress-Archive -Path $items -DestinationPath '%TEMP%\temp_ts2d.zip' -Force;" ^
        "Move-Item -Path '%TEMP%\temp_ts2d.zip' -Destination '!LOVE_FILE!' -Force;"
)

if not exist "!LOVE_FILE!" (
    echo [ERRO] Falha ao criar o arquivo .love compactado!
    goto :error
)

:: 4. Criar binarios fundidos
echo [3/4] Gerando executaveis fundidos...

:: Gerar ts2d.exe (jogo com janela)
copy /b "!LOVE_EXE!" + "!LOVE_FILE!" "build\ts2d.exe" >nul
if errorlevel 1 (
    echo [ERRO] Falha ao criar build\ts2d.exe!
    goto :cleanup_error
)
echo    - Criado: build\ts2d.exe

:: Gerar ts2d_server.exe (se lovec.exe estiver disponivel)
if defined LOVEC_EXE (
    copy /b "!LOVEC_EXE!" + "!LOVE_FILE!" "build\ts2d_server.exe" >nul
    if not errorlevel 1 echo    - Criado: build\ts2d_server.exe (Modo Console / Servidor Dedicado)
)

:: 5. Montar pasta dist completa com executaveis e DLLs de build/
echo [4/4] Montando pasta de distribuicao 'dist'...
if not exist "dist" mkdir "dist"
copy /y "build\*.dll" "dist\" >nul
copy /y "build\ts2d.exe" "dist\" >nul
if exist "build\ts2d_server.exe" copy /y "build\ts2d_server.exe" "dist\" >nul
if exist "README.md" copy /y "README.md" "dist\" >nul

:: Limpar arquivo temporario
if exist "!LOVE_FILE!" del /f /q "!LOVE_FILE!"

echo.
echo ========================================================
echo               BUILD CONCLUIDO COM SUCESSO!
echo ========================================================
echo Executaveis gerados:
echo   - build\ts2d.exe (junto com as DLLs em build\)
if exist "build\ts2d_server.exe" echo   - build\ts2d_server.exe (console/servidor)
echo.
echo Pacote pronto para distribuicao:
echo   - dist\ (contem os executaveis e todas as DLLs de build\)
echo ========================================================
goto :end

:cleanup_error
if exist "!LOVE_FILE!" del /f /q "!LOVE_FILE!"

:error
echo.
echo [FALHA] Ocorreu um erro durante a criacao do binario.
echo.

:end
pause

