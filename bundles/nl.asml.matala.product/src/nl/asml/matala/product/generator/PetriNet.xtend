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
package nl.asml.matala.product.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import nl.esi.comma.types.types.SimpleTypeDecl

class PetriNet {
	public var places = new ArrayList<Place>
	public var transitions = new ArrayList<Transition>
	public var input_arcs = new HashMap<String,List<String>>  // transition -> list of places
	public var output_arcs = new HashMap<String,List<String>> // transition -> list of places
	//TODO Rename the function below and across all references. 
	public var map_transition_assertions = new HashMap<String,List<String>> // transition -> list of places to assert on 
	public var arc_expressions = new ArrayList<ArcExpression>
	public var guard_expressions = new HashMap<String,String> // transition -> expression
	public var assert_expressions = new HashMap<String,String> // transition <TYPE: ASSERT> -> expression reference
	public var internal_places = new ArrayList<Place>
	public var init_place_expression_map = new HashMap<String, List<String>>
	
	
	def add_to_map_transition_assertions(String tname, String assertion_place) {
	    // System.out.println("   DEBUG: " + assertion_place)
		if(map_transition_assertions.keySet.contains(tname)) {
			if(!map_transition_assertions.get(tname).contains(assertion_place)) {
				map_transition_assertions.get(tname).add(assertion_place)
			}
		}
		else {
			map_transition_assertions.put(tname, new ArrayList<String>)
			map_transition_assertions.get(tname).add(assertion_place)
		}
	}
	
	def generatePlaceInitializationText() {
		return 
		'''
		«FOR k : init_place_expression_map.keySet»
			self.n.place('«k.trim»').empty()
			«FOR elm : init_place_expression_map.get(k)»
				self.n.place('«k.trim»').add(json.dumps(«elm.trim»))
			«ENDFOR»
		«ENDFOR»
		'''
	}
	
	def add_to_init_place_expression_map(String p, String e) {
		if(init_place_expression_map.keySet.contains(p)) 
			init_place_expression_map.get(p).add(e)
		else{
			var lst = new ArrayList<String>
			lst.add(e)
			init_place_expression_map.put(p,lst)
		}
	}
		
	def is_internal_place(String p) {
		for(ip : internal_places) {
			if(ip.name.equals(p)) return true
		}
		return false
	}
	
	// TODO validate all entry in input and output arcs 
	// have corresponding expression in arc_expressions. Risk of null pointer!
	def get_expression(String t, String p, PType type) {
		for(ae : arc_expressions) {
			if(ae.areEqual(t,p,type)) return ae
		}
		return null
	}
	
	def add_expression(String t, String p, String expTxt, PType type, ArrayList<Constraint> constraints) {
		arc_expressions.add(new ArcExpression(t,p,expTxt,type, constraints))
	}
	
	def add_guard_expression(String t, String txt) {
		guard_expressions.put(t,txt)
	}
	
	def add_assert_expression_ref(String t, String txt) {
        assert_expressions.put(t,txt)
    }
	
	def display() {
		System.out.println("********* Petri Net ***************")
		System.out.println(" > Places ")
		for(p : places){
			System.out.println("	> name: " + p.name + " block-name: " + p.bname + " type: " + p.type.toString)
		}
		System.out.println("	> Transition ")
		for(t : transitions){
			if(guard_expressions.containsKey(t.name))
			     System.out.println("	> name: " + t.name + " block-name: " + t.bname + " guard: " + guard_expressions.get(t.name))
			else System.out.println("	> name: " + t.name + " block-name: " + t.bname)
			
			if(assert_expressions.containsKey(t.name))
                 System.out.println("\t> name: " + t.name + " block-name: " + t.bname + " assert-ref: " + assert_expressions.get(t.name))
		}
		System.out.println("	> Input Arcs ")
		for(k : input_arcs.keySet) {
			System.out.println("	> places: " + input_arcs.get(k) + "  transition: " + k)
		}
		System.out.println("	> Output Arcs ")
		for(k : output_arcs.keySet) {
			System.out.println("	> transition: " + k + "  places: " + output_arcs.get(k))
		}
		System.out.println("	> Transition Output Assertions ")
		for(k : map_transition_assertions.keySet) {
			System.out.println("	> transition: " + k + "  assert-places: " + map_transition_assertions.get(k))
		}
		System.out.println("	> Constraints ")
		for(e : arc_expressions) {
			for(c : e.constraints) {
				System.out.println("	> transition: " + e.t + "  place: " + e.p + "  direction: " + e.type)
				System.out.println("	> name: " + c.name + "  constraint: " + c.txt)
			}
		}
		System.out.println("***********************************")
	}
	
