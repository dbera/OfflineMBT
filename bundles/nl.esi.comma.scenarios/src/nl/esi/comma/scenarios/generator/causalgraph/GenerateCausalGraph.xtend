/**
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
package nl.esi.comma.scenarios.generator.causalgraph

import java.util.List
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.scoping.IScopeProvider
import java.io.ByteArrayInputStream
import java.util.stream.Collectors

class GenerateCausalGraph {
	//List<Scenarios> scenarios
	CausalGraph graph
	CausalFootprint footprint
	String graphName
	Scenarios scn
	
	def generateCausalGraph(IFileSystemAccess2 fsa, IScopeProvider context,
							List<Scenarios> scenarios, String taskName)
	{
		//this.scenarios = scenarios
		this.graphName = taskName
		val String path = "..\\test-gen\\SpecFlowToScenarios\\" + taskName + "\\graph"
		graph = CausalGraphUtil.getCausalGraphFromScenarios(scenarios)
		footprint = new CausalFootprint(scenarios)
		var graphModel = ScenarioToGraph
		fsa.generateFile(path + ".scn", graphModel)
		
		var output = graph.toJSON(true, null, null)
		fsa.generateFile(path + ".json", output)
		var html = graph.toHTML(false, null, null)
		fsa.generateFile(path + ".html", new ByteArrayInputStream(html))
		return new GenerateCausalGraphResult(graphModel, footprint, graph);
	}
	
	def generateDiffCG(IFileSystemAccess2 fsa, Scenarios srcScn, Scenarios dstScn, Scenarios _scn, String taskName, 
	                   boolean visualize, double sensitivity, boolean ignoreOverlap, boolean ignoreStepContext, 
	                   boolean genDot, long scnDur, long cgDur, GenerateCausalGraphResult srcResult, GenerateCausalGraphResult dstResult,
	                   String configFP, String assemFP, String prefix, String defaultName) {
		var testSelector = new TestSetSelector
		var srcgraph = CausalGraphUtil.getCausalGraphFromCG(newArrayList(srcScn), srcResult.causalGraph.features.values())
		var dstgraph = CausalGraphUtil.getCausalGraphFromCG(newArrayList(dstScn), dstResult.causalGraph.features.values())
		val String path = "..\\test-gen\\DiffCausalGraph\\" + taskName + "\\diffGraph"
		scn = _scn
		var startTimeDiffCG = System.currentTimeMillis
		graph = CausalGraphUtil.getDiffGraph(srcgraph, dstgraph, _scn, testSelector, sensitivity, ignoreOverlap, ignoreStepContext, fsa, taskName, genDot)
		var endTimeDiffCG = System.currentTimeMillis
		var startTimeTestSelector = System.currentTimeMillis
		testSelector.selectTestConfigsAndGenerateDashBoard(fsa, _scn, taskName, configFP, assemFP, prefix, defaultName)
		var endTimeTestSelector = System.currentTimeMillis
		var startTimeDashBoard = System.currentTimeMillis
		if (visualize) {
			var output = graph.toJSON(true, srcResult.footprint, dstResult.footprint)
			fsa.generateFile(path + ".json", output)
			var html = graph.toHTML(true, srcResult.footprint, dstResult.footprint)
			fsa.generateFile(path + ".html", new ByteArrayInputStream(html))
		}
		var endTimeDashBoard = System.currentTimeMillis
		this.graphName = "diffCG"
		var txt = ScenarioToGraph
		fsa.generateFile(path + ".scn", txt)
		
		var startDOTGeneration = System.currentTimeMillis
		if(genDot) graph.generateDOT(fsa, taskName, scn.specFlowScenarios.size)
		var endDOTGeneration = System.currentTimeMillis
		
		var perf = generatePerformanceReport(scnDur, cgDur, endTimeDiffCG-startTimeDiffCG, 
		                          endTimeTestSelector-startTimeTestSelector, 
		                          endTimeDashBoard-startTimeDashBoard, 
		                          endDOTGeneration-startDOTGeneration)
        fsa.generateFile("..\\test-gen\\DiffCausalGraph\\" + taskName + "\\performance.txt", perf)
		
		return txt
	}
	
	def generatePerformanceReport(long scnDur, long cgDur, long diffCGDur, 
	                              long testSelDur, long dashBoardDur, long DOTGenDur) {
	    '''
	    /************SpecDiff Performance Report****************/
	       > Scenario Extraction:      «scnDur/1000.0» secs
	       > Model Extraction:         «cgDur/1000.0» msecs
	       > Difference Calculation:   «diffCGDur/1000.0» msecs
	       > Test Selection Duration:  «testSelDur/1000.0» msecs
	       > DashBoard Generation:     «dashBoardDur/1000.0» msecs
	       > DotGeneration:            «DOTGenDur/1000.0» msecs
	    /*******************************************************/
	    '''
	}

    // TODO to be deprecated
    /*def generateDiffCG(IFileSystemAccess2 fsa, Scenarios srcScn, Scenarios dstScn, String taskName, boolean visualize, double sensitivity){
        var srcgraph = CausalGraphUtil.getCausalGraphFromCG(newArrayList(srcScn))
        var dstgraph = CausalGraphUtil.getCausalGraphFromCG(newArrayList(dstScn))
        val String path = "..\\test-gen\\DiffCausalGraph\\" + taskName + "\\diffGraph"
        graph = CausalGraphUtil.getDiffGraph(srcgraph, dstgraph, null, null, sensitivity, false)
        if (visualize) {
            var output = graph.toJSON(true, null, null)
            fsa.generateFile(path + ".json", output)
            var html = graph.toHTML(true, null, null)
            fsa.generateFile(path + ".html", new ByteArrayInputStream(html))
        }
        this.graphName = "diffCG"
        var txt = ScenarioToGraph
        fsa.generateFile(path + ".scn", txt)
        return txt
    }*/

	
	def ScenarioToGraph(){
		'''
		action-list: {
			«actionList»
		}
		
		Causal-Graph «graphName» {
			«getGraph»
		}
		'''
	}
	
	def getGraph() {
		var txt = ''''''
		for (node : graph.nodes) {
			txt += '''
				
				Action «node.actionName» «IF node.changeType !== null && !node.changeType.empty»[ «changeType(node)»]«ENDIF» {
					«IF node.init»
					init
					«ENDIF»
					«IF node.terminal»
					term
					«ENDIF»
					«data(node)»
					«IF !node.scnIDs.isEmpty»
					test-set [ 
					«ScnIDs(node)»]
					«ENDIF»
					«IF !node.eventSet.isEmpty»
					event-set [ «eventSet(node)»]
					«ENDIF»
					«IF !node.configs.isEmpty»
					config [ «configs(node)»]
					«ENDIF»
					«IF !node.productSet.isEmpty»
					product-set [ «productSet(node)»]
					«ENDIF»
					«IF !node.mapIDtoProductSet.keySet.empty»
					map [ «idToProductSet(node)»]
					«ENDIF»					
					«getEdges(node)»
				}
			'''
		}
		return txt
	}
	
	def changeType(Node node){
		var txt = ''''''
		for (type : node.changeType) {
			txt += '''«type» '''
		}
		return txt
	}
	
	def eventSet(Node node) {
		var txt = ''''''
		for (e : node.eventSet) {
			txt += '''"«e»" '''
		}
		return txt
	}
	
	def idToProductSet(Node node) {
	    var txt = ''''''
        for (id : node.mapIDtoProductSet.keySet) {
            txt += '''"«id»" : '''
            for(prod : node.mapIDtoProductSet.get(id)) {
                txt += '''"«prod»" '''                
            }
            txt += ''';'''

        }
        return txt
	}
	
	def productSet(Node node) {
		var txt = ''''''
		for (prod : node.productSet) {
			txt += '''"«prod»" '''
		}
		return txt
	}
	
	def productSet(Edge edge) {
		var txt = ''''''
		for (prod : edge.productSet) {
			txt += '''"«prod»" '''
		}
		return txt
	}
	
	def ScnIDs(Node node) {
		var txt = ''''''
		for (scnID : node.scnIDs){
			txt += 
			'''
			"«scnID»" 
			'''
			
		}
		return txt
	}
	
	def getEdges(Node node) {
		var txt = ''''''
		var edges = graph.getEdgesOfNode(node)
		for (e : edges) {
			txt += '''
				edge «IF !e.changeType.empty»[«e.changeType»]«ENDIF» -{
					test-set [ 
					«ScnIDs(e)»]
					«IF !e.configs.empty»
					config [ «configs(e)»]
					«ENDIF»
					«IF !e.productSet.empty»
					product-set[ «productSet(e)»]
					«ENDIF»
				} -> leads-to [ «e.dst» ]
				
			'''
		}
		return txt
	}
	
	def data(Node node) {
		var txt = ''''''
		for (d : node.datas) {
			txt += '''
				
				data ["«d.scnID»" - "«d.index»"]'''
			for (key : d.dataMap.keySet) {
				txt += ''' ["«key»" : "«d.dataMap.get(key)»"]'''
			}
		}
		return txt
	}
	
	def configs(Node node) {
		var txt = ''''''
		for (conf : node.configs) {
			txt += '''"«conf»" '''
		}
		return txt
	}
	
	def configs(Edge edge) {
		var txt = ''''''
		for (conf : edge.configs) {
			txt += '''"«conf»" '''
		}
		return txt
	}
	
	def ScnIDs(Edge edge) {
		var txt = ''''''
		for (scnID : edge.scnIDs) {
			txt += 
			'''
			"«scnID»" 
			'''
		}
		return txt
	}
	
	def actionList(){
		var txt = ''''''
		for (node : graph.nodes) {
			txt += '''
				«node.type» «node.actionName» "«node.actionName»"
			'''
		}
		return txt
	}
}