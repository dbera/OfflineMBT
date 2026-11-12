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
public record Schema(List<Declaration> declarations) {

	public Schema {
		declarations = List.copyOf(declarations);
	}
}