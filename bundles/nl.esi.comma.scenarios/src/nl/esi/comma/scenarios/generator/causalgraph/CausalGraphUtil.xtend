package nl.esi.comma.scenarios.generator.causalgraph

import java.util.ArrayList
import java.util.List
import nl.esi.comma.scenarios.scenarios.Scenarios
import java.util.LinkedHashMap
import java.util.Map
import java.util.HashMap
import java.util.Arrays
import java.util.Set
import nl.esi.comma.scenarios.scenarios.ActionType
import java.util.HashSet
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.util.Collection

enum NodeChangeType {
    none,
	init_added,
	init_removed,
	terminal_added,
	terminal_removed,
	data_added,
	data_removed,
	data_updated,
	index_added,
	index_removed,
	testset_added,
	testset_removed,
	event_added,
	event_removed,
	config_added,
	config_removed,
	product_added,
	product_removed,
	node_added,
	node_removed,
	node_context_updated
}

enum EdgeChangeType {
	none,
	testset_added,
	testset_removed,
	config_added,
	config_removed,
	product_added,
	product_removed,
	edge_added,
	edge_removed,
	edge_updated
}

class CausalGraphUtil {
	
	def static getCausalGraphFromCG(List<Scenarios> scenarios, Collection<Feature> features){
		var nodes = new ArrayList<Node>
		var edges = new ArrayList<Edge>
		val graph = new CausalGraph(nodes, edges)
		features.forEach[f | graph.addFeature(f)]
		
		for (scenarioSrc : scenarios) {
			for (cg : scenarioSrc.extendedCG) {
				for (action : cg.action){
					var node = new Node(action.actionName.name, action.isIsInit, action.isIsTerminal)
					
					//add data
					for(data : action.data){
						var nodedata = new NodeData(data.testID, Integer.parseInt(data.index))
						for (dataItem : data.dataList){
							nodedata.addData(dataItem.key, dataItem.value)
							node.addData(nodedata)
						}
					}
					//add test id
					for(scnIDs : action.testset){
						for(id : scnIDs.value){
							node.addScnID(id)
						}
					}
					//add events
					for(e : action.events){
						node.addEvents(e.value)
					}
					//add config and product
					for(prod : action.product) {
						node.addProductSet(prod.value)
					}
					for(entry : action.mapIDToProduct) {
					    for(k : entry.elm) {
					        node.addIDtoProductSet(k.key, k.values)
					    }
					}
					for(conf : action.config) {
						node.addConfig(conf.value)
					}
					//add or update edges
					for(e : action.edge){
						for(targetAction : e.actionSet){
							var targetNode = targetAction.value.get(0)
							var matchedEdge = graph.getEdge(node.actionName, targetNode.name)
							if ( matchedEdge === null) {
								var edge = new Edge(node.actionName, targetNode.name)
								//add test set
								for(scnIDs : e.testset){
									for(id : scnIDs.value){
										edge.addScnID(id)
									}
								}
								//add config
								for(conf : e.config) {
									edge.addConfig(conf.value)
								}
								//add product
								for(prod : e.product) {
									edge.addProductSet(prod.value)
								}
								node.addEdges(edge)
								graph.addEdge(edge)
							} else {
								var scnIds = new ArrayList<String>
								for(scnIDs : e.testset){
									for(id : scnIDs.value){
										scnIds.add(id)
									}
								}
								graph.setEdgeProperties(node.actionName, targetNode.name, scnIds, e.config, e.product)
							}
						}
					}
					graph.addNode(node)
				}
			}
		}
		return graph
	}
	
