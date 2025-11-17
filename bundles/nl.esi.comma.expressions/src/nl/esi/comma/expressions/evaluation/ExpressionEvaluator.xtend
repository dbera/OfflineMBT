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

import java.math.BigDecimal
import java.util.ArrayList
import java.util.LinkedHashMap
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
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
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

class ExpressionEvaluator {
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

    def Expression createValueExpression(Object _value, TypeObject _type) {
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
                elements += _value.map[createValueExpression(_type.elementType)]
            ]
            Map<Object, Object> case _type.isMapType: createExpressionMap => [
                typeAnnotation = createTypeAnnotation => [ type = _type.asType.copy ]
                pairs += _value.entrySet.map[ entry | createPair => [
                    key = entry.key.createValueExpression(_type.keyType)
                    value = entry.value.createValueExpression(_type.valueType)
                ]]
            ]
            Map<String, Object> case _type.isRecordType: createExpressionRecord => [ rec |
                rec.type = _type as RecordTypeDecl
                rec.fields += _value.entrySet.map [ entry | createField => [
                    recordField = rec.type.fields.findFirst[name == entry.key]
                    if (recordField === null) throw new RuntimeException('''Unknown record field '«entry.key»' for type «rec.type.typeName»''')
                    exp = entry.value.createValueExpression(recordField.type.typeObject)
                ]]
            ]
            default: throw new RuntimeException('''Unsupported value '«_value»' for type «_type.typeName»''')
        }
    }

    def Object evaluate(Expression expression, IEvaluationContext context) {
        if (expression === null) {
            return null
        }
        val ctx = InternalEvaluationContext.wrap(context)
        if (ctx.hasValue(expression)) {
            return ctx.getValue(expression)
        }
        val value = doEvaluate(expression, ctx)
        ctx.setValue(expression, value)
        return value
    }

    /**
     * Returning {@code null} results in an undefined result (i.e. {@link Optional#isEmpty()}.
     * Use {@link #LITERAL_NULL} to return a {@code null} result.
     */
    protected dispatch def Object doEvaluate(Expression expression, IEvaluationContext context) {
        return null
    }

    protected dispatch def Object doEvaluate(ExpressionFunctionCall expression, IEvaluationContext context) {
        // TODO
    }

    // Binary

    protected dispatch def Object doEvaluate(ExpressionAnd expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Boolean && right instanceof Boolean: (left as Boolean) && (right as Boolean)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionOr expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Boolean && right instanceof Boolean: (left as Boolean) || (right as Boolean)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionEqual expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return left === null || right === null ? null : left == right
    }

    protected dispatch def Object doEvaluate(ExpressionNEqual expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return left === null || right === null ? null : left != right
    }

    protected dispatch def Object doEvaluate(ExpressionGeq expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) >= (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) >= (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionGreater expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) > (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) > (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionLeq expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) <= (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) <= (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionLess expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) < (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) < (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionAddition expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) + (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) + (right as BigDecimal)
            case left instanceof String && right instanceof String: (left as String) + (right as String)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionSubtraction expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) - (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) - (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionMultiply expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) * (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) * (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionDivision expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) / (right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal) / (right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionMaximum expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: Math.max(left as Long, right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal).max(right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionMinimum expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: Math.min(left as Long, right as Long)
            case left instanceof BigDecimal && right instanceof BigDecimal: (left as BigDecimal).min(right as BigDecimal)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionModulo expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: (left as Long) % (right as Long)
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionPower expression, IEvaluationContext context) {
        val left = expression.left.evaluate(context)
        val right = expression.right.evaluate(context)
        return switch (expression) {
            case left instanceof Long && right instanceof Long: Math.round(Math.pow(left as Long, right as Long))
            case left instanceof BigDecimal && right instanceof BigDecimal: 
                BigDecimal.valueOf(Math.pow((left as BigDecimal).doubleValue, (right as BigDecimal).doubleValue))
            default: null
        }
    }

    // Unary

    protected dispatch def Object doEvaluate(ExpressionNot expression, IEvaluationContext context) {
        return switch (result: expression.sub.evaluate(context)) {
            Boolean: !result
            default: null
        }
    }

    protected dispatch def Object doEvaluate(ExpressionMinus expression, IEvaluationContext context) {
        return switch (result: expression.sub.evaluate(context)) {
            Long: -result
            BigDecimal: -result
            default: null
        }
    }

    // Derived

    protected dispatch def Object doEvaluate(ExpressionVariable expression, IEvaluationContext context) {
        return context.getExpression(expression).evaluate(context)
    }

    protected dispatch def Object doEvaluate(ExpressionRecordAccess expression, IEvaluationContext context) {
        val recordValue = expression.record.evaluate(context)
        if (recordValue instanceof Map) {
            return recordValue.get(expression.field.name)
        }
    }

    protected dispatch def Object doEvaluate(ExpressionMapRW expression, IEvaluationContext context) {
        val mapValue = expression.map.evaluate(context)
        if (mapValue instanceof Map) {
            val keyValue = expression.key.evaluate(context)
            if (expression.value === null) {
                return mapValue.get(keyValue)
            } else {
                // The setter is side-effect-free and returns a new instance of the map
                val result = new LinkedHashMap(mapValue)
                // If the key of a map is undefined, the value is always undefined!
                result.put(keyValue, keyValue === null ? null : expression.value.evaluate(context))
                return result
            }
        }
    }

    protected dispatch def Object doEvaluate(ExpressionBracket expression, IEvaluationContext context) {
        return expression.sub.evaluate(context)
    }

    protected dispatch def Object doEvaluate(ExpressionPlus expression, IEvaluationContext context) {
        return expression.sub.evaluate(context)
    }

    // Collections

    protected dispatch def Object doEvaluate(ExpressionRecord expression, IEvaluationContext context) {
        return expression.fields.toMap([recordField.name], [exp.evaluate(context)])
    }

    protected dispatch def Object doEvaluate(ExpressionMap expression, IEvaluationContext context) {
        val result = newLinkedHashMap
        for (pair : expression.pairs) {
            val keyValue = pair.key.evaluate(context)
            // If the key of a map is undefined, the value is always undefined!
            result.put(keyValue, keyValue === null ? null : pair.value.evaluate(context))
        }
        return result
    }

    protected dispatch def Object doEvaluate(ExpressionVector expression, IEvaluationContext context) {
        return new ArrayList(expression.elements.map[evaluate(context)])
    }

    // Constants

    protected dispatch def Object doEvaluate(ExpressionConstantBool expression, IEvaluationContext context) {
        return expression.value
    }

    protected dispatch def Object doEvaluate(ExpressionConstantInt expression, IEvaluationContext context) {
        return expression.value
    }

    protected dispatch def Object doEvaluate(ExpressionConstantReal expression, IEvaluationContext context) {
        return BigDecimal.valueOf(expression.value)
    }

    protected dispatch def Object doEvaluate(ExpressionConstantString expression, IEvaluationContext context) {
        return expression.value
    }

    protected dispatch def Object doEvaluate(ExpressionEnumLiteral expression, IEvaluationContext context) {
        return expression.literal?.name
    }

    protected dispatch def Object doEvaluate(ExpressionNullLiteral expression, IEvaluationContext context) {
        return LITERAL_NULL
    }
}