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