	def static getCausalGraphFromScenarios(List<Scenarios> scenarios){
		var nodes = new ArrayList<Node>
		var edges = new ArrayList<Edge>
		var graph = new CausalGraph(nodes, edges)
		
		for (scenarioSrc : scenarios) {
			for (scn : scenarioSrc.specFlowScenarios) {
			    graph.addFeature(new Feature(scn))
				var init = true
				var src = new Node()
				var dst = new Node()
				var terminal = false
				var counter = new LinkedHashMap<String, Integer>
				for (var i = 0; i < scn.events.size; i++) {
					var event = scn.events.get(i)
					if (counter.keySet.contains(event.name)){
						counter.put(event.name, counter.get(event.name) + 1)
					} else {
						counter.put(event.name, 0)
					}
					if (i == scn.events.size - 1) {
						terminal = true
					}
					var n = new Node(event.name, event.type, init, terminal)
					if (!graph.isPresentNode(n.actionName)){
						//var data = new NodeData(scn.name, counter.get(event.name))
						var data = new NodeData(scn.HID, counter.get(event.name))
						for (d : event.data) {
							for (testData : d.dataList) {
								data.dataMap.put(testData.key, testData.value)
							}
							n.addData(data)
						}
						// n.addScnID(scn.name)
						n.addScnID(scn.HID)
						for (conf : event.config) {
							n.addConfig(conf.value)
						}
						for (prod : event.product) {
							n.addProductSet(prod.value)
							n.addIDtoProductSet(scn.HID, prod.value)
						}
						for (e : event.events) {
							n.addEvents(e.value)
						}
						graph.addNode(n)
						//println("add node: " + n.actionName)
					} else {
						/*graph.setNodeProperties(event.name, scn.name, event.data, init, terminal, event.config, 
							event.product, event.events, counter.get(event.name))*/
						graph.setNodeProperties(event.name, scn.HID, event.data, init, terminal, event.config, 
                            event.product, event.events, counter.get(event.name))
					}
					
					if ( i > 0 ) {
						dst = n
						if (graph.getEdge(src.actionName, dst.actionName) === null){
							var e = new Edge(src.actionName, dst.actionName)
							//e.addScnID(scn.name)
							e.addScnID(scn.HID)
							for (conf : event.config) {
								e.addConfig(conf.value)
							}
							for (prod : event.product) {
								e.addProductSet(prod.value)
							}
							graph.addEdge(e)
						} else {
						    graph.setEdgeProperties(src.actionName, dst.actionName, newArrayList(scn.HID), event.config, event.product)
							//graph.setEdgeProperties(src.actionName, dst.actionName, newArrayList(scn.name), event.config, event.product)
						}
						
						//println("add edge: " + src.actionName + "->" + dst.actionName)
					}
					src = n
					init = false
				}
			}
		}
		return graph
	}
	
    // compute step groups (AND steps) from updated scenarios
    def static computeStepGroups(Scenarios scnList, CausalGraph cg) {
        var nodeSequences = new ArrayList<List<Node>>
        for(scn : scnList.specFlowScenarios) {
            var current = new Node
            var sequence = new ArrayList<Node>
            var started = false
            for(act : scn.events) {
                if(act.type.equals(ActionType.AND)) {
                    // if started
                    if(started) {
                        // remaining iterations
                        sequence.add(cg.getNode(act.name))
                    }
                    // not started
                    else {
                        // first iteration
                        started = true
                        sequence.add(current)
                        sequence.add(cg.getNode(act.name))
                    }
                } else { 
                    started = false
                    if(sequence.size > 0) {nodeSequences.add(sequence) } 
                    sequence = new ArrayList<Node>
                }
                current = cg.getNode(act.name)
            }
        }
        
        /*System.out.println("Printing Step Groups")
        for(elm1 : nodeSequences) {
            println(" Group ")
            for(elm2 : elm1) 
                System.out.println("    > Action: " + elm2.actionName)
        }*/
            
        return nodeSequences
    }

    def static isNodePresentInSequence(List<Node> nodeList, Node n) {
        for(node : nodeList) {
            if(node.actionName.equals(n.actionName)) return true
        }
        return false
    }
	
