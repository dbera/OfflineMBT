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
import nl.esi.comma.constraints.constraints.Ref
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.Response
import nl.esi.comma.constraints.constraints.Template
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TestDefinition
import nl.esi.xtext.actions.actions.AssignmentAction
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess
import nl.esi.xtext.expressions.expression.Variable
import nl.esi.xtext.types.types.TypesModel
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.serializer.ISerializer

import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import nl.esi.xtext.expressions.expression.ExpressionVariable
import org.eclipse.emf.ecore.resource.Resource
import nl.esi.comma.testspecification.testspecification.TSMain

// import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
// import org.eclipse.emf.common.util.URI
// import org.eclipse.xtext.resource.XtextResourceSet

class CPNTemplateGenerator 
{

    def generatePSpec(
        Resource res, IFileSystemAccess2 fsa, 
        List<Constraints> constraints,
        TSMain tsMain) {
        for(constraintsSource : constraints){
            (new CPNTemplateGenerator().generatePS(constraintsSource, tsMain.model as TestDefinition, fsa))
        }
    }

    def isStepNamePresent(List<RefInfo> labelList, String name) {
        for(label : labelList) { if(label.refName.equals(name)) return true }
        return false
    }

    def generateTSpecModel(TestDefinition td, List<RefInfo> labelList) 
    {
        var idx = 0
        for(ss : td.stepSeq) {
            for(step: ss.step) {
                if(step instanceof RunStep) {
                    if(isStepNamePresent(labelList, step.stepVar.name)) idx++
                }
                else if(step instanceof AssertionStep) {
                    if(isStepNamePresent(labelList, step.stepVar.name)) idx++
                }
                else {}
            }
        }
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
                    «IF step instanceof RunStep && isStepNamePresent(labelList, step.stepVar.name)»
                        action «step.type.name»_«_idx»
                        element-label "«step.type.name»"
                        case default
                        with-inputs p«_idx»
                        produces-outputs «step.stepVar.name»
                        updates:
                            // Constructor
                            «step.stepVar.name» := «Utils.defaultValue(step.stepVar.type.type, step.stepVar.name)»
                        «FOR elm : step.refStep»
                            «FOR act : elm.input.actions»
                                «IF act instanceof RecordFieldAssignmentAction»«IF act.exp.eAllContents.filter(ExpressionVariable).isEmpty»   // ReferenceExp. TODO Skip. «ENDIF»«ENDIF»
                                «NodeModelUtils.getNode(act).text.replaceAll("(?m)^\\s*$\\R?", "")»
                            «ENDFOR»
                        «ENDFOR»
                        produces-outputs p«_idx+1»
                        «{_idx++ ""}»
                    «ELSEIF step instanceof AssertionStep && isStepNamePresent(labelList, step.stepVar.name)»
                    «ENDIF»
                «ENDFOR»
            «ENDFOR»
        }
        '''
    }

    def generatePS(Constraints model, TestDefinition td, IFileSystemAccess2 fsa) 
    {
        var typesText = '''''' 
//        '''
//        record UNIT {
//            int unit
//        }
//        '''
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
        // generate types file that will be imported into the generated ps file
        fsa.generateFile(fileName + ".types", typesText)

        // state computing ps system model based on concrete tspec
        var tspecModel = generateTSpecModel(td, computeLabelSet(model.templates))

        // start computing ps system model based on declare constraints
        var specPrefix = 
        '''
        import "«fileName».types"

        specification «fileName»
        {
        '''
        // parse declare templates
        for ( t : model.templates) {
            for(elm : t.type) {
                if(elm instanceof Future) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof Response) {
                            specBody = generateResponseTemplate(
                                t.name,
                                t.variables.head,
                                elmInst.refA.head,
                                getRefInputTypeAndVar(elmInst.refA.head),
                                getRefName(elmInst.refA.head),
                                elmInst.refB.head,
                                getRefName(elmInst.refB.head),
                                getRefInputTypeAndVar(elmInst.refB.head)
                            )
                        }
                    }
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
        fsa.generateFile(fileName + ".ps", specPrefix + tspecModel + specBody + specPostfix)
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
    // TODO create class for Declare Template generator functions
    def computeLabelSet(EList<Template> tlist) {
        var labelList = new ArrayList<RefInfo>
        for(t : tlist) {
            for(elm : t.type) {
                if(elm instanceof Future) {
                    for(elmInst : elm.type) {
                        if(elmInst instanceof Response) {
                            if(elmInst.refA.head instanceof RefAction) {
                                if(!isRefInfoPresent(labelList, getRefInputTypeAndVar(elmInst.refA.head)))
                                    labelList.add(getRefInputTypeAndVar(elmInst.refA.head))
                            }
                            if(elmInst.refB.head instanceof RefAction) {
                                if(!isRefInfoPresent(labelList, getRefInputTypeAndVar(elmInst.refB.head)))
                                    labelList.add(getRefInputTypeAndVar(elmInst.refB.head))
                            }
                        }
                    }
                }
            }
        }
        return labelList
    }

