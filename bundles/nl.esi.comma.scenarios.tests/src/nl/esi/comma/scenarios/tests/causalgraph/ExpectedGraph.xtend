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

class ExpectedGraph {
	def static ISimpleWithoutDataTest() {'''
	action-list: {
		Given a1 "a1"
		When a2 "a2"
		And a3 "a3"
		Given a4 "a4"
		When a5 "a5"
		Then a6 "a6"
	}
	
	Causal-Graph SimpleWithoutData {
		
		Action a1  {
			init
			term
			test-set [ 
			"-1273492146" 
			"-1273492148" 
			]
			edge  -{
				test-set [ 
				"-1273492148" 
				]
			} -> leads-to [ a2 ]
			
		}
		
		Action a2  {
			test-set [ 
			"-1273492147" 
			"-1273492148" 
			]
			edge  -{
				test-set [ 
				"-1273492148" 
				]
			} -> leads-to [ a3 ]
			
			edge  -{
				test-set [ 
				"-1273492147" 
				]
			} -> leads-to [ a5 ]
			
		}
		
		Action a3  {
			term
			test-set [ 
			"-1273492147" 
			"-1273492148" 
			]
			edge  -{
				test-set [ 
				"-1273492148" 
				]
			} -> leads-to [ a1 ]
			
			edge  -{
				test-set [ 
				"-1273492147" 
				]
			} -> leads-to [ a2 ]
			
		}
		
		Action a4  {
			init
			test-set [ 
			"-1273492147" 
			]
			edge  -{
				test-set [ 
				"-1273492147" 
				]
			} -> leads-to [ a3 ]
			
		}
		
		Action a5  {
			init
			test-set [ 
			"-1273492146" 
			"-1273492147" 
			]
			edge  -{
				test-set [ 
				"-1273492146" 
				"-1273492147" 
				]
			} -> leads-to [ a6 ]
			
		}
		
		Action a6  {
			term
			test-set [ 
			"-1273492146" 
			"-1273492147" 
			]
			edge  -{
				test-set [ 
				"-1273492146" 
				]
			} -> leads-to [ a1 ]
			
		}
	}
	'''
	}
	
	def static ISimpleWithConfigTest() {'''
	action-list: {
		Given a1 "a1"
		When a2 "a2"
		And a3 "a3"
		Given a4 "a4"
		When a5 "a5"
		Then a6 "a6"
	}
	
	Causal-Graph SimpleWithConfig {
		
		Action a1  {
			init
			term
			test-set [ 
			"-1273492146" 
			"-1273492148" 
			]
			config [ "FeatureC" "FeatureA" ]
			product-set [ "configC" "configA" ]
			map [ "-1273492146" : "configC" ;"-1273492148" : "configC" "configA" ;]
			edge  -{
				test-set [ 
				"-1273492148" 
				]
				config [ "FeatureA" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ a2 ]
			
		}
		
		Action a2  {
			test-set [ 
			"-1273492147" 
			"-1273492148" 
			]
			config [ "FeatureB" "FeatureA" ]
			product-set [ "configB" "configC" "configA" ]
			map [ "-1273492147" : "configB" "configC" ;"-1273492148" : "configC" "configA" ;]
			edge  -{
				test-set [ 
				"-1273492148" 
				]
				config [ "FeatureA" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ a3 ]
			
			edge  -{
				test-set [ 
				"-1273492147" 
				]
				config [ "FeatureB" ]
				product-set[ "configB" "configC" ]
			} -> leads-to [ a5 ]
			
		}
		
		Action a3  {
			term
			test-set [ 
			"-1273492147" 
			"-1273492148" 
			]
			config [ "FeatureB" "FeatureA" ]
			product-set [ "configB" "configC" "configA" ]
			map [ "-1273492147" : "configB" "configC" ;"-1273492148" : "configC" "configA" ;]
			edge  -{
				test-set [ 
				"-1273492148" 
				]
				config [ "FeatureA" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ a1 ]
			
			edge  -{
				test-set [ 
				"-1273492147" 
				]
				config [ "FeatureB" ]
				product-set[ "configB" "configC" ]
			} -> leads-to [ a2 ]
			
		}
		
		Action a4  {
			init
			test-set [ 
			"-1273492147" 
			]
			config [ "FeatureB" ]
			product-set [ "configB" "configC" ]
			map [ "-1273492147" : "configB" "configC" ;]
			edge  -{
				test-set [ 
				"-1273492147" 
				]
				config [ "FeatureB" ]
				product-set[ "configB" "configC" ]
			} -> leads-to [ a3 ]
			
		}
		
		Action a5  {
			init
			test-set [ 
			"-1273492146" 
			"-1273492147" 
			]
			config [ "FeatureC" "FeatureB" ]
			product-set [ "configB" "configC" ]
			map [ "-1273492146" : "configC" ;"-1273492147" : "configB" "configC" ;]
			edge  -{
				test-set [ 
				"-1273492146" 
				"-1273492147" 
				]
				config [ "FeatureC" "FeatureB" ]
				product-set[ "configB" "configC" ]
			} -> leads-to [ a6 ]
			
		}
		
		Action a6  {
			term
			test-set [ 
			"-1273492146" 
			"-1273492147" 
			]
			config [ "FeatureC" "FeatureB" ]
			product-set [ "configB" "configC" ]
			map [ "-1273492146" : "configC" ;"-1273492147" : "configB" "configC" ;]
			edge  -{
				test-set [ 
				"-1273492146" 
				]
				config [ "FeatureC" ]
				product-set[ "configC" ]
			} -> leads-to [ a1 ]
			
		}
	}
	'''
	}
	
