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

## Starting the language servers

To get data expression editing support and simulation capabilities, the language servers (LSP and CPN) need to be started.
The CPN simulation server is started automatically when you run the `start-server.bat` script. Simply execute the `start-server.bat` file by double clicking it.

This will:
1. Set up the Python virtual environment (downloading dependencies if needed)
2. Start the data expression language server (LSP) on a dynamically allocated WebSocket port
3. Start the CPN simulation server on `http://127.0.0.1:5000` or a higher port if the port is not available
4. Open the BPMN4S editor in your default browser

Please keep the console open during your BPMN4S modeling sessions, and just close it when you are done.

If you encounter any errors during startup, you can try running the script with the `--clean` flag to reset the Python environment:

```
start-server.bat --clean
```

## Starting the BPMN4S editor

The BPMN4S editor will open automatically in your default browser when you run the `start-server.bat` script.
The editor will be accessible at `http://localhost:5000`.

If the browser does not open automatically, you can manually navigate to `http://localhost:5000` in your browser.
To get editing support for data expressions, just click on the `fx` button near the data expression field.
Please click the `fx` button again when done editing.

NOTE: The following error message indicates that the LSP server is not running:
      `WebSocket connection to 'ws://localhost:5000/lsp' failed.`

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

**IMPORTANT**: The regression test requires a running simulation server on port 5000.
Start the server first by running `start-server.bat` in a separate terminal before running regression tests.

Regression tests can be used to validate if previously generated test scenarios can still be replayed on a new version of your BPMN model.
To start a regression test, execute the `regression-test.bat` file from the command line with your BPMN file and scenario files:

```
regression-test.bat <model.bpmn> <scenario1.json> [scenario2.json ...]
```

The regression test command-line utility will replay all provided test scenarios against the running server's BPMN model and report if this succeeded or failed.
If one or more scenarios could not be replayed, the process will exit with exit code 1.

**Optional flags**:
- `--verbose`: Enable detailed per-step logs
- `--timeout N`: HTTP timeout in seconds (default: 60)

For a complete list of regression-test CLI options, see [DESIGN.md](server/DESIGN.md#running-the-regression-test).

Example:
```
regression-test.bat models\printer.bpmn scenarios\scenario1.json scenarios\scenario2.json
```

If you see the error `Failed to connect to simulation server: Failed to fetch`, it means the simulation server is not running on port 5000.
Start it with `start-server.bat` first.
