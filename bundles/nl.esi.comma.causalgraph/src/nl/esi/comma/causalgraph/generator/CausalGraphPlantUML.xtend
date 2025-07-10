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
package nl.esi.comma.causalgraph.generator

import java.util.List
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.util.HashSet
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.Node

class CausalGraphPlantUML 
{
	def generatePlantUML(CausalGraph prod, IFileSystemAccess2 fsa) {
				// Causal Graph Handling
				toPlantUML(fsa, prod)
	}
	
	def toPlantUML(IFileSystemAccess2 fsa, CausalGraph cg) 
	{
		var cgTxt = ''''''
		val (String) => String func = [s|s]
		
		// for(cg : cgList) {
			cg.name
			cgTxt = 
			'''
			@startuml
			«FOR n : cg.nodes»
				class «n.name» {}
				note right of «n.name»
				«FOR a : n.act»
					«CSharpHelper.commaAction(a, func, "")»
				«ENDFOR»
				end note
			«ENDFOR»
			«FOR cf : cg.cfedges»
				«cf.src.name» --> «cf.dst.name»
				note left on link
				«FOR elm : getTestIDOnEdge(cf.src, cf.dst)»
					Test Case ID: «elm»
				«ENDFOR»
				«FOR elm : getReqIDOnEdge(cf.src, cf.dst)»
					Requirement ID: «elm»
				«ENDFOR»
				end note
			«ENDFOR»
			«FOR df : cg.dfedges»
				«df.src.name» ..> «df.dst.name»
				note left on link
				«FOR r : df.refVarList»
					«r.name»
				«ENDFOR»
				end note
			«ENDFOR»
			@enduml
			'''
			fsa.generateFile(cg.name + '.plantuml', cgTxt)
		//}
	}
	
	def getTestIDsFromNode(Node n) {
		var tidList = new HashSet<String>
		for(a : n.stepArgsInitActions) {
			tidList.add(a.testCaseID)
		}
		return tidList
	}
	
	def getReqIDsFromNode(Node n) {
		var tidList = new HashSet<String>
		for(a : n.stepArgsInitActions) {
			tidList.addAll(a.requirementID)
		}
		return tidList
	}
	
	def getTestIDOnEdge(Node src, Node dst) {
		var srcTIDList = getTestIDsFromNode(src)
		var dstTIDList = getTestIDsFromNode(dst)
		var intersectionList = new HashSet<String>
		
		for(e1 : srcTIDList) {
			for(e2 : dstTIDList) {
				if(e1.equals(e2)) intersectionList.add(e1)
			}
		}
		return intersectionList
	}
	
	def getReqIDOnEdge(Node src, Node dst) {
		var srcTIDList = getReqIDsFromNode(src)
		var dstTIDList = getReqIDsFromNode(dst)
		var intersectionList = new HashSet<String>
		
		for(e1 : srcTIDList) {
			for(e2 : dstTIDList) {
				if(e1.equals(e2)) intersectionList.add(e1)
			}
		}
		return intersectionList
	}
}