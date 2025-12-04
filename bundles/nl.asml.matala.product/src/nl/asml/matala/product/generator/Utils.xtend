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
import java.util.LinkedHashSet
import java.util.Set
import nl.asml.matala.product.product.Block
import nl.asml.matala.product.product.Blocks
import nl.esi.comma.assertthat.assertThat.DataAssertions
import nl.asml.matala.product.product.DataConstraints
import nl.asml.matala.product.product.DataReferences
import nl.asml.matala.product.product.Function
import nl.asml.matala.product.product.Product
import nl.asml.matala.product.product.RefConstraint
import nl.asml.matala.product.product.Specification
import nl.asml.matala.product.product.SymbConstraint
import nl.asml.matala.product.product.Update
import nl.asml.matala.product.product.UpdateOutVar
import nl.asml.matala.product.product.VarRef
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBulkData
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionGeq
import nl.esi.comma.expressions.expression.ExpressionGreater
import nl.esi.comma.expressions.expression.ExpressionLeq
import nl.esi.comma.expressions.expression.ExpressionLess
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionMaximum
import nl.esi.comma.expressions.expression.ExpressionMinimum
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionModulo
import nl.esi.comma.expressions.expression.ExpressionMultiply
import nl.esi.comma.expressions.expression.ExpressionNEqual
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionUnary
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.Field
import nl.esi.comma.expressions.expression.Variable
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

class Utils 
{
    // Added for Asserts
    dispatch def String printConstraint(DataAssertions ref) {
        return printConstraint(ref.eContainer as Update) + "." + ref.name
    } 

    dispatch def String printConstraint(SymbConstraint sref) {
        return printConstraint(sref.eContainer as DataConstraints) + "." + sref.name
    }   

    dispatch def String printConstraint(RefConstraint ref) {
        return printConstraint(ref.eContainer as DataReferences) + "." + ref.name
    }
    
    dispatch def String printConstraint(DataConstraints ref) {
        return printConstraint(ref.eContainer as VarRef)
    }
    
    dispatch def String printConstraint(DataReferences ref) {
        return printConstraint(ref.eContainer as VarRef)
    }
    
    dispatch def String printConstraint(VarRef ref) {
        return printConstraint(ref.eContainer as UpdateOutVar)
    }
    
    dispatch def String printConstraint(UpdateOutVar ref) {
        return printConstraint(ref.eContainer as Update)
    }
    
    dispatch def String printConstraint(Update ref) {
        return printConstraint(ref.eContainer as Function) + "." + ref.name
    }
    
    dispatch def String printConstraint(Function ref) {
        return printConstraint(ref.eContainer as Block) + "." + ref.name
    }
    
    dispatch def String printConstraint(Variable ref) {
        return printConstraint(ref.eContainer as Block) + "." + ref.name
    }
    
    dispatch def String printConstraint(Block ref) {
        return printConstraint(ref.eContainer as Blocks) + "." + ref.name
    }
    
    dispatch def String printConstraint(Blocks ref) {
        return printConstraint(ref.eContainer as Specification)
    }
    
    dispatch def String printConstraint(Specification ref) {
        return ref.name
    }

