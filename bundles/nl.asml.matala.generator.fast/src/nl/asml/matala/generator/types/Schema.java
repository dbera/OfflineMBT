/* Copyright (c) 2026 TNO-ESI
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
	public record Declaration(String name, String base, List<String> literals, List<Field> fields,
			Map<String, Object> metadata) {
		public Declaration {
			literals = List.copyOf(literals);
			fields = List.copyOf(fields);
			metadata = java.util.Collections.unmodifiableMap(new java.util.LinkedHashMap<>(metadata));
		}
	}

	public record Field(String name, String type, String helper, Map<String, Object> metadata) {
		public Field {
			metadata = java.util.Collections.unmodifiableMap(new java.util.LinkedHashMap<>(metadata));
		}
	}
}
