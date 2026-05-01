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

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.apache.log4j.Logger;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.URIHandler;

import com.google.inject.Inject;
import com.google.inject.Singleton;

import nl.esi.comma.expressions.conversion.IExpressionConverter;
import nl.esi.comma.expressions.conversion.IExpressionConvertersProvider;
import nl.esi.comma.expressions.evaluation.IEvaluationContext;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionFunctionCall;
import nl.esi.comma.types.types.Type;

/**
 * Registry for managing expression functions with validation and invocation.
 * Maintains a mapping of function names to methods and provides type conversion
 * of arguments and return values using registered converters.
 */
@Singleton
public class ExpressionFunctionsRegistry {
	
	public static final URI EXPR_URI = InMemoryExprResourceRegistry.IMR_URI;
	
	private static final Logger logger = Logger.getLogger(ExpressionFunctionsRegistry.class);
	
	public static class NoMatchingFunctionFoundException extends RuntimeException {
		private static final long serialVersionUID = 1L;

		public NoMatchingFunctionFoundException(String message) {
			super(message);
		}
	}

	private final Map<String, List<Method>> functions = new LinkedHashMap<>();

	private final List<IExpressionConverter> converters;

	private final InMemoryExprResourceRegistry inMemoryRegistry = new InMemoryExprResourceRegistry();


	@Inject
	public ExpressionFunctionsRegistry(IExpressionConvertersProvider convertersProvider, IExpressionFunctionLibrariesProvider librariesProvider) {
		librariesProvider.get().stream().forEach(this::addLibraryFunctions);
		this.converters = new ArrayList<>(convertersProvider.get());
	}
	
	/** Returns an unmodifiable map of all registered functions. */
	public Map<String, List<Method>> getFunctions() {
		return Collections.unmodifiableMap(functions);
	}

	/** Checks if a function with the given name is registered. */
	public boolean hasFunction(String name) {
		return functions.containsKey(name);
	}

	/**
	 * Invokes the matching function and returns the result as an Expression. For
	 * instance methods, uses the first object from context assignable to the
	 * declaring class.
	 */
	public Expression invokeFunction(ExpressionFunctionCall functionCall, IEvaluationContext context) throws NoMatchingFunctionFoundException {
		var funcName = functionCall.getFunction().getName();
		var method = findMatchingMethod(functionCall, context);
		if (method == null) {
			throw new NoMatchingFunctionFoundException("No matching overload found for function " + funcName);
		}
		var args = convertArguments(functionCall, method.getParameterTypes(), context);
		var receiver = getClassInstanceFromContext(context, method);

		try {
			try {
				var result = method.invoke(receiver, args);
				return toExpression(result, functionCall.getFunction().getReturnType(), context);
			} catch (InvocationTargetException e) {
				throw e.getTargetException();
			}// Rethrow runtime exceptions without wrapping
		} catch (RuntimeException e) {
			throw e; // Rethrow runtime exceptions without wrapping
		} catch (Throwable e) {
			throw new RuntimeException("Error invoking function " + funcName + " with args " + Arrays.toString(args),
					e);
		}
	}
	/**
	 *  Returns the URIHandler from the in-memory registry, which can be used to resolve URIs for resources
	 */
	public URIHandler getURIHandler() {
		return inMemoryRegistry.getURIHandler();
	}
	
    /** Returns an iterable of all registered URIs in the  registry. */
	public Iterable<? extends URI> getRegisteredURIs() {
	  return  inMemoryRegistry.getRegisteredURIs();
	}
	/** Checks if the registry can handle the given URI. */
	public boolean handlesURI(URI uri) {
		return inMemoryRegistry.handles(uri);
	}

	/** Returns the content associated with the given URI, or null if not found. */
	public String getContent(URI uri) {
		return inMemoryRegistry.getContent(uri);
	}
    
	
	public void addConverter(IExpressionConverter converter) {
		converters.add(converter);
	}
	/**
	 * Registers all public methods from a library class as expression functions.
	 */
	public void addLibraryFunctions(Class<?> libraryClass) {
		for (Method method : libraryClass.getDeclaredMethods()) {
			if (isPublic(method)) {
				try {
					registerFunction(method.getName(), method);
				} catch (Exception e) {
					logger.error(String.format("Failed to register function '%s.%s': %s", libraryClass.getName(), getSignature(method), e.getMessage()));
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
		inMemoryRegistry.addMethod(method);
		var overloads = functions.computeIfAbsent(name, k -> new ArrayList<>());
		overloads.add(method);
	}

	private String getSignature(Method method) {
		return method.getName() + Arrays.stream(method.getParameterTypes()).map(Class::getSimpleName)
				.collect(Collectors.joining(",", "(", ")"));
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
	private Method findMatchingMethod(ExpressionFunctionCall functionCall, IEvaluationContext context) {
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
	private Object[] convertArguments(ExpressionFunctionCall funcCall, Class<?>[] paramTypes, IEvaluationContext context) {
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
			var expression = converter.toExpression(object, type);
			if (expression.isPresent()) {
				return expression.get();
			}
		}
		return null;
	}

	/** Converts an Expression to a Java object using registered converters. */
	private Object toObject(Expression type, Class<?> paramType, IEvaluationContext context) {
		for (IExpressionConverter converter : converters) {
			var obj = converter.toObject(type, paramType);
				if (obj.isPresent()) {
					return obj.get();
				}
		}
		return null;
	}

	/** Checks if an Expression can be converted to the given Java type. */
	private boolean isValidArgumentType(Expression expression, Class<?> paramType, IEvaluationContext context) {

		for (IExpressionConverter converter : converters) {
			if (converter.toObject(expression, paramType).isPresent()) {
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