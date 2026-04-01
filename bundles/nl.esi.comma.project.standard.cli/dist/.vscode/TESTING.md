# Testing Guide

All commands and setup described in this guide should be executed from the parent `dist` folder (the directory containing this `.vscode` folder).

## Development Environment Setup

To test the server using VS Code, set up a local Python virtual environment in the `dist` folder:

**Create Virtual Environment:**

From the `dist` folder, run:
```
python -m venv .venv
```

**Activate Virtual Environment:**

On Windows (PowerShell):
```
.\.venv\Scripts\Activate.ps1
```

On Windows (Command Prompt):
```
.venv\Scripts\activate.bat
```

On Unix/Linux/macOS:
```
source .venv/bin/activate
```

**Install Dependencies:**

After activating the virtual environment, install all required packages:
```
pip install -r requirements.txt
```

This installs al requirements as specified in `requirements.txt`

**VS Code Python Interpreter:**

After setup, VS Code will automatically detect the virtual environment. You can verify the interpreter selection:
1. Open the Command Palette (Ctrl+Shift+P)
2. Type "Python: Select Interpreter"
3. Choose `.\.venv` from the list

Once configured, you can use VS Code's debugging features with the `CPNServer` and `CPNServer_cov` debug configurations, which will use the virtual environment's Python interpreter.

**Note:** The launch configuration assumes the `bpmn4s-editor` directory is located at the root of the disk (e.g., `/bpmn4s-editor/`). If your installation uses a different path, update the `--web-path` argument in the launch configuration accordingly.

**Alternative: Using VS Code's Create Environment Feature**

Instead of manual commands, you can use VS Code's built-in environment creation:

1. Open the Command Palette (Ctrl+Shift+P)
2. Type "Python: Create Environment"
3. Select "Venv"
4. Choose the Python interpreter version
5. VS Code will automatically:
   - Create the `.venv` directory
   - Activate the environment
   - Install `pip` and `setuptools`
   - Optionally install packages from `requirements.txt`

When prompted, select "Yes" to install packages from `requirements.txt`. This will execute `pip install -r requirements.txt` automatically within the newly created environment.

After creation, the Python terminal in VS Code will use the virtual environment by default.

## Code Coverage Testing

Code coverage analysis can be performed on CPNServer.py to measure which code paths are exercised during testing. This requires the `coverage` package and uses the `CPNServer_cov` debug configuration in VS Code.

**Setup:**

First, install the coverage package in you virtual environment (it is not part of the requirements.txt):
```
pip install coverage
```

**Running Coverage:**

1. Open the debug configuration dropdown in VS Code (top of Run panel)
2. Select `CPNServer_cov` instead of `CPNServer`
3. Press F5 or click the Start Debugging button
4. Use the server normally for testing
5. Stop the debugger when finished

**Generating the HTML Report:**

After the coverage run completes, generate an HTML coverage report:
```
python -m coverage html
```

This creates an `htmlcov/` directory with detailed coverage information. Open the report in a browser:
```
start htmlcov\index.html
```

Or from PowerShell:
```
Invoke-Item .\htmlcov\index.html
```

**Coverage Report Details:**

The HTML report shows:
- Overall code coverage percentage
- Line-by-line coverage for each module (green = executed, red = not executed)
- Uncovered branches and conditionals
- Summary statistics by file

This helps identify untested code paths and areas that may need additional test scenarios.
