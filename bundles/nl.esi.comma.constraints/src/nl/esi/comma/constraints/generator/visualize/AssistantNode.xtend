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
package nl.esi.comma.constraints.generator.visualize

import java.util.ArrayList

class AssistantNode {
	String label
	boolean init
	boolean end
	ArrayList<String> missingConstr
	//edges incoming, outgoing, inout(PF)
	
	
	new(String label){
		this.label = label
		this.init = false
		this.end = false
		this.missingConstr = new ArrayList<String>
	}
	
	def addMissingConstr(String constraints){
		missingConstr.add(constraints)
	}
	
	def getMissingConstr(){
		return missingConstr
	}
	
	def getLabel(){
		return label
	}
	
	def setLabel(String l){
		label = l
	}
	
	def setInit(boolean init){
		this.init = init
	}
	
	def getInit(){
		return this.init
	}
	
	def setEnd(boolean end){
		this.end = end
	}
	
	def getEnd(){
		return this.end
	}
}