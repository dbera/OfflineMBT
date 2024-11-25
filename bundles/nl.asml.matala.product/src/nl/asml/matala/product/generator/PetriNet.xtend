package nl.asml.matala.product.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.HashSet
import nl.esi.comma.types.types.SimpleTypeDecl

class PetriNet {
	public var places = new ArrayList<Place>
	public var transitions = new ArrayList<Transition>
	public var input_arcs = new HashMap<String,List<String>>  // transition -> list of places
	public var output_arcs = new HashMap<String,List<String>> // transition -> list of places
	public var map_transition_assertions = new HashMap<String,List<String>> // transition -> list of places to assert on
	public var arc_expressions = new ArrayList<ArcExpression>
	public var guard_expressions = new HashMap<String,String> // transition -> expression
	public var internal_places = new ArrayList<Place>
	public var init_place_expression_map = new HashMap<String, List<String>>
	
	
	def add_to_map_transition_assertions(String tname, String assertion_place) {
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
	
	def display() {
		System.out.println("********* Petri Net ***************")
		System.out.println(" > Places ")
		for(p : places){
			System.out.println("	> name: " + p.name + " block-name: " + p.bname + " type: " + p.type.toString)
		}
		System.out.println("	> Transition ")
		for(t : transitions){
			if(guard_expressions.containsKey(t.name))
				System.out.println("	> name: " + t.name + " block-name: " + t.bname + " guard: " + guard_expressions.get(t))
			else System.out.println("	> name: " + t.name + " block-name: " + t.bname)
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
				return '''self.n.add_place(Place('«p.name»', «SnakesHelper.defaultValue(p.custom_type)»))'''
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
		                print(' Enabled-transition-name: ', t)
		                print('    # with-input-modes: ')
		                for key, value in mode.dict().items():
		                    json_data = json.loads(value)
		                    print('      - var: ', key, '  ->  value:\n', json.dumps(json_data, indent=2))
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
		            print('    + choice: ', k1, ':')
		            for k2, v2 in v1[1].items():
		                json_data = json.loads(v2)
		                print('    + key: ', k2, ' with-mode:\n', json.dumps(json_data, indent=2))
		
		        if not dead_marking:
		            print('\n')
		            value = input(" Enter Choice: ")
		            print('\n')
		            print(' - Selected transition: ', choices.get(int(value)))
		            t, m = choices.get(int(value))
		            t.fire(m)
		            print('\n')
		            print(' [ Transition Fired! ]')
		            print('\n')
		            print(' Resulting Marking: ')
		            for k in n.get_marking():
		                ms = n.get_marking()[k]
		                json_data = json.loads(ms.items()[0])
		                print('    + Place: ', k, ' has Token:\n', json.dumps(json_data, indent=2))
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
				 ArrayList<String> listOfAssertTransitions,
				 HashMap<String,List<String>> mapOfSuppressTransitionVars,
				 List<String> inout_places, 
				 List<String> init_places, 
				 int depth_limit
	) {
		'''
		import datetime
		import json
		import pprint
		
		from snakes.nets import *

		from «prod_name»_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
		from «prod_name»_data import Data
		from «prod_name»_Simulation import Simulation, simulate
		import subprocess
		import copy
		import os
		
		snakes.plugins.load('gv', 'snakes.nets', 'nets')
		from nets import *
		
		
		class «prod_name»Model:
		    visitedList = set()
		    visitedTList = [[]]
		    visitedTProdList = [[]]
		    rg_txt = ""
		    SavedMarking = Marking()
		
		    def __init__(self):
		        self.rg_txt = '@startuml\n'
		        self.rg_txt += '[*] --> 0\n'
		        self.n = PetriNet('«topology_name»')
		        self.n.globals["Data"] = Data
		        self.n.globals.declare("import json")
		        «getPlacesTxt(inout_places, init_places)»
		        «generatePlaceInitializationText»
		        «transitionsTxt»
		        «inputArcsTxt»
		        «outputArcsTxt»
		    
		    «print_SCNGen»
		    
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
		    a = datetime.datetime.now()
		    pn = «prod_name»Model()
		    print("[INFO] Loaded CPN model.")
		    # pn.n.draw('net-gv-graph.png')
		    s = StateGraph(pn.n)
		    # s.build()
		    # s.draw('test-gv-graph.png')
		    # print(" Finished Generation, writing to file.. ")
		    print("[INFO] Starting Reachability Graph Generation")
		    pn.generateScenarios(s,0,[],[],[],0,«depth_limit»)
		    print("[INFO] Finished.")
		    b = datetime.datetime.now()
		
		    s.goto(0)
		    # rg_txt = '@startuml\n'
		    # rg_txt += '[*] --> 0\n'
		    # for state in s:
		        # for succ in s.successors():
		            # rg_txt += '%s --> %s : %s\n' % (state,succ[0],succ[1])
		    pn.rg_txt += "@enduml\n"
		    fname = "rg.plantuml"
		    with open(fname, 'w') as f:
		        f.write(pn.rg_txt)
		    print("[INFO] Created rg.platuml")
		    
		    # server = PlantUML(url='http://www.plantuml.com/plantuml/img/', basic_auth={}, form_auth={}, http_opts={}, request_opts={})
		    # subprocess.call(['java -DPLANTUML_LIMIT_SIZE=122192', '-jar', 'plantuml-1.2023.8.jar', 'rg.plantuml'])
		    subprocess.Popen('java -DPLANTUML_LIMIT_SIZE=122192 -jar ./lib/plantuml-1.2023.11.jar rg.plantuml',
		                     stdout=subprocess.PIPE,
		                     stderr=subprocess.STDOUT)
		    #if os.path.exists(fname):
		    #    server.processes_file(abspath(fname))
		    # for entry in pn.visitedTList:
		    #    print('SCN: ', entry)
		    c = datetime.datetime.now()
		    
		    listOfEnvBlocks = [«FOR elm : listOfEnvBlocks SEPARATOR ','»"«elm»"«ENDFOR»]
		    listOfAssertTransitions = [«FOR elm : listOfAssertTransitions SEPARATOR ','»"«elm»"«ENDFOR»]
		    mapOfSuppressTransitionVars = {«FOR k : mapOfSuppressTransitionVars.keySet SEPARATOR ','»'«k»': [«FOR v : mapOfSuppressTransitionVars.get(k) SEPARATOR ','»'«v»'«ENDFOR»]«ENDFOR»}
		    print("[INFO] Starting Test Generation.")
		    
		    map_of_transition_modes = {}
		    for entry in pn.visitedTList:
		        if entry:
		            for step in entry:
		                if step[1].name in map_of_transition_modes:
		                    map_of_transition_modes.get(step[1].name).append(step[2])
		                else:
		                    map_of_transition_modes[step[1].name] = [step[2]]
		    
		    map_transition_modes_to_name = {}
		    cnt = 0
		    for k,v in map_of_transition_modes.items():
		        # print(k)
		        cnt = 0
		        # modes = set(v)
		        for elm in v: # modes
		            # print(elm)
		            map_transition_modes_to_name[k + "_" +elm.__repr__()] = k + "_" + str(cnt)
		            # map_transition_modes_to_name[k + "_" + pprint.pformat(elm.items(), width=60, compact=True,depth=5)] = k + "_" + str(cnt)
		            cnt = cnt + 1
		    
		    txt = '\n// import "<insert valid step specification file>"\n\ncontext-map\n\n'
		    for k,v in map_transition_modes_to_name.items():
		        # print(k)
		        # print(v)
		        step_txt = v
		        if step_txt.split("_")[0] in listOfEnvBlocks:
		            txt += 'abstract-step %s\n' %(v)
		            txt += '    with /* %s */\n' %(k)
		            txt += '    // -> <refer to a step sequence>\n'
		    
		    fname = "./generated_scenarios/_cm.tspec"
		    os.makedirs(os.path.dirname(fname), exist_ok=True)
		    with open(fname, 'w') as f:
		        f.write(txt)
		    
		    print("[INFO] Created context mapper.")
		    
		    _txt = []
		    constraint_list = []
		    constraint_dict = {}
		    «FOR e : arc_expressions»
		    	«IF !e.constraints.empty»
		    	«FOR c : e.constraints»
		    		_txt.append(CEntry("«c.name»","«c.txt.replace("\"", "\\\"")»"))
		    	«ENDFOR»
		    	constraint_list.append(Constraint("«e.p»","«e.type»", _txt))
		    	_txt = []
		    	if "«e.t»" not in constraint_dict:
		    	    constraint_dict["«e.t»"] = constraint_list
		    	else:
		    	    constraint_dict["«e.t»"].extend(constraint_list)
		    	«ENDIF»
		    «ENDFOR»
		    
		    idx = 0
		    # txt = ''
		    map_transition_assert = {«FOR elm : map_transition_assertions.keySet SEPARATOR ','»'«elm»': [«FOR v : map_transition_assertions.get(elm) SEPARATOR ','»'«v»'«ENDFOR»]«ENDFOR»}
		    i = 0
		    j = 0
		    _tests = Tests()
		    for entry in pn.visitedTList:
		        # txt = ''
		        if entry:
		            _test_scn = TestSCN(map_transition_assert, constraint_dict)
		            idx = idx + 1
		            # txt += '\nimport "_cm.tspec"\n\nabstract-test-definition\n\nTest-Scenario : s%s \n' % (idx)
		            j = 0
		            for step in entry:
		                # txt += "    [%s] : [%s]\n" % (step[1], step[2])
		                stp = step[1].name + "_" + step[2].__repr__()
		                # stp = step[1].name + "_" + pprint.pformat(step[2].items(), width=60, compact=True, depth=5)
		                # step_txt = map_transition_modes_to_name[step[1].name + "_" + step[2].__repr__()]
		                step_txt = map_transition_modes_to_name[stp]
		                if step_txt.split("_")[0] in listOfEnvBlocks or step_txt.rsplit("_",1)[0] in listOfAssertTransitions:
		                    # suppress = False
		                    # if step_txt.split("@")[0] in listOfSuppressTransitions:
		                    # suppress = True
		                    if not step_txt.split("_")[0] in listOfEnvBlocks:
		                        _step = Step(step_txt.rsplit("_",1)[0] in listOfAssertTransitions)
		                    else:
		                        _step = Step(False)
		                    # txt += "    %s\n" % (map_transition_modes_to_name[step[1].name + "_" + step[2].__repr__()])
		                    # txt += "step-name: %s\n" % (map_transition_modes_to_name[stp])
		                    _step.step_name = map_transition_modes_to_name[stp]
		                    # txt += "    input-binding: %s\n" % (step[2].__repr__())
		                    # txt += "input-binding:\n"
		                    for x,y in step[2].dict().items():
		                        # txt += "    /*\n"
		                        # txt += "%s: %s\n" % (x,json.dumps(json.loads(y), indent=4, sort_keys=True))
		                        _step.input_data[x.replace("v_", "", 1)] = json.dumps(json.loads(y), indent=4, sort_keys=True)
		                        # txt += "    \n\t*/\n"
		                    # txt += "    output-data: %s\n" % (pn.visitedTProdList[i][j])
		                    # txt += "output-data:\n"
		                    for x,y in pn.visitedTProdList[i][j].items():
		                        # txt += "%s:" % x
		                        for z in y.items():
		                            # txt += "%s\n" % (json.dumps(json.loads(z), indent=4, sort_keys=True))
		                            if step_txt.split("@")[0] in mapOfSuppressTransitionVars:
		                                if x not in mapOfSuppressTransitionVars[step_txt.split("@")[0]]:
		                                    _step.output_data[x] = json.dumps(json.loads(z), indent=4, sort_keys=True)
		                            else:
		                                _step.output_data[x] = json.dumps(json.loads(z), indent=4, sort_keys=True)
		                    # txt += "\n"
		                    _test_scn.step_list.append(_step)
		                    # if map_transition_assert[map_transition_modes_to_name[stp].rsplit('_', 1)[0]]:
		                        # s.goto(step[0])
		                        # txt += "    result-marking\n"
		                        # txt += "\n/*\n"
		                        # for k, v in s.net.get_marking().items():
		                            # if k in map_transition_assert[map_transition_modes_to_name[stp].rsplit('_', 1)[0]]:
		                                # txt += "\t" + k
		                                # txt += ":"
		                                # txt += "\t" + pprint.pformat(v, width=60, indent=4, compact=True, depth=2)
		                                # txt += "\n"
		                        # txt += "\t*/\n"
		                j = j + 1
		            _test_scn.compute_dependencies()
		            _test_scn.generate_viz(i)
		            _test_scn.generateTSpec(i)
		            _tests.list_of_test_scn.append(_test_scn)
		            # txt += '\ngenerate-file "./vfab2_scenario/"\n\n'
		            # fname = "./generated_scenarios/scenario" + str(idx) +".tspec"
		            # os.makedirs(os.path.dirname(fname), exist_ok=True)
		            # with open(fname, 'w') as f:
		            #    f.write(txt)
		        i = i + 1
		    
		    fname = "./generated_scenarios/tcs" + ".json"
		    os.makedirs(os.path.dirname(fname), exist_ok=True)
		    with open(fname, 'w') as f:
		        f.write(_tests.toJSON())
		    
		    print('[INFO] Number-of-generated-scenario files: ',len(pn.visitedTList))
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
		        fname = key + ".plantuml"
		        with open(fname, 'w') as f:
		            f.write(txt)
		    
		    print("[INFO] View Generation Finished.")
		    e = datetime.datetime.now()
		    print("[INFO] Time Statistics")
		    print("[INFO]    * Reachability Computation: %s" % (b - a))
		    print("[INFO]    * Reachability PUML Creation: %s" % (c - b))
		    print("[INFO]    * Test Generation: %s" % (d - c))
		    print("[INFO]    * PlantUML View Generation: %s" % (e - d))
		    
		    print("[INFO] Starting Command-Line Simulation.")
		    # Simulation().simulateUI(pn.n)
		    
		    print('[SIM] Start Simulation? (Y/N) :')
		    value = input(" Enter Choice: ")
		    if value == "Y" or value == "y":
		        os.system('cls')
		        simulate(pn.n)
		    
		    print("[INFO] Exiting..")
		'''
	}
	
	def print_SCNGen() {
		return
		'''
	    def getCurrentMarking(self):
	        print('[INFO] Current Marking: ', self.n.get_marking())
	        return self.n.get_marking()

	    def saveMarking(self):
	        self.SavedMarking = self.n.get_marking()
	    
	    def gotoSavedMarking(self):
	        print('[INFO] Setting Petri net to Saved Marking: ', self.SavedMarking)
	        self.n.set_marking(self.SavedMarking)

	    @staticmethod
	    def fireEnabledTransition(choices, cid):
	        _t, _m = choices.get(int(cid))
	        _t.fire(_m)
	        print('[INFO] Transition Fired with ID: ', cid)

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
	    
	    def generateScenarios(self, state_space, currentVertex, visited, visitedT, visitedTP, depth, limit):
	        # print(currentVertex)
	        # print(self.visitedList)
	        # print(visitedT)
	        if depth > limit:
	            print('	[RG-INFO] depth limit is reached.')
	            self.visitedTList.append(list(visitedT))
	            self.visitedTProdList.append(list(visitedTP))
	        elif currentVertex in self.visitedList:
	            print('	[RG-INFO] current vertex is already visited.')
	            self.visitedTList.append(list(visitedT))
	            self.visitedTProdList.append(list(visitedTP))
	        else:
	            self.visitedList.add(currentVertex)
	            state_space.goto(currentVertex)
	            visited.append(currentVertex)
	            if len(list(state_space.successors())) == 0:
	                print('	[RG-INFO] deadlock detected.')
	                self.visitedTList.append(list(visitedT))
	                self.visitedTProdList.append(list(visitedTP))
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
