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

/**
 * Provider interface for supplying a set of expression function converters.
 */
public class ExpressionConvertersProvider  implements IExpressionConvertersProvider {
	private static final Set<IExpressionConverter> converters = Set.of(new DefaultExpressionsConverter());

	public Set<IExpressionConverter> get() {
		return converters;
	}
}