	def add_input_arc(String t, String p) {
		if(input_arcs.keySet.contains(t)) { 
			if(!input_arcs.get(t).contains(p)) {
				input_arcs.get(t).add(p)
			}
		}
		else { 
			input_arcs.put(t, new ArrayList<String>) 
			input_arcs.get(t).add(p)
		}
	}
	
	def add_output_arc(String t, String p) {
		if(output_arcs.keySet.contains(t)) { 
			if(!output_arcs.get(t).contains(p)) {
				output_arcs.get(t).add(p)
			}
		}
		else { 
			output_arcs.put(t, new ArrayList<String>) 
			output_arcs.get(t).add(p)
		}
	}
	
	def getPlace(String bname, String name) { 
		for(pl : places)
			if(pl.name.equals(name) && pl.bname.equals(bname))
				return pl
		throw new RuntimeException
	}
	
	def getTransition(String bname, String name) { 
		for(tr : transitions)
			if(tr.name.equals(name) && tr.bname.equals(bname))
				return tr
		throw new RuntimeException
	}
	
	def generateSnakesPlace(Place p, List<String> inout_places, List<String> init_places) 
	{
		if(inout_places.contains(p.name) || init_places.contains(p.name)) {
			if(p.custom_type instanceof SimpleTypeDecl) 
				return '''self.n.add_place(Place('«p.name»', «SnakesHelper.defaultValue(p.custom_type, null)»))'''
			else return '''self.n.add_place(Place('«p.name»', Data().get_«p.custom_type.name»()))'''
		} else {
			return '''self.n.add_place(Place('«p.name»'))'''
		}
	}
	
	def isPresent(Place p, List<Place> lp) {
		for(elm : lp) { if(elm.name.equals(p.name)) return true }
		return false
	}
	
	def getPlacesTxt(List<String> inout_places, List<String> init_places) 
	{
		var lp = new ArrayList<Place>
		for(p : places) { if(!isPresent(p,lp)) lp.add(p) }
		return
		'''
		«FOR p : lp»
		    «generateSnakesPlace(p, inout_places, init_places)»
		«ENDFOR»
		'''
	}
	
	def getTransitionsTxt() {
		return
		'''
		«FOR t : transitions»
		    self.n.add_transition(Transition('«t.name»'«IF guard_expressions.containsKey(t.name)», «guard_expressions.get(t.name)»«ENDIF»))
		«ENDFOR»
		'''
	}
	
	def getInputArcsTxt() {
		return
		'''
		«FOR t : input_arcs.keySet»
		    «FOR p : input_arcs.get(t)»
		        self.n.add_input('«p»','«t»',«get_expression(t,p,PType.IN).expTxt»)
		    «ENDFOR»
		«ENDFOR»
		'''
	}
	
	def getOutputArcsTxt() {
		return
		'''
		«FOR t : output_arcs.keySet»
		    «FOR p : output_arcs.get(t)»
		        self.n.add_output('«p»','«t»', «get_expression(t,p,PType.OUT).expTxt»)
		    «ENDFOR»
		«ENDFOR»
		'''
	}
	
