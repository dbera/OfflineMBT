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
	Object toObject(Expression expression, Class<?> targetType);
	/**
	 * Converts a Java Object to an Expression of the specified type.
	 * 
	 * @param object the Java Object to convert
	 * @param type the target Expression type
	 * @return the converted Expression
	 */
	Expression toExpression(Object object, Type type);

	/**
	 * Checks if an Expression can be converted to a Java Object of the specified type.
	 * 
	 * @param expression the Expression to check for convertibility
	 * @param targetType the target Java type
	 * @return true if the Expression can be converted to the targetType, false otherwise
	 */
	boolean isConvertible(Expression expression, Class<?> targetType);
}