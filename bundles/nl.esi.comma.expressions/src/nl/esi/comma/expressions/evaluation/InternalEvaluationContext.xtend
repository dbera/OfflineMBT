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

import java.util.Map
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionVariable
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class InternalEvaluationContext implements IEvaluationContext {
    val Map<Expression, Object> expressionValues = newHashMap

    val IEvaluationContext delegate

    static def InternalEvaluationContext wrap(IEvaluationContext context) {
        return context instanceof InternalEvaluationContext ? context : new InternalEvaluationContext(context)
    }

    override getExpression(ExpressionVariable variable) {
        return delegate === null ? null : delegate.getExpression(variable)
    }

    override typeOf(Expression expression) {
        return delegate === null
            ? IEvaluationContext.super.typeOf(expression)
            : delegate.typeOf(expression)
    }

    def boolean hasValue(Expression expression) {
        return expressionValues.containsKey(expression)
    }

    def Object getValue(Expression expression) {
        return expressionValues.get(expression)
    }

    def void setValue(Expression expression, Object value) {
        expressionValues.put(expression, value)
    }
}
