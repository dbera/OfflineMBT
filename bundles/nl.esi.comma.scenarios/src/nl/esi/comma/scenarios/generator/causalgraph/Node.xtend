package nl.esi.comma.scenarios.generator.causalgraph

import java.util.List
import java.util.ArrayList
import java.util.Set
import java.util.HashSet
import nl.esi.comma.scenarios.scenarios.ActionType
import java.util.LinkedHashSet
import java.util.Map
import java.util.HashMap

class Node {
	public String actionName
	public List<Edge> edges = new ArrayList<Edge>
	public boolean init
	public boolean terminal
	public Set<String> scnIDs = new HashSet<String>
	public Map<String, Set<String>> mapIDtoProductSet = new HashMap<String, Set<String>>
	public ActionType type
	public HashSet<NodeData> datas = new LinkedHashSet<NodeData>
	public HashSet<String> configs = new HashSet<String>
	public HashSet<String> productSet = new HashSet<String>
	public HashSet<String> eventSet = new HashSet<String>
	public HashSet<String> changeType = new HashSet<String>
	
	new(Node n) {
	    this.actionName = n.actionName
	    for(e : n.edges) this.edges.add(e)
	    this.init = n.init
	    this.terminal = n.terminal
	    for(id : n.scnIDs) this.scnIDs.add(id)
	    for(id : n.mapIDtoProductSet.keySet) this.mapIDtoProductSet.put(id,n.mapIDtoProductSet.get(id))
	    this.type = n.type
	    for(d : n.datas) this.datas.add(d)
	    for(c : n.configs) this.configs.add(c)
	    for(p : n.productSet) this.productSet.add(p)
	    for(e : n.eventSet) this.eventSet.add(e)
	    for(c : n.changeType) this.changeType.add(c)
	}
	
	new(){
		this.actionName = ""
		this.changeType = new HashSet<String>
	}
	
	new(String name, boolean init, boolean terminal) {
		this.actionName = name
		this.init = init
		this.terminal = terminal
		this.changeType = new HashSet<String>
	}
	
	new(String name, ActionType type, boolean init, boolean terminal) {
		this.actionName = name
		this.type = type
		this.init = init
		this.terminal = terminal
	}
	
	def addScnID(String scnID) {
		this.scnIDs.add(scnID)
	}
	
	def addData(NodeData data) {
		this.datas.add(data)
	}
	
	def addIDtoProductSet(String id, List<String> prodSet) {
	    if(this.mapIDtoProductSet.keySet.contains(id)) {
	        if(prodSet!==null) mapIDtoProductSet.get(id).addAll(prodSet)
	        else mapIDtoProductSet.get(id).addAll(new ArrayList<String>)
	    } else {
	        var tmp = new HashSet<String>
	        if(prodSet!==null) tmp.addAll(prodSet)
	        else tmp.addAll(new ArrayList<String>)
	        mapIDtoProductSet.put(id, tmp)
	    }
	}
	
	def addConfig(List<String> config) {
		this.configs.addAll(config)
	}
	
	def addProductSet(List<String> prodSet) {
		this.productSet.addAll(prodSet)
	}
	
	def addEvents(List<String> events) {
		this.eventSet.addAll(events)
	}
	
	def addEdges(Edge e){
		this.edges.add(e)
	}
	
	def getEdge(String src, String dst){
		for (e : edges){
			if (e.src.equals(src) 
				&& e.dst.equals(dst)){
				return e
			}
		}
		return null
	}
	
	def setEdgeChangeType(String src, String dst, String type){
		for (var i = 0; i < this.edges.size; i++){
			if (this.edges.get(i).src.equals(src) 
				&& this.edges.get(i).dst.equals(dst)){
				this.edges.get(i).changeType = type
			}
		}
	}
	
	def addChangeType(String type){
		this.changeType.add(type)
	}
	
	// Functions for Test Set Selection
	
	def Set<String> getProductSet(String id) {
	    if(mapIDtoProductSet.containsKey(id))
	       return mapIDtoProductSet.get(id)
	    return new HashSet<String>
	}
		
	def Map<String, Set<String>> selectAllSCNID() {
	     var m = new HashMap<String, Set<String>>
	     for(id : this.scnIDs) {
	         if(this.mapIDtoProductSet.get(id) !== null)
	           m.put(id, this.mapIDtoProductSet.get(id))
	         else m.put(id, new HashSet<String>)
	     }
	     return m
	}
	
	def Map<String, Set<String>> selectAllSCNID(Edge e) {
	    var m = new HashMap<String, Set<String>>
	    // find the matching edge
	    for(edge : this.edges) {
	        if(edge.src.equals(e.src) && edge.dst.equals(e.dst)) {
                for(id : edge.scnIDs) {
                    if(this.mapIDtoProductSet.get(id) !== null)
                        m.put(id, this.mapIDtoProductSet.get(id))
                    else m.put(id, new HashSet<String>)
                }
	        }
	    }
	    return m
	}

    // optimizes previous method: selectAllSCNID
    // selects test scenarios for distinct configurations (not random; based on order of traversal)
    // ignores causal SCNID
    // ms1: Extend to select based on degree of similarity to reference test scenario (select farthest distance)
    def Map<String, Set<String>> selectMinSCNID(Edge e, String scnID) {
        var m = new HashMap<String, Set<String>>
        // find the matching edge
        for(edge : this.edges) {
            if((edge.src.equals(e.src) && edge.dst.equals(e.dst))) {
                var _m = new HashMap<String, Set<String>>
                for(id : edge.scnIDs) {
                    // Add SCNID if the product set it introduces is unique for the edge
                    // skip causal SCN ID
                    if(!scnID.equals(id)) {
                        if(mapIDtoProductSet.get(id) === null) {
                            if(_m.isEmpty) {
                                m.put(id, new HashSet<String>)
                                _m.put(id, new HashSet<String>)
                            }
                        }
                        else {
                            if(!_m.values.contains(mapIDtoProductSet.get(id))) { // note this is check on sets of products. not individual!
                                m.put(id, mapIDtoProductSet.get(id))
                                _m.put(id, mapIDtoProductSet.get(id))
                            }
                        }
                    }
                }
            }
        }
        return m
    }

