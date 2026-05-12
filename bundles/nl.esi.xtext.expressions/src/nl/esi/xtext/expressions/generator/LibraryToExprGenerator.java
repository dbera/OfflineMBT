/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.generator;

import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.lang.reflect.TypeVariable;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.expressions.expression.ExpressionMap;
import nl.esi.xtext.expressions.expression.ExpressionVector;

/**
 * Generates {@code .expr} function declarations from Java methods.
 * 
 * <p>This class provides two main capabilities:
 * <ol>
 *   <li><strong>Method to Function Declaration:</strong> Converts a single Java method
 *       to an {@code .expr} function declaration (e.g., {@code function string uuid toUUID(string id)}).
 *       Methods with {@code void} return type produce an empty string.
 *   </li>
 *   <li><strong>Custom Type Extraction:</strong> Identifies all custom (non-built-in) types
 *       used in a method's signature (both parameters and return type). These types
 *       require type declarations in the generated {@code .expr} file.
 *   </li>
 * </ol>
 * 
 * <p><strong>Supported Type Mappings:</strong>
 * <ul>
 *   <li>Primitives and wrappers: {@code boolean/Boolean} → {@code bool}, {@code int/Integer/long/Long} → {@code int}, etc.</li>
 *   <li>Numeric: {@code double/Double/float/Float/BigDecimal} → {@code real}</li>
 *   <li>String: {@code String} → {@code string}</li>
 *   <li>EMF expression types:
 *       {@link ExpressionVector} with generics → {@code T[]},
 *       {@link ExpressionMap} with generics → {@code map<K,V>},
 *       {@link Expression} → {@code any}
 *   </li>
 *   <li>Collections: {@code List, Collection} → {@code T[]}</li>
 *   <li>Maps: {@code Map} → {@code map<K,V>}</li>
 *   <li>Generic types: {@code List<String>} → {@code string[]}, {@code Map<String, Long>} → {@code map<string, int>}</li>
 *   <li>Type variables: {@code <T>} → {@code T}</li>
 *   <li>Custom types: Any other type (e.g., {@code UUID}) → lowercase simple name (e.g., {@code uuid})</li>
 * </ul>
 * 
 * <p><strong>Template Support:</strong>
 * Methods using EMF expression collection types automatically generate template function declarations.
 * For example:
 * <ul>
 *   <li>{@code Expression get(ExpressionMap, long)} generates: {@code function <K, V> V get(map<K, V> p0, int p1)}</li>
 *   <li>{@code ExpressionVector add(ExpressionVector, Expression)} generates: {@code function <T> T[] add(T[] p0, T p1)}</li>
 *   <li>{@code boolean hasKey(ExpressionMap, Expression)} generates: {@code function <K, V> bool hasKey(map<K, V> p0, K p1)}</li>
 *   <li>{@code boolean contains(ExpressionVector, Expression)} generates: {@code function <T> bool contains(T[] p0, T p1)}</li>
 * </ul>
 * 
 * <p><strong>Example Usage:</strong>
 * <pre>
 * Method method = UUID.class.getMethod("fromString", String.class);
 * 
 * // Generate function declaration
 * String funcDecl = LibraryToExprGenerator.generate(method);
 * // Output: "function uuid fromString(string p0)"
 * 
 * // Extract custom types
 * List<String> customTypes = LibraryToExprGenerator.getCustomTypes(method);
 * // Output: ["uuid"]
 * </pre>
 */
public final class LibraryToExprGenerator {

	private LibraryToExprGenerator() {
	}

	/**
	 * Generates a {@code .expr} function declaration for a single method.
	 * 
	 * <p>Converts the method signature to the format:
	 * {@code function <returnType> <methodName>(<param1Type> <param1Name>, ...)}
	 * 
	 * <p>Methods with {@code void} or {@code Void} return type produce an empty string.
	 * Parameter names are derived from the method's parameter names (if compiled with
	 * {@code -parameters} flag) or generated as {@code p0, p1, ...} otherwise.
	 * 
	 * @param method the Java method to convert
	 * @return the {@code .expr} function declaration, or empty string if void
	 */
	public static String generate(Method method) {
		return toFunctionDecl(method).orElse("");
	}

