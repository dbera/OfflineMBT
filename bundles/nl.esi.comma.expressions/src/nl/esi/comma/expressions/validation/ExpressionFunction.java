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
package nl.esi.comma.expressions.validation;

import static nl.esi.comma.expressions.validation.ExpressionValidator.boolType;
import static nl.esi.comma.expressions.validation.ExpressionValidator.intType;
import static nl.esi.comma.expressions.validation.ExpressionValidator.numeric;
import static nl.esi.comma.expressions.validation.ExpressionValidator.realType;
import static nl.esi.comma.expressions.validation.ExpressionValidator.typeOf;
import static nl.esi.comma.expressions.validation.ExpressionValidator.voidType;
import static nl.esi.comma.types.utilities.TypeUtilities.isMapType;
import static nl.esi.comma.types.utilities.TypeUtilities.isVectorType;
import static nl.esi.comma.types.utilities.TypeUtilities.subTypeOf;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.xtext.xbase.lib.Pair;

import nl.esi.comma.expressions.evaluation.ExpressionEvaluator;
import nl.esi.comma.expressions.evaluation.IEvaluationContext;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionFunctionCall;
import nl.esi.comma.expressions.expression.ExpressionVector;
import nl.esi.comma.types.types.TypeObject;
import nl.esi.comma.types.utilities.TypeUtilities;

public enum ExpressionFunction {
	isEmpty {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return boolType;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 1);
			if (result == null && !isVectorType(inferType(args, 0))) {
				result = Pair.of(0, "Function isEmpty expects argument 1 to be of type vector");
			}
			return result;
		}
		
		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof List<?>) {
				return ((List<?>) args.get(0)).isEmpty();
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("%s(vector): bool", name());
		}
	},
	size {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return intType;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 1);
			if (result == null && !(isVectorType(inferType(args, 0)) || isMapType(inferType(args, 0)))) {
				result = Pair.of(0, "Function size expects argument 1 to be of type vector or map");
			}
			return result;
		}

		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof List<?>) {
				return ((List<?>) args.get(0)).size();
			}
			if (args.get(0) instanceof Map<?, ?>) {
				return ((Map<?, ?>) args.get(0)).size();
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("%s(vector|map): int", name());
		}
	},
	contains {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return boolType;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 2);
			if (result == null && !isVectorType(inferType(args, 0))) {
				result = Pair.of(0, "Function contains expects argument 1 to be of type vector");
			}
			return result;
		}

		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof List<?> && args.get(1) != null) {
				return ((List<?>) args.get(0)).contains(args.get(1));
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("%s(vector, any): bool", name());
		}
	},
	add {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return inferType(args, 0);
			case 1:
				TypeObject argType = inferType(args, 0);
				return isVectorType(argType) ? TypeUtilities.getElementType(argType) : null;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 2);
			if (result == null && !isVectorType(inferType(args, 0))) {
				result = Pair.of(0, "Function add expects argument 1 to be of type vector");
			}
			return result;
		}
		
		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof List<?>) {
				ArrayList<Object> result = new ArrayList<>((List<?>) args.get(0));
				result.add(args.get(1));
				return result;
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("<T> %s(vector<T>, T): vector<T>", name());
		}
	},
	asReal {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return realType;
			case 0:
				return intType;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			return validateArgs(args, 1);
		}

		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof Long) {
				return BigDecimal.valueOf((Long) args.get(0));
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("%s(int): real", name());
		}
	},
	abs {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return inferType(args, 0);
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 1);
			if (result == null && !numeric(inferType(args, 0))) {
				result = Pair.of(0, "Function abs expects argument 1 to be of numeric type");
			}
			return result;
		}

		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof Long) {
				return Math.abs((Long) args.get(0));
			}
			if (args.get(0) instanceof BigDecimal) {
				return ((BigDecimal) args.get(0)).abs();
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("<T int|real> %s(T): T", name());
		}
	},
