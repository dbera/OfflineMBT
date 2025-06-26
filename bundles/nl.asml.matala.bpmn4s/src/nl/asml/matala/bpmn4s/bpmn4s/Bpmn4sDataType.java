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

public abstract class Bpmn4sDataType {
	
	public static final String ENUM_TYPE = "Enumeration";
	public static final String CONTEXT_TYPE = "Context";
	public static final String RECORD_TYPE = "Record";
	public static final String LIST_TYPE = "List";
	public static final String SET_TYPE = "Set";
	public static final String MAP_TYPE = "Map";
	public static final String STRING_TYPE = "String";
	public static final String INT_TYPE = "Int";
	public static final String BOOLEAN_TYPE = "Boolean";
	public static final String FLOAT_TYPE = "Float";
	
	private final String name;
	private final String type;
	
	public Bpmn4sDataType(String _name, String _type) {
		name = _name;
		type = _type;
	}
	
	public String getName() {
		return name;
	}
	
	public String getType() {
		return type;
	}
}
