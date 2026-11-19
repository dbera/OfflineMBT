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
package nl.asml.matala.generator.types;

import java.util.List;
import java.util.Map;

/** Small immutable boundary between the Xtext adapter and Python emission. */
public class Declaration {
	public String name;
	public String base;
	public List<String> literals;
	public List<Field> fields;
	public Map<String, Object> metadata;

	public Declaration(String name, String base, List<String> literals, List<Field> fields,
			Map<String, Object> metadata) {
		this.name = name;
		this.base = base;
		this.literals = List.copyOf(literals);
		this.fields = List.copyOf(fields);
		this.metadata = java.util.Collections.unmodifiableMap(new java.util.LinkedHashMap<>(metadata));
	}
}
