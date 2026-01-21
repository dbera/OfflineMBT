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
package nl.esi.comma.constraints.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Set
import nl.esi.comma.constraints.constraints.Action
import nl.esi.comma.constraints.constraints.ActionType
import nl.esi.comma.constraints.constraints.Actions
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.DataTable
import nl.esi.comma.steps.step.StepType
import nl.esi.comma.steps.step.Steps
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import java.util.HashSet

class FeatureGenerator {
	var static stepsMapping = new HashMap<String, String>
	def static generateFeatureFileWithData(String constraint, Steps stepModel, Constraints constraintSource, ArrayList<List<String>> SCNList,
		Set<String> configTags, Set<String> reqTags, String descTxt, HashMap<String, String> mapping
	){
		stepsMapping = mapping
		var idx = 0
		var stepIdx = 0
		var ctx = StepType.GIVEN
		var actionDef = getActionDef(constraintSource)

		'''
		Feature: «constraint»
		
		«FOR stepList : SCNList»
			«IF getStepType(stepList.head,stepModel,actionDef).equals(StepType.GIVEN) || getStepType(stepList.head,stepModel,actionDef).equals(StepType.WHEN)»
			«getTagTxt(reqTags, configTags)»
			Scenario: «constraint»«idx» - «descTxt»
			«{idx++ ""}»
			«{ctx = StepType.GIVEN ""}»
			«{stepIdx = 0 ""}»
			«FOR step : stepList»
				«IF ctx.equals(getStepType(step, stepModel,actionDef))»
					«IF stepIdx === 0»
						«ctx» «getStepWithData(step, stepModel, actionDef).replaceAll("_", " ")»
					«ELSE»
						«StepType.AND» «getStepWithData(step, stepModel, actionDef).replaceAll("_", " ")»
					«ENDIF»
				«ELSE»
					«IF !getStepType(step,stepModel,actionDef).equals(StepType.AND)»
						«{ctx = getStepType(step,stepModel,actionDef) ""}»
						«IF ctx.equals(StepType.WHEN)»
						
						«ENDIF»
						«ctx» «getStepWithData(step, stepModel, actionDef).replaceAll("_", " ")»
					«ELSE»
						«StepType.AND» «getStepWithData(step, stepModel, actionDef).replaceAll("_", " ")»
					«ENDIF»
				«ENDIF»
				«{ctx = getStepType(step,stepModel,actionDef) ""}»
				«{stepIdx++ ""}»
			«ENDFOR»
			
			«ENDIF»
		«ENDFOR»
		'''
	}
	
	def static String getStepWithData(String step, Steps stepModel, List<Actions> actionDef){
		var stepWithData = step
		if (stepModel !== null){
			for (stepAction : stepModel.actionList.acts){
				if (stepAction.name.equals(step)){
					stepWithData = stepAction.text.get(0).split(" ", 2).get(1)
					return stepWithData
				}
			}
		}
		var stepAction = step
		//var data = ""
		if (actionDef.size > 0){
			/*if (step.contains("(")){
				var strList = step.split("\\(")
				stepAction = strList.get(0)
				data = strList.get(1).replace(")", "")
			}*/
			for(actDef : actionDef){
				for(act : actDef.act){
					if (stepAction.equals(act.label.replaceAll(" ", "_"))){
						stepWithData = act.label
						for (d : act.data) {
							if (!d.instances){
								stepWithData = getGherkinTextWithData(stepWithData, act).toString
								return stepWithData
							}
						}
						return stepWithData
					} else {
						var stepName = stepsMapping.get(step)
						if (stepName !== null){
							var label = act.label.replaceAll(" ", "_")
							if (stepName.equals(label)) {
								for (d : act.data) {
									if (d.instances){
										stepWithData = getGherkinTextWithDataInstance(stepWithData, act)
										return stepWithData
									}
								}
							}
						}
					}
				}
			}
		}
		return stepWithData
	}

    def static getGherkinTextWithData(String action, Action act) '''
        «action»«FOR dataTable : act.data»«FOR cell : dataTable.header.cells» "<«cell»>"«ENDFOR»«ENDFOR»
        «dataExample(act.data)»
    '''

