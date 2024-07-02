package nl.esi.comma.constraints.generator

import nl.esi.comma.constraints.generator.report.ConformanceReport.ConformanceResults
import java.util.HashSet
import java.util.Map
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.util.ArrayList
import nl.esi.comma.automata.AlignResult
import java.util.HashMap
import java.util.List
import nl.esi.comma.scenarios.scenarios.SpecFlowScenario
import nl.esi.comma.scenarios.scenarios.KEY_ID
import nl.esi.comma.automata.AlignResult.Status
import nl.esi.comma.automata.EAutomaton

class CoCoGenerator {
    
    var constraintTestConformanceSet = new HashSet<ConformanceResults>
    
    def checkConformanceAndCoverage(Scenarios scn, Map<String, ConstraintStateMachine> mapContraintToAutomata, IFileSystemAccess2 fsa, String path) 
    {
        for(constraint : mapContraintToAutomata.keySet) 
        {
            var coverage = 0.0
            var numAccepted = 0
            var numSCN = getNumSCN(scn)
            
            var constraintSM = mapContraintToAutomata.get(constraint)
            
            // var result = new ConformanceResults(constraint, numSCN, coverage)
            var result = new ConformanceResults(constraint, numSCN, coverage)
            result.constraintText = constraintSM.constraintText
            result.constraintDot = constraintSM.dot
            /*System.out.println("Constraint Text")
            System.out.println(result.constraintText)
            System.out.println(result.constraintDot)*/
                        
            var aut = new EAutomaton
            aut.addRegexes(mapContraintToAutomata.get(constraint).regExList)
            var updatedUnicodeMap = removeCyclesInUnicodeMap(mapContraintToAutomata.get(constraint).compoundUnicodeMap) 
            
            for(key : updatedUnicodeMap.keySet) {
                for(elm : updatedUnicodeMap.get(key))
                    aut.addMacro(key, elm)
            }
                        
            if(scn!==null) 
            {
                var resList = new ArrayList<AlignResult>                
                for(s : scn.specFlowScenarios) 
                {
                    var currSCN = new ArrayList<String>
                    var charSCN = new String
                    for(var i=0; i < s.events.size; i++) {
                        var act = s.events.get(i)
                        charSCN += mapContraintToAutomata.get(constraint).getStepChar(act.name)
                        currSCN.add(act.name)
                    }
                    // System.out.println("Going to align SCN "+ s.name +" with contents: " + charSCN)
                    
                    var res = aut.alignScenario(charSCN)
                    resList.add(res)
                    
                    /*System.out.println(" status: " + res.status)
                    System.out.println(" Accepted: " + res.accepted)
                    if(res.notAccepted.length > 0) displaySCN(res.accepted, mapContraintToAutomata, constraint)
                    System.out.println(" Not Accepted: " + res.notAccepted)
                    if(res.notAccepted.length > 0) displaySCN(res.notAccepted, mapContraintToAutomata, constraint)
                    System.out.println(" scenario: " + res.scenario)*/
                    var configList = new ArrayList<String>
                    for(p : s.events.head.product) configList.addAll(p.value)
                    
                    // FULLY_ACCEPTED, PARTIAL_ACCEPTED, NOT_ACCEPTED
                    if(!res.status.equals(Status.FULLY_ACCEPTED)) {
                        //if(!res.status.equals(Status.PARTIAL_ACCEPTED)) {
                            if(!res.notAccepted.nullOrEmpty) {
                                result.addListOfViolatingScenarios(getSCNTitle(s), configList, getSCNFilePath(s), removeUnderscores(currSCN), 
                                newArrayList(mapContraintToAutomata.get(constraint).getStepName(res.notAccepted.charAt(0)).replaceAll("_", " ").trim), constraintSM.highLightedKeyWords) // TODO get this feedback better. Discuss.
                            }
                            else
                                result.addListOfViolatingScenarios(getSCNTitle(s), configList, getSCNFilePath(s), removeUnderscores(currSCN), 
                                newArrayList("Expected step not found!"), constraintSM.highLightedKeyWords) // TODO get this feedback better. Discuss.
                        /*} else {
                            // we will consider partial acceptance as full acceptance. TODO Further classify based on whether all events were eaten at least once
                            result.addListOfConformingScenarios(getSCNTitle(s) + "\\n(Partially Accepted)", configList, getSCNFilePath(s), 
                                removeUnderscores(currSCN), constraintSM.highLightedKeyWords
                            )
                            numAccepted++
                        }*/
                    }
                    else {
                        println("Accepted Scenario Name: " + s.name)
                        for(p : s.events.head.product) println("Configurations: " + p.value)
                        System.out.println(configList)
                        result.addListOfConformingScenarios(getSCNTitle(s), configList, getSCNFilePath(s), removeUnderscores(currSCN), constraintSM.highLightedKeyWords)
                        numAccepted++
                    }
                }
                var covResult = aut.calculateCoverage(resList)
                /*System.out.println("    Coverage ")
                System.out.println("    State Coverage: "+ covResult.stateCoverage)
                System.out.println("    Transition Coverage: "+ covResult.transitionCoverage)*/
                
                coverage = (numAccepted/numSCN.doubleValue)*100.0
                result.testCoverage = coverage
                result.stateCoverage = covResult.stateCoverage*100.0
                result.transitionCoverage = covResult.transitionCoverage*100.0
                result.numberOfConformingSCN = numAccepted
            }
            constraintTestConformanceSet.add(result)
            fsa.generateFile(path + "Conformance\\" + constraint + "_conformance_report.txt", generateReport(result))
        }
        constraintTestConformanceSet
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
    
    def ArrayList<String> removeUnderscores(List<String> scnList) {
        var _scnList = new ArrayList<String>
        for(elm : scnList) _scnList.add(elm.replaceAll("_", " ").trim)
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