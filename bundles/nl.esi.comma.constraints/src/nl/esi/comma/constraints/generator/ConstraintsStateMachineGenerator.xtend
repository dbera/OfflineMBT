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

import dk.brics.automaton.Automaton
import dk.brics.automaton.RegExp
import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import nl.esi.comma.constraints.constraints.Act
import nl.esi.comma.constraints.constraints.Actions
import nl.esi.comma.constraints.constraints.AlternatePrecedence
import nl.esi.comma.constraints.constraints.AlternateResponse
import nl.esi.comma.constraints.constraints.AlternateSuccession
import nl.esi.comma.constraints.constraints.AtLeast
import nl.esi.comma.constraints.constraints.AtMost
import nl.esi.comma.constraints.constraints.ChainPrecedence
import nl.esi.comma.constraints.constraints.ChainResponse
import nl.esi.comma.constraints.constraints.ChainSuccession
import nl.esi.comma.constraints.constraints.Choice
import nl.esi.comma.constraints.constraints.CoExistance
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.Dependencies
import nl.esi.comma.constraints.constraints.End
import nl.esi.comma.constraints.constraints.Exact
import nl.esi.comma.constraints.constraints.ExclusiveChoice
import nl.esi.comma.constraints.constraints.Existential
import nl.esi.comma.constraints.constraints.Future
import nl.esi.comma.constraints.constraints.Init
import nl.esi.comma.constraints.constraints.NotChainSuccession
import nl.esi.comma.constraints.constraints.NotCoExistance
import nl.esi.comma.constraints.constraints.NotSuccession
import nl.esi.comma.constraints.constraints.Past
import nl.esi.comma.constraints.constraints.Precedence
import nl.esi.comma.constraints.constraints.Ref
import nl.esi.comma.constraints.constraints.RefActSequence
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.RefStep
import nl.esi.comma.constraints.constraints.RefStepSequence
import nl.esi.comma.constraints.constraints.RespondedExistence
import nl.esi.comma.constraints.constraints.Response
import nl.esi.comma.constraints.constraints.SimpleChoice
import nl.esi.comma.constraints.constraints.Succession
import nl.esi.comma.constraints.constraints.Templates
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.IFileSystemAccess2
import nl.esi.comma.actions.generator.plantuml.ActionsUmlGenerator

class ConstraintsStateMachineGenerator 
{
    var Set<String> activityList = new HashSet<String>();
    var Map<String,Character> unicodeMap = new HashMap<String,Character>(); // global for each constraint file or constraint composition
	var Map<String,String> actionToExprMap = new HashMap<String,String>(); // global for each constraint file
    
    // Support complex mapping of actions to sequences and non-determinism
    var stepDataMap = new HashMap<String, Set<String>>
    var stepsMapping = new HashMap<String, String>
    var Map<String,Character> unusedUnicodeMap = new HashMap<String,Character>();
    var sequenceDefMap = new HashMap<String,List<List<String>>> // list of defined and used macros
    // a -> { b,c,d ; x,y,z } // support non-deterministic mapping
    var compoundUnicodeMap = new HashMap<Character,List<List<Character>>>
    
    val char INIT_CHAR = 'A'
    var char symbol = INIT_CHAR
    char fs = INIT_CHAR;
    
    var Map<String,ConstraintStateMachine> mapContraintToAutomata = new HashMap<String,ConstraintStateMachine>
    
    def transformMap(Map<String, String> _stepsMapping) {
        for(elm : _stepsMapping.keySet) 
            stepsMapping.put(elm, _stepsMapping.get(elm))
        for(elm : stepsMapping.keySet) {
            if(!stepDataMap.containsKey(stepsMapping.get(elm))) {
                var elmSet = new HashSet<String>
                elmSet.add(elm)
                stepDataMap.put(stepsMapping.get(elm), elmSet)    
            } 
            else stepDataMap.get(stepsMapping.get(elm)).add(elm)
        }
        // System.out.println(stepDataMap)
    }
    //Luna 2-8-22, use label with underscore instead of data index
    def computeActionMap(Constraints model) {
    	//add local action definition
        for(acts : model.actions) {
            addActionsToMap(acts)
        }
        //add imported action definition
        var importedConstraints = getConstraintsModel(model)
        if(importedConstraints !== null) {
            for(ic : importedConstraints) {
                for(acts : ic.actions) {
                    addActionsToMap(acts)
                }
            }
        }
        //if composition is not null, add action definition from the references
        if(!model.composition.isNullOrEmpty){
			for(comps : model.composition){
				for(t : comps.templates){
					if (t.eContainer !== null){
						for(acts :(t.eContainer as Constraints).actions){
							addActionsToMap(acts)
						}
					}
				}
			}
		}
        System.out.println("Steps Mapping for Action: " + stepsMapping)
        System.out.println("Steps Data Map: " + stepDataMap)
    }
    