	def static IWithEventSet(){'''
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
	
	Causal-Graph WithEventSet {
		
		Action _machine_is_off_  {
			init
			term
			test-set [ 
			"-462344139" 
			"-1447766567" 
			]
			config [ "FeatureC" ]
			product-set [ "configC" "configA" ]
			map [ "-462344139" : "configC" "configA" ;"-1447766567" : "configC" "configA" ;]
			edge  -{
				test-set [ 
				"-462344139" 
				]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _switch_on_ ]
			
		}
		
		Action _switch_on_  {
			test-set [ 
			"-462344139" 
			]
			event-set [ "SwitchOn" ]
			config [ "FeatureC" ]
			product-set [ "configC" "configA" ]
			map [ "-462344139" : "configC" "configA" ;]
			edge  -{
				test-set [ 
				"-462344139" 
				]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _check_inventory_ ]
			
		}
		
		Action _check_inventory_  {
			test-set [ 
			"-462344139" 
			]
			event-set [ "CheckInventory" ]
			config [ "FeatureC" ]
			product-set [ "configC" "configA" ]
			map [ "-462344139" : "configC" "configA" ;]
			edge  -{
				test-set [ 
				"-462344139" 
				]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
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
			config [ "FeatureC" "FeatureB" "FeatureA" ]
			product-set [ "configB" "configC" "configA" ]
			map [ "-671687929" : "configB" ;"-462344139" : "configC" "configA" ;"348214829" : "configA" ;"-1417738989" : "configB" ;"-1447766567" : "configC" "configA" ;]
			edge  -{
				test-set [ 
				"-1447766567" 
				]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _switch_off_ ]
			
			edge  -{
				test-set [ 
				"-671687929" 
				"348214829" 
				"-1417738989" 
				]
				config [ "FeatureB" "FeatureA" ]
				product-set[ "configB" "configA" ]
			} -> leads-to [ _throw_coins_in_ ]
			
		}
		
		Action _switch_off_  {
			test-set [ 
			"-1447766567" 
			]
			event-set [ "SwitchOff" ]
			config [ "FeatureC" ]
			product-set [ "configC" "configA" ]
			map [ "-1447766567" : "configC" "configA" ;]
			edge  -{
				test-set [ 
				"-1447766567" 
				]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _machine_is_off_ ]
			
		}
		
		Action _throw_coins_in_  {
			
			data ["348214829" - "0"] ["arg0" : "3"]
			data ["-671687929" - "0"] ["arg0" : "2"]
			data ["-671687929" - "1"] ["arg0" : "3"]
			data ["-1417738989" - "0"] ["arg0" : "2"]
			test-set [ 
			"-671687929" 
			"348214829" 
			"-1417738989" 
			]
			event-set [ "ThrowCoinsIn" ]
			config [ "FeatureB" "FeatureA" ]
			product-set [ "configB" "configA" ]
			map [ "-671687929" : "configB" ;"348214829" : "configA" ;"-1417738989" : "configB" ;]
			edge  -{
				test-set [ 
				"-671687929" 
				"348214829" 
				"-1417738989" 
				]
				config [ "FeatureB" "FeatureA" ]
				product-set[ "configB" "configA" ]
			} -> leads-to [ _order_product_ ]
			
		}
		
		Action _order_product_  {
			
			data ["348214829" - "0"] ["arg0" : "cola"]
			data ["-671687929" - "0"] ["arg0" : "water"]
			data ["-671687929" - "1"] ["arg0" : "cola"]
			data ["-1417738989" - "0"] ["arg0" : "cola"]
			test-set [ 
			"-671687929" 
			"348214829" 
			"-1417738989" 
			]
			event-set [ "OrderProduct" ]
			config [ "FeatureB" "FeatureA" ]
			product-set [ "configB" "configA" ]
			map [ "-671687929" : "configB" ;"348214829" : "configA" ;"-1417738989" : "configB" ;]
			edge  -{
				test-set [ 
				"348214829" 
				]
				config [ "FeatureA" ]
				product-set[ "configA" ]
			} -> leads-to [ _out_of_order_ ]
			
			edge  -{
				test-set [ 
				"-671687929" 
				]
				config [ "FeatureB" ]
				product-set[ "configB" ]
			} -> leads-to [ _get_product_ ]
			
			edge  -{
				test-set [ 
				"-1417738989" 
				]
				config [ "FeatureB" ]
				product-set[ "configB" ]
			} -> leads-to [ _show_message_ ]
			
		}
		
		Action _out_of_order_  {
			test-set [ 
			"348214829" 
			]
			event-set [ "OutofOrder" ]
			config [ "FeatureA" ]
			product-set [ "configA" ]
			map [ "348214829" : "configA" ;]
			edge  -{
				test-set [ 
				"348214829" 
				]
				config [ "FeatureA" ]
				product-set[ "configA" ]
			} -> leads-to [ _return_money_ ]
			
		}
		
		Action _return_money_  {
			term
			test-set [ 
			"348214829" 
			]
			config [ "FeatureA" ]
			product-set [ "configA" ]
			map [ "348214829" : "configA" ;]
		}
		
		Action _get_product_  {
			
			data ["-671687929" - "0"] ["arg0" : "water"]
			data ["-671687929" - "1"] ["arg0" : "cola"]
			test-set [ 
			"-671687929" 
			]
			config [ "FeatureB" ]
			product-set [ "configB" ]
			map [ "-671687929" : "configB" ;]
			edge  -{
				test-set [ 
				"-671687929" 
				]
				config [ "FeatureB" ]
				product-set[ "configB" ]
			} -> leads-to [ _update_inventory_info_of_product_ ]
			
		}
		
		Action _update_inventory_info_of_product_  {
			term
			
			data ["-671687929" - "0"] ["arg0" : "water"]
			data ["-671687929" - "1"] ["arg0" : "cola"]
			test-set [ 
			"-671687929" 
			]
			event-set [ "UpdateInventoryInfoOfProduct" ]
			config [ "FeatureB" ]
			product-set [ "configB" ]
			map [ "-671687929" : "configB" ;]
			edge  -{
				test-set [ 
				"-671687929" 
				]
				config [ "FeatureB" ]
				product-set[ "configB" ]
			} -> leads-to [ _throw_coins_in_ ]
			
		}
		
		Action _show_message_  {
			term
			test-set [ 
			"-1417738989" 
			]
			event-set [ "ShowMessage" ]
			config [ "FeatureB" ]
			product-set [ "configB" ]
			map [ "-1417738989" : "configB" ;]
		}
	}
	'''
	}
	
