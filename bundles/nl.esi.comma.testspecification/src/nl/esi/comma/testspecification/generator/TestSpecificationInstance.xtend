package nl.esi.comma.testspecification.generator

import java.util.HashMap
import java.util.ArrayList
import java.util.List
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import java.util.regex.Pattern
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.actions.actions.AssignmentAction
import java.util.HashSet
import nl.esi.comma.testspecification.generator.utils.KeyValue
import nl.esi.comma.testspecification.generator.utils.ExpressionsParser
import nl.esi.comma.testspecification.generator.utils.Step

class TestSpecificationInstance {
    // In-Memory Data Structures corresponding *.tspec (captured in resource object)
    public var mapLocalDataVarToDataInstance = new HashMap<String, List<String>>
    public var mapLocalStepInstance = new HashMap<String, List<String>>
    public var mapLocalSUTVarToDataInstance = new HashMap<String, List<String>>
    public var mapDataInstanceToFile = new HashMap<String, List<String>>
    public var mapSUTInstanceToFile = new HashMap<String, List<String>>
    public var listStepInstances = new ArrayList<Step>

    public var title = new String
    public var testpurpose = new String
    public var background = new String
    public var stakeholders = new ArrayList<String>

    new() {
    }

    def addMapSUTInstanceToFile(String key, String value) {
        if (mapSUTInstanceToFile.containsKey(key))
            mapSUTInstanceToFile.get(key).add(value)
        else {
            mapSUTInstanceToFile.put(key, new ArrayList)
            mapSUTInstanceToFile.get(key).add(value)
        }
    }

    def addMapDataInstanceToFile(String key, String value) {
        if (mapDataInstanceToFile.containsKey(key))
            mapDataInstanceToFile.get(key).add(value)
        else {
            mapDataInstanceToFile.put(key, new ArrayList)
            mapDataInstanceToFile.get(key).add(value)
        }
    }

    def addMapLocalSUTVarToDataInstance(String key, String value) {
        if (mapLocalSUTVarToDataInstance.containsKey(key))
            mapLocalSUTVarToDataInstance.get(key).add(value)
        else {
            mapLocalSUTVarToDataInstance.put(key, new ArrayList)
            mapLocalSUTVarToDataInstance.get(key).add(value)
        }
    }

    def addMapLocalStepInstance(String key, String value) {
        if (mapLocalStepInstance.containsKey(key))
            mapLocalStepInstance.get(key).add(value)
        else {
            mapLocalStepInstance.put(key, new ArrayList)
            mapLocalStepInstance.get(key).add(value)
        }
    }

    def addMapLocalDataVarToDataInstance(String key, String value) {
        if (mapLocalDataVarToDataInstance.containsKey(key))
            mapLocalDataVarToDataInstance.get(key).add(value)
        else {
            mapLocalDataVarToDataInstance.put(key, new ArrayList)
            mapLocalDataVarToDataInstance.get(key).add(value)
        }
    }

    def getExtensions(String varName, boolean addRefToJson) {
        var mapListOfKeyValue = new HashMap<String, List<KeyValue>>
        // System.out.println(" Getting Extension for Variable: " + varName)
        for (step : listStepInstances) {
            if (step.variableName.equals(varName)) {
                // System.out.println("STEP ID: " + step.id)
                // Note DB: Incomplete implementation. Decision to avoid duplicate keys in front end. 
                // Decision: If an attribute of record needs references and concrete data, then do everything in the reference part. 
                // combineKeys(step.parameters)
                mapListOfKeyValue.put(step.id, step.parameters)
                if (!step.stepRefs.empty && addRefToJson) {
                    // System.out.println("Adding Step Reference for "+ step.id)
                    // Added DB: add reference to explicit JSON file
                    for (sr : step.stepRefs) {
                        var kv = new KeyValue
                        kv.key = sr.variableName
                        kv.value = '"' + sr.inputFile + sr.variableName + "_" + sr.recordExp + ".json" + '"'
                        kv.refVal = new HashSet<String>
                        kv.refVal.add('"' + sr.inputFile + '"')
                        mapListOfKeyValue.get(step.id).add(kv)
                    }
                }
            // return step.parameters
            }
        }
        /*for(k : mapListOfKeyValue.keySet) {
         *     System.out.println(" ++ KEY : " + k)
         *     for(elm : mapListOfKeyValue.get(k)) {
         *         System.out.println(" ++ Value : " + elm.key + " -> " + elm.value)
         *     }
         }*/
        // System.out.println(" Extension: " + mapListOfKeyValue)
        return mapListOfKeyValue // new ArrayList<KeyValue>
    }

    def String getStepInstanceFileName(String step_id) {
        for (elm : listStepInstances) {
            if (elm.id.equals(step_id)) {
                return elm.inputFile
            }
        }
        return new String
    }

