# Welcome to BPMN4S

This readme explains howto run the BPMN4S editor, including support for writing and validating data expressions.

## Starting the LSP server

To get data expression editing support, the data expression language server needs to be started before loading a bpmn model.
To start the data expression language server, simply execute the `start-server.bat` file by double clicking it.
This will open a console, and if correct, the console will state: `... Started server socket at /0.0.0.0:9090`
Please keep this console open during your BPMN4S modeling sessions, and just close it when you are done.

## Starting the BPMN4S editor

Now you are ready to start modeling, just open the `index.html` in your browser.
To get editing support for data expressions, just click on the `fx` button near the data expression field.
Please click the `fx` button again when done editing.

NOTE: The following validation error message indicates that the LSP server is not running:
      `WebSocket connection to 'ws://localhost:9090' failed.`