import datetime
import json
import pprint
import argparse
import random
from pathlib import Path

from snakes.nets import *

if __package__ is None or __package__ == '':
    from issue371_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
    from issue371_data import Data
    from issue371_Simulation import Simulation, simulate
else:
    from .issue371_TestSCN import TestSCN, Step, Tests, Constraint, CEntry
    from .issue371_data import Data
    from .issue371_Simulation import Simulation, simulate
import subprocess
import copy
import os

snakes.plugins.load('gv', 'snakes.nets', 'nets')
from nets import *
# from CPNServer.utils import AbstractCPNControl


class issue371Model:
    visitedList = set()
    visitedTList = [[]]
    visitedTProdList = [[]]
    rg_txt = ""

    # test generation data
    sutTypesList = []
    sutVarTransitionMap = {}
    numTestCases = 0
    listOfEnvBlocks = []
    listOfSUTActions = []
    mapOfSuppressTransitionVars = {}
    mapOfTransitionQnames = {}
    map_of_transition_modes = {}
    map_transition_modes_to_name = {}
    constraint_dict = {}
    tr_assert_ref_dict = {}
    map_transition_assert = {}

    # Simulation data
    stepsList = []
    markedIndex = 0
    # Replay scenario data
    map_transition_filter = {}

    def __init__(self):
        self.rg_txt = '@startuml\n'
        self.rg_txt += '[*] --> 0\n'
        self.listOfEnvBlocks = []
        self.listOfSUTActions = []
        self.mapOfSuppressTransitionVars = {}
        self.mapOfTransitionQnames = {}
        self.n = PetriNet('issue371')
        self.n.globals["Data"] = Data
        self.n.globals.declare("import json")
        self.n.add_place(Place('Event_0o4qsh5'))
        self.n.add_place(Place('Event_1bks5sc'))
        self.n.place('Event_0o4qsh5').empty()
        self.n.place('Event_0o4qsh5').add(json.dumps({"myField": 0}))
        self.n.add_transition(PrioritizedTransition('Root_T1_default@null@INTERNAL@', 0))
        self.n.add_input('Event_0o4qsh5','Root_T1_default@null@INTERNAL@',Variable('v_Event_0o4qsh5'))
        self.n.add_output('Event_1bks5sc','Root_T1_default@null@INTERNAL@', Expression('Data().execute_Root_T1_default_Event_1bks5sc(json.loads(v_Event_0o4qsh5, object_pairs_hook=Data().int_keys))'))
        self.stepsList.append(self.n.get_marking())
    
    def loadScenario(self, scenario):
        self.map_transition_filter = scenario
        print('[INFO] Loaded scenario with ' + str(len(self.map_transition_filter)) + ' steps.')
        self.gotoMarking(0)
    
    def getCurrentMarking(self):
        # print('[INFO] Current Marking: ', self.n.get_marking())
        return self.n.get_marking()
    
    # Deprecated, use gotoMarking
    def saveMarking(self):
        self.markedIndex = len(self.stepsList) - 1
        print('[INFO] Save petri net marking', self.markedIndex)
    
    # Deprecated, use gotoMarking
    def gotoSavedMarking(self):
        print('[INFO] Setting petri net to saved marking')
        self.gotoMarking(self.markedIndex)
    
    def gotoMarking(self, index):
        print('[INFO] Setting petri net to marking', index)
        self.n.set_marking(self.stepsList[index])
        self.stepsList = self.stepsList[:index + 1]
    
    def fireEnabledTransition(self, choices, cid):
        transition, mode = choices.get(int(cid))
        flow = transition.flow(mode)
        transition.fire(mode)
        # print('[INFO] Transition Fired with ID: ', cid)
        self.stepsList.append(self.n.get_marking())
        return flow
    
    def getEnabledTransitions(self):
        choices = {}
        stepIndex = len(self.stepsList)
        stepFilter = None
        if len(self.map_transition_filter) > 0:
            if str(stepIndex) in self.map_transition_filter:
                stepFilter = self.map_transition_filter[str(stepIndex)]
            else:
                print('[INFO] End of scenario reached at step:', stepIndex)
                return choices
        chidx = 0
        for transition in self.getPNPriorityEnabledTransitions():
            for mode in transition.modes():
                if stepFilter is None or (_key.name == stepFilter['transition'] and _elm.dict() == stepFilter['substitution']):
                    choices[chidx] = transition, mode
                    chidx = chidx + 1
        if stepFilter and (len(choices) == 0):
            print('[ERROR] Scenario step is not available: ', stepIndex)
            raise RuntimeError('Scenario step is not available: ' + str(stepIndex))
        # print('[INFO] Enabled Transition Choices: ', choices)
        return choices
    
    # Only return the enabled transitions with the highest priority
    def getPNPriorityEnabledTransitions(self):
        priority = None
        priorityTransitions = []
        for transition in self.n.transition():
            if transition.modes():
                if priority is None or transition.priority > priority:
                    priority = transition.priority
                    priorityTransitions = []
                if transition.priority == priority:
                    priorityTransitions.append(transition)
        return priorityTransitions
    
    def generateSCN(self, level = 0, visitedT = None, visitedTP = None):
        if self.numTestCases >= 1:
            # print(' [RG-INFO] Max test cases reached! Terminating path.')
            return
        if level > 300:
            self.visitedTList.append(list(visitedT))
            self.visitedTProdList.append(list(visitedTP))
            self.numTestCases = self.numTestCases + 1
            # print(' [RG-INFO] Depth limit reached! Terminating path.')
            return
        if not visitedT:
            visitedT = []
        if not visitedTP:
            visitedTP = []
    
        enabled_transitions = self.getPNPriorityEnabledTransitions()
        if enabled_transitions:
            currM = self.n.get_marking()
            for t in enabled_transitions:
                for m in t.modes():
                    visitedT.append((0,t,m))
                    visitedTP.append(t.flow(m)[1])
                    t.fire(m)
                    self.n.get_marking()
                    self.generateSCN(level + 1, visitedT.copy(), visitedTP.copy())
                    del visitedT[-1]
                    del visitedTP[-1]
                    self.n.set_marking(currM)
        else:
            # print('[RG-INFO] Dead marking found.')
            self.visitedTList.append(list(visitedT))
            self.visitedTProdList.append(list(visitedTP))
            self.numTestCases = self.numTestCases + 1
            return
    
    def generateReachabilityGraph(self, writer, state_space = None, currIndex = 0, level = 0):
        nrOfDependencies = 0
        initial = not state_space
        if initial:
            writer.write('@startuml\n')
            state_space = [self.n.get_marking()]
        elif level > 300:
            writer.write('(%s) #red\n' % (currIndex,))
            print(' [RG-INFO] Depth limit reached! Terminating path.')
            return nrOfDependencies
        elif len(state_space) > 1000:
            writer.write('(%s) #red\n' % (currIndex,))
            print(' [RG-INFO] State-space limit reached! Terminating path.')
            return nrOfDependencies
    
        enabledTransitions = self.getPNPriorityEnabledTransitions()
        if enabledTransitions:
            mark = len([t for t in self.n.transition() if t.modes()]) != len(enabledTransitions)
            currMarking = state_space[currIndex]
            for transition in enabledTransitions:
                transitionLabel = transition.name.split('_default@')[0]
                for mode in transition.modes():
                    transition.fire(mode)
                    nextMarking = self.n.get_marking()
                    if nextMarking in state_space:
                        nextIndex = state_space.index(nextMarking)
                        writer.write('(%s) -%s-> (%s): %s\n' % (currIndex, "[#darkorange]" if mark else "", nextIndex, transitionLabel))
                        nrOfDependencies += 1
                    else:
                        nextIndex = len(state_space)
                        state_space.append(nextMarking)
                        writer.write('(%s) -%s-> (%s): %s\n' % (currIndex, "[#darkorange]" if mark else "", nextIndex, transitionLabel))
                        nrOfDependencies += 1 + self.generateReachabilityGraph(writer, state_space, nextIndex, level + 1)
                    self.n.set_marking(currMarking)
    
        if initial:
            writer.write('title State space: %d nodes and %d edges\n' % (len(state_space), nrOfDependencies))
            writer.write('@enduml\n')
    
        return nrOfDependencies
    
    def initializeTestGeneration(self):
        self.sutVarTransitionMap = {}
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
        # tr_assert_ref_dict = {}
        # map_transition_assert = {}
        self.map_transition_assert = {}
    
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
                _test_scn.generateJSON(i, entry, output_dir=p.tspec_dir)
                _test_scn.generateTSpec(i, pn.sutTypesList, pn.sutVarTransitionMap, pn.mapOfTransitionQnames, output_dir=p.tspec_dir)
                _tests.list_of_test_scn.append(_test_scn)
            i = i + 1
    
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


