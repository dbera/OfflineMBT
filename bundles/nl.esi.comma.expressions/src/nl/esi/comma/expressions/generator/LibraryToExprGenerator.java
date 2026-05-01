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
package nl.esi.comma.expressions.generator;

import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.lang.reflect.TypeVariable;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionMap;
import nl.esi.comma.expressions.expression.ExpressionVector;

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
 *       {@link ExpressionVector} → {@code any[]},
 *       {@link ExpressionMap} → {@code map<any,any>},
 *       {@link Expression} → {@code any}
 *   </li>
 *   <li>Collections: {@code List, Collection} → {@code any[]}</li>
 *   <li>Maps: {@code Map} → {@code map<any,any>}</li>
 *   <li>Generic types: {@code List<String>} → {@code string[]}, {@code Map<String, Long>} → {@code map<string, int>}</li>
 *   <li>Custom types: Any other type (e.g., {@code UUID}) → lowercase simple name (e.g., {@code uuid})</li>
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
	 * Converts a single method to a {@code function ...} declaration, or empty if
	 * void.
	 */
	private static Optional<String> toFunctionDecl(Method method) {
		String returnExpr = toExprType(method.getGenericReturnType());
		if (returnExpr == null)
			return Optional.empty();

		String params = IntStream.range(0, method.getParameterCount())
				.mapToObj(i -> toExprType(method.getGenericParameterTypes()[i]) + " " + parameterName(method, i))
				.collect(Collectors.joining(", "));

		return Optional.of("function " + returnExpr + " " + method.getName() + "(" + params + ")");
	}

	// -- Type mapping: Java Type → expr type string ---------------------------

	/**
	 * Maps a Java {@link Type} to an expr type string; returns {@code null} for
	 * void.
	 */
	public static String toExprType(Type type) {
		return switch (type) {
		case Class<?> c when c == void.class || c == Void.class -> null;
		case Class<?> cls -> rawClassToExpr(cls);
		case ParameterizedType pt -> parameterizedToExpr(pt);
		case TypeVariable<?> tv -> "any";
		default -> "any";
		};
	}

	private static final Map<Class<?>, String> TYPE_MAP = Map.ofEntries(Map.entry(boolean.class, "bool"),
			Map.entry(Boolean.class, "bool"), Map.entry(long.class, "int"), Map.entry(Long.class, "int"),
			Map.entry(int.class, "int"), Map.entry(Integer.class, "int"), Map.entry(short.class, "int"),
			Map.entry(Short.class, "int"), Map.entry(byte.class, "int"), Map.entry(Byte.class, "int"),
			Map.entry(double.class, "real"), Map.entry(Double.class, "real"), Map.entry(float.class, "real"),
			Map.entry(Float.class, "real"), Map.entry(BigDecimal.class, "real"), Map.entry(String.class, "string"));

	private static String rawClassToExpr(Class<?> cls) {
		String mapped = TYPE_MAP.get(cls);
		if (mapped != null)            return mapped;
		// Exclude Object - should be treated as "any"
		if (cls == Object.class)       return "any";
		// EMF expression model types
		if (ExpressionVector.class.isAssignableFrom(cls)) return "any[]";
		if (ExpressionMap.class.isAssignableFrom(cls))    return "map<any, any>";
		if (Expression.class.isAssignableFrom(cls))       return "any";
		// Java collection / map types
		if (Collection.class.isAssignableFrom(cls))       return "any[]";
		if (Map.class.isAssignableFrom(cls))              return "map<any, any>";
		// Custom types - use their class name
		return cls.getSimpleName().toLowerCase();
	}

	private static String parameterizedToExpr(ParameterizedType pt) {
		Class<?> raw = (Class<?>) pt.getRawType();
		Type[] args = pt.getActualTypeArguments();

		if (Collection.class.isAssignableFrom(raw)) {
			return (args.length > 0 ? toExprType(args[0]) : "any") + "[]";
		}
		if (Map.class.isAssignableFrom(raw)) {
			return "map<" + (args.length > 0 ? toExprType(args[0]) : "any") + ", "
					+ (args.length > 1 ? toExprType(args[1]) : "any") + ">";
		}
		return rawClassToExpr(raw);
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
