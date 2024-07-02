package nl.esi.comma.constraints.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import nl.esi.comma.constraints.generator.report.ConformanceReport.ConformanceResults
import nl.esi.comma.scenarios.scenarios.KEY_ID
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.scenarios.scenarios.SpecFlowScenario
import org.eclipse.xtext.generator.IFileSystemAccess2
import dk.brics.automaton.Automaton
import dk.brics.automaton.State

//new class by Luna
class ComformanceChecker {
    
    var constraintTestConformanceSet = new HashSet<ConformanceResults>
    var stepsMapping = new HashMap<String, String> // key: step with data, value: step without data
    var sequenceMapping = new HashMap<String, ArrayList<String>>//key: sequence name, value: a list of steps
    def checkConformance(Scenarios scn, Map<String, ConstraintStateMachine> mapContraintToAutomata, Map<String, String> stepsMapping, Map<String, ArrayList<String>> seqMapping, IFileSystemAccess2 fsa, String path) 
    {
    	this.stepsMapping.putAll(stepsMapping)
    	this.sequenceMapping.putAll(seqMapping)
        for(constraint : mapContraintToAutomata.keySet) {
            var fa = mapContraintToAutomata.get(constraint).computedAutomata
            var unicodeMap = mapContraintToAutomata.get(constraint).unicodeMap
            var result = checkViolation(scn, fa, unicodeMap, constraint)
            System.out.println(" Coverage (percentage of test scenarios satisfying Constraint " + constraint + "): " + result.testCoverage + "%")
            constraintTestConformanceSet.add(result)
            fsa.generateFile(path + "Conformance\\" + constraint + "_conformance_report.txt", generateReport(result))    
        }
        constraintTestConformanceSet
    }
    
    def ConformanceResults checkViolation(Scenarios scn, Automaton fa, Map<String, Character> unicodeMap, String constraint){
    	var currState = fa.initialState
        var violation = false

        var coverage = 0.0
        var numAccepted = 0
        var numSCN = getNumSCN(scn)
        var result = new ConformanceResults(constraint, numSCN, coverage)//Change for dashboard TODO

        for(s : scn.specFlowScenarios) {
            violation = false
            currState = fa.initialState
            var currSCN = new ArrayList<String>
            for(var i=0; i < s.events.size; i++) { // for every step in a specflow scenario
            	var act = s.events.get(i)
            	println(act.name)
                currSCN.add(act.name)
                if(!violation) {
                	//first check single step isPresent or not
                	var stepChar = unicodeMap.get(act.name)
                	var isPresent = false
                	if(stepChar !== null){
                		isPresent = isPresent(currState, stepChar)
                	}
                	//then try with step without data
                	if(!isPresent){
                		var stepWOData = stepsMapping.get(act.name)
                		if(unicodeMap.containsKey(stepWOData)){
                			stepChar = unicodeMap.get(stepWOData)
                    		isPresent = isPresent(currState, stepChar)
                    	}
                	}
                	//try to match sequence
                	if(!isPresent){
                		var matchedSeq = ""
                		var k = i //index for counting the events
                		for(seq : sequenceMapping.keySet){
                			//get steps in the sequence
                			var stepList = sequenceMapping.get(seq)
                			for(var j = 0; j < stepList.size; j++){
                				//get the event
                				var action = s.events.get(k)
                				if(matchStep(stepList.get(j), action.name)){
                					if(j == stepList.size - 1){
                						//last step is matched
                						matchedSeq = seq
                					} else {
                						if (k < s.events.size - 1) {
                							k++ //if not reach the end of the events, continue
                						} else {
                							j = stepList.size //if no next event to match then exit
                						}
                					}
                				} else {
                					j = stepList.size //if not matched then exit
                				}
                			}
                		}
                		
                		if(!matchedSeq.nullOrEmpty){
                			stepChar = unicodeMap.get(matchedSeq)
                			isPresent = isPresent(currState, stepChar)
                			i = k
                		}
                	}
                	//last, try to match ANY
                	if(!isPresent){
                		stepChar = unicodeMap.get("ANY")
                		isPresent = isPresent(currState, stepChar)
                	}
                	println(isPresent)
                    
                    if(isPresent) {
                        currState = currState.step(stepChar) // fire transition!
                        // System.out.println(" Accepting step : " + act.name + " - " + stepChar + " - " + currState.accept)
                    } else { 
                        violation = true
                        // System.out.println(" Violation with step : " + act.name)
                    	// create violating scenario - Activated and Violated
                    	result.addListOfViolatingScenarios(getSCNTitle(s), getSCNFilePath(s), removeUnderscores(currSCN), newArrayList(act.name.replaceAll("_", " ")))
                    }
                }
            }
            if(currState.isAccept && !violation) {
                numAccepted++
                System.out.println(" Scenario Accepted " + s.name)
                // create conforming scenario
                result.addListOfConformingScenarios(getSCNTitle(s), getSCNFilePath(s), removeUnderscores(currSCN))
            }
            else { // Can come here if currState is not accept but violation is false! 
                   // This violation is OK to not report. Unactivated constraint
                System.out.println(" Scenario Rejected " + s.name + " - violation flag: " + violation)
            }
        }
        coverage = (numAccepted/numSCN.doubleValue)*100.0
        result.testCoverage = coverage
        result.numberOfConformingSCN = numAccepted
        return result
    }
    
