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
package nl.esi.comma.scenarios.generator.causalgraph

import java.util.HashSet
import java.util.List

class Edge {
	String src
	String dst
	HashSet<String> scnIDs
	public HashSet<String> configs = new HashSet<String>
	public HashSet<String> productSet = new HashSet<String>
	public String changeType
	
	new (String src, String dst) {
		this.src = src
		this.dst = dst
		this.scnIDs = new HashSet<String>
		this.changeType = ""
	}
	
	def getSrc(){
		return src
	}
	
	def getDst(){
		return dst
	}
	
	def getScnIDs(){
		return scnIDs
	}
	
	def addScnID(String id){
		scnIDs.add(id)
	}
	
	def addConfig(List<String> config) {
		this.configs.addAll(config)
	}
	
	def addProductSet(List<String> prodSet) {
		this.productSet.addAll(prodSet)
	}
	
	def setChangeType(String type){
		this.changeType = type
	}
	
	def isMatch(Edge e) {
	    if(src.equals(e.src) && dst.equals(e.dst)) return true
	    else return false
	}
}