    def addActionsToMap(Actions acts){
    	for(act : acts.act) {
            if(!act.data.nullOrEmpty) {
                if(act.data.head.instances) {
                    var dataList = new HashSet<String>
                    for(r : act.data.head.rows){
                    	var label = act.label
                    	for(var i = 0; i < r.cells.size; i++) {
                    		label = label.replaceAll("<"+act.data.head.header.cells.get(i)+">", r.cells.get(i))
                    	}
                    	label = label.replaceAll(" ", "_")
                    	dataList.add(label)
                    	stepsMapping.put(label, act.label.replaceAll(" ", "_"))
                    }
                    stepDataMap.put(act.label.replaceAll(" ", "_"), dataList)
                }
            }
            if (!act.actParam.nullOrEmpty) {
				for(p : act.actParam) {
                    var dataList = new HashSet<String>
    				for(ia : p.initActions) {
    					var label = (new ActionsUmlGenerator().generateAction(ia)).toString
                    	label = label.replaceAll(" ", "_")
                    	dataList.add(label)    					
    				}
					stepDataMap.put(act.label.replaceAll(" ", "_"),dataList)
    			}
            }
        }
    }
    /* 
    def computeActionMap(Constraints model) {
        for(acts : model.actions) {
            for(act : acts.act) {
                if(!act.data.nullOrEmpty) {
                    if(act.data.head.instances) {
                        var dataList = new HashSet<String>
                        for(var i = 0; i < act.data.head.rows.size; i++) {
                            var idx = i + 1
                            dataList.add(act.name + "(" + idx + ")")
                            stepsMapping.put(act.name + "(" + idx + ")", act.name)
                        }
                        stepDataMap.put(act.name, dataList)
                    }
                }
            }
        }
        var importedConstraints = getConstraintsModel(model)
        if(importedConstraints !== null) {
            for(ic : importedConstraints) {
                for(acts : ic.actions) {
                    for(act : acts.act) {
                        if(!act.data.nullOrEmpty) {
                            if(act.data.head.instances) {
                                var dataList = new HashSet<String>
                                for(var i = 0; i < act.data.head.rows.size; i++) {
                                    var idx = i + 1
                                    dataList.add(act.name + "(" + idx + ")")
                                    stepsMapping.put(act.name + "(" + idx + ")", act.name)
                                }
                                stepDataMap.put(act.name, dataList)
                            }
                        }
                    }    
                }
            }
        }
        System.out.println("Steps Mapping for Action: " + stepsMapping)
        System.out.println("Steps Data Map: " + stepDataMap)
    }*/
    
    def computeActionToExpr(List<Actions> acts) {
    	for(a : acts) {
    		for(elm : a.act) {
    			var ename = elm.name
    			for(p : elm.actParam) {
    				for(ia : p.initActions) {
    					actionToExprMap.put(ename,(new ActionsUmlGenerator().generateAction(ia)).toString)
    				}
    			}
    		}
    	}
    }
    
    def generateStateMachine(Constraints model, Map<String, String> _stepsMapping, String path, String name, IFileSystemAccess2 fsa, boolean display, boolean printConstraints) 
    {
        symbol = INIT_CHAR
        fs = INIT_CHAR
        transformMap(_stepsMapping)
        computeActionMap(model)
        computeActionToExpr(model.actions)
        if(model.composition.isNullOrEmpty) {
            computeUnicodeMaps(model.templates)
            computeCompoundUnicodeMap
            var constraintSMInst = computeStateMachine(model.templates, path, name, fsa, display, printConstraints)
            mapContraintToAutomata.put(name,constraintSMInst)
        } else {
            for(elm : model.composition) {
                symbol = INIT_CHAR
                activityList = new HashSet<String>();
                unicodeMap = new HashMap<String,Character>();
                unusedUnicodeMap = new HashMap<String,Character>();
                sequenceDefMap = new HashMap<String,List<List<String>>>
                compoundUnicodeMap = new HashMap<Character,List<List<Character>>>                
                fs = INIT_CHAR;
                
                var templateList = new HashSet<Templates>
                for(t : elm.templates) templateList.add(t)
                computeUnicodeMaps(templateList.toList)
                computeCompoundUnicodeMap
                System.out.println(" > Constraint Name: " + elm.name)
                var constraintSMInst = computeStateMachine(templateList.toList, path, elm.name, fsa, display, printConstraints)
                mapContraintToAutomata.put(elm.name,constraintSMInst)                
            }
        }
        return mapContraintToAutomata
    }

