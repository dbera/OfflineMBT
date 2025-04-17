@ECHO OFF
SETLOCAL

IF not defined BPMN4S_PYTHON (
  ECHO *-----------------------------------------* >&2
  ECHO * BPMN4S_PYTHON variable is NOT defined!  * >&2
  ECHO * Standard python.exe will be used.       * >&2
  ECHO *-----------------------------------------* >&2
  ECHO:
  set BPMN4S_PYTHON=python.exe
)
 
ECHO # Using python environment: "%BPMN4S_PYTHON%"

FOR /F "delims=" %%i IN ("%~dp0") DO (
  set script_drive=%%~di
  set script_path=%%~pi
)
set simulator_file=%script_drive%%script_path%simulator\CPNServer.py
ECHO # Starting simulator:  "%simulator_file%" 
ECHO:

%BPMN4S_PYTHON% "%simulator_file%"

ENDLOCAL

pause