package nl.asml.matala.product.generator

import nl.asml.matala.product.product.Product

class FlaskSimulationGenerator 
{	
	def generateCPNClient(String product_name)
	{
	    return
	    '''
	    import requests
	    import json
	    
	    files = {
	        '«product_name»': ('«product_name»', open('CPNclient.py', 'rb'), 'text/xml'),
	    }
	    response = requests.post(url="http://127.0.0.1:5000/BPMNParser", files=files)
	    print(f'Parsing BPMN Response: {json.dumps(response.json(), indent=4)}')
	    uuids = response.json()['response']['module']['loaded']
	    
	    uuid = uuids[0]
	    
	    response = requests.get(url=f"http://127.0.0.1:5000/CPNServer/{uuid}/markings")
	    print(f'Current Marking: {json.dumps(response.json(), indent=4)}')
	    # init_marking = json.loads(response.text)
	    
	    response = requests.get(url=f"http://127.0.0.1:5000/CPNServer/{uuid}/transitions/enabled")
	    print(f'Enabled Transitions Response: {json.dumps(response.json(), indent=4)}')
	    d = json.loads(response.text)
	    print(f'id_mode_dict: {json.dumps(d["id_mode_dict"], indent=4)}')
	    print(f'id_transition_dict: {json.dumps(d["id_transition_dict"], indent=4)}')
	    
	    payload = {'choice': 0}
	    headers = {'Content-type': 'application/json'}
	    response = requests.post(url=f"http://127.0.0.1:5000/CPNServer/{uuid}/transition/fire", data=json.dumps(payload), headers=headers)
	    print(f'Fired Transition Response: {json.dumps(response.json(), indent=4)}')
	    
	    response = requests.post(url=f"http://127.0.0.1:5000/CPNServer/{uuid}/markings/save", data=json.dumps(payload))
	    print(f'Save Marking Response: {json.dumps(response.json(), indent=4)}')
	    
	    response = requests.post(url=f"http://127.0.0.1:5000/CPNServer/{uuid}/markings/restore", data=json.dumps(payload))
	    print(f'Set Marking Response: {response.text}')
	    
	    response = requests.delete(url=f"http://127.0.0.1:5000/BPMNParser/{uuid}", files=files)
	    print(f'Deleting CPNServer resource: {json.dumps(response.json(), indent=4)}')
	    
	    '''
	}
	