    def String getFileName(String varName) {
        for (step : listStepInstances) {
            if (step.variableName.equals(varName)) {
                return step.inputFile.replaceAll(".json", "_" + step.id + ".json")
            }
        }
        for (key : mapDataInstanceToFile.keySet) {
            if (key.equals(varName)) {
                return mapDataInstanceToFile.get(key).head
            }
        }
        for (key : mapSUTInstanceToFile.keySet) {
            var fname = mapSUTInstanceToFile.get(key).head
            // System.out.println("Checking: " + fname + " map key entry: " + key)
            if (key.equals(varName)) {
                return fname
            }
        }
        return "undefined.json"
    }

    // Added DB: get contents for explicit JSON file generation
    def getRefExtensions(String varName) {
        var mapListOfKeyValue = new HashMap<String, List<KeyValue>>
        for (step : listStepInstances) {
            if (step.variableName.equals(varName)) {
                if (!step.stepRefs.empty) {
                    for (sr : step.stepRefs) {
                        mapListOfKeyValue.put(sr.inputFile + sr.variableName + "_" + sr.recordExp + ".json",
                            sr.parameters)
                    }
                }
            }
        }
        return mapListOfKeyValue
    }

    def String getFileExtension(String varName) {
        for (step : listStepInstances) {
            if (step.variableName.equals(varName))
                return step.inputFile
        }
        return new String
    }