	def toSnakesSimulation() {
		'''
		import json
		
		def simulate(n):
		    stop = False
		    while not stop:
		        dead_marking = False
		        enabled_transition_modes = {}
		        # print("Current State")
		        # print("{\n\t" +
		        #      "\n\t".join("{!r}: {!r},".format(k, v) for k, v in n.get_marking().items()) +
		        #      "\n}")
		        for t in n.transition():
		            tmodes = t.modes()
		            # print(tmodes)
		            for mode in tmodes:
		                enabled_transition_modes[t] = tmodes
		                print('\n')
		                print('Enabled-transition: ', t)
		                print('    - with inputs: ', mode.dict())
		                # print('    # with-input-modes: ')
		                # for key, value in mode.dict().items():
		                #    json_data = json.loads(value)
		                #    print('      - var: ', key, '  ->  value:\n', json.dumps(json_data, indent=2))
		                # print('     > with mode: ', mode.dict())
		
		        # print(enabled_transition_modes)
		
		        if not enabled_transition_modes:
		            dead_marking = True
		
		        choices = {}
		        idx = 0
		        for key, value in enabled_transition_modes.items():
		            for elm in value:
		                choices[idx] = key, elm
		                idx = idx + 1
		
		        for k1, v1 in choices.items():
		            print('\n')
		            print('Possible-choices: ')
		            print(k1, ' : ', v1)
		            # print('    + choice: ', k1, ':')
		            # for k2, v2 in v1[1].items():
		            #    json_data = json.loads(v2)
		            #    print('    + key: ', k2, ' with-mode:\n', json.dumps(json_data, indent=2))
		
		        if not dead_marking:
		            print('\n')
		            value = input("Enter Choice: ")
		            print('\n')
		            print('****************************************************************')
		            print('Selected transition: ', choices.get(int(value)))
		            t, m = choices.get(int(value))
		            t.fire(m)
		            print('\n')
		            print('[ Transition Fired! ]')
		            print('\n')
		            print('Current Marking: ')
		            for k in n.get_marking():
		                ms = n.get_marking()[k]
		                for i in ms.items():
		                    json_data = json.loads(i)
		                    print('    + Place: ', k, ' has token: ', json.dumps(json_data))
		            print('****************************************************************')
		            # self.generatePlantUML(n, True)
		        else:
		            print('No Enabled Transitions!!')
		            stop = True
		
		
		def getTransitionName(t, isDetailed):
		    if isDetailed:
		        return t.name
		    else:
		        return t.name.split('_')[0]
		
		
		class Simulation:
		    def __init__(self):
		        self.dictTrMode = None
		        self.dictTrName = None
		
		    def getEnabledTransitionList(self, n):
		        trList = []
		        self.dictTrName = {}
		        self.dictTrMode = {}
		        for t in n.transition():
		            tmodes = t.modes()
		            idx = 0
		            for mode in tmodes:
		                # for key,value in mode.dict().items():
		                # kv = ': {0}  -> {1}'.format(key,value)
		                trList.append(t.name + str(idx))
		                self.dictTrName.update({t.name + str(idx): t.name})
		                self.dictTrMode.update({t.name + str(idx): mode})
		                idx = idx + 1
		        return trList
		'''
	}
	
