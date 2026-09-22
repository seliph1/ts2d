@echo off
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

"C:\Program Files\7-Zip\7z.exe" a -tzip "%SCRIPT_DIR%game.zip" "%SCRIPT_DIR%\*" ^
-xr!*.py ^
-xr!*.bat ^
-xr!game ^
-xr!lovejs_source ^
-xr!.gitattributes ^
-xr!.gitignore ^
-xr!.vscode ^
-xr!uidebug

if exist "game.love" del "game.love"

ren "game.zip" "game.love"

pause