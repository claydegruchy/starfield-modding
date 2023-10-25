@REM @echo off

@REM print the 1st command line parameter passed to the batch file
echo "PARAM: %1"


set IMPORT=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\Base
set OUTPUT=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts
@REM set FLAGS=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\User\Starfield_Papyrus_Flags.flg
set SCRIPTPATH=C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\User
set SCRIPTNAME=bescript.psc

rem Notepad++ needs current working directory to be where Caprica.exe is 
cd "%SCRIPTPATH%"

rem %1 is the first command line parameter passed which will override hardcoded SCRIPTNAME Notepad++ passes $(FILE_NAME)
if [%1] == [] goto START
echo "A param has been passed in 1: '%1'"
set SCRIPTNAME=%1
@REM print out the script name
echo SCRIPTNAME: "%SCRIPTNAME%"

@REM %2 is the second command line parameter passed which will override hardcoded OUTPUT
if [%2] == [] goto START
echo "A param has been passed in 2: '%2'"
set OUTPUT=%2
@REM print out the output path
echo OUTPUT: "%OUTPUT%"

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
