/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.evaluation;

import static nl.esi.xtext.types.utilities.TypeUtilities.asType;
import static nl.esi.xtext.types.utilities.TypeUtilities.getElementType;
import static nl.esi.xtext.types.utilities.TypeUtilities.getKeyType;
import static nl.esi.xtext.types.utilities.TypeUtilities.getTypeObject;
import static nl.esi.xtext.types.utilities.TypeUtilities.getValueType;
import static nl.esi.xtext.types.utilities.TypeUtilities.isMapType;
import static nl.esi.xtext.types.utilities.TypeUtilities.isVectorType;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BiFunction;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.ecore.EObject;

import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.expressions.expression.ExpressionBinary;
import nl.esi.xtext.expressions.expression.ExpressionConstantBool;
import nl.esi.xtext.expressions.expression.ExpressionConstantInt;
import nl.esi.xtext.expressions.expression.ExpressionConstantReal;
import nl.esi.xtext.expressions.expression.ExpressionConstantString;
import nl.esi.xtext.expressions.expression.ExpressionFactory;
import nl.esi.xtext.expressions.expression.ExpressionMap;
import nl.esi.xtext.expressions.expression.ExpressionMinus;
import nl.esi.xtext.expressions.expression.ExpressionVariable;
import nl.esi.xtext.expressions.expression.ExpressionVector;
import nl.esi.xtext.expressions.expression.Pair;
import nl.esi.xtext.expressions.expression.Variable;
import nl.esi.xtext.expressions.functions.ExpressionFunctionsRegistry;
import nl.esi.xtext.expressions.utilities.ExpressionsUtilities;
import nl.esi.xtext.types.types.Type;

public interface IEvaluationContext {
	static final IEvaluationContext EMPTY = variable -> null;
	final List<Object> libraryFunctionObjects = new ArrayList<Object>();

	Expression getExpression(Variable variable);
	
	/**
	 * Returns a mutable list of library function objects that are available in this context.
	 * These are used for function resolution and invocation during expression evaluation.
	 * By default, this returns an empty list, but clients can add instances of their libraries to it. 
	 * The objects should be assignable from the classes that the {@link ExpressionFunctionsRegistry} supports for library functions.
	 */
	default List<Object> getLibraryFunctionObjects(){
		return libraryFunctionObjects;
	}

	/**
	 * Returns {@code true} if an only if the {@code expression} resolves to a full
	 * value, meaning that it will not contain any unresolved variable references.
	 */
	default boolean isValue(Expression expression) {
		if (expression == null || expression instanceof ExpressionVariable) {
			return false;
		}
		for (TreeIterator<EObject> i = expression.eAllContents(); i.hasNext();) {
			if (i.next() instanceof Expression expr) {
				if (isValue(expr)) {
					i.prune();
				} else {
					return false;
				}
			}
		}
		return true;
	}

	default Expression calcIfBool(ExpressionBinary expression, BiFunction<Boolean, Boolean, Object> calc) {
		return calcIfBool(expression.getLeft(), expression.getRight(), calc);
	}

	default Expression calcIfBool(Expression left, Expression right, BiFunction<Boolean, Boolean, Object> calc) {
		Boolean leftValue = asBool(left);
		Boolean rightValue = asBool(right);
		if (leftValue == null || rightValue == null) {
			return null;
		}
		return toExpression(calc.apply(leftValue, rightValue));
	}

	default Expression calcIfString(ExpressionBinary expression, BiFunction<String, String, Object> calc) {
		return calcIfString(expression.getLeft(), expression.getRight(), calc);
	}

	default Expression calcIfString(Expression left, Expression right, BiFunction<String, String, Object> calc) {
		String leftValue = asString(left);
		String rightValue = asString(right);
		if (leftValue == null || rightValue == null) {
			return null;
		}
		return toExpression(calc.apply(leftValue, rightValue));
	}

