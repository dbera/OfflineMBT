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
import java.util.HashSet
import java.util.List
import java.util.Map
import nl.esi.comma.automata.AlgorithmType
import nl.esi.comma.automata.EAutomaton
import nl.esi.comma.automata.ScenarioComputeResult
import nl.esi.comma.constraints.constraints.ActionType
import nl.esi.comma.constraints.constraints.Actions
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.generator.report.ConformanceReport.Statistics
import nl.esi.comma.constraints.generator.report.ConformanceReport.TestGeneration
import nl.esi.comma.scenarios.scenarios.KEY_ID
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.steps.step.StepType
import nl.esi.comma.steps.step.Steps
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.IFileSystemAccess2
import nl.esi.comma.constraints.generator.report.ConformanceReport.SimScore
import nl.esi.comma.constraints.generator.report.ConformanceReport.Similarity

class TestGenerator {
 
    var configTags = new HashSet<String>
    var reqTags = new HashSet<String>
    var taskName = new String
    var descTxt = new String
    var Steps stepModel = null
    var mapOfExistingTestIdToName = new HashMap<Integer, String>
    var mapOfNewTestIdToName = new HashMap<Integer, String> 
    
    var constraintTestGenerationStatisticsSet = new HashSet<TestGeneration>
    
    def getList(HashSet<String> hsStr) {
        var lst = new ArrayList<String>
        for(elm : hsStr) lst.add(elm)
        return lst
    }
    
    def generateSimilarityStatistics(String constraint, 
                                    Map<Integer, String> mapExistingTest, 
                                    Map<Integer, String> mapNewTest,
                                    List<SimilariyScore> listOfSimilarityScores, 
                                    IFileSystemAccess2 fsa) {
        var txt = 
        '''
        
        Constraint Name: «constraint»
        
            «FOR sim : listOfSimilarityScores»
                «IF mapExistingTest.containsKey(sim.EID)»Existing Test: «mapExistingTest.get(sim.EID)»«ENDIF»
                and 
                «IF mapNewTest.containsKey(sim.NID)»Generated Test: «mapNewTest.get(sim.NID)»«ENDIF»
                have
                structural similarity of «(1.0 - sim.JIndex) * 100.0» %
                step ordering similarity of «(1.0 - sim.NED) * 100.0» %
                    
            «ENDFOR»
        '''
        fsa.generateFile("Similarity_Metrics_For_" + constraint + ".txt", txt)
    }
    
    def initializeAutomatonForConstraint(String constraint, 
            Map<String, ConstraintStateMachine> mapContraintToAutomata) {
                
        var aut = new EAutomaton
        System.out.println("    REGEXES : " + mapContraintToAutomata.get(constraint).regExList)
        aut.addRegexes(mapContraintToAutomata.get(constraint).regExList)
            
        var updatedUnicodeMap = removeCyclesInUnicodeMap(mapContraintToAutomata.get(constraint).compoundUnicodeMap) 
        System.out.println("    MACRO MAP : " + updatedUnicodeMap)
           
        for(key : updatedUnicodeMap.keySet) {
            for(elm : updatedUnicodeMap.get(key))
                aut.addMacro(key, elm)
        }
        return aut        
    }

    def generateCharSequenceListOfExistingScenarios(Scenarios scn, String constraint, 
            Map<String, ConstraintStateMachine> mapContraintToAutomata, 
            HashMap<Integer, String> mapOfExistingTestIdToName) {
                
            var charSCNList = new ArrayList<String>
            var eidx = 0
            if(scn!==null) {
                for(s : scn.specFlowScenarios) {
                    var currSCN = new ArrayList<String>
                    var charSCN = new String
                    for(var i=0; i < s.events.size; i++) {
                        var act = s.events.get(i)
                        charSCN += mapContraintToAutomata.get(constraint).getStepChar(act.name)
                        currSCN.add(act.name)
                    }
                    var scnName = new String
                    for(elm : s.scenarioAttributes) { 
                        if(elm.key.equals(KEY_ID.SCN_NAME)) 
                            scnName = elm.value.head
                    } 
                    mapOfExistingTestIdToName.put(eidx,scnName)
                    charSCNList.add(charSCN)
                    eidx++
                }
            }
            return charSCNList        
    }
    
    def computeMapOfNewTestIdToName(String constraint, List<String> charSCNListOfNewScenarios) {
        var nidx = 0
        for(elm : charSCNListOfNewScenarios) {
            mapOfNewTestIdToName.put(nidx, constraint + nidx + " - " + descTxt)
            nidx++
        }        
    }
    
