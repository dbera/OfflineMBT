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

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import nl.esi.xtext.expressions.evaluation.IEvaluationContext;
import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.expressions.expression.ExpressionMap;
import nl.esi.xtext.expressions.expression.ExpressionVector;
import nl.esi.xtext.types.types.Type;

/**
 * Default converter from Expression model types to plain Java types.
 * 
 * Conversion mapping: - ExpressionVector → List (elements converted
 * recursively, validated against type annotation) - ExpressionMap → Map
 * (keys/values converted recursively, validated against type annotation) -
 * ExpressionRecord → custom Java object (via reflection) - int expressions →
 * Long - real expressions → BigDecimal - bool expressions → Boolean - string
 * expressions → String
 */
public final class DefaultExpressionsConverter implements IExpressionConverter {

	@Override
	public Optional<Object> toObject(Expression expression, Class<?> targetType) {
		var context = IEvaluationContext.EMPTY; // No variable resolution needed for type checking in this default
												// converter

		if (expression == null) {
			return Optional.empty();
		}

		// allow returning the raw Expression if the target type is Expression or a
		// supertype
		if (targetType.isInstance(expression)) {
			return Optional.of(expression);
		}

		// Vector → List
		if (expression instanceof ExpressionVector vector) {
			if (targetType.isAssignableFrom(List.class) || targetType.isAssignableFrom(Collection.class))
				return Optional.of(context.toList(vector));
		}

		// Map → Map
		if (expression instanceof ExpressionMap map) {
			if (targetType.isAssignableFrom(Map.class)) {
				return Optional.of(context.toMap(map));
			}
		}

		// Scalar conversions
		return convertScalar(expression, targetType, context);
	}

	// ---- Type annotation resolution ----

	@Override
	public Optional<Expression> toExpression(Object object, Type type) {
		if (type.getType().getName().equals("void")) {
			return Optional.empty();
		}
		if (object instanceof Expression expr) {
			return Optional.of(expr);
		}
		 // No variable resolution needed for type checking in this default converter
		var context = IEvaluationContext.EMPTY;
		Expression result = context.toExpression(object, type);
		return Optional.ofNullable(result);
	}

	// ---- Scalar conversion ----
	/**
	 * Converts a scalar expression to the requested Java type. Lets the context
	 * resolve the expression to its natural Java type first, then checks if that
	 * result is assignable to the target type.
	 */
	private Optional<Object> convertScalar(Expression expression, Class<?> targetType, IEvaluationContext context) {
		Object value = context.toObject(expression);
		if (value == null) {
			if (targetType.isPrimitive()) {
				return Optional.of(defaultPrimitive(targetType));
			}
			return Optional.empty();
		}

		// Direct match
		if (targetType.isInstance(value) || targetType.isAssignableFrom(value.getClass())) {
			return Optional.of(value);
		}

		// Check scalar type compatibility explicitly
		// Int types (Long in XPlus)
		if (value instanceof Long longVal) {
			if (targetType == long.class || targetType == int.class || targetType == short.class
					|| targetType == byte.class || targetType.isAssignableFrom(Long.class)
					|| targetType.isAssignableFrom(Number.class)) {
				return Optional.of(convertNumericFrom(longVal, targetType));
			}
		}

		// Real types (BigDecimal in XPlus)
		if (value instanceof BigDecimal decVal) {
			if (targetType == double.class || targetType == float.class || targetType.isAssignableFrom(BigDecimal.class)
					|| targetType.isAssignableFrom(Number.class)) {
				return Optional.of(convertNumericFrom(decVal, targetType));
			}
		}

		// Bool types
		if (value instanceof Boolean && (targetType == boolean.class || targetType.isAssignableFrom(Boolean.class))) {
			return Optional.of(value);
		}

		// String types
		if (value instanceof String && targetType.isAssignableFrom(String.class)) {
			return Optional.of(value);
		}

		// Type mismatch
		return Optional.empty();
	}

	private Object convertNumericFrom(Long value, Class<?> targetType) {
		if (targetType == long.class || targetType == Long.class)
			return value;
		if (targetType == int.class || targetType == Integer.class)
			return value.intValue();
		if (targetType == short.class || targetType == Short.class)
			return value.shortValue();
		if (targetType == byte.class || targetType == Byte.class)
			return value.byteValue();
		if (targetType == double.class || targetType == Double.class)
			return value.doubleValue();
		if (targetType == float.class || targetType == Float.class)
			return value.floatValue();
		if (targetType.isAssignableFrom(BigDecimal.class))
			return new BigDecimal(value);
		if (targetType.isAssignableFrom(Number.class))
			return value;
		return value;
	}

	private Object convertNumericFrom(BigDecimal value, Class<?> targetType) {
		if (targetType == double.class || targetType == Double.class)
			return value.doubleValue();
		if (targetType == float.class || targetType == Float.class)
			return value.floatValue();
		if (targetType.isAssignableFrom(Number.class))
			return value;
		return value;
	}

	private Object defaultPrimitive(Class<?> type) {
		if (type == boolean.class)
			return false;
		if (type == long.class)
			return 0L;
		if (type == int.class)
			return 0;
		if (type == short.class)
			return (short) 0;
		if (type == byte.class)
			return (byte) 0;
		if (type == double.class)
			return 0.0;
		if (type == float.class)
			return 0.0f;
		return null;
	}

}