	default Expression calcIfInt(ExpressionBinary expression, BiFunction<BigInteger, BigInteger, Object> calc) {
		return calcIfInt(expression.getLeft(), expression.getRight(), calc);
	}

	default Expression calcIfInt(Expression left, Expression right, BiFunction<BigInteger, BigInteger, Object> calc) {
		BigInteger leftValue = asInt(left);
		BigInteger rightValue = asInt(right);
		if (leftValue == null || rightValue == null) {
			return null;
		}
		return toExpression(calc.apply(leftValue, rightValue));
	}

	default Expression calcIfReal(ExpressionBinary expression, BiFunction<BigDecimal, BigDecimal, Object> calc) {
		return calcIfReal(expression.getLeft(), expression.getRight(), calc);
	}

	default Expression calcIfReal(Expression left, Expression right, BiFunction<BigDecimal, BigDecimal, Object> calc) {
		BigDecimal leftValue = asReal(left);
		BigDecimal rightValue = asReal(right);
		if (leftValue == null || rightValue == null) {
			return null;
		}
		return toExpression(calc.apply(leftValue, rightValue));
	}

	/**
	 * Converts a Java value to an {@link Expression} based on its type.
	 * Supports conversion of primitive wrapper types, numbers, and strings.
	 * 
	 * @param value the Java value to convert (Boolean, String, Integer, Long, BigInteger, Float, Double, BigDecimal, or CharSequence)
	 * @return an Expression representing the value, or {@code null} if the value type is not supported
	 * 
	 * @see #toExpression(Object, Type) for conversion with explicit type information
	 * @see #toBoolExpr(Boolean)
	 * @see #toStringExpr(String)
	 * @see #toIntExpr(BigInteger)
	 * @see #toRealExpr(BigDecimal)
	 */
	default Expression toExpression(Object value) {
		if (value instanceof Boolean b) {
			return toBoolExpr(b);
		} else if (value instanceof String s) {
			return toStringExpr(s);
		} else if (value instanceof CharSequence s) {
			return toStringExpr(s);
		} else if (value instanceof BigInteger i) {
			return toIntExpr(i);
		} else if (value instanceof Integer i) {
			return toIntExpr(i);
		} else if (value instanceof Long i) {
			return toIntExpr(i);
		} else if (value instanceof BigDecimal r) {
			return toRealExpr(r);
		} else if (value instanceof Double r) {
			return toRealExpr(r);
		} else if (value instanceof Float r) {
			return toRealExpr(r);
		} else {
			return null;
		}
	}

	/**
	 * Converts a Java value to an {@link Expression} with explicit type information.
	 * For collections and maps, uses the provided type for type annotation and element/key/value type resolution.
	 * For scalar values, delegates to {@link #toExpression(Object)} for basic conversion.
	 * 
	 * @param value the Java value to convert (can be Collection, Map, or any scalar type)
	 * @param type the XPlus type providing type information for vectors and maps
	 * @return an Expression representing the value with proper type annotation,
	 *         or {@code null} if the value or type is {@code null}, or value type doesn't match the type
	 * 
	 * @see #toExpression(Object) for scalar value conversion
	 * @see #toVectorExpr(Collection, Type) for collection conversion
	 * @see #toMapExpr(Map, Type) for map conversion
	 */
	default Expression toExpression(Object value, Type type) {
		if (value instanceof Collection<?> coll && isVectorType(type)) {
			return toVectorExpr(coll, type);
		} else if (value instanceof Map<?, ?> map && isMapType(type)) {
			return toMapExpr(map, type);
		} else {
			return toExpression(value);
		}
	}

	default Boolean asBool(Expression expression) {
		if (expression instanceof ExpressionConstantBool expr) {
			return expr.isValue();
		}
		return null;
	}

	default ExpressionConstantBool toBoolExpr(Boolean value) {
		if (value != null) {
			ExpressionConstantBool expression = ExpressionFactory.eINSTANCE.createExpressionConstantBool();
			expression.setValue(value);
			return expression;
		}
		return null;
	}

