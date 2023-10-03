@echo off

rem skk.50@outlook.com September 2023
rem CapricaCompile.cmd

set IMPORT=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\Base
set OUTPUT=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts
@REM set FLAGS=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\User\Starfield_Papyrus_Flags.flg
set SCRIPTPATH=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\User
set SCRIPTNAME=SKK_ConsoleUtilityScript.psc

rem Notepad++ needs current working directory to be where Caprica.exe is 
cd "%SCRIPTPATH%"

rem %1 is the first command line parameter passed which will override hardcoded SCRIPTNAME Notepad++ passes $(FILE_NAME)
if [%1] == [] goto START
set SCRIPTNAME=%1

:START
cls
echo ****************************************************************
echo Caprica Starfield DEBUG compile 002
echo.

if [%SCRIPTNAME%] == [] goto GETSCRIPTNAME
goto COMPILE

:GETSCRIPTNAME
 set /p SCRIPTNAME="SCRIPTFILE Name (include.psc): "
 echo.

:COMPILE
 set SCRIPTFILE=%SCRIPTPATH%\%SCRIPTNAME%

 echo IMPORT:     "%IMPORT%"
 echo OUTPUT:     "%OUTPUT%"
@REM  echo FLAGS:      "%FLAGS%"
 echo SCRIPTPATH: "%SCRIPTPATH%"
 echo SCRIPTNAME: "%SCRIPTNAME%"
 echo SCRIPTFILE: "%SCRIPTFILE%" 
 echo.

Caprica.exe --game starfield --import "%IMPORT%"  --output "%OUTPUT%" "%SCRIPTFILE%" 

:END
 echo.
