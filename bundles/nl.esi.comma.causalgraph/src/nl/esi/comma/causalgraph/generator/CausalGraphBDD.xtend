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

import java.util.HashSet
import org.eclipse.emf.common.util.EList
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.util.ArrayList
import java.util.Arrays
import java.util.stream.Collectors
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import java.util.List
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.Node

class CausalGraphBDD {
	def generateBDD(CausalGraph prod, IFileSystemAccess2 fsa) 
	{
	    var pList = new ArrayList<CausalGraph>
	    pList.add(prod)

		// Causal Graph Handling
		toBDD(fsa, pList)
		toStepDefinition(fsa, pList)
	}
	
	def toStepDefinition(IFileSystemAccess2 fsa, List<CausalGraph> cgList)
	{
		if(!cgList.get(0).graphType.equals(GraphType.BDDCG)) return
		var txt = ''''''
		val (String) => String func = [s|s]
		
		txt +=
		'''
		using System;
		using TechTalk.SpecFlow;
		
		namespace XYZ
		{
			[Binding]
			
			public class ABC 
			{
				«FOR v : cgList.get(0).vars»
					«v.type.type.name» «v.name»;
				«ENDFOR»
				
				«FOR n : cgList.get(0).nodes»
					[«n.stepType»(@"«n.stepName» «IF !getNodeArguments(n).nullOrEmpty»(«FOR elm : getNodeArguments(n) SEPARATOR ''' '''»'(.*)'«ENDFOR»)«ENDIF»")]
					public void «n.stepType»«(new StringHelper).makeCaps(n.stepName).replaceAll("\\s+","")» «IF !getNodeArguments(n).nullOrEmpty»(«FOR elm : getNodeArguments(n) SEPARATOR ''','''»string «elm»«ENDFOR»)«ENDIF» {
						«FOR v : n.localVars»
							«v.type.type.name» «v.name»;
						«ENDFOR»
						«FOR a : n.initActions»
							«CSharpHelper.commaAction(a, func, "")»
						«ENDFOR»
						«FOR a : n.act»
							«CSharpHelper.commaAction(a, func, "")»
						«ENDFOR»
					}
				«ENDFOR» 
			}
		}
		'''	
		fsa.generateFile(cgList.get(0).name + '.cs', txt)
	}
	
	def getNodeArguments(Node n) {
		var argList = new ArrayList<String>
		for(a : n.stepArgsInitActions) {
			if(!a.param.isNullOrEmpty) {
				argList.add(a.param)
			}			
		}
		return argList
	}

	def toBDD(IFileSystemAccess2 fsa, List<CausalGraph> cgList) 
	{
		if(!cgList.get(0).graphType.equals(GraphType.BDDCG)) return
		var txt = ''''''
		
		var reqTags = new HashSet<String>
		var testTags = new HashSet<String>
		
		for(cg : cgList) {
			for(n : cg.nodes) {
				for(a : n.stepArgsInitActions) {
					testTags.add(a.testCaseID)
					reqTags.addAll(a.requirementID)
				}
			}
		}
		
		for(cg : cgList) {
			txt = 
			'''
			«FOR elm : reqTags»
			@«elm»
			«ENDFOR»
			«IF !testTags.nullOrEmpty»
				Scenario: «testTags.get(0)»
			«ENDIF»
			«FOR n : cg.nodes»
				«n.stepType» «n.stepName»
				«FOR a : n.stepArgsInitActions»
					«IF !a.param.isNullOrEmpty»
						| «a.param» | «a.value» |
					«ENDIF»
				«ENDFOR»
			«ENDFOR»
			'''
			fsa.generateFile(cg.name + '.feature', txt)
		}
	}
	
}