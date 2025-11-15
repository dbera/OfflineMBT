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
package nl.esi.comma.expressions.evaluation

import java.util.ArrayList
import java.util.List
import java.util.Map
import java.util.Optional
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionFactory
import nl.esi.comma.expressions.expression.ExpressionGeq
import nl.esi.comma.expressions.expression.ExpressionGreater
import nl.esi.comma.expressions.expression.ExpressionLeq
import nl.esi.comma.expressions.expression.ExpressionLess
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionMaximum
import nl.esi.comma.expressions.expression.ExpressionMinimum
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionModulo
import nl.esi.comma.expressions.expression.ExpressionMultiply
import nl.esi.comma.expressions.expression.ExpressionNEqual
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionNullLiteral
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.TypeObject

import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.copy
import java.math.BigDecimal

class ExpressionInterpreter {
    static extension val ExpressionFactory m_exp = ExpressionFactory.eINSTANCE

    protected val LITERAL_NULL = new Object {}

    def boolean isUndefined(Object _value) {
        return switch (_value) {
            case null: true
            List<Object>: _value.exists[undefined]
            Map<Object, Object>: _value.entrySet.exists[key.undefined || value.undefined]
            default: false
        }
    }

    def Expression createExpression(Object _value, TypeObject _type) {
        return switch (_value) {
            case _value.undefined || _type === null: null
            case LITERAL_NULL: createExpressionNullLiteral
            Boolean: createExpressionConstantBool => [value = _value]
            Long case _value < 0L: createExpressionMinus => [sub = createExpressionConstantInt => [value = -_value]]
            Long: createExpressionConstantInt => [value = _value]
            BigDecimal case _value < BigDecimal.ZERO: createExpressionMinus => [sub = createExpressionConstantReal => [value = _value.abs.doubleValue]]
            BigDecimal: createExpressionConstantReal => [value = _value.doubleValue]
            String case _type.isEnumType: createExpressionEnumLiteral => [
                type = _type as EnumTypeDecl
                literal = type.literals.findFirst[name == _value]
                if (literal === null) throw new RuntimeException('''Unsupported value '«_value»' for type «_type.typeName»''')
            ]
            String: createExpressionConstantString => [value = _value]
            List<Object> case _type.isVectorType: createExpressionVector => [
                typeAnnotation = createTypeAnnotation => [ type = _type.asType.copy ]
                elements += _value.map[createExpression(_type.elementType)]
            ]
            Map<Object, Object> case _type.isMapType: createExpressionMap => [
                typeAnnotation = createTypeAnnotation => [ type = _type.asType.copy ]
                pairs += _value.entrySet.map[ entry | createPair => [
                    key = entry.key.createExpression(_type.keyType)
                    value = entry.value.createExpression(_type.valueType)
                ]]
            ]
            Map<String, Object> case _type.isRecordType: createExpressionRecord => [ rec |
                rec.type = _type as RecordTypeDecl
                rec.fields += _value.entrySet.map [ entry | createField => [
                    recordField = rec.type.fields.findFirst[name == entry.key]
                    if (recordField === null) throw new RuntimeException('''Unknown record field '«entry.key»' for type «rec.type.typeName»''')
                    exp = entry.value.createExpression(recordField.type.typeObject)
                ]]
            ]
            default: throw new RuntimeException('''Unsupported value '«_value»' for type «_type.typeName»''')
        }
    }

    def Object execute(Expression expression, IEvaluationContext context) {
        if (expression === null) {
            return null
        }
        val ctx = InternalEvaluationContext.wrap(context)
        if (ctx.hasValue(expression)) {
            return ctx.getValue(expression)
        }
        val value = doExecute(expression, ctx)
        ctx.setValue(expression, value)
        return value
    }

    /**
     * Returning {@code null} results in an undefined result (i.e. {@link Optional#isEmpty()}.
     * Use {@link #LITERAL_NULL} to return a {@code null} result.
     */
    protected dispatch def Object doExecute(Expression expression, IEvaluationContext context) {
        return null
    }

    // Binary

