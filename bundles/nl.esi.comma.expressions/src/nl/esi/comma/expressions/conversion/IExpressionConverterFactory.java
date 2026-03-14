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

import java.util.List;

/**
 * Factory interface for creating and managing expression converters.
 * 
 * Implementations of this interface are responsible for instantiating
 * and configuring all available expression converters that handle conversion
 * from expression language types to Java types.
 * 
 * Converters are returned in priority order - the first converter that
 * reports it can convert a value (via isConvertible) will be used.
 */
public interface IExpressionConverterFactory {
	
	/**
	 * Creates and configures all available expression converters.
	 * 
	 * @return an ordered list of converters (first match wins)
	 */
	List<ExpressionConverter> createConverters();
}
