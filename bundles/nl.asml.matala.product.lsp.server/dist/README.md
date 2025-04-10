# Welcome to BPMN4S

This readme explains howto run the BPMN4S editor, including support for writing and validating data expressions, as well as the transformation of BPMN models into a coloured petri net (CPN) module and its simulation via a (python-based) REST server.

## Starting the LSP server

To get data expression editing support, the data expression language server needs to be started before loading a bpmn model.
To start the data expression language server, simply execute the `start-lsp-server.bat` file by double clicking it.
This will open a console, and if correct, the console will state: `... Started server socket at /0.0.0.0:9090`
Please keep this console open during your BPMN4S modeling sessions, and just close it when you are done.

## Starting the simulation server

To get simulation capabilities enabled, the CPNServer needs to be started before starting a token simulation.
To start the CPN server, simply execute the `start-simulator.bat` file by double clicking it.
This will open a console, and if correct, the console will state: `... Running on http://127.0.0.1:5000`
Please keep this console open during your BPMN4S modeling sessions, and just close it when you are done.

## Starting the BPMN4S editor

Now you are ready to start modeling, just open the `index.html` in your browser.
To get editing support for data expressions, just click on the `fx` button near the data expression field.
Please click the `fx` button again when done editing.

NOTE: The following validation error message indicates that the LSP server is not running:
      `WebSocket connection to 'ws://localhost:9090' failed.`

NOTE2: The following validation error message indicates that the CPN server is not running:
      `Failed to connect to simulation server: Failed to fetch`