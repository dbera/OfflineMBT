package nl.esi.comma.expressions.validation;

import static nl.esi.comma.expressions.validation.ExpressionValidator.boolType;
import static nl.esi.comma.expressions.validation.ExpressionValidator.getBaseTypeToCheck;
import static nl.esi.comma.expressions.validation.ExpressionValidator.identical;
import static nl.esi.comma.expressions.validation.ExpressionValidator.intType;
import static nl.esi.comma.expressions.validation.ExpressionValidator.numeric;
import static nl.esi.comma.expressions.validation.ExpressionValidator.realType;
import static nl.esi.comma.expressions.validation.ExpressionValidator.subTypeOf;
import static nl.esi.comma.expressions.validation.ExpressionValidator.typeOf;
import static nl.esi.comma.types.utilities.TypeUtilities.getBaseType;
import static nl.esi.comma.types.utilities.TypeUtilities.getKeyType;
import static nl.esi.comma.types.utilities.TypeUtilities.isMapType;
import static nl.esi.comma.types.utilities.TypeUtilities.isVectorType;

import java.util.Arrays;
import java.util.List;

import org.eclipse.xtext.xbase.lib.Pair;

import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionFunctionCall;
import nl.esi.comma.types.types.TypeObject;

public enum ExpressionFunction {
	isEmpty {
		@Override
		public TypeObject inferType(List<Expression> args) {
			return boolType;
		}

		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 1) {
				return Pair.of(-1, "Function isEmpty expects one argument");
			}
			if (!isVectorType(typeOf(args.get(0)))) {
				return Pair.of(0, "Function isEmpty expects argument of type vector");
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
		public TypeObject inferType(List<Expression> args) {
			return intType;
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 1) {
				return Pair.of(-1, "Function size expects one argument");
			}
			TypeObject type0 = typeOf(args.get(0));
			if (!(isVectorType(type0) || isMapType(type0))) {
				return Pair.of(0, "Function size expects argument of type vector or map");
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
		public TypeObject inferType(List<Expression> args) {
			return boolType;
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 2) {
				return Pair.of(-1, "Function contains expects two arguments");
			}
			if (!isVectorType(typeOf(args.get(0)))) {
				return Pair.of(0, "Function contains expects first argument of type vector");
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
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 2) {
				return Pair.of(-1, "Function add expects two arguments");
			}
			TypeObject type0 = typeOf(args.get(0));
			if (!isVectorType(type0)) {
				return Pair.of(0, "Function add expects first argument of type vector");
			}
			if (!subTypeOf(typeOf(args.get(1)), getBaseTypeToCheck(type0))) {
				return Pair.of(1, "Second argument does not conform to the base type of the vector");
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
		public TypeObject inferType(List<Expression> args) {
			return realType;
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 1) {
				return Pair.of(-1, "Function asReal expects one argument");
			}
			if (!subTypeOf(typeOf(args.get(0)), intType)) {
				return Pair.of(0, "Function asReal expects an argument of type int");
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
		public TypeObject inferType(List<Expression> args) {
			TypeObject result = super.inferType(args);
			return numeric(result) ? result : null;
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 1) {
				return Pair.of(-1, "Function abs expects one argument");
			}
			TypeObject type0 = typeOf(args.get(0));
			if (!(subTypeOf(type0, intType) || subTypeOf(type0, realType))) {
				return Pair.of(0, "Function abs expects an argument of numeric type");
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
		public TypeObject inferType(List<Expression> args) {
			return boolType;
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 2) {
				return Pair.of(-1, "Function hasKey expects two arguments");
			}
			TypeObject type0 = typeOf(args.get(0));
			if (!isMapType(type0)) {
				return Pair.of(0, "Function hasKey expects first argument of type map");
			}
			if (!identical(typeOf(args.get(1)), getKeyType(type0))) {
				return Pair.of(1, "Second argument does not conform to the key type of the map");
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
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 2) {
				return Pair.of(-1, "Function deleteKey expects two arguments");
			}
			TypeObject type0 = typeOf(args.get(0));
			if (!isMapType(type0)) {
				return Pair.of(0, "Function deleteKey expects first argument of type map");
			}
			if (!identical(typeOf(args.get(1)), getKeyType(type0))) {
				return Pair.of(1, "Second argument does not conform to the key type of the map");
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
		public TypeObject inferType(List<Expression> args) {
			TypeObject result = super.inferType(args);
			return result == null ? null : getBaseType(result);
		}

		@Override
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 2) {
				return Pair.of(-1, "Function get expects two arguments");
			}
			TypeObject type0 = typeOf(args.get(0));
			if (!isVectorType(type0)) {
				return Pair.of(0, "Function get expects first argument of type vector");
			}
			if (!intType.equals(typeOf(args.get(1)))) {
				return Pair.of(1, "Function get expects second argument of type integer");
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
		public Pair<Integer, String> validate(List<Expression> args) {
			if (args.size() != 3) {
				return Pair.of(-1, "Function get expects three arguments");
			}
			TypeObject type0 = typeOf(args.get(0));
			if (!isVectorType(type0)) {
				return Pair.of(0, "Function get expects first argument of type vector");
			}
			if (!intType.equals(typeOf(args.get(1)))) {
				return Pair.of(1, "Function get expects second argument of type integer");
			}
			if (!subTypeOf(typeOf(args.get(2)), getBaseTypeToCheck(type0))) {
				return Pair.of(1, "Second argument does not conform to the base type of the vector");
			}
			return null;
		}

		@Override
		public String getDocumentation() {
			return String.format("<T> %s(vector<T>, int): T", name());
		}
	};

	public TypeObject inferType(List<Expression> args) {
		return args.isEmpty() ? null : typeOf(args.get(0));
	}

	public abstract Pair<Integer, String> validate(List<Expression> args);

	public abstract String getDocumentation();
	
	/**
	 * NOTE: This function will not throw IllegalArgumentException, it will return {@code null} instead.
	 * @see #valueOf(String)
	 */
	public static ExpressionFunction valueOf(ExpressionFunctionCall call) {
		return Arrays.stream(ExpressionFunction.values()).filter(e -> e.name().equals(call.getFunctionName()))
				.findFirst().orElse(null);
	}
}
