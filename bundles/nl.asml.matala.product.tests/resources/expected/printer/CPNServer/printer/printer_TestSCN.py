import json
import os

# from .printer.printer_types import Types


class Tests:
    list_of_test_scn = []

    def __init__(self):
        self.list_of_test_scn = []

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
                          sort_keys=True, indent=4)


class TestSCN:
    step_list = []
    step_dependencies = []
    map_transition_assert = {}
    constraint_dict = {}
    tr_assert_ref_dict = {}

    def __init__(self, _mapTrAssert, _constraint_dict, _tr_assert_ref_dict):
        self.step_list = []
        self.step_dependencies = []
        self.map_transition_assert = _mapTrAssert
        self.constraint_dict = _constraint_dict
        self.tr_assert_ref_dict = _tr_assert_ref_dict

    def generate_viz(self, idx, output_dir):
        txt = "@startuml\n"
        if len(self.step_list) > 0:
            # txt += "[*] --> %s : x\n" % self.step_list[0].step_name
            for first, second in zip(self.step_list, self.step_list[1:]):
                txt += "%s --> %s : follows\n" % (first.step_name.replace("@","_"), second.step_name.replace("@","_"))
        if len(self.step_dependencies):
            for elm in self.step_dependencies:
                txt += "%s ..> %s : uses\n" % (elm.step_name.replace("@","_"), elm.depends_on.replace("@","_"))
                # txt += "note on link\n"
                # txt += "%s" % elm.payload
                # txt += "\nend note\n"
        txt += "@enduml"

        fname = output_dir / f"scenario{str(idx)}.plantuml"
        os.makedirs(os.path.dirname(fname), exist_ok=True)
        with open(fname, 'w') as f:
            f.write(txt)

    # Deprecated. To be Removed. DB 03.04.2025
    def recurseJson(self, items, prefix):
        txt = ""
        try:
            for jk in items.keys():
                txt += self.recurseJson(items[jk], f"{prefix}.{jk}")
        except:
            match items:
                case str():
                    if ":" in items and not "()" in items:
                        items = items.replace(":", "::")
                    elif "True" in items:
                        items = "true"
                    elif "False" in items:
                        items = "false"
                    else:
                        items = f"\"{items}\""
                case int():
                    items = items
                case list():
                    items = self.updateDict[prefix].strip()
                case _:
                    raise TypeError('Unsupported type')
            txt += f"    {prefix} := {items}\n"
        return txt
    
    def printData(self, idata):
        txt = ""
        for k, v in idata.items():
            txt += "%s : " % k
            j = json.loads(v)
            txt += json.dumps(j, indent=4, sort_keys=False) + "\n"
            # for jk in j.keys():
            #     txt += self.recurseJson(j[jk], "%s.%s" % (k,jk))
        return txt
        
    def generateTSpec(self, idx, sutTypesList, sutVarTransitionMap, transitionQnameMap, output_dir):
        txt = ""
        txt += "import \"printer.ps\"\n\n"
        txt += "using printer.PrintFactoryA3DPrinter.printJob\n"
        txt += "using printer.PrintFactoryA3DPrinter.corrections\n"
        txt += "using printer.PrintFactoryA3DPrinter.printResult\n"
        txt += "using printer.PrintFactoryA3DPrinter.printReport\n"
        txt += "using printer.PrintFactoryA3DPrinter.request\n"
        txt += "using printer.PrintFactoryA3DPrinter.Event_0mxx05p\n"
        txt += "using printer.PrintFactoryA3DPrinter.Event_0jcg6zx\n"
        txt += "using printer.PrintFactoryA3DPrinter.Flow_1u2qmtt\n"
        txt += "using printer.PrintFactoryA3DPrinter.Flow_0iaelzn\n"
        txt += "using printer.PrintFactoryInspection.inspectionJob\n"
        txt += "using printer.PrintFactoryInspection.inspectionReport\n"
        txt += "using printer.PrintFactoryInspection.inspectionResult\n"
        txt += "using printer.PrintFactoryInspection.measureRequest\n"
        txt += "using printer.PrintFactoryInspection.Flow_07l0yyj\n"
        txt += "using printer.PrintFactoryOptimization.optJob\n"
        txt += "using printer.PrintFactoryOptimization.optResult\n"
        txt += "using printer.PrintFactoryOptimization.optimizeJob\n"
        txt += "using printer.PrintFactoryOptimization.Event_1oozdnw\n"
        txt += "using printer.PrintFactoryOptimization.Flow_0y8u5pd\n"
        txt += "using printer.PrintFactoryFactoryAutomation.printRequests\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Gateway_0p2uo9v\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Gateway_1wpvmtk\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_16s4ey1\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_1dcdx0e\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_1dt29vl\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_0kbycuh\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_01m2s0h\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_09b0flo\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_1rkhqnd\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_1vq9t2p\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_0fe8hce\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_1y4bjf4\n"
        txt += "using printer.PrintFactoryFactoryAutomation.Flow_1f74bn4\n"
        txt += "\nabstract-test-definition\n\n"
        txt += "Test-Scenario: S%s\n" % idx
        for step in self.step_list:
            if not step.is_assert:
                name = step.step_name
                idata = step.input_data
                odata = step.output_data
                osuppress = step.output_suppress
                parts = name.split("@")
                new_name = parts[0] + parts[3]
                raw_name = parts[0]
                if "RUN" in parts[2]:
                    type_name = ""
                    if not "null" in parts[1]:
                        type_name = " step-type: \"%s\"" % parts[1] 
                    txt += "\nrun-step-name: %s%s\n" % (new_name, type_name)
                elif "COMPOSE" in parts[2]:
                    txt += "\ncompose-step-name: %s\n" % new_name
                else:
                    type_name = ""
                    if not "null" in parts[1]:
                        type_name = " assert-type: \"%s\"" % parts[1] 
                    txt += "\nassert-step-name: %s%s\n" % (new_name, type_name)
                if parts[0] in transitionQnameMap:
                    qname = transitionQnameMap[parts[0]]
                    txt += "action-case: %s\n" % (qname)
                for elm in self.step_dependencies:
                    if elm.step_name == name:
                        parts = elm.depends_on.split("@")
                        new_name = parts[0] + parts[3]
                        txt += "consumes-from-step: %s { " % new_name
                        for v in elm.var_ref:
                            txt += v + " "
                        # txt += elm.var_ref
                        txt += " }\n"
                txt += "input-binding:\n"
                txt += self.printData(idata)
                isSutVarPresent = False
                for k, v in idata.items():
                    if k in sutVarTransitionMap:
                        for tr in sutVarTransitionMap[k]:
                            if tr == raw_name:
                               isSutVarPresent = True
                    if name.rsplit("_",1)[0] in self.constraint_dict:
                        for constr in self.constraint_dict[name.rsplit("_",1)[0]]:
                            if constr.var_ref == k and constr.dir == "IN":
                                txt += "output-assertion: %s\n" % k
                                for entry in constr.centry:
                                    txt += "%s\n" % entry.name
                txt += "output-data:\n"
                txt += self.printData(odata)
                if osuppress:
                    txt += "suppress(%s)\n" % ", ".join(osuppress)
                for k, v in odata.items():
                    if k in sutVarTransitionMap:
                        for tr in sutVarTransitionMap[k]:
                            if tr == raw_name:
                               isSutVarPresent = True
                    if name.rsplit("_",1)[0] in self.constraint_dict:
                        for constr in self.constraint_dict[name.rsplit("_",1)[0]]:
                            if constr.var_ref == k and constr.dir == "OUT":
                                txt += "data-references: %s\n" % k
                                for entry in constr.centry:
                                    txt += "%s\n" % entry.name
                if name.rsplit("_",1)[0] in self.tr_assert_ref_dict.keys():
                    txt += "output-assertion: %s\n" % new_name
                    txt += "%s\n" % self.tr_assert_ref_dict[name.rsplit("_",1)[0]]
                if isSutVarPresent:
                    txt += "sut-var: { "
                    for _v in sutVarTransitionMap:
                        txt += "%s " % _v
                    txt += " }\n"
            else: # deprecated branch.
                name = step.step_name
                idata = step.input_data
                odata = step.output_data
                # txt += name
                # txt += "input-binding:\n"
                for k, v in idata.items():
                    # txt += "%s : %s\n" % (k, v)
                    if name.rsplit("_", 1)[0] in self.constraint_dict:
                        for constr in self.constraint_dict[name.rsplit("_", 1)[0]]:
                            if constr.var_ref == k and constr.dir == "IN":
                                txt += "\noutput-assertion: %s\n" % k
                                for entry in constr.centry:
                                    txt += "%s : \"%s\"\n" % (entry.name, entry.constr.replace('"','\\"'))
                for k, v in odata.items():
                    # txt += "%s : %s\n" % (k, v)
                    if name.rsplit("_", 1)[0] in self.constraint_dict:
                        for constr in self.constraint_dict[name.rsplit("_", 1)[0]]:
                            if constr.var_ref == k and constr.dir == "OUT":
                                txt += "\ndata-references: %s\n" % k
                                for entry in constr.centry:
                                    txt += "%s : \"%s\"\n" % (entry.name, entry.constr.replace('"','\\"'))
                if name.rsplit("_",1)[0] in self.tr_assert_ref_dict.keys():
                    txt += "output-assertion: %s\n" % new_name
                    txt += "%s\n" % self.tr_assert_ref_dict[name.rsplit("_",1)[0]]
                txt += "\n"
        txt += '\ngenerate-file "./dataset/"\n\n'
        fname = output_dir / f"_scenario{str(idx)}.atspec"
        print(str(fname))
        os.makedirs(os.path.dirname(fname), exist_ok=True)
        with open(fname, 'w') as f:
            f.write(txt)

    def generateJSON(self, idx, scenario, output_dir):
        jsonScenario = {}
        for nr, step in enumerate(scenario):
            jsonScenario[nr + 1] = {
                'transition' : step[1].name,
                'substitution' : step[2].dict()
            }
        fname = output_dir / f"_scenario{str(idx)}.json"
        print(str(fname))
        os.makedirs(os.path.dirname(fname), exist_ok=True)
        with open(fname, 'w') as f:
            f.write(json.dumps(jsonScenario, indent=4))

    def compute_dependencies(self):
        for step in self.step_list:
            idx = self.step_list.index(step)
            preced = [item for i, item in enumerate(self.step_list) if idx < i < len(self.step_list)]
            for elm in preced:
                # print(" SRC-STEP: %s" % step.step_name)
                # print(" DST-STEP: %s" % elm.step_name)
                step_dep = step.compare(elm,self.map_transition_assert)
                if step_dep:
                    self.step_dependencies.append(step_dep)
        # for elm in self.step_dependencies:
        #    print("%s" % elm.step_name)
        #    print("%s" % elm.depends_on)
        #    print("%s" % elm.payload)


