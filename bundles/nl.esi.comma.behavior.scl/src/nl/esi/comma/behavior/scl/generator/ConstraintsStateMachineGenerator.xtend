package nl.esi.comma.behavior.scl.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set

import nl.esi.comma.behavior.scl.scl.Templates
import nl.esi.comma.behavior.scl.scl.Existential
import nl.esi.comma.behavior.scl.scl.RespondedExistence
import nl.esi.comma.behavior.scl.scl.Response
import nl.esi.comma.behavior.scl.scl.AlternateResponse
import nl.esi.comma.behavior.scl.scl.ChainResponse
import nl.esi.comma.behavior.scl.scl.Precedence
import nl.esi.comma.behavior.scl.scl.AlternatePrecedence
import nl.esi.comma.behavior.scl.scl.ChainPrecedence
import nl.esi.comma.behavior.scl.scl.CoExistance
import nl.esi.comma.behavior.scl.scl.Succession
import nl.esi.comma.behavior.scl.scl.AlternateSuccession
import nl.esi.comma.behavior.scl.scl.ChainSuccession
import nl.esi.comma.behavior.scl.scl.NotSuccession
import nl.esi.comma.behavior.scl.scl.NotCoExistance
import nl.esi.comma.behavior.scl.scl.NotChainSuccession
import nl.esi.comma.behavior.scl.scl.Ref
import nl.esi.comma.behavior.scl.scl.RefStep
import nl.esi.comma.behavior.scl.scl.RefSequence
import nl.esi.comma.behavior.scl.scl.Init
import nl.esi.comma.behavior.scl.scl.End
import nl.esi.comma.behavior.scl.scl.Model
import nl.esi.comma.behavior.scl.scl.Choice
import nl.esi.comma.behavior.scl.scl.SimpleChoice
import nl.esi.comma.behavior.scl.scl.ExclusiveChoice
import nl.esi.comma.behavior.scl.scl.AtLeast
import nl.esi.comma.behavior.scl.scl.AtMost
import nl.esi.comma.behavior.scl.scl.Exact
import nl.esi.comma.behavior.scl.scl.Future
import nl.esi.comma.behavior.scl.scl.Past
import nl.esi.comma.behavior.scl.scl.Dependencies
import dk.brics.automaton.Automaton
import dk.brics.automaton.RegExp
import nl.esi.comma.automata.RelationType
import nl.esi.comma.automata.Semantics
import nl.esi.comma.behavior.scl.scl.Actions
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import nl.esi.comma.actions.generator.plantuml.ActionsUmlGenerator

class ConstraintsStateMachineGenerator 
{
    var Set<String> activityList = new HashSet<String>();
    var Map<String,Character> unicodeMap = new HashMap<String,Character>(); // global for each constraint file
	var Map<String,String> actionToExprMap = new HashMap<String,String>(); // global for each constraint file
    var char symbol = 'a'
    char fs = '0';
    var Map<String,ConstraintStateMachine> mapContraintToAutomata = new HashMap<String,ConstraintStateMachine>
    
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
    
    def generateStateMachine(Model model, String path, String name) 
    {
    	computeActionToExpr(model.actions)
        if(model.composition.isNullOrEmpty) {
            computeStepLabels(model.templates)
            // generate state machine model for elm.name and save file with that name
            // precondition: unicodeMap is ready            
            var constraintSMInst = computeStateMachine(model.templates, path, name)
            mapContraintToAutomata.put(name,constraintSMInst)
            
        } else {
            for(elm : model.composition) {
                symbol = 'a'
                activityList = new HashSet<String>();
                unicodeMap = new HashMap<String,Character>();
                fs = '0';
                var templateList = new HashSet<Templates>
                for(t : elm.templates) templateList.add(t)
                computeStepLabels(templateList.toList)
               
                // generate state machine model for elm.name and save file with that name
                // precondition: unicodeMap is ready                
                var constraintSMInst = computeStateMachine(templateList.toList, path, elm.name)
                mapContraintToAutomata.put(elm.name,constraintSMInst)                
            }
        }
        return mapContraintToAutomata
    }
    
    def getAutomatonForStrings(List<String> strList) {
    	var _a_ = new ArrayList<Automaton>();
		for(String str : strList) {
			System.out.println(str);
			var r = new RegExp(str);
			_a_.add(r.toAutomaton());
		}
		return _a_
    }
    
    def getRelationType(boolean either) {
    	if(either) return RelationType.OR
    	else return RelationType.AND
    }
    
