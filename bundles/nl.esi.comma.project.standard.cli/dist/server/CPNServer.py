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

FastAPI web server providing REST API endpoints for BPMN model simulation and
test generation. Manages LSP subprocess on a dynamically allocated WebSocket
port, forwarding WebSocket messages between clients and the Language Server
Protocol backend. Supports scenario loading, state management, and transition
firing.
"""

import os
import sys
import json
import shutil
import tempfile
import subprocess
import threading
import asyncio
import socket
import logging
import time
import webbrowser
import argparse
from typing import Optional
from contextlib import asynccontextmanager

try:
    from . import CPNUtils as utils   # when run as package (-m server.CPNServer)
except ImportError:
    import CPNUtils as utils          # when run directly (python server/CPNServer.py)

from fastapi import FastAPI, UploadFile, File, Form, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware

import websockets

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
logger.setLevel(logging.INFO)  # Default to INFO, can be set to DEBUG with command-line flag

SERVER_PATH = os.path.dirname(os.path.abspath(__file__))
                           
BPMN4S_JAR_NAME = "bpmn4s-toolchain.jar"
BPMN4S_GEN = os.path.join(SERVER_PATH, BPMN4S_JAR_NAME)
JAVA_REL_PATH = ("jre", "bin", "java.exe")
JAVA_PATH = os.path.join(SERVER_PATH, *JAVA_REL_PATH)

TEMP_FILE   = tempfile.TemporaryDirectory(prefix=f'{utils.gensym(prefix="cpnserver_",timestamp=True)}_', ignore_cleanup_errors=True)
TEMP_PATH = os.path.abspath(TEMP_FILE.name)
sys.path.append(TEMP_PATH)

# LSP subprocess port - will be set at runtime
LSP_PORT: Optional[int] = None

# Static files path - will be set from command-line arguments
WEB_PATH = os.path.join(os.path.dirname(__file__), '..', 'web')

# LSP subprocess handle - set in __main__, used by lifespan for cleanup
lsp_proc: Optional[subprocess.Popen] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown hooks replacing Flask's try/finally pattern."""
    yield
    # Shutdown
    logger.info("Shutting down server...")
    if lsp_proc is not None and lsp_proc.poll() is None:
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

# Initiating a FastAPI application
app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    if result.stdout:
        logger.debug("build_and_load_model stdout: %s", result.stdout.decode('utf-8', errors='replace').rstrip())
    if result.stderr:
        logger.debug("build_and_load_model stderr: %s", result.stderr.decode('utf-8', errors='replace').rstrip())
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