class PrioritizedTransition(Transition):
    def __init__ (self, name, priority=0, guard=None):
        super().__init__(name, guard)
        self.priority = priority

    def priority(self):
        return self.priority
    
    def copy(self, name=None):
        if name is None:
            name = self.name
        return self.__class__(name, self.priority, self.guard.copy())


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
    pn = issue371Model()
    print("[INFO] Loaded CPN model.")
    # pn.n.draw('net-gv-graph.png')
    s = StateGraph(pn.n)
    # s.build()
    # s.draw('test-gv-graph.png')
    # print(" Finished Generation, writing to file.. ")
    print("[INFO] Starting Reachability Graph Generation")
    # pn.generateScenarios(s,0,[],[],[],0,300)
    sys.setrecursionlimit(400)
    pn.generateSCN()
    print('Num Tests: ', pn.numTestCases)
    print("[INFO] Finished.")
    b = datetime.datetime.now()

    # s.goto(0)
    
    fname = p.plantuml_dir / "rg.plantuml"
    with open(fname, 'w') as f:
        pn.generateReachabilityGraph(f)
        print("[INFO] Created %s" % (fname,))
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
    # simulate(pn.n)
    
    #if not p.no_sim:
    #    print('[SIM] Start Simulation? (Y/N) :')
    #    value = input(" Enter Choice: ")
    #    if value == "Y" or value == "y":
    #        os.system('cls')
    #        simulate(pn.n)
    
    print("[INFO] Exiting..")