    // Expression Parser utils
    def dispatch ArrayList<String> findVariableAssignments(RecordFieldAssignmentAction act) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionVariable v) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionConstantBool b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionConstantInt i) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionConstantReal r) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionConstantString s) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionVector v) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionEnumLiteral e) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionAny e) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionBulkData b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionFunctionCall b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionQuantifier q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionAnd q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionOr q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionEqual q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionNEqual q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionGeq q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionGreater q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionLeq q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionLess q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionAddition q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionSubtraction b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionMultiply b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionDivision b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionMaximum b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionMinimum b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionModulo b) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionPower q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionUnary q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionNot q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionMinus q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionPlus q) {
        return new ArrayList<String>()
    }

    def dispatch ArrayList<String> findVariableAssignments(AssignmentAction act) {
        return findVariableAssignments(act.exp)
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionMapRW m) {
        return findVariableAssignments(m.key)
    }
    
    def dispatch ArrayList<String> findVariableAssignments(ExpressionMap m) {
        var list = new ArrayList<String>()
        for (p : m.pairs) {
            list += findVariableAssignments(p.key)
        }
        return list
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionRecordAccess r) {
        return findVariableAssignments(r.record)
    }

    def dispatch ArrayList<String> findVariableAssignments(ExpressionRecord exp) {
        var list = new ArrayList<String>()
        for (f : exp.fields) {
            var fqname = getFQName(f)
            list += "updateDict[\"" + fqname + "\"] = \"\"\"" + (new ExpressionGenerator).exprToComMASyntax(f.exp) + " \"\"\"\n"
            list += findVariableAssignments(f.exp)
        }
        return list
    }

    def dispatch String getFQName(Field f) {
        return getFQName(f.eContainer) + "." + f.recordField.name
    }

    def dispatch String getFQName(ExpressionRecord e) {
        return getFQName(e.eContainer)
    }

    def dispatch String getFQName(AssignmentAction e) {
        return e.assignment.name
    }   

    def printLists(Product prod) {
        return new ArrayList<String>()
        /* Commented DB. 03.04.2025. 
         * Design Decision: Use JSON Structures and Types information in abstract TSpec to reconstruct ComMA expressions.
         */
//        var list = new ArrayList<String>()
//        list += "updateDict = {}\n"
//        for (updateOutVar :  prod.eAllContents.filter(UpdateOutVar).toIterable) {
//            if (updateOutVar.act !== null) {
//                for (act : updateOutVar.act.actions) {
//                    list += findVariableAssignments(act)
//                }
//            }
//        }
//        return list.join("")
    }

    def usageList(Product prod) {
        var varSet = getUniqueVariables(prod)
        var usings = ""
        for (v : varSet) {
            var blockName = (v.eContainer as Block).name
            usings += "txt += \"using " + prod.specification.name + "." + blockName + "." + v.name + "\\n\"\n"
        }
        return usings
    }

    def getUniqueVariables(Product prod) {
        var Set<Variable> varSet = new LinkedHashSet<Variable>()
        var Set<Variable> varSetUniqueNames = new LinkedHashSet<Variable>()
        for (b : prod.eAllContents.filter(Block).toIterable) {
            varSet.addAll(b.invars)
            varSet.addAll(b.outvars)
            varSet.addAll(b.localvars)
        }
        for (v : varSet) {
            var notInUniqueSet = true
            for (u : varSetUniqueNames) {
                if (v.name.compareToIgnoreCase(u.name) == 0) {
                    notInUniqueSet = false
                }
            }
            if (notInUniqueSet) {
                varSetUniqueNames.add(v)
            }
        }
        return varSetUniqueNames
    }

    // The Python Test Scenario Generator Class
    def generateTestSCNTxt(String name, Product prod, String pSpecFile) {
        return
        '''
        import json
        import os
        
        # from .«prod.specification.name».«name» import Types
        
        
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
                txt += "import \"«pSpecFile»\"\n\n"
                «(new Utils()).usageList(prod)»
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
                    jsonScenario[nr] = {
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
        

        '''
    }
    
    def toTypes(String class_name, ArrayList<String> import_list, HashMap<String,String> var_decl_map) {
        '''
        class Types:
            def __init__(self):
                self.import_list = ["«FOR elm : import_list SEPARATOR ','»«elm»«ENDFOR»"]
                self.var_decl_map = {«FOR k : var_decl_map.keySet SEPARATOR ','»"«k»" : "«var_decl_map.get(k)»"«ENDFOR»}
        '''
    }
    
    def getDataContainerClass(String dataGetterTxt, String methodTxt) 
    {
        // var data_container_class =
        return 
            '''
            import copy
            import json
            
            
            class Data:
                
                @staticmethod
                def int_keys(ordered_pairs):
                    result = {}
                    for key, value in ordered_pairs:
                        try:
                            key = int(key)
                        except ValueError:
                            pass
                        result[key] = value
                    return result
                
                «dataGetterTxt»
                «methodTxt»
            '''
    }


    def generateOnlineMBTController(Product envModel, Product sutModel, 
        IFileSystemAccess2 fsa, IGeneratorContext context
    ) {
        var txt =
        '''
        import asyncio
        import random
        
        from «envModel.specification.name» import «envModel.specification.name»Model
        from «sutModel.specification.name» import «sutModel.specification.name»Model
        
        
        class OnlineMBTController:
        
            async def execute(self, pnMod, is_client):
                dead_marking = False
                while True:
                    if is_client and dead_marking:
                        # item = await self.ni_queue.get()
                        try:
                            item = await asyncio.wait_for(self.ni_queue.get(), timeout=1)
                            print(f' [Test Client] Received Message: {item}')
                            self.cpn.n.place(item[0]).add(item[1])
                            self.ni_queue.task_done()
                        except asyncio.TimeoutError:
                            print(' [INFO] Time-out')
                    elif not is_client and dead_marking:
                        # item = await self.rq_queue.get()
                        try:
                            item = await asyncio.wait_for(self.rq_queue.get(), timeout=1)
                            print(f' [SUT] Received Message: {item}')
                            self.spn.n.place(item[0]).add(item[1])
                            self.rq_queue.task_done()
                        except asyncio.TimeoutError:
                            print(' [INFO] Time-out')
                    else:
                        if is_client:
                            print(' [Test Client] Going to Fire a Transition!')
                        else:
                            print(' [SUT] Going to Fire a Transition!')
                    dead_marking = False
                    enabled_transition_modes = {}
                    for t in pnMod.n.transition():
                        tmodes = t.modes()
                        for mode in tmodes:
                            enabled_transition_modes[t] = tmodes
                    if not enabled_transition_modes:
                        dead_marking = True
                        if is_client:
                            print(' [Test Client] Deadlock Marking Detected! Waiting for Message.. ')
                        else:
                            print(' [SUT] Deadlock Marking Detected! Waiting for Message.. ')
                    choices = {}
                    idx = 0
                    for key, value in enabled_transition_modes.items():
                        for elm in value:
                            choices[idx] = key, elm
                            idx = idx + 1
                    if not dead_marking:
                        value = random.randint(0, idx - 1)
                        if is_client:
                            print(' [Test Client] Selected Transition: ', choices.get(int(value)))
                        else:
                            print(' [SUT] Selected Transition: ', choices.get(int(value)))
                        t, m = choices.get(int(value))
                        t.fire(m)
                        if is_client:
                            print(' [Test Client] Transition Fired! ')
                        else:
                            print(' [SUT] Transition Fired! ')
                        if is_client:
                            for ch in self.ClientToSUTchannels:
                                if not pnMod.n.place(ch).is_empty():
                                    m = pnMod.n.get_marking()
                                    pnMod.n.place(ch).remove(m.get(ch))
                                    print(' [Test Client] Sent Request')
                                    await self.rq_queue.put((ch, m.get(ch)))
                        else:
                            for ch in self.SUTToClientchannels:
                                if not pnMod.n.place(ch).is_empty():
                                    m = pnMod.n.get_marking()
                                    pnMod.n.place(ch).remove(m.get(ch))
                                    print(' [SUT] Sent Notification')
                                    await self.ni_queue.put((ch, m.get(ch)))
        
            def __init__(self):
                self.rq_queue = asyncio.Queue(maxsize=2)  # single input queue
                self.ni_queue = asyncio.Queue(maxsize=2)  # single output queue
                self.cpn = «envModel.specification.name»Model()  # for each client component
                self.spn = «sutModel.specification.name»Model()  # for each SUT
                print(" [INFO] Loaded CPN models and Initialized Queues.")
                cIntfP = self.cpn.determineInterfacePlaces()  # create set, by iterating over each client component
                sIntfP = self.spn.determineInterfacePlaces()  # create set, by iterating over each SUT component
                # From the point of view of SUT
                self.SUTToClientchannels = [x for x in cIntfP.input if
                                            x in sIntfP.output]  # find common places between client and SUT
                self.ClientToSUTchannels = [x for x in cIntfP.output if
                                            x in sIntfP.input]  # find common places between client and SUT
        
            async def run(self):
                await asyncio.gather(self.execute(self.spn, False),
                                     self.execute(self.cpn, True))
        
        
        if __name__ == '__main__':
            asyncio.run(OnlineMBTController().run())
        '''
        fsa.generateFile('OnlineMBT_Controller.py', txt)
    }

//  /* TODO Is this deprecated? Who is using this? Commented DB 16.03.2025 */
//  def Map<String,String> recurseTypes(Type typ) {
//      var constructors = newLinkedHashMap() 
//      var typ2 = typ.type
//      if (typ instanceof VectorTypeConstructor) {
//          if (!typ2.name.equalsIgnoreCase("string")) {
//              if (typ.eContainer instanceof RecordField) {
//                  var field = (typ.eContainer as RecordField).name
//                  var key = typ2.name
//                  constructors.put(key, field)
//              }
//          }
//      }
//      if (typ2 instanceof RecordTypeDecl) {
//          for (f : (typ2 as RecordTypeDecl).fields) {
//              constructors.putAll(recurseTypes(f.type))
//          }
//      }
//      return constructors
//  }
}