    def static dataExample(EList<DataTable> list) '''
        Example:
        «FOR dataTable : list»«FOR cell : dataTable.header.cells»«cell»«ENDFOR»«ENDFOR»|
        «FOR dataTable : list»«FOR row : dataTable.rows»«FOR cell : row.cells»«cell»«ENDFOR»«ENDFOR»«ENDFOR»|
    '''
	
	def static getGherkinTextWithDataInstance(String action, Action act){
		var strList = action.split("_")
		var labelList = act.label.split(" ")
		var stepWithData = ""
		for (var i = 0; i < strList.size; i++) {
			if (labelList.get(i).startsWith("<")) {
				stepWithData += "\"" + strList.get(i) + "\" "
			} else {
				stepWithData += labelList.get(i) + " "
			}
			
		}
		return stepWithData.trim
	}
	
//	def static getDataValue(String data){
//		var Map<String, String> dataRow = newHashMap
//		if (!data.empty){
//			var dataList = data.split(",")
//			for (d : dataList){
//				var id = d.split(":").get(0)
//				var value = d.split(":").get(1)
//				dataRow.put(id, value)
//			}
//		}
//		return dataRow
//	}
	
	def static getStepType(String step, Steps stepModel, List<Actions> actList) {
        if(stepModel!== null) {
            for(action : stepModel.actionList.acts) {
                if(step.equals(action.name)) 
                    return action.label.head
            }
        }
        //if(actList)
        for(actl : actList) {
            for(action : actl.act) {
            	var label = action.label.replaceAll(" ", "_")
                if(step.equals(label)){
                    if(action.act.equals(ActionType.PRE_CONDITION)) return StepType.GIVEN
                    else if(action.act.equals(ActionType.TRIGGER)) return StepType.WHEN
                    else if(action.act.equals(ActionType.OBSERVABLE)) return StepType.THEN
                    else if(action.act.equals(ActionType.CONJUNCTION)) return StepType.AND
                    else {}
                } else {
                	if(action.data.size > 0){
                		//action with data
                		var actName = stepsMapping.get(step)
                		var actlabel = action.label.replaceAll(" ", "_")
                		if (actlabel.equals(actName)){
                			if(action.act.equals(ActionType.PRE_CONDITION)) return StepType.GIVEN
		                    else if(action.act.equals(ActionType.TRIGGER)) return StepType.WHEN
		                    else if(action.act.equals(ActionType.OBSERVABLE)) return StepType.THEN
		                    else if(action.act.equals(ActionType.CONJUNCTION)) return StepType.AND
		                    else {}
                		}
                	}
                }
            }
        }
        //System.out.println("Did not find step type during test generation!")
        return StepType.AND
    }
	
	def static getConstraintsModel(Constraints model) {
        var List<Constraints> constModel = new ArrayList<Constraints>
        for(imp : model.imports) {
            val Resource r = EcoreUtil2.getResource(imp.eResource, imp.importURI)
            if (r === null){
                new IllegalArgumentException("Cannot resolve the imported Constraints model in the Constraints model.")
            } else {
                val root = r.allContents.head
                if (root instanceof Constraints) {
                    constModel.add(root)
                }
            }
        }
        return constModel
    }
	
	def static getTagTxt(Set<String> reqTags, Set<String> configTags) {
        '''
        «FOR elm : reqTags»
            @«elm»
        «ENDFOR»
        «FOR elm : configTags»
            @«elm»
        «ENDFOR»
        '''
    }
	
	def static getActionDef(Constraints root){
		var actionDef = new HashSet<Actions>
		//add local action def
		if(!root.actions.isNullOrEmpty) actionDef.addAll(root.actions)
		//add imported action def
		var importedConstraintSource = getConstraintsModel(root)
		for(c : importedConstraintSource) actionDef.addAll(c.actions)
		//if composition is not empty
		if(!root.composition.isNullOrEmpty){
			for(comps : root.composition){
				for(t : comps.templates){
					actionDef.addAll((t.eContainer as Constraints).actions)
				}
			}
		}
		return actionDef.toList
	}
}