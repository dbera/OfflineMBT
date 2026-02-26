#!/usr/bin/env python3
#
# Copyright (c) 2024, 2025 TNO-ESI
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available
# under the terms of the MIT License which is available at
# https://opensource.org/licenses/MIT
#
# SPDX-License-Identifier: MIT
#

"""CPN Server - LSP-based BPMN Model Simulator

Flask web server providing REST API endpoints for BPMN model simulation and
test generation. Manages LSP subprocess on a dynamically allocated socket port,
forwarding WebSocket messages between clients and the Language Server Protocol
backend. Supports scenario loading, state management, and transition firing.
"""

import os
import sys
import json
import shutil
import tempfile
import subprocess
import threading
import socket
import logging
import time
import webbrowser
from typing import Optional, Tuple, Any

import CPNUtils as utils
from LSPProxy import LSPProxy
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from flask_sock import Server, Sock

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

BPMN4S_GEN = os.path.join("bpmn4s-toolchain.jar")
JAVA_PATH = os.path.join("jre", "bin", "java.exe")

prefix_str = f'{utils.gensym(prefix="cpnserver_", timestamp=True)}_'
TEMP_FILE = tempfile.TemporaryDirectory(prefix=prefix_str,
                                        ignore_cleanup_errors=True)
TEMP_PATH = os.path.abspath(TEMP_FILE.name)
sys.path.append(TEMP_PATH)

# Initiating a Flask application
app = Flask(__name__)
sock = Sock(app)

CORS(app)

# LSP subprocess port - will be set at runtime
LSP_PORT: Optional[int] = None


def build_and_load_model(model_path: str) -> Tuple[
        Any, subprocess.CompletedProcess]:
    model_dir, model_name = os.path.split(model_path)
    model_name, model_ext = os.path.splitext(model_name)
    model_name = utils.to_valid_variable_name(model_name)
    taskname: str = "simulator"
    prj_template: str = """Project project {{
    Generate Simulator {{
        {0} {{
          bpmn-file "{1}.bpmn"
        }}
      }}
    }}
    """
    # Generate the module
    prj_filename: str = os.path.join(model_dir, f'{model_name}.prj')
    with open(prj_filename, "w") as file1:
        prj_content = prj_template.format(taskname, model_name)
        file1.write(prj_content)
    cmd = [JAVA_PATH, "-jar", BPMN4S_GEN, "-l", prj_filename]
    result = subprocess.run(cmd, shell=True, capture_output=True)
    if result.returncode != 0:
        raise utils.BPMN4SException(
            cliargs={'bpmn-file': model_name},
            result=result
        )
    # Move all input files to the bpmn folder
    bpmn_dir = os.path.join(model_dir, 'src-gen', taskname,
                            'CPNServer', model_name, 'bpmn')
    os.makedirs(bpmn_dir, exist_ok=True)
    filename_wildcard = os.path.join(TEMP_PATH, f"{model_name}.*")
    utils.move(filename_wildcard, bpmn_dir)
    # Now load the module
    module = utils.load_module(source=model_name,
                               package=f"src-gen.{taskname}.CPNServer")
    return module, result


def generate_tests(model_path: str, num_tests: int = 1,
                   depth_limit: int = 500) -> Tuple[
                       str, subprocess.CompletedProcess]:
    model_dir, model_name = os.path.split(model_path)
    model_name, model_ext = os.path.splitext(model_name)
    model_name = utils.to_valid_variable_name(model_name)
    taskname: str = "testgen"
    prj_template: str = """Project project {{
      Generate Tests {{
        {0} {{
          bpmn-file "{1}.bpmn"
          num-tests {2}
          depth-limit {3}
        }}
      }}
    }}
    """

    prj_filename: str = os.path.join(model_dir, f'{model_name}.prj')
    with open(prj_filename, "w") as file1:
        prj_content = prj_template.format(taskname, model_name, num_tests,
                                          depth_limit)
        file1.write(prj_content)
    cmd = [JAVA_PATH, "-jar", BPMN4S_GEN, "-l", prj_filename]
    result = subprocess.run(cmd, shell=True, capture_output=True)
    if result.returncode != 0:
        raise utils.BPMN4SException(
            cliargs={
                'bpmn-file': model_name,
                'num-tests': num_tests,
                'depth-limit': depth_limit
            },
            result=result
        )

    # zip filename (without .zip extension)
    zip_filename = os.path.join(model_dir, model_name)
    # path to directory about to be zipped
    output_dir = os.path.join(model_dir, 'src-gen', taskname)
    # store bpmn and prj files in bpmn directory
    bpmn_dir = os.path.join(output_dir, 'bpmn')
    os.makedirs(bpmn_dir, exist_ok=True)
    filename_wildcard = os.path.join(model_dir, f"{model_name}.*")
    utils.move(filename_wildcard, bpmn_dir)
    # make zip file
    zip_filename = shutil.make_archive(base_name=zip_filename, format='zip',
                                       root_dir=output_dir)
    try:
        # remove generated tests
        shutil.rmtree(output_dir, ignore_errors=True)
    except Exception as e:
        err_msg = f"An error occurred while deleting generated test: {str(e)}"
        print(err_msg, file=sys.stderr)
    return zip_filename, result


