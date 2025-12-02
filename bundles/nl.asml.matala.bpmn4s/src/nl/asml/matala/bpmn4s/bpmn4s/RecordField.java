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

public class RecordField {
	private final String name;
	private final String type;
	private final RecordFieldKind kind;
	private final boolean suppressed;

	public RecordField(String name, String type, RecordFieldKind kind, boolean suppressed) {
		this.name = name;
		this.type = type;
		this.kind = kind;
		this.suppressed = suppressed;
	}

	public String getName() {
		return name;
	}

	public String getType() {
		return type;
	}

	public RecordFieldKind getKind() {
		return kind;
	}

	public boolean isSuppressed() {
		return suppressed;
	}
}
