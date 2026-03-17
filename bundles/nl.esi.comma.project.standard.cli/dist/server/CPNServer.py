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
import argparse
from typing import Optional, Tuple, Any

import CPNUtils as utils
from LSPProxy import LSPProxy
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from flask_sock import Server, Sock

# Configure logging with colored errors and warnings
class PrefixedFormatter(logging.Formatter):
    """Custom formatter that adds colors for errors and warnings"""
    
    # ANSI color codes
    RED = '\033[31m'      # Red for errors
    YELLOW = '\033[33m'   # Yellow for warnings
    RESET = '\033[0m'     # Reset to default
    
    def format(self, record):
        if record.levelno == logging.ERROR:
            record.msg = f"{self.RED}{record.msg}{self.RESET}"
        elif record.levelno == logging.WARNING:
            record.msg = f"{self.YELLOW}{record.msg}{self.RESET}"
        return super().format(record)

handler = logging.StreamHandler()
handler.setFormatter(PrefixedFormatter("%(asctime)s - %(message)s"))
logging.basicConfig(level=logging.INFO, handlers=[handler])
logger = logging.getLogger(__name__)

BPMN4S_GEN = os.path.join(os.path.dirname(__file__),"bpmn4s-toolchain.jar")
JAVA_PATH = os.path.join(os.path.dirname(__file__),"jre", "bin", "java.exe")

TEMP_FILE   = tempfile.TemporaryDirectory(prefix=f'{utils.gensym(prefix="cpnserver_",timestamp=True)}_', ignore_cleanup_errors=True)
TEMP_PATH = os.path.abspath(TEMP_FILE.name)
sys.path.append(TEMP_PATH)

# Initiating a Flask application
app = Flask(__name__)
sock = Sock(app)

CORS(app)

# LSP subprocess port - will be set at runtime
LSP_PORT: Optional[int] = None

# Static files path - will be set from command-line arguments
WEB_PATH = os.path.join(os.path.dirname(__file__), '..', 'web')

def build_and_load_model(model_path:str):

    model_dir, model_name = os.path.split(model_path)
    model_name, model_ext = os.path.splitext(model_name)
    model_name = utils.to_valid_variable_name(model_name)
    taskname:str = f"server"
    prj_template:str = """Project project {{
    Generate Simulator {{
        {0} {{
          bpmn-file "{1}.bpmn"
        }}
      }}
    }}
    """
    # Generate the module
    prj_filename:str = os.path.join(model_dir,f'{model_name}.prj')
    with open(prj_filename, "w") as file1:
        prj_content = prj_template.format(taskname,model_name)
        file1.write(prj_content)
    result = subprocess.run([JAVA_PATH,"-jar",BPMN4S_GEN,"-l", prj_filename],shell=True, capture_output=True)
    if result.returncode != 0: 
        raise utils.BPMN4SException(
            cliargs={
                'bpmn-file': model_name
            }, 
            result=result
            )
    # Move all input files to the bpmn folder within the generated module
    bpmn_dir = os.path.join(model_dir, 'src-gen', taskname, 'CPNServer', model_name, 'bpmn')
    os.makedirs(bpmn_dir, exist_ok=True)
    filename_wildcard = os.path.join(TEMP_PATH,f"{model_name}.*")
    utils.move(filename_wildcard, bpmn_dir)
    # Now load the module
    module = utils.load_module(source=model_name,package=f"src-gen.{taskname}.CPNServer")
    return module, result