	def toSnakes(String prod_name, 
				 String topology_name, 
				 List<String> listOfEnvBlocks,
				 List<String> listOfAssertTransitions,
				 Map<String, ? extends Set<String>> mapOfSuppressTransitionVars,
				 List<String> inout_places, 
				 List<String> init_places, 
				 int depth_limit,
				 int num_tests,
				 Map<String, ? extends Set<String>> sutTransitionMap
	) {
		'''
		import datetime
		import json
		import pprint
		import argparse
		import random
		from pathlib import Path
		
		from snakes.nets import *

		if __package__ is None or __package__ == '':
		    from «prod_name»_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
		    from «prod_name»_data import Data
		    from «prod_name»_Simulation import Simulation, simulate
		else:
		    from .«prod_name»_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
		    from .«prod_name»_data import Data
		    from .«prod_name»_Simulation import Simulation, simulate
		import subprocess
		import copy
		import os
		
		snakes.plugins.load('gv', 'snakes.nets', 'nets')
		from nets import *
		# from CPNServer.utils import AbstractCPNControl
		
		
		class «prod_name»Model:
		    visitedList = set()
		    visitedTList = [[]]
		    visitedTProdList = [[]]
		    rg_txt = ""
		    SavedMarking = Marking()
		    
		    # test generation data
		    sutTypesList = [«FOR elm : sutTransitionMap.keySet SEPARATOR ','»'«elm»'«ENDFOR»]
		    sutVarTransitionMap = {}
		    numTestCases = 0
		    listOfEnvBlocks = []
		    listOfSUTActions = []
		    mapOfSuppressTransitionVars = {}
		    map_of_transition_modes = {}
		    map_transition_modes_to_name = {}
		    constraint_dict = {}
		    tr_assert_ref_dict = {}
		    map_transition_assert = {}
		
		    def __init__(self):
		        self.rg_txt = '@startuml\n'
		        self.rg_txt += '[*] --> 0\n'
		        self.listOfEnvBlocks = [«FOR elm : listOfEnvBlocks SEPARATOR ','»"«elm»"«ENDFOR»]
		        self.listOfSUTActions = [«FOR elm : listOfAssertTransitions SEPARATOR ','»"«elm»"«ENDFOR»]
		        self.mapOfSuppressTransitionVars = {«FOR k : mapOfSuppressTransitionVars.keySet SEPARATOR ','»'«k»': [«FOR v : mapOfSuppressTransitionVars.get(k) SEPARATOR ','»'«v»'«ENDFOR»]«ENDFOR»}
		        self.n = PetriNet('«topology_name»')
		        self.n.globals["Data"] = Data
		        self.n.globals.declare("import json")
		        «getPlacesTxt(inout_places, init_places)»
		        «generatePlaceInitializationText»
		        «transitionsTxt»
		        «inputArcsTxt»
		        «outputArcsTxt»
		    
		    «print_SCNGen(num_tests, depth_limit)»
		    
		    def initializeTestGeneration(self):
		        self.sutVarTransitionMap = {«FOR entry : sutTransitionMap.entrySet SEPARATOR ','»'«entry.key»': [«FOR v : entry.value SEPARATOR ','»'«v»'«ENDFOR»]«ENDFOR»}
		        # map_of_transition_modes = {}
		        for entry in self.visitedTList:
		            if entry:
		                for step in entry:
		                    if step[1].name in self.map_of_transition_modes:
		                        self.map_of_transition_modes.get(step[1].name).append(step[2])
		                    else:
		                        self.map_of_transition_modes[step[1].name] = [step[2]]
		        # map_transition_modes_to_name = {}
		        cnt = 0
		        for k,v in self.map_of_transition_modes.items():
		            # print(k)
		            cnt = 0
		            # modes = set(v)
		            for elm in v: # modes
		                # print(elm)
		                if k + "_" +elm.__repr__() in self.map_transition_modes_to_name:
		                    print("WARN: duplicate modes detected for same transition.")
		                    print(k + "_" +elm.__repr__())
		                    print("WARN: references to the above transitions are ambigous!")
		                self.map_transition_modes_to_name[k + "_" +elm.__repr__()] = k + "_" + str(cnt)
		                # self.map_transition_modes_to_name[k + "_" + pprint.pformat(elm.items(), width=60, compact=True,depth=5)] = k + "_" + str(cnt)
		                cnt = cnt + 1
		        _txt = []
		        constraint_list = []
		        «FOR e : arc_expressions»
		            «IF !e.constraints.empty»
		                «FOR c : e.constraints»
		                    _txt.append(CEntry("«c.name»","«c.txt.replace("\"", "\\\"")»"))
		                «ENDFOR»
		                constraint_list.append(Constraint("«e.p»","«e.type»", _txt))
		                # _txt = []
		                if "«e.t»" not in self.constraint_dict:
		                    self.constraint_dict["«e.t»"] = constraint_list
		                else:
		                    self.constraint_dict["«e.t»"].extend(constraint_list)
		                _txt = []
		                constraint_list = []
		            «ENDIF»
		        «ENDFOR»
		        # tr_assert_ref_dict = {}
		        # map_transition_assert = {}
		        «FOR tname : assert_expressions.keySet»
		            self.tr_assert_ref_dict["«tname»"] = "«assert_expressions.get(tname)»"
		        «ENDFOR»
		        self.map_transition_assert = {«FOR elm : map_transition_assertions.keySet SEPARATOR ','»'«elm»': [«FOR v : map_transition_assertions.get(elm) SEPARATOR ','»'«v»'«ENDFOR»]«ENDFOR»}
		    
		    def generateTestCases(self):
		        i = 0
		        j = 0
		        idx = 0
		        _tests = Tests()
		        
		        for entry in pn.visitedTList:
		            # txt = ''
		            if entry:
		                _test_scn = TestSCN(self.map_transition_assert, self.constraint_dict, self.tr_assert_ref_dict)
		                idx = idx + 1
		                j = 0
		                for step in entry:
		                    stp = step[1].name + "_" + step[2].__repr__()
		                    step_txt = self.map_transition_modes_to_name[stp] 
		                    if step_txt.rsplit("_",1)[0].split("@",1)[0] in self.listOfSUTActions:
		                        # if not step_txt.split("_")[0] in self.listOfEnvBlocks:
		                            # _step = Step(step_txt.rsplit("_",1)[0].split("@",1)[0] in self.listOfSUTActions)
		                        # else:
		                            # _step = Step(False)
		                        _step = Step(False)
		                        _step.step_name = self.map_transition_modes_to_name[stp]
		                        for x,y in step[2].dict().items():
		                            _step.input_data[x.replace("v_", "", 1)] = json.dumps(json.loads(y), indent=4, sort_keys=True)
		                        for x,y in self.visitedTProdList[i][j].items():
		                            for z in y.items():
		                                #if step_txt.split("@")[0] in self.mapOfSuppressTransitionVars:
		                                #    if x not in self.mapOfSuppressTransitionVars[step_txt.split("@")[0]]:
		                                #        _step.output_data[x] = json.dumps(json.loads(z), indent=4, sort_keys=True)
		                                #else:
		                                _step.output_data[x] = json.dumps(json.loads(z), indent=4, sort_keys=True)
		                        if step_txt.split("@")[0] in self.mapOfSuppressTransitionVars:
		                            _step.output_suppress = self.mapOfSuppressTransitionVars[step_txt.split("@")[0]]
		                        _test_scn.step_list.append(_step)
		                    j = j + 1
		                _test_scn.compute_dependencies()
		                _test_scn.generate_viz(i, output_dir=p.plantuml_dir)
		                _test_scn.generateTSpec(i, pn.sutTypesList, pn.sutVarTransitionMap, output_dir=p.tspec_dir)
		                _tests.list_of_test_scn.append(_test_scn)
		            i = i + 1
		            
		        fname = p.tspec_dir / ("tcs"+".json")
		        os.makedirs(os.path.dirname(fname), exist_ok=True)
		        with open(fname, 'w') as f:
		            f.write(_tests.toJSON())
		    
		    def chunkstring(self, string, length):
		        return (string[0+i:length+i] for i in range(0, len(string), length))
		        
		    def determineInterfacePlaces(self):
		        intfP = InterfacePlaces()
		        for p in self.n.place():
		            if not self.n.pre([str(p)]):
		                # print(" - " + str(p) + " -> source")
		                intfP.input.append(str(p))
		            if not self.n.post([str(p)]):
		                # print(" - " + str(p) + " -> dest")
		                intfP.output.append(str(p))
		        return intfP
		
		
		class InterfacePlaces:
		    def __init__(self):
		        self.input = []
		        self.output = []
		
		
		if __name__ == '__main__':
		    # check if there is custom output directory
		    parser = argparse.ArgumentParser(
		                    prog='ProgramName',
		                    description='What the program does',
		                    epilog='Text at the bottom of help')
		    parser.add_argument("-tsdir","--tspec_dir",
		                        type=Path,
		                        default="generated_scenarios",
		                        help="The directory in which tspec files produced will be saved")
		    
		    parser.add_argument("-pudir","--plantuml_dir",
		                        type=Path,
		                        default=os.getcwd(),
		                        help="The directory in which plantuml files produced will be saved")
		    
		    parser.add_argument("-no_sim",
		                        type=bool,
		                        default=False,
		                        help="Disable simulation")
		    
		    p = parser.parse_args()
		    p.tspec_dir.mkdir(exist_ok=True)
		    p.plantuml_dir.mkdir(exist_ok=True)
		    
		    a = datetime.datetime.now()
		    pn = «prod_name»Model()
		    print("[INFO] Loaded CPN model.")
		    # pn.n.draw('net-gv-graph.png')
		    s = StateGraph(pn.n)
		    # s.build()
		    # s.draw('test-gv-graph.png')
		    # print(" Finished Generation, writing to file.. ")
		    print("[INFO] Starting Reachability Graph Generation")
		    # pn.generateScenarios(s,0,[],[],[],0,«depth_limit»)
		    pn.generateSCN(0,[],[])
		    print('Num Tests: ', pn.numTestCases)
		    print("[INFO] Finished.")
		    b = datetime.datetime.now()
		
		    # s.goto(0)
		    
		    # rg_txt = '@startuml\n'
		    # rg_txt += '[*] --> 0\n'
		    # for state in s:
		        # for succ in s.successors():
		            # rg_txt += '%s --> %s : %s\n' % (state,succ[0],succ[1])
		    # pn.rg_txt += "@enduml\n"
		    # fname = p.plantuml_dir / "rg.plantuml"
		    # with open(fname, 'w') as f:
		        # f.write(pn.rg_txt)
		    # print("[INFO] Created rg.plantuml")
		    c = datetime.datetime.now()

		    print("[INFO] Starting Test Generation.")
		    pn.initializeTestGeneration()
		    pn.generateTestCases()
		    
		    # print('[INFO] Number-of-generated-scenario files: ',len(pn.visitedTList))
		    print("[INFO] Test Generation Finished.")
		    d = datetime.datetime.now()
		    
		    print("[INFO] Creating Structure and Behavior Views in PlantUML.")
		    map_block_uml_txt = {}
		    for t in pn.n.transition():
		        map_block_uml_txt[t.name.split('_')[0]] = '@startuml\n'
		        
		    for t in pn.n.transition():
		        gtxt = map_block_uml_txt.get(t.name.split('_')[0])
		        if 'json.loads' in t.guard._str:
		            # print(t.guard._str.replace('json.loads',''))
		            # print('\n'.join(list(pn.chunkstring(t.guard._str.replace('json.loads','').replace(', object_pairs_hook=Data().int_keys', ''),55))))
		            gtxt += 'component %s\n' % (t.name)
		            if len(list(pn.chunkstring(t.guard._str.replace('json.loads','').replace(', object_pairs_hook=Data().int_keys', ''),68))) <= 2:
		                gtxt += 'note left of [%s]\n %s\nendnote\n' % (t.name, '\n'.join(list(pn.chunkstring(t.guard._str.replace('json.loads','').replace(', object_pairs_hook=Data().int_keys', ''),55))))
		            else:
		                gtxt += 'note bottom of [%s]\n %s\nendnote\n' % (t.name, '\n'.join(list(pn.chunkstring(t.guard._str.replace('json.loads','').replace(', object_pairs_hook=Data().int_keys', ''),55))))
		        else:
		            gtxt += 'component %s\n' % (t.name)
		            gtxt += 'note right of [%s]\n %s\nendnote\n' % (t.name, t.guard)
		        map_block_uml_txt[t.name.split('_')[0]] = gtxt
		        
		    for t in pn.n.transition():
		        for inp in pn.n.pre(t.name):
		            txt = map_block_uml_txt.get(t.name.split('_')[0])
		            if 'local' in inp:
		                txt += '%s -[#lightgrey]-> [%s]\n' % (inp, t.name)
		            else:
		                txt += '%s --> [%s]\n' % (inp, t.name)
		            map_block_uml_txt[t.name.split('_')[0]] = txt
		        for out in pn.n.post(t.name):
		            txt = map_block_uml_txt.get(t.name.split('_')[0])
		            if 'local' in out:
		                txt += '[%s] -[#lightgrey]-> %s\n' % (t.name, out)
		            else:
		                txt += '[%s] --> %s\n' % (t.name, out)
		            map_block_uml_txt[t.name.split('_')[0]] = txt
		    
		    for key in map_block_uml_txt:
		        txt = map_block_uml_txt.get(key)
		        txt += '@enduml\n'
		        map_block_uml_txt[key] = txt
		        fname = p.plantuml_dir / (key + ".plantuml")
		        with open(fname, 'w') as f:
		            f.write(txt)
		    
		    print("[INFO] View Generation Finished.")
		    e = datetime.datetime.now()
		    print("[INFO] Time Statistics")
		    print("[INFO]    * Reachability Computation: %s" % (b - a))
		    print("[INFO]    * Reachability PUML Creation: %s" % (c - b))
		    print("[INFO]    * Test Generation: %s" % (d - c))
		    print("[INFO]    * PlantUML View Generation: %s" % (e - d))
		    
		    # print("[INFO] Starting Command-Line Simulation.")
		    # Simulation().simulateUI(pn.n)
		    
		    #if not p.no_sim:
			#    print('[SIM] Start Simulation? (Y/N) :')
			#    value = input(" Enter Choice: ")
			#    if value == "Y" or value == "y":
			#        os.system('cls')
			#        simulate(pn.n)
		    
		    print("[INFO] Exiting..")
		'''
	}
	
