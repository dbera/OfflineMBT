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

:: Delegate to start-server.bat with --regression-test flag to reuse venv setup
:: Use absolute path to ensure correct directory resolution regardless of CWD
CALL "%~dp0start-server.bat" --regression-test %*

ENDLOCAL