	def static getDiffGraph(CausalGraph source, CausalGraph target, Scenarios scn, TestSetSelector testSelector, 
	    double sensitivity, boolean ignoreOverlap, boolean ignoreStepContext, IFileSystemAccess2 fsa, String taskName, boolean genDot) {
		val diffGraph = new CausalGraph //union of two graphs with labels
		target.features.values.forEach[f | diffGraph.addFeature(f)]
		var stepGroups = computeStepGroups(scn, target)
		var impactedContextNodes = new HashSet<Node>
		var nodeChanges = new LinkedHashMap<String, NodeChangeType> // use internally for tracking the detailed changes
		// var testSelector = new TestSetSelector
		// compare nodes; edges are compared via its source node
		// check if all actions of source graph are present in target graph
		System.out.println("------------ Checking Differences -----------------")
		for (node : source.nodes) {
			var newNode = new Node
			var matchedNode = findNodeByName(node.actionName, target.nodes) // target node
			if (matchedNode !== null) {
				//compare two nodes // check for node updates
				newNode = compareNode(node, matchedNode, testSelector, stepGroups, impactedContextNodes, ignoreStepContext)
			} else {
				//node removed
				nodeChanges.put(node.actionName, NodeChangeType.node_removed)
				newNode = new Node(node)
				newNode.changeType.add("node_deleted")
				println("Node " + node.actionName + " is removed")
			}
			diffGraph.addNode(newNode)
			for (e : newNode.edges) {
				diffGraph.addEdge(e)
			}
		}
		
		//Check if all actions of the target graph are present in source graph
		for (node : target.nodes){
			var newNode = new Node(node)
			var matchedNode = findNodeByName(node.actionName, source.nodes)
			if (matchedNode === null) {
				//node added
				nodeChanges.put(node.actionName, NodeChangeType.node_added)
				newNode.changeType.add("node_added")
				diffGraph.addNode(newNode)
				for(e : newNode.edges) { e.changeType = "edge_added" diffGraph.addEdge(e) }
				println("Node " + node.actionName + " is added")
			} else {
			    // we already compared them before.
			}
		}
		
		// update the node status of context impacted nodes
		for(impactedNode : impactedContextNodes) {
		    var node = diffGraph.getNode(impactedNode.actionName)
		    println(" > Impacted Context Node: " + node.actionName)
		    node.changeType.add("node_updated")
		    nodeChanges.put(node.actionName, NodeChangeType.node_context_updated)
		}
		
		// there are already elements in progression test set if existing scenarios have re-routing
		//testSelector.printProgressionTestSet
		testSelector.computeProgressionTests(source, target)
		// this DS was already ready
		testSelector.printNodeTestSetSelection
		// get the map of ID to name and file location
		testSelector.computeIDToMetaInfo(scn)
		// needs data computed in previous step
		//println("computing steps to symbol")
		testSelector.computeStepsToSymbolMap(scn) // computes step to symbol map needed by following function call
		//println("computed steps to symbol")
		testSelector.computeRegressionTestSet(scn, sensitivity, ignoreOverlap, ignoreStepContext)
		//println("finished regre set")
		testSelector.computeImpactedTestSet
		//println("finished imp set")
		  // testSelector.printProgressionTestSet
		testSelector.printReason
        testSelector.printMetaInfo
        testSelector.computeBaselineStats(scn)
        //println("finished")
		
		// if(genDot) diffGraph.generateDOT(fsa, taskName, scn.specFlowScenarios.size)
		
		return diffGraph
	}
	
