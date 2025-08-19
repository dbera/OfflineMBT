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

import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

public class RecordType extends Bpmn4sDataType {

	public Map<String, String> fields = new LinkedHashMap<String, String>();
	private Set<String> symbolicFields = new HashSet<String>();
	private Set<String> suppressedFields = new HashSet<String>();

	public RecordType (String _name) {
		super(_name, RECORD_TYPE);
	}

	public void addField(String _key, String _type, boolean _symbolic, boolean _suppress) {
		fields.put(_key, _type);
		if (_symbolic) {
			symbolicFields.add(_key);
		}
		if (_suppress) {
			suppressedFields.add(_key);
		}
	}

	public boolean isSymbolic(String _field) {
		return symbolicFields.contains(_field);
	}

	public boolean isSuppressed(String _field) {
		return suppressedFields.contains(_field);
	}
}