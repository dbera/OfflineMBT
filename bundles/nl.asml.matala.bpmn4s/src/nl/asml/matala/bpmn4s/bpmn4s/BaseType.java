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


public class BaseType extends Bpmn4sDataType {
	// Int, Bool, Float, String
	BaseType (String type) {
		super(type);
		String name = "";
		if (type.equals(Bpmn4sDataType.BOOL_TYPE)) {
			name = "Bool";
		} else if (type.equals(Bpmn4sDataType.INT_TYPE)) {
			name = "Int";
		} else if (type.equals(Bpmn4sDataType.STRING_TYPE)) {
			name = "String";
		} else if (type.equals(Bpmn4sDataType.FLOAT_TYPE)) {
			name = "Real";
		}
		setName(name);
	}
}
	
class Bpmn4s_Bool extends Bpmn4sDataType {
	Bpmn4s_Bool () {
		super(BOOL_TYPE);
	}
}

class Bpmn4s_Int extends Bpmn4sDataType {
	Bpmn4s_Int () {
		super(INT_TYPE);
	}
}

class Bpmn4s_Float extends Bpmn4sDataType {
	Bpmn4s_Float () {
		super(FLOAT_TYPE);
	}
}

