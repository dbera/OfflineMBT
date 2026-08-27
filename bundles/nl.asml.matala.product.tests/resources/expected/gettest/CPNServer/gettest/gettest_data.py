import copy
import json
if __package__ is None or __package__ == '':
    from gettest_reporting import get_reporting, Location
else:
    from .gettest_reporting import get_reporting, Location

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
    def get_Test():
    	return json.dumps({"aMap":{},"aList":[]})
    	
    @staticmethod
    def get_Single():
    	return json.dumps({"aString":"","aInt":0})
    	
    @staticmethod
    def execute_Root_T1_default_single(test):
    	try:
    	    single = {"aString": list(test["aMap"].items())[2][1], "aInt": test["aList"][2]}
    	except Exception as e:
    	    __location = Location(28,31,523,107,"single := Single { aString = get(test.aMap, 2), aInt = get(test.aList, 2) }")
    	    __source_file = "gettest.ps"
    	    get_reporting().exception(str(e), e, details=__location.text, source=__source_file, location=__location)
    	return json.dumps(single)
    