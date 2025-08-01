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

import nl.asml.matala.product.ProductStandaloneSetup;
import nl.esi.comma.inputspecification.InputSpecificationStandaloneSetup;
import nl.esi.comma.project.standard.StandardProjectStandaloneSetup;
import nl.esi.comma.signature.InterfaceSignatureStandaloneSetup;
import nl.esi.comma.testspecification.TestspecificationStandaloneSetup;
import nl.esi.comma.abstracttestspecification.AbstractTestspecificationStandaloneSetup;
import nl.esi.comma.types.generator.CommaMain;

public class Main {

	public static void main(String[] args) {
	    InterfaceSignatureStandaloneSetup.doSetup();
	    InputSpecificationStandaloneSetup.doSetup();
	    TestspecificationStandaloneSetup.doSetup();
	    AbstractTestspecificationStandaloneSetup.doSetup();
		ProductStandaloneSetup.doSetup();
		
		Injector injector = new StandardProjectStandaloneSetup().createInjectorAndDoEMFRegistration();
	    CommaMain main = injector.getInstance(CommaMain.class);
	    main.configure(args, "ComMA Standard project generator", "project", ".prj");
	    main.read();
	}
}