	default String asString(Expression expression) {
		if (expression instanceof ExpressionConstantString expr) {
			return expr.getValue();
		}
		return null;
	}

	default ExpressionConstantString toStringExpr(CharSequence value) {
		return value == null ? null : toStringExpr(value.toString());
	}

	default ExpressionConstantString toStringExpr(String value) {
		if (value != null) {
			ExpressionConstantString expression = ExpressionFactory.eINSTANCE.createExpressionConstantString();
			expression.setValue(value);
			return expression;
		}
		return null;
	}

	default BigInteger asInt(Expression expression) {
		if (expression instanceof ExpressionConstantInt expr) {
			return BigInteger.valueOf(expr.getValue());
		} else if (expression instanceof ExpressionMinus expr) {
			BigInteger value = asInt(expr.getSub());
			return value == null ? null : value.negate();
		}
		return null;
	}

	default Expression toIntExpr(Integer value) {
		return value == null ? null : toIntExpr(BigInteger.valueOf(value));
	}

	default Expression toIntExpr(Long value) {
		return value == null ? null : toIntExpr(BigInteger.valueOf(value));
	}

	default Expression toIntExpr(BigInteger value) {
		if (value != null) {
			ExpressionConstantInt intExpression = ExpressionFactory.eINSTANCE.createExpressionConstantInt();
			intExpression.setValue(value.abs().longValue());
			if (value.compareTo(BigInteger.ZERO) >= 0) {
				return intExpression;
			}
			ExpressionMinus minusExpression = ExpressionFactory.eINSTANCE.createExpressionMinus();
			minusExpression.setSub(intExpression);
			return minusExpression;
		}
		return null;
	}

	default BigDecimal asReal(Expression expression) {
		if (expression instanceof ExpressionConstantReal expr) {
			return BigDecimal.valueOf(expr.getValue());
		} else if (expression instanceof ExpressionMinus expr) {
			BigDecimal value = asReal(expr.getSub());
			return value == null ? null : value.negate();
		}
		return null;
	}

	default Expression toRealExpr(Float value) {
		return value == null ? null : toRealExpr(BigDecimal.valueOf(value));
	}

	default Expression toRealExpr(Double value) {
		return value == null ? null : toRealExpr(BigDecimal.valueOf(value));
	}

	default Expression toRealExpr(BigDecimal value) {
		if (value != null) {
			ExpressionConstantReal realExpression = ExpressionFactory.eINSTANCE.createExpressionConstantReal();
			realExpression.setValue(value.abs().doubleValue());
			if (value.compareTo(BigDecimal.ZERO) >= 0) {
				return realExpression;
			}
			ExpressionMinus minusExpression = ExpressionFactory.eINSTANCE.createExpressionMinus();
			minusExpression.setSub(realExpression);
			return minusExpression;
		}
		return null;
	}
	
	default Object toObject(Expression expression) {
		var intValue = asInt(expression);
		if (intValue != null)
			return intValue.longValue();

		var realValue = asReal(expression);
		if (realValue != null)
			return realValue;

		var boolValue = asBool(expression);
		if (boolValue != null)
			return boolValue;

		return asString(expression);
	}
	
