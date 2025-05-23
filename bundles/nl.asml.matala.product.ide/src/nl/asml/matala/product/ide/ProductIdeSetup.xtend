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
 * generated by Xtext 2.36.0
 */
package nl.asml.matala.product.ide

import com.google.inject.Guice
import nl.asml.matala.product.ProductRuntimeModule
import nl.asml.matala.product.ProductStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class ProductIdeSetup extends ProductStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new ProductRuntimeModule, new ProductIdeModule))
	}
	
}
