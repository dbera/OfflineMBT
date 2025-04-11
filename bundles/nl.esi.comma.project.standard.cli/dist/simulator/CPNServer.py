#!/usr/bin/env python3

import os
import sys
import tempfile
import subprocess

import CPNUtils as utils
from flask import Flask, request, jsonify
from flask_cors import CORS

BPMN4S_GEN = os.path.join("bpmn4s-generator.jar")
JAVA_PATH  = os.path.join("jre","bin","java.exe")

TEMP_FILE   = tempfile.TemporaryDirectory(prefix=f'{utils.gensym(prefix="cpnserver_",timestamp=True)}_')
TEMP_PATH   = TEMP_FILE.name
sys.path.append(TEMP_PATH)

# Initiating a Flask application
app = Flask(__name__)
CORS(app)

def build_and_load_model( model_name:str , filepath=""):
    
    prj_template:str = """
    Project project {{
      Generate Simulator {{
        simulator {{
          product-file "{0}.bpmn"
        }}
      }}
    }}
    """
    
    prj_filename:str = os.path.join(filepath,f'{model_name}.prj')
    with open(prj_filename, "w") as file1:
        prj_content = prj_template.format(model_name)
        file1.write(prj_content)
    result = subprocess.run([JAVA_PATH,"-jar",BPMN4S_GEN,"-l", prj_filename,"-o", filepath],shell=True, capture_output=True)
    if result.returncode != 0: 
        raise Exception(result.stderr)
    module = utils.load_module(model_name)
    return module

# The endpoint of our flask app
@app.route(rule="/BPMNParser", methods=["POST"])
def handle_bpmn():
    status_code = 200
    
    load_okay, load_fail = [], []
    _files = request.files
    for _file in _files:
        fname, fobj = _files[_file].filename, _files[_file]
        filename = f'{fname}{utils.gensym(prefix="_",timestamp=True)}_'
        tmp_path = os.path.join(TEMP_PATH,f"{filename}.bpmn")
        try:
            with utils.lock_handle_bpmn():
                if utils.is_loaded_module(filename): 
                    raise Exception(F"BPMN model '{filename}' is already loaded!")
                fobj.save(tmp_path)
                module = build_and_load_model(filename,filepath=TEMP_PATH)
            load_okay.append(filename)
            bpmn_dir = os.path.join(module.__path__[0],'bpmn')
            os.makedirs(bpmn_dir, exist_ok=True)
            filename_wildcard = os.path.join(TEMP_PATH,f"{filename}.*")
            utils.move(filename_wildcard, bpmn_dir)
        except Exception as e:
            status_code = 400
            load_fail.append({filename: str(e)})
            print(str(e),file=sys.stderr)

    response = {'response': {
        'message': f'Package loading report',
        'module': {
            "loaded": load_okay,
            "failed": load_fail
        },
    }}
    # return the response as JSON
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
    pn.fireEnabledTransition(pn.getEnabledTransitions(), choice)
    response = {'response': {'executed_transition_idx': choice}}
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


# TEMP_FILE.cleanup()