// Disabled support for bulkdata
//	length {
//		@Override
//		public TypeObject inferType(List<Expression> args) {
//			return intType;
//		}
//
//		@Override
//		public Pair<Integer, String> validate(List<Expression> args) {
//			if (args.size() != 1) {
//				return Pair.of(-1, "Function length expects one argument");
//			}
//			if (!subTypeOf(typeOf(args.get(0)), bulkdataType)) {
//				return Pair.of(0, "Function length expects an argument of type bulkdata");
//			}
//			return null;
//		}
//
//		@Override
//		public String getDocumentation() {
//			return String.format("%s(bulkdata): int", name());
//		}
//	},
	hasKey {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return boolType;
			case 1:
				TypeObject argType = inferType(args, 0);
				return isMapType(argType) ? TypeUtilities.getKeyType(argType) : null;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 2);
			if (result == null && !isMapType(inferType(args, 0))) {
				result = Pair.of(0, "Function hasKey expects argument 1 to be of type map");
			}
			return result;
		}

		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof Map<?, ?> && args.get(1) != null) {
				return ((Map<?, ?>) args.get(0)).containsKey(args.get(1));
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("<K, V> %s(map<K, V>, K): bool", name());
		}
	},
	deleteKey {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return inferType(args, 0);
			case 1:
				TypeObject argType = inferType(args, 0);
				return isMapType(argType) ? TypeUtilities.getKeyType(argType) : null;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 2);
			if (result == null && !isMapType(inferType(args, 0))) {
				result = Pair.of(0, "Function hasKey expects argument 1 to be of type map");
			}
			return result;
		}

		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof Map<?, ?> && args.get(1) != null) {
				Map<Object, Object> result = new LinkedHashMap<>((Map<?, ?>) args.get(0));
				result.remove(args.get(1));
				return result;
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("<K, V> %s(map<K, V>, K): map<K, V>", name());
		}
	},
	get {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				TypeObject argType = inferType(args, 0);
				return isVectorType(argType) ? TypeUtilities.getElementType(argType) : null;
			case 1:
				return intType;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 2);
			if (result == null && !isVectorType(inferType(args, 0))) {
				result = Pair.of(0, "Function get expects argument 1 to be of type vector");
			}
			return result;
		}

		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof List<?> && args.get(1) instanceof Long) {
				return ((List<?>) args.get(0)).get(((Long) args.get(1)).intValue());
			}
			return null;
		}
		
		// TODO: Implement new evaluation method for all functions
		
		@Override
		public Expression evaluate2(List<Expression> args, IEvaluationContext context) {
			BigInteger arg1 = context.asInt(args.get(1));
			if (arg1 != null && args.get(0) instanceof ExpressionVector expr) {
				int index = arg1.intValueExact();
				if (index < 0 || index >= expr.getElements().size()) {
					throw new IndexOutOfBoundsException(index);
				}
				return expr.getElements().get(index);
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("<T> %s(vector<T>, int): T", name());
		}
	},
	at {
		@Override
		public TypeObject inferType(List<Expression> args, int argIndex) {
			switch (argIndex) {
			case -1:
				return inferType(args, 0);
			case 1:
				return intType;
			case 2:
				TypeObject argType = inferType(args, 0);
				return isVectorType(argType) ? TypeUtilities.getElementType(argType) : null;
			default:
				return super.inferType(args, argIndex);
			}
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			Pair<Integer, String> result = validateArgs(args, 3);
			if (result == null && !isVectorType(inferType(args, 0))) {
				result = Pair.of(0, "Function at expects argument 1 to be of type vector");
			}
			return result;
		}

		@Override
		public Object evaluate(List<Object> args) {
			if (args.get(0) instanceof List<?> && args.get(1) instanceof Long) {
				int index = ((Long) args.get(1)).intValue();
				ArrayList<Object> result = new ArrayList<>((List<?>) args.get(0));
				result.set(index, args.get(2));
				return result;
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("<T> %s(vector<T>, int, T): vector<T>", name());
		}
	};
	
	public static final int RETURN_ARG = -1;

	public TypeObject inferType(List<Expression> args, int argIndex) {
		if(argIndex < 0) {
			// Default return type is void
			return voidType;
		} else if (argIndex < args.size()) {
			return typeOf(args.get(argIndex));
		} else {
			return null;
		}
	}
	
	public abstract Pair<Integer, String> validate(List<Expression> args);
	
	Pair<Integer, String> validateArgs(List<Expression> args, int expectedNrOfArgs) {
		if (args.size() != expectedNrOfArgs) {
			return Pair.of(-1, String.format("Function %s expects %d arguments", name(), expectedNrOfArgs));
		}
		for (int i = 0; i < args.size(); i++) {
			Expression arg = args.get(i);
			TypeObject argType = inferType(args, i);
			if (argType != null && !subTypeOf(typeOf(arg), argType)) {
				return Pair.of(i, String.format("Function %s expects argument %d to be of type %s", name(), i + 1,
						TypeUtilities.getTypeName(argType)));
			}
		}
		return null;
	}

	public abstract String getDocumentation();
	
	/**
	 * Evaluates this function to a value (if possible), also see
	 * {@link ExpressionEvaluator}.
	 * <p>
	 * <b>IMPORTANT:</b> This method should only be called when
	 * {@link #validate(List)} returned {@code null}!
	 * </p>
	 * <p>
	 * Supported Object types (i.e. args and return values):
	 * </p>
	 * <ul>
	 * <li>{@link Boolean} for bool</li>
	 * <li>{@link Long} for int</li>
	 * <li>{@link BigDecimal} for real</li>
	 * <li>{@link String} for string</li>
	 * <li>{@link List}{@code <Object>} for array</li>
	 * <li>{@link Map}{@code <Object, Object>} for map</li>
	 * <li>{@link Map}{@code <String, Object>} for record</li>
	 * </ul>
	 * 
	 * @param args function arguments
	 * @return {@code null} if value cannot be evaluated (i.e. undefined).
	 * @see ExpressionEvaluator
	 */
	public Object evaluate(List<Object> args) {
		return null;
	}
	
	public Expression evaluate2(List<Expression> args, IEvaluationContext context) {
		return null;
	}

	/**
	 * NOTE: This function will not throw IllegalArgumentException, it will return {@code null} instead.
	 * @see #valueOf(String)
	 */
	public static ExpressionFunction valueOf(ExpressionFunctionCall call) {
		return Arrays.stream(ExpressionFunction.values()).filter(e -> e.name().equals(call.getFunctionName()))
				.findFirst().orElse(null);
	}
}
