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

import java.util.ArrayList;
import java.util.List;

public class RecordType extends Bpmn4sDataType {

	public List<RecordField> fields = new ArrayList<RecordField>();
	private final boolean isContext;

	public RecordType(String _name, boolean _isContext) {
		super(_name, RECORD_TYPE);
		this.isContext = _isContext;
	}
	
	boolean isContext() {
		return isContext;
	}

	public void addField(String _key, String _type, RecordFieldKind _kind, boolean _suppress) {
		fields.add(new RecordField(_key, _type, _kind, _suppress));
	}
}