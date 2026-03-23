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

/**
 * Base class for providing expression function library sets.
 * 
  */
public class ExpressionFunctionLibrariesProvider implements IExpressionFunctionLibrariesProvider {
	public Set<Class<?>> get(){
		return Set.of(DefaultExpressionFunctions.class);
	}
}
