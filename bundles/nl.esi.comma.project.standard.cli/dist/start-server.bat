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
SETLOCAL EnableDelayedExpansion

:: Save script directory before any CALL statements (important when called from another batch)
SET "SCRIPT_DIR=%~dp0"

:: Main script execution starts here
GOTO :main

:: Function for logging with timestamps
:log
ECHO [%date% %time%] %~1
EXIT /B 0

:main
CALL :log "Starting script execution"

:: Check for --clean and --regression-test arguments anywhere in parameters and consume them
SET CLEAN_FLAG=0
SET REGRESSION_TEST_FLAG=0
SET "ARGS="
:parse_args
IF NOT "%~1"=="" (
  IF /I "%~1"=="--clean" (
    SET CLEAN_FLAG=1
  ) ELSE IF /I "%~1"=="--regression-test" (
    SET REGRESSION_TEST_FLAG=1
  ) ELSE (
    :: Preserve other arguments with quotes if they contain spaces
    IF DEFINED ARGS (
      SET "ARGS=!ARGS! %~1"
    ) ELSE (
      SET "ARGS=%~1"
    )
  )
  SHIFT
  GOTO parse_args
)

IF %CLEAN_FLAG%==1 (
  CALL :log "Cleaning up virtual environments..."
  IF EXIST "%TEMP%\cpn" (
    RMDIR /S /Q "%TEMP%\cpn"
    CALL :log "Virtual environments removed successfully"
  ) ELSE (
    CALL :log "No virtual environments found to clean"
  )
  CALL :log "Continuing with regular execution..."
) ELSE (
  ECHO.
  ECHO Tip: If you encounter errors during execution, run the script with --clean flag:
  ECHO   start-server.bat --clean
  ECHO This will remove corrupted virtual environments and create fresh ones.
  ECHO.
)

:: Check for Python environment
IF DEFINED BPMN4S_PYTHON (
  ECHO *-----------------------------------------* >&2
  ECHO * BPMN4S_PYTHON variable is used          * >&2
  ECHO *-----------------------------------------* >&2
  ECHO:
) ELSE (
  ECHO *-----------------------------------------* >&2
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
    
    :: Create parent directories if needed
    IF NOT EXIST "!TEMP!\cpn\!python_version!" (
      MKDIR "!TEMP!\cpn\!python_version!" >NUL 2>&1
    )
    
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
    "!VENV_PYTHON!" -m pip install --timeout 60 -r "!SCRIPT_DIR!server\requirements.txt"
    IF %ERRORLEVEL% NEQ 0 (
      CALL :log "Error: Failed to install requirements"
      EXIT /B 1
    )
    
    :: Save requirements hash for future comparison
    CERTUTIL -hashfile "!SCRIPT_DIR!server\requirements.txt" MD5 | FINDSTR /V ":" > "!TEMP_ENV!\req_hash.txt"
  ) ELSE (
    :: Check if requirements have changed
    CALL :log "Checking if requirements have changed..."
    CERTUTIL -hashfile "!SCRIPT_DIR!server\requirements.txt" MD5 | FINDSTR /V ":" > "%TEMP%\req_hash.txt"
    SET /p NEW_HASH=<"%TEMP%\req_hash.txt"
    
    IF EXIST "!TEMP_ENV!\req_hash.txt" (
      SET /p OLD_HASH=<"!TEMP_ENV!\req_hash.txt"
    ) ELSE (
      SET "OLD_HASH="
    )
    
    IF NOT "!NEW_HASH!"=="!OLD_HASH!" (
      CALL :log "Requirements have changed, updating packages..."
      
      :: Verify venv integrity before updating
      IF NOT EXIST "!TEMP_ENV!\pyvenv.cfg" (
        CALL :log "Warning: Virtual environment appears corrupted, recreating..."
        RMDIR /S /Q "!TEMP_ENV!" >NUL 2>&1
        "%BPMN4S_PYTHON%" -m venv "!TEMP_ENV!"
        IF %ERRORLEVEL% NEQ 0 (
          CALL :log "Error: Failed to recreate virtual environment"
          EXIT /B 1
        )
        "!VENV_PYTHON!" -m pip install --upgrade pip >NUL 2>&1
      )
      
      "!VENV_PYTHON!" -m pip install --timeout 60 -r "!SCRIPT_DIR!server\requirements.txt"
      IF %ERRORLEVEL% NEQ 0 (
        CALL :log "Error: Failed to update requirements"
        EXIT /B 1
      )
      ECHO !NEW_HASH! > "!TEMP_ENV!\req_hash.txt"
    )
    
    :: Cleanup temporary hash file
    DEL "%TEMP%\req_hash.txt" >NUL 2>&1
  )
)

IF %REGRESSION_TEST_FLAG%==1 (
  SET python_file=!SCRIPT_DIR!server\CPNRegressionTest.py
  CALL :log "Running regression tests: '!python_file!'"
) ELSE (
  SET python_file=!SCRIPT_DIR!server\CPNServer.py
  CALL :log "Starting simulator: '!python_file!'"
)

:: Set PATH to prioritize venv Python
SET "PATH=!TEMP_ENV!\Scripts;!PATH!"
CALL :log "PATH updated to prioritize venv Python: '!TEMP_ENV!\Scripts'"

ECHO.
IF %REGRESSION_TEST_FLAG%==1 (
  ECHO *-----------------------------------------*
  ECHO * Running regression tests...             *
  ECHO *-----------------------------------------*
) ELSE (
  ECHO *-----------------------------------------*
  ECHO * Simulator is now running...             *
  ECHO * Press Ctrl+C to exit the simulator      *
  ECHO *-----------------------------------------*
)
ECHO.

"!VENV_PYTHON!" "!python_file!" !ARGS!
SET EXIT_CODE=%ERRORLEVEL%

IF %EXIT_CODE% NEQ 0 (
  IF %REGRESSION_TEST_FLAG%==1 (
    CALL :log "Error: Regression tests exited with code %EXIT_CODE%"
  ) ELSE (
    CALL :log "Error: Simulator exited with code %EXIT_CODE%"
  )
)

IF NOT %REGRESSION_TEST_FLAG%==1 (
  PAUSE
)
EXIT /B %EXIT_CODE%