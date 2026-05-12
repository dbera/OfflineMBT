/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.conversion;

import java.util.Set;

import com.google.inject.Provider;

/**
 * Base interface for providing expression converter sets.
 * 
 */
public interface IExpressionConvertersProvider extends Provider<Set<IExpressionConverter>> {
	/**
	 * Provides the set of expression converters.
	 * 
	 * @return a set of converters (should not be null)
	 */
	Set<IExpressionConverter> get();
}
