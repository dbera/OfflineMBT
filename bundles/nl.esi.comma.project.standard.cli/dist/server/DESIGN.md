# Server Design Documentation

## Overview

This document describes the design decisions and architecture of the BPMN4S server.

## Architecture

### One Server Approach (FastAPI + ASGI)

The server uses a unified architecture that serves both the Language Server Protocol (LSP) and the web application from a single FastAPI server (via uvicorn, an ASGI server). This consolidation simplifies deployment and eliminates the need for multiple server processes. Both HTTP and WebSocket endpoints are served on the same port.

## Components

### WebSocket LSP Proxy (in CPNServer.py)

The `/lsp` WebSocket endpoint acts as an async bidirectional bridge between browser clients and the Java LSP subprocess. Each browser WebSocket connection gets its own dedicated upstream connection to the Java LSP backend. It performs the following functions:

- **Async Protocol Translation**: Converts WebSocket messages to/from the Java LSP subprocess via the `websockets` library
- **Connection Management**: Handles the lifecycle of connections to both the browser client and the LSP subprocess
- **Concurrent Forwarding**: Uses `asyncio.wait()` to run client→backend and backend→client message streams concurrently, with automatic cleanup when either direction closes
- **Error Handling**: Gracefully handles WebSocket disconnects and LSP backend failures without blocking the server

### CPNServer (CPNServer.py)

The main FastAPI-based server that:

- Serves the web application (BPMN4S editor UI) via `StaticFiles` middleware
- Automatically detects and binds to an available port (5000-5009 range)
- Proxies LSP connections via the `/lsp` WebSocket endpoint
- Manages static file serving with configurable paths
- Launches the Java LSP subprocess on a dynamically allocated WebSocket port (OS-assigned)
- Opens the browser automatically to the correct URL
- Handles server lifecycle and graceful shutdown via the `lifespan` async context manager
- All endpoints run asynchronously on uvicorn (ASGI)

### Subprocess Output Logging

All Java subprocess output (stdout/stderr) is forwarded to the Python logger:

- **LSP subprocess** (long-running `Popen`): Two background daemon threads continuously drain `stdout` and `stderr`, logging each line at `DEBUG` level with `LSP stdout:` / `LSP stderr:` prefixes. This prevents the OS pipe buffers (~4 KB on Windows) from filling up, which would otherwise **deadlock the Java process** — the root cause of the "Request timeout 30000ms" LSP hangs.
- **Build/test subprocesses** (short-lived `subprocess.run`): Output from `build_and_load_model` and `generate_tests` is logged at `DEBUG` level after completion (`build_and_load_model stdout:`, `generate_tests stderr:`, etc.).

All subprocess output is visible when running with `--debug`.

## Key Design Decisions

### Web Path Configuration

The `--web-path` command-line argument allows users to specify a custom directory for serving static web files. By default, the BPMN4S editor serves static files (HTML, CSS, JavaScript) from the `web` directory.

Usage:
```
start-server.bat --web-path "C:\path\to\custom\web"
```

### Server Path Configuration

The `--server-path` command-line argument allows users to specify a custom directory for the server resources, including the Java LSP executable and the BPMN4S toolchain JAR. By default, the server resources are located relative to the server directory.

Usage:
```
start-server.bat --server-path "C:\path\to\server"
```

This enables:

- **Custom Deployments**: Users can deploy server resources to alternative locations outside the default installation directory
- **Isolation**: Separates web content (`--web-path`) from server infrastructure (`--server-path`)

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
- `--server-path`: Specifies a custom directory for server resources including Java LSP and toolchain JAR (CPNServer.py only)
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

### Dual-Mode Import (Script vs Package)

CPNServer.py supports running both as a standalone script and as a Python package module:

```python
try:
    from . import CPNUtils as utils   # when run as package (-m server.CPNServer)
except ImportError:
    import CPNUtils as utils          # when run directly (python server/CPNServer.py)
```

This is needed because:
- `start-server.bat` runs `python server/CPNServer.py` (script mode, `server/` is on `sys.path`)
- The `CPNServer_cov` VS Code launch config runs via `coverage run server/CPNServer.py` 
- A `server/__init__.py` file (empty) is present to allow Python to treat `server/` as a package when needed

### Code Coverage

The `CPNServer_cov` launch configuration runs the server under `coverage`:

```
coverage run --source=server server/CPNServer.py [args...]
```

Note: It uses `coverage run server/CPNServer.py` (not `coverage run -m server.CPNServer`), because the `-m` form sets `__name__` to `"server.CPNServer"` instead of `"__main__"`, which would skip the entire startup block.

After a coverage run, generate the HTML report with:
```
python -m coverage html
start htmlcov\index.html
```

### Custom Python Installation

Users can specify a custom Python interpreter via the `BPMN4S_PYTHON` environment variable. The startup script will detect if the specified Python path is already a virtual environment and in that case use it directly.

