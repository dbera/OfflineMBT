package nl.esi.comma.behavior.scl.generator

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import java.util.Map
import org.eclipse.xtext.generator.IFileSystemAccess2
import nl.esi.comma.behavior.scl.generator.ConstraintStateMachine
import nl.esi.comma.behavior.scl.scl.Model
import nl.esi.comma.behavior.scl.scl.Actions
import nl.esi.comma.behavior.scl.scl.ActionType
import nl.esi.comma.automata.AlgorithmType
import nl.esi.comma.automata.EAutomaton

class ScenarioGenerator {

    def generateTestScenarios(Map<String, ConstraintStateMachine> mapContraintToAutomata, 
    							List<Actions> actList,
                                Model constraintSource, int numSCN,
                                IFileSystemAccess2 fsa, 
                                String path, String _taskName,
                                String algorithm) 
    {
    	var acts = actList.head
        for(constraint : mapContraintToAutomata.keySet) {
            var automata = mapContraintToAutomata.get(constraint).computedAutomata;
            var map = mapContraintToAutomata.get(constraint).unicodeMap;
            var exprMap = mapContraintToAutomata.get(constraint).actExprMap
            /*var Algorithm algorithmCls = null;
            if (algorithm.equals("prefix-suffix")) algorithmCls = new AlgorithmPrefixSuffix(automata, map, 1, false);
            if (algorithm.equals("prefix-suffix-minimized")) algorithmCls = new AlgorithmPrefixSuffix(automata, map, 1, true);
            if (algorithm.equals("bfs")) algorithmCls = new AlgorithmDfsBfs(automata, map, "bfs");
            if (algorithm.equals("dfs")) algorithmCls = new AlgorithmDfsBfs(automata, map, "dfs");*/
            
            var AlgorithmType algorithmType;
            if (algorithm.equals("prefix-suffix")) algorithmType = AlgorithmType.PREFIX_SUFFIX;
            if (algorithm.equals("prefix-suffix-minimized")) algorithmType = AlgorithmType.PREFIX_SUFFIX_MINIMIZED;
            if (algorithm.equals("bfs")) algorithmType = AlgorithmType.BFS;
            if (algorithm.equals("dfs")) algorithmType = AlgorithmType.DFS;
           
            var List<String> existingCases = #[]
            /*if (scn !== null) {
                existingCases = scn.specFlowScenarios.map[s | s.events.map[e | map.get(e.name)].join("")]
            }*/
            
            val result = new EAutomaton(automata).computeScenarios(algorithmType, existingCases, 3)

            var listOfStrList = new ArrayList<List<String>>
            for(str : result.scenarios) {
                var chArr = str.toCharArray
                var cAutomataInst = mapContraintToAutomata.get(constraint) // get the corresponding automata
                var newStrList = new ArrayList<String>
                for(c : chArr) {
                    //System.out.println("translating char: " + c + " to " + cAutomataInst.getStepName(c))
                    newStrList.add(cAutomataInst.getStepName(c)) // get the actual step name
                }
                System.out.println("Complete: " + str + " - > " + newStrList)
                listOfStrList.add(newStrList)
            }
            
            if(listOfStrList.size > 0) {
                fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".recipe", generateRecipe(constraint, acts, exprMap, listOfStrList))
                fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".PSrecipe", generatePSInit(constraint, acts, exprMap, listOfStrList))
                // fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".feature", generateFeatureFile(constraint, acts, listOfStrList))    
                fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".statistics.txt", result.statistics)
            }
        }           
    }
    
    def getStepType(String step, Actions acts) {
    	for(a : acts.act) {
    		if(a.name.equals(step))
    			return a.act
    	}
    	return ActionType.TRIGGER
    }

	def getGherkinType(ActionType actType) {
		if(actType.equals(ActionType.PRE_CONDITION)) return "Given"
		if(actType.equals(ActionType.TRIGGER)) return "When"
		if(actType.equals(ActionType.OBSERVABLE)) return "Then"
		if(actType.equals(ActionType.CONJUNCTION)) return "And"
	}

	

   def generateFeatureFile(String constraint, Actions acts, ArrayList<List<String>> SCNList) {
        var idx = 0
        var stepIdx = 0
        var ctx = ActionType.PRE_CONDITION
                
        '''
			Feature: «constraint»
			
			«FOR stepList : SCNList»
				Scenario: «constraint»_«idx»
				«{idx++ ""}»
				«{ctx = ActionType.PRE_CONDITION ""}»
				«{stepIdx = 0 ""}»
				«FOR step : stepList»
					«IF ctx.equals(getStepType(step, acts))»
						«IF stepIdx == 0»
							«getGherkinType(ctx)» «step»
						«ELSE»
							«ActionType.CONJUNCTION» «step»
						«ENDIF»
					«ELSE»
						«IF stepIdx == 0»
							«getGherkinType(ctx)» «step»
						«ELSE»
							«{ctx = getStepType(step, acts) ""}»
							«getGherkinType(ctx)» «step»
						«ENDIF»
					«ENDIF»
					«{stepIdx++ ""}»
				«ENDFOR»
				
			«ENDFOR»
		'''
    }

   	def generatePSInit(String constraint, Actions acts, Map<String, String> exprMap, ArrayList<List<String>> SCNList) {
   		var idx = 0
        var stepIdx = 0
        
	'''
		«FOR stepList : SCNList»
			fab_chip_recipe := 
			ChipRecipe { 
				lots = <map<int, Lot>> { 
			«{idx++ ""}»
			«{stepIdx = 1 ""}»
			«FOR step : stepList SEPARATOR ''','''»
						// «step»
						«IF !step.equals("ANY") && exprMap.containsKey(step)»«exprMap.get(step).replaceAll("lot :=", stepIdx + " ->")»«ENDIF»
				«{stepIdx++ ""}»
			«ENDFOR»
				}
			}
		«ENDFOR»
	'''
   	}

   	def generateRecipe(String constraint, Actions acts, Map<String, String> exprMap, ArrayList<List<String>> SCNList) {
        var idx = 0
        var stepIdx = 0
                
        '''
			Recipe-Name: «constraint»
			
			«FOR stepList : SCNList»
				Recipe: «constraint»_«idx»
				«{idx++ ""}»
				«{stepIdx = 0 ""}»
				«FOR step : stepList»
						«IF !step.equals("ANY")»«step» «IF exprMap.containsKey(step)» : «exprMap.get(step)»«ENDIF»«ENDIF»
					«{stepIdx++ ""}»
				«ENDFOR»
				
			«ENDFOR»
		'''
    }
}
