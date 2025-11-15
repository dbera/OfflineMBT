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
package nl.esi.comma.expressions.evaluation;

import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.validation.ExpressionValidator;
import nl.esi.comma.types.types.TypeObject;

public interface IEvaluationContext {
	static final IEvaluationContext EMPTY = v -> null;

	Expression getExpression(ExpressionVariable variable);
	
	default TypeObject typeOf(Expression expression) {
		return ExpressionValidator.typeOf(expression);
	}
}