    def Map<String, Set<String>> selectAllOtherSCNID(Edge e) {
        var m = new HashMap<String, Set<String>>
        // find the matching edge
        for(edge : this.edges) {
            if(!(edge.src.equals(e.src) && edge.dst.equals(e.dst))) {
                for(id : edge.scnIDs) {
                    if(this.mapIDtoProductSet.get(id)!==null)
                        m.put(id, this.mapIDtoProductSet.get(id))
                    else m.put(id, new HashSet<String>)
                }
            }
        }
        return m
    }

    // stopped here 14.11.2021
    // TODO compute upfront all the SCNID that are not in new version. Do not select those!
    // somehow old edges are seeping in. should not have been possible. check it and fix it.
    // Investigation: Removal of edges is causing this. The edge e here is not belonging to n, its from old graph!  
    // so test-ids are not valid; we should select based on edges of n only.
    // Resolved. To be checked. 16.11.2021
    // -> was caused by not creating copy of node n2 in calling functions. n2 was being updated with edges from n1.
    
    // optimizes previous method: selectAllOtherSCNID
    // selects test scenarios for distinct configurations (not random; based on order of traversal)
    // ms1: Extend to select based on degree of similarity to reference test scenario (select farthest distance)
    def Map<String, Set<String>> selectMinOtherSCNID(Edge e, String scnID) {
        var m = new HashMap<String, Set<String>> // scnID - product set
        // find the matching edge
        for(edge : this.edges) {
            //System.out.println("        ! Debug:  - " + edge.src + " - " + edge.dst + " -- " + edge.scnIDs)
            //System.out.println("        <!> Debug:  - " + e.src + " - " + e.dst + " -- " + edge.scnIDs)
            if(!(edge.src.equals(e.src) && edge.dst.equals(e.dst))) {
                var _m = new HashMap<String, Set<String>>
                //System.out.println("Debug [" + this.actionName + "]: " + edge.scnIDs )
                for(id : edge.scnIDs) {
                    if(!scnID.equals(id)) { // we do not want to select the same test id on another edge
                        if(mapIDtoProductSet.get(id) === null) {
                            if(_m.isEmpty) {
                                m.put(id, new HashSet<String>)
                                _m.put(id, new HashSet<String>)
                            }
                        }
                        else {
                            if(!_m.values.contains(mapIDtoProductSet.get(id))) { // note this is check on sets of products. not individual!
                                m.put(id, mapIDtoProductSet.get(id))
                                _m.put(id, mapIDtoProductSet.get(id))
                            }
                        }
                    }
                }
            }
        }
        return m
    }
    
    // static selection of tests due to data update
    // data update: what influence does it have based on edges only (iteration added/removed) - select only this test
    // data updated: select all tests and configurations into impacted test set
    // data added: select all tests and configurations into impacted test set (does it mean iteration was added? - this is to be checked)
    // data removed: select all tests and configurations into impacted test set (does it mean iteration was removed? - this is to be checked)
    // distinctive factor: test set and configuration selection at node level. previous ones were at edge level and neighbours.
    
    // returns all tests and configurations present in node, including scnID
    def Map<String, Set<String>> selectAllSCNIDandConfigOfNode() {
        var m = new HashMap<String, Set<String>> // scnID - product set
        
        for(id : scnIDs) {
            if(mapIDtoProductSet.get(id)!== null)
                m.put(id,mapIDtoProductSet.get(id))
            else m.put(id, new HashSet<String>)
        }
        
        return m
    }
    
    // select one test-id per configuration, excluding scnID but using its configuration as basis, but added later - scnID
    def Map<String, Set<String>> selectMinSCNIDandConfigofNode(String scnID) {
        var m = new HashMap<String, Set<String>> // scnID - product set
        
        // find all unique SCNIDs per configuration. Choice of SCNid is based on iteration order. 
        // To be improved with similarity of scenarios
        var seenConfigs = new HashSet<Set<String>>
        for(id : scnIDs) {
            if(mapIDtoProductSet.get(id) !== null) {
                if(!seenConfigs.contains(mapIDtoProductSet.get(id))) { // note this is check on sets of products. not individual!
                    m.put(id, mapIDtoProductSet.get(id))
                    seenConfigs.add(mapIDtoProductSet.get(id))
                }
            } else {
                // only add id, if a test set with no configurations does not exist
                // there should exist at most one empty entry
                for(entry : seenConfigs) {
                    if(entry === null) { 
                        m.put(id, new HashSet<String>)
                        seenConfigs.add(new HashSet<String>)    
                    }    
                    else
                        if(entry.empty) { 
                            m.put(id, new HashSet<String>)
                            seenConfigs.add(new HashSet<String>)
                        }
                }
            }
        }
        
        if(!m.containsKey(scnID)) {
            if(mapIDtoProductSet.get(scnID)!==null)
                m.put(scnID, mapIDtoProductSet.get(scnID))
            else
                m.put(scnID, new HashSet<String>)
        }
        
        return m
    }
}