@app.route('/')
def index() -> str:
    return serve_static('index.html')


# This route handles any static files in the root directory
@app.route('/<path:path>')
def serve_static(path: str) -> Tuple[str, int]:
    static_path = os.path.join(os.path.join(__file__, '..'), 'static', path)
    if os.path.exists(static_path):
        return send_from_directory('static', path)
    else:
        return "File not found", 404


@sock.route('/lsp')
def lsp_endpoint(ws: Server) -> None:
    """WebSocket endpoint that proxies messages to LSP subprocess."""
    print("Client connected to LSP endpoint...")

    if LSP_PORT is None:
        print("Error: LSP subprocess port not set")
        try:
            error_msg = {
                "jsonrpc": "2.0",
                "error": {
                    "code": -32603,
                    "message": "LSP server not available"
                }
            }
            ws.send(json.dumps(error_msg))
        except Exception:
            pass
        ws.close()
        return

    # Create proxy to LSP subprocess
    proxy: LSPProxy = LSPProxy(LSP_PORT)
    if not proxy.connect():
        print("Failed to connect to LSP subprocess")
        try:
            error_msg = {
                "jsonrpc": "2.0",
                "error": {
                    "code": -32603,
                    "message": "Failed to connect to LSP server"
                }
            }
            ws.send(json.dumps(error_msg))
        except Exception:
            pass
        ws.close()
        return

    print(f"Connected to LSP subprocess on port {LSP_PORT}")

    # Shutdown event for clean termination
    shutdown_event: threading.Event = threading.Event()

    # Thread to forward responses from LSP to WebSocket client
    def forward_lsp_responses() -> None:
        try:
            while not shutdown_event.is_set() and proxy.connected:
                try:
                    message = proxy.receive_message()
                    # Distinguish None (error/disconnect) from empty string
                    if message is not None:
                        if len(message) > 100:
                            print(f'out: {message[:100]}...')
                        else:
                            print(f'out: {message}')
                        try:
                            ws.send(message)
                        except Exception as e:
                            logger.error(f"Error sending to client: {e}")
                            shutdown_event.set()
                            break
                    else:
                        # LSP connection closed or error
                        logger.warning("LSP connection closed by server")
                        break
                except socket.timeout:
                    # Timeout is normal, continue
                    continue
                except Exception as e:
                    logger.error(f"Error receiving from LSP: {e}")
                    break
        except Exception as e:
            logger.error(f"Forward thread error: {e}")
        finally:
            logger.info("Response forwarding thread stopping")
            shutdown_event.set()

    response_thread: threading.Thread = threading.Thread(
        target=forward_lsp_responses)
    response_thread.daemon = False  # Not a daemon thread
    response_thread.start()

    try:
        while not shutdown_event.is_set():
            try:
                # No timeout - flask-sock doesn't support it
                message = ws.receive()
                # Distinguish None (disconnect) from empty string
                if message is not None:
                    if len(message) > 100:
                        print(f'in: {message[:100]}...')
                    else:
                        print(f'in: {message}')
                    if not proxy.send_message(message):
                        print("Failed to send message to LSP")
                        break
                # If message is None, connection was closed by client
                else:
                    print("Client disconnected")
                    break
            except Exception as e:
                logger.error(f"Error receiving from client: {e}")
                break
    except Exception as e:
        logger.error(f"Connection error: {e}")
    finally:
        print("Cleaning up LSP connection...")
        shutdown_event.set()
        # Wait for response thread to finish before closing ws
        response_thread.join(timeout=5)
        proxy.disconnect()
        try:
            ws.close()
        except Exception as e:
            logger.error(f"Error closing WebSocket: {e}")
        logger.info("LSP endpoint cleanup complete")


