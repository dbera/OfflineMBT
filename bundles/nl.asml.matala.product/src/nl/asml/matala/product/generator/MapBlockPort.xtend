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
package nl.asml.matala.product.generator

class MapBlockPort {
	public var in 	= new BlockPort
	public var out = new BlockPort
	
	new (BlockPort bin, BlockPort bout) {
		in = new BlockPort(bin.block_name, bin.var_name)
		out = new BlockPort(bout.block_name, bout.var_name)
	}
	
	def display() {
		System.out.println(" > in: " + in.display())
		System.out.println(" > out: " + out.display())
	}
}

class BlockPort {
	public var block_name 	= new String
	public var var_name 	= new String
	
	new() {}
	
	new (String bname, String vname) {
		block_name = bname
		var_name = vname
	}
	
	def display() {
		return " block name: " + block_name + " ; " + " var name: " + var_name 
	}
}