	def generateCPNServer()
	{
	    return
	    '''
	    import json, os
	    import shutil
	    
	    from flask import Flask, request, jsonify
	    from flask_cors import CORS
	    from CPNServer import get_cpn, load_module, unload_module
	    
	    # Initiating a Flask application
	    app = Flask(__name__)
	    CORS(app)
	    
	    # The endpoint of our flask app
	    @app.route(rule="/BPMNParser", methods=["POST"])
	    def handle_bpmn():
	        load_okay, load_fail = [], []
	        _files = request.files
	        for _file in _files:
	            name, filename, fileobj = _file, _files[_file].filename, _files[_file]
	            fileobj.save(filename)
	            # TODO run transformation lib (BPMN -> P-spec)
	            # TODO run OfflineMBT (P-spec -> Python package/Snakes code)
	            try:
	                module = load_module(filename)
	                load_okay.append(name)
	                bpmn_dir = os.path.join(module.__path__[0],'bpmn')
	                os.makedirs(bpmn_dir, exist_ok=True)
	                # os.remove(os.path.join(bpmn_dir, f"{name}.bpmn"))
	                # os.rename(filename, os.path.join(bpmn_dir, f"{name}.bpmn"))
	                shutil.move(filename, os.path.join(bpmn_dir, f"{name}.bpmn"))
	            except Exception as e:
	                load_fail.append({name: str(e)})
	                os.remove(filename)
	    
	        response = {'response': {
	            'message': f'Package loading report',
	            'module': {
	                "loaded": load_okay,
	                "failed": load_fail
	            },
	        }}
	        # return the response as JSON
	        return jsonify(response)
	    
	    
	    # The endpoint of our flask app
	    @app.route(rule="/BPMNParser/<uuid>", methods=["DELETE"])
	    def handle_delete_bpmn(uuid):
	        response = {'response': f'Package {uuid} has been unloaded'}
	        if get_cpn(uuid) is not None:
	            unload_module(uuid)
	        else:
	            response['response'] = f'Package {uuid} does not exist'
	        # return the response as JSON
	        return jsonify(response)
	    
	    
	    # The endpoints of our flask app
	    @app.route(rule="/CPNServer/<uuid>", methods=["GET"])
	    def handle_request(uuid: str):
	        print(f'Received Request [{uuid}]: request_cpn')
	    
	        response = {}
	        pn = get_cpn(uuid)
	        if not pn is None:
	            response['response'] = f'CPN "{uuid}" preloaded'
	        else:
	            response['error'] = f'CPN "{uuid}" not loaded.'
	    
	        return jsonify(response)
	    
	    
	    @app.route(rule="/CPNServer/<uuid>/markings", methods=["GET"])
	    def handle_markings(uuid: str):
	        print(f'Received Request [{uuid}]: get_marking')
	        pn = get_cpn(uuid)
	        json_data = {}
	        current_marking = pn.getCurrentMarking()
	        for k in current_marking:
	            json_data[k] = current_marking[k].items()  # convert multi-set to list with items()
	        response = {'response': json_data}
	        return jsonify(response)
	    
	    
	    @app.route(rule="/CPNServer/<uuid>/transitions/enabled", methods=["GET"])
	    def handle_transitions_enabled(uuid: str):
	        print(f'Received Request [{uuid}]: get_enabled_transitions')
	        pn = get_cpn(uuid)
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
	        pn = get_cpn(uuid)
	        payload = request.get_json()
	        choice = payload['choice']
	        pn.fireEnabledTransition(pn.getEnabledTransitions(), choice)
	        response = {'response': {'executed_transition_idx': choice}}
	        return jsonify(response)
	    
	    
	    @app.route(rule="/CPNServer/<uuid>/markings/save", methods=["POST"])
	    def handle_markings_save(uuid: str):
	        print(f'Received Request [{uuid}]: save_marking')
	        pn = get_cpn(uuid)
	        pn.saveMarking()
	        response = {'response': 'The marking has been saved'}
	        return jsonify(response)
	    
	    
	    @app.route(rule="/CPNServer/<uuid>/markings/restore", methods=["POST"])
	    def handle_markings_reload(uuid: str):
	        print(f'Received Request [{uuid}]: set_marking')
	        pn = get_cpn(uuid)
	        pn.gotoSavedMarking()
	        response = {'response': 'The net has been restored to saved state'}
	        return jsonify(response)
	    
	    
	    # Running the API
	    if __name__ == "__main__":
	        # Setting host = "0.0.0.0" runs it on localhost
	        app.run(host="0.0.0.0", debug=True)
	    
	    '''
	}
	
