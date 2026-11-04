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
 
package nl.esi.comma.constraints.generator.cpn

import com.google.gson.GsonBuilder
import java.util.ArrayList
import java.util.HashSet
import java.util.List
import java.util.Set
import nl.esi.comma.constraints.constraints.AlternatePrecedence
import nl.esi.comma.constraints.constraints.AlternateResponse
import nl.esi.comma.constraints.constraints.AtLeast
import nl.esi.comma.constraints.constraints.AtMost
import nl.esi.comma.constraints.constraints.ChainPrecedence
import nl.esi.comma.constraints.constraints.ChainResponse
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.End
import nl.esi.comma.constraints.constraints.Exact
import nl.esi.comma.constraints.constraints.Existential
import nl.esi.comma.constraints.constraints.Future
import nl.esi.comma.constraints.constraints.Init
import nl.esi.comma.constraints.constraints.Past
import nl.esi.comma.constraints.constraints.Precedence
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.Response
import nl.esi.comma.constraints.constraints.Template
import nl.esi.comma.constraints.generator.cpn.model.CPNTemplateResult
import nl.esi.comma.constraints.generator.cpn.model.ConstraintGenerationResult
import nl.esi.comma.constraints.generator.cpn.model.RefInfo
import nl.esi.comma.constraints.generator.cpn.templates.ExistentialTemplates
import nl.esi.comma.constraints.generator.cpn.templates.FutureTemplates
import nl.esi.comma.constraints.generator.cpn.templates.PastTemplates
import nl.esi.comma.testspecification.testspecification.AbstractStep
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import nl.esi.xtext.expressions.expression.ExpressionVariable
import nl.esi.xtext.types.types.TypesModel
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.nodemodel.util.NodeModelUtils

import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*

class CPNTemplateGenerator 
{
    val FutureTemplates futureTemplates = new FutureTemplates
    val PastTemplates pastTemplates = new PastTemplates
    val ExistentialTemplates existentialTemplates = new ExistentialTemplates
    val Helpers helpers = new Helpers

//  generates product pspec files for each constraints in the constraint file
    def List<ConstraintGenerationResult> generatePSpec(
        Resource res, IFileSystemAccess2 fsa, 
        List<Constraints> constraints,
        TSMain tsMain) {
        val results = new ArrayList<ConstraintGenerationResult>    
        for(constraintsSource : constraints){
            for (constraintDef : constraintsSource.templates){
                results += generateConstraintPS(constraintsSource, constraintDef, tsMain.model as TestDefinition, fsa)
            }
        }
        return results
    }
    
    def isStepNamePresent(List<RefInfo> labelList, String name) {
        for(label : labelList) { if(label.refName.equals(name)) return true }
        return false
    }

    def generateTSpecModel(TestDefinition td, List<RefInfo> labelList) 
    {
        var idx = helpers.countTraceSize(td, labelList)
        var _idx = 0
        return
        '''
        system RootConcreteTSpec
        {
            inputs
                StepMetaData StepMetaData
            outputs
            «FOR l : labelList»
                «l.refType» «l.refName»
            «ENDFOR»
            StepMetaData StepMetaData

            local
            «FOR i : 0..idx»
                UNIT p«i»
            «ENDFOR»
            
        init
            p0 := UNIT { unit = 0 }
            StepMetaData:=StepMetaData { steps = <map<string,string>>{} }

            desc "TSpecCPNModel"

            «FOR ss : td.stepSeq»
                «FOR step : ss.step» 
                    «IF step instanceof RunStep || step instanceof AssertionStep»
                        action «step.stepVar.name»_«_idx»
                        element-label "«step.typeName»"
                        case default
                        with-inputs p«_idx», StepMetaData
                        «IF isStepNamePresent(labelList,step.stepVar.name)»
                            produces-outputs «step.stepVar.name»
                            updates:
                                // Constructor
                                «step.stepVar.name» := «Utils.defaultValue(step.stepVar.type.type, step.stepVar.name)»
                            «FOR act : step.input»
                                «IF act.exp.eAllContents.filter(ExpressionVariable).isEmpty»
                                    // ReferenceExp. TODO Skip.
                                    «NodeModelUtils.getNode(act).text.replaceAll("(?m)^\\s*$\\R?", "")»
                                «ENDIF»
«««                            «NodeModelUtils.getNode(act).text.replaceAll("(?m)^\\s*$\\R?", "")»
                            «ENDFOR»
                        «ELSE»
                            produces-outputs any
                        «ENDIF»
                        produces-outputs StepMetaData
                        updates:
                            «IF step instanceof RunStep»
                                StepMetaData := StepMetaData {
                                    steps = <map<string,string>>{
                                        "stepid" -> "«step.stepVar.name»"
                                    }
                                }
                            «ELSE»
                                StepMetaData := StepMetaData
                            «ENDIF»
                             
                        produces-outputs p«_idx+1»
                        «{_idx++ ""}»
                    «ENDIF»
                «ENDFOR»
            «ENDFOR»
        }
        '''
    }
    
