/*
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
package nl.esi.comma.expressions.conversion;

import nl.esi.comma.expressions.evaluation.IEvaluationContext;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.types.types.Type;

public interface ExpressionConverter {
	/**
	 * Converts an Expression to a Java Object of the specified type.
	 * This is a placeholder for the actual implementation which would depend on the structure of Expression and the types supported.
	 * @param context 
	 */
	Object toObject(Expression expression, Class<?> targetType, IEvaluationContext context);

	Expression toExpression(Object object, Type type, IEvaluationContext context);

	boolean isConvertible(Expression expression, Class<?> targetType, IEvaluationContext context);
}