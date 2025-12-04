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
import nl.esi.comma.expressions.expression.ExpressionMinus;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.Variable;
import nl.esi.comma.expressions.validation.ExpressionValidator;
import nl.esi.comma.types.types.TypeObject;

public interface IEvaluationContext {
	static final IEvaluationContext EMPTY = variable -> null;

	Expression getExpression(Variable variable);

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

	default TypeObject typeOf(Expression expression) {
		return ExpressionValidator.typeOf(expression);
	}
}