    def generateReversedTSpecModel(TestDefinition td, List<RefInfo> labelList)
    {
        var idx = helpers.countTraceSize(td, labelList)
        var _idx = 0
        val reversedSteps = td.stepSeq.flatMap[step].toList.reverseView
        return
        '''
        system RootConcreteTSpec
        {
            inputs
                StepMetaData StepMetaData
            outputs
            «FOR l : labelList»
                «l.refType» «l.refName»
            «ENDFOR»
            StepMetaData StepMetaData

            local
            «FOR i : 0..idx»
                UNIT p«i»
            «ENDFOR»
            
        init
            p0 := UNIT { unit = 0 }
            StepMetaData:=StepMetaData { steps = <map<string,string>>{} }

            desc "TSpecCPNModel"

           
            «FOR step : reversedSteps» 
                «IF step instanceof RunStep || step instanceof AssertionStep»
                    action «step.typeName»_«_idx»
                    element-label "«step.typeName»"
                    case default
                    with-inputs p«_idx», StepMetaData
                    «IF isStepNamePresent(labelList,step.stepVar.name)»
                        produces-outputs «step.stepVar.name»
                        updates:
                            // Constructor
                            «step.stepVar.name» := «Utils.defaultValue(step.stepVar.type.type, step.stepVar.name)»
                        «FOR act : step.input»
                            «IF act.exp.eAllContents.filter(ExpressionVariable).isEmpty»
                                // ReferenceExp. TODO Skip.
                                «NodeModelUtils.getNode(act).text.replaceAll("(?m)^\\s*$\\R?", "")»
                            «ENDIF»
                        «ENDFOR»
                    «ELSE»
                        produces-outputs any
                    «ENDIF»
                    produces-outputs StepMetaData
                    updates:
                        «IF step instanceof RunStep»
                            StepMetaData := StepMetaData {
                                steps = <map<string,string>>{
                                    "stepid" -> "«step.stepVar.name»"
                                }
                            }
                        «ELSE»
                            StepMetaData := StepMetaData
                        «ENDIF»
                    produces-outputs p«_idx+1»
                    «{_idx++ ""}»
                «ENDIF»
            «ENDFOR»
        }
        '''
    }
    
    def generateFirstEventTSpecModel(TestDefinition td, List<RefInfo> labelList, boolean reversed) 
    {
        val steps = td.stepSeq.flatMap[step].filter[step |
                step instanceof RunStep ||
                step instanceof AssertionStep
            ].toList
    
        val boundaryStep =
            if (steps.empty) {
                null
            } else if (reversed) {
                steps.last
            } else {
                steps.head
            }
    
        return
        '''
        system RootConcreteTSpec
        {
            inputs
                StepMetaData StepMetaData
            outputs
            «FOR label : labelList»
                «label.refType» «label.refName»
            «ENDFOR»
            StepMetaData StepMetaData
    
            local
            UNIT p0
            UNIT p1
    
            init
            p0 := UNIT { unit = 0 }
            StepMetaData:=StepMetaData { steps = <map<string,string>>{} }
    
            desc "TSpecCPNModel"
    
            «IF boundaryStep !== null»
                action «boundaryStep.typeName»_0
                element-label "«boundaryStep.typeName»"
                case default
                with-inputs p0, StepMetaData
                
                «IF isStepNamePresent(labelList, boundaryStep.stepVar.name)»
                    produces-outputs «boundaryStep.stepVar.name»
                    updates:
                        «boundaryStep.stepVar.name» :=
                            «Utils.defaultValue(
                                boundaryStep.stepVar.type.type,
                                boundaryStep.stepVar.name
                            )»
                    «FOR action : boundaryStep.input»
                        «IF action.exp.eAllContents
                            .filter(ExpressionVariable).isEmpty»
                            «NodeModelUtils.getNode(action).text
                                .replaceAll("(?m)^\\s*$\\R?", "")»
                        «ENDIF»
                    «ENDFOR»
                «ELSE»
                    produces-outputs any
                «ENDIF»
                produces-outputs StepMetaData
                updates:
                    «IF boundaryStep instanceof RunStep»
                        StepMetaData := StepMetaData {
                            steps = <map<string,string>>{
                                "stepid" -> "«boundaryStep.stepVar.name»"
                            }
                        }
                    «ELSE»
                        StepMetaData := StepMetaData
                    «ENDIF»

                produces-outputs p1
            «ENDIF»
        }
        '''
    }
    