# The endpoint of our flask app
@app.route(rule="/BPMNParser", methods=["POST"])
def handle_bpmn() -> Tuple[Any, int]:
    _bpmn = request.files['bpmn-file']
    fname = _bpmn.filename
    filename = fname + utils.gensym(prefix="_", timestamp=True)
    bpmn_path = os.path.join(TEMP_PATH, f"{filename}.bpmn")
    _bpmn.save(bpmn_path)

    status_code = 200
    response = {'response': {'uuid': filename}}
    try:
        if utils.is_loaded_module(filename):
            raise Exception(F"BPMN model '{filename}' is already loaded!")
        module, result = build_and_load_model(bpmn_path)
        bpmn_dir = os.path.join(module.__path__[0], 'bpmn')
        os.makedirs(bpmn_dir, exist_ok=True)
        filename_wildcard = os.path.join(TEMP_PATH, f"{filename}.*")
        utils.move(filename_wildcard, bpmn_dir)
        loaded = response['response']
        loaded['message'] = 'Package loaded successfully'
        loaded['returncode'] = result.returncode
        loaded['stdout'] = result.stdout.decode('utf-8').replace('\r\n', '\n')
        loaded['stderr'] = result.stderr.decode('utf-8').replace('\r\n', '\n')
    except utils.BPMN4SException as e:
        status_code = 400
        failed = response['response']
        failed['message'] = 'Package loading failed'
        failed['returncode'] = e.returncode
        failed['stdout'] = e.stdout
        failed['stderr'] = e.stderr
        failed['cliargs'] = e.cliargs
    except Exception as e:
        status_code = 400
        failed = response['response']
        failed['exception'] = str(e)

    # return the response as JSON
    return jsonify(response), status_code


@app.route(rule="/TestGenerator", methods=["POST"])
def test_generator() -> Tuple[Any, int]:
    _bpmn = request.files['bpmn-file']
    prj_params = request.form.get('prj-params', '{}')
    _args = json.loads(prj_params) if 'prj-params' in request.form else {}

    numTests = _args.get('num-tests', 1)
    depthLimit = _args.get('depth-limit', 1000)

    fname = _bpmn.filename
    filename = fname + utils.gensym(prefix="_", timestamp=True)
    model_path = os.path.join(TEMP_PATH, f"{filename}.bpmn")
    _bpmn.save(model_path)

    status_code = 200
    response = {'response': {'uuid': filename}}
    try:
        zip_fname, result = generate_tests(model_path, num_tests=numTests,
                                           depth_limit=depthLimit)
        zip_dir, zip_path = os.path.split(zip_fname)
        return send_from_directory(zip_dir, zip_path,
                                   mimetype='application/zip',
                                   as_attachment=True), status_code
    except utils.BPMN4SException as e:
        status_code = 400
        failed = response['response']
        failed['message'] = f'Error generating test cases from file {fname}'
        failed['returncode'] = e.returncode
        failed['stdout'] = e.stdout
        failed['stderr'] = e.stderr
        failed['cliargs'] = e.cliargs
    except Exception as e:
        status_code = 400
        failed = response['response']
        failed['exception'] = str(e)

    return jsonify(response), status_code


# The endpoint of our flask app
@app.route(rule="/BPMNParser/<uuid>", methods=["DELETE"])
def handle_delete_bpmn(uuid: str) -> Any:
    msg = f'Error (un)loading Package {uuid}'
    response = {'response': msg}
    with utils.lock_handle_bpmn():
        if utils.get_cpn(uuid) is not None:
            utils.unload_module(uuid)
            response['response'] = f'Package {uuid} has been unloaded'
        else:
            response['response'] = f'Package {uuid} does not exist'
    # return the response as JSON
    return jsonify(response)


# The endpoints of our flask app
@app.route(rule="/CPNServer/<uuid>", methods=["GET"])
def handle_request(uuid: str) -> Any:
    print(f'Received Request [{uuid}]: request_cpn')

    response = {}
    pn = utils.get_cpn(uuid)
    if pn is not None:
        response['response'] = f'CPN "{uuid}" preloaded'
    else:
        response['error'] = f'CPN "{uuid}" not loaded.'

    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/scenario/load", methods=["POST"])
def handle_scenario_load(uuid: str) -> Tuple[Any, int]:
    print(f'Received Request [{uuid}]: load_scenario')
    pn = utils.get_cpn(uuid)

    status_code = 200
    response = {}
    try:
        scenarioFile = request.files['scenario-file']
        scenarioJson = json.load(scenarioFile)
        pn.loadScenario(scenarioJson)
        response['message'] = 'The scenario has been loaded'
        response['steps'] = len(scenarioJson)

    except Exception as e:
        status_code = 400
        response['exception'] = str(e)

    return jsonify(response), status_code


@app.route(rule="/CPNServer/<uuid>/markings", methods=["GET"])
def handle_markings(uuid: str) -> Any:
    print(f'Received Request [{uuid}]: get_marking')
    pn = utils.get_cpn(uuid)
    json_data = {}
    current_marking = pn.getCurrentMarking()
    for k in current_marking:
        # convert multi-set to list with items()
        json_data[k] = current_marking[k].items()
    response = {'response': json_data}
    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/transitions/enabled", methods=["GET"])
