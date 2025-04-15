@ECHO OFF
SETLOCAL

FOR /F "delims=" %%i IN ("%~dp0") DO (
  set script_drive=%%~di
  set script_path=%%~pi
)

set simulator_file=%script_drive%%script_path%\simulator\CPNServer.py
echo Starting simulator:  %simulator_file%

python "%simulator_file%"

pause
