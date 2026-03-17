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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.google.inject.Inject;

import nl.esi.comma.expressions.conversion.DefaultExpressionsConverter;
import nl.esi.comma.expressions.conversion.ExpressionConverter;
import nl.esi.comma.expressions.evaluation.IEvaluationContext;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionFnCall;
import nl.esi.comma.types.types.Type;

/**
 * Registry for managing expression functions and their conversion.
 * 
 * This registry maintains a mapping of function names to methods and provides
 * facilities for validating and invoking expression functions with proper
 * type conversion of arguments.
 * 
 * The registry is managed by Xtext's Guice container and available as a singleton
 * throughout the application lifecycle. Injected converters handle type conversion
 * from expression types to Java types.
 * 
 * Usage:
 * ------
 * // Inject into your component
 * @Inject private FunctionsRegistry registry;
 * 
 * // Add functions from a library
 * registry.addLibraryFunctions(MyFunctionsLibrary.class);
 * 
 * // Validate a function call
 * registry.validateFunction(functionCall);
 * 
 * // Invoke a function
 * Object result = registry.invokeFunction(functionCall);
 */
public class ExpressionFunctionsRegistry {
	
	private static final int METHOD_CACHE_SIZE = 64;
	
	private final Map<String, List<Method>> functions = new LinkedHashMap<>();
	private final List<ExpressionConverter> converters = new ArrayList<>();
	private final InMemoryExprResourceRegistry inMemoryRegistry;
	private final Map<Integer, Method> methodCache = new LinkedHashMap<>(METHOD_CACHE_SIZE, 0.75f, true) {
		private static final long serialVersionUID = 1L;
		@Override
		protected boolean removeEldestEntry(Map.Entry<Integer, Method> eldest) {
			return size() > METHOD_CACHE_SIZE;
		}
	};

	@Inject
	public ExpressionFunctionsRegistry(InMemoryExprResourceRegistry inMemoryRegistry) {
		this.inMemoryRegistry = inMemoryRegistry;
		addConverter(new DefaultExpressionsConverter());
		addLibraryFunctions(DefaultExpressionFunctions.class);
		
	}
	
	public void addConverter(ExpressionConverter converter) {
		this.converters.add(converter);
	}

	/** Registers all public methods of {@code libraryClass} as expression functions. */
	public void addLibraryFunctions(Class<?> libraryClass) {
		inMemoryRegistry.addLibrary(libraryClass);
		for (Method method : libraryClass.getDeclaredMethods()) {
			if (isPublic(method)) {
				try {
					registerFunction(method.getName(), method);
				} catch (Exception e) {
					// ignore
				}
			}
		}
	}

	public Map<String, List<Method>> getFunctions() {
		return functions;
	}

	private void registerFunction(String name, Method method) {
		if (method == null) throw new IllegalArgumentException("Function cannot be null");
		if (!isPublic(method)) throw new IllegalArgumentException("Function must be public");
		functions.computeIfAbsent(name, k -> new ArrayList<>()).add(method);
	}
	
	public boolean hasFunction(String name) {
		return functions.containsKey(name);
	}

	public void validateFunction(ExpressionFnCall functionCall, IEvaluationContext context) throws UnsupportedOperationException, IllegalArgumentException {
		String funcName = functionCall.getFunction().getName();
		if (!functions.containsKey(funcName))
			throw new UnsupportedOperationException("Unknown function: " + funcName);
		if (findMatchingMethod(functionCall, context) == null)
			throw new IllegalArgumentException("No matching overload found for function " + funcName
				+ " with " + functionCall.getArgs().size() + " arguments");
	}

	/**
	 * Invokes the matching function and returns the result as an Expression.
	 * {@code libraryObjects} provides receivers for non-static methods;
	 * the first object assignable to the method's declaring class is used.
	 */
	public Expression invokeFunction(ExpressionFnCall functionCall, IEvaluationContext context) {
		String funcName = functionCall.getFunction().getName();
		Method method = findMatchingMethod(functionCall, context);
		if (method == null)
			throw new IllegalArgumentException("No matching overload found for function " + funcName);
		List<Object> libraryObjects = context.getLibraryFunctionObjects();

		List<Object> argObjects = new ArrayList<>(functionCall.getArgs().size());
		Object[] args = new Object[method.getParameterTypes().length];
		for (int i = 0; i < args.length; i++) {
			Object argObj = fromExpression(functionCall.getArgs().get(i), method.getParameterTypes()[i], context);
			if (argObj == null)
				throw new IllegalArgumentException("Cannot convert argument " + i + " of function '" + funcName
					+ "' to " + method.getParameterTypes()[i].getSimpleName());
			args[i] = argObj;
			argObjects.add(argObj);
		}

		// For instance methods, find the first object assignable to the declaring class
		Object receiver = null;
		if (!isStatic(method)) {
			Class<?> declaring = method.getDeclaringClass();
			receiver = libraryObjects.stream()
				.filter(declaring::isInstance)
				.findFirst()
				.orElseThrow(() -> new IllegalStateException(
					"No instance found for " + declaring.getName() + " in libraryObjects"));
		}

		try {
			var result = method.invoke(receiver, args);
			return toExpression(result, functionCall.getFunction().getReturnType(), context);
		} catch (Exception e) {
			throw new RuntimeException("Error invoking function " + funcName + " with args " + argObjects, e);
		}
	}
	
	/**
	 * Finds a matching method for the given function name and argument list.
	 * Supports method overloading by checking parameter count and type compatibility.
	 * 
	 * @param funcName the function name
	 * @param args the argument expressions
	 * @return the matching method, or null if no match found
	 */
	private Method findMatchingMethod(ExpressionFnCall functionCall, IEvaluationContext context) {
		int cacheKey = System.identityHashCode(functionCall);
		
		Method cached = methodCache.get(cacheKey);
		if (cached != null) {
			return cached;
		}
		
		List<Method> candidates = functions.get(functionCall.getFunction().getName());
		if (candidates == null) {
			return null;
		}
		
		List<Expression> args = functionCall.getArgs();
		for (Method method : candidates) {
			if (method.getParameterTypes().length == args.size()) {
				boolean allMatch = true;
				for (int i = 0; i < args.size(); i++) {
					if (!isValidArgumentType(args.get(i), method.getParameterTypes()[i], context)) {
						allMatch = false;
						break;
					}
				}
				if (allMatch) {
					methodCache.put(cacheKey, method);
					return method;
				}
			}
		}
		
		return null;
	}
	
	
	private Expression toExpression(Object object, Type type, IEvaluationContext context) {
		for(ExpressionConverter converter : converters) {
			Expression expr = converter.toExpression(object, type, context);
			if(expr != null) {
				return expr;
			}
		}
		return null;
	}

	
	
	private Object fromExpression(Expression type, Class<?> paramType, IEvaluationContext context) {
		for(ExpressionConverter converter : converters) {
			if(converter.isConvertible(type, paramType, context)) {
				return converter.toObject(type, paramType, context);
			}
		}
		return null;
	}

	private boolean isValidArgumentType(Expression type, Class<?> paramType, IEvaluationContext context) {
		for(ExpressionConverter converter : converters) {
			if(converter.isConvertible(type, paramType, context)) {
				return true;
			}
		}
		return false;
	}
	
	private boolean isPublic(Method method) {
		return Modifier.isPublic(method.getModifiers());
	}

	private boolean isStatic(Method method) {
		return Modifier.isStatic(method.getModifiers());
	}

	private boolean isPublicStatic(Method method) {
		return isPublic(method) && isStatic(method);
	}
}