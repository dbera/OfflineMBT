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

import nl.esi.comma.constraints.generator.cpn.model.RefInfo
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.Ref
import nl.esi.xtext.expressions.expression.Expression
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.common.util.EList
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.serializer.ISerializer
import nl.esi.xtext.actions.actions.AssignmentAction
import nl.esi.comma.testspecification.testspecification.TestDefinition
import java.util.List
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.AssertionStep
import org.eclipse.emf.ecore.EObject

class Helpers {
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
    
    //TODO{discuss: made this a counting function in the helper class}
    //Counts the size of a trace here
    def countTraceSize(TestDefinition td, List<RefInfo> labellist)
    {
        var idx = 0
        
        for(ss : td.stepSeq) {
            for(step: ss.step) {
                if(step instanceof RunStep) {
                    idx++
                }
                else if(step instanceof AssertionStep) {
                    idx++
                }
                else {}
            }
        }
        return idx
    }
    //TODO{discuss: adding a helper function to get all refs as a list for a template type}
    def getRefsforTemplate(EObject templatetype){
        val reflist = newArrayList
        for (feature : templatetype.eClass.EAllStructuralFeatures) {
            if (feature.name.startsWith("ref")) {
                val refs = templatetype.eGet(feature) as List<Ref>
                
                if (!refs.empty)
                    reflist.add(refs.head)
            }
        }
        return reflist
    }
    
    //TODO{discuss: adding a helper function to get all templatetypes of a templategroup
    //    as there is no superclass implementation in the grammar}
    def getTemplateTypes(EObject templateGroup){
        val feature = templateGroup.eClass.getEStructuralFeature("type")
        
        if (feature !== null)
            return templateGroup.eGet(feature) as List<EObject>
        else
            return emptyList
    }
    
//    returns "where-concrete" guard
//    TODO{it should return "true" if there is no clause, check the null function}
    def getRefConcreteWhereClause(Ref ref) {
        if(ref instanceof RefAction) {
            if (ref.whereArgs.isNullOrEmpty) 
                return "true"
            return getConjunction(ref.whereArgs)
        }
//        System.out.println("message")
        return null
    }
    
//    returns guard for repeated activation tasks
    def getRefRepeatedActivationWhereClause(Ref ref) {
    if(ref instanceof RefAction) {
        val concreteWhere = getRefConcreteWhereClause(ref)
        val correlationWhere =
            if (!ref.whereOptArgs.isNullOrEmpty)
                getConjunction(ref.whereOptArgs)
            else if (!ref.withArgs.isNullOrEmpty)
                getWithConjunction(ref.withArgs).replace(":=", "==").trim
            else
                "true"
    
        if (concreteWhere == "true") return correlationWhere
        if (correlationWhere == "true") return concreteWhere
        return '''«concreteWhere» and «correlationWhere»'''
        }
        return null
    }

//    returns "where-correlation" guard
    def getRefCorrelationWhereClause(Ref ref) {
        if(ref instanceof RefAction) {
            if(ref.whereOptArgs !== null)
                return getConjunction(ref.whereOptArgs)
        }
        return null    
    }

//  returns combination of "where-concrete" and "where-correlation" guards
//  TODO{here also if both are not there, "true" should be returned}
    def getRefCombinedWhereClause(Ref ref) {
        if(ref instanceof RefAction) {
            val EList<Expression> temp = new BasicEList<Expression>()
            if (ref.whereArgs !== null) temp.addAll(ref.whereArgs)
            if (ref.whereOptArgs !== null) temp.addAll(ref.whereOptArgs)
            if (temp.isNullOrEmpty) 
                return "true"
            return getConjunction(temp)
        }
        return null
    }

//  returns "with" bindings
    def getRefWithClause(Ref ref) {
        if(ref instanceof RefAction) {
            if (ref.withArgs !== null) 
                return getWithConjunction(ref.withArgs)
        }
        return null
    }
    
//    TODO{need a helper function to generate correlation clauses for repeated activation}
//    def getRepeatedActivationGuard(Ref ref, Variable correlationVar) {
//        if (!(ref instanceof RefAction) || ref.withArgs.isNullOrEmpty)
//            return "false"
//
//         
//    }

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
    
}