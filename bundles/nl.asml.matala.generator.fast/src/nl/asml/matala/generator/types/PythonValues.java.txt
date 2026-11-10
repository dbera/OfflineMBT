/* Copyright (c) 2026 TNO-ESI
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.generator.types;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Safe literal emission. Metadata is data, never executable Python text. */
public final class PythonValues {
	private PythonValues() {

	}

	public static String quote(String text) {
		StringBuilder out = new StringBuilder("\"");
		for (char c : text.toCharArray()) {
			switch (c) {
			case '\\' -> out.append("\\\\");
			case '"' -> out.append("\\\"");
			case '\n' -> out.append("\\n");
			case '\r' -> out.append("\\r");
			case '\t' -> out.append("\\t");
			default -> {
				if (c < 32 || c == 0x2028 || c == 0x2029)
					out.append(String.format("\\u%04x", (int) c));
				else
					out.append(c);
			}
			}
		}
		return out.append('"').toString();
	}

	public static String literal(Object value) {
		if (value == null)
			return "None";
		if (value instanceof String s)
			return quote(s);
		if (value instanceof Boolean b)
			return b ? "True" : "False";
		if (value instanceof Number n) {
			if (!Double.isFinite(n.doubleValue()))
				throw new IllegalArgumentException("Non-finite number");
			return n.toString();
		}
		if (value instanceof List<?> list)
			return "[" + String.join(", ", list.stream().map(PythonValues::literal).toList()) + "]";
		if (value instanceof Map<?, ?> map) {
			List<String> pairs = new ArrayList<>();
			map.forEach((k, v) -> pairs.add(literal(k) + ": " + literal(v)));
			return "{" + String.join(", ", pairs) + "}";
		}
		throw new IllegalArgumentException("Unsupported metadata value: " + value.getClass().getName());
	}

	/** Strict JSON reader for structured annotation strings (no Python eval). */
	public static Object json(String text) {
		Reader reader = new Reader(text);
		Object result = reader.value();
		reader.ws();
		if (reader.pos != text.length())
			throw reader.error("Trailing JSON content");
		return result;
	}

	private static final class Reader {
		final String text;
		int pos;

		Reader(String text) {
			this.text = text;
		}

		IllegalArgumentException error(String message) {
			return new IllegalArgumentException(message + " at JSON offset " + pos);
		}

		void ws() {
			while (pos < text.length() && Character.isWhitespace(text.charAt(pos)))
				pos++;
		}

		boolean take(char c) {
			ws();
			if (pos < text.length() && text.charAt(pos) == c) {
				pos++;
				return true;
			}
			return false;
		}

		void expect(char c) {
			if (!take(c))
				throw error("Expected " + c);
		}

		Object value() {
			ws();
			if (pos == text.length())
				throw error("Missing JSON value");
			char c = text.charAt(pos);
			if (c == '"')
				return string();
			if (take('{')) {
				Map<String, Object> map = new LinkedHashMap<>();
				if (take('}'))
					return map;
				do {
					ws();
					if (pos == text.length() || text.charAt(pos) != '"')
						throw error("Expected string key");
					String key = string();
					expect(':');
					if (map.containsKey(key))
						throw error("Duplicate key " + key);
					map.put(key, value());
				} while (take(','));
				expect('}');
				return map;
			}
			if (take('[')) {
				List<Object> list = new ArrayList<>();
				if (take(']'))
					return list;
				do {
					list.add(value());
				} while (take(','));
				expect(']');
				return list;
			}
			for (String word : List.of("true", "false", "null")) {
				if (text.startsWith(word, pos)) {
					pos += word.length();
					return word.equals("null") ? null : word.equals("true");
				}
			}
			java.util.regex.Matcher m = java.util.regex.Pattern
					.compile("-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?").matcher(text.substring(pos));
			if (!m.lookingAt())
				throw error("Invalid JSON value");
			String number = m.group();
			pos += number.length();
			return new java.math.BigDecimal(number);
		}

		String string() {
			expect('"');
			StringBuilder out = new StringBuilder();
			while (pos < text.length()) {
				char c = text.charAt(pos++);
				if (c == '"')
					return out.toString();
				if (c < 32)
					throw error("Control character in string");
				if (c != '\\') {
					out.append(c);
					continue;
				}
				if (pos == text.length())
					throw error("Incomplete escape");
				char e = text.charAt(pos++);
				switch (e) {
				case '"', '\\', '/' -> out.append(e);
				case 'b' -> out.append('\b');
				case 'f' -> out.append('\f');
				case 'n' -> out.append('\n');
				case 'r' -> out.append('\r');
				case 't' -> out.append('\t');
				case 'u' -> {
					if (pos + 4 > text.length())
						throw error("Incomplete Unicode escape");
					try {
						out.append((char) Integer.parseInt(text.substring(pos, pos + 4), 16));
					} catch (NumberFormatException ex) {
						throw error("Invalid Unicode escape");
					}
					pos += 4;
				}
				default -> throw error("Invalid escape");
				}
			}
			throw error("Unterminated string");
		}
	}
}
