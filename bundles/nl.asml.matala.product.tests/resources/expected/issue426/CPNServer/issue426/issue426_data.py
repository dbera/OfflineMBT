import copy
import json
if __package__ is None or __package__ == '':
    from issue426_reporting import get_reporting, Location
else:
    from .issue426_reporting import get_reporting, Location

class Data:
    
    @staticmethod
    def int_keys(ordered_pairs):
        result = {}
        for key, value in ordered_pairs:
            try:
                key = int(key)
            except ValueError:
                pass
            result[key] = value
        return result
    
    @staticmethod
    def get_UNIT():
    	return json.dumps({"unit":0})
    	
    @staticmethod
    def get_TheType():
    	return json.dumps({"id":0,"counter":0})
    	
    @staticmethod
    def execute_Issue426_D_default_Event_04j9655(Flow_11d1u6w,params):
    	try:
    	    Event_04j9655 = Flow_11d1u6w
    	except Exception as e:
    	    __location = Location(35,35,698,29,"Event_04j9655 := Flow_11d1u6w")
    	    __source_file = "issue426.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Event_04j9655)
    
    @staticmethod
    def execute_Issue426_C_default_Flow_11d1u6w(Flow_109yqzk):
    	try:
    	    Flow_11d1u6w = Flow_109yqzk
    	except Exception as e:
    	    __location = Location(43,43,943,28,"Flow_11d1u6w := Flow_109yqzk")
    	    __source_file = "issue426.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_11d1u6w)
    
    @staticmethod
    def execute_Issue426_C_default_params(Flow_109yqzk):
    	try:
    	    params = {"id": Flow_109yqzk["id"], "counter": Flow_109yqzk["counter"]}
    	except Exception as e:
    	    __location = Location(46,49,1047,112,"params := TheType { id = Flow_109yqzk.id, counter = Flow_109yqzk.counter }")
    	    __source_file = "issue426.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(params)
    
    @staticmethod
    def execute_Issue426_A_default_Flow_1ew3pv8(Event_01uaof6):
    	try:
    	    Flow_1ew3pv8 = Event_01uaof6
    	except Exception as e:
    	    __location = Location(57,57,1339,29,"Flow_1ew3pv8 := Event_01uaof6")
    	    __source_file = "issue426.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    for idx in list(range(0, 5)):
    	    	Flow_1ew3pv8["counter"] = Flow_1ew3pv8["counter"] + idx
    	except Exception as e:
    	    __location = Location(58,60,1381,114,"for int idx in range(0, 5) do Flow_1ew3pv8.counter := Flow_1ew3pv8.counter + idx end-for")
    	    __source_file = "issue426.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_1ew3pv8)
    
    @staticmethod
    def execute_Issue426_B_default_Flow_109yqzk(Flow_1ew3pv8):
    	try:
    	    Flow_109yqzk = Flow_1ew3pv8
    	except Exception as e:
    	    __location = Location(68,68,1674,28,"Flow_109yqzk := Flow_1ew3pv8")
    	    __source_file = "issue426.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    for idx in list(range(5, 10)):
    	    	Flow_109yqzk["counter"] = Flow_109yqzk["counter"] + idx
    	except Exception as e:
    	    __location = Location(69,71,1715,115,"for int idx in range(5, 10) do Flow_109yqzk.counter := Flow_109yqzk.counter + idx end-for")
    	    __source_file = "issue426.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Flow_109yqzk)
    