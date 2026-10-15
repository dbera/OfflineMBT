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
import nl.esi.comma.assertthat.assertThat.AssertThatBlock
import nl.esi.comma.assertthat.assertThat.GenericScriptBlock
import nl.esi.comma.testspecification.testspecification.AbstractStep
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.comma.testspecification.testspecification.StepSequence
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction
import nl.esi.xtext.common.lang.utilities.EcoreUtil3
import nl.esi.xtext.expressions.evaluation.ExpressionEvaluator
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionRecord
import nl.esi.xtext.expressions.expression.Field
import nl.esi.xtext.expressions.expression.Variable
import nl.esi.xtext.types.types.RecordField
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension nl.esi.xtext.actions.utilities.ActionsUtilities.*
import static extension nl.esi.xtext.expressions.utilities.ExpressionsUtilities.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*

class EvaluateDataExpressions {
    def static void transform(Resource resource) {
        resource.contents.filter(TSMain).flatMap[model.stepSeq].forEach[evaluateDataExpressions]
    }

    def private static void evaluateDataExpressions(StepSequence stepSequence) {
        extension val evaluator = new ImperativeEvaluator(EcoreUtil3.getService(stepSequence, ExpressionEvaluator))

        for (step : stepSequence.step) {
            step.stepVar.declare
            step.context.forEach[evaluateAction]
            step.input.forEach[evaluateAction]
            if (step instanceof AssertionStep) {
                step.asserts.flatMap[constr].forEach[evaluateAssert]
            }
        }
    }

    @FinalFieldsConstructor
    static class ImperativeEvaluator {
        val Map<Variable, Expression> variableExpressions = newHashMap

        val ExpressionEvaluator expressionEvaluator

        def void declare(Variable variable) {
            variableExpressions.put(variable, variable.type.typeObject.createDefaultValue)
        }

        def void evaluateAction(RecordFieldAssignmentAction action) {
            action.exp = action.exp.evaluate

            // Update the evaluation context
            val field = variableExpressions.get(action.assignment).resolveField(action.fields)
            if (field !== null) {
                field.exp = action.exp.copy
            }
        }

        dispatch def void evaluateAssert(AssertThatBlock block) {
            if (block.name == 'report_result') {
                val bla = variableExpressions.get(block.getContainerOfType(AbstractStep).stepVar)
                println('Here')
            }
            block.output.sub = block.output.sub.evaluate
        }

        dispatch def void evaluateAssert(GenericScriptBlock block) {
        }

        def Expression evaluate(Expression expression) {
            return expressionEvaluator.evaluate(expression)[variableExpressions.get(it)]
        }

        static def Field resolveField(Expression expression, Iterable<RecordField> fields) {
            if (expression instanceof ExpressionRecord) {
                val field = expression.fields.findFirst[recordField == fields.head]
                if (field !== null && !fields.tail.isEmpty) {
                    return field.exp.resolveField(fields.tail)
                }
                return field
            }
        }
    }
}
