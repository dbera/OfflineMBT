/*
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
package nl.asml.matala.bpmn4s.bpmn4s;

import java.util.LinkedHashMap;
import java.util.Map;

public class EnumerationType extends Bpmn4sDataType {

	public Map<String, String> literals = new LinkedHashMap<String, String>();
	
	public EnumerationType (String name) {
		super(name, ENUM_TYPE);
	}
	
	public void addLiteral(String name, String value) {
		literals.put(name, value);
	}
}