	def print_SCNGen(int num_tests, int depth_limit) {
		return
		'''
	    def getCurrentMarking(self):
	        # print('[INFO] Current Marking: ', self.n.get_marking())
	        return self.n.get_marking()

	    def saveMarking(self):
	        self.SavedMarking = self.n.get_marking()
	    
	    def gotoSavedMarking(self):
	        print('[INFO] Setting Petri net to Saved Marking: ', self.SavedMarking)
	        self.n.set_marking(self.SavedMarking)

	    @staticmethod
	    def fireEnabledTransition(choices, cid):
	        _t, _m = choices.get(int(cid))
	        _r = _t.flow(_m)
	        _t.fire(_m)
	        print('[INFO] Transition Fired with ID: ', cid)
	        return _r

	    def getEnabledTransitions(self):
	        enabled_transition_modes = {}
	        choices = {}
	        for _t in self.n.transition():
	            enabled_transition_modes[_t] = _t.modes()
	            # print(enabled_transition_modes)
	            chidx = 0
	            for _key, _value in enabled_transition_modes.items():
	                for _elm in _value:
	                    choices[chidx] = _key, _elm
	                    chidx = chidx + 1
	        print('[INFO] Enabled Transition Choices: ', choices)
	        return choices
	    
	    def generateSCN(self, level, visitedT, visitedTP):
	        «IF num_tests !== 0»
	            if self.numTestCases >= «num_tests»:
	                # print(' [RG-INFO] Max test cases reached! Terminating path. ')
	                return
	        «ENDIF»
	        if level > «depth_limit»:
	            self.visitedTList.append(list(visitedT))
	            self.visitedTProdList.append(list(visitedTP))
	            self.numTestCases = self.numTestCases + 1
	            # print(' [RG-INFO] Depth limit reached! Terminating path.')
	            return
	        enabled_transition_modes = {}
	        for t in self.n.transition():
	            tmodes = t.modes()
	            for mode in tmodes:
	                enabled_transition_modes[t] = tmodes
	        dead_marking = False
	        if not enabled_transition_modes:
	            dead_marking = True
	        choices = {}
	        idx = 0
	        for key, value in enabled_transition_modes.items():
	            for elm in value:
	                choices[idx] = key, elm
	                idx = idx + 1
	        currM = self.getCurrentMarking()
	        if not dead_marking:
	            # t, m = random.choice(list(choices.values()))
	            for t, m in choices.values():  
	                visitedT.append((0,t,m))
	                visitedTP.append(t.flow(m)[1])
	                t.fire(m)
	                self.getCurrentMarking()
	                self.generateSCN(level+1,visitedT.copy(), visitedTP.copy())
	                del visitedT[-1]
	                del visitedTP[-1]
	                self.n.set_marking(currM)
	        else:
	            # print('[RG-INFO] Dead marking found.')
	            self.visitedTList.append(list(visitedT))
	            self.visitedTProdList.append(list(visitedTP))
	            self.numTestCases = self.numTestCases + 1
	            self.n.set_marking(currM)
	            return
	    
	    def generateScenarios(self, state_space, currentVertex, visited, visitedT, visitedTP, depth, limit):
	        # print(currentVertex)
	        # print(self.visitedList)
	        # print(visitedT)
	        «IF num_tests !== 0»
	            if self.numTestCases >= «num_tests»:
	                print(' [RG-INFO] max test cases reached! Terminating path. ')
	                return
	        «ENDIF»
	        if depth > limit:
	            print('	[RG-INFO] depth limit is reached.')
	            self.visitedTList.append(list(visitedT))
	            self.visitedTProdList.append(list(visitedTP))
	            self.numTestCases = self.numTestCases + 1
	            return
	        elif currentVertex in self.visitedList:
	            print('	[RG-INFO] current vertex is already visited.')
	            self.visitedTList.append(list(visitedT))
	            self.visitedTProdList.append(list(visitedTP))
	            self.numTestCases = self.numTestCases + 1
	            return
	        else:
	            self.visitedList.add(currentVertex)
	            state_space.goto(currentVertex)
	            visited.append(currentVertex)
	            if len(list(state_space.successors())) == 0:
	                print('	[RG-INFO] deadlock detected.')
	                self.visitedTList.append(list(visitedT))
	                self.visitedTProdList.append(list(visitedTP))
	                self.numTestCases = self.numTestCases + 1
	                return
	            else:
	                for elm in state_space.successors():
	                    state_space.goto(currentVertex)
	                    visitedT.append(elm)  # [1].name)
	                    visitedTP.append(elm[1].flow(elm[2])[1])
	                    self.rg_txt += '%s --> %s : %s\n' % (currentVertex, elm[0], elm[1])
	                    self.generateScenarios(state_space, elm[0], visited.copy(), visitedT.copy(), visitedTP.copy(), depth + 1, limit)
	                    # visitedT.remove(elm[1].name)
	                    del visitedT[-1]
	                    del visitedTP[-1]
		'''
	}
	
