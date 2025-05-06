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

import org.eclipse.xtext.testing.XtextRunner
import org.junit.runner.RunWith
import org.eclipse.xtext.testing.InjectWith
import nl.esi.comma.scenarios.tests.ScenariosInjectorProvider
import com.google.inject.Inject
import org.eclipse.xtext.testing.util.ParseHelper
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.scoping.IScopeProvider
import org.junit.Before
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import java.util.ArrayList
import nl.esi.comma.scenarios.generator.causalgraph.GenerateCausalGraph
import org.junit.Test
import org.eclipse.xtext.generator.IFileSystemAccess
import static org.junit.Assert.*
@RunWith(typeof(XtextRunner))
@InjectWith(ScenariosInjectorProvider)
class WithTestConfigTest {
	@Inject ParseHelper<Scenarios> parseHelper
	@Inject IScopeProvider scopeProvider
	
	//ResourceSet set
	InMemoryFileSystemAccess fsa
	
	@Before
	def void setup() {
		fsa = new InMemoryFileSystemAccess()
		var scnModel = parseHelper.parse('''
		feature-name "Feature: VendingMachine"
		file-location "C:/ComMA/TestingPhilips/ScenarioTest/features/TestForScenario.feature"
		Scenario s0 Hash "-462344139"
		    scenario-name "Scenario: switch on"
		    scenario-tag "@FeatureC" 
		    // Given step
		                Given Action _machine_is_off_
		    			config [ "FeatureC" ]
		    			product-set [ "configA" "configC" ]
		    /*
		    */
		    // When step
		                When Action _switch_on_
		    			event-set [ "SwitchOn" ]
		    			config [ "FeatureC" ]
		    			product-set [ "configA" "configC" ]
		    /*
		    */
		    // Then step
		                Then Action _check_inventory_
		    			event-set [ "CheckInventory" ]
		    			config [ "FeatureC" ]
		    			product-set [ "configA" "configC" ]
		    /*
		    */
		    // Then step
		                Then Action _machine_is_on_
		    			config [ "FeatureC" ]
		    			product-set [ "configA" "configC" ]
		    /*
		    */
		feature-name "Feature: VendingMachine"
		file-location "C:/ComMA/TestingPhilips/ScenarioTest/features/TestForScenario.feature"
		Scenario s1 Hash "-1447766567"
		    scenario-name "Scenario: switch off"
		    scenario-tag "@FeatureC" 
		    // Given step
		                Given Action _machine_is_on_
		    			config [ "FeatureC" ]
		    			product-set [ "configA" "configC" ]
		    /*
		    */
		    // When step
		                When Action _switch_off_
		    			event-set [ "SwitchOff" ]
		    			config [ "FeatureC" ]
		    			product-set [ "configA" "configC" ]
		    /*
		    */
		    // Then step
		                Then Action _machine_is_off_
		    			config [ "FeatureC" ]
		    			product-set [ "configA" "configC" ]
		    /*
		    */
		feature-name "Feature: VendingMachine"
		file-location "C:/ComMA/TestingPhilips/ScenarioTest/features/TestForScenario.feature"
		Scenario s2  Hash "348214829"
		    scenario-name "Scenario: out of order"
		    scenario-tag "@FeatureA" 
		    // Given step
		                Given Action _machine_is_on_
		    			config [ "FeatureA" ]
		    			product-set [ "configA" ]
		    /*
		    */
		    // When step
		                When Action _throw_coins_in_
		                data [ "arg0" : "3" : "s2"]
		    			event-set [ "ThrowCoinsIn" ]
		    			config [ "FeatureA" ]
		    			product-set [ "configA" ]
		    /*
		    */
		    // And step
		                And Action _order_product_
		                data [ "arg0" : "cola" : "s2"]
		    			event-set [ "OrderProduct" ]
		    			config [ "FeatureA" ]
		    			product-set [ "configA" ]
		    /*
		    */
		    // Then step
		                Then Action _out_of_order_
		    			event-set [ "OutofOrder" ]
		    			config [ "FeatureA" ]
		    			product-set [ "configA" ]
		    /*
		    */
		    // And step
		                And Action _return_money_
		    			config [ "FeatureA" ]
		    			product-set [ "configA" ]
		    /*
		    */
		feature-name "Feature: VendingMachine"
		file-location "C:/ComMA/TestingPhilips/ScenarioTest/features/TestForScenario.feature"
		Scenario s3 Hash "-671687929"
		    scenario-name "Scenario: order product"
		    scenario-tag "@FeatureB" 
		    // Given step
		                Given Action _machine_is_on_
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // When step
		                When Action _throw_coins_in_
		                data [ "arg0" : "2" : "s3"]
		    			event-set [ "ThrowCoinsIn" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // And step
		                And Action _order_product_
		                data [ "arg0" : "water" : "s3"]
		    			event-set [ "OrderProduct" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // Then step
		                Then Action _get_product_
		                data [ "arg0" : "water" : "s3"]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // And step
		                And Action _update_inventory_info_of_product_
		                data [ "arg0" : "water" : "s3"]
		    			event-set [ "UpdateInventoryInfoOfProduct" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // When step
		                When Action _throw_coins_in_
		                data [ "arg0" : "3" : "s3"]
		    			event-set [ "ThrowCoinsIn" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // And step
		                And Action _order_product_
		                data [ "arg0" : "cola" : "s3"]
		    			event-set [ "OrderProduct" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // Then step
		                Then Action _get_product_
		                data [ "arg0" : "cola" : "s3"]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // And step
		                And Action _update_inventory_info_of_product_
		                data [ "arg0" : "cola" : "s3"]
		    			event-set [ "UpdateInventoryInfoOfProduct" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		feature-name "Feature: VendingMachine"
		file-location "C:/ComMA/TestingPhilips/ScenarioTest/features/TestForScenario.feature"
		Scenario s4 Hash "-1417738989"
		    scenario-name "Scenario: not enough money"
		    scenario-tag "@FeatureB" 
		    // Given step
		                Given Action _machine_is_on_
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // When step
		                When Action _throw_coins_in_
		                data [ "arg0" : "2" : "s4"]
		    			event-set [ "ThrowCoinsIn" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // And step
		                And Action _order_product_
		                data [ "arg0" : "cola" : "s4"]
		    			event-set [ "OrderProduct" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		    // Then step
		                Then Action _show_message_
		    			event-set [ "ShowMessage" ]
		    			config [ "FeatureB" ]
		    			product-set [ "configB" ]
		    /*
		    */
		''')
		var scnSources = new ArrayList<Scenarios>
		scnSources.add(scnModel)
		(new GenerateCausalGraph).generateCausalGraph(fsa, scopeProvider, scnSources, "WithEventSet")
		
	}
	
	@Test
	def generateGraph(){
		val file = IFileSystemAccess::DEFAULT_OUTPUT +"..\\test-gen\\SpecFlowToScenarios\\WithEventSet\\graph.scn"
		
		assertTrue(fsa.textFiles.containsKey(file))
		assertEquals(ExpectedGraph.IWithEventSet.toString, fsa.textFiles.get(file).toString)
	}
}