    /* PreCondition
     *   unusedUnicodeMap : String - Character
     *   unicodeMap       : String - Character
     *   sequenceDefMap   : String - List<List<String>> 
     *   stepDataMap
     *   stepsMapping
     */
    def computeCompoundUnicodeMap() {
        for(elm : unicodeMap.keySet) {
            if(sequenceDefMap.containsKey(elm)) {
                var charListOfList = new ArrayList<List<Character>>
                var charList = new ArrayList<Character>
                for(act : sequenceDefMap.get(elm).head) {
                    if(unicodeMap.containsKey(act)) charList.add(unicodeMap.get(act))
                    else if(unusedUnicodeMap.containsKey(act)) charList.add(unusedUnicodeMap.get(act))
                    else { System.out.println("Element not present in unicode and unused unicode maps: " + act) }
                }
                charListOfList.add(charList)
                compoundUnicodeMap.put(unicodeMap.get(elm),charListOfList)
            } else {
                var charListOfList = new ArrayList<List<Character>>
                var charList = new ArrayList<Character>
                charList.add(unicodeMap.get(elm)) // assumption that all directly used symbols in constraints are present in this map.
                charListOfList.add(charList)
                if(getRelatedSteps(elm)!==null) {
                    var relatedSteps = getRelatedSteps(elm)
                    for(st : relatedSteps) {
                        // note symbols were generated earlier and added to unused unicode map. see data support comment below.
                        charList = new ArrayList<Character>
                        if(unusedUnicodeMap.containsKey(st)) {
                            charList.add(unusedUnicodeMap.get(st))
                            charListOfList.add(charList)
                        } else if(unicodeMap.containsKey(st)) {
                            charList.add(unicodeMap.get(st))
                            charListOfList.add(charList)
                        } else { System.out.println("Element not present in unicode and unused unicode maps: " + st) }
                    }
                }
                compoundUnicodeMap.put(unicodeMap.get(elm),charListOfList)
            }
        }
        for(elm : unusedUnicodeMap.keySet) {
            if(!compoundUnicodeMap.containsKey(unusedUnicodeMap.get(elm))) {
                var charListOfList = new ArrayList<List<Character>>
                var charList = new ArrayList<Character>
                charList.add(unusedUnicodeMap.get(elm))
                charListOfList.add(charList)
                // added DB to handle steps without data relation to all other steps
                if(getRelatedSteps(elm)!==null) {
                    var relatedSteps = getRelatedSteps(elm)
                    for(st : relatedSteps) {
                        charList = new ArrayList<Character>
                        if(unusedUnicodeMap.containsKey(st)) {
                            charList.add(unusedUnicodeMap.get(st))
                            charListOfList.add(charList)
                        }
                    }
                }
                compoundUnicodeMap.put(unusedUnicodeMap.get(elm), charListOfList)
            }
        }
        //displayComputedMaps
    }
    
    // Given a step, get other related step instantiations with different data
    def getRelatedSteps(String step) {
        // var relatedSteps = new HashSet<String>
        if(stepsMapping.get(step)!==null) { 
            /*for(elm : stepDataMap.get(stepsMapping.get(step))) 
                if(!elm.equals(step)) 
                    relatedSteps.add(elm)
            return relatedSteps*/ // we do not want to map steps with different data!
        } else {
            // if step wo data // Note mapping only exists if it is a step WO data
            if(stepDataMap.containsKey(step)) return stepDataMap.get(step)
        }
        return new HashSet<String>
    }
    
    def displayComputedMaps() {
        System.out.println("UNICODE MAP")
        for(elm : unicodeMap.keySet)
            System.out.println("    Key: " + elm + "  Value: "+ unicodeMap.get(elm) as int)
        System.out.println("UnUSed UNICODE MAP")
        for(elm : unusedUnicodeMap.keySet)
            System.out.println("    Key: " + elm + "  Value: "+ unusedUnicodeMap.get(elm))
        System.out.println("Sequence Def MAP")
        for(elm : sequenceDefMap.keySet)
            System.out.println("    Key: " + elm + "  Value: "+ sequenceDefMap.get(elm))
        System.out.println("Compound UNICODE MAP")
        for(elm : compoundUnicodeMap.keySet)
            System.out.println("    Key: " + elm as int + "  Value: "+ compoundUnicodeMap.get(elm))
    }

    def getAutomatonForStrings(List<String> strList) {
        // System.out.println(" DEBUG STRLIST: \r\n" +strList)
        var _a_ = new ArrayList<Automaton>();
        for(String str : strList) {
            // System.out.println("DEBUG REGEX: " + str);
            var r = new RegExp(str);
            _a_.add(r.toAutomaton());
        }
        return _a_
    }
    
    def getRelationType(boolean either) {
        if(either) return RelationType.OR
        else return RelationType.AND
    }
    
    def computeConstraintText(ArrayList<String> strList, String constStr) {
        strList.add(constStr)
        return strList
    }
    