	/**
	 * Extracts all custom types from a method's signature.
	 * 
	 * <p>Analyzes both parameter types and return type, filtering to include only
	 * custom (non-built-in) types. Built-in types like {@code int}, {@code string},
	 * {@code bool}, {@code real}, collections, maps, and EMF expression types are excluded.
	 * 
	 * <p>Results are deduplicated and returned in lowercase.
	 * 
	 * <p><strong>Example:</strong>
	 * <pre>
	 * // Method: UUID fromString(String id, List<UUID> others)
	 * List<String> types = LibraryToExprGenerator.getCustomTypes(method);
	 * // Returns: ["uuid"]
	 * </pre>
	 * 
	 * @param method the Java method to analyze
	 * @return list of custom type names in lowercase, without duplicates
	 */
	public static List<String> getCustomTypes(Method method) {
		return Stream.concat(
				Arrays.stream(method.getGenericParameterTypes()),
				Stream.of(method.getGenericReturnType())
			)
			.map(LibraryToExprGenerator::getCustomTypes)
			.flatMap(List::stream)
			.map(LibraryToExprGenerator::getTypeName)
			.distinct()
			.collect(Collectors.toList());
	}

	// -- Core generation ------------------------------------------------------

	/**
	 * Determines the template context for a method by scanning for EMF expression
	 * types in its signature. The context determines how EMF types are mapped:
	 * <ul>
	 *   <li>{@code VECTOR}: {@link ExpressionVector} → {@code T[]},
	 *       {@link Expression} → {@code T}</li>
	 *   <li>{@code MAP}: {@link ExpressionMap} → {@code map<K, V>},
	 *       {@link Expression} as parameter → {@code K},
	 *       {@link Expression} as return → {@code V}</li>
	 *   <li>{@code NONE}: No EMF collection types; {@link Expression} → {@code any}</li>
	 * </ul>
	 */
	private enum TemplateContext {
		NONE, VECTOR, MAP;

		Set<String> typeParams() {
			return switch (this) {
			case VECTOR -> new LinkedHashSet<>(List.of("T"));
			case MAP -> new LinkedHashSet<>(List.of("K", "V"));
			case NONE -> new LinkedHashSet<>();
			};
		}
	}

	/**
	 * Determines the template context for a method by scanning for
	 * {@link ExpressionVector} and {@link ExpressionMap} in params and return type.
	 */
	private static TemplateContext resolveTemplateContext(Method method) {
		List<Class<?>> allRawTypes = new ArrayList<>();
		allRawTypes.add(rawType(method.getGenericReturnType()));
		for (Type t : method.getGenericParameterTypes()) {
			allRawTypes.add(rawType(t));
		}

		for (Class<?> cls : allRawTypes) {
			if (cls != null && ExpressionMap.class.isAssignableFrom(cls)) return TemplateContext.MAP;
		}
		for (Class<?> cls : allRawTypes) {
			if (cls != null && ExpressionVector.class.isAssignableFrom(cls)) return TemplateContext.VECTOR;
		}
		return TemplateContext.NONE;
	}

	private static Class<?> rawType(Type type) {
		if (type instanceof Class<?> cls) return cls;
		if (type instanceof ParameterizedType pt) return (Class<?>) pt.getRawType();
		return null;
	}