	def printSCNGen() {
		return
		'''
		def generateScenarios(self, state_space, currentVertex, visited, visitedT, depth, limit):
		    state_space.goto(currentVertex)
		    visited.append(currentVertex)
		    # print('state %s is %r with status %s' % (state_space.current(), state_space.net.get_marking(),
		    # state_space.completed()))
		    for elm in state_space.successors():
		        visitedT.append(elm[1].name)
		        # print('Next State: ', elm[0], ' with transition ', elm[1])
		        if elm[0] not in visited:
		            self.generateScenarios(state_space,elm[0],visited.copy(),visitedT.copy(), depth+1, limit)
		        else:
		            self.visitedTList.append(visitedT)
		        visitedT.remove(elm[1].name)
		    self.visitedList.append(visited)
		'''
	}	
	
	def getBlocks() {
		var block_set = new HashSet<String>
		for(t : transitions) {
			block_set.add(t.bname)
		}
		return block_set
	}
	
	def getTransitions(String block_name) {
		var transition_list = new ArrayList<String>
		for(t : transitions) {
			if(t.bname.equals(block_name))
				transition_list.add(t.name)
		}
		return transition_list
	}
	
	def getOutputs(String transition_name) {
		var output_list = new HashSet<String>
		for(t : output_arcs.keySet) {
			if(t.equals(transition_name)) {
				for(p : output_arcs.get(t)) {
					output_list.add(p)
				}
			}
		}
		return output_list
	}
	
