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
package nl.esi.comma.testspecification.generator.utils

import java.util.Map
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction
import nl.esi.xtext.common.lang.utilities.EcoreUtil3
import nl.esi.xtext.expressions.evaluation.ExpressionEvaluator
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionBracket
import nl.esi.xtext.expressions.expression.ExpressionRecord
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess
import nl.esi.xtext.expressions.expression.ExpressionVariable
import nl.esi.xtext.expressions.expression.Field
import nl.esi.xtext.expressions.expression.Variable
import nl.esi.xtext.types.types.MapTypeConstructor
import nl.esi.xtext.types.types.RecordField
import nl.esi.xtext.types.types.Type
import nl.esi.xtext.types.types.TypeReference
import nl.esi.xtext.types.types.TypesFactory
import nl.esi.xtext.types.types.VectorTypeConstructor
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.xtext.actions.utilities.ActionsUtilities.*
import static extension nl.esi.xtext.expressions.utilities.ExpressionsUtilities.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*

class Utils 
{
    private new() {
        // Empty
    }

    static def void evaluateAssertions(AssertionStep step) {
        // Prepare evaluation context, copy the initializers such that they remain unchanged
        val stepInput = step.stepVar.createValue((step.context + step.input + step.sut).map[copy])

        // Evaluate all expressions in all assertions
        val Map<Variable, Expression> variableExpressions = newHashMap(step.stepVar -> stepInput)
        val ExpressionEvaluator expressionEvaluator = EcoreUtil3.getService(step, ExpressionEvaluator)
        for (assert : step.asserts) {
            for (val iter = assert.eAllContents; iter.hasNext;) {
                switch (expr: iter.next) {
                    ExpressionBracket case (!(expr.eContainer instanceof Expression)): {
                        // Do not evaluate top level bracket expressions
                    }
                    Expression: {
                        val replacement = expressionEvaluator.evaluate(expr)[variableExpressions.get(it)]
                        expr.replace(replacement)
                        iter.prune
                    }
                }
            }
        }
    }

    static def Expression createValue(Variable variable, Iterable<RecordFieldAssignmentAction> fieldInitializers) {
        val variableValue = variable.type.typeObject.createDefaultValue[true]
        for (action : fieldInitializers.filter[exp !== null && assignment === variable]) {
            val field = variableValue.resolveField(action.fields)
            if (field !== null) {
                field.exp = action.exp
            }
        }
        return variableValue
    }

    private static def Field resolveField(Expression expression, Iterable<RecordField> fields) {
        if (expression instanceof ExpressionRecord) {
            val field = expression.fields.findFirst[recordField === fields.head]
            if (field !== null && !fields.tail.isEmpty) {
                return field.exp.resolveField(fields.tail)
            }
            return field
        }
    }

    static def Expression filterRecordFields(Expression expression, (RecordField)=>boolean filter) {
        for (val iterator = expression.eAllContents; iterator.hasNext;) {
            val exprRec = iterator.next
            if (exprRec instanceof ExpressionRecord) {
                exprRec.fields.removeIf[!filter.apply(recordField)]
            }
        }
        // TODO: Should we remove empty records?
        return expression
    }

    dispatch static def String printField(ExpressionRecordAccess exp) {
        return exp.record.printField + '.' + exp.field.name
    }

    dispatch static def String printField(ExpressionVariable exp) {
        return exp.variable.name
    }

    // Types utilities

    static def Type getOuterDimension(VectorTypeConstructor type) {
        return if (type.dimensions.size > 1) {
            EcoreUtil.copy(type) => [
                dimensions.removeLast
            ]
        } else {
            TypesFactory.eINSTANCE.createTypeReference => [
                type = type.type
            ]
        }
    }

    dispatch static def String getTypeName(TypeReference type) '''
        «type.type.name»'''

    dispatch static def String getTypeName(VectorTypeConstructor type) '''
        «type.type.name»«FOR dimension : type.dimensions»[]«ENDFOR»'''

    dispatch static def String getTypeName(MapTypeConstructor type) '''
        map<«type.type.name», «type.valueType.typeName»>'''

}