def generate_tests( model_path:str, num_tests:int=1, depth_limit:int=500):
    
    model_dir, model_name = os.path.split(model_path)
    model_name, model_ext = os.path.splitext(model_name)
    model_name = utils.to_valid_variable_name(model_name)
    taskname:str = f"testgen"
    prj_template:str = """Project project {{
      Generate Tests {{
        {0} {{
          bpmn-file "{1}.bpmn"
          num-tests {2}
          depth-limit {3}
        }}
      }}
    }}
    """
    
    prj_filename:str = os.path.join(model_dir,f'{model_name}.prj')
    with open(prj_filename, "w") as file1:
        prj_content = prj_template.format(taskname,model_name,num_tests,depth_limit)
        file1.write(prj_content)
    result = subprocess.run([JAVA_PATH,"-jar",BPMN4S_GEN,"-l", prj_filename],shell=True, capture_output=True)
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
    zip_filename = os.path.join(model_dir,model_name)
    # path to directory about to be zipped
    output_dir = os.path.join(model_dir,'src-gen',taskname)
    # store bpmn and prj files in bpmn directory 
    bpmn_dir = os.path.join(output_dir,'bpmn')
    os.makedirs(bpmn_dir, exist_ok=True)
    filename_wildcard = os.path.join(model_dir,f"{model_name}.*")
    utils.move(filename_wildcard, bpmn_dir)
    # make zip file
    zip_filename = shutil.make_archive(base_name=zip_filename, format='zip', root_dir=output_dir)
    try:
        # remove generated tests 
        shutil.rmtree(output_dir, ignore_errors=True)
    except Exception as e:
        print(f"An error occurred while deleting generated test: {str(e)}", file=sys.stderr)
    return zip_filename, result

# The endpoint of our flask app
@app.route(rule="/BPMNParser", methods=["POST"])
def handle_bpmn():
    _bpmn = request.files['bpmn-file']
    fname = _bpmn.filename
    filename = fname + utils.gensym(prefix="_",timestamp=True)
    bpmn_path = os.path.join(TEMP_PATH,f"{filename}.bpmn")
    _bpmn.save(bpmn_path)

    status_code = 200
    response = {'response': {'uuid': filename}}
    try:
        if utils.is_loaded_module(filename): 
            raise Exception(F"BPMN model '{filename}' is already loaded!")
        module, result = build_and_load_model(bpmn_path)
        bpmn_dir = os.path.join(module.__path__[0],'bpmn')
        os.makedirs(bpmn_dir, exist_ok=True)
        filename_wildcard = os.path.join(TEMP_PATH,f"{filename}.*")
        utils.move(filename_wildcard, bpmn_dir)
        loaded = response['response']
        loaded['message'] = 'Package loaded successfully'
        loaded['returncode'] = result.returncode
        loaded['stdout'] = result.stdout.decode('utf-8').replace('\r\n','\n')
        loaded['stderr'] = result.stderr.decode('utf-8').replace('\r\n','\n')
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
def test_generator():
    _bpmn = request.files['bpmn-file']
    _args = json.loads(request.form['prj-params']) if 'prj-params' in request.form else {}

    numTests = _args.get('num-tests',1)
    depthLimit = _args.get('depth-limit',1000)

    fname = _bpmn.filename
    filename = fname + utils.gensym(prefix="_",timestamp=True)
    model_path = os.path.join(TEMP_PATH,f"{filename}.bpmn")
    _bpmn.save(model_path)

    status_code = 200
    response = {'response': {'uuid': filename}}
    try:
        zip_fname, result = generate_tests(model_path, num_tests=numTests, depth_limit=depthLimit)
        zip_dir, zip_path = os.path.split(zip_fname)
        return send_from_directory(zip_dir, zip_path, mimetype='application/zip', as_attachment=True), status_code
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
def handle_delete_bpmn(uuid):
    response = {'response': f'Error (un)loading Package {uuid}'}
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
def handle_request(uuid: str):
    print(f'Received Request [{uuid}]: request_cpn')

    response = {}
    pn = utils.get_cpn(uuid)
    if not pn is None:
        response['response'] = f'CPN "{uuid}" preloaded'
    else:
        response['error'] = f'CPN "{uuid}" not loaded.'

    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/scenario/load", methods=["POST"])
