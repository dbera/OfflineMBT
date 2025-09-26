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
import java.util.HashMap
import java.util.HashSet
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import java.util.regex.Pattern
import nl.esi.comma.actions.actions.Action
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionNullLiteral
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.inputspecification.inputSpecification.APIDefinition
import nl.esi.comma.inputspecification.inputSpecification.Main
import nl.esi.comma.testspecification.generator.TestSpecificationInstance
import nl.esi.comma.testspecification.generator.to.docgen.DocGen
import nl.esi.comma.testspecification.generator.utils.JSONData
import nl.esi.comma.testspecification.generator.utils.KeyValue
import nl.esi.comma.testspecification.generator.utils.Step
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.TypeDecl
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import static extension nl.esi.comma.types.utilities.FileSystemAccessUtil.*
import java.util.Set
import java.util.LinkedHashSet
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.testspecification.testspecification.AssertionStep

class FromConcreteToFast extends AbstractGenerator {

    var Map<String, String> rename = new HashMap<String, String>()
    var Map<String, String> args = new HashMap<String, String>()

    new() {
    }

    new(Map<String, String> rename, Map<String, String> params) {
        this.rename = rename
        this.args = params
    }

    /* TODO this should come from project task? Investigate and Implement it. */
    var List<String> record_def_file_names = List.of("lot_definition", "job_definition")
    var List<String> setup_file_names = List.of("setup_file")

// On save of TSPEC file, this function is called by Eclipse Framework
    override void doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val ctd = res.contents.filter(TSMain).map[model].filter(TestDefinition).head
        if (ctd === null) {
            throw new Exception('No concrete tspec found in resource: ' + res.URI)
        }

        generateContents(res, fsa) // Parsing and File Generation
    }

