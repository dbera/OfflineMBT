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

setlocal EnableDelayedExpansion

:: Get Python version and store it in a variable
for /f "tokens=2" %%a in ('python --version 2^>^&1') do (
    set "full_version=%%a"
)

:: Extract only digits and dots from the version
set "python_version="
for /f "delims=" %%a in ('echo %full_version% ^| findstr /r "[0-9\.]"') do (
    set "raw_version=%%a"
)

:: Clean the version to contain only digits and dots
set "python_version="
for /L %%i in (0,1,100) do (
    if "!raw_version:~%%i,1!"=="" goto :done
    set "char=!raw_version:~%%i,1!"
    if "!char!"=="." (
        set "python_version=!python_version!."
    ) else (
        echo !char! | findstr /r "[0-9]" >nul
        if not errorlevel 1 (
            set "python_version=!python_version!!char!"
        )
    )
)

:done
:: Set the environment variable
set PYTHON_VERSION=%python_version%

:: Display the result
ECHO # Using python version: %PYTHON_VERSION%


ECHO # Using python environment: "%BPMN4S_PYTHON%"
set TEMP_ENV=%TEMP%\cpn\%PYTHON_VERSION%\.venv

ECHO # Using virtual  environment: %TEMP_ENV%
set VENV_PYTHON=%TEMP_ENV%\Scripts\python.exe

if not exist "%TEMP_ENV%" (
    call %BPMN4S_PYTHON% -m venv %TEMP_ENV%
    %VENV_PYTHON% -m pip install --upgrade pip
    %VENV_PYTHON% -m pip install -r "%~dp0requirements.txt"
)
 
ECHO # Using virtual  environment: %TEMP_ENV%

set simulator_file=%~dp0simulator\CPNServer.py
ECHO # Starting simulator:  "%simulator_file%" 

%VENV_PYTHON% "%simulator_file%"

ENDLOCAL

pause