def handle_scenario_load(uuid: str):
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
def handle_markings(uuid: str):
    print(f'Received Request [{uuid}]: get_marking')
    pn = utils.get_cpn(uuid)
    json_data = {}
    current_marking = pn.getCurrentMarking()
    for k in current_marking:
        json_data[k] = current_marking[k].items()  # convert multi-set to list with items()
    response = {'response': json_data}
    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/transitions/enabled", methods=["GET"])
def handle_transitions_enabled(uuid: str):
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
def handle_transition_fire(uuid: str):
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
            marks_data[idx][k] = item[k].items()  # convert multi-set to list with items()
    response = {'response': {'executed_transition_idx': choice, 'markings_consumed': marks_data[0],'markings_produced': marks_data[1]}}
    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/markings/save", methods=["POST"])
def handle_markings_save(uuid: str):
    print(f'Received Request [{uuid}]: save_marking')
    pn = utils.get_cpn(uuid)
    pn.saveMarking()
    response = {'response': 'The marking has been saved'}
    return jsonify(response)


@app.route(rule="/CPNServer/<uuid>/markings/restore", methods=["POST"])
def handle_markings_reload(uuid: str):
    print(f'Received Request [{uuid}]: set_marking')
    pn = utils.get_cpn(uuid)
    pn.gotoSavedMarking()
    response = {'response': 'The net has been restored to saved state'}
    return jsonify(response)

@app.route(rule="/CPNServer/<uuid>/markings/goto", methods=["POST"])
def handle_markings_goto(uuid: str):
    print(f'Received Request [{uuid}]: goto_marking')
    pn = utils.get_cpn(uuid)
    payload = request.get_json()
    index = payload['index']
    pn.gotoMarking(index)
    response = {'response': 'The net has been restored to the marking'}
    return jsonify(response)

# The root will serve index.html from ../web
@app.route("/")
def index() -> str:
    return serve_web("index.html")

# This route handles any web files in the root directory
@app.route("/<path:path>")
def serve_web(path: str) -> Tuple[str, int]:
    web_file = os.path.join(WEB_PATH, path)
    if os.path.exists(web_file):
        return send_from_directory(WEB_PATH, path)
    else:
        return f"File not found {path}", 404

# A Proxy to the java lsp server 
@sock.route("/lsp")
def lsp_endpoint(ws: Server) -> None:
    """WebSocket endpoint that proxies messages to LSP subprocess."""
    logger.info("Client connected to LSP endpoint...")

    if LSP_PORT is None:
        logger.error("Error: LSP subprocess port not set")
        try:
            error_msg = {
                "jsonrpc": "2.0",
                "error": {"code": -32603, "message": "LSP server not available"},
            }
            ws.send(json.dumps(error_msg))
        except Exception:
            pass
        ws.close()
        return

    # Create proxy to LSP subprocess
    proxy: LSPProxy = LSPProxy(LSP_PORT)
    if not proxy.connect():
        logger.error("Failed to connect to LSP subprocess")
        try:
            error_msg = {
                "jsonrpc": "2.0",
                "error": {"code": -32603, "message": "Failed to connect to LSP server"},
            }
            ws.send(json.dumps(error_msg))
        except Exception:
            pass
        ws.close()
        return

    logger.info(f"Connected to LSP subprocess on port {LSP_PORT}")

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
                            logger.debug(f"out: {message[:100]}...")
                        else:
                            logger.debug(f"out: {message}")
                        try:
                            ws.send(message)
                        except Exception as e:
                            logger.error(f"Error sending to client: {e}")
                            shutdown_event.set()
                            break
                    else:
                        # LSP connection closed or error
                        logger.info("LSP connection closed")
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

    response_thread: threading.Thread = threading.Thread(target=forward_lsp_responses)
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
                        logger.debug(f"in: {message[:100]}...")
                    else:
                        logger.debug(f"in: {message}")
                    if not proxy.send_message(message):
                        logger.debug("Failed to send message to LSP")
                        break
                # If message is None, connection was closed by client
                else:
                    logger.info("LSP Client disconnected")
                    break
            except Exception as e:
                logger.info(f"Message from client: {e}")
                break
    except Exception as e:
        logger.error(f"Connection error: {e}")
    finally:
        logger.info("Cleaning up LSP connection...")
        shutdown_event.set()
        # Wait for response thread to finish before closing ws
        response_thread.join(timeout=5)
        proxy.disconnect()
        try:
            ws.close()
        except Exception as e:
            pass # at this point the connection is likely already closed, so we can ignore errors here
        logger.info("LSP endpoint cleanup complete")