    def computeTimesTransitionExecuted(String constraint, 
                Map<String, ConstraintStateMachine> mapContraintToAutomata,
                ScenarioComputeResult res) {
                                    
        var Map<Integer, List<String>> timesExecuted = new HashMap<Integer, List<String>>
        for (key : res.timesTransitionIsExecuted.keySet) {
                var transitions = res.timesTransitionIsExecuted.get(key)
                for (tran : transitions){
                    var cAutomataInst = mapContraintToAutomata.get(constraint)
                    //assumption the min and max are the same
                    if (!timesExecuted.containsKey(key)){
                        timesExecuted.put(key, newArrayList)
                    } 
                    timesExecuted.get(key).add(cAutomataInst.getStepName(tran.max))
                }
            } 
         return timesExecuted      
    }
    
    def printGeneratedTests(String constraint, List<String> charSCNListOfNewScenarios, 
                         Map<String, ConstraintStateMachine> mapContraintToAutomata) {
                             
        var numCompleteSCN = 0
        for(strSCN : charSCNListOfNewScenarios) {
            var anyFound = false
            var lst = new ArrayList
            for(var idx = 0; idx < strSCN.length; idx++) {
                var name = mapContraintToAutomata.get(constraint).getStepName(strSCN.charAt(idx))
                lst.add(name)
            }
            if(!anyFound) {
                numCompleteSCN++
                System.out.println("    SCN: " + lst)
            }
        }
        System.out.println("    Total SCENARIO Nos. " + charSCNListOfNewScenarios.size)
        System.out.println("    Complete Scenarios: " + numCompleteSCN)        
    }
    
    def transformCharSequencesToScenarios(String constraint, List<String> charSCNListOfNewScenarios, 
                        Map<String, ConstraintStateMachine> mapContraintToAutomata) {
        var listOfNewScenarios = new ArrayList<List<String>>
        for(str : charSCNListOfNewScenarios) {
            var chArr = str.toCharArray
            var cAutomataInst = mapContraintToAutomata.get(constraint)
            var newStrList = new ArrayList<String>
            for(c : chArr) newStrList.add(cAutomataInst.getStepName(c))
            listOfNewScenarios.add(newStrList)
        }    
        return listOfNewScenarios
    }
    
