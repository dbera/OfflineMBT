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
SETLOCAL EnableDelayedExpansion

:: Main script execution starts here
GOTO :main

:: Function for logging with timestamps
:log
ECHO [%date% %time%] %~1
EXIT /B 0

:main
CALL :log "Starting script execution"

:: Check for --clean argument
IF /I "%~1"=="--clean" (
  CALL :log "Cleaning up virtual environments..."
  IF EXIST "%TEMP%\cpn" (
    RMDIR /S /Q "%TEMP%\cpn"
    CALL :log "Virtual environments removed successfully"
  ) ELSE (
    CALL :log "No virtual environments found to clean"
  )
  CALL :log "Continuing with regular execution..."
)

:: Check for Python environment
IF NOT DEFINED BPMN4S_PYTHON (
  ECHO *-----------------------------------------* >&2
  ECHO * BPMN4S_PYTHON variable is NOT defined!  * >&2
  ECHO * Standard python.exe will be used.       * >&2
  ECHO *-----------------------------------------* >&2
  ECHO:
  SET BPMN4S_PYTHON=python.exe
)

:: Check if Python exists
WHERE "%BPMN4S_PYTHON%" >NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
  CALL :log "Error: Python executable not found at '%BPMN4S_PYTHON%'"
  EXIT /B 1
)

:: Get Python version
FOR /F "tokens=2 delims= " %%a IN ('"%BPMN4S_PYTHON%" --version 2^>^&1') DO (
  SET "full_version=%%a"
)

:: Extract major.minor.patch version
FOR /F "tokens=1,2,3 delims=." %%a IN ("!full_version!") DO (
  SET "python_version=%%a.%%b"
  IF NOT "%%c"=="" SET "python_version=!python_version!.%%c"
  SET "py_major=%%a"
  SET "py_minor=%%b"
)

:: Check Python version compatibility
IF !py_major! LSS 3 (
  CALL :log "Error: Python 3.x is required, but version !python_version! was found"
  EXIT /B 1
)

IF !py_major!==3 IF !py_minor! LSS 6 (
  CALL :log "Warning: Python 3.6+ is recommended, but version !python_version! was found"
)

CALL :log "Using python version: !python_version!"
CALL :log "Using python environment: '%BPMN4S_PYTHON%'"

:: Check if BPMN4S_PYTHON is already a virtual environment
"%BPMN4S_PYTHON%" -c "import os, sys; print('VIRTUAL_ENV' in os.environ)" > "%TEMP%\is_venv.txt"
SET /p IS_VENV=<"%TEMP%\is_venv.txt"
DEL "%TEMP%\is_venv.txt"

IF "!IS_VENV!"=="True" (
  CALL :log "BPMN4S_PYTHON is already a virtual environment, using it directly"
  SET VENV_PYTHON=%BPMN4S_PYTHON%
) ELSE (
  SET TEMP_ENV=%TEMP%\cpn\!python_version!\.venv
  CALL :log "Using virtual environment: '!TEMP_ENV!'"
  SET VENV_PYTHON=!TEMP_ENV!\Scripts\python.exe
  
  IF NOT EXIST "!TEMP_ENV!" (
    CALL :log "Setting up virtual environment..."
    
    :: Check internet connectivity
    PING -n 1 pypi.org >NUL 2>&1
    IF %ERRORLEVEL% NEQ 0 (
      CALL :log "Warning: Cannot reach pypi.org. Package installation may fail."
    )
    
    "%BPMN4S_PYTHON%" -m venv "!TEMP_ENV!"
    IF %ERRORLEVEL% NEQ 0 (
      CALL :log "Error: Failed to create virtual environment"
      EXIT /B 1
    )
    
    CALL :log "Installing packages..."
    "!VENV_PYTHON!" -m pip install --upgrade pip
    "!VENV_PYTHON!" -m pip install --timeout 60 -r "%~dp0requirements.txt"
    IF %ERRORLEVEL% NEQ 0 (
      CALL :log "Error: Failed to install requirements"
      EXIT /B 1
    )
    
    :: Save requirements hash for future comparison
    CERTUTIL -hashfile "%~dp0requirements.txt" MD5 | FINDSTR /V ":" > "!TEMP_ENV!\req_hash.txt"
  ) ELSE (
    :: Check if requirements have changed
    CALL :log "Checking if requirements have changed..."
    CERTUTIL -hashfile "%~dp0requirements.txt" MD5 | FINDSTR /V ":" > "%TEMP%\req_hash.txt"
    SET /p NEW_HASH=<"%TEMP%\req_hash.txt"
    
    IF EXIST "!TEMP_ENV!\req_hash.txt" (
      SET /p OLD_HASH=<"!TEMP_ENV!\req_hash.txt"
    ) ELSE (
      SET "OLD_HASH="
    )
    
    IF NOT "!NEW_HASH!"=="!OLD_HASH!" (
      CALL :log "Requirements have changed, updating packages..."
      "!VENV_PYTHON!" -m pip install --timeout 60 -r "%~dp0requirements.txt"
      ECHO !NEW_HASH! > "!TEMP_ENV!\req_hash.txt"
    )
  )
)

SET simulator_file=%~dp0simulator\CPNServer.py
CALL :log "Starting simulator: '!simulator_file!'"
ECHO.
ECHO *-----------------------------------------*
ECHO * Simulator is now running...             *
ECHO * Press Ctrl+C to exit the simulator      *
ECHO *-----------------------------------------*
ECHO.

"!VENV_PYTHON!" "!simulator_file!"
SET EXIT_CODE=%ERRORLEVEL%

IF %EXIT_CODE% NEQ 0 (
  CALL :log "Error: Simulator exited with code %EXIT_CODE%"
)

PAUSE
EXIT /B %EXIT_CODE%