	def static diffGraphSimple(){'''
	action-list: {
		 _machine_is_off_ "_machine_is_off_"
		 _switch_on_ "_switch_on_"
		 _check_inventory_ "_check_inventory_"
		 _machine_is_on_ "_machine_is_on_"
		 _switch_off_ "_switch_off_"
		 _throw_coins_in_ "_throw_coins_in_"
		 _order_product_ "_order_product_"
		 _out_of_order_ "_out_of_order_"
		 _return_money_ "_return_money_"
		 _get_product_ "_get_product_"
		 _update_inventory_info_of_product_ "_update_inventory_info_of_product_"
		 _show_message_ "_show_message_"
		 dummy "dummy"
		 _show_message_new_ "_show_message_new_"
	}
	
	Causal-Graph diffCG {
		
		Action _machine_is_off_ [ node_updated ] {
			init
			test-set [ "s0" "s1" ]
			config [ "FeatureC" ]
			product-set [ "configC" "configA" ]
			
			edge  -{
				test-set [ "s0" ]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _switch_on_ ]
			
		}
		
		Action _switch_on_  {
			test-set [ "s0" ]
			event-set [ "SwitchOn" ]
			config [ "FeatureC" ]
			product-set [ "configC" "configA" ]
			
			edge [edge_updated] -{
				test-set [ "s0" ]
				config [ "FeatureC" "FeatureA" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _check_inventory_ ]
			
			edge [edge_added] -{
				test-set [ "s1" ]
			} -> leads-to [ _order_product_ ]
			
		}
		
		Action _check_inventory_  {
			test-set [ "s0" ]
			event-set [ "CheckInventory" ]
			config [ "FeatureC" ]
			product-set [ "configC" "configA" ]
			
			edge  -{
				test-set [ "s0" ]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _machine_is_on_ ]
			
		}
		
		Action _machine_is_on_  {
			init
			term
			test-set [ "s3" "s4" "s0" "s1" "s2" ]
			config [ "FeatureC" "FeatureB" "FeatureA" ]
			product-set [ "configB" "configC" "configA" ]
			
			edge  -{
				test-set [ "s1" ]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _switch_off_ ]
			
			edge  -{
				test-set [ "s3" "s4" "s2" ]
				config [ "FeatureB" "FeatureA" ]
				product-set[ "configB" "configA" ]
			} -> leads-to [ _throw_coins_in_ ]
			
		}
		
		Action _switch_off_ [ data_added ] {
			
			data ["s1" - "0"] ["arg0" : "20"]
			test-set [ "s1" ]
			event-set [ "SwitchOff" ]
			config [ "FeatureC" ]
			product-set [ "configC" "configA" ]
			
			edge  -{
				test-set [ "s1" ]
				config [ "FeatureC" ]
				product-set[ "configC" "configA" ]
			} -> leads-to [ _machine_is_off_ ]
			
		}
		
		Action _throw_coins_in_ [ data_updated data_deleted ] {
			
			data ["s2" - "0"] ["arg0" : "3"]
			data ["s3" - "0"] ["arg0" : "1"]
			data ["s4" - "0"] ["arg0" : "2"]
			test-set [ "s3" "s4" "s2" ]
			event-set [ "ThrowCoinsIn" ]
			config [ "FeatureB" "FeatureA" ]
			product-set [ "configB" "configA" ]
			
			edge  -{
				test-set [ "s3" "s4" "s2" ]
				config [ "FeatureB" "FeatureA" ]
				product-set[ "configB" "configA" ]
			} -> leads-to [ _order_product_ ]
			
		}
		
		Action _order_product_ [ data_updated ] {
			
			data ["s2" - "0"] ["arg0" : "cola"]
			data ["s3" - "0"] ["arg0" : "water"]
			data ["s3" - "1"] ["arg0" : "cola"]
			data ["s4" - "0"] ["arg0" : "water"]
			test-set [ "s3" "s4" "s2" ]
			event-set [ "OrderProduct" ]
			config [ "FeatureB" "FeatureA" ]
			product-set [ "configB" "configA" ]
			
			edge  -{
				test-set [ "s2" ]
				config [ "FeatureA" ]
				product-set[ "configA" ]
			} -> leads-to [ _out_of_order_ ]
			
			edge  -{
				test-set [ "s3" ]
				config [ "FeatureB" ]
				product-set[ "configB" ]
			} -> leads-to [ _get_product_ ]
			
			edge [edge_deleted] -{
				test-set [ "s4" ]
				config [ "FeatureB" ]
				product-set[ "configB" ]
			} -> leads-to [ _show_message_ ]
			
		}
		
		Action _out_of_order_  {
			test-set [ "s2" ]
			event-set [ "OutofOrder" ]
			config [ "FeatureA" ]
			product-set [ "configA" ]
			
			edge  -{
				test-set [ "s2" ]
				config [ "FeatureA" ]
				product-set[ "configA" ]
			} -> leads-to [ _return_money_ ]
			
		}
		
		Action _return_money_  {
			term
			test-set [ "s2" ]
			config [ "FeatureA" ]
			product-set [ "configA" ]
			
		}
		
		Action _get_product_  {
			
			data ["s3" - "0"] ["arg0" : "water"]
			data ["s3" - "1"] ["arg0" : "cola"]
			test-set [ "s3" ]
			config [ "FeatureB" ]
			product-set [ "configB" ]
			
			edge  -{
				test-set [ "s3" ]
				config [ "FeatureB" ]
				product-set[ "configB" ]
			} -> leads-to [ _update_inventory_info_of_product_ ]
			
		}
		
		Action _update_inventory_info_of_product_  {
			term
			
			data ["s3" - "0"] ["arg0" : "water"]
			data ["s3" - "1"] ["arg0" : "cola"]
			test-set [ "s3" ]
			event-set [ "UpdateInventoryInfoOfProduct" ]
			config [ "FeatureB" ]
			product-set [ "configB" ]
			
			edge  -{
				test-set [ "s3" ]
				config [ "FeatureB" ]
				product-set[ "configB" ]
			} -> leads-to [ _throw_coins_in_ ]
			
		}
		
		Action _show_message_  {
			term
			test-set [ "s4" ]
			event-set [ "ShowMessage" ]
			config [ "FeatureB" ]
			product-set [ "configB" ]
			
		}
		
		Action dummy [ node_deleted ] {
			term
			
		}
		
		Action _show_message_new_ [ node_added ] {
			init
			
		}
	}
	'''	
	}
}