	/**
	 * Converts a single method to a {@code function ...} declaration, or empty if
	 * void. Automatically synthesizes template parameters for methods using EMF
	 * expression collection types ({@link ExpressionVector}, {@link ExpressionMap}).
	 */
	private static Optional<String> toFunctionDecl(Method method) {
		TemplateContext ctx = resolveTemplateContext(method);

		String returnExpr = toExprType(method.getGenericReturnType(), ctx, true);
		if (returnExpr == null)
			return Optional.empty();

		String params = IntStream.range(0, method.getParameterCount())
				.mapToObj(i -> toExprType(method.getGenericParameterTypes()[i], ctx, false) + " " + parameterName(method, i))
				.collect(Collectors.joining(", "));

		// Combine explicit Java type parameters with synthesized EMF template params
		Set<String> typeParams = new LinkedHashSet<>();
		for (TypeVariable<?> tv : method.getTypeParameters()) {
			typeParams.add(tv.getName());
		}
		collectTypeVariables(method.getGenericReturnType(), typeParams);
		for (Type pt : method.getGenericParameterTypes()) {
			collectTypeVariables(pt, typeParams);
		}
		typeParams.addAll(ctx.typeParams());

		String typeParamStr = typeParams.isEmpty() ? "" : "<" + String.join(", ", typeParams) + "> ";
		return Optional.of("function " + typeParamStr + returnExpr + " " + method.getName() + "(" + params + ")");
	}

	// -- Type mapping: Java Type → expr type string ---------------------------

	/**
	 * Maps a Java {@link Type} to an expr type string; returns {@code null} for void.
	 * Type variables are rendered as-is (e.g., "T"). EMF expression types are mapped
	 * based on the {@link TemplateContext}.
	 *
	 * @param type      the Java type to map
	 * @param ctx       the template context (VECTOR, MAP, or NONE)
	 * @param isReturn  whether this type appears in return position
	 */
	private static String toExprType(Type type, TemplateContext ctx, boolean isReturn) {
		return switch (type) {
		case Class<?> c when c == void.class || c == Void.class -> null;
		case Class<?> cls -> rawClassToExpr(cls, ctx, isReturn);
		case ParameterizedType pt -> parameterizedToExpr(pt, ctx, isReturn);
		case TypeVariable<?> tv -> tv.getName();
		default -> "any";
		};
	}

	/**
	 * Public convenience overload without template context (for external callers).
	 * EMF expression types map to {@code any}/{@code any[]}/{@code map<any, any>}.
	 */
	public static String toExprType(Type type) {
		return toExprType(type, TemplateContext.NONE, false);
	}

	private static final Map<Class<?>, String> TYPE_MAP = Map.ofEntries(Map.entry(boolean.class, "bool"),
			Map.entry(Boolean.class, "bool"), Map.entry(long.class, "int"), Map.entry(Long.class, "int"),
			Map.entry(int.class, "int"), Map.entry(Integer.class, "int"), Map.entry(short.class, "int"),
			Map.entry(Short.class, "int"), Map.entry(byte.class, "int"), Map.entry(Byte.class, "int"),
			Map.entry(double.class, "real"), Map.entry(Double.class, "real"), Map.entry(float.class, "real"),
			Map.entry(Float.class, "real"), Map.entry(BigDecimal.class, "real"), Map.entry(String.class, "string"));

	private static String rawClassToExpr(Class<?> cls, TemplateContext ctx, boolean isReturn) {
		String mapped = TYPE_MAP.get(cls);
		if (mapped != null)            return mapped;
		if (cls == Object.class)       return "any";
		// EMF expression model types — context-sensitive mapping
		if (ExpressionVector.class.isAssignableFrom(cls)) {
			return ctx == TemplateContext.VECTOR ? "T[]" : "any[]";
		}
		if (ExpressionMap.class.isAssignableFrom(cls)) {
			return ctx == TemplateContext.MAP ? "map<K, V>" : "map<any, any>";
		}
		if (Expression.class.isAssignableFrom(cls)) {
			return switch (ctx) {
			case VECTOR -> "T";
			case MAP -> isReturn ? "V" : "K";
			case NONE -> "any";
			};
		}
		// Java collection / map types
		if (Collection.class.isAssignableFrom(cls)) return "any[]";
		if (Map.class.isAssignableFrom(cls))        return "map<any, any>";
		return cls.getSimpleName().toLowerCase();
	}

