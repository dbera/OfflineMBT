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
 * generated by Xtext 2.19.0
 */
package nl.esi.comma.systemconfig

import nl.esi.comma.types.TypesStandaloneSetup
import nl.esi.comma.expressions.ExpressionStandaloneSetup

/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class ConfigurationStandaloneSetup extends ConfigurationStandaloneSetupGenerated {

	def static void doSetup() {
		new ConfigurationStandaloneSetup().createInjectorAndDoEMFRegistration()
		new TypesStandaloneSetup().createInjectorAndDoEMFRegistration()
		new ExpressionStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}