	/*compare two nodes, return a new node with labels */
	def static compareNode(Node n1, Node n2, TestSetSelector tss, ArrayList<List<Node>> stepGroups, Set<Node> impactedContextNodes, boolean ignoreStepContext){
		var newNode = new Node(n2)
		var nodeDiff = new HashMap<NodeChangeType, List<String>>
		var edgeDiff = new HashMap<EdgeChangeType, List<String>>
		//compare init properties
		if (!n1.init.equals(n2.init)) {
			if (n1.init) {
				//nodeDiff.add(NodeChangeType.init_removed)
				if(nodeDiff.containsKey(NodeChangeType.init_removed)) 
				    nodeDiff.get(NodeChangeType.init_removed).add(n1.actionName)
				else nodeDiff.put(NodeChangeType.init_removed, new ArrayList(Arrays.asList(n1.actionName)))
			} else {
				//nodeDiff.add(NodeChangeType.init_added)
                if(nodeDiff.containsKey(NodeChangeType.init_added)) 
                    nodeDiff.get(NodeChangeType.init_added).add(n1.actionName)
                else nodeDiff.put(NodeChangeType.init_added, new ArrayList(Arrays.asList(n1.actionName)))
			}
			//newNode.changeType.add("node_updated")
		}
		//compare terminal properties
		if (!n1.terminal.equals(n2.terminal)) {
			if (n1.terminal) {
				//nodeDiff.add(NodeChangeType.terminal_removed)
                if(nodeDiff.containsKey(NodeChangeType.terminal_removed)) 
                    nodeDiff.get(NodeChangeType.terminal_removed).add(n1.actionName)
                else nodeDiff.put(NodeChangeType.terminal_removed, new ArrayList(Arrays.asList(n1.actionName)))
			} else {
				//nodeDiff.add(NodeChangeType.terminal_added)
                if(nodeDiff.containsKey(NodeChangeType.terminal_added)) 
                    nodeDiff.get(NodeChangeType.terminal_added).add(n1.actionName)
                else nodeDiff.put(NodeChangeType.terminal_added, new ArrayList(Arrays.asList(n1.actionName)))
			}
			//newNode.changeType.add("node_updated")
		}
		//compare data
		for (data : n1.datas) {
			var changeSet = getDataChange(data.scnID, data.index, n2.datas.toList, true) // returns index_removed or added
			var matchedData = findData(data.scnID, data.index, data, n2.datas.toList) // finds data and index based search
			if ( matchedData !== null) { // same index and SCN ID (id changes when data is manipulated) exists in target node
				var result = compareDataMap(data.dataMap, matchedData.dataMap) // data added/updated/removed (this where actual data is checked)
				if (result.size > 0) { // never  gets to this case because SCNID has changed with data update -> will be detected as data removed and added
				    if(!nodeDiff.containsKey(NodeChangeType.data_updated)) {
				        matchedData.print
				        //println("Debug 1: " + data.dataMap + "Debug 2: " +  matchedData.dataMap)
				        /*println("Debug: "+ result.keySet)
				        println("Debug: "+ result.values)
				        println("Debug: "+ changeSet.keySet)
				        println("Debug: "+ changeSet.values)
				        matchedData.print*/
    				    nodeDiff.put(NodeChangeType.data_updated, new ArrayList(Arrays.asList(n1.actionName)))
    				    tss.computeImpactOfDataUpdate(n2, data.scnID, NodeChangeType.data_updated, changeSet)
                        for(elm : result.keySet) {
                            if(nodeDiff.containsKey(elm)) {
                                nodeDiff.get(elm).addAll(result.get(elm))
                            } else {
                                nodeDiff.put(elm, result.get(elm))
                            }
                        }
    					//nodeDiff.putAll(result) // nodeDiff.addAll(result)
    					newNode.changeType.add("data_updated")
					} else { 
                        nodeDiff.get(NodeChangeType.data_updated).add(n1.actionName)
                        //nodeDiff.put(NodeChangeType.data_updated, new ArrayList(Arrays.asList(n1.actionName)))
                        tss.computeImpactOfDataUpdate(n2, data.scnID, NodeChangeType.data_updated, changeSet)
                        for(elm : result.keySet) {
                            if(nodeDiff.containsKey(elm)) {
                                nodeDiff.get(elm).addAll(result.get(elm))
                            } else {
                                nodeDiff.put(elm, result.get(elm))
                            }
                        }
                        //nodeDiff.putAll(result) // nodeDiff.addAll(result)
                        newNode.changeType.add("data_updated")					    
					}
				} // else data is unchanged
			} else { // No scn ID and index match was found // same index and SCN ID does not exist in target node
			    if(!nodeDiff.containsKey(NodeChangeType.data_removed)) {
    			    nodeDiff.put(NodeChangeType.data_removed, new ArrayList(Arrays.asList(n1.actionName)))
    			    tss.computeImpactOfDataRemoval(n2, NodeChangeType.data_removed)
                    for(elm : changeSet.keySet) {
                        if(nodeDiff.containsKey(elm)) {
                            nodeDiff.get(elm).addAll(changeSet.get(elm))
                        } else {
                            nodeDiff.put(elm, changeSet.get(elm))
                        }
                    }
    				//nodeDiff.putAll(changeSet) //add(NodeChangeType.data_removed)
    				newNode.changeType.add("data_deleted")
				} else {
				    nodeDiff.get(NodeChangeType.data_removed).add(n1.actionName)
				    tss.computeImpactOfDataRemoval(n2, NodeChangeType.data_removed)
				    for(elm : changeSet.keySet) {
				        if(nodeDiff.containsKey(elm)) {
				            nodeDiff.get(elm).addAll(changeSet.get(elm))
				        } else {
				            nodeDiff.put(elm, changeSet.get(elm))
				        }
				    }
				    newNode.changeType.add("data_deleted")
				}
			}
		}
		//find new data in n2 but not in n1
		for (data : n2.datas){
		    var changeSet = getDataChange(data.scnID, data.index, n1.datas.toList, false)
			var matchedData = findData(data.scnID, data.index, data, n1.datas.toList)
			if ( matchedData === null){
			    if(!nodeDiff.containsKey(NodeChangeType.data_added)) {
			        tss.computeImpactOfDataAddition(n2, data.scnID, NodeChangeType.data_added)
                    nodeDiff.put(NodeChangeType.data_added, new ArrayList(Arrays.asList(n2.actionName)))				
    				//nodeDiff.putAll(changeSet) //add(NodeChangeType.data_added)
                    for(elm : changeSet.keySet) {
                        if(nodeDiff.containsKey(elm)) {
                            nodeDiff.get(elm).addAll(changeSet.get(elm))
                        } else {
                            nodeDiff.put(elm, changeSet.get(elm))
                        }
                    }
    				newNode.changeType.add("data_added")
				} else { // no scn id and index match was found
                    nodeDiff.get(NodeChangeType.data_added).add(n2.actionName)
                    tss.computeImpactOfDataAddition(n2, data.scnID, NodeChangeType.data_added)                
                    //nodeDiff.putAll(changeSet) //add(NodeChangeType.data_added)
                    for(elm : changeSet.keySet) {
                        if(nodeDiff.containsKey(elm)) {
                            nodeDiff.get(elm).addAll(changeSet.get(elm))
                        } else {
                            nodeDiff.put(elm, changeSet.get(elm))
                        }
                    }
                    newNode.changeType.add("data_added")				    
				}
			}
		}
		//compare test set
		for (testID : n1.scnIDs) {
			if (!n2.scnIDs.contains(testID)){
			    if(nodeDiff.containsKey(NodeChangeType.testset_removed))
			        nodeDiff.get(NodeChangeType.testset_removed).add(testID)
			    else nodeDiff.put(NodeChangeType.testset_removed, new ArrayList(Arrays.asList(testID)))
				//newNode.changeType.add("node_updated")
				newNode.changeType.add("testset_removed")
			}
		}
		
		for (testID : n2.scnIDs){
			if (!n1.scnIDs.contains(testID)){
                if(nodeDiff.containsKey(NodeChangeType.testset_added))
                    nodeDiff.get(NodeChangeType.testset_added).add(testID)
                else nodeDiff.put(NodeChangeType.testset_added, new ArrayList(Arrays.asList(testID)))
				//nodeDiff.put(NodeChangeType.testset_added, Arrays.asList(testID))
				//newNode.changeType.add("node_updated")
				newNode.changeType.add("testset_added")
			}
		}
		//compare event
		for (event : n1.eventSet){
			if(!n2.eventSet.contains(event)){
				nodeDiff.put(NodeChangeType.event_removed, new ArrayList(Arrays.asList(event)))
				newNode.changeType.add("node_updated")
			}
		}
		for (event : n2.eventSet){
			if(!n1.eventSet.contains(event)){
				nodeDiff.put(NodeChangeType.event_added, new ArrayList(Arrays.asList(event)))
				newNode.changeType.add("node_updated")
			}
		}
		//compare config
		for (conf : n1.configs){
			if(!n2.configs.contains(conf)){
				nodeDiff.put(NodeChangeType.config_removed, new ArrayList(Arrays.asList(conf)))
				//newNode.changeType.add("node_updated")
			}
		}
		for (conf : n2.configs){
			if(!n1.configs.contains(conf)){
				nodeDiff.put(NodeChangeType.config_added, new ArrayList (Arrays.asList(conf)))
				//newNode.changeType.add("node_updated")
			}
		}
		//compare product
		for (prod : n1.productSet){
			if(!n2.productSet.contains(prod)){
				nodeDiff.put(NodeChangeType.product_removed, new ArrayList(Arrays.asList(prod)))
				newNode.changeType.add("node_updated")
				newNode.changeType.add("product_removed")
			}
		}
		for (prod : n2.productSet){
			if(!n1.productSet.contains(prod)){
				nodeDiff.put(NodeChangeType.product_added, new ArrayList (Arrays.asList(prod)))
				newNode.changeType.add("node_updated")
				newNode.changeType.add("product_added")
			}
		}
		//compare edges
		// find all edges n1 in n2
		for (edge : n1.edges){
			var matchedEdge = findEdge(edge.src, edge.dst, n2.edges)
			if ( matchedEdge !== null) {
				var result = compareEdges(edge, matchedEdge, n2, tss) // edge is from n2
				if (result.size > 0){
					edgeDiff.put(EdgeChangeType.edge_updated, new ArrayList)
					edgeDiff.putAll(result)
					newNode.setEdgeChangeType(edge.src, edge.dst, "edge_updated")
					//newNode.changeType.add("node_updated")
				}
			} else { // if edge not found
			    tss.computeImpactOfEdgeRemoval(n2, edge) // Note: this edge is not in n2. Potential future issue?
				edgeDiff.put(EdgeChangeType.edge_removed, edge.scnIDs.toList)
				// implies test set deleted. Add these as well to map
				edge.changeType = "edge_deleted"
				newNode.addEdges(edge)
				newNode.changeType.add("node_updated")
			}
		}
		//find new edge in n2 but not in n1
		for (edge : n2.edges){
			var matchedEdge = findEdge(edge.src, edge.dst, n1.edges)
			if ( matchedEdge === null) {    
			    tss.computeImpactOfEdgeAddition(n2, edge)
				edgeDiff.put(EdgeChangeType.edge_added, edge.scnIDs.toList)
				newNode.setEdgeChangeType(edge.src, edge.dst, "edge_added")
				newNode.changeType.add("node_updated")
				
				// consider all nodes related by AND to this node
				// New feature DB : 10.05.2022
                if(!ignoreStepContext) {
                    println("Checking Node Context For: " + n2.actionName)
                    for(group : stepGroups) {
                        if(isNodePresentInSequence(group,n2)) {
                            for(var idx = 0 ; idx < group.size-1; idx++) 
                            {
                                var n = group.get(idx)
                                var m = group.get(idx+1)
                                if(!n.actionName.equals(n2.actionName)) {
                                    var e = n.getEdge(n.actionName, m.actionName)
                                    if(e === null) println("could not find edge between " + n.actionName + " and " + m.actionName)
                                    else tss.computeImpactOfEdgeContextChange(n, e) // does not populate primary set.
                                    impactedContextNodes.add(n)
                                    impactedContextNodes.add(m)
                                }
                            }
                        }    
                    }
                }
			}
		}
		
		for (diff: nodeDiff.keySet){
			println("Node "+ n1.actionName + " : " + diff + " : " + nodeDiff.get(diff))
		}
		for (diff: edgeDiff.keySet){
			println("Edge "+ n1.actionName + " : " + diff + " : " + edgeDiff.get(diff))
		}
		
		return newNode // n2
	}
	
