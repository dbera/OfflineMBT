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

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.function.BiFunction;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.ecore.EObject;

import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionBinary;
import nl.esi.comma.expressions.expression.ExpressionConstantBool;
import nl.esi.comma.expressions.expression.ExpressionConstantInt;
import nl.esi.comma.expressions.expression.ExpressionConstantReal;
import nl.esi.comma.expressions.expression.ExpressionConstantString;
import nl.esi.comma.expressions.expression.ExpressionFactory;
import nl.esi.comma.expressions.expression.ExpressionMap;
import nl.esi.comma.expressions.expression.ExpressionMinus;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.ExpressionVector;
import nl.esi.comma.expressions.expression.Pair;
import nl.esi.comma.expressions.expression.Variable;
import nl.esi.comma.expressions.functions.ExpressionFunctionsRegistry;
import nl.esi.comma.expressions.utilities.ExpressionsUtilities;
import nl.esi.comma.expressions.validation.ExpressionValidator;
import nl.esi.comma.types.types.SimpleTypeDecl;
import nl.esi.comma.types.types.TypeObject;
import nl.esi.comma.types.utilities.TypeUtilities;

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
	 * Returns an {@link Expression}, based on the {@code value} type.
	 * 
	 * @see IEvaluationContext#toBool(Boolean)
	 * @see IEvaluationContext#toString(String)
	 * @see IEvaluationContext#toString(CharSequence)
	 * @see IEvaluationContext#toInt(Integer)
	 * @see IEvaluationContext#toInt(Long)
	 * @see IEvaluationContext#toInt(BigInteger)
	 * @see IEvaluationContext#toReal(Float)
	 * @see IEvaluationContext#toReal(Double)
	 * @see IEvaluationContext#toReal(BigDecimal)
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
		} else if (value instanceof Collection<?> coll) {
			return toVectorExpr(coll);
		} else if (value instanceof Map<?, ?> map) {
			return toMapExpr(map);
		} else {
			return null;
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

	/**
	 * Converts a Java {@link Collection} to an {@link ExpressionVector}.
	 * Each element is recursively converted via {@link #toExpression(Object)}.
	 * A {@link nl.esi.comma.expressions.expression.TypeAnnotation TypeAnnotation}
	 * is inferred from the first element's Java type so the output serializes as
	 * e.g. {@code <int[]> [1, 2, 3]}.
	 *
	 * @param collection the Java collection (typically a {@code List})
	 * @return an {@code ExpressionVector} containing the converted elements,
	 *         or {@code null} if the collection is {@code null}
	 */
	default ExpressionVector toVectorExpr(Collection<?> collection) {
		if (collection == null) {
			return null;
		}
		// Infer element type and create a typed vector shell (with TypeAnnotation)
		SimpleTypeDecl elementTypeDecl = TypeUtilities.inferElementType(collection);
		ExpressionVector vector = (ExpressionVector) ExpressionsUtilities.createDefaultValue(
				TypeUtilities.vectorOf(elementTypeDecl));

		for (Object element : collection) {
			Expression converted = toExpression(element);
			if (converted != null) {
				vector.getElements().add(converted);
			}
		}
		return vector;
	}

	/**
	 * Converts a Java {@link Map} to an {@link ExpressionMap}.
	 * Each key and value is recursively converted via {@link #toExpression(Object)}.
	 * A {@link nl.esi.comma.expressions.expression.TypeAnnotation TypeAnnotation}
	 * is inferred from the first entry's key/value Java types so the output
	 * serializes as e.g. {@code <map<int, string>> { 1 -> "a" }}.
	 *
	 * @param map the Java map
	 * @return an {@code ExpressionMap} containing the converted key-value pairs,
	 *         or {@code null} if the map is {@code null}
	 */
	default ExpressionMap toMapExpr(Map<?, ?> map) {
		if (map == null) {
			return null;
		}

		// Infer key/value types from the first entry and create a typed map shell
		ExpressionMap exprMap;
		if (!map.isEmpty()) {
			Map.Entry<?, ?> firstEntry = map.entrySet().iterator().next();
			SimpleTypeDecl keyTypeDecl = TypeUtilities.resolveBasicType(firstEntry.getKey());
			SimpleTypeDecl valTypeDecl = TypeUtilities.resolveBasicType(firstEntry.getValue());
			exprMap = (ExpressionMap) ExpressionsUtilities.createDefaultValue(
					TypeUtilities.mapOf(keyTypeDecl, valTypeDecl));
		} else {
			exprMap = ExpressionFactory.eINSTANCE.createExpressionMap();
		}

		for (Map.Entry<?, ?> entry : map.entrySet()) {
			Expression keyExpr = toExpression(entry.getKey());
			Expression valExpr = toExpression(entry.getValue());
			if (keyExpr != null && valExpr != null) {
				Pair pair = ExpressionFactory.eINSTANCE.createPair();
				pair.setKey(keyExpr);
				pair.setValue(valExpr);
				exprMap.getPairs().add(pair);
			}
		}

		return exprMap;
	}

	default TypeObject typeOf(Expression expression) {
		return ExpressionValidator.typeOf(expression);
	}
}
