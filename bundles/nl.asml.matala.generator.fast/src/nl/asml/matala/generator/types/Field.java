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

import java.util.Map;

public record Field(String name, String type, String helper, Map<String, Object> metadata) {
	public Field {
		metadata = java.util.Collections.unmodifiableMap(new java.util.LinkedHashMap<>(metadata));
	}
}
