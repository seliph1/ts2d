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

echo [2/4] Compactando codigo e scripts do motor em "!LOVE_FILE!"...

if defined SEVENZIP (
    "!SEVENZIP!" a -tzip "!LOVE_FILE!" ^
        "core" "lib" "meta" ^
        "conf.lua" "main.lua" "cs2d.png" "cs2d1024px.png" >nul
) else (
    echo    (7-Zip nao encontrado, usando PowerShell Compress-Archive...)
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$dirs = @('core','lib','meta');" ^
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
    set "SERVER_LOVE=%TEMP%\ts2d_server_%RANDOM%.love"
    copy /y "!LOVE_FILE!" "!SERVER_LOVE!" >nul
    echo server > "%TEMP%\is_server"
    if defined SEVENZIP (
        "!SEVENZIP!" a -tzip "!SERVER_LOVE!" "%TEMP%\is_server" >nul
    )
    if exist "%TEMP%\is_server" del /f /q "%TEMP%\is_server"
    copy /b "!LOVEC_EXE!" + "!SERVER_LOVE!" "build\ts2d_server.exe" >nul
    if not errorlevel 1 echo    - Criado: build\ts2d_server.exe (Modo Console / Servidor Dedicado Headless)
    if exist "!SERVER_LOVE!" del /f /q "!SERVER_LOVE!"
)

:: Vincular pastas expostas na pasta build/ para desenvolvimento local imediato
if not exist "build\gfx" mklink /j "build\gfx" "gfx" >nul 2>nul
if not exist "build\sfx" mklink /j "build\sfx" "sfx" >nul 2>nul
if not exist "build\logos" mklink /j "build\logos" "logos" >nul 2>nul
if not exist "build\sys" mklink /j "build\sys" "sys" >nul 2>nul
if not exist "build\maps" mklink /j "build\maps" "maps" >nul 2>nul

:: 5. Montar pasta dist completa com executaveis, DLLs e pastas expostas
echo [4/4] Montando pasta de distribuicao 'dist' com pastas expostas...
if not exist "dist" mkdir "dist"
copy /y "build\*.dll" "dist\" >nul
copy /y "build\ts2d.exe" "dist\" >nul
if exist "build\ts2d_server.exe" copy /y "build\ts2d_server.exe" "dist\" >nul
if exist "README.md" copy /y "README.md" "dist\" >nul

echo    - Copiando pastas expostas para dist\...
if exist "gfx" xcopy "gfx" "dist\gfx\" /e /i /y >nul
if exist "sfx" xcopy "sfx" "dist\sfx\" /e /i /y >nul
if exist "logos" xcopy "logos" "dist\logos\" /e /i /y >nul
if exist "sys" xcopy "sys" "dist\sys\" /e /i /y >nul
if exist "maps" xcopy "maps" "dist\maps\" /e /i /y >nul

:: Limpar arquivo temporario
if exist "!LOVE_FILE!" del /f /q "!LOVE_FILE!"

echo.
echo ========================================================
echo               BUILD CONCLUIDO COM SUCESSO!
echo ========================================================
echo Executaveis gerados:
echo   - build\ts2d.exe
if exist "build\ts2d_server.exe" echo   - build\ts2d_server.exe (console/servidor)
echo.
echo Pacote de distribuicao configurado em 'dist\':
echo   - dist\ts2d.exe (executavel)
if exist "dist\ts2d_server.exe" echo   - dist\ts2d_server.exe (console/servidor)
echo   - dist\*.dll (todas as dependencias da pasta build\)
echo   - dist\gfx\   (exposta para sprites, tiles, HUD e texturas)
echo   - dist\sfx\   (exposta para sons e efeitos sonoros)
echo   - dist\logos\ (exposta para sprays e icones)
echo   - dist\sys\   (exposta para configuracoes e scripts Lua de servidor)
echo   - dist\maps\  (exposta para mapas .map customizados)
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