	def generateServer(String prod_name) 
	{
		var txt = 
		'''
		import json
		
		from flask import Flask, request, jsonify
		if __package__ is None or __package__ == '':
		    from «prod_name» import «prod_name»Model
		else:
		    from .«prod_name» import «prod_name»Model
		
		# Initiating a Flask application
		app = Flask(__name__)
		# Initializing CPN Model
		pn = «prod_name»Model()
		
		
		# The endpoint of our flask app
		@app.route(rule="/CPNServer", methods=["GET", "POST"])
		def handle_request():
		    # The GET endpoint
		    if request.method == "GET":
		        return "This is the GET Endpoint of flask API."
		
		    # The POST endpoint
		    if request.method == "POST":
		        payload = request.get_json()
		        text = payload['request']
		        response = {}
		        if text == 'get_marking':
		            print('Received Request: get_marking')
		            json_data = {}
		            current_marking = pn.getCurrentMarking()
		            for k in current_marking:
		                json_data[k] = current_marking[k].items()  # convert multi-set to list with items()
		            response = {'response': json.dumps(json_data)}
		        elif text == 'get_enabled_transitions':
		            print('Received Request: get_enabled_transitions')
		            enabled_transitions = pn.getEnabledTransitions()
		            id_mode_dict = {}
		            id_transition_dict = {}
		            for _k, _v in enabled_transitions.items():
		                # print(_k)  # choice ids
		                # print(_v[0].name)  # transition object
		                # print(_v[1].dict())  # substitution object
		                id_mode_dict[_k] = _v[1].dict()
		                id_transition_dict[_k] = _v[0].name
		            response = {'id_mode_dict': json.dumps(id_mode_dict),
		                        "id_transition_dict": json.dumps(id_transition_dict)}
		        elif text == 'fire_transition':
		            print('Received Request: fire_transition')
		            choice = payload['choice']
		            pn.fireEnabledTransition(pn.getEnabledTransitions(), choice)
		            response = {'response': json.dumps({'executed_transition_idx': choice})}
		        elif text == 'save_marking':
		            print('Received Request: save_marking')
		            pn.saveMarking()
		            response = {'response': 'The marking has been saved'}
		        elif text == 'goto_saved_marking':
		            print('Received Request: set_marking')
		            pn.gotoSavedMarking()
		            response = {'response': 'The net has been restored to saved state'}
		        else:
		            print(' [FATAL] Undefined Request Type!')
		
		        # return the response as JSON
		        return jsonify(response)
		
		
		# Running the API
		if __name__ == "__main__":
		    # Setting host = "0.0.0.0" runs it on localhost
		    app.run(host="0.0.0.0", debug=True)
		'''
		
		return txt	
	}
	
	def generateClient() 
	{
		var txt = 
		'''
		import requests
		import json
		
		payload = {'request': 'get_marking'}
		headers = {'Content-type': 'application/json'}
		response = requests.post(url="http://127.0.0.1:5000/CPNServer", data=json.dumps(payload), headers=headers)
		print('Current Marking: ', response.text)
		init_marking = json.loads(response.text)
		
		payload = {'request': 'get_enabled_transitions'}
		headers = {'Content-type': 'application/json'}
		response = requests.post(url="http://127.0.0.1:5000/CPNServer", data=json.dumps(payload), headers=headers)
		print('Enabled Transitions Response: ', response.text)
		# d = json.loads(response.text)
		# print(d['id_mode_dict'])
		# print(d['id_transition_dict'])
		
		payload = {'request': 'fire_transition', 'choice': 0}
		headers = {'Content-type': 'application/json'}
		response = requests.post(url="http://127.0.0.1:5000/CPNServer", data=json.dumps(payload), headers=headers)
		print('Fired Transition Response: ', response.text)
		
		payload = {'request': 'save_marking'}
		headers = {'Content-type': 'application/json'}
		response = requests.post(url="http://127.0.0.1:5000/CPNServer", data=json.dumps(payload), headers=headers)
		print('Save Marking Response: ', response.text)
		
		payload = {'request': 'goto_saved_marking'}
		headers = {'Content-type': 'application/json'}
		response = requests.post(url="http://127.0.0.1:5000/CPNServer", data=json.dumps(payload), headers=headers)
		print('Set Marking Response: ', response.text)
		
		'''
		return txt
	}

    def generateInitForCPNSpecPkg(Product prod) 
    {
        var init_for_cpn_spec_pkg = 
        '''
        from .«prod.specification.name» import «prod.specification.name»Model
        
        
        def new_controller():
            return «prod.specification.name»Model()
        '''
        return init_for_cpn_spec_pkg
    }
    
    def generateInitForSrcGen() 
    {
        var init_for_src_gen = 
        '''# Init file to turn src-gen (or other custom dir) as an importable package
        '''
        return init_for_src_gen
    }
    
