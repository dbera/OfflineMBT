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

/**
 * Provider interface for supplying a set of expression function converters.
 */
public class ExpressionConvertersProvider  implements IExpressionConvertersProvider {
	private static final Set<IExpressionConverter> converters = Set.of(new DefaultExpressionsConverter());

	public Set<IExpressionConverter> get() {
		return converters;
	}
}