def generate_tests( model_path:str, num_tests:int=1, depth_limit:int=500, state_limit:int=1000):
    
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
          state-limit {4}
        }}
      }}
    }}
    """
    
    prj_filename:str = os.path.join(model_dir,f'{model_name}.prj')
    with open(prj_filename, "w") as file1:
        prj_content = prj_template.format(taskname,model_name,num_tests,depth_limit,state_limit)
        file1.write(prj_content)
    result = subprocess.run([JAVA_PATH,"-jar",BPMN4S_GEN,"-l", prj_filename],shell=True, capture_output=True)
    if result.stdout:
        logger.debug("generate_tests stdout: %s", result.stdout.decode('utf-8', errors='replace').rstrip())
    if result.stderr:
        logger.debug("generate_tests stderr: %s", result.stderr.decode('utf-8', errors='replace').rstrip())
    if result.returncode != 0: 
        raise utils.BPMN4SException(
            cliargs={
                'bpmn-file': model_name,
                'num-tests': num_tests,
                'depth-limit': depth_limit,
                'state-limit': state_limit
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
        logger.error(f"An error occurred while deleting generated test: {str(e)}", file=sys.stderr)
    return zip_filename, result

# The endpoint of our FastAPI app
@app.post("/BPMNParser")
async def handle_bpmn(bpmn_file: UploadFile = File(alias="bpmn-file")):
    fname = bpmn_file.filename
    filename = fname + utils.gensym(prefix="_",timestamp=True)
    bpmn_path = os.path.join(TEMP_PATH,f"{filename}.bpmn")

    contents = await bpmn_file.read()
    with open(bpmn_path, "wb") as f:
        f.write(contents)

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
        failed['exception'] = format_error(e)

    # return the response as JSON
    return JSONResponse(response, status_code=status_code)


@app.post("/TestGenerator")
async def test_generator(
    bpmn_file: UploadFile = File(alias="bpmn-file"),
    prj_params: Optional[str] = Form(None, alias="prj-params"),
):
    _args = json.loads(prj_params) if prj_params else {}

    numTests = _args.get('num-tests',1)
    depthLimit = _args.get('depth-limit',1000)
    stateLimit = _args.get('state-limit',1000)

    fname = bpmn_file.filename
    filename = fname + utils.gensym(prefix="_",timestamp=True)
    model_path = os.path.join(TEMP_PATH,f"{filename}.bpmn")

    contents = await bpmn_file.read()
    with open(model_path, "wb") as f:
        f.write(contents)

    status_code = 200
    response = {'response': {'uuid': filename}}
    try:
        zip_fname, result = generate_tests(model_path, num_tests=numTests, depth_limit=depthLimit, state_limit=stateLimit)
        zip_dir, zip_path = os.path.split(zip_fname)
        return FileResponse(os.path.join(zip_dir, zip_path), media_type='application/zip', filename=zip_path)
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
        failed['exception'] = format_error(e)

    return JSONResponse(response, status_code=status_code)

# The endpoint of our FastAPI app
@app.delete("/BPMNParser/{uuid}")
async def handle_delete_bpmn(uuid: str):
    response = {'response': f'Error (un)loading Package {uuid}'}
    with utils.lock_handle_bpmn(): 
        if utils.get_cpn(uuid) is not None:
            utils.unload_module(uuid)
            response['response'] = f'Package {uuid} has been unloaded'
        else:
            response['response'] = f'Package {uuid} does not exist'
    # return the response as JSON
    return JSONResponse(response)


# The endpoints of our FastAPI app
@app.get("/CPNServer/{uuid}")
async def handle_request(uuid: str):
    logger.debug(f'Received Request [{uuid}]: request_cpn')

    response = {}
    pn = utils.get_cpn(uuid)
    if not pn is None:
        response['response'] = f'CPN "{uuid}" preloaded'
    else:
        response['error'] = f'CPN "{uuid}" not loaded.'

    return JSONResponse(response)


@app.post("/CPNServer/{uuid}/scenario/load")
async def handle_scenario_load(uuid: str, scenario_file: UploadFile = File(alias="scenario-file")):
    logger.debug(f'Received Request [{uuid}]: load_scenario')
    pn = utils.get_cpn(uuid)

    status_code = 200
    response = {}
    try:
        contents = await scenario_file.read()
        scenarioJson = json.loads(contents)
        pn.loadScenario(scenarioJson)
        response['message'] = 'The scenario has been loaded'
        response['steps'] = len(scenarioJson)

    except Exception as e:
        status_code = 400
        response['exception'] = format_error(e)

    return JSONResponse(response, status_code=status_code)


@app.get("/CPNServer/{uuid}/markings")
async def handle_markings(uuid: str):
    logger.debug(f'Received Request [{uuid}]: get_marking')
    pn = utils.get_cpn(uuid)
    json_data = {}
    current_marking = pn.getCurrentMarking()
    for k in current_marking:
        json_data[k] = current_marking[k].items()  # convert multi-set to list with items()
    response = {'response': json_data}
    return JSONResponse(response)


@app.get("/CPNServer/{uuid}/transitions/enabled")
async def handle_transitions_enabled(uuid: str):
    logger.debug(f'Received Request [{uuid}]: get_enabled_transitions')
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
        response['exception'] = format_error(e)

    return JSONResponse(response, status_code=status_code)


@app.post("/CPNServer/{uuid}/transition/fire")
async def handle_transition_fire(uuid: str, payload: dict):
    logger.debug(f'Received Request [{uuid}]: fire_transition')
    pn = utils.get_cpn(uuid)
    choice = payload['choice']
    enabled_t = pn.getEnabledTransitions()
    _r = pn.fireEnabledTransition(enabled_t, choice)

    marks_data = {}
    for idx, item in enumerate(_r):
        marks_data[idx] = {}
        for k in item:
            marks_data[idx][k] = item[k].items()  # convert multi-set to list with items()
    response = {'response': {'executed_transition_idx': choice, 'markings_consumed': marks_data[0],'markings_produced': marks_data[1]}}
    return JSONResponse(response)


@app.post("/CPNServer/{uuid}/markings/save")
async def handle_markings_save(uuid: str):
    logger.debug(f'Received Request [{uuid}]: save_marking')
    pn = utils.get_cpn(uuid)
    pn.saveMarking()
    response = {'response': 'The marking has been saved'}
    return JSONResponse(response)


@app.post("/CPNServer/{uuid}/markings/restore")
async def handle_markings_reload(uuid: str):
    logger.debug(f'Received Request [{uuid}]: set_marking')
    pn = utils.get_cpn(uuid)
    pn.gotoSavedMarking()
    response = {'response': 'The net has been restored to saved state'}
    return JSONResponse(response)

@app.post("/CPNServer/{uuid}/markings/goto")
async def handle_markings_goto(uuid: str, payload: dict):
    logger.debug(f'Received Request [{uuid}]: goto_marking')
    pn = utils.get_cpn(uuid)
    index = payload['index']
    pn.gotoMarking(index)
    response = {'response': 'The net has been restored to the marking'}
    return JSONResponse(response)

# The root will serve index.html from ../web
@app.get("/")
async def index():
    response = FileResponse(os.path.join(WEB_PATH, "index.html"))
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    return response

# This route handles any web files in the root directory
@app.get("/{path:path}")
async def get(path: str):
    return serve_web(path)

def serve_web(path: str):
    web_file = os.path.join(WEB_PATH, path)
    if os.path.exists(web_file):
        return FileResponse(web_file)
    else:
        return JSONResponse({"error": f"File not found {path}"}, status_code=404)

# A Proxy to the java lsp server via WebSocket
@app.websocket("/lsp")
async def lsp_endpoint(ws: WebSocket):
    """WebSocket endpoint that proxies messages to LSP subprocess."""
    await ws.accept()
    logger.info("Client connected to LSP endpoint...")

    if LSP_PORT is None:
        logger.error("Error: LSP subprocess port not set")
        try:
            error_msg = {
                "jsonrpc": "2.0",
                "error": {"code": -32603, "message": "LSP server not available"},
            }
            await ws.send_text(json.dumps(error_msg))
        except Exception:
            pass
        await ws.close()
        return

    backend_url = f"ws://127.0.0.1:{LSP_PORT}"
    try:
        async with websockets.connect(backend_url) as lsp_ws:
            logger.info(f"Connected to LSP subprocess on port {LSP_PORT}")

            async def client_to_backend():
                """Forward messages from browser client -> LSP backend."""
                try:
                    while True:
                        data = await ws.receive_text()
                        await lsp_ws.send(data)
                except WebSocketDisconnect:
                    logger.info("LSP client disconnected")
                except Exception as e:
                    logger.debug(f"client_to_backend ended: {e}")

            async def backend_to_client():
                """Forward messages from LSP backend -> browser client."""
                try:
                    async for message in lsp_ws:
                        if isinstance(message, str):
                            await ws.send_text(message)
                        elif isinstance(message, bytes):
                            await ws.send_bytes(message)
                except websockets.exceptions.ConnectionClosed:
                    logger.info("LSP backend connection closed")
                except Exception as e:
                    logger.debug(f"backend_to_client ended: {e}")

            # Run both directions concurrently; first to finish cancels the other
            done, pending = await asyncio.wait(
                [
                    asyncio.create_task(client_to_backend()),
                    asyncio.create_task(backend_to_client()),
                ],
                return_when=asyncio.FIRST_COMPLETED,
            )
            for task in pending:
                task.cancel()

    except Exception as e:
        logger.error(f"LSP proxy error: {e}")
    finally:
        try:
            await ws.close()
        except Exception:
            pass
        logger.info("LSP endpoint cleanup complete")

def format_error(e: Exception) -> str:
    return f"{type(e).__name__}: {str(e)}"

# Running the API
if __name__ == "__main__":
    import uvicorn

    logger.info(f'# Using temporary directory:  "{TEMP_PATH}"')

    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='BPMN4S CPN Server')
    parser.add_argument('--web-path', type=str, default=WEB_PATH, help='Path to static files directory')
    parser.add_argument('--server-path', type=str, default=SERVER_PATH, help='Path to static server directory')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    args = parser.parse_args()
    WEB_PATH = args.web_path
    SERVER_PATH = args.server_path
    BPMN4S_GEN = os.path.join(SERVER_PATH, BPMN4S_JAR_NAME)
    JAVA_PATH = os.path.join(SERVER_PATH, *JAVA_REL_PATH)

    # Set logging level based on debug flag
    if args.debug:
        logger.setLevel(logging.DEBUG)


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
        "-ws",
        "-port",
        str(LSP_PORT),
    ]

    logger.debug(f"LSP command: {' '.join(lsp_command)}")
    logger.debug(f"Using JAVA_PATH: {JAVA_PATH}")

    lsp_proc = subprocess.Popen(
        lsp_command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    # Forward LSP subprocess stdout/stderr to our logger in background threads
    def _pipe_reader(pipe, level, prefix):
        """Read lines from a subprocess pipe and log them."""
        try:
            for line in pipe:
                line = line.rstrip("\n\r")
                if line:
                    logger.log(level, "%s: %s", prefix, line)
        except Exception:
            pass

    threading.Thread(
        target=_pipe_reader,
        args=(lsp_proc.stdout, logging.DEBUG, "LSP stdout"),
        daemon=True,
    ).start()
    threading.Thread(
        target=_pipe_reader,
        args=(lsp_proc.stderr, logging.DEBUG, "LSP stderr"),
        daemon=True,
    ).start()

    # Give LSP subprocess time to start and listen on socket
    logger.info("Initializing server...")
    time.sleep(2)

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

    logger.info(f"Starting BPMN4S server on http://127.0.0.1:{port}/")
    url = f"http://127.0.0.1:{port}/"
    # Open browser after a short delay to ensure server is ready
    def open_browser(url: str, delay: float = 1.5) -> None:
        time.sleep(delay)
        try:
            webbrowser.open_new_tab(url)
            logger.debug(f"Opened browser to {url}")
        except Exception as e:
            logger.warning(f"Could not open browser automatically: {e}")
    # only that the browser if index.html exists in the web path, otherwise it will just open a blank page which is not ideal
    
    if os.path.exists(os.path.join(WEB_PATH, "index.html")):
        browser_thread = threading.Thread(target=open_browser, args=(url,), daemon=True)
        browser_thread.start()
    else:
        logger.warning(f"index.html not found in {WEB_PATH}, skipping automatic browser launch.")

    # Setting host = "0.0.0.0" runs it on localhost
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="debug" if args.debug else "warning")
