package nl.asml.matala.product.generator


class FlaskSimulationGenerator 
{
	def generateServer(String prod_name) 
	{
		var txt = 
		'''
		import json
		
		from flask import Flask, request, jsonify
		from «prod_name» import «prod_name»Model
		
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
}