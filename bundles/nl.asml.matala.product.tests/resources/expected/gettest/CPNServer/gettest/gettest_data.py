import copy
import json


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
    	single = {"aString": list(test["aMap"].items())[2][1], "aInt": test["aList"][2]}
    	return json.dumps(single)
    