    def computeStateMachine(List<Templates> templateList, String path, String name, IFileSystemAccess2 fsa, boolean display, boolean printConstraints) 
    { 
       var sem = new Semantics
       var List<Automaton> automataList = new ArrayList<Automaton>();
       var listOfRegexes = new ArrayList<String>
       
       var text = new ArrayList<String>
       var existentialText = new ArrayList<String>
       var futureText = new ArrayList<String>
       var pastText = new ArrayList<String>
       var pastFutureText = new ArrayList<String>
       var choiceText = new ArrayList<String>
       
       var dot = new String
       var highlightedKeywords = new HashSet<String>
       var _highlightedKeywords = new ArrayList<String>
       
       for(templates : templateList) {
           // System.out.println("DEBUG " + templates.name)
            for(elm : templates.type) {
                if(elm instanceof Choice) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof SimpleChoice) {
                            var refACharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getSimpleChoice(refACharList);
                            listOfRegexes.addAll(strList)                         
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getSimpleChoiceText(getRefName(elmInst.refA)))
                            choiceText.add(getSimpleChoiceText(getRefName(elmInst.refA)))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                        }
                        if(elmInst instanceof ExclusiveChoice) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getExclusiveChoice(refACharList, refBCharList);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getExclusiveChoiceText(getRefName(elmInst.refA), getRefName(elmInst.refB)))
                            choiceText.add(getExclusiveChoiceText(getRefName(elmInst.refA), getRefName(elmInst.refB)))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                        }
                    }
                }
                if(elm instanceof Existential) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof AtLeast) {
                            var refACharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getAtLeast(refACharList,elmInst.num);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getAtLeastText(getRefName(elmInst.ref),elmInst.num))
                            existentialText.add(getAtLeastText(getRefName(elmInst.ref),elmInst.num))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.ref))      
                        }
                        if(elmInst instanceof AtMost) {
                            var refACharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getAtMost(refACharList,elmInst.num);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getAtMostText(getRefName(elmInst.ref),elmInst.num))
                            existentialText.add(getAtMostText(getRefName(elmInst.ref),elmInst.num))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.ref))
                        }
                        if(elmInst instanceof Exact) {
                            var refACharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getExactOccurence(refACharList,elmInst.num,elmInst.consecutively);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getExactText(getRefName(elmInst.ref),elmInst.num))
                            existentialText.add(getExactText(getRefName(elmInst.ref),elmInst.num))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.ref))
                        }
                        if(elmInst instanceof Init) {
                            var refACharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getInit(refACharList);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getInitText(getRefName(elmInst.ref)))
                            existentialText.add(getInitText(getRefName(elmInst.ref)))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.ref))
                        }
                        if(elmInst instanceof End) { 
                            var refACharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getEnd(refACharList);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getEndText(getRefName(elmInst.ref)))
                            existentialText.add(getEndText(getRefName(elmInst.ref)))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.ref))
                        }
                    }
                }
                if(elm instanceof Future) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof Response) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getResponse(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), elmInst.not);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getResponseText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB, elmInst.not))
                            futureText.add(getResponseText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB, elmInst.not))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))                            
                        }
                        if(elmInst instanceof AlternateResponse) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            var refCCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            for(elmC : getRefName(elmInst.refC)) refCCharList.add(unicodeMap.get(elmC))
                            var List<String> strList = sem.getAlternateResponse(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), 
                                                                       refCCharList, getRelationType(elmInst.eitherC), !elmInst.not);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getAlternateResponseText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB, getRefName(elmInst.refC), elmInst.eitherC, elmInst.not))
                            futureText.add(getAlternateResponseText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB, getRefName(elmInst.refC), elmInst.eitherC, elmInst.not))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refC))
                        }
                        if(elmInst instanceof ChainResponse) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getChainResponse(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), elmInst.not);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getChainResponseText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB, elmInst.not))
                            futureText.add(getChainResponseText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB, elmInst.not))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                        }
                    }
                }
                if(elm instanceof Past) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof Precedence) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getPrecedence(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), elmInst.not);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getPrecedenceText(getRefName(elmInst.refA), elmInst.eitherA, 
                                    getRefName(elmInst.refB), elmInst.eitherB, elmInst.not))
                            pastText.add(getPrecedenceText(getRefName(elmInst.refA), elmInst.eitherA, 
                                    getRefName(elmInst.refB), elmInst.eitherB, elmInst.not))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                        }
                        if(elmInst instanceof AlternatePrecedence) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            var refCCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            for(elmC : getRefName(elmInst.refC)) refCCharList.add(unicodeMap.get(elmC))
                            var List<String> strList = sem.getAlternatePrecedence(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), 
                                                                       refCCharList, getRelationType(elmInst.eitherC), !elmInst.not);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getAlternatePrecedenceText(getRefName(elmInst.refA), elmInst.eitherA, 
                                        getRefName(elmInst.refB), elmInst.eitherB, 
                                        getRefName(elmInst.refC), elmInst.eitherC, elmInst.not))
                            pastText.add(getAlternatePrecedenceText(getRefName(elmInst.refA), elmInst.eitherA, 
                                        getRefName(elmInst.refB), elmInst.eitherB, 
                                        getRefName(elmInst.refC), elmInst.eitherC, elmInst.not))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refC))
                        }
                        if(elmInst instanceof ChainPrecedence) { 
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getChainPrecedence(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), elmInst.not);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList))
                            text = computeConstraintText(text, getChainPrecedenceText(getRefName(elmInst.refA), elmInst.eitherA, 
                                    getRefName(elmInst.refB), elmInst.eitherB, elmInst.not))
                            pastText.add(getChainPrecedenceText(getRefName(elmInst.refA), elmInst.eitherA, 
                                    getRefName(elmInst.refB), elmInst.eitherB, elmInst.not))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                        }
                    }
                }
                if(elm instanceof Dependencies) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof RespondedExistence) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getRespondedExistence(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), false);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList))
                            text = computeConstraintText(text, getRespondedExistenceText(getRefName(elmInst.refA), elmInst.eitherA, 
                                    getRefName(elmInst.refB), elmInst.eitherB))
                            pastFutureText.add(getRespondedExistenceText(getRefName(elmInst.refA), elmInst.eitherA, 
                                    getRefName(elmInst.refB), elmInst.eitherB))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                        }
                        if(elmInst instanceof CoExistance) {
                            var refACharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getCoExistence(refACharList,false);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList))
                            text = computeConstraintText(text, getCoExistanceText(getRefName(elmInst.refA)))
                            pastFutureText.add(getCoExistanceText(getRefName(elmInst.refA)))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))    
                        }
                        if(elmInst instanceof Succession) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getSuccession(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), false);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList)); 
                            text = computeConstraintText(text, getSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                    getRefName(elmInst.refB), elmInst.eitherB))
                            pastFutureText.add(getSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                    getRefName(elmInst.refB), elmInst.eitherB))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))                           
                        }
                        if(elmInst instanceof AlternateSuccession) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            var refCCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            for(elmC : getRefName(elmInst.refC)) refCCharList.add(unicodeMap.get(elmC))
                            var List<String> strList = sem.getAlternateSuccession(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), 
                                                                       refCCharList, getRelationType(elmInst.eitherC), !elmInst.negation); // false                          
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getAlternateSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB, getRefName(elmInst.refC), elmInst.eitherC, elmInst.negation))
                            pastFutureText.add(getAlternateSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB, getRefName(elmInst.refC), elmInst.eitherC, elmInst.negation))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refC))
                        }
                        if(elmInst instanceof ChainSuccession) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getChainSuccession(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), false);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList))
                            text = computeConstraintText(text, getChainSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB))
                            pastFutureText.add(getChainSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))
                        }
                        if(elmInst instanceof NotSuccession) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getSuccession(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), true);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getNotSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB))
                            pastFutureText.add(getNotSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))    
                        }
                        if(elmInst instanceof NotCoExistance) {
                            var refACharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getCoExistence(refACharList,true);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getNotCoExistanceText(getRefName(elmInst.refA)))
                            pastFutureText.add(getNotCoExistanceText(getRefName(elmInst.refA)))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                        }
                        if(elmInst instanceof NotChainSuccession) {
                            var refACharList = new ArrayList<Character>
                            var refBCharList = new ArrayList<Character>
                            for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getChainSuccession(refACharList, getRelationType(elmInst.eitherA), 
                                                                       refBCharList, getRelationType(elmInst.eitherB), true);                           
                            listOfRegexes.addAll(strList)
                            automataList.addAll(getAutomatonForStrings(strList));
                            text = computeConstraintText(text, getNotChainSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB))
                            pastFutureText.add(getNotChainSuccessionText(getRefName(elmInst.refA), elmInst.eitherA, 
                                getRefName(elmInst.refB), elmInst.eitherB))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refA))
                            highlightedKeywords.addAll(getRefNameWOUnderScore(elmInst.refB))    
                        }

                    }
                }
            }
        }
        
        var String regex = "[";
        for(String act : unicodeMap.keySet()) {
            regex += unicodeMap.get(act);
        }
        fs = symbol;
        regex += symbol + "]*";
        listOfRegexes.add(regex)
        
        var RegExp r = new RegExp(regex);
        automataList.add(r.toAutomaton());
        
        unicodeMap.put("ANY", symbol)
        
        var lst = new ArrayList<Character>
        var lstOfList = new ArrayList<List<Character>>
        lst.add(symbol) lstOfList.add(lst)
        compoundUnicodeMap.put(symbol, lstOfList)
        
        for(elm : highlightedKeywords) _highlightedKeywords.add(elm)
        
        var constraintSMInst = new ConstraintStateMachine(name, unicodeMap, 
                                                                stepDataMap, 
                                                                stepsMapping, 
                                                                unusedUnicodeMap, 
                                                                sequenceDefMap, 
                                                                compoundUnicodeMap,
                                                                listOfRegexes, 
                                                                actionToExprMap,
                                                                automataList, fs,
                                                                text, _highlightedKeywords)
        constraintSMInst.setTemplateText(choiceText, pastText, futureText, pastFutureText, existentialText)
        dot = constraintSMInst.computeAutomaton(path, fsa, display, printConstraints)
        constraintSMInst.setDotText(dot)
        
        return constraintSMInst
    }
    
    // Note that this function also populates the sequenceDefMap
    def computeUnicodeMaps(List<Templates> templateList) {
        for(templates : templateList) {
            for(elm : templates.type) {
                if(elm instanceof Choice) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof SimpleChoice) addActivityToMap(elmInst.refA)
                        if(elmInst instanceof ExclusiveChoice) addActivityToMap(elmInst.refA,elmInst.refB)
                    }
                }
                if(elm instanceof Existential) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof AtLeast) addActivityToMap(elmInst.ref)
                        if(elmInst instanceof Exact) addActivityToMap(elmInst.ref)
                        if(elmInst instanceof AtMost) addActivityToMap(elmInst.ref)
                        if(elmInst instanceof Init) addActivityToMap(elmInst.ref)
                        if(elmInst instanceof End) addActivityToMap(elmInst.ref)
                    }
                }
                if(elm instanceof Future) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof Response) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof AlternateResponse) addActivityToMap(elmInst.refA,elmInst.refB,elmInst.refC)
                        if(elmInst instanceof ChainResponse) addActivityToMap(elmInst.refA,elmInst.refB)
                    }
                }
                if(elm instanceof Past) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof Precedence) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof AlternatePrecedence) addActivityToMap(elmInst.refA,elmInst.refB,elmInst.refC)
                        if(elmInst instanceof ChainPrecedence) addActivityToMap(elmInst.refA,elmInst.refB)
                    }
                }
                if(elm instanceof Dependencies) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof RespondedExistence) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof CoExistance) addActivityToMap(elmInst.refA)
                        if(elmInst instanceof Succession) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof AlternateSuccession) addActivityToMap(elmInst.refA,elmInst.refB,elmInst.refC)
                        if(elmInst instanceof ChainSuccession) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof NotSuccession) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof NotCoExistance) addActivityToMap(elmInst.refA)
                        if(elmInst instanceof NotChainSuccession) addActivityToMap(elmInst.refA,elmInst.refB)
                    }
                }
            }
        }
        // sequenceDefMap is populated for this list of constraints
        // construct compound character map.
        // iterate over unicode map: string - character
        // if elm is sequence-def, check in sequenceDefMap the list of actions to see if they are present in unicode map, if not 
    }

    def addActivityToMap(List<Ref> elmA) {
        var refAName = getRefName(elmA)
        for(elmAName : refAName) {
            activityList.add(elmAName)
            addToUnicodeMap(elmAName)
        }       
    }

    def addActivityToMap(List<Ref> elmA, List<Ref> elmB) {
        var refAName = getRefName(elmA)
        var refBName = getRefName(elmB)
        for(elmAName : refAName) {
            activityList.add(elmAName)
            addToUnicodeMap(elmAName)
        }
        for(elmBName : refBName) {
            activityList.add(elmBName)
            addToUnicodeMap(elmBName)
        }
    }
 
     def addActivityToMap(List<Ref> elmA, List<Ref> elmB, List<Ref> elmC) {
        var refAName = getRefName(elmA)
        var refBName = getRefName(elmB)
        var refCName = getRefName(elmC)
        for(elmAName : refAName) {
            activityList.add(elmAName)
            addToUnicodeMap(elmAName)
        }
        for(elmBName : refBName) {
            activityList.add(elmBName)
            addToUnicodeMap(elmBName)
        }
        for(elmCName : refCName) {
            activityList.add(elmCName)
            addToUnicodeMap(elmCName)
        }
    }
    
    def getRefName(List<Ref> refList){
        var refName = new ArrayList<String>
        for(ref : refList)  
            refName.add(getRefName(ref))            
        return refName
    }
    
    def getRefNameWOUnderScore(List<Ref> refList){
        var refName = new ArrayList<String>
        for(ref : refList) 
        {
            if(ref instanceof RefStepSequence) 
            {
                if(sequenceDefMap.containsKey(ref.seq.name)) {
                    var actList = getRefActionList(ref)
                    for(act : actList) for(a : act) refName.add(a.replaceAll("_", " ").trim)
                } 
                else println("    > ERROR: Sequence Name not found in Sequence Def Map! " + ref.seq.name)
            } 
            else if(ref instanceof RefActSequence) 
            {
                if(sequenceDefMap.containsKey(ref.seq.name)) {
                    var actList = getRefActionList(ref)
                    for(act : actList) for(a : act) refName.add(a.replaceAll("_", " ").trim)
                } 
                else println("    > ERROR: Sequence Name not found in Sequence Def Map! " + ref.seq.name)
            }
            else refName.add(getRefName(ref).replaceAll("_", " ").trim)
        }
        return refName
    }
    
    // Note if the ref is a sequence then 
    // populate the sequenceDefMap with list of list of actions
    def getRefName(Ref ref){
        var refName = new String
        if(ref instanceof RefStep) {
            refName = ref.step.name
            // data support: finding all related steps with different data
            var relatedSteps = getRelatedSteps(refName)
            for(elm : relatedSteps)
                addToUnusedUnicodeMap(elm)
        }
        if(ref instanceof RefAction) {
            refName = getActionLabel(ref.act)
            // data support: finding all related steps with different data            
            var relatedSteps = getRelatedSteps(refName) // for action without data instances
            for(elm : relatedSteps)
                addToUnusedUnicodeMap(elm)
        }
        if(ref instanceof RefStepSequence) { 
            refName = ref.seq.name
            sequenceDefMap.put(ref.seq.name, getRefActionList(ref))
        }
        if(ref instanceof RefActSequence) {
            refName = ref.seq.name
            sequenceDefMap.put(ref.seq.name, getRefActionList(ref))
        }
        return refName
    }
    
    //use the label instead of name, add "_" and replace data
    def getActionLabel(Act ref){
    	var label = ref.act.label
    	if (ref.dataRow.size > 0){
    		for(d : ref.dataRow){
	    		if (label.contains(d.name)){
	    			label = label.replaceAll("<"+d.name+">", d.value)
	    		}
    		}
    	}
    	label = label.replaceAll(" ", "_")
    	return label
    }
    
    // construct list of list of actions for each sequence def
    def getRefActionList(RefStepSequence refSeq) {
        var lstOfList = new ArrayList<List<String>>
        var lst = new ArrayList<String>
        for(act : refSeq.seq.stepList) {
            lst.add(act.name)
            addToUnusedUnicodeMap(act.name)
            // data support: finding all related steps relating to this step WO data // experimental DB TODO check
            var relatedSteps = getRelatedSteps(act.name)
            for(elm : relatedSteps)
                addToUnusedUnicodeMap(elm)
        }
        lstOfList.add(lst)
        return lstOfList
    }
    
    def getRefActionList(RefActSequence actSeq) {
        var lstOfList = new ArrayList<List<String>>
        var lst = new ArrayList<String>
        for(act : actSeq.seq.actList) {
            lst.add(getActionLabel(act))
            addToUnusedUnicodeMap(getActionLabel(act))
            // data support: finding all related steps relating to this step WO data // experimental DB TODO check
            var relatedSteps = getRelatedSteps(getActionLabel(act))
            for(elm : relatedSteps)
                addToUnusedUnicodeMap(elm)
        }
        lstOfList.add(lst)
        return lstOfList
    }
    
    // if already present in unused unicode map then use that, otherwise add to unicode map with new symbol
    def addToUnicodeMap(String elm) {
        if(unusedUnicodeMap.containsKey(elm)) {
            unicodeMap.put(elm,unusedUnicodeMap.get(elm))    
        }
        if(!unicodeMap.containsKey(elm)) {
            unicodeMap.put(elm, symbol)
            // symbol++
            symbol = getNextSymbol(symbol)
        }
    }
    
    // gets added only if not in unicode map
    def addToUnusedUnicodeMap(String elm) {
        if(!unicodeMap.containsKey(elm)) {
            if(!unusedUnicodeMap.containsKey(elm)) {            
                unusedUnicodeMap.put(elm, symbol)
                // symbol++
                symbol = getNextSymbol(symbol)
            }
        }
    }
    
    def getListText(List<String> strList) {
        var str = new String
        for(var idx = 0 ; idx < strList.size; idx++) { 
            if(idx < strList.size-1) str += strList.get(idx).replaceAll("_", " ").trim + ", " 
            else str += strList.get(idx).replaceAll("_", " ").trim
        }
        return str
    }
    
    def getExclusiveChoiceText(List<String> refA, List<String> refB) {
        return getListText(refA) + " or " + getListText(refB) + " eventually-occur, but-never-together"
    }
    
    def getSimpleChoiceText(List<String> refA) {
        return getListText(refA) + " eventually-occur"
    }
    
    def getNotChainSuccessionText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB) {
        return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " then " + getEitherText(refB.size,eitherB) + getListText(refB) + " must-not immediately-follow, and vice-versa" //!<> 
    }
    
    def getNotCoExistanceText(List<String> refA) {
        return getListText(refA) + " do-not-occur-together" //"!- " +
    }
    
    def getNotSuccessionText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB) {
        return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " then " + getEitherText(refB.size,eitherB) + getListText(refB) + " must-not eventually-follow, and vice-versa" //!<-->
    }
    
    def getChainSuccessionText(List<String> refA, boolean eitherA, List<String> refB,boolean eitherB) {
        return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " then " + getEitherText(refA.size,eitherB) + getListText(refB) + " must-immediately-follow, and vice-versa" //<> 
    }
    
    def getAlternateSuccessionText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB, List<String> refC, boolean eitherC, boolean not) {
        if(!not) "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " then " + getEitherText(refB.size,eitherB) + getListText(refB) + " must-follow, and vice-versa, with " + getEitherText(refC.size,eitherC) + getListText(refC) + " in-between" //<!>
        else return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " then " + getEitherText(refB.size,eitherB) + getListText(refB) + " must-follow, and vice-versa, with no " + getEitherText(refC.size,eitherC) + getListText(refC) + " in-between" //<!> 
    }
    
    def getSuccessionText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB) {
        return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " then " + getEitherText(refB.size,eitherB) + getListText(refB) + " must-eventually-follow, and vice-versa" //<--> 
    }
    
    def getCoExistanceText(List<String> refA) {
        return getListText(refA) + " occur-together" // "- " + 
    }
    
    def getRespondedExistenceText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB) {
        return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " occurs then " + getEitherText(refB.size,eitherB) + getListText(refB) + " occurs-as-well" // -|- 
    }
       
    def getChainPrecedenceText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB, boolean not) {
        if(!not) return "whenever " + getEitherText(refB.size,eitherB) + getListText(refB) + " occurs then " + getEitherText(refA.size,eitherA) + getListText(refA) + " must have-occurred-immediately-before" //< 
        else return "whenever " + getEitherText(refB.size,eitherB) + getListText(refB) + " occurs then " + getEitherText(refA.size,eitherA) + getListText(refA) + " must not have-occurred-immediately-before" //< 
    }
    
    def getChainResponseText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB, boolean not) {
        if(!not) return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " occurs then " + getEitherText(refB.size,eitherB) + getListText(refB) + " must immediately-follow" //> 
        else return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " occurs then " + getEitherText(refB.size,eitherB) + getListText(refB) + " must not immediately-follow" //> 
    }
    
    def getAlternateResponseText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB, List<String> refC, boolean eitherC, boolean not) {
        if(!not) return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " occurs then " + 
                                getEitherText(refB.size,eitherB) + getListText(refB) + " must-follow, with " + 
                                getEitherText(refC.size,eitherC) + getListText(refC) + " in-between"
        else return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " occurs then " + 
                            getEitherText(refB.size,eitherB) + getListText(refB) + " must-follow, with no " + 
                            getEitherText(refC.size,eitherC) + getListText(refC) + " in-between" //!> 
    }
    
    def getAlternatePrecedenceText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB, List<String> refC, boolean eitherC, boolean not) {
        if(!not) return "whenever " + getEitherText(refB.size,eitherB) + getListText(refB) + " occurs then " + getEitherText(refA.size,eitherA) + getListText(refA) + " must-have-occurred-before, with " + getEitherText(refC.size,eitherC) + getListText(refC) + " in-between" //<! 
        else return "whenever " + getEitherText(refB.size,eitherB) + getListText(refB) + " occurs then " + getEitherText(refA.size,eitherA) + getListText(refA) + " must-have-occurred-before, with no " + getEitherText(refC.size,eitherC) + getListText(refC) + " in-between"
    }
    
    def getResponseText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB, boolean not) {
        if(!not) return "if " + getEitherText(refA.size,eitherA) + getListText(refA) + " occurs then " + getEitherText(refB.size,eitherB)  + getListText(refB) + " must eventually-follow" //-> 
        else return "if " + getEitherText(refA.size,eitherA)  + getListText(refA) + " occurs then " + getEitherText(refA.size,eitherA) + getListText(refB) + " must not eventually-follow"
    }
    
    def getPrecedenceText(List<String> refA, boolean eitherA, List<String> refB, boolean eitherB, boolean not) {
        if(!not) return "whenever " + getEitherText(refB.size,eitherB) + getListText(refB) + " occurs then " + getEitherText(refA.size,eitherA) + getListText(refA) + " must have-occurred-before" //<- 
        else return "whenever " + getEitherText(refB.size,eitherB) + getListText(refB) + " occurs then " + getEitherText(refA.size,eitherA) + getListText(refA) + " must not have-occurred-before"
    }
    
    def getEndText(List<String> refA) {
        return "" + getListText(refA) + " occurs-last"
    }
    
    def getInitText(List<String> refA) {
        return "" + getListText(refA) + " occurs-first"
    }
    
    def getAtMostText(List<String> refA, int num) {
        return "" + getListText(refA) + " occurs-at-most 1 times"
    }
    
    def getExactText(List<String> refA, int num) {
        return "" + getListText(refA) + " occurs-exactly 1 times"
    }
    
    def getAtLeastText(List<String> refA, int num) {
        return "" + getListText(refA) + " occurs-at-least 1 times"
    }
    
    def getEitherText(int size, boolean value) { 
        if(size > 1) { if(value) return "either " } 
        return new String
    }
    
    def getNextSymbol(Character c) {
        var currChar = c
        var Set<Character> listOfForbiddenChars = #{'/', '\\', '~', '?', '|', '[', ']', '(', ')', '{', '}', '#', '@', '&', '^', '+', '*', '!', '<', '>', '.', '-', '_', '`', 0x0001 as char, 0x0002 as char, 0x0004 as char, 0x0008 as char, 0x0010 as char, 0x0020 as char, 0xffff as char, 0x0000 as char}
        currChar++
        while(listOfForbiddenChars.contains(currChar)) currChar++
        return currChar
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