def handle_transitions_enabled(uuid: str) -> Tuple[Any, int]:
    print(f'Received Request [{uuid}]: get_enabled_transitions')
    pn = utils.get_cpn(uuid)
    status_code = 200
    response = {'id_mode_dict': {},
                'id_transition_dict': {}}
    try:
        enabled_transitions = pn.getEnabledTransitions()
        for _k, _v in enabled_transitions.items():
            # print(_k)  # choice ids
            # print(_v[0].name)  # transition object
            # print(_v[1].dict())  # substitution object
            response['id_mode_dict'][_k] = _v[1].dict()
            response['id_transition_dict'][_k] = _v[0].name
    except Exception as e:
        status_code = 400
        response['exception'] = str(e)

    return jsonify(response), status_code


@app.route(rule="/CPNServer/<uuid>/transition/fire", methods=["POST"])
def handle_transition_fire(uuid: str) -> Any:
    print(f'Received Request [{uuid}]: fire_transition')
    pn = utils.get_cpn(uuid)
    payload = request.get_json()
    choice = payload['choice']
    enabled_t = pn.getEnabledTransitions()
    _r = pn.fireEnabledTransition(enabled_t, choice)

    marks_data = {}
    for idx, item in enumerate(_r):
        marks_data[idx] = {}
        for k in item:
            # convert multi-set to list with items()
            marks_data[idx][k] = item[k].items()
    response = {
        'response': {
            'executed_transition_idx': choice,
            'markings_consumed': marks_data[0],
            'markings_produced': marks_data[1]
        }
    }
    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/markings/save", methods=["POST"])
def handle_markings_save(uuid: str) -> Any:
    print(f'Received Request [{uuid}]: save_marking')
    pn = utils.get_cpn(uuid)
    pn.saveMarking()
    response = {'response': 'The marking has been saved'}
    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/markings/restore", methods=["POST"])
def handle_markings_reload(uuid: str) -> Any:
    print(f'Received Request [{uuid}]: set_marking')
    pn = utils.get_cpn(uuid)
    pn.gotoSavedMarking()
    response = {'response': 'The net has been restored to saved state'}
    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/markings/goto", methods=["POST"])
def handle_markings_goto(uuid: str) -> Any:
    print(f'Received Request [{uuid}]: goto_marking')
    pn = utils.get_cpn(uuid)
    payload = request.get_json()
    index = payload['index']
    pn.gotoMarking(index)
    response = {'response': 'The net has been restored to the marking'}
    return jsonify(response)


# Running the API
if __name__ == "__main__":

    print(f'# Using temporary directory:  "{TEMP_PATH}"')

    # Find a free port for LSP subprocess
    def find_free_port() -> Optional[int]:
        """Find a free port by letting the OS assign one, then return it."""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.bind(('127.0.0.1', 0))  # 0 = let OS choose a free port
            port = s.getsockname()[1]
            s.close()
            return port
        except OSError as e:
            logger.error(f"Failed to find free port: {e}")
            return None

    lsp_port = find_free_port()
    if lsp_port is None:
        print("Error: Failed to find free port for LSP subprocess")
        sys.exit(1)

    # Set global LSP_PORT for lsp_endpoint to use
    LSP_PORT = lsp_port
    logger.info(f"LSP subprocess will use port {LSP_PORT}")

    print(f"Starting LSP subprocess on port {LSP_PORT}...")

    # Start LSP subprocess directly
    lsp_command = [
        JAVA_PATH,
        "-cp",
        BPMN4S_GEN,
        "nl.asml.matala.product.lsp.server.ProductServerLauncher",
        "-socket",
        "-port",
        str(LSP_PORT)
    ]

    logger.info(f"LSP command: {' '.join(lsp_command)}")

    lsp_proc: subprocess.Popen = subprocess.Popen(
        lsp_command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Give LSP subprocess time to start and listen on socket
    logger.info("Waiting for LSP subprocess to initialize...")
    time.sleep(2)

    print("Starting CPN Server on port 5000...")

    # Open browser to the server
    try:
        reuse_window = 0  # Reuse existing window if possible
        webbrowser.open('http://localhost:5000/', new=reuse_window)
        logger.info("Browser opened to http://localhost:5000/")
    except Exception as e:
        logger.warning(f"Failed to open browser: {e}")

    try:
        app.run(host="0.0.0.0", debug=False, port=5000)
    finally:
        logger.info("Shutting down CPN Server...")
        if lsp_proc.poll() is None:
            logger.info("Terminating LSP subprocess...")
            lsp_proc.terminate()
            try:
                lsp_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                logger.warning("LSP subprocess did not terminate, killing...")
                lsp_proc.kill()
                lsp_proc.wait()
        TEMP_FILE.cleanup()
        logger.info("CPN Server shutdown complete")
