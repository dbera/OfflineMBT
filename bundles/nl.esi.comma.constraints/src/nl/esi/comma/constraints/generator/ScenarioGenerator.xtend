package nl.esi.comma.constraints.generator

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import java.util.Map
import nl.esi.comma.steps.step.StepType
import nl.esi.comma.steps.step.Steps
import org.eclipse.xtext.generator.IFileSystemAccess2
import nl.esi.comma.constraints.constraints.Constraints
import java.util.Set
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.constraints.constraints.Actions
import nl.esi.comma.constraints.constraints.ActionType
import nl.esi.comma.automata.EAutomaton
import nl.esi.comma.automata.AlgorithmType
import dk.brics.automaton.State
import dk.brics.automaton.Transition

class ScenarioGenerator {

    var configTags = new HashSet<String>
    var reqTags = new HashSet<String>
    var taskName = new String
    var descTxt = new String

    def generateTestScenarios(Map<String, ConstraintStateMachine> mapContraintToAutomata, 
                                Steps stepModel, Constraints constraintSource, int numSCN,
                                HashSet<String> _configTags,
                                HashSet<String> _reqTags, 
                                String _descTxt,
                                IFileSystemAccess2 fsa, 
                                String path, String _taskName,
                                String algorithm,
                                Scenarios scn) 
    {
        configTags = _configTags // is re-computed. TODO drop from args
        reqTags = _reqTags // is recomputed. TODO drop from args
        descTxt = _descTxt
        taskName = _taskName // not used
        for(constraint : mapContraintToAutomata.keySet) {
            configTags = getConfigurationTags(constraintSource, constraint)
            reqTags = getRequirementTags(constraintSource, constraint)

            // generate scenarios
            //var strList = mapContraintToAutomata.get(constraint).computedAutomata.getStrings(numSCN).toSet
            /*var List<Character> currPath = new ArrayList<Character>();
            var List<String> paths = new ArrayList<String>();
            var List<String> incompletePaths = new ArrayList<String>();
            var Set<String> visitedStates = new HashSet<String>();
            //System.out.println(getPaths(a.getInitialState(), currPath, paths, incompletePaths, visitedStates));            
            var strList = getPaths(mapContraintToAutomata.get(constraint).computedAutomata.initialState,
                                    currPath, paths, incompletePaths, visitedStates)
            System.out.println("Debug")
            System.out.println(strList)
            System.out.println(incompletePaths)*/
            
            
            //////////////////// USE AUTOMATA LIB //////////////////////////////////
            var automata = mapContraintToAutomata.get(constraint).computedAutomata;
            val map = mapContraintToAutomata.get(constraint).unicodeMap;
            var AlgorithmType algorithmType;
            if (algorithm.equals("prefix-suffix")) algorithmType = AlgorithmType.PREFIX_SUFFIX;
            if (algorithm.equals("prefix-suffix-minimized")) algorithmType = AlgorithmType.PREFIX_SUFFIX_MINIMIZED;
            if (algorithm.equals("bfs")) algorithmType = AlgorithmType.BFS;
            if (algorithm.equals("dfs")) algorithmType = AlgorithmType.DFS;
           
            var List<String> existingCases = #[]
            if (scn !== null) {
                existingCases = scn.specFlowScenarios.map[s | s.events.map[e | map.get(e.name)].join("")]
            }
            
            val result = new EAutomaton(automata).computeScenarios(algorithmType, existingCases, 1, #[], false, false, null)
           
            //////////////////// USE AUTOMATA LIB //////////////////////////////////
            
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
            /*for(str : incompletePaths) {
                var chArr = str.toCharArray
                var cAutomataInst = mapContraintToAutomata.get(constraint) // get the corresponding automata
                var newStrList = new ArrayList<String>
                for(c : chArr) {
                    newStrList.add(cAutomataInst.getStepName(c)) // get the actual step name
                }
                System.out.println("Incomplete: " + str + " - > " + newStrList)
            }*/
            
            var acts = constraintSource.actions.head
            var exprMap = mapContraintToAutomata.get(constraint).actExprMap
            
            if(listOfStrList.size > 0) {
                fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".recipe", generateRecipe(constraint, acts, exprMap, listOfStrList))
                fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".PSrecipe", generatePSInit(constraint, acts, exprMap, listOfStrList))
                // fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".feature", generateFeatureFile(constraint, acts, listOfStrList))    
                fsa.generateFile(path + "GeneratedFeatures\\" + constraint + ".statistics.txt", result.statistics)
            }
        }           
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
        var actionDef = constraintSource.actions
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
    
    def getStepType(String step, Steps stepModel, List<Actions> actList) {
        for(action : stepModel.actionList.acts) {
            if(step.equals(action.name)) 
                return action.label.head
        }
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
 
    // DFS
    def List<String> getPaths(State s, 
                        List<Character> currPath, 
                        List<String> paths, 
                        List<String> incompletePaths, 
                        Set<String> visitedStates
    ) 
    {   
        if(s.isAccept()) {
            paths.add(currPath.toString().substring(1, 3 * currPath.size() - 1).replaceAll(", ", ""));
            //return paths;
        }
        if(visitedStates.contains(s.toString())) {
            incompletePaths.add(currPath.toString().substring(1, 3 * currPath.size() - 1).replaceAll(", ", ""));
            return paths;
        }
        visitedStates.add(s.toString());
        
        for(Transition t : s.getTransitions()) {
            var c = t.getMin();
            do {
                currPath.add(c);
                getPaths(t.getDest(), currPath, paths, incompletePaths, visitedStates);
                currPath.remove(currPath.size()-1);
                c++;
            } while(c<=t.getMax());
        }       
        return paths;
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
			«FOR step : stepList SEPARATOR ','»
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
