/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.functions;

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
