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
/*
 * generated by Xtext 2.25.0
 */
package nl.esi.comma.behavior.scl;


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
public class SclStandaloneSetup extends SclStandaloneSetupGenerated {

	public static void doSetup() {
		new SclStandaloneSetup().createInjectorAndDoEMFRegistration();
	}
}
