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
package nl.esi.comma.systemconfig.ide

import com.google.inject.Guice
import nl.esi.comma.systemconfig.ConfigurationRuntimeModule
import nl.esi.comma.systemconfig.ConfigurationStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class ConfigurationIdeSetup extends ConfigurationStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new ConfigurationRuntimeModule, new ConfigurationIdeModule))
	}
	
}
