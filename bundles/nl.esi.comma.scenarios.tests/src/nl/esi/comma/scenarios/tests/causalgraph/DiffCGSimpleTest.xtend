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
import org.junit.Before
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import nl.esi.comma.scenarios.generator.causalgraph.GenerateCausalGraph
import org.junit.Test
import org.eclipse.xtext.generator.IFileSystemAccess
import static org.junit.Assert.*
@RunWith(typeof(XtextRunner))
@InjectWith(ScenariosInjectorProvider)
class DiffCGSimpleTest {
	@Inject ParseHelper<Scenarios> parseHelper
	
	//ResourceSet set
	InMemoryFileSystemAccess fsa
	
	@Before
	def void setup() {
		fsa = new InMemoryFileSystemAccess()
		var cg1 = parseHelper.parse('''
		action-list: {
			Given _machine_is_off_ "_machine_is_off_"
			When _switch_on_ "_switch_on_"
			Then _check_inventory_ "_check_inventory_"
			Then _machine_is_on_ "_machine_is_on_"
			When _switch_off_ "_switch_off_"
			When _throw_coins_in_ "_throw_coins_in_"
			And _order_product_ "_order_product_"
			Then _out_of_order_ "_out_of_order_"
			And _return_money_ "_return_money_"
			Then _get_product_ "_get_product_"
			And _update_inventory_info_of_product_ "_update_inventory_info_of_product_"
			Then _show_message_ "_show_message_"
		}
		
		Causal-Graph demoCausalGraph {
			
			Action _machine_is_off_  {
				init
				term
				test-set [ 
				"-462344139" 
				"-1447766567" 
				]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-462344139" : "ALL CONFIGURATIONS" ;"-1447766567" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-462344139" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _switch_on_ ]
				
			}
			
			Action _switch_on_  {
				test-set [ 
				"-462344139" 
				]
				event-set [ "SwitchOn" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-462344139" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-462344139" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _check_inventory_ ]
				
			}
			
			Action _check_inventory_  {
				test-set [ 
				"-462344139" 
				]
				event-set [ "CheckInventory" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-462344139" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-462344139" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _machine_is_on_ ]
				
			}
			
			Action _machine_is_on_  {
				init
				term
				test-set [ 
				"-671687929" 
				"-462344139" 
				"348214829" 
				"-1417738989" 
				"-1447766567" 
				]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;"-462344139" : "ALL CONFIGURATIONS" ;"348214829" : "ALL CONFIGURATIONS" ;"-1417738989" : "ALL CONFIGURATIONS" ;"-1447766567" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-1447766567" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _switch_off_ ]
				
				edge  -{
					test-set [ 
					"-671687929" 
					"348214829" 
					"-1417738989" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _throw_coins_in_ ]
				
			}
			
			Action _switch_off_  {
				test-set [ 
				"-1447766567" 
				]
				event-set [ "SwitchOff" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-1447766567" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-1447766567" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _machine_is_off_ ]
				
			}
			
			Action _throw_coins_in_  {
				
				data ["-671687929" - "0"] ["arg0" : "2"]
				data ["-1417738989" - "0"] ["arg0" : "2"]
				test-set [ 
				"-671687929" 
				"348214829" 
				"-1417738989" 
				]
				event-set [ "ThrowCoinsIn" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;"348214829" : "ALL CONFIGURATIONS" ;"-1417738989" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-671687929" 
					"348214829" 
					"-1417738989" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _order_product_ ]
				
			}
			
			Action _order_product_  {
				
				data ["348214829" - "0"] ["arg0" : "cola"]
				data ["-671687929" - "0"] ["arg0" : "water"]
				data ["-1417738989" - "0"] ["arg0" : "cola"]
				test-set [ 
				"-671687929" 
				"348214829" 
				"-1417738989" 
				]
				event-set [ "OrderProduct" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;"348214829" : "ALL CONFIGURATIONS" ;"-1417738989" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"348214829" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _out_of_order_ ]
				
				edge  -{
					test-set [ 
					"-671687929" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _get_product_ ]
				
				edge  -{
					test-set [ 
					"-1417738989" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _show_message_ ]
				
			}
			
			Action _out_of_order_  {
				test-set [ 
				"348214829" 
				]
				event-set [ "OutofOrder" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "348214829" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"348214829" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _return_money_ ]
				
			}
			
			Action _return_money_  {
				term
				test-set [ 
				"348214829" 
				]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "348214829" : "ALL CONFIGURATIONS" ;]
			}
			
			Action _get_product_  {
				
				data ["-671687929" - "0"] ["arg0" : "water"]
				test-set [ 
				"-671687929" 
				]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-671687929" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _update_inventory_info_of_product_ ]
				
			}
			
			Action _update_inventory_info_of_product_  {
				term
				
				data ["-671687929" - "0"] ["arg0" : "water"]
				test-set [ 
				"-671687929" 
				]
				event-set [ "UpdateInventoryInfoOfProduct" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;]
			}
			
			Action _show_message_  {
				term
				test-set [ 
				"-1417738989" 
				]
				event-set [ "ShowMessage" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-1417738989" : "ALL CONFIGURATIONS" ;]
			}
		}
		''')
		
		var cg2 = parseHelper.parse('''
		action-list: {
			Given _machine_is_off_ "_machine_is_off_"
			When _switch_on_ "_switch_on_"
			Then _check_inventory_ "_check_inventory_"
			Then _machine_is_on_ "_machine_is_on_"
			When _switch_off_ "_switch_off_"
			When _throw_coins_in_ "_throw_coins_in_"
			And _order_product_ "_order_product_"
			Then _out_of_order_ "_out_of_order_"
			And _return_money_ "_return_money_"
			Then _get_product_ "_get_product_"
			And _update_inventory_info_of_product_ "_update_inventory_info_of_product_"
			Then _show_message_ "_show_message_"
		}
		
		Causal-Graph demoCausalGraph {
			
			Action _machine_is_off_  {
				init
				term
				test-set [ 
				"-462344139" 
				"-1447766567" 
				]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-462344139" : "ALL CONFIGURATIONS" ;"-1447766567" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-462344139" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _switch_on_ ]
				
			}
			
			Action _switch_on_  {
				test-set [ 
				"-462344139" 
				]
				event-set [ "SwitchOn" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-462344139" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-462344139" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _check_inventory_ ]
				
			}
			
			Action _check_inventory_  {
				test-set [ 
				"-462344139" 
				]
				event-set [ "CheckInventory" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-462344139" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-462344139" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _machine_is_on_ ]
				
			}
			
			Action _machine_is_on_  {
				init
				term
				test-set [ 
				"-671687929" 
				"-462344139" 
				"348214829" 
				"-1417738989" 
				"-1447766567" 
				]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;"-462344139" : "ALL CONFIGURATIONS" ;"348214829" : "ALL CONFIGURATIONS" ;"-1417738989" : "ALL CONFIGURATIONS" ;"-1447766567" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-1447766567" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _switch_off_ ]
				
				edge  -{
					test-set [ 
					"-671687929" 
					"348214829" 
					"-1417738989" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _throw_coins_in_ ]
				
			}
			
			Action _switch_off_  {
				test-set [ 
				"-1447766567" 
				]
				event-set [ "SwitchOff" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-1447766567" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-1447766567" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _machine_is_off_ ]
				
			}
			
			Action _throw_coins_in_  {
				
				data ["-671687929" - "0"] ["arg0" : "2"]
				data ["-1417738989" - "0"] ["arg0" : "3"]
				test-set [ 
				"-671687929" 
				"348214829" 
				"-1417738989" 
				]
				event-set [ "ThrowCoinsIn" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;"348214829" : "ALL CONFIGURATIONS" ;"-1417738989" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-671687929" 
					"348214829" 
					"-1417738989" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _order_product_ ]
				
			}
			
			Action _order_product_  {
				
				data ["348214829" - "0"] ["arg0" : "juice"]
				data ["-671687929" - "0"] ["arg0" : "water"]
				data ["-1417738989" - "0"] ["arg0" : "cola"]
				test-set [ 
				"-671687929" 
				"348214829" 
				"-1417738989" 
				]
				event-set [ "OrderProduct" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;"348214829" : "ALL CONFIGURATIONS" ;"-1417738989" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"348214829" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _out_of_order_ ]
				
				edge  -{
					test-set [ 
					"-671687929" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _get_product_ ]
				
				edge  -{
					test-set [ 
					"-1417738989" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _show_message_ ]
				
			}
			
			Action _out_of_order_  {
				test-set [ 
				"348214829" 
				]
				event-set [ "OutofOrder" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "348214829" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"348214829" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _return_money_ ]
				
			}
			
			Action _return_money_  {
				term
				test-set [ 
				"348214829" 
				]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "348214829" : "ALL CONFIGURATIONS" ;]
			}
			
			Action _get_product_  {
				
				data ["-671687929" - "0"] ["arg0" : "water"]
				test-set [ 
				"-671687929" 
				]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-671687929" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _update_inventory_info_of_product_ ]
				
			}
			
			Action _update_inventory_info_of_product_  {
				term
				
				data ["-671687929" - "0"] ["arg0" : "water"]
				data ["-1417738989" - "0"] ["arg0" : "cola"]
				test-set [ 
				"-671687929" 
				"-1417738989" 
				]
				event-set [ "UpdateInventoryInfoOfProduct" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-671687929" : "ALL CONFIGURATIONS" ;"-1417738989" : "ALL CONFIGURATIONS" ;]
			}
			
			Action _show_message_  {
				test-set [ 
				"-1417738989" 
				]
				event-set [ "ShowMessage" ]
				product-set [ "ALL CONFIGURATIONS" ]
				map [ "-1417738989" : "ALL CONFIGURATIONS" ;]
				edge  -{
					test-set [ 
					"-1417738989" 
					]
					product-set[ "ALL CONFIGURATIONS" ]
				} -> leads-to [ _update_inventory_info_of_product_ ]
				
			}
		}
		''')
		//TODO update test cases
		//(new GenerateCausalGraph).generateDiffCG(fsa, cg1, cg2, "demo", false, 0.5)
	}
	
	@Test
	def generateGraph(){
		val file = IFileSystemAccess::DEFAULT_OUTPUT +"..\\test-gen\\DiffCausalGraph\\demo\\diffGraph.scn"
		
		//assertTrue(fsa.textFiles.containsKey(file))
		//assertEquals(ExpectedGraph.diffGraphSimple.toString, fsa.textFiles.get(file).toString)
	}
}