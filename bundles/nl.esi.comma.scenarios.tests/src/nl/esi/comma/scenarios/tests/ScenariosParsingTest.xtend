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
package nl.esi.comma.scenarios.tests

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Assert
import org.junit.Test
import org.junit.runner.RunWith
import nl.esi.comma.scenarios.scenarios.Scenarios

@RunWith(XtextRunner)
@InjectWith(ScenariosInjectorProvider)
class ScenariosParsingTest {
	@Inject
	ParseHelper<Scenarios> parseHelper
	
	@Test
	def void loadModel() {
		val result = parseHelper.parse('''
		import "IBossUI.signature"
		import "IBoss.signature"
		
		    
		Scenario StartupSystemOn
		
		signal SystemOn
		periodic notification SystemOnLed_Blink 
		notification SystemOnLed_On
		''')
		Assert.assertNotNull(result)
		Assert.assertTrue(result.eResource.errors.isEmpty)
	}
}
