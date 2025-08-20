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
package nl.esi.comma.testspecification.generator.to.fast

import java.util.ArrayList
import java.util.Arrays
import java.util.HashMap
import java.util.HashSet
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import java.util.regex.Pattern
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.inputspecification.inputSpecification.APIDefinition
import nl.esi.comma.inputspecification.inputSpecification.Main
import nl.esi.comma.testspecification.generator.to.docgen.DocGen
import nl.esi.comma.testspecification.generator.utils.JSONData
import nl.esi.comma.testspecification.generator.utils.KeyValue
import nl.esi.comma.testspecification.generator.utils.Step
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import nl.esi.comma.actions.actions.Action
import nl.esi.comma.expressions.expression.ExpressionNullLiteral

class FromConcreteToFast extends AbstractGenerator {
    
    val Map<String, String> rename = new HashMap<String, String>()
    val Map<String, String> args = new HashMap<String, String>()

    new (){ 
        
    }
    
    new(Map<String, String> rename, Map<String, String> params) {
        this.rename = rename
        this.args = params
    }
    
    /* TODO this should come from project task? Investigate and Implement it. */
    var record_path_for_lot_def = "ReferenceFabModelTWINSCANtooladapterandSUTTWINSCANSUTExposeInput.twinscan_expose_input.lot_definition"
    var record_lot_def_file_name = "lot_definition"

    var record_path_for_job_def = "ReferenceFabModelYieldStartooladapterandSUTRUNYSMeasureInput.yieldstar_measure_input.job_definition"
    var record_job_def_file_name = "job_definition"

    // In-Memory Data Structures corresponding *.tspec (captured in resource object)
    var mapLocalDataVarToDataInstance = new HashMap<String, List<String>>
    var mapLocalStepInstance = new HashMap<String, List<String>>
    var mapLocalSUTVarToDataInstance = new HashMap<String, List<String>>
    var mapDataInstanceToFile = new HashMap<String, List<String>>
    var mapSUTInstanceToFile = new HashMap<String, List<String>>
    var listStepInstances = new ArrayList<Step>
    

    // On save of TSPEC file, this function is called by Eclipse Framework
    override void doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        mapLocalDataVarToDataInstance = new HashMap<String, List<String>>
        mapLocalStepInstance = new HashMap<String, List<String>>
        mapLocalSUTVarToDataInstance = new HashMap<String, List<String>>
        mapDataInstanceToFile = new HashMap<String, List<String>>
        mapSUTInstanceToFile = new HashMap<String, List<String>>
        listStepInstances = new ArrayList<Step>

        val ctd = res.contents.filter(TSMain).map[model].filter(TestDefinition).head
        if (ctd === null) {
            throw new Exception('No concrete tspec found in resource: ' + res.URI)
        }

