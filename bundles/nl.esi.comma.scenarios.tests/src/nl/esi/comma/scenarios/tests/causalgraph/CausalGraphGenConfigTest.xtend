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
package nl.esi.comma.scenarios.tests.causalgraph

import com.google.inject.Inject
import java.util.ArrayList
import nl.esi.comma.scenarios.generator.causalgraph.GenerateCausalGraph
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.scenarios.tests.ScenariosInjectorProvider
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*

@RunWith(typeof(XtextRunner))
@InjectWith(ScenariosInjectorProvider)
class CausalGraphGenConfigTest {
	@Inject ParseHelper<Scenarios> parseHelper
	@Inject IScopeProvider scopeProvider
	
	//ResourceSet set
	InMemoryFileSystemAccess fsa
	
	@Before
	def void setup() {
		fsa = new InMemoryFileSystemAccess()
		var scnModel = parseHelper.parse('''
		feature-name "Feature: BasicTestWithoutData"
		feature-tag "@tag1" "@tag2"
		file-location ""
		Scenario s0 Hash "-1273492148"
			scenario-name "Scenario: Perform basic interaction A"
			scenario-tag "@tagA" "@tagB" "@FeatureA"
						
						Given Action a1
						config [ "FeatureA" ]
						product-set [ "configA" "configC" ]
						
						When Action a2
						config [ "FeatureA" ]
						product-set [ "configA" "configC" ]
						
						And Action a3
						config [ "FeatureA" ]
						product-set [ "configA" "configC" ]
						
						Then Action a1
						config [ "FeatureA" ]
						product-set [ "configA" "configC" ]
						
						When Action a2
						config [ "FeatureA" ]
						product-set [ "configA" "configC" ]
						
						Then Action a3
						config [ "FeatureA" ]
						product-set [ "configA" "configC" ]
						
		feature-name "Feature: BasicTestWithoutData"
		feature-tag "@tag1" "@tag2"
		file-location ""
		Scenario s1 Hash "-1273492147"
			scenario-name "Scenario: Perform basic interaction B"
			scenario-tag "@tagC" "@tagD" "@FeatureB"
			
						Given Action a4
						config [ "FeatureB" ]
						product-set [ "configB" "configC" ]
						
						When Action a3
						config [ "FeatureB" ]
						product-set [ "configB" "configC" ]
						
						Then Action a2
						config [ "FeatureB" ]
						product-set [ "configB" "configC" ]
						
						When Action a5
						config [ "FeatureB" ]
						product-set [ "configB" "configC" ]
						
						Then Action a6
						config [ "FeatureB" ]
						product-set [ "configB" "configC" ]
						
		feature-name "Feature: BasicTestWithoutData"
		feature-tag "@tag1" "@tag2"
		file-location ""
		Scenario s2 Hash "-1273492146"
			scenario-name "Scenario: Perform basic interaction C"
			scenario-tag "@tagB" "@tagD" "@FeatureC"
						Given Action a5
						config [ "FeatureC" ]
						product-set [ "configC" ]
						
						When Action a6
						config [ "FeatureC" ]
						product-set [ "configC" ]
						
						Then Action a1
						config [ "FeatureC" ]
						product-set [ "configC" ]
		''')
		var scnSources = new ArrayList<Scenarios>
		scnSources.add(scnModel)
		(new GenerateCausalGraph).generateCausalGraph(fsa, scopeProvider, scnSources, "SimpleWithConfig")
		
	}
	
	@Test
	def generateGraph(){
		val file = IFileSystemAccess::DEFAULT_OUTPUT +"..\\test-gen\\SpecFlowToScenarios\\SimpleWithConfig\\graph.scn"
		
		assertTrue(fsa.textFiles.containsKey(file))
		assertEquals(ExpectedGraph.ISimpleWithConfigTest.toString, fsa.textFiles.get(file).toString)
	}
}