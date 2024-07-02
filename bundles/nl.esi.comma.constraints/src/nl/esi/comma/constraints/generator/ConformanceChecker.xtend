package nl.esi.comma.constraints.generator

import java.util.ArrayList
import java.util.HashSet
import java.util.Map
import nl.esi.comma.constraints.generator.report.ConformanceReport.ConformanceResults
import nl.esi.comma.scenarios.scenarios.KEY_ID
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.scenarios.scenarios.SpecFlowScenario
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.util.List

class ConformanceChecker {
    
    var constraintTestConformanceSet = new HashSet<ConformanceResults>
    
    def checkConformance(Scenarios scn, Map<String, ConstraintStateMachine> mapContraintToAutomata, IFileSystemAccess2 fsa, String path) 
    {        
        for(constraint : mapContraintToAutomata.keySet) {
            var fa = mapContraintToAutomata.get(constraint).computedAutomata
            var unicodeMap = mapContraintToAutomata.get(constraint).unicodeMap
            //for(k:unicodeMap.keySet)
                //System.out.println("UNICODE MAP: " + k + " - " + unicodeMap.get(k))
            var currState = fa.initialState
            var violation = false

            var coverage = 0.0
            var numAccepted = 0
            var numSCN = getNumSCN(scn)
            var result = new ConformanceResults(constraint, numSCN, coverage)//Change for dashboard TODO
            //result.constraintText = constraintText
            //result.constraintDot = dot
                        
            for(s : scn.specFlowScenarios) {
                violation = false
                currState = fa.initialState
                var currSCN = new ArrayList<String>
                for(act : s.events) { // for every step in a specflow scenario
                    currSCN.add(act.name) // TODO given act.name (with Data), return act without data. 
                    if(!violation) {
                        var stepChar = unicodeMap.get(act.name) // get char corresponding action in scenario
                        if(!unicodeMap.containsKey(act.name)) { 
                            //System.out.println(" Did not find char " + act.name)
                            stepChar = unicodeMap.get("ANY")
                        }
                        //System.out.println(" Going to use: " + stepChar)
                        
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
            System.out.println(" Coverage (percentage of test scenarios satisfying Constraint " + constraint + "): " + coverage + "%")
            constraintTestConformanceSet.add(result)
            fsa.generateFile(path + "Conformance\\" + constraint + "_conformance_report.txt", generateReport(result))    
        }
        constraintTestConformanceSet
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