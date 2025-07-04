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
package nl.esi.comma.testspecification.generator.utils

import java.util.ArrayList
import java.util.List
import java.util.HashSet

class Step {
	public var String id = new String
	public var String type = new String
	public var String inputFile = new String
	public var List<KeyValue> parameters = new ArrayList<KeyValue>
	public var String variableName = new String
	public var String recordExp = new String
	public var List<Step> stepRefs = new ArrayList<Step>()
	
	
	def getId() { return id }
	def getType() { return type }
	def getInputFile() { return inputFile }
	def getParameters() { return parameters }
	def getVariableName() { return variableName }
	def getRecordExp() { return recordExp }
	def getStepRefs() { return stepRefs }
	
	def getStepRefs(String _id) {
		for(sref : stepRefs) {
			if(sref.getId.equals(_id)) return sref
		}
		return null
	}
	
	def isStepRefPresent(String _id) {
		if(stepRefs.empty) return false
		for(sref : stepRefs) {
			if(sref.getId.equals(_id)) return true
			else return false
		}
	}
	
	def void display() {
		System.out.println("********** STEP: " + id + " **********")
		System.out.println("	> type: " + type)
		System.out.println("	> input-file: " + inputFile)
		System.out.println("	> var-name: " + variableName)
		System.out.println("	> var-value: " + recordExp)
		for(p : parameters) { p.display }
		for(s : stepRefs) { 
			System.out.println("******** REF-STEP *******")
			s.display
		}
	}
	
//	def isParamPresent(KeyValue kv, List<KeyValue> kvList) {
//		for(_kv : kvList) {
//			if(_kv.key.equals(kv.key) && _kv.value.equals(kv.value)) {
//				return true
//			}
//		}
//		return false
//	}
//	
//	def getUniqueParameters() {
//		var uniqueParamsList = new ArrayList<KeyValue>
//		for(kv : parameters) {
//			if(!isParamPresent(kv, uniqueParamsList)) {
//				uniqueParamsList.add(kv)
//			}
//		}
//		return uniqueParamsList
//	}
}


class KeyValue {
	public var key = new String
	public var value = new String
	public var refKey = new HashSet<String>
	public var refVal = new HashSet<String>
	
	def getKey() { return key }
	def getValue() { return value }
	def getRefKey() { return refKey }
	def getRefVal() { return refVal }
	
	def display() {
		System.out.println("	Key: " + key + "	Value: " + value )
		for(rk : refKey) System.out.println("	RefKey: " + rk )
		for(rv : refVal) System.out.println("	RefVal: " + rv )
	}
}

class JSONData {
	public var kvList = new ArrayList<KeyValue>
	def getKvList() { return kvList }
	def display() {
		for(elm : kvList)
			System.out.println(" JSON Key: " + elm.key + " -> value: " + elm.value )
	}
}