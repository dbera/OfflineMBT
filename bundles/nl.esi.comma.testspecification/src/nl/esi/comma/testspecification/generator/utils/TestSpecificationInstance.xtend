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

import java.util.LinkedHashMap
import java.util.ArrayList
import java.util.List
import nl.esi.comma.testspecification.generator.utils.Step

class TestSpecificationInstance 
{
	public var dataImplToFilename = new LinkedHashMap<String, List<String>>
	public var stepVarNameToType = new LinkedHashMap<String, List<String>>
	public var dataVarToDataInstance = new LinkedHashMap<String, List<String>>
	public var sutVarToDataInstance = new LinkedHashMap<String, List<String>>
	public var sutInstanceToFile = new LinkedHashMap<String, List<String>>
	public var sutDefinitionsVFDXML = new LinkedHashMap<String, List<String>>
	
	public var title = new String
	public var testpurpose = new String
	public var background = new String
	public var stakeholders = new ArrayList<String>
	public var steps = new ArrayList<Step>
	public var filePath = new String
	public var indatasuts= new ArrayList<Step>
	
}