    def computeStateMachine(List<Templates> templateList, String path, String name) 
    { 
       var sem = new Semantics
       var debug = false
       var List<Automaton> automataList = new ArrayList<Automaton>();
       for(templates : templateList) {
            for(elm : templates.type) {
            	if(elm instanceof Choice) {
            		for(elmInst : elm.type) {
            			if(elmInst instanceof SimpleChoice) {
                         	var refACharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            var List<String> strList = sem.getSimpleChoice(refACharList);                           
                            automataList.addAll(getAutomatonForStrings(strList));            				
            			}
            			if(elmInst instanceof ExclusiveChoice) {
            				var refACharList = new ArrayList<Character>
            				var refBCharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getExclusiveChoice(refACharList, refBCharList);                           
                            automataList.addAll(getAutomatonForStrings(strList));
            			}
            		}
            	}
                if(elm instanceof Existential) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof AtLeast) {
                        	var refACharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                        	var List<String> strList = sem.getAtLeast(refACharList,elmInst.num);                           
                            automataList.addAll(getAutomatonForStrings(strList));
                        }
                        if(elmInst instanceof AtMost) {
                        	var refACharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                        	var List<String> strList = sem.getAtMost(refACharList,elmInst.num);                           
                            automataList.addAll(getAutomatonForStrings(strList));
                        }
                        if(elmInst instanceof Exact) {
                        	var refACharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                        	var List<String> strList = sem.getExactOccurence(refACharList,elmInst.num,elmInst.consecutively);                           
                            automataList.addAll(getAutomatonForStrings(strList));
                        }
                        if(elmInst instanceof Init) {
                        	var refACharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                        	var List<String> strList = sem.getInit(refACharList);                           
                            automataList.addAll(getAutomatonForStrings(strList));
                        }
                        if(elmInst instanceof End) { 
                        	var refACharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.ref)) refACharList.add(unicodeMap.get(elmA))
                        	var List<String> strList = sem.getEnd(refACharList);                           
                            automataList.addAll(getAutomatonForStrings(strList));
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
                            automataList.addAll(getAutomatonForStrings(strList));   
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
                            										   refCCharList, getRelationType(elmInst.eitherC), elmInst.not);                           
                            automataList.addAll(getAutomatonForStrings(strList));    
                        }
                        if(elmInst instanceof ChainResponse) {
            				var refACharList = new ArrayList<Character>
            				var refBCharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getChainResponse(refACharList, getRelationType(elmInst.eitherA), 
                            										   refBCharList, getRelationType(elmInst.eitherB), elmInst.not);                           
                            automataList.addAll(getAutomatonForStrings(strList));     
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
                            automataList.addAll(getAutomatonForStrings(strList));   
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
                            										   refCCharList, getRelationType(elmInst.eitherC), elmInst.not);                           
                            automataList.addAll(getAutomatonForStrings(strList));   
                        }
                        if(elmInst instanceof ChainPrecedence) { 
                        	var refACharList = new ArrayList<Character>
            				var refBCharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getChainPrecedence(refACharList, getRelationType(elmInst.eitherA), 
                            										   refBCharList, getRelationType(elmInst.eitherB), elmInst.not);                           
                            automataList.addAll(getAutomatonForStrings(strList));          
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
                            automataList.addAll(getAutomatonForStrings(strList));     
                        }
                        if(elmInst instanceof CoExistance) {
                        	var refACharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                        	var List<String> strList = sem.getCoExistence(refACharList,false);                           
                            automataList.addAll(getAutomatonForStrings(strList));                     
                        }
                        if(elmInst instanceof Succession) {
                        	var refACharList = new ArrayList<Character>
            				var refBCharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getSuccession(refACharList, getRelationType(elmInst.eitherA), 
                            										   refBCharList, getRelationType(elmInst.eitherB), false);                           
                            automataList.addAll(getAutomatonForStrings(strList));                            
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
                            										   refCCharList, getRelationType(elmInst.eitherC), false);                           
                            automataList.addAll(getAutomatonForStrings(strList));                                  
                        }
                        if(elmInst instanceof ChainSuccession) {
                        	var refACharList = new ArrayList<Character>
            				var refBCharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getChainSuccession(refACharList, getRelationType(elmInst.eitherA), 
                            										   refBCharList, getRelationType(elmInst.eitherB), false);                           
                            automataList.addAll(getAutomatonForStrings(strList));  
                        }
                        if(elmInst instanceof NotSuccession) {
                        	var refACharList = new ArrayList<Character>
            				var refBCharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getSuccession(refACharList, getRelationType(elmInst.eitherA), 
                            										   refBCharList, getRelationType(elmInst.eitherB), true);                           
                            automataList.addAll(getAutomatonForStrings(strList));    
                        }
                        if(elmInst instanceof NotCoExistance) {
                        	var refACharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                        	var List<String> strList = sem.getCoExistence(refACharList,true);                           
                            automataList.addAll(getAutomatonForStrings(strList));  
                        }
                        if(elmInst instanceof NotChainSuccession) {
                        	var refACharList = new ArrayList<Character>
            				var refBCharList = new ArrayList<Character>
                         	for(elmA : getRefName(elmInst.refA)) refACharList.add(unicodeMap.get(elmA))
                            for(elmB : getRefName(elmInst.refB)) refBCharList.add(unicodeMap.get(elmB))
                            var List<String> strList = sem.getChainSuccession(refACharList, getRelationType(elmInst.eitherA), 
                            										   refBCharList, getRelationType(elmInst.eitherB), true);                           
                            automataList.addAll(getAutomatonForStrings(strList));     
                        }

                    }
                }
            }
        }
        var String regex = "[";
        for(String act : unicodeMap.keySet()) {
            regex += unicodeMap.get(act);
        }
        fs = symbol; // extra symbol : for skip - used by other functionality: conformance checking
        regex += symbol + "]*";
        var RegExp r = new RegExp(regex);
        automataList.add(r.toAutomaton());
        unicodeMap.put("ANY", symbol)
        
        var constraintSMInst = new ConstraintStateMachine(name, unicodeMap, actionToExprMap, automataList)
        constraintSMInst.computeAutomaton(path)
        
        return constraintSMInst
    }
    
        /*var Automaton fa = new Automaton()
        if(automataList.size() > 1) {
            // final Automaton Construction 
            fa = automataList.get(0);
            for(var i = 1; i < automataList.size(); i++) {
                fa = fa.intersection(automataList.get(i));
            }
            // Visualize final automaton
            displayAutomaton(fa, path, true);          
        }*/
 
    /*def displayAutomaton(Automaton fa, String path, boolean useProvidedLabels) 
    {
        try(
            var BufferedWriter out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(path + "g.dot")))
        ) {
            try { out.write(transformWithLabels(fa.toDot(),useProvidedLabels)); } catch (IOException e) { e.printStackTrace(); } 
        } catch (FileNotFoundException e1) { e1.printStackTrace(); } catch (IOException e1) { e1.printStackTrace(); }

        var ProcessBuilder builder = new ProcessBuilder("cmd.exe", "/c", "dot -Tpng -O g.dot");
        builder.redirectErrorStream(true);
        var Process p = null;
        try { p = builder.start(); } catch (IOException e) { e.printStackTrace(); }
        var BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream()));
        var String line = null;
        do {
            try {
            line = r.readLine();
            } catch (IOException e) {
                e.printStackTrace();
            }
            //if (line == null) { break; }
            //System.out.println(line);
        } while (line!==null)
        //String path = "C:\\Users\\berad\\Desktop\\ContentsFeb2021\\JavaAndCSharpSources\\JavaWorkspace2020\\wrkspace\\DemoRegExp\\g.dot.png";
        var String expr1 = "dot -Tpng " + path + "g.dot -O g.dot";
        //String apath = path + "g.dot.png";
        var String expr2 = "rundll32.exe \"C:\\Program Files\\Windows Photo Viewer\\PhotoViewer.dll\", ImageView_Fullscreen " + path + "g.dot.png";
        try { Runtime.getRuntime().exec(expr1); } catch (IOException e) { e.printStackTrace(); }
        try { Runtime.getRuntime().exec(expr2); } catch (IOException e) { e.printStackTrace(); }
    }

    def String transformWithLabels(String str, boolean useProvidedLabels) {
        var String final_str = str;
        if(useProvidedLabels) {
            for(String key : unicodeMap.keySet()) {
                //System.out.println("check<!> " + "[label=\"" + "\\u"+String.format("%04x", (int) unicodeMap.get(key)) + "\"]"  + " -> " + key);
                if(final_str.contains("[label=\"" + unicodeMap.get(key).toString() + "\"]")) {
                    //System.out.println("check " + "[label=\"" + unicodeMap.get(key).toString() + "\"]"  + " -> " + key);
                    final_str = final_str.replace("[label=\"" + unicodeMap.get(key).toString() + "\"]", "[label=\"" + key + "\"]");
                }
                if(final_str.contains("[label=\"" + "\\u"+String.format("%04x", Character.getNumericValue(unicodeMap.get(key))) + "\"]")) {
                    //System.out.println("check<> " + "\\u"+String.format("%04x", (int) unicodeMap.get(key))  + " -> " + key);
                    final_str = final_str.replace("[label=\"" + "\\u"+String.format("%04x", Character.getNumericValue(unicodeMap.get(key))) + "\"]", "[label=\"" + key + "\"]");
                }
            }
        }
        return final_str;
    }*/
    
    def computeStepLabels(List<Templates> templateList) {
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
                        if(elmInst instanceof AlternateResponse) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof ChainResponse) addActivityToMap(elmInst.refA,elmInst.refB)
                    }
                }
				if(elm instanceof Past) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof Precedence) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof AlternatePrecedence) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof ChainPrecedence) addActivityToMap(elmInst.refA,elmInst.refB)
                    }
                }
                if(elm instanceof Dependencies) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof RespondedExistence) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof CoExistance) addActivityToMap(elmInst.refA)
                        if(elmInst instanceof Succession) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof AlternateSuccession) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof ChainSuccession) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof NotSuccession) addActivityToMap(elmInst.refA,elmInst.refB)
                        if(elmInst instanceof NotCoExistance) addActivityToMap(elmInst.refA)
                        if(elmInst instanceof NotChainSuccession) addActivityToMap(elmInst.refA,elmInst.refB)
                    }
                }
            }
        }
    }
    
    def addActivityToMap(Ref elmA) {
    	var refName = getRefName(elmA)
        activityList.add(refName)
        if(!unicodeMap.containsKey(refName)) {
            unicodeMap.put(refName, symbol)
            symbol++
        }
    }

	def addActivityToMap(List<Ref> elmA) {
    	var refAName = getRefName(elmA)
		for(elmAName : refAName) {
        	activityList.add(elmAName)
	        if(!unicodeMap.containsKey(elmAName)) {
	            unicodeMap.put(elmAName, symbol)
	            symbol++    
	        }
        }       
    }

	def addActivityToMap(List<Ref> elmA, List<Ref> elmB) {
    	var refAName = getRefName(elmA)
    	var refBName = getRefName(elmB)
    	for(elmAName : refAName) {
        	activityList.add(elmAName)
	        if(!unicodeMap.containsKey(elmAName)) {
	            unicodeMap.put(elmAName, symbol)
	            symbol++    
	        }
        }
		for(elmBName : refBName) {
        	activityList.add(elmBName)
	        if(!unicodeMap.containsKey(elmBName)) {
	            unicodeMap.put(elmBName, symbol)
	            symbol++    
	        }
        }
	}
    
    def addActivityToMap(Ref elmA, Ref elmB) {
    	var refAName = getRefName(elmA)
    	var refBName = getRefName(elmB)
         activityList.add(refAName)
        if(!unicodeMap.containsKey(refAName)){
            unicodeMap.put(refAName, symbol)
            symbol++
        }
        activityList.add(refBName)
        if(!unicodeMap.containsKey(refBName)) {
            unicodeMap.put(refBName, symbol)
            symbol++    
        }
    }

    def addActivityToMap(Ref elmA, List<Ref> elmB) {
    	var refAName = getRefName(elmA)
    	var refBName = getRefName(elmB)
         activityList.add(refAName)
        if(!unicodeMap.containsKey(refAName)){
            unicodeMap.put(refAName, symbol)
            symbol++
        }       
        for(elmBName : refBName) {
        	activityList.add(elmBName)
	        if(!unicodeMap.containsKey(elmBName)) {
	            unicodeMap.put(elmBName, symbol)
	            symbol++    
	        }
        }
    }

    def addActivityToMap(List<Ref> elmA, Ref elmB) {
    	var refAName = getRefName(elmA)
    	var refBName = getRefName(elmB)
        for(elmAName : refAName) {
        	activityList.add(elmAName)
	        if(!unicodeMap.containsKey(elmAName)) {
	            unicodeMap.put(elmAName, symbol)
	            symbol++    
	        }
        }
        activityList.add(refBName)
        if(!unicodeMap.containsKey(refAName)){
            unicodeMap.put(refBName, symbol)
            symbol++
        }
    }
    
	def getRefName(Ref ref){
		var refName = ""
		if(ref instanceof RefStep){
			refName = ref.step.name
		} else {
			if(ref instanceof RefSequence){
				refName = ref.seq.name
			}
		}
		return refName
	}
	
	def getRefName(List<Ref> refList){
		var refName = new ArrayList<String>
		for(ref : refList) {
			if(ref instanceof RefStep){
				refName.add(ref.step.name)
			}
			if(ref instanceof RefSequence){
				refName.add(ref.seq.name)
			}
		}
		return refName
	}
	
}