	def static findNodeByName(String nodeName, List<Node> nodes){
		for (node : nodes) {
			if (node.actionName.equals(nodeName)){
				return node
			}
		}
		return null
	}
	
	def static findData(String scnID, int index, NodeData srcData, List<NodeData> nodeData){
		for (data : nodeData){
			/*if (data.index.equals(index) &&
				data.scnID.equals(scnID)){
				return data
			}*/
			if(data.isEqualDataMap(srcData.dataMap)) return data
		}
		// check for data equality instead of SCNID - index match. Edges are taking care of new behavior.
		
		return null
	}
	// call this function first. check if nodechangetype is none and only then call: findData
	def static getDataChange(String scnID, int index, List<NodeData> nodeData, boolean isSrcDst) {
        var m = new HashMap<NodeChangeType, List<String>>
        for (data : nodeData){
            if (data.index.equals(index) &&
                data.scnID.equals(scnID)){
                m.put(NodeChangeType.none, new ArrayList)
                return m
            }
        }
        // SCN ID and index did not match so far
        var found = false
        m = new HashMap<NodeChangeType, List<String>>
        for (data : nodeData) {
            if(data.scnID.equals(scnID)){
                // index missing/added
                if(isSrcDst) {
                    if(!m.containsKey(NodeChangeType.index_removed)) 
                        m.put(NodeChangeType.index_removed, new ArrayList(Arrays.asList(scnID)))
                    else m.get(NodeChangeType.index_removed).addAll(new ArrayList(Arrays.asList(scnID)))
                } else {
                    if(!m.containsKey(NodeChangeType.index_added)) 
                        m.put(NodeChangeType.index_added, new ArrayList(Arrays.asList(scnID)))
                    else m.get(NodeChangeType.index_added).addAll(new ArrayList(Arrays.asList(scnID)))
                }
            } 
        }
        //if(found) return m
        // index and testset missing
        //m.put(NodeChangeType.index_removed, new ArrayList(Arrays.asList(scnID)))
        //m.put(NodeChangeType.testset_removed, new ArrayList(Arrays.asList(scnID)))
        return m
	}
	