    def generateCountingTSpecModel(TestDefinition td, List<RefInfo> labelList)
    {
        var idx = helpers.countTraceSize(td, labelList)
        var _idx = 0
    
        return
        '''
        system RootConcreteTSpec
                {
                    inputs
                    StepMetaData StepMetaData
                    outputs
                    «FOR l : labelList»
                        «l.refType» «l.refName»
                    «ENDFOR»
                    StepMetaData StepMetaData
                    EOT endoftrace
        
                    local
                    «FOR i : 0..idx»
                        UNIT p«i»
                    «ENDFOR»
                    
                    init
                    p0 := UNIT { unit = 0 }
                    StepMetaData:=StepMetaData { steps = <map<string,string>>{} }

                    desc "TSpecCPNModel"
                    «FOR ss : td.stepSeq»
                        «FOR step : ss.step»
                            «IF step instanceof RunStep || step instanceof AssertionStep»
                                action «step.typeName»_«_idx»
                                element-label "«step.typeName»"
                                case default
                                with-inputs p«_idx»,StepMetaData
                                «IF isStepNamePresent(labelList,step.stepVar.name)»
                                    produces-outputs «step.stepVar.name»
                                    updates:
                                        «step.stepVar.name» := «Utils.defaultValue(step.stepVar.type.type, step.stepVar.name)»
                                    «FOR act : step.input»
                                        «IF act.exp.eAllContents.filter(ExpressionVariable).isEmpty»
                                            // ReferenceExp. TODO Skip.
                                            «NodeModelUtils.getNode(act).text.replaceAll("(?m)^\\s*$\\R?", "")»
                                        «ENDIF»
«««                                    «NodeModelUtils.getNode(act).text.replaceAll("(?m)^\\s*$\\R?", "")»
                                    «ENDFOR»
                                «ELSE»
                                    produces-outputs any
                                «ENDIF»
                                produces-outputs StepMetaData
                                updates:
                                    «IF step instanceof RunStep»
                                        StepMetaData := StepMetaData {
                                            steps = <map<string,string>>{
                                                "stepid" -> "«step.stepVar.name»"
                                            }
                                        }
                                    «ELSE»
                                        StepMetaData := StepMetaData
                                    «ENDIF»

                                «IF _idx == idx - 1»
                                    produces-outputs endoftrace
                                «ENDIF»
                                produces-outputs p«_idx+1»
                                «{_idx++ ""}»
                            «ENDIF»
                        «ENDFOR»
                    «ENDFOR»
                }
        '''
    }

