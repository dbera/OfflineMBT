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
	public var dataImplToFilename = new HashMap<String, List<String>>
	public var stepVarNameToType = new HashMap<String, List<String>>
	public var dataVarToDataInstance = new HashMap<String, List<String>>
	public var sutVarToDataInstance = new HashMap<String, List<String>>
	public var sutInstanceToFile = new HashMap<String, List<String>>
	
	public var title = new String
	public var testpurpose = new String
	public var background = new String
	public var stakeholders = new ArrayList<String>
	public var steps = new ArrayList<Step>
	
}