        generateContents(res, fsa) // Parsing and File Generation
    }

    // Generate data.kvp and referenced JSON files
    def private generateContents(Resource res, IFileSystemAccess2 fsa) {
        val modelInst = res.contents.head as TSMain
        var testDefFilePath = new String

        // Process TSPEC Imports.
        for (imp : modelInst.imports) {
            val inputResource = imp.resource
            var input = inputResource.contents.head
            if (input instanceof Main) {
                if (input.model instanceof APIDefinition) {
                    val apidef = input.model as APIDefinition
                    for (api : apidef.apiImpl) {
                        for (elm : api.di)
                            addMapDataInstanceToFile(elm.^var.name, api.path + elm.fname)
                    }
                } else {
                    System.out.println("Error: Unhandled Model Type! ")
                }
            }
        }

        // Parse TSPEC Test Definition
        val model = modelInst.model
        if (model instanceof TestDefinition) {
            var String path_prefix = model.filePath
            testDefFilePath = model.filePath
            // for(gpars : model.gparams) { addMapLocalDataVarToDataInstance(gpars.name, new String) }
            for (steppars : model.stepparams) {
                addMapLocalStepInstance(steppars.name, steppars.type.type.name)
            }
            // for(sutpars : model.sutparams) { addMapLocalSUTVarToDataInstance(sutpars.name, new String) }
            for (act : model.gparamsInitActions) {
                var mapLHStoRHS = generateInitAssignmentAction(act)
                addMapLocalDataVarToDataInstance(mapLHStoRHS.key, mapLHStoRHS.value)
            }
            for (act : model.sutInitActions) {
                var mapLHStoRHS = generateInitAssignmentAction(act)
                addMapLocalSUTVarToDataInstance(mapLHStoRHS.key, mapLHStoRHS.value)
            }

            // Parse Step Sequence
            val stepSequence = getStepSequence(model)
            for (s : stepSequence) {
                var stepInst = new Step
                stepInst.id = s.inputVar.name // stepVar.name // was identifier
                stepInst.type = s.type.name
                stepInst.inputFile = mapDataInstanceToFile.get(s.stepVar.name).head
                // check if additional data was specified in a step
                for (ref : s.refStep) {
                    // if(s.input!==null) {
                    for (act : ref.input.actions) {
                        if (isPrintableAssignment(act)) {
                            var mapLHStoRHS = generateInitAssignmentAction(act)
                            var lhs = getLHS(act) // note key = record variable, and value = recExp
                            stepInst.variableName = lhs.key // Note DB: This is the same for all actions
                            stepInst.recordExp = lhs.value // Note DB: This keeps overwriting (record prefix)
                            /*System.out.println("DEBUG LHS.KEY: " + lhs.key)
                             * System.out.println("DEBUG LHS.VALUE: " + lhs.value)
                             * System.out.println("DEBUG MAP LHStoRHS: ")
                             mapLHStoRHS.display*/
                            // System.out.println("DEBUG: " + record_path_for_lot_def)
                            if (record_path_for_lot_def.equals(lhs.value) ||
                                record_path_for_lot_def.endsWith(lhs.value)) {
                                if (stepInst.isStepRefPresent(lhs.value)) {
                                    var refStep = stepInst.getStepRefs(lhs.value)
                                    refStep.parameters.add(mapLHStoRHS)
                                // stepInst.stepRefs.add(refStep)
                                } else {
                                    // Create new step instance and fill all details there
                                    // Add to list of step reference of step
                                    var rstepInst = new Step
                                    rstepInst.id = lhs.value
                                    rstepInst.type = s.type.name
                                    rstepInst.inputFile = path_prefix
                                    rstepInst.variableName = record_lot_def_file_name
                                    rstepInst.recordExp = stepInst.id
                                    rstepInst.parameters.add(mapLHStoRHS) // Added DB 29.05.2025
                                    stepInst.stepRefs.add(rstepInst)
                                }
                            } else if (record_path_for_job_def.equals(lhs.value) ||
                                record_path_for_job_def.endsWith(lhs.value)) {
                                if (stepInst.isStepRefPresent(lhs.value)) {
                                    var refStep = stepInst.getStepRefs(lhs.value)
                                    refStep.parameters.add(mapLHStoRHS)
                                // stepInst.stepRefs.add(refStep)
                                } else {
                                    // Create new step instance and fill all details there
                                    // Add to list of step reference of step
                                    var rstepInst = new Step
                                    rstepInst.id = lhs.value
                                    rstepInst.type = s.type.name
                                    rstepInst.inputFile = path_prefix
                                    rstepInst.variableName = record_job_def_file_name
                                    rstepInst.recordExp = stepInst.id
                                    rstepInst.parameters.add(mapLHStoRHS) // Added DB 29.05.2025
                                    stepInst.stepRefs.add(rstepInst)
                                }
                            } else {
                                stepInst.parameters.add(mapLHStoRHS)
                            }
                        }
                    }
                }
                // stepInst.display
                listStepInstances.add(stepInst)
            }
            // generate vfd XML file
            fsa.generateFile(testDefFilePath + '/variants/single_variant/' + "vfd.xml", (new VFDXMLGenerator(this.args, this.rename)).generateXMLFromSUTVars(model))
            fsa.generateFile(testDefFilePath + '/variants/single_variant/' + "reference.kvp", (new RefKVPGenerator()).generateRefKVP(model))
        }

        // update step file names based on checking if additional data was specified. 
        for (step : listStepInstances) {
            if (!step.parameters.isEmpty) {
                step.inputFile = step.inputFile.replaceFirst("[^/]+\\.json$", step.id + ".json")
            }
        }

        // Turn off during production!
        displayParseResults

        // generate data.kvp file
        fsa.generateFile(testDefFilePath + '/variants/single_variant/' + "data.kvp", generateFASTScenarioFile)
        /* Added DB: 12.05.2025. Support PlantUML Generation for Review */
        fsa.generateFile(testDefFilePath + '/variants/single_variant/' + "viz.plantuml",
            (new DocGen).generatePlantUMLFile(listStepInstances, new HashMap<String, List<String>>))

        // Generate JSON data files and vfd.xml
        generateJSONDataAndVFDFiles(testDefFilePath, fsa, modelInst)
    }
    
    def boolean isPrintableAssignment(Action act) {
        return switch (act) {
        	AssignmentAction: !(act.exp instanceof ExpressionNullLiteral) 
        	RecordFieldAssignmentAction: !(act.exp instanceof ExpressionNullLiteral)
        	default: false
        }
    }

    def private getStepSequence(TestDefinition td) {
        var listStepSequence = new ArrayList<RunStep>
        if (td.testSeq.empty) {
            for (ss : td.stepSeq) {
                for (step : ss.step.filter(RunStep))
                    listStepSequence.add(step)
            }
        } else {
            for (ts : td.testSeq) {
                for (ss : ts.stepSeqRef) {
                    for (step : ss.step.filter(RunStep))
                        listStepSequence.add(step)
                }
            }
        }
        return listStepSequence
    }

    def private dispatch KeyValue getLHS(AssignmentAction action) {
        var kv = new KeyValue
        kv.key = action.assignment.name
        kv.value = new String
        return kv
    }

    def private dispatch KeyValue getLHS(RecordFieldAssignmentAction action) {
        return getLHSRecAssignment(action.fieldAccess as ExpressionRecordAccess, action.exp)
    }

    def private KeyValue getLHSRecAssignment(ExpressionRecordAccess eRecAccess, Expression exp) {
        var record = eRecAccess.record
        var recExp = ''''''

        while (! (record instanceof ExpressionVariable)) {
            if(recExp.
                empty) recExp = '''«(record as ExpressionRecordAccess).field.name»''' else recExp = '''«(record as ExpressionRecordAccess).field.name».''' +
                recExp
            record = (record as ExpressionRecordAccess).record
        }
        // System.out.println("DEBUG: " + recExp)
        val varExp = record as ExpressionVariable
        var kv = new KeyValue
        kv.key = varExp.variable.name
        kv.value = recExp
        return kv
    }

    // Expression Handler //
    def private dispatch KeyValue generateInitAssignmentAction(AssignmentAction action) {
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

    def private dispatch KeyValue generateInitAssignmentAction(RecordFieldAssignmentAction action) {
        return generateInitRecordAssignment(action.fieldAccess as ExpressionRecordAccess, action.exp, '''''')
    }

    def private generateInitRecordAssignment(ExpressionRecordAccess eRecAccess, Expression exp, CharSequence ref) {
        var mapLHStoRHS = new KeyValue

        var record = eRecAccess.record
        var field = eRecAccess.field
        var recExp = ''''''

        while (! (record instanceof ExpressionVariable)) {
            if(recExp.
                empty) recExp = '''«(record as ExpressionRecordAccess).field.name»''' else recExp = '''«(record as ExpressionRecordAccess).field.name».''' +
                recExp
            record = (record as ExpressionRecordAccess).record
        }
        // tracking fully-qualified field name 
        mapLHStoRHS.key = '''«recExp».''' + field.name
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
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm + "\\.output" + "\\.(.*?)\\.",
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
    def private addMapSUTInstanceToFile(String key, String value) {
        if (mapSUTInstanceToFile.containsKey(key))
            mapSUTInstanceToFile.get(key).add(value)
        else {
            mapSUTInstanceToFile.put(key, new ArrayList)
            mapSUTInstanceToFile.get(key).add(value)
        }
    }

    def private addMapDataInstanceToFile(String key, String value) {
        if (mapDataInstanceToFile.containsKey(key))
            mapDataInstanceToFile.get(key).add(value)
        else {
            mapDataInstanceToFile.put(key, new ArrayList)
            mapDataInstanceToFile.get(key).add(value)
        }
    }

    def private addMapLocalSUTVarToDataInstance(String key, String value) {
        if (mapLocalSUTVarToDataInstance.containsKey(key))
            mapLocalSUTVarToDataInstance.get(key).add(value)
        else {
            mapLocalSUTVarToDataInstance.put(key, new ArrayList)
            mapLocalSUTVarToDataInstance.get(key).add(value)
        }
    }

    def private addMapLocalStepInstance(String key, String value) {
        if (mapLocalStepInstance.containsKey(key))
            mapLocalStepInstance.get(key).add(value)
        else {
            mapLocalStepInstance.put(key, new ArrayList)
            mapLocalStepInstance.get(key).add(value)
        }
    }

    def private addMapLocalDataVarToDataInstance(String key, String value) {
        if (mapLocalDataVarToDataInstance.containsKey(key))
            mapLocalDataVarToDataInstance.get(key).add(value)
        else {
            mapLocalDataVarToDataInstance.put(key, new ArrayList)
            mapLocalDataVarToDataInstance.get(key).add(value)
        }
    }

    def private generateJSONDataAndVFDFiles(String testDefFilePath, IFileSystemAccess2 fsa, TSMain modelInst) {
        var txt = ''''''
        var listOfStepVars = new HashSet<String>
        // val modelInst = _resource.contents.head as TSMain
        // NOTE. Assumption is that steps are populated.
        for (step : listStepInstances) {
            listOfStepVars.add(step.variableName)
        }
        // Process TSPEC Imports and parse them
        for (imp : modelInst.imports) {
            val inputResource = imp.resource
            var input = inputResource.contents.head
            var JSONDataFileContents = new ArrayList<JSONData>
            if (input instanceof Main) {
                if (input.model instanceof APIDefinition) {
                    val apiDef = input.model as APIDefinition
                    var dataInst = new JSONData
                    for (act : apiDef.initActions) {
                        if (act instanceof AssignmentAction || act instanceof RecordFieldAssignmentAction) {
                            var mapLHStoRHS = generateInitAssignmentAction(act)
                            listOfStepVars.remove(mapLHStoRHS.key) // variable is initialized in param file
                            dataInst.getKvList.add(mapLHStoRHS)
                        }
                    }
                    // dataInst.display
                    JSONDataFileContents.add(dataInst)
                }
            }

            // Merge Contents and Generate JSON File //
            // ASSUMPTION: Data Extensions on Record Fields of Steps API should not overlap 
            // with their initialization in *.params, i.e. should not init same record field. 
            for (dataInst : JSONDataFileContents) {
                for (mapLHStoRHS : dataInst.kvList) {
                    // System.out.println("Checking " + mapLHStoRHS.key)
                    var mapLHStoRHS_ = getExtensions(mapLHStoRHS.key)
                    // System.out.println(" Got Extension for Key: " + mapLHStoRHS.key)
                    /*for(elm: mapLHStoRHS_.keySet) { 
                     *     System.out.println("    K: " + elm)
                     *     for(kv : mapLHStoRHS_.get(elm))
                     *         System.out.println("    k: " + kv.key + "   v : " + kv.value)
                     }*/
                    // elm.display
                    // check that mapLHStoRHS_ is not empty => get file name from step instance list
                    // else call function to get file name
                    // Reason: 
                    // the map data structure SUT to File name, 
                    // does not consider new data files due to data extension in steps 
                    var String fileName = new String

                    if (!mapLHStoRHS_.isEmpty) {
                        for (stepId : mapLHStoRHS_.keySet) {
                            fileName = getStepInstanceFileName(stepId)
                            var fileContents = mapLHStoRHS.value
                            System.out.println("Generating File: " + fileName + " For Step: " + stepId)
                            var refinedMapLHStoRHS = refineListLHStoRHS(mapLHStoRHS_.get(stepId))
                            fileContents = printRefinedMap(refinedMapLHStoRHS)
                            fsa.generateFile(fileName, fileContents)
                        }
                    } else {
                        System.out.println("Warning: Variable " + mapLHStoRHS.key +
                            " defined in param but not used in TSpec!")
                        fileName = getFileName(mapLHStoRHS.key)
                        fsa.generateFile(fileName, mapLHStoRHS.value)
                    }
                }
                dataInst.display
            }
        }
        // if var in params file does not have a constructor init
        // but occurs in tspec ==> create data files per step input def.
        // TODO. Make this the only way to generate JSON, i.e. remove previous file generation 
        // Prevent variable init in params file. 
        for (vname : listOfStepVars) {
            // System.out.println(" variable not declared in params: " + vname)
            // for(step : listStepInstances) {
            // if(step.variableName.equals(vname)) {
            var mapLHStoRHS_ = getExtensions(vname) // step.variableName
            /*for(elm: mapLHStoRHS_.keySet) { 
             *             System.out.println("    VAR: " + elm)
             *             for(kv : mapLHStoRHS_.get(elm))
             *                 System.out.println("    k: " + kv.key + "   v : " + kv.value)
             }*/
            var String fileName = new String
            var fileContents = ''''''
            if (!mapLHStoRHS_.isEmpty) {
                for (stepId : mapLHStoRHS_.keySet) {
                    fileName = getStepInstanceFileName(stepId)
                    System.out.println("Generating File: " + fileName + " For Step: " + stepId)
                    var refinedMapLHStoRHS = refineListLHStoRHS(mapLHStoRHS_.get(stepId))
                    fileContents = printRefinedMap(refinedMapLHStoRHS)
                    fsa.generateFile(fileName, fileContents)
                    fileContents = ''''''
                }
            }

            // Added 09.11.2024 DB: generate explicit JSON files referenced before 
            var mapLHStoRHSExt = getRefExtensions(vname)
            var String fileNameExt = new String
            var fileContentsExt = ''''''
            if (!mapLHStoRHSExt.isEmpty) {
                for (stepId : mapLHStoRHSExt.keySet) {
                    fileNameExt = stepId
                    System.out.println("Generating File: " + fileNameExt + " For Var: " + vname)
                    var refinedMapLHStoRHS = refineListLHStoRHS(mapLHStoRHSExt.get(stepId))
                    fileContentsExt = printRefinedMap(refinedMapLHStoRHS)
                    fsa.generateFile(fileNameExt, fileContentsExt)
                    fileContentsExt = ''''''
                }
            }
        }
        return txt // TODO Remove unused variable
    }

    def String printRefinedMap(Object item) {
        switch item {
            Map<String,Object>: return printRefinedMap(item)
            String: return item
            default: throw new UnsupportedOperationException("Unsupported type")
        }
    }

    def String printRefinedMap(Map<String, Object> map) '''
        {
            «FOR entry : map.entrySet() SEPARATOR ','»
                "«entry.key»" : «printRefinedMap(entry.value)»
            «ENDFOR»
        }
    '''

    def private Map<String, Object> refineListLHStoRHS(List<KeyValue> values) {
        var mapOfMaps = new LinkedHashMap<String, Object>()
        for (elem : values) {
            var fquali = new ArrayList<String>(elem.key.split("\\."))
            var current = mapOfMaps
            for (var i = 1; i < fquali.length - 1; i++) {
                var field = fquali.get(i)
                // If the key doesn't exist or isn't a map, create a new empty map
                if (!(current.get(field) instanceof Map)) {
                    current.put(field, new LinkedHashMap<String, Object>());
                }
                // Move deeper into the nested map
                current = current.get(field) as LinkedHashMap<String, Object>
            }
            current.put(fquali.last, elem.value)
        }

        if (mapOfMaps.size == 1) { // if json map has only one element which is either a 
            var field_list = Arrays.asList(
                record_lot_def_file_name, // ...lot_definition 
                record_job_def_file_name // ...job_definition
            )
            for (field : field_list) {
                var item = mapOfMaps.getOrDefault(field, null) // check if this element is 
                if (item instanceof LinkedHashMap) { // ...of record type and, if so,
                    return item // ...then pull it out of the value!
                }
            }
        }
        return mapOfMaps
    }

    def private String getStepInstanceFileName(String step_id) {
        for (elm : listStepInstances) {
            if (elm.id.equals(step_id)) {
                return elm.inputFile
            }
        }
        return new String
    }

    def private String getFileName(String varName) {
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
    def private getRefExtensions(String varName) {
        var mapListOfKeyValue = new HashMap<String, List<KeyValue>>
        for (step : listStepInstances) {
            if (step.variableName.equals(varName)) {
                if (!step.stepRefs.empty) {
                    for (sr : step.stepRefs) {
                        mapListOfKeyValue.put(sr.inputFile + sr.variableName +
                            "_" + sr.recordExp + ".json", sr.parameters)
                    }
                }
            }
        }
        return mapListOfKeyValue
    }

    // function to combine keys (parameters of step may have duplicate keys) //
    // Note DB: Incomplete implementation. Decision to avoid duplicate keys in front end. 
    // Decision: If an attribute of record needs references and concrete data, then do
    // everything in the reference part. 
    def private combineKeys(List<KeyValue> parameters) {
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

    def private getExtensions(String varName) {
        var mapListOfKeyValue = new HashMap<String, List<KeyValue>>
        // System.out.println(" Getting Extension for Variable: " + varName)
        for (step : listStepInstances) {
            if (step.variableName.equals(varName)) {
                // System.out.println("STEP ID: " + step.id)
                // Note DB: Incomplete implementation. Decision to avoid duplicate keys in front end. 
                // Decision: If an attribute of record needs references and concrete data, then do everything in the reference part. 
                // combineKeys(step.parameters)
                mapListOfKeyValue.put(step.id, step.parameters)
                if (!step.stepRefs.empty) {
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

    def private generateFASTScenarioFile() {
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

    def private generateFASTRefStepTxt(Step step) {
        var refTxt = new ArrayList<CharSequence>
        var refKeyList = new HashSet<String>
        // System.out.println(" Step Name: " + step.id)
        for (kv : step.parameters) {
            // System.out.println(" Parameters ")
            kv.display
            for (rk : kv.refKey) {
                // System.out.println(" KeyValue Pair:  " + rk)
                if (!refKeyList.contains(rk)) {
                    // System.out.println(" Added Ref Link ")
                    refTxt.add('''"_«rk»" : "«rk»"''')
                    refKeyList.add(rk)
                }
            }
        }
        // Added DB. 28.05.2025. 
        // Fix to handle step references when data is explicitly separated (e.g. lot definition)
        for (sref : step.stepRefs) {
            // System.out.println(" REF Step ID: " + sref.id)
            for (kv : sref.parameters) {
                // System.out.println(" REF STEP Parameters ")
                // kv.display 
                for (rk : kv.refKey) {
                    // System.out.println(" REF STEP KeyValue Pair:  " + rk)
                    if (!refKeyList.contains(rk)) {
                        // System.out.println(" Added REF STEP Ref Link ")
                        refTxt.add('''"_«rk»" : "«rk»"''')
                        refKeyList.add(rk)
                    }
                }
            }
        }
        return refTxt
    }

    def private displayParseResults() {
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