    def generateInitForCPNServerSpecPkg(Product prod) {
        var init_for_cpn_server_spec_pkg = 
            '''
            from abc import ABC, abstractmethod
            
            import sys
            import types
            import typing
            import importlib.util
            from abc import ABC, abstractmethod
            
            
            class AbstractCPNControl(ABC):
            
                @abstractmethod
                def getCurrentMarking(self):
                    pass
            
                @abstractmethod
                def getEnabledTransitions(self):
                    pass
            
                @staticmethod
                @abstractmethod
                def fireEnabledTransition(self, choices, cid):
                    pass
            
                @abstractmethod
                def getEnabledTransitions(self):
                    pass
            
                @abstractmethod
                def saveMarking(self):
                    pass
            
                @abstractmethod
                def gotoSavedMarking(self):
                    pass
            
            
            # Initializing CPN Model
            pn: typing.Dict[str, AbstractCPNControl] = {}
            
            
            def load_module(source, package="CPNServer") -> types.ModuleType:
                """
                pre-loads file source as a module, and
                returns a CPN instance.
            
                :param source: submodule to be loaded
                :param package: prefix of package in which source is found (Default: CPNServer)
                :return: loaded module
                """
            
                spec = importlib.util.find_spec(f".{source}", package=package)
                assert spec is not None, f"Package \"{package}.{source}\" not found!"
            
                module = importlib.util.module_from_spec(spec)
                sys.modules[f"{package}.{source}"] = module
                spec.loader.exec_module(module)
            
                pn[source] = module.new_controller()
                return module
            
            
            def unload_module(source, package="CPNServer") -> types.ModuleType:
                """
                dereferences a module, and deletes CPN instance.
            
                :param source: submodule to be unloaded
                :param package: prefix of package in which source is found (Default: CPNServer)
                """
            
                del sys.modules[f"{package}.{source}"]
                del pn[source]
            
            
            def get_cpn(name) -> AbstractCPNControl:
                """
                returns an instance of CPN using module "source"
            
                :param name: unique identifier for the CPN
                :return: instance of CPN controller
                """
            
                if not name in pn.keys():
                    return None
                return pn[name]

            '''
        return init_for_cpn_server_spec_pkg
    }
    
    def generateServerUtils(Product prod) {
            var server_utils = 
            '''
            import sys
            import types
            import typing
            import importlib.util
            from abc import ABC, abstractmethod
            
            from CPNServer.utils import AbstractCPNControl
            
            # Initializing CPN Model
            pn: typing.Dict[str, AbstractCPNControl] = {}
            
            
            def load_module(source, package="CPNServer") -> types.ModuleType:
                """
                pre-loads file source as a module, and
                returns a CPN instance.
            
                :param source: submodule to be loaded
                :param package: prefix of package in which source is found (Default: CPNServer)
                :return: loaded module
                """
            
                spec = importlib.util.find_spec(f".{source}", package=package)
                assert spec is not None, f"Package \"{package}.{source}\" not found!"
            
                module = importlib.util.module_from_spec(spec)
                sys.modules[f"{package}.{source}"] = module
                spec.loader.exec_module(module)
            
                pn[source] = module.new_controller()
                return module
            
            
            def unload_module(source, package="CPNServer") -> types.ModuleType:
                """
                dereferences a module, and deletes CPN instance.
            
                :param source: submodule to be unloaded
                :param package: prefix of package in which source is found (Default: CPNServer)
                """
            
                del sys.modules[f"{package}.{source}"]
                del pn[source]
            
            
            def get_cpn(name) -> AbstractCPNControl:
                """
                returns an instance of CPN using module "source"
            
                :param name: unique identifier for the CPN
                :return: instance of CPN controller
                """
            
                if not name in pn.keys():
                    return None
                return pn[name]
            
            class AbstractCPNControl(ABC):
            
                @abstractmethod
                def getCurrentMarking(self):
                    pass
            
                @abstractmethod
                def getEnabledTransitions(self):
                    pass
            
                @staticmethod
                @abstractmethod
                def fireEnabledTransition(self, choices, cid):
                    pass
            
                @abstractmethod
                def getEnabledTransitions(self):
                    pass
            
                @abstractmethod
                def saveMarking(self):
                    pass
            
                @abstractmethod
                def gotoSavedMarking(self):
                    pass
            '''
            return server_utils
    }

}