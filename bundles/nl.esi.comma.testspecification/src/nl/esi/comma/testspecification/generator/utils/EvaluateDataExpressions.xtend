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
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.xtext.common.lang.utilities.EcoreUtil3
import nl.esi.xtext.expressions.evaluation.ExpressionEvaluator
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionBracket
import nl.esi.xtext.expressions.expression.ExpressionFactory
import nl.esi.xtext.expressions.expression.ExpressionRecord
import nl.esi.xtext.expressions.expression.Field
import nl.esi.xtext.expressions.expression.Variable
import nl.esi.xtext.types.types.EnumTypeDecl
import nl.esi.xtext.types.types.MapTypeConstructor
import nl.esi.xtext.types.types.MapTypeDecl
import nl.esi.xtext.types.types.RecordField
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.SimpleTypeDecl
import nl.esi.xtext.types.types.TypeObject
import nl.esi.xtext.types.types.VectorTypeConstructor
import nl.esi.xtext.types.types.VectorTypeDecl
import org.eclipse.emf.ecore.resource.Resource

import static extension nl.esi.xtext.actions.utilities.ActionsUtilities.*
import static extension nl.esi.xtext.expressions.utilities.ExpressionsUtilities.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*

class EvaluateDataExpressions {
    def static void transform(Resource resource) {
        resource.contents.filter(TSMain).flatMap[model.stepSeq].flatMap[step].filter(AssertionStep).forEach[evaluateAssertions]
    }

    private static def void evaluateAssertions(AssertionStep step) {
        // Prepare evaluation context
        val stepInput = step.stepVar.type.typeObject.createDefaultValue
        for (action : step.context + step.input + step.sut) {
            val field = stepInput.resolveField(action.fields)
            field.exp = action.exp.copy
        }

        // Evaluate all expressions in all assertions
        val Map<Variable, Expression> variableExpressions = newHashMap(step.stepVar -> stepInput)
        val ExpressionEvaluator expressionEvaluator = EcoreUtil3.getService(step, ExpressionEvaluator)
        for (assert : step.asserts) {
            for (val iter = assert.eAllContents; iter.hasNext;) {
                switch (expr: iter.next) {
                    ExpressionBracket: {
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

    private static def Field resolveField(Expression expression, Iterable<RecordField> fields) {
        if (expression instanceof ExpressionRecord) {
            val field = expression.fields.findFirst[recordField == fields.head]
            if (field !== null && !fields.tail.isEmpty) {
                return field.exp.resolveField(fields.tail)
            }
            return field
        }
    }

    // TODO: Remove next part after merge of Paul
    static extension val ExpressionFactory EXPRESSION_FACTORY = ExpressionFactory.eINSTANCE

    private static def Expression createDefaultValue(TypeObject typeObj) {
        return switch (typeObj) {
            SimpleTypeDecl case typeObj.name == 'int': createExpressionConstantInt
            SimpleTypeDecl case typeObj.name == 'real': createExpressionConstantReal
            SimpleTypeDecl case typeObj.name == 'bool': createExpressionConstantBool
            SimpleTypeDecl: createExpressionConstantString => [ value = "" ]

            EnumTypeDecl: createExpressionEnumLiteral => [
                type = typeObj
                typeObj.literals.head
            ]

            RecordTypeDecl: createExpressionRecord => [
                type = typeObj
                for(field: typeObj.allFields) {
                    fields += createField => [
                        recordField = field
                        exp = field.type.typeObject.createDefaultValue
                    ]
                }
            ]

            VectorTypeDecl: typeObj.constructor.createDefaultValue
            VectorTypeConstructor: createExpressionVector => [
                typeAnnotation = createTypeAnnotation => [ type = typeObj.asExprType ]
            ]

            MapTypeDecl: typeObj.constructor.createDefaultValue
            MapTypeConstructor: createExpressionMap => [
                typeAnnotation = createTypeAnnotation => [ type = typeObj.asExprType ]
            ]
        }
    }
}
