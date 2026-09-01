import copy
import json
if __package__ is None or __package__ == '':
    from issue371_reporting import get_reporting, Location
else:
    from .issue371_reporting import get_reporting, Location

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
    def get_MyContext():
    	return json.dumps({"myField":0})
    	
    @staticmethod
    def execute_Root_T1_default_Event_1bks5sc(Event_0o4qsh5):
    	try:
    	    Event_1bks5sc = Event_0o4qsh5
    	except Exception as e:
    	    __location = Location(26,26,485,30,"Event_1bks5sc := Event_0o4qsh5")
    	    __source_file = "issue371.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    if True:
    	    	pass
    	    else:
    	    	pass
    	except Exception as e:
    	    __location = Location(27,31,528,90,"if true then // Empty else // Empty fi")
    	    __source_file = "issue371.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    for i in list(range(2)):
    	    	pass
    	except Exception as e:
    	    __location = Location(32,34,631,67,"for int i in range(2) do // Empty end-for")
    	    __source_file = "issue371.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	try:
    	    if not (False):
    	    	Event_1bks5sc["myField"] = 1
    	except Exception as e:
    	    __location = Location(35,37,711,73,"if not false then Event_1bks5sc.myField := 1 fi")
    	    __source_file = "issue371.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(Event_1bks5sc)
    