# Running the API
if __name__ == "__main__":
    print(f'# Using temporary directory:  "{TEMP_PATH}"')

    # Find a free port for LSP subprocess
    def find_free_port() -> Optional[int]:
        """Find a free port by letting the OS assign one, then return it."""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.bind(("127.0.0.1", 0))  # 0 = let OS choose a free port
            port = s.getsockname()[1]
            s.close()
            return port
        except OSError as e:
            logger.error(f"Failed to find free port: {e}")
            return None

    lsp_port = find_free_port()
    if lsp_port is None:
        logger.error("Failed to find an available port for LSP subprocess. Please check your system resources.")
        sys.exit(1)

    # Set global LSP_PORT for lsp_endpoint to use
    LSP_PORT = lsp_port
    logger.info(f"Starting LSP subprocess on port {LSP_PORT}...")

    # Start LSP subprocess directly
    lsp_command = [
        JAVA_PATH,
        "-cp",
        BPMN4S_GEN,
        "nl.asml.matala.product.lsp.server.ProductServerLauncher",
        "-socket",
        "-port",
        str(LSP_PORT),
    ]

    logger.debug(f"LSP command: {' '.join(lsp_command)}")
    logger.debug(f"Using JAVA_PATH: {JAVA_PATH}")

    lsp_proc: subprocess.Popen = subprocess.Popen(lsp_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    # Give LSP subprocess time to start and listen on socket
    logger.info("Initializing server...")
    time.sleep(2)

    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='BPMN4S CPN Server')
    parser.add_argument('--web-path', type=str, default=WEB_PATH, help='Path to static files directory')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    args = parser.parse_args()
    WEB_PATH = args.web_path
    
    # Set logging level based on debug flag
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    # Find a free port for the CPN server (between 5000 and 5009)
    def find_free_server_port(start_port: int = 5000, end_port: int = 5009) -> int:
        """Find a free port in the specified range.

        Uses SO_EXCLUSIVEADDRUSE on Windows to ensure the port is truly available.
        """
        for port in range(start_port, end_port + 1):
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                if sys.platform == "win32":
                    s.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
                else:
                    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                s.bind(("0.0.0.0", port))
                s.close()
                return port
            except OSError:
                continue
        logger.error(f"No free ports available between {start_port}-{end_port}. Please close other applications and try again.")
        sys.exit(1)

    port = find_free_server_port()

    logger.info(f"Starting BPMN4S server on http://localhost:{port}/")
    url = f"http://localhost:{port}/"
    # Open browser after a short delay to ensure Flask is ready
    def open_browser(url: str, delay: float = 1.5) -> None:
        time.sleep(delay)
        try:
            webbrowser.open_new_tab(url)
            logger.debug(f"Opened browser to {url}")
        except Exception as e:
            logger.warning(f"Could not open browser automatically: {e}")

    browser_thread = threading.Thread(target=open_browser, args=(url,), daemon=True)
    browser_thread.start()

    try:
       # Setting host = "0.0.0.0" runs it on localhost
       app.run(host="0.0.0.0", debug=False, port=port)
    finally:
        logger.info("Shutting down server...")
        if lsp_proc.poll() is None:
            logger.debug("Terminating LSP subprocess...")
            lsp_proc.terminate()
            try:
                lsp_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                logger.debug("LSP subprocess did not respond, force terminating...")
                lsp_proc.kill()
                lsp_proc.wait()
        TEMP_FILE.cleanup()
        logger.info("Server shutdown complete")
