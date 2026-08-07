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

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import java.util.Set
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.Future
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.Response
import nl.esi.comma.constraints.constraints.Template
import nl.esi.comma.constraints.generator.cpn.model.RefInfo
import nl.esi.comma.constraints.generator.cpn.templates.FutureTemplates
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction
import nl.esi.xtext.expressions.expression.ExpressionVariable
import nl.esi.xtext.types.types.TypesModel
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.nodemodel.util.NodeModelUtils

import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*

// import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
// import org.eclipse.emf.common.util.URI
// import org.eclipse.xtext.resource.XtextResourceSet

class CPNTemplateGenerator 
{
    val FutureTemplates futureTemplates = new FutureTemplates
    val Helpers helpers = new Helpers

// it should generate different pspec files for different constraints in the constraint file
    def generatePSpec(
        Resource res, IFileSystemAccess2 fsa, 
        List<Constraints> constraints,
        TSMain tsMain) {
        for(constraintsSource : constraints){
            for (constraintDef : constraintsSource.templates){
                generateConstraintPS(constraintsSource, constraintDef, tsMain.model as TestDefinition, fsa)
//                TODO{discuss: why new object?}
//            new CPNTemplateGenerator().generateConstraintPS(constraintsSource, constraintDef,
//                tsMain.model as TestDefinition, fsa
//            )
            }
        }
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
            outputs
            «FOR l : labelList»
                «l.refType» «l.refName»
            «ENDFOR»

            local
            «FOR i : 0..idx»
                UNIT p«i»
            «ENDFOR»
            
        init
            p0 := UNIT { unit = 0 }

            desc "TSpecCPNModel"

            «FOR ss : td.stepSeq»
                «FOR step : ss.step» 
                    «IF step instanceof RunStep || step instanceof AssertionStep»
                        action «step.type.name»_«_idx»
                        element-label "«step.type.name»"
                        case default
                        with-inputs p«_idx»
                        «IF isStepNamePresent(labelList,step.stepVar.name)»
                            produces-outputs «step.stepVar.name»
                            updates:
                                // Constructor
                                «step.stepVar.name» := «Utils.defaultValue(step.stepVar.type.type, step.stepVar.name)»
                            «FOR elm : step.refStep»
                                «FOR act : elm.input.actions»
                                    «IF act instanceof RecordFieldAssignmentAction»
                                        «IF act.exp.eAllContents.filter(ExpressionVariable).isEmpty»
                                            // ReferenceExp. TODO Skip.
                                        «ENDIF»
                                    «ENDIF»
                                    «NodeModelUtils.getNode(act).text.replaceAll("(?m)^\\s*$\\R?", "")»
                                «ENDFOR»
                            «ENDFOR»
                        «ELSE»
                            produces-outputs any
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
        '''
        var specBody = ''''''

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
        if (uri === null) return "Unknown URI"
        var fileName = uri.trimFileExtension().lastSegment()
        val generatedSpecName = fileName + "_" + currentConstraint.name 
        // generate types file that will be imported into the generated ps file
        fsa.generateFile(fileName + ".types", typesText)

        // state computing ps system model based on concrete tspec
        var tspecModel = generateTSpecModel(td, computeLabelSet(currentConstraint))

        // start computing ps system model based on declare constraints
        var specPrefix = 
        '''
        import "«fileName».types"

        specification «generatedSpecName»
        {
        '''
        // parse declare templates
        // TODO{we have to make it for each constraint, not template}
        for(templateGroup : currentConstraint.type) {
            if(templateGroup instanceof Future) {
                for(templateType : templateGroup.type) {
                    if(templateType instanceof Response) {
                        specBody = futureTemplates.generateResponseTemplate(
                            currentConstraint.name,
                            currentConstraint.variables.head,
                            templateType.refA.head,
                            helpers.getRefInputTypeAndVar(templateType.refA.head),
                            helpers.getRefName(templateType.refA.head),
                            templateType.refB.head,
                            helpers.getRefName(templateType.refB.head),
                            helpers.getRefInputTypeAndVar(templateType.refB.head)
                        )
                    }
                }
            }
        }
        
//        for ( t : model.templates) {
//            for(elm : t.type) {
//                if(elm instanceof Future) {
//                    for(elmInst : elm.type) {
//                        if(elmInst instanceof Response) {
//                            specBody = futureTemplates.generateResponseTemplate(
//                                t.name,
//                                t.variables.head,
//                                elmInst.refA.head,
//                                helpers.getRefInputTypeAndVar(elmInst.refA.head),
//                                helpers.getRefName(elmInst.refA.head),
//                                elmInst.refB.head,
//                                helpers.getRefName(elmInst.refB.head),
//                                helpers.getRefInputTypeAndVar(elmInst.refB.head)
//                            )
//                        }
//                    }
//                }
//            }
//        }
        var specPostfix = 
        '''
            SUT-blocks 
            depth-limits 1000
            state-limits 1000
            num-tests 1
        }

        '''
        fsa.generateFile(
            generatedSpecName + ".ps",
            specPrefix + tspecModel + specBody + specPostfix
        )
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

    // Generate PSpec System for Response Template
    //TODO{discuss: here we need compute label for each constraint, not combination of all constraints}
    //TODO{This also can be made more general and moved to helper class. This is not really template specific.}
    def computeLabelSet(Template currentConstraint) {
        var labelList = new ArrayList<RefInfo>
            for(templateGroup : currentConstraint.type) {
                if(templateGroup instanceof Future) {
                    for(templateType : templateGroup.type) {
                        if(templateType instanceof Response) {
                            if(templateType.refA.head instanceof RefAction) {
                                if(!isRefInfoPresent(labelList, helpers.getRefInputTypeAndVar(templateType.refA.head)))
                                    labelList.add(helpers.getRefInputTypeAndVar(templateType.refA.head))
                            }
                            if(templateType.refB.head instanceof RefAction) {
                                if(!isRefInfoPresent(labelList, helpers.getRefInputTypeAndVar(templateType.refB.head)))
                                    labelList.add(helpers.getRefInputTypeAndVar(templateType.refB.head))
                            }
                        }
                    }
                }
            }
        val anyInfo = new RefInfo("ANY", "any")
//        TODO{discuss: emitting ANY here}
        if(!isRefInfoPresent(labelList, anyInfo))
            labelList.add(anyInfo)
        return labelList
    }
}
//    def computeLabelSet(EList<Template> tlist) {
//        var labelList = new ArrayList<RefInfo>
//        for(t : tlist) {
//            for(elm : t.type) {
//                if(elm instanceof Future) {
//                    for(elmInst : elm.type) {
//                        if(elmInst instanceof Response) {
//                            if(elmInst.refA.head instanceof RefAction) {
//                                if(!isRefInfoPresent(labelList, helpers.getRefInputTypeAndVar(elmInst.refA.head)))
//                                    labelList.add(helpers.getRefInputTypeAndVar(elmInst.refA.head))
//                            }
//                            if(elmInst.refB.head instanceof RefAction) {
//                                if(!isRefInfoPresent(labelList, helpers.getRefInputTypeAndVar(elmInst.refB.head)))
//                                    labelList.add(helpers.getRefInputTypeAndVar(elmInst.refB.head))
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        return labelList
//    }
//}