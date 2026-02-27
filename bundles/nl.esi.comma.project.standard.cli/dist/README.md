# Welcome to BPMN4S

This readme explains howto run the BPMN4S editor, including support for writing and validating data expressions, as well as the transformation of BPMN models into a coloured petri net (CPN) module and its simulation via a (python-based) REST server.

**!!! IMPORTANT !!!**

BPMN models from version v0.3.x and earlier need to be migrated before used with v0.4.x or later.
To migrate your model, use the following command (the original bpmn file will be backed up with an `.orig` file extension):

```
sed -e 's/__uuid__\s*=\s*uuid()\s*,\(&#10;\|\s\)*//g' -e '/<bpmn4s:field name="__uuid__" typeRef="String"/d' -i.orig <bpmn_file.bpmn>
```

## Pre-requisites

To run BPMN4S, you need ``python v3.10 (or greater)`` installed on your system.

By default, the `start-all.bat` script will create a temporary Python virtual environment in the system's temp directory. This environment will be cleaned up automatically if you use the `--clean` flag.

If you want to use your own Python installation (e.g., from an existing virtual environment), you can define an environment variable named ``BPMN4S_PYTHON`` pointing to the desired ``python.exe``.
The script will detect if it's already a virtual environment and use it directly.

**Package management:** Python packages are installed automatically by the `start-all.bat` script. If the `requirements.txt` file changes, the script will automatically detect this and reinstall/update the required packages on the next run. Manual pip installation is not needed.

## Starting the language servers

To get data expression editing support and simulation capabilities, the language servers (LSP and CPN) need to be started.
Both servers are started automatically when you run the `start-all.bat` script. Simply execute the `start-all.bat` file by double clicking it.

This will:
1. Start the data expression language server (LSP) on a dynamically allocated socket port
2. Start the CPN simulation server on `http://127.0.0.1:5000`
3. Open the BPMN4S editor in your default browser

Please keep the console open during your BPMN4S modeling sessions, and just close it when you are done.

If you encounter any errors during startup, try running the script with the `--clean` flag to reset the Python environment:
```
start-all.bat --clean
```

## Starting the BPMN4S editor

The BPMN4S editor will open automatically in your default browser when you run the `start-all.bat` script.
The editor will be accessible at `http://localhost:5000`.

If the browser does not open automatically, you can manually navigate to `http://localhost:5000` in your browser.
To get editing support for data expressions, just click on the `fx` button near the data expression field.
Please click the `fx` button again when done editing.

NOTE: The following error message indicates that the LSP server is not running:
      `WebSocket connection to 'ws://localhost:9090' failed.`

To simulate your model, please click the `Token Simulation` button at the top left of your browser window.
This will change the palette at the top left, and now you can click the play button at the top to start simulation.

NOTE: The following error message indicates that the simulation server is not running:
      `Failed to connect to simulation server: Failed to fetch`

When your model is complete, test scenarios can be generated, this also requires a running simulation server.
Please click the `Generate test cases` button at the right side of the bottom toolbar in your browser window.
A dialog will be presented where the number of test and the maximum depth of a scenario can be specified, please click the `Ok` button to continue.
On successful test generation a zip file will be downloaded, which contains the required test artifacts:

- **bpmn** - Contains the BPMN model from which the test scenarios were generated.
- **pspec / CPNServer** - internal models that were used for test generation, for debugging purposes only!
- **tspec_abstract** - Contains the generated test scenarios, including a graphical BPMN representation (i.e. `*.bpmn`) and a trace (i.e. `*.json`) which can be replayed during simulation or can be used for regression testing, also see next section.
- **tspec_concrete** - Executable test scenarios.

## Running a regression test

NOTE: Running a regression test requires a running simulation server.

Regression tests can be used to validate if previously generated test scenarios can still be replayed on a new version of your BPMN model.
To start a regression test, please execute the `regression-test.bat` file from the command line.
The command takes the BPMN file as its first input, followed by a list of json files (i.e. test scenario traces, also see previous section).

The regression test command-line utility will replay all provided test scenarios against the provided BPMN model and report if this succeeded or failed.
If one ore more scenarios could not be replayed the process will exit with an exit code 1.

NOTE: The following error message indicates that the simulation server is not running:
      `Failed to connect to simulation server: Failed to fetch`
