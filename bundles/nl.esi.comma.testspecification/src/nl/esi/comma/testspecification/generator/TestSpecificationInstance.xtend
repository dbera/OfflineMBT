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
package nl.esi.comma.testspecification.generator

import java.util.HashMap
import java.util.ArrayList
import java.util.List
import nl.esi.comma.testspecification.generator.utils.Step
import nl.esi.comma.testspecification.generator.utils.KeyValue

class TestSpecificationInstance 
{
	public var mapLocalDataVarToDataInstance = new HashMap<String, List<String>>
	public var mapLocalStepInstance = new HashMap<String, List<String>>
	public var mapLocalSUTVarToDataInstance = new HashMap<String, List<String>>
	public var mapDataInstanceToFile = new HashMap<String, List<String>>
	public var mapSUTInstanceToFile = new HashMap<String, List<String>>
	public var listStepInstances = new ArrayList<Step>
	
	public var title = new String
	public var testpurpose = new String
	public var background = new String
	public var stakeholders = new ArrayList<String>
	
	new() {}
	
	def addMapDataInstanceToFile(String key, String value) {
		if(mapDataInstanceToFile.containsKey(key)) 
			mapDataInstanceToFile.get(key).add(value)
		else { 
			mapDataInstanceToFile.put(key, new ArrayList)
			mapDataInstanceToFile.get(key).add(value)	
		}
	}
	
	def addMapLocalSUTVarToDataInstance(String key, String value) {
		if(mapLocalSUTVarToDataInstance.containsKey(key)) 
			mapLocalSUTVarToDataInstance.get(key).add(value)
		else { 
			mapLocalSUTVarToDataInstance.put(key, new ArrayList)
			mapLocalSUTVarToDataInstance.get(key).add(value)
		}
	}
	
	def addMapLocalStepInstance(String key, String value) {
		if(mapLocalStepInstance.containsKey(key)) 
			mapLocalStepInstance.get(key).add(value)
		else {
			mapLocalStepInstance.put(key, new ArrayList)
			mapLocalStepInstance.get(key).add(value)
		}
	}
	
	def addMapLocalDataVarToDataInstance(String key, String value) {
		if(mapLocalDataVarToDataInstance.containsKey(key)) 
			mapLocalDataVarToDataInstance.get(key).add(value)
		else { 
			mapLocalDataVarToDataInstance.put(key, new ArrayList)
			mapLocalDataVarToDataInstance.get(key).add(value)
		}
	}
	
	def getExtensions(String varName) {
		var mapListOfKeyValue = new HashMap<String,List<KeyValue>>
		for(step : listStepInstances) {
			if(step.variableName.equals(varName)) {
				mapListOfKeyValue.put(step.id,step.parameters)
			}
		}
		return mapListOfKeyValue
	}
}