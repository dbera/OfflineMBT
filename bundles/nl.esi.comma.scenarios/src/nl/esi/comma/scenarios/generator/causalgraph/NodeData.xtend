package nl.esi.comma.scenarios.generator.causalgraph

import java.util.Map
import java.util.LinkedHashMap

class NodeData {
	public Map<String, String> dataMap
	public String scnID
	public int index
	
	new(String scnID, int index) {
		this.scnID = scnID
		this.index = index
		this.dataMap = new LinkedHashMap<String, String>
	}
	
	def addData(String key, String value) {
		this.dataMap.put(key, value)
	}
	
	def isEqualDataMap(Map<String, String> dMap) {
	    // return dataMap.values.containsAll(dMap.values) 
	    // gets confused since it is being treated as set. if arguments are shuffled in two iterations.
	    // e.g. _layout_is_and_is_not_active_in_the_view_ :  iter 1 - TwoByTwo, SideBySide iter 2 - SideBySide, TwoByTwo
	    // DB Fix 06.05.2022. TODO to be qualified...
	    var outcome = true
	    for(k : dataMap.keySet) {
	        if(dMap.containsKey(k)) {
	            if(!dataMap.get(k).equals(dMap.get(k))) outcome = false
	        } else outcome = false
	    }
	    return outcome	    
	}
	
	def print() {
	    System.out.println(" Printing Node Data: " + scnID)
	    System.out.println(" Printing Node Index: " + index)
	    System.out.println(" Printing Node DataMap: " + dataMap)
	}
}