	default List<?> toList(ExpressionVector vector) {
		// TODO validate against type annotation if present
		List<Object> result = new ArrayList<>();
		for (Expression element : vector.getElements()) {
			Object converted = toObject(element);
			if (converted == null) {
				// throw illegal argument exception
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

	default  Map<?, ?> toMap(ExpressionMap map) {
		Map<Object, Object> result = new LinkedHashMap<>();
		for (var pair : map.getPairs()) {
			Object key = toObject(pair.getKey());
			if (key == null) {
				throw new IllegalArgumentException(String
						.format("Map key conversion from %s failed: expected an Object but got null.", pair.getKey()));
			}
			Object value = toObject(pair.getValue());
			if (value == null) {
				throw new IllegalArgumentException(String.format(
						"Map value conversion from %s failed: expected an Object but got null.", pair.getValue()));
			}
			result.put(key, value);
		}
		// return a new map the has generic types of the first element using streaming,
		// if possible
		if (!result.isEmpty()) {
			Class<?> keyType = result.keySet().iterator().next().getClass();
			Class<?> valueType = result.values().iterator().next().getClass();
			return result.entrySet().stream().collect(
					Collectors.toMap(entry -> keyType.cast(entry.getKey()), entry -> valueType.cast(entry.getValue())));
		}
		return result;
	}



	/**
	 * Converts a Java {@link Collection} to an {@link ExpressionVector}.
	 * Each element is recursively converted via {@link #toExpression(Object, Type)}.
	 * A {@link nl.esi.xtext.expressions.expression.TypeAnnotation TypeAnnotation}
	 * is created from the provided type so the output serializes as e.g. {@code <int[]> [1, 2, 3]}.
	 *
	 * @param collection the Java collection (typically a {@code List})
	 * @param type the vector type to use for type annotation and element type resolution
	 * @return an {@code ExpressionVector} containing the converted elements,
	 *         or {@code null} if the collection or type is {@code null}, or type is not a vector type
	 */
	default ExpressionVector toVectorExpr(Collection<?> collection, Type type) {
		if (collection == null) {
			return null;
		}
		if (!isVectorType(type)) {
			return null;
		}

		// Create typed vector shell with type annotation
		ExpressionVector vector = ExpressionFactory.eINSTANCE.createExpressionVector();
		var typeAnnotation = ExpressionFactory.eINSTANCE.createTypeAnnotation();
		typeAnnotation.setType(ExpressionsUtilities.asExprType(type));
		vector.setTypeAnnotation(typeAnnotation);

		// Convert elements and add them
		for (Object element : collection) {
			Expression converted = toExpression(element, asType(getElementType(getTypeObject(type))));
			if (converted != null) {
				vector.getElements().add(converted);
			}
		}

		return vector;
	}

	/**
	 * Converts a Java {@link Map} to an {@link ExpressionMap}.
	 * Each key and value is recursively converted via {@link #toExpression(Object, Type)}.
	 * A {@link nl.esi.xtext.expressions.expression.TypeAnnotation TypeAnnotation}
	 * is created from the provided type so the output serializes as e.g. {@code <map<int, string>> { 1 -> "a" }}.
	 *
	 * @param map the Java map
	 * @param type the map type to use for type annotation and key/value type resolution
	 * @return an {@code ExpressionMap} containing the converted key-value pairs,
	 *         or {@code null} if the map or type is {@code null}, or type is not a map type
	 */
	default ExpressionMap toMapExpr(Map<?, ?> map, Type type) {
		if (map == null) {
			return null;
		}
		if (!isMapType(type)) {
			return null;
		}
		// Create typed map shell with type annotation
		ExpressionMap exprMap = ExpressionFactory.eINSTANCE.createExpressionMap();
		if (type != null) {
			var typeAnnotation = ExpressionFactory.eINSTANCE.createTypeAnnotation();
			typeAnnotation.setType(ExpressionsUtilities.asExprType(type));
			exprMap.setTypeAnnotation(typeAnnotation);
		}

		// Convert entries to pairs and add them
		for (Map.Entry<?, ?> entry : map.entrySet()) {
			Pair pair = ExpressionFactory.eINSTANCE.createPair();
			pair.setKey(toExpression(entry.getKey(), asType(getKeyType(getTypeObject(type)))));
			pair.setValue(toExpression(entry.getValue(), asType(getValueType(getTypeObject(type)))));
			exprMap.getPairs().add(pair);
		}

		return exprMap;
	}
}