class Step:
    step_name = ""
    input_data = {}
    output_data = {}
    output_suppress = []
    is_assert = False

    def __init__(self, _is_assert):
        self.step_name = ""
        self.input_data = {}
        self.output_data = {}
        self.output_suppress = []
        self.is_assert = _is_assert

    def compare(self, _step, mapTrAssert):
        step_dep = StepDependency()
        isMatched = False
        for ipdata in self.output_data:
            if ipdata in self.output_suppress:
                continue
            for opdata in _step.input_data:
                if self.step_name.rsplit('_', 1)[0] in mapTrAssert:
                    if ipdata == opdata and ipdata in mapTrAssert[self.step_name.rsplit('_', 1)[0]]:
                        # print("     Step %s depends on Step %s" % (_step.step_name, self.step_name))
                        # print("     Matched %s - %s" % (ipdata,opdata))
                        if _step.input_data[opdata] == self.output_data[ipdata]:
                            # print("     Payload Matched!")
                            # step_dep = StepDependency()
                            step_dep.step_name = _step.step_name
                            step_dep.depends_on = self.step_name
                            # step_dep.var_ref = ipdata
                            step_dep.var_ref.append(ipdata)
                            step_dep.payload = _step.input_data[opdata]
                            isMatched = True
                            # return step_dep
                        # else:
                        # print("     Payload Not Matched!")
                        # print(_step.input_data[opdata])
                        # print(self.output_data[ipdata])
                        # print("\n")
        if isMatched:
            return step_dep
        else:
            return None


class StepDependency:
    step_name = ""
    depends_on = ""
    var_ref = []
    payload = ""

    def __init__(self):
        self.step_name = ""
        self.depends_on = ""
        self.var_ref = []
        self.payload = ""


class Constraint:
    var_ref = ""
    dir = ""
    centry = []

    def __init__(self, v, d, ce):
        self.var_ref = v
        self.dir = d
        self.centry = ce


class CEntry:
    name = ""
    constr = ""

    def __init__(self, n, c):
        self.name = n
        self.constr = c


