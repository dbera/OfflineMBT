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

public class ListType extends Bpmn4sDataType{
	
	String valueType;

	public ListType (String _name, String vtype) {
		super(_name, LIST_TYPE);
		valueType = vtype;
	}
}
