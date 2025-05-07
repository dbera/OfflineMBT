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
package nl.esi.comma.systemconfig.tests

import org.eclipse.xtext.testing.InjectWith
import org.junit.runner.RunWith
import org.eclipse.xtext.testing.XtextRunner
import nl.esi.comma.systemconfig.configuration.FeatureDefinition
import com.google.inject.Inject
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Assert
import org.junit.Test

@RunWith(XtextRunner)
@InjectWith(ConfigurationInjectorProvider)
class ConfigurationParsingTest {
	@Inject
	ParseHelper<FeatureDefinition> parseHelper
	
	@Test
	def void loadModel(){
		val result = parseHelper.parse('''
		Feature-list {
			bool FeatureA
			bool FeatureB
			bool FeatureC
		}
		
		Configuration configA {
			FeatureA,
			FeatureC
		}
		
		Configuration configB {
			FeatureB
		}
		
		Configuration configC {
			FeatureC
		}
		''')
		Assert.assertNotNull(result)
		Assert.assertTrue(result.eResource.errors.isEmpty)
	}
}
