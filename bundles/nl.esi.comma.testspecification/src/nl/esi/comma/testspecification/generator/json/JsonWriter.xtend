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
 
package nl.esi.comma.testspecification.generator.json

import java.util.Map

/** Dependency-free deterministic JSON writer. */
class JsonWriter {
    static dispatch def String toJson(Map<?,?> values) '''
        {
            «FOR key : values.keySet SEPARATOR ","»
                «String.valueOf(key).quoted»: «values.get(key).toJson»
            «ENDFOR»
        }
    '''

    static dispatch def String toJson(Iterable<?> values) '''
        [
            «FOR value : values SEPARATOR ","»
                «value.toJson»
            «ENDFOR»
        ]
    '''

    static dispatch def String toJson(Number value) {
        return value.toString
    }

    static dispatch def String toJson(Boolean value) {
        return value.toString
    }

    static dispatch def String toJson(Object value) {
        return String.valueOf(value).quoted
    }

    private static def String quoted(String in) {
        val out = new StringBuilder('"')
        for (var i = 0; i < in.length; i++) {
            out.append(switch (c: in.charAt(i)) {
                case c == 34: '\\"' // Double quote
                case c == 92: '\\\\' // Backslash
                case c == 8: '\\b'
                case c == 9: '\\t'
                case c == 10: '\\n'
                case c == 12: '\\f'
                case c == 13: '\\r'
                case c < 32: String.format('\\u%04x', c as int)
                default: c
            })
        }
        return out.append('"').toString
    }
}
