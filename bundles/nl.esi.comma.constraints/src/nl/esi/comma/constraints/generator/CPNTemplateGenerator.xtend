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
 
package nl.esi.comma.constraints.generator

import com.google.inject.Inject
import java.util.HashSet
import java.util.Set
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.Future
import nl.esi.comma.constraints.constraints.Ref
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.Response
import nl.esi.xtext.actions.actions.AssignmentAction
import nl.esi.xtext.expressions.expression.Expression
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

class CPNTemplateGenerator 
{
    @Inject extension ISerializer serializer

    def generatePS(Constraints model, IFileSystemAccess2 fsa) 
    {
        var typesText = new String
        var specBody = ''''''

        // get first layer of types definitions
        typesText = typesText + "\n\n" + generateTypes(model)

        // parse custom defined types and append to existing type definitions
        for(typ : model.types) {
            var node = NodeModelUtils.getNode(typ)
            if (node !== null) {
                typesText = typesText + node.getText()
            }
        }
        System.out.println(typesText)
        var uri = model.eResource.getURI()
        if (uri === null) return "Unknown URI"
        var fileName = uri.trimFileExtension().lastSegment()
        // generate types file that will be imported into the generated ps file
        fsa.generateFile(fileName + ".types", typesText)

        // start computing the ps file
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
        fsa.generateFile(fileName + ".ps", specPrefix + specBody + specPostfix)
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

    // Generate PSpec System for Response Template
    // TODO create class for Declare Template generator functions
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
    }

    def String cleanSerialize(AssignmentAction expr) {
        if (expr === null || expr.eResource === null) { return "" }
        val resource = expr.eResource as XtextResource
        val serializer = resource.resourceServiceProvider.get(ISerializer)
        return serializer.serialize(expr).trim
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