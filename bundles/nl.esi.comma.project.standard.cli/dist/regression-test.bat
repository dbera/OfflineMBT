@REM
@REM Copyright (c) 2024, 2025 TNO-ESI
@REM
@REM See the NOTICE file(s) distributed with this work for additional
@REM information regarding copyright ownership.
@REM
@REM This program and the accompanying materials are made available
@REM under the terms of the MIT License which is available at
@REM https://opensource.org/licenses/MIT
@REM
@REM SPDX-License-Identifier: MIT
@REM

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
set python_file=%script_drive%%script_path%simulator\CPNRegressionTest.py

%BPMN4S_PYTHON% "%python_file%" %*

ENDLOCAL