    // Expression Handler //
    def dispatch KeyValue generateInitAssignmentAction(AssignmentAction action) {
        var mapLHStoRHS = new KeyValue // HashMap<String,String>
        mapLHStoRHS.key = action.assignment.name
        mapLHStoRHS.value = ExpressionsParser::generateExpression(action.exp, '''''').toString
        /*if(mapLHStoRHS.value.contains('''platform:''') || mapLHStoRHS.value.contains('''setup.suts''')) 
         *     {
         *         System.out.println(" DETECTED PLATFORM: " + mapLHStoRHS.value)
         *         mapLHStoRHS.value = mapLHStoRHS.value.replaceAll("^\"|\"$", "")
         *         
         }*/
        // replace references to global variables with FAST syntax
        for (elm : mapLocalDataVarToDataInstance.keySet) {
            if (mapLHStoRHS.value.contains(elm)) {
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm, "global.params['" + elm + "']")
            }
        }
        return mapLHStoRHS
    }

    def dispatch KeyValue generateInitAssignmentAction(RecordFieldAssignmentAction action) {
        return generateInitRecordAssignment(action.fieldAccess as ExpressionRecordAccess, action.exp, '''''')
    }

    def generateInitRecordAssignment(ExpressionRecordAccess eRecAccess, Expression exp, CharSequence ref) {
        var mapLHStoRHS = new KeyValue

        var record = eRecAccess.record
        var field = eRecAccess.field
        var recExp = ''''''

        while (! (record instanceof ExpressionVariable)) {
            if (recExp.empty)
                recExp = '''«(record as ExpressionRecordAccess).field.name»'''
            else
                recExp = '''«(record as ExpressionRecordAccess).field.name».''' + recExp
            record = (record as ExpressionRecordAccess).record
        }
        // System.out.println(" DEBUG: " + recExp)
        // val varExp = record as ExpressionVariable
        mapLHStoRHS.key = field.name
        mapLHStoRHS.value = ExpressionsParser::generateExpression(exp, ref).toString
        mapLHStoRHS.refVal.add(mapLHStoRHS.value) // Added DB 14.10.2024
        // modify key value data structure to JSON
        /*mapLHStoRHS.value = mapLHStoRHS.value.replaceAll("\"key\" : ","")
         * mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(", \"value\"","")      
         * // check references to SUT and replace with FAST syntax
         * for(elm : mapLocalSUTVarToDataInstance.keySet) {
         *     if(mapLHStoRHS.value.contains(elm+"."))
         *         mapLHStoRHS.value = mapLHStoRHS.value.replaceFirst(elm, "setup.suts['" + elm + "']")
         }*/
        // check references to Step outputs and replace with FAST syntax
        for (elm : mapLocalStepInstance.keySet) {
            if (mapLHStoRHS.value.contains(elm + ".output")) {
                // mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm+".output", "steps.out['" + "_" + elm + "']") // commented 26.11.2024
                // Added REGEX 26.11.2024: remove (x) after steps.out[step.params[....]].x.y.... (assumption, always a y is present)
                // In BPMN4S model, x represents the container of output data. So we need to filter it out for FAST. 
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm + ".output" + "\\.(.*?)\\.",
                    "steps.out[step.params['" + "_" + elm + "']].")
                // System.out.println("DEBUG XY: " + mapLHStoRHS.value)
                mapLHStoRHS.refKey.add(elm) // reference to step
                // Custom String Updates for FAST Syntax Peculiarities! TODO investigate solution?
                // map-var['key'] + "[0]" -> map-var['key'][0] 
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(Pattern.quote("] + \"["), "][") // ("\\] + \"\\[","\\]\\[")
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll("\\]\"", "]")
            }
        }
        // replace references to global variables with FAST syntax
        for (elm : mapLocalDataVarToDataInstance.keySet) {
            if (mapLHStoRHS.value.contains(elm)) {
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm, "global.params['" + elm + "']")
            }
        }
        // name of variable instance: varExp.variable.name
        return mapLHStoRHS
    }

    // End Expression Handler //
    def generateFASTScenarioFile() {
        var txt = '''
            in.data.global_parameters = {
                «FOR key : mapLocalDataVarToDataInstance.keySet SEPARATOR ','»
                    "«key»" : «mapLocalDataVarToDataInstance.get(key).head»
                «ENDFOR»
            }
            
            in.data.suts = [
                «FOR elm : mapLocalSUTVarToDataInstance.keySet SEPARATOR ','»
                    «mapLocalSUTVarToDataInstance.get(elm).head»
                «ENDFOR»
            ]
            
            in.data.steps = [
                «FOR elm : listStepInstances SEPARATOR ','»
                    «IF generateFASTRefStepTxt(elm).empty»
                        { "id" : "«elm.id»", "type" : "«elm.type.replaceAll("_dot_",".")»", "input_file" : "«elm.inputFile»" }
                    «ELSE»
                        { "id" : "«elm.id»", "type" : "«elm.type.replaceAll("_dot_",".")»", "input_file" : "«elm.inputFile»",
                            "parameters" : {
                                «FOR refTxt : generateFASTRefStepTxt(elm) SEPARATOR ','»
                                    «refTxt»
                                «ENDFOR»
                            } 
                        }
                    «ENDIF»
                «ENDFOR»
            ]
        '''
        return txt
    }

    def generateFASTRefStepTxt(Step step) {
        var refTxt = new ArrayList<CharSequence>
        var refKeyList = new HashSet<String>
        for (kv : step.parameters) {
            for (rk : kv.refKey) {
                if (!refKeyList.contains(rk)) {
                    refTxt.add('''"_«rk»" : "«rk»"''')
                    refKeyList.add(rk)
                }
            }
        }
        return refTxt
    }

    // function to combine keys (parameters of step may have duplicate keys) //
    // Note DB: Incomplete implementation. Decision to avoid duplicate keys in front end. 
    // Decision: If an attribute of record needs references and concrete data, then do
    // everything in the reference part. 
    def combineKeys(List<KeyValue> parameters) {
        var _parameters = new ArrayList<KeyValue>
        var listOfExclusionKeys = new ArrayList<String>
        for (kv : parameters) {
            if (!listOfExclusionKeys.contains(kv.key)) {
                var commonKV = new ArrayList<KeyValue>
                for (_kv : parameters) {
                    if (kv.key.equals(_kv.key)) {
                        commonKV.add(_kv)
                    }
                }
                if (commonKV.size > 1) {
                    System.out.println("***** COMMON KEYS ******")
                    for (elmKV : commonKV) {
                        elmKV.display
                    }
                    System.out.println("***** *********** ******")
                } else {
                    _parameters.addAll(commonKV)
                }
            }
            listOfExclusionKeys.add(kv.key)
        }
    }

    def displayParseResults() {
        System.out.println(" ---- Map Data Instance To File ---- ")
        for (key : mapDataInstanceToFile.keySet) {
            System.out.println("    Key: " + key + " Value: " + mapDataInstanceToFile.get(key))
        }

        System.out.println(" ---- Map SUT Instance To File ---- ")
        for (key : mapSUTInstanceToFile.keySet) {
            System.out.println("    Key: " + key + " Value: " + mapSUTInstanceToFile.get(key))
        }

        System.out.println(" ---- Map Local Data Var To Data Instance ---- ")
        for (key : mapLocalDataVarToDataInstance.keySet) {
            System.out.println("    Key: " + key + " Value: " + mapLocalDataVarToDataInstance.get(key))
        }

        System.out.println(" ---- Map SUT Var To Data Instance ---- ")
        for (key : mapLocalSUTVarToDataInstance.keySet) {
            System.out.println("    Key: " + key + " Value: " + mapLocalSUTVarToDataInstance.get(key))
        }

        System.out.println(" ---- Map Step Instance ---- ")
        for (key : mapLocalStepInstance.keySet) {
            System.out.println("    Key: " + key + " Value: " + mapLocalStepInstance.get(key))
        }

        System.out.println(" ------------------ STEPS ------------------")
        for (st : listStepInstances) {
            st.display
//          System.out.println("    step-id: " + st.id + " type: " + st.type)
//          System.out.println("    input: " + st.inputFile)
//          System.out.println("    var: " + st.variableName)
//          for(param : st.parameters) 
//              param.display
        // System.out.println("  parameters: " + param.key + " -> " + param.value)
        }
    }

}
