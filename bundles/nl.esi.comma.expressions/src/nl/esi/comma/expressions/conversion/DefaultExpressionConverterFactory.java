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

import java.util.ArrayList;
import java.util.List;

/**
 * Default implementation of IExpressionConverterFactory.
 * 
 * This factory creates and manages the standard set of expression converters.
 * Converters are returned in priority order:
 * 1. DefaultExpressionsConverter - handles most expression types
 * 
 * Additional converters can be added by extending this class or
 * providing an alternative factory implementation.
 */
public class DefaultExpressionConverterFactory implements IExpressionConverterFactory {
	
	/**
	 * Creates the default set of expression converters.
	 * 
	 * The converters are ordered by priority - the first converter
	 * that can handle a conversion (via isConvertible) will be used.
	 * 
	 * @return ordered list of available converters
	 */
	@Override
	public List<ExpressionConverter> createConverters() {
		List<ExpressionConverter> converters = new ArrayList<>();
		
		// Primary converter for standard expression types
		converters.add(new DefaultExpressionsConverter());
		
		// Additional converters can be added here:
		// converters.add(new CustomTypeConverter());
		// converters.add(new LegacyTypeConverter());
		// ... etc
		
		return converters;
	}
}