    def generateConstraintPS(Constraints model, Template currentConstraint, TestDefinition td, IFileSystemAccess2 fsa) 
    {
        var typesText = '''''' 
//        '''
//        record UNIT {
//            int unit
//        }
//        '''
        typesText = typesText +
        '''
        record ANY {
            int any
        }
        
        record StepMetaData {
            map<string,string> steps
        }
        
        record EOT {
            int eot
        }
        
        record ConformanceCountState {
            int count
            map<string,string[]> MetaData
        }
        '''
        var specBody = ''''''
        var acceptanceJson= ''''''

        // get nested type definitions
        typesText = typesText + "\n" + generateTypes(model)

        // parse custom defined types and append to existing type definitions
        for(typ : model.types) {
            var node = NodeModelUtils.getNode(typ)
            if (node !== null) {
                typesText = typesText + node.getText()
            }
        }
        var uri = model.eResource.getURI()
        if (uri === null) throw new IllegalArgumentException("Constraint resource has no URI")
        var fileName = uri.trimFileExtension().lastSegment()
        val generatedSpecName = fileName + "_" + currentConstraint.name 
        val constraintFolder = generatedSpecName + "/"
                
//        Check if correlation variable has been declared by the user or not
//        Otherwise creates a dummy variable with metadata after checking if this name already exists or not
        val hasCorrelation = !currentConstraint.variables.empty
        val templateInputNames = computeLabelSet(currentConstraint).map[refName].toSet
        
        var dummyTypeName = generatedSpecName + "_CorrelationMetadata"
        var dummyContextName = generatedSpecName + "_correlationMetadata"
        var suffix = 1
        
        while (typesText.contains(dummyTypeName) ||
               templateInputNames.contains(dummyContextName)) {
            dummyTypeName = generatedSpecName + "_CorrelationMetadata_" + suffix
            dummyContextName = generatedSpecName + "_correlationMetadata_" + suffix
            suffix++
        }
        
        val correlationInfo =
            if (hasCorrelation) {
                val variable = currentConstraint.variables.head
                new RefInfo(variable.type.type.name, variable.name)
            } else {
                new RefInfo(dummyTypeName, dummyContextName)
            }
        
        if (!hasCorrelation) {
            typesText = typesText +
            '''
            record «correlationInfo.refType» {
                map<string,string[]> MetaData
            }
            '''
        }
        // generate types file that will be imported into the generated ps file
        fsa.generateFile(constraintFolder + fileName + ".types", typesText)
        
       
        // state computing ps system model based on concrete tspec and the type of constraint
        val isPastConstraint = currentConstraint.type.exists[it instanceof Past]
        val isInitConstraint = currentConstraint.type.filter(Existential).exists[existential |
            existential.type.exists[it instanceof Init]]
        val isEndConstraint = currentConstraint.type.filter(Existential).exists[existential |
            existential.type.exists[it instanceof End]]
        val isCountingConstraint = currentConstraint.type.filter(Existential).exists[existential |
            existential.type.exists[it instanceof AtLeast || it instanceof AtMost || it instanceof Exact]]
        
                
        var tspecModel =
            if (isPastConstraint) {
                generateReversedTSpecModel(td, computeLabelSet(currentConstraint))
            } else if (isCountingConstraint) {
                generateCountingTSpecModel(td, computeLabelSet(currentConstraint)) 
            } else if (isInitConstraint) {
                generateFirstEventTSpecModel(td, computeLabelSet(currentConstraint), false)
            } else if (isEndConstraint) {
                generateFirstEventTSpecModel(td, computeLabelSet(currentConstraint), true)
            }else {
                generateTSpecModel(td, computeLabelSet(currentConstraint))
            }
//        var tspecModel = generateTSpecModel(td, computeLabelSet(currentConstraint))
        var CPNTemplateResult templateResult= null

        // start computing ps system model based on declare constraints
        var specPrefix = 
        '''
        import "«fileName».types"

        specification «generatedSpecName»
        {
        '''
        for(templateGroup : currentConstraint.type) {
            if(templateGroup instanceof Future) {
                for(templateType : templateGroup.type) {
                    if(templateType instanceof Response) {
                        templateResult = futureTemplates.generateResponseTemplate(
                            currentConstraint.name,
                            correlationInfo, hasCorrelation, templateType.not,
                            templateType.refA.head,
                            helpers.getRefInputTypeAndVar(templateType.refA.head),
                            helpers.getRefName(templateType.refA.head),
                            templateType.refB.head,
                            helpers.getRefName(templateType.refB.head),
                            helpers.getRefInputTypeAndVar(templateType.refB.head)
                        )
                    }
                    else if(templateType instanceof ChainResponse) {
                        templateResult = futureTemplates.generateChainResponseTemplate(
                            currentConstraint.name,
                            correlationInfo, hasCorrelation, templateType.not,
                            templateType.refA.head,
                            helpers.getRefInputTypeAndVar(templateType.refA.head),
                            helpers.getRefName(templateType.refA.head),
                            templateType.refB.head,
                            helpers.getRefName(templateType.refB.head),
                            helpers.getRefInputTypeAndVar(templateType.refB.head)
                        )
                    }
                    else if(templateType instanceof AlternateResponse) {
                        templateResult = futureTemplates.generateAlternateResponseTemplate(
                            currentConstraint.name,
                            correlationInfo, hasCorrelation,
                            templateType.refA.head,
                            helpers.getRefInputTypeAndVar(templateType.refA.head),
                            helpers.getRefName(templateType.refA.head),
                            templateType.refB.head,
                            helpers.getRefName(templateType.refB.head),
                            helpers.getRefInputTypeAndVar(templateType.refB.head),
                            templateType.refC.head,
                            helpers.getRefName(templateType.refC.head),
                            helpers.getRefInputTypeAndVar(templateType.refC.head)
                        )
                    }
                    
                    specBody = templateResult.getPsBody()
                    acceptanceJson = templateResult.getAcceptanceJson()
                    
                  }
                  
             }
            else if(templateGroup instanceof Past) {
                for(templateType : templateGroup.type) {
                    if(templateType instanceof Precedence) {
                        templateResult = pastTemplates.generatePrecedenceTemplate(
                            currentConstraint.name,
                            correlationInfo, hasCorrelation, templateType.not,
                            templateType.refB.head,
                            helpers.getRefInputTypeAndVar(templateType.refB.head),
                            helpers.getRefName(templateType.refB.head),
                            templateType.refA.head,
                            helpers.getRefName(templateType.refA.head),
                            helpers.getRefInputTypeAndVar(templateType.refA.head)
                        )
                    }
                    else if(templateType instanceof ChainPrecedence) {
                        templateResult = pastTemplates.generateChainPrecedenceTemplate(
                            currentConstraint.name,
                            correlationInfo, hasCorrelation, templateType.not,
                            templateType.refB.head,
                            helpers.getRefInputTypeAndVar(templateType.refB.head),
                            helpers.getRefName(templateType.refB.head),
                            templateType.refA.head,
                            helpers.getRefName(templateType.refA.head),
                            helpers.getRefInputTypeAndVar(templateType.refA.head)
                        )
                    }
                    else if(templateType instanceof AlternatePrecedence) {
                        templateResult = pastTemplates.generateAlternatePrecedenceTemplate(
                            currentConstraint.name,
                            correlationInfo, hasCorrelation,
                            templateType.refB.head,
                            helpers.getRefInputTypeAndVar(templateType.refB.head),
                            helpers.getRefName(templateType.refB.head),
                            templateType.refA.head,
                            helpers.getRefName(templateType.refA.head),
                            helpers.getRefInputTypeAndVar(templateType.refA.head),
                            templateType.refC.head,
                            helpers.getRefName(templateType.refC.head),
                            helpers.getRefInputTypeAndVar(templateType.refC.head)
                        )
                    }
                    specBody = templateResult.getPsBody()
                    acceptanceJson = templateResult.getAcceptanceJson()
                }
                
                }
                else if(templateGroup instanceof Existential) {
                for(templateType : templateGroup.type) {
                    if(templateType instanceof AtLeast) {
                        templateResult = existentialTemplates.generateCountTemplate(
                            currentConstraint.name,
                            templateType.ref.head,
                            helpers.getRefInputTypeAndVar(templateType.ref.head),
                            helpers.getRefName(templateType.ref.head),
                            ">=",
                            templateType.num,
                            "ATLEAST")
                    }
                    else if(templateType instanceof AtMost) {
                        templateResult = existentialTemplates.generateCountTemplate(
                            currentConstraint.name,
                            templateType.ref.head,
                            helpers.getRefInputTypeAndVar(templateType.ref.head),
                            helpers.getRefName(templateType.ref.head),
                            "<=",
                            templateType.num,
                            "ATMOST")
                    }
                    else if(templateType instanceof Exact) {
                        templateResult = existentialTemplates.generateCountTemplate(
                            currentConstraint.name,
                            templateType.ref.head,
                            helpers.getRefInputTypeAndVar(templateType.ref.head),
                            helpers.getRefName(templateType.ref.head),
                            "==",
                            templateType.num,
                            "EXACT")
                    }
                    else if(templateType instanceof Init) {
                        templateResult = existentialTemplates.generateFirstEventTemplate(
                            currentConstraint.name,
                            templateType.ref.head,
                            helpers.getRefInputTypeAndVar(templateType.ref.head),
                            helpers.getRefName(templateType.ref.head),
                            "INIT")
                    }
                    else if(templateType instanceof End) {
                        templateResult = existentialTemplates.generateFirstEventTemplate(
                            currentConstraint.name,
                            templateType.ref.head,
                            helpers.getRefInputTypeAndVar(templateType.ref.head),
                            helpers.getRefName(templateType.ref.head),
                            "END")
                    }
                    specBody = templateResult.getPsBody()
                    acceptanceJson = templateResult.getAcceptanceJson()
                }
            }
        }
        
        var specPostfix = 
        '''
            SUT-blocks 
            depth-limits 1000
            state-limits 1000
            num-tests 1
        }

        '''
        val pspecFileName = generatedSpecName+ ".ps"
        val acceptanceJsonFileName = generatedSpecName + ".acceptance.json"
        val acceptancePythonFileName = generatedSpecName + ".acceptance.py"
        
        val referenceChecks = helpers.getReferenceChecks(currentConstraint, td)
        
        // Serialize the checks, then encode them for embedding in Python source.
        val referenceChecksJson = new GsonBuilder()
            .disableHtmlEscaping()
            .setPrettyPrinting()
            .create()
            .toJson(referenceChecks)
//            
//            new GsonBuilder().disableHtmlEscaping().create().toJson(referenceChecks)
//        val referenceChecksBase64 = java.util.Base64.getEncoder().encodeToString(
//            referenceChecksJson.getBytes(java.nio.charset.StandardCharsets.UTF_8)
//        )

//        if (currentConstraint.name == "inspectionConsumesPrintReport") {
//            System.out.println("getReferenceChecks returned for " + currentConstraint.name)
//            System.out.println(
//                referenceChecks
////                new GsonBuilder().setPrettyPrinting().create().toJson(referenceChecks)
//            )
//        }
        fsa.generateFile(
           constraintFolder + pspecFileName,
            specPrefix + tspecModel + specBody + specPostfix
        )
        
        fsa.generateFile(
            constraintFolder + acceptanceJsonFileName,
            acceptanceJson
        )
    
        fsa.generateFile(
            constraintFolder + acceptancePythonFileName,
            generateAcceptancePythonClass(
                generatedSpecName,
                currentConstraint.name,
                templateResult.getDiagnostics(),
                referenceChecksJson
            )
        )


        return new ConstraintGenerationResult(
            pspecFileName,
            acceptanceJsonFileName,
            acceptancePythonFileName,
            generatedSpecName,
            model.eResource.URI.toString
        )
    }
    
//    Generates a python class with the acceptance logic
    def String generateAcceptancePythonClass(String generatedSpecName, String constraintName, String diagnostics, String referenceChecksJson  ) {
        return
        '''
        import json
        import base64
        
        # used in generating diagnostics   
        # Token is a dict and this function flattens all its keys and values to strings 
        def format_value(value):
                    if isinstance(value, dict):
                        parts = []
                        for key, nested_value in value.items():
                            parts.append(
                                str(key) + " = " + format_value(nested_value)
                            )
                        return "{" + ", ".join(parts) + "}"
                    if isinstance(value, list):
                        return "[" + ", ".join(
                            format_value(item) for item in value
                        ) + "]"
                    return str(value)

        def format_token(token):
            if isinstance(token, dict):
                parts = []
                for key, value in token.items():
                    parts.append(
                        str(key) + " = " + format_value(value)
                    )
                return ", ".join(parts)
            return str(token)

        def violation_exists(node_violations, violation_kind, place):
            for violation in node_violations:
                if (
                    violation["kind"] == violation_kind
                    and violation["group"] == [place]
                ):
                    return True
            return False

        # look up, for a given node id, the list of violations recorded for it (or None)
        def find_node_violations(violations, node_id):
            for violation in violations:
                if violation["nodeId"] == node_id:
                    return violation["violations"]
            return None

        def build_diagnostics(rules, checked_nodes, violations):
            diagnostics = []
            for node in checked_nodes:
                node_violations = find_node_violations(violations, node["id"])
                if node_violations is None:
                    continue
                marking = node.get("marking", {})

                for rule in rules:
                    violation_kind = rule.get("violationKind", "emptyPlaces")
                    trigger_place = rule.get("triggerPlace", rule.get("tokenPlace"))
                    if not violation_exists(node_violations, violation_kind, trigger_place):
                        continue
                    token_place= rule.get("tokenPlace")
                    if token_place is None:
                        diagnostic = {
                            "kind": rule["kind"],
                            "nodeId": node["id"],
                            "place": trigger_place,
                            "message": rule["message"].format(**rule)
                        }
                    
                        for field_name in ("event", "violationStep"):
                            if field_name in rule:
                                diagnostic[field_name] = dict(rule[field_name])

                        diagnostics.append(diagnostic)
                        continue

                    for token in marking.get(token_place, []):
                        values = dict(rule)
                        if isinstance(token, dict):
                            metadata = token.get("MetaData", {})
                            correlation_token = {
                                key: value
                                for key, value in token.items()
                                if key != "MetaData"
                            }
                        else:
                            metadata = {}
                            correlation_token = token
                        values["correlation"] = format_token(correlation_token)
                        if rule.get("valueKind") == "count":
                            values["actualCount"] = token.get("count", 0)

                        diagnostic = {
                            "kind": rule["kind"],
                            "nodeId": node["id"],
                            "place": token_place,
                            "token": token,
                            "metadata": metadata,
                            "message": rule["message"].format(**values)
                        }

                        if rule.get("valueKind") == "count":
                            diagnostic["actualCount"] = values["actualCount"]
                            diagnostic["requirement"] = values["requirement"]

                        for event_name in ("event", "activationEvent", "targetEvent", "blockerEvent"):
                            if event_name in rule:
                                event = dict(rule[event_name])
                                metadata_key = event.pop("stepIdsFrom", None)
                                if metadata_key is not None:
                                    event["stepIds"] = metadata.get(metadata_key, [])

                                if not rule.get("hasCorrelation", True):
                                    event.pop("correlationBinding", None)
                                    event.pop("whereCorrelation", None)
                                diagnostic[event_name] = event

                        if "violationStep" in rule:
                            diagnostic["violationStep"] = dict(rule["violationStep"])

                        if (rule.get("valueKind") == "correlation" and rule.get("hasCorrelation", True)):
                            diagnostic["correlation"] = correlation_token

                        if not rule.get("includeRawToken", True):
                            diagnostic.pop("token", None)
                            diagnostic.pop("metadata", None)

                        diagnostics.append(diagnostic)
            return diagnostics

        def reference_path(expression):
            if not isinstance(expression, dict):
                return None    
            kind = expression.get("kind")
            # when kind is just a variable
            if kind == "variable":
                name = expression.get("name")
                if isinstance(name, str) and name:
                    return (name, ())
                return None
            # Decode the receiver, then append the selected record field
            if kind == "featureAccess":
                parent = reference_path(expression.get("receiver"))
                field = expression.get("feature")
                if parent is not None and isinstance(field, str) and field:
                    return (parent[0], parent[1] + (("field", field),))
                return None
            # Decode the map receiver, then append its literal string key.
            if kind == "mapAccess":
                parent = reference_path(expression.get("map"))
                key = expression.get("key")
                if (parent is not None and isinstance(key, dict)
                        and key.get("kind") == "string"
                        and isinstance(key.get("value"), str)):
                    return (parent[0], parent[1] + (("key", key["value"]),))
                return None
            # Treat get(receiver, index) as an indexed reference selection
            if kind == "functionCall" and expression.get("function") == "get":
                arguments = expression.get("arguments")
                # validation check for a function call (accpets argument and index and accepts only nonnegative literal integers in index)
                if not isinstance(arguments, list) or len(arguments) != 2:
                    return None
                parent = reference_path(arguments[0])
                index = arguments[1]
                if (parent is not None and isinstance(index, dict)
                        and index.get("kind") == "integer"
                        and type(index.get("value")) is int
                        and index["value"] >= 0):
                    return (parent[0], parent[1] + (("index", index["value"]),))
            return None

        # follows one instruction from reference_path inside a serialized container
        def select_child(expression, selector):
            # from the selector pair, take the selector kind and selection, for instance for "kind" map, "selector kind" is key
            selector_kind, selection = selector
            kind = expression["kind"]
            # A list stores its element expressions in "items".
            if selector_kind == "index" and kind == "list":
                items = expression["items"]
                if not 0 <= selection < len(items):
                    raise ValueError("List index out of range: " + str(selection))
                return items[selection]
            # A record stores named field entries, each containing a "value".
            if selector_kind == "field" and kind == "record":
                for field in expression["fields"]:
                    if field["name"] == selection:
                        return field["value"]
                raise ValueError("Missing record field: " + selection)
            # Map keys are expression objects; this version supports string keys.
            if selector_kind == "key" and kind == "map":
                for entry in expression["entries"]:
                    key = entry["key"]
                    if key["kind"] != "string":
                        raise ValueError("Only literal string map keys are supported")
                    if key["value"] == selection:
                        return entry["value"]
                raise ValueError("Missing map key: " + selection)

            # No inference of children inside references or incompatible expressions (tspec has more granularity than constraints)
            raise ValueError(
                "Cannot apply " + selector_kind + " selection to " + kind
            )

        # check if a serialized path is contained in another serialized path (parent = A.B and child = A.B.C)
        def is_prefix(parent, child):
            if parent is None or child is None or parent[0] != child[0]:
                return False
            return child[1][:len(parent[1])] == parent[1]

        # select which assignment expressions to check in the target for constraint's reference checks
        def select_target_regions(assignments, target):
            if target is None:
                raise ValueError("Unsupported constraint target")
            regions = []
            for assignment in assignments:
                assigned = reference_path(assignment["target"])
                if assigned is None:
                    raise ValueError("Unsupported assignment target")
                # if target is broad/abstract check if the assignment contains the target or vice-versa
                if not (is_prefix(assigned, target)
                        or is_prefix(target, assigned)):
                    continue
                value = assignment["value"]
                if is_prefix(assigned, target):
                    remaining = target[1][len(assigned[1]):]
                    for selector in remaining:
                        value = select_child(value, selector)
                regions.append(value)
            if not regions:
                raise ValueError("No assignment supplies the selected target")
            return regions

        def collect_references(expression):
            path = reference_path(expression)
            if path is not None:
                return [path]
            kind = expression["kind"]
            # Literal expressions contain no dependencies.
            if kind in ("string", "integer", "real", "boolean", "enum", "null"):
                return []
            # Follow the expression children already present in the serialized tree.
            if kind == "list":
                children = expression["items"]
            elif kind == "record":
                children = [
                    field["value"] for field in expression["fields"]
                ]
            elif kind == "map":
                children = [
                    entry["value"] for entry in expression["entries"]
                ]
            elif kind == "unary":
                children = [expression["operand"]]
            elif kind == "binary":
                children = [expression["left"], expression["right"]]
            else:
                raise ValueError("Unsupported reference expression: " + kind)
            # recursively collect references
            references = []
            for child in children:
                references.extend(collect_references(child))
            return references
            
        def compare_reference(check, activation_id, target_id):
            # decode the constraint's source selection.
            source = reference_path(check["source"])
            if source is None:
                raise ValueError("Unsupported constraint source")
            # bind the constraint source selection to the matched producer's output and add "output" in the middle
            expected = (
                activation_id,
                (("field", "output"),) + source[1],
            )
            # select the requested input region in the matched consumer step.
            target = reference_path(check["target"])
            assignments = check["assignments"].get(target_id, [])
            regions = select_target_regions(assignments, target)

            # collect explicit references only within those selected regions.
            actual = []
            for region in regions:
                actual.extend(collect_references(region))

            # a reference qualifies when it equals (with full granular constraints) or descends from the source (for broader constraint)
            matched = any(is_prefix(expected, path) for path in actual)
            return matched, expected, actual

        # every accepted pair: the target step must use the activation step's output
        def check_references(checks, checked_nodes):
            diagnostics = []
            for node in checked_nodes:
                for token in node.get("marking", {}).get("matchedPairs", []):
                    metadata = token.get("MetaData", {}) if isinstance(token, dict) else {}
                    for act_id in metadata.get("activationIds", []):
                        for tgt_id in metadata.get("targetIds", []):
                            for check in checks:
                                # compare structured paths for this matched step pair.
                                expected = None
                                actual = []
                                try:
                                    matched, expected, actual = compare_reference(check, act_id, tgt_id)
                                    reason = "No reference matches the expected source region"
                                except ValueError as error:
                                    # Report invalid selections without stopping evaluation.
                                    matched = False
                                    reason = str(error)
                                if not matched:
                                    diagnostics.append({
                                        "kind": "unsatisfiedReference",
                                        "nodeId": node["id"],
                                        "place": "matchedPairs",
                                        "target": check["targetText"],
                                        "source": check["sourceText"],
                                        "expected": expected,
                                        "actual": actual,
                                        "activationEvent": {"stepIds": [act_id]},
                                        "targetEvent": {"stepIds": [tgt_id]},
                                        "message": tgt_id + ": " + reason
                                    })
            return diagnostics
        
        class TemplateConformance:
            def __init__(self, acceptance_cond):
                self.acceptance_cond = acceptance_cond
                self.constraint_name = "«constraintName»"
                self.pspec_name = "«generatedSpecName»"
                
            # pass the diagnostics logic for each template
            def diagnostic_rules(self):
                return «diagnostics»
            
            # pass the reference check rules for each constraint    
            def reference_checks(self):
                return json.loads(r"""«referenceChecksJson»""")
                        
            # evaluates the acceptance condition on the reachability graph
            def evaluate(self, reachability_graph):
                acceptance = self.acceptance_cond.get("acceptance", {})
                scope = acceptance.get("scope")
                monitor_places= acceptance.get("monitorPlaces",[])
                empty_place_groups = acceptance.get("emptyPlaces", [])
                non_empty_place_groups = acceptance.get("nonEmptyPlaces", [])
        
                # selects the nodes in scope
                checked_nodes = self._select_nodes(reachability_graph, scope)
                violations = []
                
                # check the markings for checked nodes and validate them against empty and non-empty place groups
                # it checks for each group and append if there is any violation (it is an AND over the groups)
                for node in checked_nodes:
                    marking = node.get("marking", {})
                    node_violations = []
        
                    for group in empty_place_groups:
                        if not self._empty_group_satisfied(marking, group):
                            node_violations.append({
                                "kind": "emptyPlaces",
                                "group": group
                            })
        
                    for group in non_empty_place_groups:
                        if not self._non_empty_group_satisfied(marking, group):
                            node_violations.append({
                                "kind": "nonEmptyPlaces",
                                "group": group
                            })
        
                    if len(node_violations) != 0:
                        violations.append({
                            "nodeId": node.get("id"),
                            "violations": node_violations
                        })
                reference_diagnostics = check_references(self.reference_checks(), checked_nodes)
        
                return {
                    "constraint": self.acceptance_cond.get("constraint"),
                    "expectedConstraint": self.constraint_name,
                    "generatedPspec": self.pspec_name,
                    "templateType": self.acceptance_cond.get("templateType"),
                    "accepted": len(violations) == 0 and len(reference_diagnostics) == 0,
                    "scope": scope,
                    "checkedNodeIds": [node.get("id") for node in checked_nodes],
                    "violations": violations,
                    "diagnostics": build_diagnostics(self.diagnostic_rules(), checked_nodes, violations)+ reference_diagnostics
                }
        
            def _select_nodes(self, reachability_graph, scope):
                nodes = reachability_graph.get("nodes", [])
                
                # collects all terminal nodes which have no outgoing edges
                # for our purpose, this can only be one node (the last one) but this is a more general implementation
                if scope == "terminalNodes":
                    outgoing_sources = set(
                        edge.get("source")
                        for edge in reachability_graph.get("edges", [])
                    )
                    return [
                        node
                        for node in nodes
                        if node.get("id") not in outgoing_sources
                    ]
        
                if scope == "allNodes":
                    return nodes
        
                raise ValueError("Unsupported acceptance scope: %s" % scope)
        
            # check if empty places conditions are satisfied
            # whenever a place is empty, it satisfies immediately (an OR inside a group)
            def _empty_group_satisfied(self, marking, group):
                for place in group:
                    if self._is_place_empty(marking, place):
                        return True
                return False
        
            # check if non-empty places conditions are satisfied
            # an OR inside a group
            def _non_empty_group_satisfied(self, marking, group):
                for place in group:
                    if not self._is_place_empty(marking, place):
                        return True
                return False
                
            # check if a place in a marking has a token or not 
            def _is_place_empty(self, marking, place):
                tokens = marking.get(place, [])
                return len(tokens) == 0
        
        # loads the acceptance condition from the acceptance json file
        def load_acceptance_analyzer(acceptance_json_path):
            with open(acceptance_json_path, "r", encoding="utf-8") as reader:
                acceptance_cond = json.load(reader)
            return TemplateConformance(acceptance_cond)
        
        #directly runs the function with three arguments
        if __name__ == "__main__":
            import sys
            acceptance_json_path, rg_json_path, verdict_json_path = sys.argv[1:4]
            analyzer = load_acceptance_analyzer(acceptance_json_path)
            with open(rg_json_path, "r", encoding="utf-8") as reader:
                graph = json.load(reader)
            result = analyzer.evaluate(graph)
            with open(verdict_json_path, "w", encoding="utf-8") as writer:
                json.dump(result, writer, indent=2)
        '''
}