    def generateResponseTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo actEventInfo, String activationEvent, 
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    ) 
    {
       return
       '''
           system RootRESPONSE
           {
               inputs
               «actEventInfo.refType» «actEventInfo.refName»
               «IF targetEventInfo.refType != actEventInfo.refType && targetEventInfo.refName != actEventInfo.refName»
                   «targetEventInfo.refType» «targetEventInfo.refName»
               «ENDIF»

               local
               «correlationVar.type.type.name» «correlationVar.name»
               UNIT split

               desc "«templateName»"

               action          UnactivatedTarget
               element-label   "Unactivated Target"
               case            default priority 10
               with-inputs     «targetEventInfo.refName»
               with-guard      «getRefWhereClause(targetEventInst)»

               action          RepeatedActivation
               element-label   "Repeated Activation"
               case            default priority 30
               with-inputs     split, «actEventInfo.refName», «correlationVar.name»
               with-guard      «getRefAllWhereClause(activationEventInst)»
               produces-outputs    split suppress
               updates:
                   split := split
               produces-outputs «correlationVar.name»
               updates:
                   «correlationVar.name» := «correlationVar.name»

               action          Target
               element-label   "Target"
               case            default priority 20
               with-inputs     split, «targetEventInfo.refName», «correlationVar.name»
               with-guard      «getRefWhereClause(targetEventInst)»

               action          Activation
               element-label   "Activation"
               case            default priority 20
               with-inputs     «actEventInfo.refName»
               with-guard      «getRefWhereClause(activationEventInst)»
               produces-outputs split suppress
               produces-outputs «correlationVar.name»
               updates:
                   «getRefWithClause(activationEventInst)»

               element-labels ["Root", "RESPONSE"]
           }
       ''' 
    }

    // Helper Functions //
    // TODO Move to Helper Class
    def getRefName(Ref ref){
        var refName = new String
        if(ref instanceof RefAction) { refName = ref.action.name ?: "" }
        return refName
    }

    def getRefInputTypeAndVar(Ref ref) 
    {
        var refInfo = new RefInfo
        if(ref instanceof RefAction) {
            var inputVar = ref.action.inputs.head
            refInfo = new RefInfo(inputVar.type.type.name,  inputVar.name)
        }
        return refInfo
    }

    def getRefWhereClause(Ref ref) {
        if(ref instanceof RefAction) {
            if (ref.whereArgs !== null) 
                return getConjunction(ref.whereArgs)
        }
        return null
    }

    def getRefAllWhereClause(Ref ref) {
        if(ref instanceof RefAction) {
            val EList<Expression> temp = new BasicEList<Expression>()
            if (ref.whereArgs !== null) temp.addAll(ref.whereArgs)
            if (ref.whereOptArgs !== null) temp.addAll(ref.whereOptArgs)
            return getConjunction(temp)
        }
        return null
    }

    def getRefWithClause(Ref ref) {
        if(ref instanceof RefAction) {
            if (ref.withArgs !== null) 
                return getWithConjunction(ref.withArgs)
        }
        return null
    }

    def getConjunction(EList<Expression> eList) {
        return
        '''«FOR e : eList SEPARATOR " and "»«e.cleanSerialize»«ENDFOR»'''
    }

    def getWithConjunction(EList<AssignmentAction> aList) {
        return
        '''
        «FOR a : aList SEPARATOR " and "»«a.cleanSerialize»«ENDFOR»
        '''
    }
    // End of Helper Functions //

    // Utility function to serialize EObjects //
    // TODO Move to utility class
    def String cleanSerialize(Expression expr) {
        if (expr === null || expr.eResource === null) { return "" }
        val resource = expr.eResource as XtextResource
        val serializer = resource.resourceServiceProvider.get(ISerializer)
        return serializer.serialize(expr).trim
//        return serialize(expr).trim
    }

    def String cleanSerialize(AssignmentAction expr) {
        if (expr === null || expr.eResource === null) { return "" }
        val resource = expr.eResource as XtextResource
        val serializer = resource.resourceServiceProvider.get(ISerializer)
        return serializer.serialize(expr).trim
//        return serialize(expr).trim
    }
    // End of Utility functions //
}

// Helper Class //
class RefInfo {
    var refType = new String
    var refName = new String
    
    new() {
        refType = new String
        refName = new String
    }
    
    new (String _refType, String _refName) {
        refType = _refType
        refName = _refName
    }
    
    def getRefType() { return refType}
    def getRefName() { return refName}
}