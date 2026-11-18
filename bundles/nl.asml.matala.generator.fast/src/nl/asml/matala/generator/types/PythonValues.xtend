/**
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
package nl.asml.matala.generator.types

import java.math.BigDecimal
import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import java.util.regex.Pattern

/** Safe literal emission. Metadata is data, never executable Python text. */
final class PythonValues {
    private new() {}

    def static String quote(String text) {
        '''"«FOR c : text.toCharArray()»«escape(c)»«ENDFOR»"'''.toString
    }

    def private static String escape(char c) {
        switch (c as int) {
            case 92: "\\\\"
            case 34: "\\\""
            case 10: "\\n"
            case 13: "\\r"
            case 9: "\\t"
            default: {
                if (c < 32 || c == 0x2028 || c == 0x2029)
                    String.format("\\u%04x", c as int)
                else String.valueOf(c)
            }
        }
    }

    def static String literal(Object value) {
        if (value === null) return "None"
        switch value {
            String: quote(value)
            Boolean: if (value.booleanValue()) "True" else "False"
            Number: {
                if (!Double.isFinite(value.doubleValue()))
                    throw new IllegalArgumentException("Non-finite number")
                value.toString()
            }
            List<?>: '''[ «FOR item : value SEPARATOR ', '» «literal(item)» «ENDFOR» ]'''.toString
            Map<?, ?>: '''{ «FOR key : value.keySet() SEPARATOR ', '» «literal(key)»: «literal(value.get(key))» «ENDFOR» }'''.toString
            default: throw new IllegalArgumentException("Unsupported metadata value: " + value.class.name)
        }
    }

    /** Strict JSON reader for structured annotation strings (no Python eval). */
    def static Object json(String text) {
        val reader = new Reader(text)
        val result = reader.value()
        reader.ws()
        if (!reader.atEnd()) throw reader.error("Trailing JSON content")
        result
    }

    /** Parsing stays procedural; Python output above uses rich-string templates. */
    private static class Reader {
        val String text
        var int pos = 0

        new(String text) { this.text = text }

        def boolean atEnd() { pos == text.length() }

        def IllegalArgumentException error(String message) {
            new IllegalArgumentException(message + " at JSON offset " + pos)
        }

        def void ws() {
            while (pos < text.length() && Character.isWhitespace(text.charAt(pos))) pos++
        }

        // Integer character codes avoid ambiguity between Xtend strings and Java chars.
        def boolean take(int c) {
            ws()
            if (pos < text.length() && text.charAt(pos) == c) {
                pos++
                return true
            }
            false
        }

        def void expect(int c) {
            if (!take(c)) throw error("Expected " + String.valueOf(c as char))
        }

        def Object value() {
            ws()
            if (atEnd()) throw error("Missing JSON value")
            if (text.charAt(pos) == 34) return string()
            if (take(123)) {
                val map = new LinkedHashMap<String, Object>()
                if (take(125)) return map
                var boolean more = true
                while (more) {
                    ws()
                    if (atEnd() || text.charAt(pos) != 34) throw error("Expected string key")
                    val key = string()
                    expect(58)
                    if (map.containsKey(key)) throw error("Duplicate key " + key)
                    map.put(key, value())
                    more = take(44)
                }
                expect(125)
                return map
            }
            if (take(91)) {
                val list = new ArrayList<Object>()
                if (take(93)) return list
                var boolean more = true
                while (more) {
                    list.add(value())
                    more = take(44)
                }
                expect(93)
                return list
            }
            for (word : List.of("true", "false", "null")) {
                if (text.startsWith(word, pos)) {
                    pos += word.length()
                    if (word == "null") return null
                    return Boolean.valueOf(word == "true")
                }
            }
            val matcher = Pattern.compile("-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?").matcher(text.substring(pos))
            if (!matcher.lookingAt()) throw error("Invalid JSON value")
            val number = matcher.group()
            pos += number.length()
            new BigDecimal(number)
        }

        def String string() {
            expect(34)
            val parts = new ArrayList<String>()
            while (pos < text.length()) {
                val c = text.charAt(pos)
                pos++
                if (c == 34) return parts.join("")
                if (c < 32) throw error("Control character in string")
                if (c != 92) {
                    parts.add(String.valueOf(c))
                } else {
                    if (atEnd()) throw error("Incomplete escape")
                    val e = text.charAt(pos)
                    pos++
                    switch (e as int) {
                        case 34: parts.add(String.valueOf(e))
                        case 92: parts.add(String.valueOf(e))
                        case 47: parts.add(String.valueOf(e))
                        case 98: parts.add("\b")
                        case 102: parts.add("\f")
                        case 110: parts.add("\n")
                        case 114: parts.add("\r")
                        case 116: parts.add("\t")
                        case 117: {
                            if (pos + 4 > text.length()) throw error("Incomplete Unicode escape")
                            try {
                                parts.add(String.valueOf(Integer.parseInt(text.substring(pos, pos + 4), 16) as char))
                            } catch (NumberFormatException ex) {
                                throw error("Invalid Unicode escape")
                            }
                            pos += 4
                        }
                        default: throw error("Invalid escape")
                    }
                }
            }
            throw error("Unterminated string")
        }
    }
}
