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

/**
 * Base class for providing expression function library sets.
 * 
  */
public class ExpressionFunctionLibrariesProvider implements IExpressionFunctionLibrariesProvider {
	private static final Set<Class<?>> libraries = Set.of(DefaultExpressionFunctions.class);

	public Set<Class<?>> get(){
		return libraries;
	}
}
