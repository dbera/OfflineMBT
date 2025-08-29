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

class TestSpecificationInstance 
{
	public var mapLocalDataVarToDataInstance = new HashMap<String, List<String>>
	public var mapLocalStepInstance = new HashMap<String, List<String>>
	public var mapLocalSUTVarToDataInstance = new HashMap<String, List<String>>
	public var mapDataInstanceToFile = new HashMap<String, List<String>>
	public var mapSUTInstanceToFile = new HashMap<String, List<String>>
	public var listStepInstances = new ArrayList<Step>
	public var listSutSetup = new ArrayList<Step>
	
	public var title = new String
	public var testpurpose = new String
	public var background = new String
	public var stakeholders = new ArrayList<String>
	
}