	def static compareDataMap(Map<String, String> data1, Map<String, String> data2){
		/*var dataChanges = new ArrayList<NodeChangeType>
		if (data1.size > data2.size) {
			dataChanges.add(NodeChangeType.data_removed)
		}
		
		if (data1.size < data2.size) {
			dataChanges.add(NodeChangeType.data_added)
		}
		for (key : data1.keySet) {
			var dataValue1 = data1.get(key)
			var dataValue2 = data2.get(key) // This may lead to null pointer exception! DB 29.10.2021
			if (!dataValue1.equals(dataValue2)){
				dataChanges.add(NodeChangeType.data_updated)
			}
		}*/
		// Alt. Implementation
		var dataChangeMap = new HashMap<NodeChangeType, List<String>>
		
		for(k1 : data1.keySet) {
		    if(data2.keySet.contains(k1)) {
		        var dataValue1 = data1.get(k1)
		        var dataValue2 = data2.get(k1)
		        var dataList = new ArrayList
		        dataList.add(dataValue1) 
		        dataList.add(dataValue2)
                if (!dataValue1.equals(dataValue2)){
                    // data updated
                    dataChangeMap.put(NodeChangeType.data_updated, dataList)
                }
		    }
		    else {
		        // data removed
		        dataChangeMap.put(NodeChangeType.data_removed, new ArrayList(Arrays.asList(data1.get(k1)))) 
		    }
		}
		// find keys in dest that are not present in source (new args added) 
		for(k2 : data2.keySet) {
            if(!data1.keySet.contains(k2)) {                
                // data added
                dataChangeMap.put(NodeChangeType.data_added, new ArrayList(Arrays.asList(data1.get(k2))))
            }
       }
		//return dataChanges
		return dataChangeMap
	}
	