	def getIntputs(String transition_name) {
		var input_list = new HashSet<String>
		for(t : input_arcs.keySet) {
			if(t.equals(transition_name)) {
				for(p : input_arcs.get(t)) {
					input_list.add(p)
				}
			}
		}
		return input_list
	}
	
	def getInputArcsOfBlock(String block_name) {
		var arcList = new HashSet<String>
		for(b: getBlocks) {
			for(t : getTransitions(b)) {
				for(ip : getIntputs(t)) {
					arcList.add(ip)
				}		
			}
		}
		return arcList
	}
	
	def getOutputArcsOfBlock(String block_name) {
		var arcList = new HashSet<String>
		for(b: getBlocks) {
			for(t : getTransitions(b)) {
				for(ip : getOutputs(t)) {
					arcList.add(ip)
				}		
			}
		}
		return arcList
	}
	
	def toPlantUML(PetriNet pn, boolean printBlocks) {
		return 
		'''
		@startuml
		«IF printBlocks»
			«FOR b: getBlocks»
				node "«b»" {
					«FOR t : getTransitions(b)»
						[«t»]
					«ENDFOR»
				}
			«ENDFOR»
		«ENDIF»
		«FOR b: getBlocks»
			«FOR t : getTransitions(b)»
				«FOR elm : getIntputs(t)»
					«IF !pn.is_internal_place(elm) && printBlocks»«elm» --> [«t»]«ENDIF»
					«IF !printBlocks»«elm» --> [«t»]«ENDIF»
				«ENDFOR»
				«FOR elm : getOutputs(t)»
					«IF !pn.is_internal_place(elm) && printBlocks»[«t»] --> «elm»«ENDIF»
					«IF !printBlocks»[«t»] --> «elm»«ENDIF»
				«ENDFOR»
			«ENDFOR»
		«ENDFOR»
		@enduml
		'''
	}
}