// Generate data.kvp and referenced JSON files
    def private generateContents(Resource res, IFileSystemAccess2 fsa) {
        // 0) setup FAST directory structure
        val baseFsa = fsa.createFolderAccess('generated_FAST/')
        val datasetPath = this.args.getOrDefault('prefixPath', './')
        val testFsa = baseFsa.createFolderAccess(datasetPath)

        // 1) using the .tspec file
        val modelInst = res.contents.head as TSMain
        val model = modelInst.model as TestDefinition
        shortenStepNames(model)

        // 2) create mapping data-implementation to filenames (in .params files)
        var tsi = new TestSpecificationInstance
        // 2.1) Path to folder containing .json input_file(s) (default: ./dataset/)
        tsi.filePath = datasetPath
        tsi._process_Import_Data_Implementation(modelInst)

        // 3) create mappings for:
        // 3.1) Step variable name to step-type (step-parameters field in .tspec file)
        tsi._process_Step_Parameters(modelInst)
        // 3.2) Global parameters key and value (LHS and RHS, resp.)
        tsi._process_Global_Param_Init(modelInst)
        // 3.3) SUT initialization key and value (LHS and RHS, resp.)
        tsi._process_Sut_Param_Init(modelInst)

        // 4) Parse step-sequence (precondition: steps 2-3, where import and step-parameters are processed)
        val stepSequence = getRunStepSequence(model)
        for (s : stepSequence) {
            var stepInst = tsi.createStep(model, s)
            tsi.steps.add(stepInst)
        }
        // Turn off during production!
        tsi.displayParseResults

        // 5) Generate data.kvp file
        testFsa.generateFile('variants/single_variant/data.kvp', tsi.generateFASTScenarioFile)

        // 6) Generate JSON data files
        tsi.generateJSONDataFiles(baseFsa, modelInst, record_def_file_names)
        tsi.generateJSONSutSetupFiles(baseFsa)

        // 7) generate reference.kvp
        var refkvpgen = new RefKVPGenerator()
        testFsa.generateFile('variants/single_variant/reference.kvp', refkvpgen.generateRefKVP(model))

        // 8) parse sut-param-init actions into a XML elements of a vfd XML file
        var vfdgen = new VFDXMLGenerator(this.args, this.rename)
        testFsa.generateFile('variants/single_variant/vfd.xml', vfdgen.generateXML(tsi))

        // 9) generate PlantUML files Generation for Review /* Added DB: 12.05.2025*/
        var docgen = new DocGen()
        testFsa.generateFile('variants/single_variant/viz.plantuml', docgen.generatePlantUMLFile(tsi.steps))

    }

    def String findMatchingRecordName(String name, List<String> suffixes) {
        for (suffix : suffixes) {
            if (name.endsWith('.' + suffix)) {
                return suffix
            }
        }
        return null
    }

    def boolean isPrintableAssignment(Action act) {
        return switch (act) {
            AssignmentAction: !(act.exp instanceof ExpressionNullLiteral)
            RecordFieldAssignmentAction: !(act.exp instanceof ExpressionNullLiteral)
            default: false
        }
    }

    def private getRunStepSequence(TestDefinition td) {
        var listStepSequence = new ArrayList<RunStep>
        // 4.1) Fetches test_single_sequence from .atspec file (check FromAbstractToConcrete)
        var test_single_sequence = td.testSeq.head
        for (ss : test_single_sequence.stepSeqRef) {
            for (step : ss.step.filter(RunStep))
                listStepSequence.add(step)
        }
        return listStepSequence
    }

    def private shortenStepNames(TestDefinition td) {
        var pat = Pattern.compile("_[^_]+_+default_[0-9]+")
        var listStepSequence = new ArrayList<RunStep>
        var test_single_sequence = td.testSeq.head
        for (ss : test_single_sequence.stepSeqRef) {
            for (step : ss.step){
                var mat = pat.matcher(step.inputVar.name); mat.find
                var prefix =  switch(step) {
                    RunStep: 'step'
                    AssertionStep: 'assertion'
                    default: throw new UnsupportedOperationException("Unsupported type")
                }
                step.inputVar.name = prefix + mat.group
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
        // get fully-qualified field name
        var recExp = ''''''

        while (! (record instanceof ExpressionVariable)) {
            if (recExp.empty)
                recExp = '''«(record as ExpressionRecordAccess).field.name»'''
            else
                recExp = '''«(record as ExpressionRecordAccess).field.name».''' + recExp
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
    def private dispatch KeyValue generateInitAssignmentAction(TestSpecificationInstance tsi, AssignmentAction action) {
        var mapLHStoRHS = new KeyValue
        mapLHStoRHS.key = action.assignment.name
        mapLHStoRHS.value = ExpressionsParser::generateExpression(action.exp, '''''').toString
//        // replace references to global variables with FAST syntax
//        for (elm : tsi.mapLocalDataVarToDataInstance.keySet) {
//            if (mapLHStoRHS.value.contains(elm)) {
//                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm, "global.params['" + elm + "']")
//            }
//        }
        return mapLHStoRHS
    }

    def private dispatch KeyValue generateInitAssignmentAction(TestSpecificationInstance tsi,
        RecordFieldAssignmentAction action) {
        return tsi.generateInitRecordAssignment(action.fieldAccess as ExpressionRecordAccess, action.exp, '''''')
    }

    def String findPrefixBasedOnType(Expression access) {
        if (access instanceof ExpressionRecordAccess) {
            var TypeDecl fieldType = access.field.type.type
            if (fieldType instanceof SimpleTypeDecl) {
                var isBasedOnString = fieldType.base?.name?.equals('string')
                if (isBasedOnString) {
                    var baseName = fieldType.name
                    var prefix = this.args.getOrDefault('prefixPath', './')
                    return switch baseName {
                        case 'Dataset': '"%s/dataset/"+'.formatted(prefix)
                        default: ''
                    }
                }
            }
        }
        return ""
    }

    def private generateInitRecordAssignment(TestSpecificationInstance tsi, ExpressionRecordAccess eRecAccess,
        Expression exp, CharSequence ref) {
        var mapLHStoRHS = new KeyValue

        var record = eRecAccess.record
        var field = eRecAccess.field
        // get fully-qualified field name 
        var recExp = ''''''

        while (! (record instanceof ExpressionVariable)) {
            if (recExp.empty)
                recExp = '''«(record as ExpressionRecordAccess).field.name»'''
            else
                recExp = '''«(record as ExpressionRecordAccess).field.name».''' + recExp
            record = (record as ExpressionRecordAccess).record
        }
        // tracking fully-qualified field name 
        mapLHStoRHS.key = '''«recExp».''' + field.name
        // check if there is any applicable auto-prefixing rule (for custom types *based on string*)
        var prefix = findPrefixBasedOnType(eRecAccess)
        mapLHStoRHS.value = prefix + ExpressionsParser::generateExpression(exp, ref).toString
        mapLHStoRHS.refVal.add(mapLHStoRHS.value) // Added DB 14.10.2024
        // check references to Step outputs and replace with FAST syntax
        for (elm : tsi.stepVarNameToType.keySet) {
            if (mapLHStoRHS.value.contains(elm + ".output")) {
                // Added REGEX 26.11.2024: In .ps files, '.output'field is the container of output data. 
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm + "\\.output" + "\\.(.*?)\\.", // We need to remove '.output' field from steps.out[step.params[....]].output.x.y.z...
                // for proper FAST generation. 
                "steps.out[step.params['" + "_" + elm + "']].")
                mapLHStoRHS.refKey.add(elm) // reference to step
                // Custom String Updates for FAST Syntax Peculiarities! TODO investigate solution?
                // map-var['key'] + "[0]" -> map-var['key'][0] 
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(Pattern.quote("] + \"["), "][") // ("\\] + \"\\[","\\]\\[")
                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll("\\]\"", "]")
            }
        }
//        // replace references to global variables with FAST syntax
//        for (elm : tsi.mapLocalDataVarToDataInstance.keySet) {
//            if (mapLHStoRHS.value.contains(elm)) {
//                mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm, "global.params['" + elm + "']")
//            }
//        }
        return mapLHStoRHS
    }

// End Expression Handler //
    def private generateJSONDataFiles(TestSpecificationInstance tsi, IFileSystemAccess2 fsa, TSMain modelInst,
        List<String> record_names) {
        var List<Step> listOfSteps = new ArrayList<Step>
        // val modelInst = _resource.contents.head as TSMain
        // NOTE. Assumption is that steps are populated.
        for (step : tsi.steps) {
            listOfSteps.add(step)
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
                            val mapLHStoRHS = tsi.generateInitAssignmentAction(act)
                            // variable is initialized in param file
                            listOfSteps = listOfSteps.stream().filter(t|t.variableName == mapLHStoRHS.key).toList
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
                    var mapLHStoRHS_ = tsi.getExtensions(mapLHStoRHS.key)
                    var String fileName = new String
                    if (!mapLHStoRHS_.isEmpty) {
                        // check that mapLHStoRHS_ is not empty => get file name from step instance list
                        // Reason: the map data structure SUT to File name, 
                        // does not consider new data files due to data extension in steps 
                        for (stepId : mapLHStoRHS_.keySet) {
                            fileName = tsi.getStepInstanceFileName(stepId)
                            var fileContents = mapLHStoRHS.value
                            System.out.println("Generating File: " + fileName + " For Step: " + stepId)
                            var refinedMapLHStoRHS = refineListLHStoRHS(mapLHStoRHS_.get(stepId), record_names)
                            fileContents = printRefinedMap(refinedMapLHStoRHS)
                            fsa.generateFile(fileName, fileContents)
                        }
                    } else {
                        // else call function to get file name. 
                        System.out.println("Warning: Variable " + mapLHStoRHS.key +
                            " defined in param but not used in TSpec!")
                        fileName = tsi.getFileName(mapLHStoRHS.key)
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
        for (step : listOfSteps) {
            var vname = step.variableName
            // System.out.println(" variable not declared in params: " + vname)
            // for(step : listStepInstances) {
            // if(step.variableName.equals(vname)) {
            var mapLHStoRHS_ = tsi.getExtensions(vname) // step.variableName
            /*for(elm: mapLHStoRHS_.keySet) { 
             *             System.out.println("    VAR: " + elm)
             *             for(kv : mapLHStoRHS_.get(elm))
             *                 System.out.println("    k: " + kv.key + "   v : " + kv.value)
             }*/
            var String fileName = new String
            var fileContents = ''''''
            if (!mapLHStoRHS_.isEmpty) {
                for (stepId : mapLHStoRHS_.keySet) {
                    fileName = tsi.getStepInstanceFileName(stepId)
                    System.out.println("Generating File: " + fileName + " For Step: " + stepId)
                    var refinedMapLHStoRHS = refineListLHStoRHS(mapLHStoRHS_.get(stepId), record_names)
                    fileContents = printRefinedMap(refinedMapLHStoRHS)
                    fsa.generateFile(fileName, fileContents)
                    fileContents = ''''''
                }
            }
        }

        // Added 09.11.2024 DB: generate explicit JSON files referenced before 
        for (step : listOfSteps) {
            var vname = step.variableName
            var mapLHStoRHSExt = tsi.getRefExtensions(vname)
            var String fileNameExt = new String
            var fileContentsExt = ''''''
            if (!mapLHStoRHSExt.isEmpty) {
                for (stepId : mapLHStoRHSExt.keySet) {
                    fileNameExt = stepId
                    System.out.println("Generating File: " + fileNameExt + " For Var: " + vname)
                    var refinedMapLHStoRHS = refineListLHStoRHS(mapLHStoRHSExt.get(stepId), record_names)
                    fileContentsExt = printRefinedMap(refinedMapLHStoRHS)
                    fsa.generateFile(fileNameExt, fileContentsExt)
                    fileContentsExt = ''''''
                }
            }
        }
    }

    def private generateJSONSutSetupFiles(TestSpecificationInstance tsi, IFileSystemAccess2 fsa) {
        for (datasuts_item : tsi.indatasuts) {
            for (step : datasuts_item.stepRefs) {
                var fname = step.inputFile
                var fileContents = step.recordExp
                fsa.generateFile(fname, fileContents)
            }
        }
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

    def private Map<String, Object> refineListLHStoRHS(List<KeyValue> values, List<String> record_names) {
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
            for (field : record_names) {
                var item = mapOfMaps.getOrDefault(field, null) // check if this element is 
                if (item instanceof LinkedHashMap) { // ...of record type and, if so,
                    return item // ...then pull it out of the value!
                }
            }
        }
        return mapOfMaps
    }

    def private String getStepInstanceFileName(TestSpecificationInstance tsi, String step_id) {
        for (elm : tsi.steps) {
            if (elm.id.equals(step_id)) {
                return elm.inputFile
            }
        }
        return new String
    }

    def private String getFileName(TestSpecificationInstance tsi, String varName) {
        for (step : tsi.steps) {
            if (step.variableName.equals(varName)) {
                return step.inputFile.replaceAll(".json", "_" + step.id + ".json")
            }
        }
        for (key : tsi.dataImplToFilename.keySet) {
            if (key.equals(varName)) {
                return tsi.dataImplToFilename.get(key).head
            }
        }
        for (key : tsi.sutInstanceToFile.keySet) {
            var fname = tsi.sutInstanceToFile.get(key).head
            // System.out.println("Checking: " + fname + " map key entry: " + key)
            if (key.equals(varName)) {
                return fname
            }
        }
        return "undefined.json"
    }

// Added DB: get contents for explicit JSON file generation
    def private getRefExtensions(TestSpecificationInstance tsi, String varName) {
        var mapListOfKeyValue = new HashMap<String, List<KeyValue>>
        for (step : tsi.steps) {
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

    def private getExtensions(TestSpecificationInstance tsi, String varName) {
        var mapListOfKeyValue = new HashMap<String, List<KeyValue>>
        // System.out.println(" Getting Extension for Variable: " + varName)
        for (step : tsi.steps) {
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

    def private generateFASTScenarioFile(TestSpecificationInstance tsi) {
        var txt = '''
            in.data.global_parameters = {
                «FOR key : tsi.dataVarToDataInstance.keySet SEPARATOR ','»
                    "«key»" : «tsi.dataVarToDataInstance.get(key).head»
                «ENDFOR»
            }
            
            in.data.suts = [
                «FOR sut_setup : tsi.indatasuts SEPARATOR ','»
                    {
                        «FOR param: sut_setup.parameters SEPARATOR ','»
                            "«param.key»": «param.value»
                        «ENDFOR»
                    }
                «ENDFOR»
            ]
            
            in.data.steps = [
                «FOR elm : tsi.steps SEPARATOR ','»
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

    def private displayParseResults(TestSpecificationInstance tsi) {
        System.out.println(" ---- Map Data Instance To File ---- ")
        for (key : tsi.dataImplToFilename.keySet) {
            System.out.println("    Key: " + key + " Value: " + tsi.dataImplToFilename.get(key))
        }

        System.out.println(" ---- Map SUT Instance To File ---- ")
        for (key : tsi.sutInstanceToFile.keySet) {
            System.out.println("    Key: " + key + " Value: " + tsi.sutInstanceToFile.get(key))
        }

        System.out.println(" ---- Map Local Data Var To Data Instance ---- ")
        for (key : tsi.dataVarToDataInstance.keySet) {
            System.out.println("    Key: " + key + " Value: " + tsi.dataVarToDataInstance.get(key))
        }

        System.out.println(" ---- Map SUT Var To Data Instance ---- ")
        for (key : tsi.sutVarToDataInstance.keySet) {
            System.out.println("    Key: " + key + " Value: " + tsi.sutVarToDataInstance.get(key))
        }

        System.out.println(" ---- Map Step Parameters Variable To Type ---- ")
        for (key : tsi.stepVarNameToType.keySet) {
            System.out.println("    Key: " + key + " Value: " + tsi.stepVarNameToType.get(key))
        }

        System.out.println(" ------------------ STEPS ------------------")
        for (st : tsi.steps) {
            st.display
//          System.out.println("    step-id: " + st.id + " type: " + st.type)
//          System.out.println("    input: " + st.inputFile)
//          System.out.println("    var: " + st.variableName)
//          for(param : st.parameters) 
//              param.display
        // System.out.println("  parameters: " + param.key + " -> " + param.value)
        }
    }

    protected def void _process_Import_Data_Implementation(TestSpecificationInstance tsi, TSMain model) {
        for (imp : model.imports) {
            val inputResource = imp.resource
            var input = inputResource.contents.head
            if (input instanceof Main) {
                if (input.model instanceof APIDefinition) {
                    val apidef = input.model as APIDefinition
                    for (api : apidef.apiImpl) {
                        for (elm : api.di) {
                            var filepath = tsi.filePath + '/dataset/' + elm.fname
                            var key = elm.^var.name
                            tsi.dataImplToFilename.putIfAbsent(key, new ArrayList)
                            tsi.dataImplToFilename.get(key).add(filepath)
                        }
                    }
                } else {
                    System.out.println("Error: Unhandled Model Type! ")
                }
            }
        }
    }

    protected def void _process_Step_Parameters(TestSpecificationInstance tsi, TSMain modelInst) {
        val model = modelInst.model as TestDefinition
        for (steppars : model.stepparams) {
            var key = steppars.name
            var value = steppars.type.type.name
            tsi.stepVarNameToType.putIfAbsent(key, new ArrayList)
            tsi.stepVarNameToType.get(key).add(value)
        }
    }

    protected def void _process_Global_Param_Init(TestSpecificationInstance tsi, TSMain modelInst) {
        val model = modelInst.model as TestDefinition
        for (act : model.gparamsInitActions) {
            var mapLHStoRHS = tsi.generateInitAssignmentAction(act)
            tsi.dataVarToDataInstance.putIfAbsent(mapLHStoRHS.key, new ArrayList)
            tsi.dataVarToDataInstance.get(mapLHStoRHS.key).add(mapLHStoRHS.value)
        }
    }

    private def boolean isInDataSuts(Action act) {
        val IDS_NAME = 'sut_setup_'
        return switch (act) {
            RecordFieldAssignmentAction: {
                var exp = act.fieldAccess
                switch (exp) {
                    ExpressionRecordAccess: exp.field.name.startsWith(IDS_NAME)
                    default: false
                }
            }
            default:
                false
        }
    }

    private def boolean isInputDataSut(Action act) {
        if (act instanceof RecordFieldAssignmentAction) {
            var vari = act.fieldAccess
            if (vari instanceof ExpressionRecordAccess) {
                var io = vari.record
                if (io instanceof ExpressionRecordAccess) {
                    return io.field.name.equals('input')
                }
            }
        }
        return false
    }

    protected def void _process_Sut_Param_Init(TestSpecificationInstance tsi, TSMain modelInst) {
        val model = modelInst.model as TestDefinition
        var sutInitInput = model.sutInitActions.filter[isInputDataSut(it)]

        var indatasuts = sutInitInput.filter[isInDataSuts(it)].filter(RecordFieldAssignmentAction)
        var uniqueDataSuts = new HashSet()
        // 3.3.1) Fetching content for in.data.suts
        for (act : indatasuts) {
            var mapLHStoRHS = tsi.generateInitAssignmentAction(act)
            if(uniqueDataSuts.addAll(mapLHStoRHS.value)){
                tsi.sutVarToDataInstance.putIfAbsent(mapLHStoRHS.key, new ArrayList)
                tsi.sutVarToDataInstance.get(mapLHStoRHS.key).add(mapLHStoRHS.value)
    
                var era = (act.fieldAccess as ExpressionRecordAccess)
                var stepId = getStepId(era)
    
                // get sut-var name and type
                var stepInst = new Step
                stepInst.id = era.field.name
                stepInst.variableName = era.field.name
                stepInst.type = era.field.type.type.name
    
                // 4.6) Check if this action is a printable assignment (aka not-a-null assignment)
                if (isPrintableAssignment(act)) {
                    for (field : (act.exp as ExpressionRecord).fields) {
                        var lhs = new KeyValue
                        // get sut-var field name and assigned value
                        lhs.key = field.recordField.name
                        lhs.value = ExpressionsParser::generateExpression(field.exp, '''''').toString
    
                        // should it become a file on its own?
                        var String match = findMatchingRecordName('.' + lhs.key, setup_file_names)
                        if (match instanceof String) {
                            // Create new step instance
                            var new_rstep = new Step
                            // field name (key), type, and value
                            new_rstep.id = lhs.key
                            new_rstep.variableName = lhs.key
                            new_rstep.type = field.recordField.type.type.name
                            new_rstep.recordExp = lhs.value
                            // path for json input_file in "filePath / field name + step ID"
                            new_rstep.inputFile = tsi.filePath + '/dataset/' + new_rstep.inputFile + new_rstep.id + '_' +
                                stepId + '.json'
                            // point lhs value to input_file
                            lhs.value = new_rstep.inputFile
                            // Add to list of step reference of step
                            stepInst.stepRefs.add(new_rstep)
                        }
                        stepInst.parameters.add(lhs)
                    }
                }
                tsi.indatasuts.add(stepInst)
            }
        }

        var vfdXmlItems = sutInitInput.reject[isInDataSuts(it)]
        // 3.3.2) Fetching XML elements (as strings) for vfd.xml file
        var Set<String> SUTList_items = new LinkedHashSet()
        for (act : vfdXmlItems) {
            var item = ExpressionsParser.generateXMLElement(act, this.rename)
            if (SUTList_items.add(item.toString)) {
                tsi.sutDefinitionsVFDXML.putIfAbsent(act.ID, new ArrayList)
                tsi.sutDefinitionsVFDXML.get(act.ID).add(item.toString)
            }
        }
    }

    private def String getStepId(ExpressionRecordAccess expr) {
        var varLabel = expr.field.name
        var ioLabel = (expr.record as ExpressionRecordAccess).field.name
        var stepLabel = ((expr.record as ExpressionRecordAccess).record as ExpressionVariable).variable.name
        return stepLabel
//        return ioLabel + '_' + stepLabel
    }

    private def Step createStep(TestSpecificationInstance tsi, TestDefinition model, RunStep s) {
        var stepInst = new Step
        stepInst.runStep = s
        // 4.2) Step ID
        stepInst.id = s.inputVar.name
        // 4.3) Step type (defined via UI text box, e.g., SUT.OperationName)
        stepInst.type = s.type.name
        // 4.4) Step input file path+name
        stepInst.inputFile = tsi.dataImplToFilename.get(s.stepVar.name).head

        // 4.5) For each action in ref-to-step-output section ...
        for (ref : s.refStep) {
            for (act : ref.input.actions) {
                // 4.6) Check if this action is a printable assignment (aka not-a-null assignment)
                if (isPrintableAssignment(act)) {
                    // 4.6.1) make strings for LHS and RHS ( flattened / fully-qualified)
                    var mapLHStoRHS = tsi.generateInitAssignmentAction(act)
                    // 4.6.2) fetch step-input variable and record field
                    var lhs = getLHS(act) // note key = record variable, and value = recExp
                    stepInst.variableName = lhs.key // Note DB: This is the same for all actions
                    stepInst.recordExp = lhs.value // Note DB: This keeps overwriting (record prefix)
                    // 4.6.3) check if record field assignment should be in its own json file
                    var String match = findMatchingRecordName(lhs.value, record_def_file_names)
                    if (match instanceof String) {
                        // 4.6.3.1) record field is part of step input_file
                        if (stepInst.isStepRefPresent(lhs.value)) {
                            var rStep = stepInst.getStepRefs(lhs.value)
                            rStep.parameters.add(mapLHStoRHS)
                        } else {
                            // Create new step instance and fill all details there
                            var new_rstep = new Step
                            new_rstep.id = lhs.value
                            new_rstep.runStep = stepInst.runStep
                            new_rstep.type = stepInst.runStep?.type.name
                            new_rstep.inputFile = tsi.filePath + '/dataset/'
                            new_rstep.variableName = match
                            new_rstep.recordExp = stepInst.id
                            new_rstep.parameters.add(mapLHStoRHS) // Added DB 29.05.2025
                            // Add to list of step reference of step
                            stepInst.stepRefs.add(new_rstep)
                        }
                    } else {
                        // 4.6.3.2) record field assignment has it own json
                        stepInst.parameters.add(mapLHStoRHS)
                    }
                }
            }
        }
        // 4.7) update step input_file names, if additional data is specified (parameters). 
        if (!stepInst.parameters.isEmpty) {
            stepInst.inputFile = stepInst.inputFile.replaceFirst("[^/]+\\.json$", stepInst.id + ".json")
        }

        return stepInst
    }

    private def Step createDataSuts(TestSpecificationInstance tsi, RecordFieldAssignmentAction act) {
        var stepInst = new Step
        var era = (act.fieldAccess as ExpressionRecordAccess)
        // 4.2) Step ID
        stepInst.id = era.field.name
        stepInst.variableName = era.field.name
        // 4.3) Step type (defined via UI text box, e.g., SUT.OperationName)
        stepInst.type = era.field.type.type.name

        // 4.6) Check if this action is a printable assignment (aka not-a-null assignment)
        if (isPrintableAssignment(act)) {
            for (field : (act.exp as ExpressionRecord).fields) {
                var lhs = new KeyValue
                lhs.key = field.recordField.name
                lhs.value = ExpressionsParser::generateExpression(field.exp, '''''').toString
                // 4.9) check if record field assignment should be in its own json file
                var String match = findMatchingRecordName('.' + lhs.key, record_def_file_names)
                if (match instanceof String) {
                    // Create new step instance and fill all details there
                    var new_rstep = new Step
                    new_rstep.id = lhs.key
                    new_rstep.variableName = lhs.key
                    new_rstep.recordExp = lhs.value
                    new_rstep.type = field.recordField.type.type.name
                    new_rstep.inputFile = tsi.filePath
                    new_rstep.parameters.add(lhs) // Added DB 29.05.2025
                    // Add to list of step reference of step
                    stepInst.stepRefs.add(new_rstep)
                } else {
                    // 4.9.2) record field assignment has it own json
                    stepInst.parameters.add(lhs)
                }
            }
        }

        return stepInst
    }

}
