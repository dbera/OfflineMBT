/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.conversion;

import java.util.Optional;

import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.types.types.Type;

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