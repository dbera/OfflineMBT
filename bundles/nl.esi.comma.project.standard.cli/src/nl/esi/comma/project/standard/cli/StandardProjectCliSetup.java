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
package nl.esi.comma.project.standard.cli;

import com.google.inject.Guice;
import com.google.inject.Injector;

import nl.esi.comma.project.standard.StandardProjectStandaloneSetupGenerated;

class StandardProjectCliSetup extends StandardProjectStandaloneSetupGenerated {
	@Override
	public Injector createInjector() {
		return Guice.createInjector(new StandardProjectCliModule());
	}
}