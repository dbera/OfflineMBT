import requests
import json

FILENAME = 'models/Example_Model.bpmn'

files = {
    'Example_Model': ('Example_Model', open(FILENAME, 'rb'), 'text/xml'),
}
response = requests.post(url="http://127.0.0.1:5000/BPMNParser", files=files)
print(f'Parsing BPMN Response: {json.dumps(response.json(), indent=4)}')
uuids = response.json()['response']['module']['loaded']

uuid = uuids[0]

response = requests.get(url=f"http://127.0.0.1:5000/CPNServer/{uuid}/markings")
print(f'Current Marking: {json.dumps(response.json(), indent=4)}')
init_marking = json.loads(response.text)

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

prj_data = {
    'project-id': "myProjectName",
    'generation-block': {
            'label': 'myTestGenItem', 
            'target': 'FAST', 
            'bpmn-file': FILENAME,
            'num-tests': 1, 
            'depth-limit': 10000 
    }
}

files = {
    'prj_params': (None, json.dumps(prj_data), 'application/json'),
    'bpmn_file': ('Example_Model', open(FILENAME, 'rb'), 'text/xml')
}

response = requests.post(url="http://127.0.0.1:5000/TestGenerator", files=files)

content_type = response.headers.get('Content-Type')
if content_type == 'application/zip':
    # Save the ZIP file
    with open('downloaded_file.zip', 'wb') as f:
        f.write(response.content)
    print("ZIP file downloaded successfully.")
elif content_type == 'application/json':
    # Parse the JSON error message
    error_data = response.json()
    print("Error:", error_data)
else:
    print("Unexpected content type:", content_type)

