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

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import nl.esi.comma.expressions.evaluation.IEvaluationContext;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionMap;
import nl.esi.comma.expressions.expression.ExpressionVector;
import nl.esi.comma.types.types.Type;

/**
 * Default converter from Expression model types to plain Java types.
 * 
 * Conversion mapping:
 * - ExpressionVector → List (elements converted recursively, validated against type annotation)
 * - ExpressionMap    → Map  (keys/values converted recursively, validated against type annotation)
 * - ExpressionRecord → custom Java object (via reflection)
 * - int expressions  → Long
 * - real expressions → BigDecimal
 * - bool expressions → Boolean
 * - string expressions → String
 */
public final class DefaultExpressionsConverter implements IExpressionConverter {

	@Override
	public Object toObject(Expression expression, Class<?> targetType) {
		var context = IEvaluationContext.EMPTY; // No variable resolution needed for type checking in this default converter

		if (expression == null) {
			return null;
		}

		// allow returning the raw Expression if the target type is Expression or a supertype
		if (targetType.isInstance(expression)) {
			return expression;
		}

		// Vector → List
		if (expression instanceof ExpressionVector vector) {
			return context.toList(vector);
		}

		// Map → Map
		if (expression instanceof ExpressionMap map) {
			return context.toMap(map);
		}

		// Scalar conversions
		return convertScalar(expression, targetType, context);
	}

	// ---- Type annotation resolution ----

	@Override
	public Expression toExpression(Object object, Type type) {
		if (type.getType().getName().equals("void")) {
			if (object != null) {
				throw new IllegalArgumentException("Cannot convert non-null value to void type.");
			}
			return null;
		}
		if (object instanceof Expression expr) {
			return expr;
		}
		var context = IEvaluationContext.EMPTY; // No variable resolution needed for type checking in this default converter
		return context.toExpression(object);
	}

	@Override
	public boolean isConvertible(Expression expression, Class<?> targetType) {
		
		var context = IEvaluationContext.EMPTY; // No variable resolution needed for type checking in this default converter
		if (expression == null) {
			return false;
		}

		// allow returning the raw Expression if the target type is Expression or a supertype
		if (targetType.isInstance(expression)) {
			return true;
		}

		if (expression instanceof ExpressionVector) {
			return targetType.isAssignableFrom(List.class) || targetType.isAssignableFrom(Collection.class);
		}

		if (expression instanceof ExpressionMap) {
			return targetType.isAssignableFrom(Map.class);
		}

		// Scalar: check what the expression resolves to, then verify target accepts it
		if (context.asInt(expression) != null) {
			return targetType == long.class || targetType == int.class || targetType == short.class
					|| targetType == byte.class || targetType.isAssignableFrom(Long.class)
					|| targetType.isAssignableFrom(Number.class);
		}
		if (context.asReal(expression) != null) {
			return targetType == double.class || targetType == float.class
					|| targetType.isAssignableFrom(BigDecimal.class) || targetType.isAssignableFrom(Number.class);
		}
		if (context.asBool(expression) != null) {
			return targetType == boolean.class || targetType.isAssignableFrom(Boolean.class);
		}
		if (context.asString(expression) != null) {
			return targetType.isAssignableFrom(String.class);
		}
		return false;
	}

	// ---- Scalar conversion ----
	/**
	 * Converts a scalar expression to the requested Java type. Lets the context
	 * resolve the expression to its natural Java type first, then checks if that
	 * result is assignable to the target type.
	 */
	private Object convertScalar(Expression expression, Class<?> targetType, IEvaluationContext context) {
		Object value = context.toObject(expression);
		if (value == null) {
			return targetType.isPrimitive() ? defaultPrimitive(targetType) : null;
		}
		// Direct match
		if (targetType.isInstance(value) || targetType.isAssignableFrom(value.getClass())) {
			return value;
		}
		// Numeric widening: int (Long) → BigDecimal, double, float, etc.
		if (value instanceof Long longVal) {
			return convertNumericFrom(longVal, targetType);
		}
		// Numeric widening: real (BigDecimal) → double, float
		if (value instanceof BigDecimal decVal) {
			return convertNumericFrom(decVal, targetType);
		}
		return value;
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