	private static String parameterizedToExpr(ParameterizedType pt, TemplateContext ctx, boolean isReturn) {
		Class<?> raw = (Class<?>) pt.getRawType();
		Type[] args = pt.getActualTypeArguments();

		if (ExpressionVector.class.isAssignableFrom(raw)) {
			return (args.length > 0 ? toExprType(args[0], ctx, isReturn) : (ctx == TemplateContext.VECTOR ? "T" : "any")) + "[]";
		}
		if (ExpressionMap.class.isAssignableFrom(raw)) {
			String k = args.length > 0 ? toExprType(args[0], ctx, false) : (ctx == TemplateContext.MAP ? "K" : "any");
			String v = args.length > 1 ? toExprType(args[1], ctx, true)  : (ctx == TemplateContext.MAP ? "V" : "any");
			return "map<" + k + ", " + v + ">";
		}
		if (Collection.class.isAssignableFrom(raw)) {
			return (args.length > 0 ? toExprType(args[0], ctx, isReturn) : "any") + "[]";
		}
		if (Map.class.isAssignableFrom(raw)) {
			return "map<" + (args.length > 0 ? toExprType(args[0], ctx, false) : "any") + ", "
					+ (args.length > 1 ? toExprType(args[1], ctx, true) : "any") + ">";
		}
		return rawClassToExpr(raw, ctx, isReturn);
	}

	/**
	 * Recursively collects all type variable names from a Type.
	 * Handles ParameterizedTypes by extracting their type arguments.
	 */
	private static void collectTypeVariables(Type type, Set<String> result) {
		if (type instanceof TypeVariable<?> tv) {
			result.add(tv.getName());
		} else if (type instanceof ParameterizedType pt) {
			for (Type arg : pt.getActualTypeArguments()) {
				collectTypeVariables(arg, result);
			}
		}
	}

	// -- Helpers --------------------------------------------------------------

	/**
	 * Determines if a type requires a type declaration.
	 * Returns true for custom types (like UUID) that are not built-in and not excluded types.
	 */
	private static List<Type> getCustomTypes(Type type) {
		// Unwrap parameterized types
		var result = new ArrayList<Type>();
		if (type instanceof ParameterizedType pt) {
			for (Type arg : pt.getActualTypeArguments()) {
				result.addAll(getCustomTypes(arg));
			}
			type = pt.getRawType();
		}
		
		// Only consider Class types
		if (!(type instanceof Class<?> cls)) {
			return result;
		}
		
		// Exclude void, Object, and Class types
		if (cls == void.class || cls == Void.class || cls == Object.class || cls == Class.class) {
			return result;
		}
		
		// Exclude built-in types that already map to expr types (bool, int, real, string)
		if (TYPE_MAP.containsKey(cls)) {
			return result;
		}
		
		// Exclude EMF expression types and collections/maps (already handled)
		if (Expression.class.isAssignableFrom(cls) ||
			Collection.class.isAssignableFrom(cls) ||
			Map.class.isAssignableFrom(cls)) {
			return result;
		}
		
		// This is a custom type - include it
		result.add(type);
		return result;
	}

	/**
	 * Extracts the simple class name from a Type object.
	 * Handles ParameterizedType, Class, and other Type implementations.
	 * 
	 * Note: In the future this is a candidate for annotations to specify the type (it could also be a record)
	 */
	private static String getTypeName(Type t) {
		if (t instanceof Class<?> cls) {
			return cls.getSimpleName().toLowerCase();
		}
		if (t instanceof ParameterizedType pt) {
			return getTypeName(pt.getRawType());
		}
		if (t instanceof TypeVariable<?> tv) {
			return tv.getName().toLowerCase();
		}
		return t.getTypeName().toLowerCase();
	}

	/**
	 * Uses the real parameter name if compiled with {@code -parameters}, else
	 * {@code pN}.
	 */
	private static String parameterName(Method method, int index) {
		Parameter p = method.getParameters()[index];
		return p.isNamePresent() ? "_" +p.getName() : "p" + index;
	}
}
