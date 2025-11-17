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

import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionBulkData
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionFactory
import nl.esi.comma.expressions.expression.ExpressionFnCall
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionNullLiteral
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil

class ExpressionOptimizer {
    static extension val ExpressionFactory m_exp = ExpressionFactory.eINSTANCE

    extension val ExpressionEvaluator evaluator

    new() {
        this(new ExpressionEvaluator())
    }

    protected new(ExpressionEvaluator _evaluator) {
        evaluator = _evaluator
    }

    def Expression optimize(Expression expression, IEvaluationContext context) {
        if (expression === null) {
            return null
        }
        val _context = InternalEvaluationContext.wrap(context)

        val expressionValue = expression.evaluate(_context)
        if (expressionValue.undefined) {
            return expression.doOptimize(_context) ?: expression
        } else {
            val valueExpression = expressionValue.createValueExpression(_context.typeOf(expression))
            return EcoreUtil.equals(expression, valueExpression) ? expression : valueExpression
        }
    }

    /**
     * Returning {@code null} will optimize to the expression itself.
     */
    protected dispatch def Expression doOptimize(Expression expression, IEvaluationContext context) {
        expression.optimizeAllContainments(context)
        return expression.reduce(context)
    }

    /**
     * IMPORTANT: Expression references should be copied before evaluation!
     */
    protected dispatch def Expression doOptimize(ExpressionVariable expression, IEvaluationContext context) {
        val reference = context.getExpression(expression)
        if (reference === null) {
            return null
        }
        // Reference should be evaluated before used, hence wrap it with brackets.
        // Reduction will remove the brackets if the evaluated value doesn't require them.
        val wrapped = createExpressionBracket => [
            // IMPORTANT: Referenced expression should be copied before it can be contained!
            sub = EcoreUtil.copy(reference)
        ]
        return wrapped.optimize(context)
    }

    protected dispatch def Expression doOptimize(ExpressionRecordAccess expression, IEvaluationContext context) {
        val recordExpression = expression.record.doOptimize(context)
        if (recordExpression instanceof ExpressionRecord) {
            recordExpression.fields.findFirst[recordField == expression.field]?.exp
        } else {
            null
        }
    }

    private def void optimizeAllContainments(EObject eObject, IEvaluationContext context) {
        if (eObject === null) {
            return
        }
        for (ref : eObject.eClass.EAllContainments) {
            if (ExpressionPackage.Literals.EXPRESSION.isSuperTypeOf(ref.EReferenceType)) {
                if (ref.isMany) {
                    val refValue = eObject.eGet(ref, true) as EList<Expression>
                    for (var index = 0; index < refValue.size; index++) {
                        val refExpr = refValue.get(index)
                        val refEval = refExpr.optimize(context)
                        if (refEval !== refExpr) {
                            refValue.set(index, refEval)
                        }
                    }
                } else {
                    val refValue = eObject.eGet(ref, true) as Expression
                    val refEval = refValue.optimize(context)
                    if (refEval !== refValue) {
                        eObject.eSet(ref, refEval)
                    }
                }
            } else if (ref.isMany) {
                val refValue = eObject.eGet(ref, true) as EList<EObject>
                refValue.forEach[optimizeAllContainments(context)]
            } else {
                val refValue = eObject.eGet(ref, true) as EObject
                refValue.optimizeAllContainments(context)
            }
        }
    }

    /**
     * Returning {@code null} will reduce to the expression itself.
     */
    protected dispatch def Expression reduce(Expression expression, IEvaluationContext context) {
        return expression
    }

    protected dispatch def Expression reduce(ExpressionBracket expression, IEvaluationContext context) {
        return switch (expression.sub) {
            ExpressionRecordAccess,
            ExpressionMapRW,
            ExpressionConstantBool,
            ExpressionConstantInt,
            ExpressionConstantReal,
            ExpressionConstantString,
            ExpressionEnumLiteral,
            ExpressionNullLiteral,
            ExpressionVariable,
            ExpressionRecord,
            ExpressionAny,
            ExpressionBulkData,
            ExpressionFnCall,
            ExpressionFunctionCall,
            ExpressionQuantifier,
            ExpressionVector,
            ExpressionMap,
            ExpressionBracket: expression.sub
            default: expression
        }
    }

    protected dispatch def Expression reduce(ExpressionMinus expression, IEvaluationContext context) {
        val sub = expression.sub
        if (sub instanceof ExpressionMinus) {
            return sub.sub
        }
    }

    protected dispatch def Expression reduce(ExpressionPlus expression, IEvaluationContext context) {
        return expression.sub
    }
}
