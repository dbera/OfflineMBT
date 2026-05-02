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

import java.util.Optional;

import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.types.types.Type;

public interface IExpressionConverter {
	/**
	 * Converts an Expression to a Java Object of the specified type.
	 * 
	 * @param expression the Expression to convert
	 * @param targetType the target Java type to convert to
	 * @return the converted Java Object of the specified targetType
	 */
	Optional<Object> toObject(Expression expression, Class<?> targetType);
	/**
	 * Converts a Java Object to an Expression of the specified type.
	 * 
	 * @param object the Java Object to convert
	 * @param type the target Expression type
	 * @return the converted Expression
	 */
	Optional<Expression> toExpression(Object object, Type type);
}