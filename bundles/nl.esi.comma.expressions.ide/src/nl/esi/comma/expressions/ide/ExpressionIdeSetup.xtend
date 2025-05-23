/**
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
/*
 * generated by Xtext 2.12.0
 */
package nl.esi.comma.expressions.ide

import com.google.inject.Guice
import nl.esi.comma.expressions.ExpressionRuntimeModule
import nl.esi.comma.expressions.ExpressionStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class ExpressionIdeSetup extends ExpressionStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new ExpressionRuntimeModule, new ExpressionIdeModule))
	}
	
}