    //check if a step equal to the action Name
    def boolean matchStep(String step, String actName){
    	if(step.equals(actName)){
    		return true
    	} else {
    		var stepWOData = stepsMapping.get(actName)
    		if(step.equals(stepWOData)){
    			return true
    		}
    	}
    	return false
    }
    
    def boolean isPresent(State currState, Character stepChar){
    	var tlist = currState.transitions // Get Enabled Transitions in State
        var isPresent = false
        for(t : tlist) { // is matching transition present in enabled list
            if(t.min.equals(t.max)) {
                if(t.min.equals(stepChar)) { 
                    isPresent = true
                    //System.out.println(" Matched !")
                }
            } else {
                var c = t.min
                while(!c.equals(t.max)) {
                    if(c.equals(stepChar)) {
                        isPresent = true
                    }
                    c++
                }
                if(c.equals(stepChar)) { // check t.max. Not checked earlier. 
                    isPresent = true
                }
            }
        }
        return isPresent
    }
    
    def ArrayList<String> removeUnderscores(List<String> scnList) {
        var _scnList = new ArrayList<String>
        for(elm : scnList) _scnList.add(elm.replaceAll("_", " "))
        return _scnList
    }
        
    def getNumSCN(Scenarios scn) {
        if(scn.specFlowScenarios.isNullOrEmpty) return 0
        else return scn.specFlowScenarios.size
    }
    
    def getSCNFilePath(SpecFlowScenario s) {
        for(attr : s.featureAttributes) {
            if(attr.key.equals(KEY_ID.LOCATION)) return attr.value.head
        }
        return "Unknown File Path"      
    }
    
    def getSCNTitle(SpecFlowScenario scn) {
        for(attr : scn.scenarioAttributes) {
            if(attr.key.equals(KEY_ID.SCN_NAME)) return attr.value.head
        }
        return "Unknown Scenario Name"
    }
    
    
    def generateReport(ConformanceResults result) {
        return 
        '''
        **********************************************************************
        ********************* CONFORMANCE CHECK ******************************
        **********************************************************************
        
        Constraint Name: «result.constraintName»
        Number of Conforming Scenarios:  «result.numberOfConformainfSCN»
        Coverage: «result.testCoverage» (% of tests satisfying constraint)
        
        **********************************************************************
        
        «FOR cSCN : result.listOfConformingScenarios»
            **********************************************************************
                                Conforming Test Scenarios
            **********************************************************************
            Scenario Name: «cSCN.scenarioName»
            Feature File Location: «cSCN.featureFileLocation»
            
            Scenario Description:
                «FOR elm : cSCN.conformingScenario»
                    + «elm.replaceAll("_"," ")»
                «ENDFOR»
            
        «ENDFOR»
        
        **********************************************************************
        
        «FOR vSCN : result.listOfViolatingScenarios»
            **********************************************************************
                                Violating Test Scenarios
            **********************************************************************
            Scenario Name: «vSCN.scenarioName»
            Feature File Location: «vSCN.featureFileLocation»
            
            Violating Action: «vSCN.violatingAction.forEach[e|e.replaceAll("_"," ")]»
            Scenario Description: 
                «FOR elm : vSCN.violatingScenario»
                    + «elm.replaceAll("_"," ")»
                «ENDFOR»

        «ENDFOR»
        
        **********************************************************************
        '''
    }
}