    // function to collect types from imports recursively //
    def String generateTypes(EObject rootModel) {
        val Set<EObject> visited = new HashSet()
        return collectOnlyTypes(rootModel, visited)
    }

    private def String collectOnlyTypes(EObject model, Set<EObject> visited) {
        if (model === null || visited.contains(model)) {
            return ""
        }
        visited.add(model) 

        var resultText = ""

        if (model instanceof TypesModel) {
            for (imp : model.imports) {
                val input = imp.resource?.contents?.head
                resultText += collectOnlyTypes(input, visited)
            }
        } 
        else if (model instanceof Constraints) {
            for (imp : model.imports) {
                val input = imp.resource?.contents?.head
                resultText += collectOnlyTypes(input, visited)
            }
        }

        if (model instanceof TypesModel) {
            for (typeDecl : model.types) {
                val node = NodeModelUtils.getNode(typeDecl)
                if (node !== null) {
                    resultText += "\n" + node.text
                }
            }
        }

        return resultText
    }

    def isRefInfoPresent(ArrayList<RefInfo> labelList, RefInfo refInfo) {
        for(elm : labelList) {
            if(refInfo.refName.equals(elm.refName) && refInfo.refType.equals(elm.refType)) {
                return true
            }
        }
        return false
    }

//  compute relevant labels for each constraints (adds ANY)
    def computeLabelSet(Template currentConstraint) {
        var labelList = new ArrayList<RefInfo>
            for(templateGroup : currentConstraint.type) {
                for (templateType : helpers.getTemplateTypes(templateGroup)){
                    for (ref : helpers.getRefsforTemplate(templateType)){
                        if (ref instanceof RefAction) {
                            val info = helpers.getRefInputTypeAndVar(ref)
                            if (!isRefInfoPresent(labelList, info))
                                labelList.add(info)
                        }
                    }
                }
            }
        val anyInfo = new RefInfo("ANY", "any")
        if(!isRefInfoPresent(labelList, anyInfo))
            labelList.add(anyInfo)
        return labelList
    }

    private def getTypeName(AbstractStep step) {
        return step.stepVar.type.typeName
    }
}