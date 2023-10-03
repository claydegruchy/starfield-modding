@echo off

rem skk.50@outlook.com September 2023
rem ChampollionDecompile.cmd

set SOURCE=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\PEX\scripts
set DESTINATION=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\Base

cls
echo *****************************************************
echo Champollion decompile Starfield base game scripts 001
echo.
echo SOURCE: "%SOURCE%"
echo DESTINATION: "%DESTINATION%"
echo.

CHAMPOLLION.EXE -r -d -p "%DESTINATION%"                      "%SOURCE%\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fx"                   "%SOURCE%\fx\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fxscripts"            "%SOURCE%\fxscripts\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\nativeterminal"       "%SOURCE%\nativeterminal\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fragments"            "%SOURCE%\fragments\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fragments\packages"   "%SOURCE%\fragments\packages\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fragments\perks"      "%SOURCE%\fragments\perks\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fragments\quests"     "%SOURCE%\fragments\quests\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fragments\scenes"     "%SOURCE%\fragments\scenes\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fragments\terminals"  "%SOURCE%\fragments\terminals\*.pex"
CHAMPOLLION.EXE -r -d -p "%DESTINATION%\fragments\topicinfos" "%SOURCE%\fragments\topicinfos\*.pex"

echo.
CHAMPOLLION.EXE --version
echo.
pause
