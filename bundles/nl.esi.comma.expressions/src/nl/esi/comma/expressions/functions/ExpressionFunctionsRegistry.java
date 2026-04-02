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
package nl.esi.comma.expressions.functions;

import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.google.inject.Inject;

import nl.esi.comma.expressions.conversion.IExpressionConverter;
import nl.esi.comma.expressions.conversion.IExpressionConvertersProvider;
import nl.esi.comma.expressions.evaluation.IEvaluationContext;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionFnCall;
import nl.esi.comma.types.types.Type;

/**
 * Registry for managing expression functions with validation and invocation.
 * Maintains a mapping of function names to methods and provides type conversion
 * of arguments and return values using registered converters.
 */
public class ExpressionFunctionsRegistry {

	private final Map<String, List<Method>> functions = new LinkedHashMap<>();

	private final Set<IExpressionConverter> converters;

	private final InMemoryExprResourceRegistry inMemoryRegistry;

	@Inject
	public ExpressionFunctionsRegistry(InMemoryExprResourceRegistry inMemoryRegistry,
			IExpressionConvertersProvider convertersProvider, IExpressionFunctionLibrariesProvider librariesProvider) {
		this.inMemoryRegistry = inMemoryRegistry;
		librariesProvider.get().stream().forEach(this::addLibraryFunctions);
		this.converters = convertersProvider.get();
	}

	/** Returns an unmodifiable map of all registered functions. */
	public Map<String, List<Method>> getFunctions() {
		return Collections.unmodifiableMap(functions);
	}

	/** Checks if a function with the given name is registered. */
	public boolean hasFunction(String name) {
		return functions.containsKey(name);
	}

	/** Validates function call and arguments against constraints. */
	public void validateFunction(ExpressionFnCall functionCall, IEvaluationContext context)
			throws UnsupportedOperationException, IllegalArgumentException {
		var funcName = functionCall.getFunction().getName();
		if (!functions.containsKey(funcName))
			throw new UnsupportedOperationException("Unknown function: " + funcName);
		if (findMatchingMethod(functionCall, context) == null)
			throw new IllegalArgumentException("No matching overload found for function " + funcName + " with "
					+ functionCall.getArgs().size() + " arguments");

		// Validate function arguments against jakarta.validation constraints
		validateFunctionArguments(functionCall, context);
	}

	/**
	 * Invokes the matching function and returns the result as an Expression. For
	 * instance methods, uses the first object from context assignable to the
	 * declaring class.
	 */
	public Expression invokeFunction(ExpressionFnCall functionCall, IEvaluationContext context) {
		var funcName = functionCall.getFunction().getName();
		var method = findMatchingMethod(functionCall, context);
		if (method == null) {
			throw new IllegalArgumentException("No matching overload found for function " + funcName);
		}
		var args = convertArguments(functionCall, method.getParameterTypes(), context);
		var receiver = getClassInstanceFromContext(context, method);

		try {
			var result = method.invoke(receiver, args);
			return toExpression(result, functionCall.getFunction().getReturnType(), context);
		} catch (Exception e) {
			throw new RuntimeException("Error invoking function " + funcName + " with args " + Arrays.toString(args),
					e);
		}
	}

	/**
	 * Registers all public methods from a library class as expression functions.
	 */
	private void addLibraryFunctions(Class<?> libraryClass) {
		inMemoryRegistry.addLibrary(libraryClass);
		for (Method method : libraryClass.getDeclaredMethods()) {
			if (isPublic(method)) {
				try {
					registerFunction(method.getName(), method);
				} catch (Exception e) {
					System.err.println("Failed to register function " + method.getName() + " from " + libraryClass.getName()
							+ ": " + e.getMessage());
				}
			}
		}
	}

	/** Registers a function method with validation checks. */
	private void registerFunction(String name, Method method) {
		if (method == null)
			throw new IllegalArgumentException("Function cannot be null");
		if (!isPublic(method))
			throw new IllegalArgumentException("Function must be public");
		functions.computeIfAbsent(name, k -> new ArrayList<>()).add(method);
	}