    protected dispatch def Object doExecute(ExpressionAnd expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Boolean && right instanceof Boolean: (left as Boolean) && (right as Boolean)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionOr expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Boolean && right instanceof Boolean: (left as Boolean) || (right as Boolean)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionEqual expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return left === null || right === null ? null : left == right
    }

    protected dispatch def Object doExecute(ExpressionNEqual expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return left === null || right === null ? null : left != right
    }

    protected dispatch def Object doExecute(ExpressionGeq expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) >= (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) >= (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionGreater expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) > (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) > (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionLeq expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) <= (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) <= (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionLess expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) < (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) < (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionAddition expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) + (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) + (right as BigDecimal)
            case left instanceof String && right instanceof String: (left as String) + (right as String)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionSubtraction expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) - (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) - (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionMultiply expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) * (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) * (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionDivision expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) / (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) / (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionMaximum expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: Math.max(left as Long, right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal).max(right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionMinimum expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: Math.min(left as Long, right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal).min(right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionModulo expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) % (right as Long)
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionPower expression, IEvaluationContext context) {
        val left = expression.left.execute(context)
        val right = expression.right.execute(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: Math.round(Math.pow(left as Long, right as Long))
            case left instanceof BigDecimal && right instanceof BigDecimal: 
                BigDecimal.valueOf(Math.pow((left as BigDecimal).doubleValue, (right as BigDecimal).doubleValue))
            default: null
        }
    }

    // Unary

    protected dispatch def Object doExecute(ExpressionNot expression, IEvaluationContext context) {
        return switch (result: expression.sub.execute(context)) {
            Boolean: !result
            default: null
        }
    }

    protected dispatch def Object doExecute(ExpressionMinus expression, IEvaluationContext context) {
        return switch (result: expression.sub.execute(context)) {
            Long: -result
            BigDecimal: -result
            default: null
        }
    }

    // Derived

    protected dispatch def Object doExecute(ExpressionVariable expression, IEvaluationContext context) {
        return context.getExpression(expression).execute(context)
    }

    protected dispatch def Object doExecute(ExpressionRecordAccess expression, IEvaluationContext context) {
        val recordValue = expression.record.execute(context)
        if (recordValue instanceof Map) {
            return recordValue.get(expression.field.name)
        }
    }

    protected dispatch def Object doExecute(ExpressionMapRW expression, IEvaluationContext context) {
        if (expression.value !== null) {
            // Expressions with side-effects cannot be interpreted
            return null
        }
        val mapValue = expression.map.execute(context)
        if (mapValue instanceof Map) {
            return mapValue.get(expression.key.execute(context))
        }
    }

    protected dispatch def Object doExecute(ExpressionBracket expression, IEvaluationContext context) {
        return expression.sub.execute(context)
    }

    protected dispatch def Object doExecute(ExpressionPlus expression, IEvaluationContext context) {
        return expression.sub.execute(context)
    }

    // Collections

    protected dispatch def Object doExecute(ExpressionRecord expression, IEvaluationContext context) {
        return expression.fields.toMap([recordField.name], [exp.execute(context)])
    }

    protected dispatch def Object doExecute(ExpressionMap expression, IEvaluationContext context) {
        return expression.pairs.toMap([key.execute(context)], [value.execute(context)])
    }

    protected dispatch def Object doExecute(ExpressionVector expression, IEvaluationContext context) {
        return new ArrayList(expression.elements.map[execute(context)])
    }

    // Constants

    protected dispatch def Object doExecute(ExpressionConstantBool expression, IEvaluationContext context) {
        return expression.value
    }

    protected dispatch def Object doExecute(ExpressionConstantInt expression, IEvaluationContext context) {
        return expression.value
    }

    protected dispatch def Object doExecute(ExpressionConstantReal expression, IEvaluationContext context) {
        return BigDecimal.valueOf(expression.value)
    }

    protected dispatch def Object doExecute(ExpressionConstantString expression, IEvaluationContext context) {
        return expression.value
    }

    protected dispatch def Object doExecute(ExpressionEnumLiteral expression, IEvaluationContext context) {
        return expression.literal?.name
    }

    protected dispatch def Object doExecute(ExpressionNullLiteral expression, IEvaluationContext context) {
        return LITERAL_NULL
    }
}