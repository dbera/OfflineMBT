@ECHO OFF
SETLOCAL

echo Using python environment: %BPMN4S_PYTHON%

IF not defined BPMN4S_PYTHON (
  ECHO BPMN4S_PYTHON variable is NOT defined >&2
  pause
  exit
)

FOR /F "delims=" %%i IN ("%~dp0") DO (
  set script_drive=%%~di
  set script_path=%%~pi
)
set simulator_file=%script_drive%%script_path%\simulator\CPNServer.py
echo Starting simulator:  %simulator_file%

%BPMN4S_PYTHON% "%simulator_file%"

pause