	/**
	 * Validates function arguments against jakarta.validation constraints. Converts
	 * each argument to its Java object representation and validates it against any
	 * constraint annotations on the corresponding method parameter.
	 */
	private void validateFunctionArguments(ExpressionFnCall functionCall, IEvaluationContext context)
			throws IllegalArgumentException {

		Method method = findMatchingMethod(functionCall, context);
		if (method == null) {
			return;
		}
		try {
			convertArguments(functionCall, method.getParameterTypes(), context);
		} catch (Exception e) {
			return; // Skip validation if argument conversion fails (e.g. type mismatch)
		}
	}

	/**
	 * Gets the receiver object for a method from context. For static methods,
	 * returns null. For instance methods, returns the first context library object
	 * assignable to the method's declaring class.
	 */
	private Object getClassInstanceFromContext(IEvaluationContext context, Method method) {
		var libraryObjects = context.getLibraryFunctionObjects();
		Object receiver = null;
		if (!isStatic(method)) {
			var declaring = method.getDeclaringClass();
			receiver = libraryObjects.stream().filter(declaring::isInstance).findFirst()
					.orElseThrow(() -> new IllegalStateException(
							"No instance found for " + declaring.getName() + " in libraryObjects"));
		}
		return receiver;
	}

	/**
	 * Finds a matching method for the given function name and argument list.
	 * Supports method overloading by checking parameter count and type
	 * compatibility.
	 */
	private Method findMatchingMethod(ExpressionFnCall functionCall, IEvaluationContext context) {
		var candidates = functions.get(functionCall.getFunction().getName());
		if (candidates == null) {
			return null;
		}

		var args = functionCall.getArgs();
		for (var method : candidates) {
			if (method.getParameterTypes().length == args.size()) {
				boolean allMatch = true;
				for (int i = 0; i < args.size(); i++) {
					if (!isValidArgumentType(args.get(i), method.getParameterTypes()[i], context)) {
						allMatch = false;
						break;
					}
				}
				if (allMatch) {
					return method;
				}
			}
		}

		return null;
	}

	/** Converts function call arguments to their Java object representations. */
	private Object[] convertArguments(ExpressionFnCall funcCall, Class<?>[] paramTypes, IEvaluationContext context) {
		var funcName = funcCall.getFunction().getName();
		var argExprs = funcCall.getArgs();
		if (argExprs.size() != paramTypes.length) {
			throw new IllegalArgumentException("Argument count mismatch for function '" + funcName + "': expected "
					+ paramTypes.length + " but got " + argExprs.size());
		}
		var argObjects = new Object[argExprs.size()];
		for (int i = 0; i < paramTypes.length; i++) {
			Object argObj = toObject(argExprs.get(i), paramTypes[i], context);
			if (argObj == null)
				throw new IllegalArgumentException("Cannot convert argument " + i + " of function '" + funcName
						+ "' to " + paramTypes[i].getSimpleName());
			argObjects[i] = argObj;
		}
		return argObjects;
	}

	/** Converts a Java object to an Expression using registered converters. */
	private Expression toExpression(Object object, Type type, IEvaluationContext context) {
		for (IExpressionConverter converter : converters) {
			Expression expr = converter.toExpression(object, type, context);
			if (expr != null) {
				return expr;
			}
		}
		return null;
	}

	/** Converts an Expression to a Java object using registered converters. */
	private Object toObject(Expression type, Class<?> paramType, IEvaluationContext context) {
		for (IExpressionConverter converter : converters) {
			if (converter.isConvertible(type, paramType, context)) {
				return converter.toObject(type, paramType, context);
			}
		}
		return null;
	}

	/** Checks if an Expression can be converted to the given Java type. */
	private boolean isValidArgumentType(Expression type, Class<?> paramType, IEvaluationContext context) {
		for (IExpressionConverter converter : converters) {
			if (converter.isConvertible(type, paramType, context)) {
				return true;
			}
		}
		return false;
	}

	/** Checks if a method has public visibility. */
	private boolean isPublic(Method method) {
		return Modifier.isPublic(method.getModifiers());
	}

	/** Checks if a method has static modifier. */
	private boolean isStatic(Method method) {
		return Modifier.isStatic(method.getModifiers());
	}

}