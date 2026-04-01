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

:: Save script directory (server folder) before any CALL statements
SET "SCRIPT_DIR=%~dp0"
:: Parent directory (dist folder)
SET "DIST_DIR=%~dp0.."

:: Main script execution starts here
GOTO :main

:: Function for logging with timestamps
:log
ECHO [%date% %time%] %~1
EXIT /B 0

:main
CALL :log "Starting Python setup"

:: Check for --clean argument
SET CLEAN_FLAG=0
IF NOT "%~1"=="" (
  IF /I "%~1"=="--clean" (
    SET CLEAN_FLAG=1
  )
)

IF %CLEAN_FLAG%==1 (
  CALL :log "Cleaning up virtual environments..."
  IF EXIST "%TEMP%\cpn" (
    RMDIR /S /Q "%TEMP%\cpn"
    CALL :log "Virtual environments removed successfully"
  ) ELSE (
    CALL :log "No virtual environments found to clean"
  )
) ELSE (
  ECHO.
  ECHO Tip: If you encounter errors during execution, run with --clean flag ^(as the first parameter^^!^)
  ECHO This will remove corrupted virtual environments and create fresh ones.
  ECHO.
)

:: Build PYTHON_ARGS with --clean consumed (stripped out)
SET "PYTHON_ARGS="
FOR %%A IN (%*) DO (
  IF /I NOT "%%~A"=="--clean" (
    SET "PYTHON_ARGS=!PYTHON_ARGS! %%A"
  )
)

:: Check for Python environment
IF DEFINED BPMN4S_PYTHON (
  ECHO *-----------------------------------------* >&2
  ECHO * BPMN4S_PYTHON variable is used.         * >&2
  ECHO *-----------------------------------------* >&2
  ECHO.
) ELSE (
  ECHO *-----------------------------------------* >&2
  ECHO * Standard python.exe will be used.       * >&2
  ECHO *-----------------------------------------* >&2
  ECHO.
  SET BPMN4S_PYTHON=python.exe
)

:: Check if Python exists
IF EXIST "%BPMN4S_PYTHON%" (
  REM Full path exists, OK
) ELSE (
  WHERE "%BPMN4S_PYTHON%" >NUL 2>&1
  IF !ERRORLEVEL! NEQ 0 (
    CALL :log "Error: Python executable not found at '%BPMN4S_PYTHON%'"
    EXIT /B 1
  )
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
  
  :: Ensure virtual environment exists and is healthy
  IF EXIST "!TEMP_ENV!" IF NOT EXIST "!VENV_PYTHON!" (
    CALL :log "Warning: Virtual environment is incomplete, recreating..."
    RMDIR /S /Q "!TEMP_ENV!" >NUL 2>&1
  )
  IF EXIST "!TEMP_ENV!" IF NOT EXIST "!TEMP_ENV!\pyvenv.cfg" (
    CALL :log "Warning: Virtual environment appears corrupted, recreating..."
    RMDIR /S /Q "!TEMP_ENV!" >NUL 2>&1
  )
  
  IF NOT EXIST "!TEMP_ENV!" (
    CALL :log "Creating virtual environment..."
    
    :: Create parent directories if needed
    IF NOT EXIST "!TEMP!\cpn\!python_version!" (
      MKDIR "!TEMP!\cpn\!python_version!" >NUL 2>&1
    )
    
    "%BPMN4S_PYTHON%" -m venv "!TEMP_ENV!"
    IF !ERRORLEVEL! NEQ 0 (
      CALL :log "Error: Failed to create virtual environment"
      EXIT /B 1
    )
    
    "!VENV_PYTHON!" -m pip install --upgrade pip >NUL 2>&1
  )
)

:: Install/update packages from requirements.txt
CALL :log "Ensuring required packages are installed..."
"!VENV_PYTHON!" -m pip install --quiet --timeout 60 -r "!SCRIPT_DIR!requirements.txt"
IF !ERRORLEVEL! NEQ 0 (
  CALL :log "Error: Failed to install requirements"
  EXIT /B 1
)

:: Export variables for caller to use
ENDLOCAL & SET "VENV_PYTHON=%VENV_PYTHON%" & SET "PYTHON_ARGS=%PYTHON_ARGS%"
EXIT /B 0
