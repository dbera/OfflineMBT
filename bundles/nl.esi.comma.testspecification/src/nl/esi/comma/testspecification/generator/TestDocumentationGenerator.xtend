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

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.inputspecification.inputSpecification.APIDefinition
import nl.esi.comma.inputspecification.inputSpecification.Main
import nl.esi.comma.inputspecification.inputSpecification.SUTDefinition
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

class TestDocumentationGenerator extends AbstractGenerator
{
	var mapConfigurationsToFeatures = new HashMap<String, List<String>>
	
	def computeSUTConfigurationsAndFeatures(Resource resource) 
	{
		if(resource.allContents.head instanceof TSMain) {
			val modelInst = resource.allContents.head as TSMain
			if(modelInst.model instanceof TestDefinition) {
				// Process TSPEC Imports.
				for(imp : modelInst.imports) {
					val inputResource = EcoreUtil2.getResource(resource, imp.importURI)
					var input = inputResource.allContents.head
					if( input instanceof Main) {
						/*if(input.model instanceof APIDefinition) {
							val apidef = input.model as APIDefinition
							for(api : apidef.apiImpl) {
								for(elm : api.di) 
									tsInst.addMapDataInstanceToFile(elm.^var.name, api.path + elm.fname)
							}
						} */
						//else 
						if(input.model instanceof SUTDefinition) {
							val sutDef = input.model as SUTDefinition
							for(conf : sutDef.configSpace) {
								mapConfigurationsToFeatures.put(conf.name, new ArrayList<String>)
								for(f : conf.feature) {
									mapConfigurationsToFeatures.get(conf.name).add(f.name)
								}
							}
						} 
						// else { System.out.println("Error: Unhandled Model Type! ")}
					} // Processed Input Specification
				} // Finished Processing Imports (input specifications)
			}
		}
		
	}
	
    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        generateDocumentationForAllVariants(res, fsa)
    }

	def generateDocumentationForAllVariants(Resource resource, IFileSystemAccess2 fsa) {
		computeSUTConfigurationsAndFeatures(resource)
		// iterate over each valid configuration defined in sut.params
		for(config : mapConfigurationsToFeatures.keySet) {
			generateDocumentation(resource, fsa, mapConfigurationsToFeatures.get(config), config)
			generateBatFile(fsa,config)
		}
	}
	
	def generateBatFile(IFileSystemAccess2 fsa, String plantuml_filename) {
		var txt = 
		'''
		java -DPLANTUML_LIMIT_SIZE=122192 -jar ./lib/plantuml-1.2023.8.jar ./src-gen/«plantuml_filename».plantuml -tsvg
		pause
		'''
		fsa.generateFile("./../gen_svg_for_" + plantuml_filename + ".bat", txt)
	}
	
	def isFeaturePresent(List<String> refFeatures, String fname) {
		for(f : refFeatures) {
			if(f.equals(fname)) return true			
		}
		return false
	}
	
	def isConfigurationEnabled(List<String> featureList, 
		List<Variable> refFeatures
	) {
		//System.out.println(" Feature List: " + featureList)
		//for(e : refFeatures) {
		//	System.out.println(" Ref Feature List: " + e.name)
		//}
		if(refFeatures.empty) { return true } //System.out.println(" >> TRUE ")
		for(f : refFeatures) {
			if(!isFeaturePresent(featureList, f.name)) {
				//System.out.println(" >> FALSE ")
				return false
			}
		}
		//System.out.println(" >> TRUE ")
		return true
	}
	
	def generateDocumentation(Resource resource, IFileSystemAccess2 fsa, 
		List<String> featureList, String configName
	)
	{
		var tsInst = new TestSpecificationInstance
		var testDefFilePath = new String
		var mapStepSeqToSteps = new HashMap<String,List<String>>
		var _sutHandler = new ConcreteSUTHandler // limitation: atmost one SUT definition file per tspec
		
		// check if the resource
		if(resource.allContents.head instanceof TSMain) {
			val modelInst = resource.allContents.head as TSMain
			if(modelInst.model instanceof TestDefinition) 
			{
				// Process TSPEC Imports.
				for(imp : modelInst.imports) {
					val inputResource = EcoreUtil2.getResource(resource, imp.importURI)
					var input = inputResource.allContents.head
					if( input instanceof Main) {
						if(input.model instanceof APIDefinition) {
							val apidef = input.model as APIDefinition
							for(api : apidef.apiImpl) {
								for(elm : api.di) 
									tsInst.addMapDataInstanceToFile(elm.^var.name, api.path + elm.fname)
							}
						} 
						else if(input.model instanceof SUTDefinition) {
							_sutHandler.generateConcreteSoSUTMap(input.model as SUTDefinition)
							// _sutHandler.display
						} 
						else { System.out.println("Error: Unhandled Model Type! ")}
					} // Processed Input Specification
				} // Finished Processing Imports (input specifications)
				
				// Parse TSPEC Test Definition
				val model = modelInst.model
				
				if(model instanceof TestDefinition) 
				{
					if(model.testSeq.isNullOrEmpty) {
						if(model.stepSeq.isNullOrEmpty) tsInst.title = ""
						else tsInst.title = model.stepSeq.head.name
					}
					else tsInst.title = model.testSeq.head.name
					
					tsInst.testpurpose = model.purpose
					tsInst.background = model.background
					for(stakehldr : model.stakeholder) { 
						tsInst.stakeholders.add(stakehldr.name + " | " + stakehldr.function + " | " + stakehldr.comments)
					}
					
					testDefFilePath = model.filePath
					//for(gpars : model.gparams) { addMapLocalDataVarToDataInstance(gpars.name, new String) }
					for(steppars : model.stepparams) { 
						tsInst.addMapLocalStepInstance(steppars.name, steppars.type.type.name)
					}
					//for(sutpars : model.sutparams) { addMapLocalSUTVarToDataInstance(sutpars.name, new String) }
					for(act : model.gparamsInitActions) {
						var mapLHStoRHS = (new ExpressionHandler).generateInitAssignmentAction(act, tsInst.mapLocalDataVarToDataInstance, tsInst.mapLocalStepInstance)
						tsInst.addMapLocalDataVarToDataInstance(mapLHStoRHS.key, mapLHStoRHS.value)
					}
					for(act : model.sutInitActions) {
						var mapLHStoRHS = (new ExpressionHandler).generateInitAssignmentAction(act, tsInst.mapLocalDataVarToDataInstance, tsInst.mapLocalStepInstance)
						tsInst.addMapLocalSUTVarToDataInstance(mapLHStoRHS.key, mapLHStoRHS.value)
					}
					
					// Parse Step Sequence
					val stepSequence = getStepSequence(model, mapStepSeqToSteps, featureList) // resolve test sequence to step sequences
					for(s : stepSequence) 
					{
						if(isConfigurationEnabled(featureList, s.featuresForStep))  
						{
							var stepInst = new Step
							stepInst.id = s.inputVar.name //stepVar.name // was identifier
							stepInst.type = s.type.name
							stepInst.inputFile = tsInst.mapDataInstanceToFile.get(s.stepVar.name).head
							// check if additional data was specified in a step
							for(ref : s.refStep) {
							//if(s.input!==null) {
								// ref.featuresToOutput
								if(isConfigurationEnabled(featureList, ref.featuresToOutput)) 
								{
									for(act : ref.input.actions) {
										if(	act instanceof AssignmentAction || act instanceof RecordFieldAssignmentAction) 
										{
											var mapLHStoRHS = (new ExpressionHandler).generateInitAssignmentAction(act, 
												tsInst.mapLocalDataVarToDataInstance, tsInst.mapLocalStepInstance
											)
											stepInst.parameters.add(mapLHStoRHS)
											// note key = record variable, and value = recExp
											var lhs = (new ExpressionHandler).getLHS(act) 
											stepInst.variableName = lhs.key
											// this is empty. see get LHS.
											stepInst.recordExp = lhs.value 	
										}
									}
								}
							} //else {
								// assign stepInst.variableName
							if(s.refStep.isNullOrEmpty) {
								stepInst.variableName = s.stepVar.name
							}
							tsInst.listStepInstances.add(stepInst)
						} // end-if config enabled
					} // End for step-sequence
				} // Finished Parsing TSPEC File
				
				// update step file names based on checking if additional data was specified. 
				for(step : tsInst.listStepInstances) {
					if(!step.parameters.isEmpty) {
						step.inputFile = step.inputFile.replaceAll(".json", "_" + step.id + ".json")
					}
				}
				
				var inputDataInst = new InputDataInstance()
				var mapStepToInputData = inputDataInst.computeInputDataInstances(resource, modelInst, tsInst)
				
				// Generate PlantUML txt
				var plantUMLTxt = (new DocGen).generatePlantUMLFile(tsInst.listStepInstances, mapStepSeqToSteps)
				fsa.generateFile(configName + ".plantuml", plantUMLTxt)
				
				// Generate MD File
				var mdTxt = (new DocGen).generateMDFile(tsInst, mapStepToInputData, _sutHandler, featureList, configName)
				fsa.generateFile(configName + "_doc.md", mdTxt)
				
				// Turn off during production!
				displayParseResults(tsInst)
				
			} // Finished Processing TestDefinition
		}
	}
	
	def getStepSequence(TestDefinition td, 
		HashMap<String,List<String>> mapStepSeqToSteps, List<String> featureList
	) {
		var listStepSequence = new ArrayList<nl.esi.comma.testspecification.testspecification.Step>
		if(td.testSeq.empty) {
			for(ss : td.stepSeq) {
				for(step : ss.step) {
					if(isConfigurationEnabled(featureList, step.featuresForStep)) 
						listStepSequence.add(step)
				}
			}
		}
		else {
			for(ts : td.testSeq) {
				for(ss : ts.stepSeqRef) {
					for(step : ss.step) {
						if(isConfigurationEnabled(featureList, step.featuresForStep)) {
							listStepSequence.add(step)
							addToMapStepSeqToSteps(ss.name, step.inputVar.name, mapStepSeqToSteps)
						}
					}
				}
			}
		}
		return listStepSequence
	}

	def addToMapStepSeqToSteps(String step_seq, String step, 
		HashMap<String,List<String>> mapStepSeqToSteps
	) {
		if(mapStepSeqToSteps.containsKey(step_seq)) {
			mapStepSeqToSteps.get(step_seq).add(step)
		} else { 
			var tmp = new ArrayList<String> 
			tmp.add(step) 
			mapStepSeqToSteps.put(step_seq,tmp)
		}
	}

	def displayParseResults(TestSpecificationInstance tsInst) 
	{
		System.out.println(" ---- Map Data Instance To File ---- ")
		for(key : tsInst.mapDataInstanceToFile.keySet) {
			System.out.println(" 	Key: " + key + " Value: " + tsInst.mapDataInstanceToFile.get(key))
		}
		
		System.out.println(" ---- Map SUT Instance To File ---- ")
		for(key : tsInst.mapSUTInstanceToFile.keySet) {
			System.out.println(" 	Key: " + key + " Value: " + tsInst.mapSUTInstanceToFile.get(key))
		}
		
		System.out.println(" ---- Map Local Data Var To Data Instance ---- ")
		for(key : tsInst.mapLocalDataVarToDataInstance.keySet) {
			System.out.println(" 	Key: " + key + " Value: " + tsInst.mapLocalDataVarToDataInstance.get(key))
		}
		
		System.out.println(" ---- Map SUT Var To Data Instance ---- ")
		for(key : tsInst.mapLocalSUTVarToDataInstance.keySet) {
			System.out.println(" 	Key: " + key + " Value: " + tsInst.mapLocalSUTVarToDataInstance.get(key))
		}
		
		System.out.println(" ---- Map Step Instance ---- ")
		for(key : tsInst.mapLocalStepInstance.keySet) {
			System.out.println(" 	Key: " + key + " Value: " + tsInst.mapLocalStepInstance.get(key))
		}
		
		System.out.println(" ------------------ STEPS ------------------")
		for(st : tsInst.listStepInstances) {
			System.out.println("")
			System.out.println("	step-id: " + st.id + " type: " + st.type)
			System.out.println("	input: " + st.inputFile)
			System.out.println("	var: " + st.variableName)
			// System.out.println("	recordExp: " + st.recordExp)
			for(param : st.parameters) {
				System.out.println("	parameters: " + param.key + " -> " + param.value)
				System.out.println("	ref-params: " + param.refKey + " -> " + param.refVal)
			}
		}		
	}

}