    def generateTestScenarios(Map<String, ConstraintStateMachine> mapContraintToAutomata, 
                                Steps stepModel, Constraints constraintSource, int numSCN,
                                String _descTxt,
                                IFileSystemAccess2 fsa, 
                                String path, String _taskName,
                                AlgorithmType algorithmType, int k, 
                                boolean skipAny, boolean skipDuplicateSelfLoop, boolean skipSelfLoop,
                                Scenarios scn,
                                Integer timeout, Integer similarity) {
                                    
        descTxt = _descTxt
        taskName = _taskName
    	
        for(constraint : mapContraintToAutomata.keySet) 
        {
            //System.out.println("CONSTRAINT-NAME: " + constraint + " with existing scn nos: " + scn.specFlowScenarios.size)
            
            configTags = getConfigurationTags(constraintSource, constraint)
            reqTags = getRequirementTags(constraintSource, constraint)
            descTxt = getDescText(constraintSource, constraint)
            this.stepModel = stepModel
            this.mapOfExistingTestIdToName = new HashMap<Integer, String>
            this.mapOfNewTestIdToName = new HashMap<Integer, String>
            
            var aut = initializeAutomatonForConstraint(constraint, mapContraintToAutomata)
            var charSCNListOfExistingScenarios = generateCharSequenceListOfExistingScenarios(scn, constraint, 
                                        mapContraintToAutomata, mapOfExistingTestIdToName)
            
            var skipCharacters = new ArrayList<Character>
            if (skipAny) skipCharacters.add(mapContraintToAutomata.get(constraint).terminalChar)
            
            var res = aut.computeScenarios(algorithmType, charSCNListOfExistingScenarios, k, skipCharacters, skipDuplicateSelfLoop, skipSelfLoop, timeout)
            //var res = aut.computeScenarios(algorithmType, k, skipCharacters, skipDuplicateSelfLoop, skipSelfLoop, timeout)
            var charSCNListOfNewScenarios = res.scenarios
            
            var testMinimizerInst = new TestMinimizer
            charSCNListOfNewScenarios = testMinimizerInst.computeMinimalTests(charSCNListOfExistingScenarios, 
                                                                        charSCNListOfNewScenarios, similarity)
            var similarityScores = testMinimizerInst.listOfSimilarityScores
            System.out.println("Similarity Score: " + similarityScores)
            computeMapOfNewTestIdToName(constraint, charSCNListOfNewScenarios)
            generateSimilarityStatistics(constraint, mapOfExistingTestIdToName, 
                                    mapOfNewTestIdToName, similarityScores, fsa)
            
            var Map<Integer, List<String>> timesExecuted = computeTimesTransitionExecuted(constraint, mapContraintToAutomata, res)
            var statistics = new Statistics(res.algorithm.toString, res.amountOfStatesInAutomaton, res.amountOfTransitionsInAutomaton, 
                            res.amountOfPaths, res.amountOfSteps, res.percentageTransitionsCoveredByExistingScenarios, res.averageAmountOfStepsPerSequence,
                        	res.percentageOfStatesCovered, res.percentageOfTransitionsCovered, res.averageTransitionExecution, timesExecuted)
            
            var constraintSM = mapContraintToAutomata.get(constraint)
            //similarity Scores
            var List<Similarity> sims = newArrayList
            var String extId = ""
			var Map<String, List<SimScore>> maps = newLinkedHashMap
            for (sim : similarityScores){
            	if (mapOfExistingTestIdToName.containsKey(sim.EID)){
            		extId = mapOfExistingTestIdToName.get(sim.EID)
            	}
        		if (maps.containsKey(extId)){
        			if (mapOfNewTestIdToName.containsKey(sim.NID)){
	            		var simScore = new SimScore(mapOfNewTestIdToName.get(sim.NID), (1.0 - sim.JIndex) * 100.0, (1.0 - sim.NED) * 100.0)
	            		maps.get(extId).add(simScore)
	            	}
        		} else {
        			if (mapOfNewTestIdToName.containsKey(sim.NID)){
	            		var simScore = new SimScore(mapOfNewTestIdToName.get(sim.NID), (1.0 - sim.JIndex) * 100.0, (1.0 - sim.NED) * 100.0)
	            		var List<SimScore> scores = newArrayList
	            		scores.add(simScore)
	            		maps.put(extId, scores)
	            	}
        		}
            }
            for (testId: maps.keySet){
            	var sim = new Similarity(testId, maps.get(testId))
            	sims.add(sim)
            }
            var result = new TestGeneration(constraint, constraintSM.constraintText, 
                constraintSM.dot, getList(configTags), constraint + ".feature", statistics, sims)
            constraintTestGenerationStatisticsSet.add(result)
           
           // printGeneratedTests(constraint, charSCNListOfNewScenarios, mapContraintToAutomata)
           
            var listOfNewScenarios = transformCharSequencesToScenarios(constraint, charSCNListOfNewScenarios, mapContraintToAutomata)
            
            if(listOfNewScenarios.size > 0) {
            	//generate feature file with data string between quotes
				fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".feature", FeatureGenerator.generateFeatureFileWithData(constraint, stepModel, constraintSource, listOfNewScenarios, configTags, reqTags, descTxt, constraintSM.stepsMapping))
                //generate feature file without data
                //fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".feature", generateFeatureFile(constraint, stepModel, constraintSource, listOfNewScenarios))
                // TODO generate statistics in new implementation
                // fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".statistics.txt", algorithmCls.statistics)
            }
        }
        return constraintTestGenerationStatisticsSet
    }

    def displaySCN(String strSCN, Map<String, ConstraintStateMachine> mapContraintToAutomata, String constraint) {
        for(var idx = 0; idx < strSCN.length; idx++) {
            System.out.println("    Step: "+ strSCN.charAt(idx) + " Name: " + mapContraintToAutomata.get(constraint).getStepName(strSCN.charAt(idx)))
        }
    }

    // remove cycle in unicode map
    def removeCyclesInUnicodeMap(HashMap<Character, List<List<Character>>> compUnicodeMap) {
        var updatedUnicodeMap = new HashMap<Character, List<List<Character>>>
        for(key : compUnicodeMap.keySet) {
            var charListOfList = new ArrayList<List<Character>>
            for(lst : compUnicodeMap.get(key)) {
                var charList = new ArrayList<Character>
                for(elm : lst) {
                    // remove self reference
                    if(!elm.equals(key)) charList.add(elm)
                }
                if(!charList.empty) charListOfList.add(charList)
            }
            updatedUnicodeMap.put(key,charListOfList)
        }
        return updatedUnicodeMap
    }

    // TODO this aggregates all tags in a given constraint file. Does not generate scenarios with specific tags.
    // move this and specialize it for given a composition find set of tags
    def getRequirementTags(Constraints constraintsSource, String constraintName) {
        var tagList = new HashSet<String>
        for(elm : constraintsSource.composition) {
            if(elm.name.equals(constraintName))
                for(f : elm.tagStr)
                   tagList.add(f)
        }
        tagList
    }

    def getDescText(Constraints constraintsSource, String constraintName) {
        for(elm : constraintsSource.composition) {
            if(elm.name.equals(constraintName))
                return elm.descTxt
        }
    }

    // TODO this aggregates all tags in a given constraint file. Does not generate scenarios with specific tags.
    // move this and specialize it for given a composition find set of tags 
    def getConfigurationTags(Constraints constraintsSource, String constraintName) {
        var tagList = new HashSet<String>
        for(elm : constraintsSource.commonFeatures) {
            tagList.add(elm.name)
        }
        for(elm : constraintsSource.composition) {
            if(elm.name.equals(constraintName))
                for(f : elm.features)
                   tagList.add(f.name)
        }
        tagList
    }

	
	
	def generateFeatureFile(String constraint, Steps stepModel, Constraints constraintSource, ArrayList<List<String>> SCNList) {
        var idx = 0
        var stepIdx = 0
        var ctx = StepType.GIVEN
        
        var actionDef = new ArrayList<Actions> // constraintSource.actions
        if(!constraintSource.actions.isNullOrEmpty) actionDef.addAll(constraintSource.actions)
        var importedConstraintSource = getConstraintsModel(constraintSource)
        for(c : importedConstraintSource) actionDef.addAll(c.actions)
        
        '''
        Feature: «constraint»
        
        «FOR stepList : SCNList»
            «IF getStepType(stepList.head,stepModel,actionDef).equals(StepType.GIVEN) || getStepType(stepList.head,stepModel,actionDef).equals(StepType.WHEN)»
            «getTagTxt»
            Scenario: «constraint»«idx» - «descTxt»
            «{idx++ ""}»
            «{ctx = StepType.GIVEN ""}»
            «{stepIdx = 0 ""}»
            «FOR step : stepList»
                «IF ctx.equals(getStepType(step, stepModel,actionDef))»
                    «IF stepIdx === 0»
                        «ctx» «step.replaceAll("_", " ")»
                    «ELSE»
                        «StepType.AND» «step.replaceAll("_", " ")»
                    «ENDIF»
                «ELSE»
                    «IF !getStepType(step,stepModel,actionDef).equals(StepType.AND)»
                        «{ctx = getStepType(step,stepModel,actionDef) ""}»
                        «IF ctx.equals(StepType.WHEN)» 
                        
                        «ENDIF»
                        «ctx» «step.replaceAll("_", " ")»
                    «ELSE»
                        «StepType.AND» «step.replaceAll("_", " ")»
                    «ENDIF»
                «ENDIF»
                «{ctx = getStepType(step,stepModel,actionDef) ""}»
                «{stepIdx++ ""}»
            «ENDFOR»
            
            «ENDIF»            
        «ENDFOR»
        '''
    }

    def getTagTxt() {
        '''
        «FOR elm : reqTags»
            @«elm»
        «ENDFOR»
        «FOR elm : configTags»
            @«elm»
        «ENDFOR»
        '''
    }
    
    def getStepText(String step, Steps stepModel) {
        
    }
    
    def getStepType(String step, Steps stepModel, List<Actions> actList) {
        if(stepModel!== null) {
            for(action : stepModel.actionList.acts) {
                if(step.equals(action.name)) 
                    return action.label.head
            }
        }
        //if(actList)
        for(actl : actList) {
            for(action : actl.act)
                if(step.equals(action.name))
                    if(action.act.equals(ActionType.PRE_CONDITION)) return StepType.GIVEN
                    else if(action.act.equals(ActionType.TRIGGER)) return StepType.WHEN
                    else if(action.act.equals(ActionType.OBSERVABLE)) return StepType.THEN
                    else if(action.act.equals(ActionType.CONJUNCTION)) return StepType.AND
                    else {}
        }
        //System.out.println("Did not find step type during test generation!")
        return StepType.AND
    }

   def getConstraintsModel(Constraints model) {
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
}