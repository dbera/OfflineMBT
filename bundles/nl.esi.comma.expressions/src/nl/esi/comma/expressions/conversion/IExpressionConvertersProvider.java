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
package nl.esi.comma.expressions.conversion;

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
