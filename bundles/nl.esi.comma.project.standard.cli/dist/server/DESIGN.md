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

This class replaces the functionality that was previously implemented in the Java `WebSocketLspConnection` class.

### CPNServer (CPNServer.py)

The main Flask-based server that:

- Serves the web application (BPMN4S editor UI)
- Routes LSP-related requests to the proxy
- Manages static file serving with configurable paths
- Handles port allocation and server lifecycle

## Key Design Decisions

### Static File Path Configuration

The `--static-path` command-line argument allows users to specify a custom directory for serving static web files. By default, the BPMN4S editor serves static files (HTML, CSS, JavaScript) from the `web` directory.

Usage:
```
start-server.bat --static-path "C:\path\to\custom\static"
```

This enables:

- **Development Flexibility**: Developers can point to the public folder of an alternative webapp implementation during testing
- **Customization**: Users can serve custom static content without modifying the codebase

### Port Configuration

- **Default Port**: The server runs on port 5000 by default
- **Command-line Override**: The port can be specified via command-line arguments
- **Future Enhancement**: Auto-detection of free ports (starting from 5000) is a planned feature to allow multiple instances to run simultaneously

### Socket Timeout

A 30-second socket timeout (`SOCKET_TIMEOUT = 30.0`) is configured for all LSP socket communications to prevent indefinite hangs on unresponsive connections.

## Development Details

### Python Environment

The server uses a Python virtual environment for dependency isolation. By default, the environment is created in the system's temp directory and can be cleaned up with the `--clean` flag.

#### Clean Flag

The `--clean` flag can be used to reset the Python environment:

```
start-server.bat --clean
```

This flag will:
- Remove the temporary Python virtual environment from the system's temp directory
- Force a fresh installation of all Python dependencies on the next run
- Useful for troubleshooting environment-related issues or when dependencies have been updated

### Custom Python Installation

Users can specify a custom Python interpreter via the `BPMN4S_PYTHON` environment variable. The startup script will detect if the specified Python path is already a virtual environment and use it directly.

## Future Enhancements

1. **Auto Port Detection**: Implement automatic free port detection starting from port 5000, allowing multiple BPMN4S instances to run concurrently
2. **Webapp Restructuring**: Consider moving webapp files to a dedicated subfolder (e.g., `webapp/`) to maintain cleaner directory organization
3. **Directory Structure**: The `server` directory contains all server-side components, reflecting its expanded responsibilities beyond pure simulation