	def static findEdge(String src, String dst, List<Edge> edges){
		for (edge : edges) {
			if(edge.src.equals(src) &&
				edge.dst.equals(dst))
				return edge
		}
		return null
	}
	
	def static isSameScenarioPresent(String id, Set<String> ids) {
	    var preid = id.split("_")
	    if(preid.size > 1) {
	        for(elm : ids) {
	            if(elm.split("_").size > 1) {
	                var tmp = elm.split("_")
	                if(tmp.get(0).equals(preid.get(0)))
	                   return true
	            }
	        }
	    }
	    else return false
	}
	
	// TODO: Harmful assumption about what each param is, e2: edge of target node, n is target node
	def static compareEdges(Edge e1, Edge e2, Node n, TestSetSelector tss){
		// var edgeChanges = new ArrayList<EdgeChangeType>
		var edgeChanges = new HashMap<EdgeChangeType, List<String>>
		//compare test set
		for(scnID : e1.scnIDs){
			if(!e2.scnIDs.contains(scnID)){
				//edgeChanges.add(EdgeChangeType.testset_removed)
				if(edgeChanges.containsKey(EdgeChangeType.testset_removed)) {
				    edgeChanges.get(EdgeChangeType.testset_removed).add(scnID)
				} else { 
				    var scnList = new ArrayList<String>
				    scnList.add(scnID) 
				    edgeChanges.put(EdgeChangeType.testset_removed, scnList)
				}
				tss.computeImpactOfEdgeUpdate(n, e2, scnID, EdgeChangeType.testset_removed) // scnID is not in target!
			}
		}
		
		for(scnID : e2.scnIDs){
			if(!e1.scnIDs.contains(scnID)){
				//edgeChanges.add(EdgeChangeType.testset_added)
                // To handle scenarios that pass by due to new data addition (so scenario already exists)
                // check if prefix already existed in e2.scnids - split string on _
                if(!isSameScenarioPresent(scnID, e2.scnIDs)) { // to not consider edge updates due to new data added to scenario outline
                    if(edgeChanges.containsKey(EdgeChangeType.testset_added)) {
                        edgeChanges.get(EdgeChangeType.testset_added).add(scnID)
                    } else { 
                        var scnList = new ArrayList<String>
                        scnList.add(scnID) 
                        edgeChanges.put(EdgeChangeType.testset_added, scnList)
                    }
                    tss.computeImpactOfEdgeUpdate(n, e2, scnID, EdgeChangeType.testset_added)
                }
			}
		}
		
		//compare config
		for (conf : e1.configs){
			if(!e2.configs.contains(conf)){
				//edgeChanges.add(EdgeChangeType.config_removed)
                if(edgeChanges.containsKey(EdgeChangeType.config_removed)) {
                    edgeChanges.get(EdgeChangeType.config_removed).add(conf)
                } else { 
                    var scnList = new ArrayList<String>
                    scnList.add(conf) 
                    edgeChanges.put(EdgeChangeType.config_removed, scnList)
                }
			}
		}
		for (conf : e2.configs){
			if(!e1.configs.contains(conf)){
				//edgeChanges.add(EdgeChangeType.config_added)
                if(edgeChanges.containsKey(EdgeChangeType.config_added)) {
                    edgeChanges.get(EdgeChangeType.config_added).add(conf)
                } else { 
                    var scnList = new ArrayList<String>
                    scnList.add(conf) 
                    edgeChanges.put(EdgeChangeType.config_added, scnList)
                }
			}
		}
		//compare product
		for (prod : e1.productSet){
			if(!e2.productSet.contains(prod)){
				//edgeChanges.add(EdgeChangeType.product_removed)
                if(edgeChanges.containsKey(EdgeChangeType.product_removed)) {
                    edgeChanges.get(EdgeChangeType.product_removed).add(prod)
                } else { 
                    var scnList = new ArrayList<String>
                    scnList.add(prod) 
                    edgeChanges.put(EdgeChangeType.product_removed, scnList)
                }
			}
		}
		for (prod : e2.productSet){
			if(!e1.productSet.contains(prod)){
				//edgeChanges.add(EdgeChangeType.product_added)
				if(edgeChanges.containsKey(EdgeChangeType.product_added)) {
                    edgeChanges.get(EdgeChangeType.product_added).add(prod)
                } else { 
                    var scnList = new ArrayList<String>
                    scnList.add(prod) 
                    edgeChanges.put(EdgeChangeType.product_added, scnList)
                }
			}
		}
		return edgeChanges
	}

}