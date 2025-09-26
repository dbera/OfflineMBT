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


import os
import sys
import json
import shutil
import tempfile
import subprocess

import CPNUtils as utils
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

BPMN4S_GEN = os.path.join("bpmn4s-toolchain.jar")
JAVA_PATH  = os.path.join("jre","bin","java.exe")

TEMP_FILE   = tempfile.TemporaryDirectory(prefix=f'{utils.gensym(prefix="cpnserver_",timestamp=True)}_', ignore_cleanup_errors=True)
TEMP_PATH   = os.path.abspath(TEMP_FILE.name)
sys.path.append(TEMP_PATH)

# Initiating a Flask application
app = Flask(__name__)
CORS(app)

def build_and_load_model(model_path:str):

    model_dir, model_name = os.path.split(model_path)
    model_name, model_ext = os.path.splitext(model_name)
    model_name = utils.to_valid_variable_name(model_name)
    taskname:str = f"simulator"
    prj_template:str = """Project project {{
    Generate Simulator {{
        {0} {{
          bpmn-file "{1}.bpmn"
        }}
      }}
    }}
    """
    
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
    module = utils.load_module(source=model_name,package=f"src-gen.{taskname}.CPNServer")
    bpmn_dir = os.path.join(module.__path__[0],'bpmn')
    os.makedirs(bpmn_dir, exist_ok=True)
    filename_wildcard = os.path.join(TEMP_PATH,f"{model_name}.*")
    utils.move(filename_wildcard, bpmn_dir)
    return module, result

def generate_fast_tests( model_path:str, num_tests:int=1, depth_limit:int=500):
    
    model_dir, model_name = os.path.split(model_path)
    model_name, model_ext = os.path.splitext(model_name)
    model_name = utils.to_valid_variable_name(model_name)
    taskname:str = f"testgen"
    prj_template:str = """Project project {{
      Generate FAST {{
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
    filename = fname
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
    filename = fname
    model_path = os.path.join(TEMP_PATH,f"{filename}.bpmn")
    _bpmn.save(model_path)

    status_code = 200
    response = {'response': {'uuid': filename}}
    try:
        zip_fname, result = generate_fast_tests(model_path, num_tests=numTests, depth_limit=depthLimit)
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
    enabled_transitions = pn.getEnabledTransitions()
    id_mode_dict = {}
    id_transition_dict = {}
    for _k, _v in enabled_transitions.items():
        # print(_k)  # choice ids
        # print(_v[0].name)  # transition object
        # print(_v[1].dict())  # substitution object
        id_mode_dict[_k] = _v[1].dict()
        id_transition_dict[_k] = _v[0].name
    response = {'id_mode_dict': id_mode_dict,
                "id_transition_dict": id_transition_dict}
    return jsonify(response)


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

# Running the API
if __name__ == "__main__":
    # Setting host = "0.0.0.0" runs it on localhost
    app.run(host="0.0.0.0", debug=False)

    TEMP_FILE.cleanup()