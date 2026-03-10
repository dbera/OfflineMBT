# Server Design Documentation

## Overview

This document describes the design decisions and architecture of the BPMN4S server.

## Architecture

### One Server Approach

The server uses a unified architecture that serves both the Language Server Protocol (LSP) and the web application from a single Flask server. This consolidation simplifies deployment and eliminates the need for multiple server processes.

## Components

### LSPProxy (LSPProxy.py)

The `LSPProxy` class is a socket-based proxy that acts as a bridge between WebSocket messages and the Java LSP subprocess. It performs the following functions:

- **Protocol Translation**: Converts WebSocket messages into plain socket messages for communication with the Java LSP subprocess, and vice-versa
- **Connection Management**: Handles the lifecycle of connections to the LSP subprocess
- **Message Framing**: Implements proper Content-Length message framing according to the Language Server Protocol (LSP) specification
- **Socket Management**: Manages socket timeouts and handles socket-level communication with a 30-second receive timeout

### CPNServer (CPNServer.py)

The main Flask-based server that:

- Serves the web application (BPMN4S editor UI)
- Automatically detects and binds to an available port (5000-5009 range)
- Routes LSP-related requests to the LSPProxy
- Manages static file serving with configurable paths
- Launches the Java LSP subprocess on a dynamically allocated socket port (OS-assigned)
- Opens the browser automatically to the correct URL
- Handles server lifecycle and graceful shutdown

## Key Design Decisions

### Web Path Configuration

The `--web-path` command-line argument allows users to specify a custom directory for serving static web files. By default, the BPMN4S editor serves static files (HTML, CSS, JavaScript) from the `web` directory.

Usage:
```
start-server.bat --web-path "C:\path\to\custom\web"
```

This enables:

- **Development Flexibility**: Developers can point to the public folder of an alternative webapp implementation during testing
- **Customization**: Users can serve custom static content without modifying the codebase

### Debug Logging

The `--debug` flag enables debug-level logging to help troubleshoot issues:

```
start-server.bat --debug
```

When enabled, debug messages will show:
- WebSocket message exchanges (in/out)
- Detailed connection information
- Internal processing steps

Debug logging is useful for:
- Troubleshooting LSP communication issues
- Understanding message flow during development
- Diagnosing connection problems

### Port Configuration

- **Automatic Port Detection**: The server automatically finds a free port in the range 5000-5009
- **Windows Support**: On Windows, uses `SO_EXCLUSIVEADDRUSE` to ensure the port is truly available
- **Unix Support**: On Unix/Linux systems, uses `SO_REUSEADDR` for port reuse
- **Error Handling**: If no free ports are available in the range, the server exits with an error message
- **URL Display**: The server logs the actual URL on startup (e.g., `http://localhost:5000/` or `http://localhost:5001/` depending on port availability)

The server uses the first available port it finds, allowing multiple instances to run simultaneously on the same machine.

### Regression Testing

Regression testing is run via a separate `regression-test.bat` script:

```
regression-test.bat model.bpmn scenario.json
```

This file:
- Reuses the same virtual environment setup and codebase as the server
- Avoids code duplication between server startup and regression testing
- Allows regression tests to be run independently with the same infrastructure

### CPNRegressionTest.py Arguments

CPNRegressionTest.py supports two modes with the following argument structure:

**Global Arguments** (apply to both modes):
- `--base-url URL`: Server URL (default: http://127.0.0.1:5000)
- `--timeout N`: HTTP timeout in seconds (default: 60)
- `--verbose`: Enable detailed per-step logs

**Mode 1: regression-test** (default if no subcommand specified)
```
CPNRegressionTest.py [global-args] [regression-test] <model.bpmn> <scenario1.json> [scenario2.json ...]
```
- `<model.bpmn>`: Path to BPMN model
- `<scenario1.json> ...`: One or more test scenario JSON files

Note: The `regression-test` subcommand is optional. If omitted, it's automatically inserted before the first non-flag argument.

**Mode 2: testgen**
```
CPNRegressionTest.py [global-args] testgen <model.bpmn> [--num-tests N] [--depth-limit N] [--out path.zip]
```
- `<model.bpmn>`: Path to BPMN model
- `--num-tests N`: Number of test cases to generate (default: 1)
- `--depth-limit N`: Search depth limit (default: 1000)
- `--out path.zip`: Custom output path for generated ZIP file (optional)

**Examples**:
```
# Regression test (explicit)
CPNRegressionTest.py regression-test model.bpmn scenario1.json scenario2.json

# Regression test (implicit - regression-test auto-inserted)
CPNRegressionTest.py model.bpmn scenario1.json

# Regression test with global flags
CPNRegressionTest.py --verbose --base-url http://localhost:5001 model.bpmn scenario.json

# Test generation
CPNRegressionTest.py testgen model.bpmn --num-tests 5 --out tests.zip

# With global flags
CPNRegressionTest.py --verbose --base-url http://localhost:5001 model.bpmn scenario.json
CPNRegressionTest.py --verbose testgen model.bpmn --num-tests 3
```

## Development Details

### Startup Infrastructure

The startup infrastructure has been refactored into separate, focused batch scripts:

**setup-python.bat** (server/setup-python.bat):
- Handles Python virtual environment creation and management
- Checks/installs dependencies from requirements.txt
- Supports `--clean` flag to reset the environment
- Exports `VENV_PYTHON` and `TEMP_ENV` variables for callers

**start-server.bat**:
- Calls setup-python.bat to prepare the Python environment
- Starts CPNServer.py
- Passes all command-line arguments to CPNServer.py

**regression-test.bat**:
- Calls setup-python.bat to prepare the Python environment  
- Starts CPNRegressionTest.py
- Passes all command-line arguments to CPNRegressionTest.py

### Batch Script Flags

**Flags consumed by setup-python.bat** (not passed to Python):
- `--clean`: Removes the temporary Python virtual environment from `%TEMP%\cpn\<version>\.venv`

**Python Application Flags** (passed to the Python application):
- `--web-path`: Specifies a custom directory for serving static files (CPNServer.py only)
- `--debug`: Enables debug-level logging for troubleshooting (CPNServer.py only)
- `--base-url`: Server URL for regression testing (CPNRegressionTest.py only)
- `--timeout`: HTTP timeout in seconds (CPNRegressionTest.py only)
- `--verbose`: Enable detailed per-step logs (CPNRegressionTest.py only)

Example usage:
```
start-server.bat --clean --debug
start-server.bat --web-path "C:\custom\web"
regression-test.bat model.bpmn scenario.json
regression-test.bat --clean --base-url http://localhost:5001 model.bpmn scenario.json
```

### Custom Python Installation

Users can specify a custom Python interpreter via the `BPMN4S_PYTHON` environment variable. The startup script will detect if the specified Python path is already a virtual environment and in that case use it directly.