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
CALL :log "Starting server script execution"

:: Call setup-python.bat to handle Python environment setup, passing all arguments
CALL "!SCRIPT_DIR!server\setup-python.bat" %*
IF %ERRORLEVEL% NEQ 0 (
  CALL :log "Error: Python setup failed"
  EXIT /B 1
)

SET python_file=!SCRIPT_DIR!server\CPNServer.py
CALL :log "Starting server: '!python_file!'"

:: Set PATH to prioritize venv Python
SET "PATH=!TEMP_ENV!\Scripts;!PATH!"
CALL :log "PATH updated to prioritize venv Python: '!TEMP_ENV!\Scripts'"

ECHO.
ECHO *-----------------------------------------*
ECHO * CPN Server is now running...            *
ECHO * Press Ctrl+C to exit the server         *
ECHO *-----------------------------------------*
ECHO.

"!VENV_PYTHON!" "!python_file!" %*
SET EXIT_CODE=%ERRORLEVEL%

IF %EXIT_CODE% NEQ 0 (
  CALL :log "Error: Server exited with code %EXIT_CODE%"
)

PAUSE
EXIT /B %EXIT_CODE%