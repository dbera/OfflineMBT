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
package nl.esi.comma.testspecification.generator

import nl.esi.comma.testspecification.testspecification.TSMain
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.EcoreUtil2
import java.util.ArrayList
import org.eclipse.emf.ecore.resource.Resource
import nl.esi.comma.inputspecification.inputSpecification.APIDefinition
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.inputspecification.inputSpecification.SUTDefinition
import java.util.HashMap

class InputDataInstance 
{
	var mapStepToInputData = new HashMap<String,String>
	
	// def getMapStepToInputData() { return mapStepToInputData }
	
	def computeInputDataInstances(Resource resource, TSMain modelInst, TestSpecificationInstance tsInst) 
	{	
		// Process TSPEC Imports and parse them
		for(imp : modelInst.imports) {
			val inputResource = EcoreUtil2.getResource(resource, imp.importURI)
			var input = inputResource.allContents.head
			var JSONDataFileContents = new ArrayList<JSONData>
			if( input instanceof nl.esi.comma.inputspecification.inputSpecification.Main) {
				if(input.model instanceof APIDefinition) {
					val apiDef = input.model as APIDefinition
					var dataInst = new JSONData
					for(act : apiDef.initActions) {
						if(	act instanceof AssignmentAction || 
							act instanceof RecordFieldAssignmentAction) {
							var mapLHStoRHS = (new ExpressionHandler).generateInitAssignmentAction(act, tsInst.mapLocalDataVarToDataInstance, tsInst.mapLocalStepInstance)
							dataInst.getKvList.add(mapLHStoRHS)
						}
					}
					// dataInst.display
					JSONDataFileContents.add(dataInst)
				} else if(input.model instanceof SUTDefinition) {
					val sutDef = input.model as SUTDefinition
					// TODO map from variable to SUT ID 
					// TODO Needed for variability.
				}
			}
			
			for(dataInst : JSONDataFileContents) {
				for(mapLHStoRHS : dataInst.kvList) {
					var mapLHStoRHS_ = tsInst.getExtensions(mapLHStoRHS.key)
					var String fileName = new String
					
					if(!mapLHStoRHS_.isEmpty) {
						for(stepId : mapLHStoRHS_.keySet) {
							//fileName = getStepInstanceFileName(stepId)
							var fileContents = mapLHStoRHS.value
							// System.out.println("Generating File" + fileName+ " For Step " + stepId)
							for(elm : mapLHStoRHS_.get(stepId)) 
							{
								var str = '''"«elm.key»" : «elm.value»'''
								var StringBuilder b = new StringBuilder(fileContents);
								b.replace(fileContents.lastIndexOf("}"), fileContents.lastIndexOf("}"), "," + str);
								fileContents = b.toString();
							}
							//fsa.generateFile(fileName, fileContents)
							mapStepToInputData.put(stepId,fileContents) // assumption is unique step name. Must be enforced! TODO
						}
					} else { 
						//fileName = getFileName(mapLHStoRHS.key)
						//fsa.generateFile(fileName, mapLHStoRHS.value)
						mapStepToInputData.put(mapLHStoRHS.key,mapLHStoRHS.value)  // assumption is unique step name. Must be enforced! TODO
					}
				}
				// dataInst.display
			} // parsing JSON Data File Contents
		} // for each import
		/*System.out.println("Map Input Var to Values")
		for(k : mapStepToInputData.keySet) {
			System.out.println("	Key: " + k + " Value: " + mapStepToInputData.get(k))
		}*/
		return mapStepToInputData
	}
}