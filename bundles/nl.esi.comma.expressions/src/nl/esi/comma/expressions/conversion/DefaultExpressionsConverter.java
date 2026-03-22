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
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import nl.esi.comma.expressions.evaluation.IEvaluationContext;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionMap;
import nl.esi.comma.expressions.expression.ExpressionRecord;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.ExpressionVector;
import nl.esi.comma.expressions.expression.VariableDecl;
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
	public Object toObject(Expression expression, Class<?> targetType, IEvaluationContext context) {
		if (expression == null) {
			return null;
		}

		// allow returning the raw Expression if the target type is Expression or a supertype
		if (targetType.isInstance(expression)) {
			return expression;
		}
		
		if(expression instanceof ExpressionVariable expressionVariable) {
			var variable = expressionVariable.getVariable();
			var parent = variable.eContainer();
			 if (parent instanceof VariableDecl decl) {
				 return toObject(decl.getExpression(), targetType, context);
			 }
			 return null;
		}

		// Vector → List
		if (expression instanceof ExpressionVector vector) {
			return convertVector(vector,context);
		}

		// Map → Map
		if (expression instanceof ExpressionMap map) {
			return convertMap(map,context);
		}

		// Record → custom Java object
		if (expression instanceof ExpressionRecord record) {
			return convertRecord(record, targetType,context);
		}

		// Scalar conversions
		return convertScalar(expression, targetType,context);
	}

	// ---- Type annotation resolution ----
	
	@Override
	public Expression toExpression(Object object, Type type, IEvaluationContext context) {
		if (type.getType().getName().equals("void")) {
			if (object != null) {
				throw new IllegalArgumentException("Cannot convert non-null value to void type.");
		}
			return null;
		}
		if (object instanceof Expression expr) {
			return expr;
		}
		return context.toExpression(object);
	}

	@Override
	public boolean isConvertible(Expression expression, Class<?> targetType, IEvaluationContext context) {
		if (expression == null) {
			return false;
		}
		// allow returning the raw Expression if the target type is Expression or a supertype
		if (targetType.isInstance(expression)) {
			return true;
		}
		
		if(expression instanceof ExpressionVariable expressionVariable) {
			var variable = expressionVariable.getVariable();
			var parent = variable.eContainer();
			 if (parent instanceof VariableDecl decl) {
				 return isConvertible(decl.getExpression(), targetType, context);
			 }
		}

		if (expression instanceof ExpressionVector) {
			return targetType.isAssignableFrom(List.class) || targetType.isAssignableFrom(Collection.class);
		}

		if (expression instanceof ExpressionMap) {
			return targetType.isAssignableFrom(Map.class);
		}

		if (expression instanceof ExpressionRecord record) {
			return isRecordConvertible(record, targetType, context);
		}

		// Scalar: check what the expression resolves to, then verify target accepts it
		if (context.asInt(expression) != null) {
			return targetType == long.class || targetType == int.class
				|| targetType == short.class || targetType == byte.class
				|| targetType.isAssignableFrom(Long.class)
				|| targetType.isAssignableFrom(Number.class);
		}
		if (context.asReal(expression) != null) {
			return targetType == double.class || targetType == float.class
				|| targetType.isAssignableFrom(BigDecimal.class)
				|| targetType.isAssignableFrom(Number.class);
		}
		if (context.asBool(expression) != null) {
			return targetType == boolean.class
				|| targetType.isAssignableFrom(Boolean.class);
		}
		if (context.asString(expression) != null) {
			return targetType.isAssignableFrom(String.class);
		}
		return false;
	}

	// ---- Vector conversion ----

	private List<?> convertVector(ExpressionVector vector, IEvaluationContext context) {
		//TODO validate against type annotation if present
		List<Object> result = new ArrayList<>();
		for (Expression element : vector.getElements()) {
			Object converted = convert(element, context);
			if (converted == null) {
				//throw illegal argument exception
				throw new IllegalArgumentException(
					"Vector element conversion failed: expected an Object but got null.");
			}

			result.add(converted);
		}
		// return a new list the has generic type of the first element using streaming, if possible
		if (!result.isEmpty()) {
			Class<?> elementType = result.getFirst().getClass();
			return result.stream().map(elementType::cast).toList();
		}
		return result;
	}

	// ---- Map conversion ----

	private  Map<?,?> convertMap(ExpressionMap map,IEvaluationContext context) {
		Map<Object,Object> result = new LinkedHashMap<>();
		for (var pair : map.getPairs()) {
			Object key = convert(pair.getKey(), context);
			if (key == null) {
				throw new IllegalArgumentException(
					String.format("Map key conversion from %s failed: expected an Object but got null.", pair.getKey()));
			}
			Object value = convert(pair.getValue(), context);
			if (value == null) {
				throw new IllegalArgumentException(
					String.format("Map value conversion from %s failed: expected an Object but got null.", pair.getValue()));
			}
			result.put(key, value);
		}
		// return a new map the has generic types of the first element using streaming, if possible
		if (!result.isEmpty()) {
			Class<?> keyType = result.keySet().iterator().next().getClass();
			Class<?> valueType = result.values().iterator().next().getClass();
			return result.entrySet().stream()
				.collect(Collectors.toMap(
					entry -> keyType.cast(entry.getKey()),
					entry -> valueType.cast(entry.getValue())
				));
		}
		return result;
	}

	// ---- Record conversion ----

	/**
	 * Converts an ExpressionRecord to a Java object via reflection.
	 * 
	 * The record type name must match the target class simple name.
	 * The target class must have a no-arg constructor.
	 * Record field names must match Java field names.
	 */
	private <T> T convertRecord(ExpressionRecord record, Class<T> targetType, IEvaluationContext context) {
		if (!record.getType().getName().equals(targetType.getSimpleName())) {
			throw new IllegalArgumentException(
				String.format("Type mismatch: record '%s' cannot convert to class '%s'.",
					record.getType().getName(), targetType.getSimpleName()));
		}

		try {
			var constructor = targetType.getDeclaredConstructor();
			constructor.setAccessible(true);
			T instance = constructor.newInstance();

			int fieldCount = record.getType().getFields().size();
			for (int i = 0; i < fieldCount; i++) {
				var recordField = record.getType().getFields().get(i);
				var recordValue = record.getFields().get(i);

				if (!(recordValue instanceof Expression expr)) {
					continue;
				}

				var javaField = targetType.getDeclaredField(recordField.getName());
				javaField.setAccessible(true);
				javaField.set(instance, toObject(expr, javaField.getType(), context) );
			}

			return instance;
		} catch (NoSuchMethodException e) {
			throw new IllegalArgumentException(
				String.format("'%s' must have a no-arg constructor.", targetType.getSimpleName()), e);
		} catch (NoSuchFieldException e) {
			throw new IllegalArgumentException(
				String.format("Field '%s' not found in '%s'.", e.getMessage(), targetType.getSimpleName()), e);
		} catch (ReflectiveOperationException e) {
			throw new IllegalArgumentException(
				String.format("Failed to convert record to '%s': %s", targetType.getSimpleName(), e.getMessage()), e);
		}
	}

	private boolean isRecordConvertible(ExpressionRecord record, Class<?> targetType, IEvaluationContext context) {
		if (!record.getType().getName().equals(targetType.getSimpleName())) {
			return false;
		}
		try {
			targetType.getDeclaredConstructor();
			int fieldCount = record.getType().getFields().size();
			for (int i = 0; i < fieldCount; i++) {
				var recordValue = record.getFields().get(i);
				if (!(recordValue instanceof Expression expr)) {
					continue;
				}
				var fieldName = record.getType().getFields().get(i).getName();
				var javaField = targetType.getDeclaredField(fieldName);
				if (!isConvertible(expr, javaField.getType(), context)) {
					return false;
				}
			}
			return true;
		} catch (NoSuchMethodException | NoSuchFieldException | SecurityException e) {
			return false;
		}
	}

	// ---- Scalar conversion ----

	/**
	 * Converts a scalar expression to the requested Java type.
	 * Lets the context resolve the expression to its natural Java type first,
	 * then checks if that result is assignable to the target type.
	 */
	private Object convertScalar(Expression expression, Class<?> targetType, IEvaluationContext context) {
		Object value = convert(expression, context);
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
		if (targetType == long.class || targetType == Long.class) return value;
		if (targetType == int.class || targetType == Integer.class) return value.intValue();
		if (targetType == short.class || targetType == Short.class) return value.shortValue();
		if (targetType == byte.class || targetType == Byte.class) return value.byteValue();
		if (targetType == double.class || targetType == Double.class) return value.doubleValue();
		if (targetType == float.class || targetType == Float.class) return value.floatValue();
		if (targetType.isAssignableFrom(BigDecimal.class)) return new BigDecimal(value);
		if (targetType.isAssignableFrom(Number.class)) return value;
		return value;
	}

	private Object convertNumericFrom(BigDecimal value, Class<?> targetType) {
		if (targetType == double.class || targetType == Double.class) return value.doubleValue();
		if (targetType == float.class || targetType == Float.class) return value.floatValue();
		if (targetType.isAssignableFrom(Number.class)) return value;
		return value;
	}

	private Object defaultPrimitive(Class<?> type) {
		if (type == boolean.class) return false;
		if (type == long.class) return 0L;
		if (type == int.class) return 0;
		if (type == short.class) return (short) 0;
		if (type == byte.class) return (byte) 0;
		if (type == double.class) return 0.0;
		if (type == float.class) return 0.0f;
		return null;
	}

	/**
	 * Best-effort conversion when no specific target type is given (Object.class).
	 * Tries int → real → bool → string in order.
	 */
	private Object convert(Expression expression, IEvaluationContext context) {
		var intValue = context.asInt(expression);
		if (intValue != null) return intValue.longValue();

		var realValue = context.asReal(expression);
		if (realValue != null) return realValue;

		var boolValue = context.asBool(expression);
		if (boolValue != null) return boolValue;

		return context.asString(expression);
	}

	// ---- Type annotation resolution ----

}