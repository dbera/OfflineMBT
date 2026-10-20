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

import nl.asml.matala.server.ServerLauncher;
import nl.esi.xtext.types.generator.XPlusMain;

public class Main {
	private static final String REST_SERVER = "--rest-server";

	public static void main(String[] args) {
		if (args.length>0 && REST_SERVER.equals(args[0])) {
			LaunchServer(args);
		}
		else {
			generateFiles(args);
		}
	}

	public static void LaunchServer(String[] args) {
		Injector injector = new StandardProjectCliSetup().createInjectorAndDoEMFRegistration();
		ServerLauncher.launch(args, injector);
	}

	public static void generateFiles(String[] args) {
		Injector injector = new StandardProjectCliSetup().createInjectorAndDoEMFRegistration();
		XPlusMain main = injector.getInstance(XPlusMain.class);
		main.configure(args, "ComMA Standard project generator", "project", ".prj");
		main.read();
	}
}