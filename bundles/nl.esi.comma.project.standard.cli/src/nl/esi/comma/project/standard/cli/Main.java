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

import com.google.inject.Injector;

import nl.esi.xtext.types.generator.CommaMain;

public class Main {
	public static void main(String[] args) {
		Injector injector = new StandardProjectCliSetup().createInjectorAndDoEMFRegistration();
		CommaMain main = injector.getInstance(CommaMain.class);
		main.configure(args, "ComMA Standard project generator", "project", ".prj");
		main.read();
	}
}
