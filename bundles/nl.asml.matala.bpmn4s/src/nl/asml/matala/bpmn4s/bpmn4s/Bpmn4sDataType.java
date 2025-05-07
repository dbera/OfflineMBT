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

public class Bpmn4sDataType {
	
	static final String RECORD_TYPE = "record";
	static final String MAP_TYPE = "map";
	static final String LIST_TYPE = "list";
	static final String ENUM_TYPE = "enum";
	static final String BOOL_TYPE = "boolean";
	static final String INT_TYPE = "int";
	static final String STRING_TYPE = "string";
	static final String FLOAT_TYPE = "float";
	static final String NO_TYPE = "notype";
	
	String name = new String();
	String type = new String();
	
	public Bpmn4sDataType(String _name, String _type) {
		name = _name;
		type = _type;
	}
	
	public Bpmn4sDataType(String _type) {
		type = _type;
	}
	
	public Bpmn4sDataType() {
		type = NO_TYPE;
	}
	
	public void setName(String _name) {
		name = _name;
	}
	
	public String getName() {
		return name;
	}
	
	public void setType(String t) {
		type = t;
	}
	
	public String getType() {
		return type;
	}

}
