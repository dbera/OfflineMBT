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

import java.util.Set;

import com.google.inject.Provider;

/**
 * Base interface for providing expression function library sets.
 */
public interface IExpressionFunctionLibrariesProvider  extends Provider<Set<Class<?>>> {
	/**
	 * Provides the set of expression function library classes.
	 * 
	 * @return a set of Class objects representing function libraries (should not be null)
	 */
	Set<Class<?>> get();
}
