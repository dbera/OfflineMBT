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
package nl.asml.matala.generator.types

import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.List
import java.util.Map

/** Explicit, validated Python expressions mixed with ordinary literal metadata. */
final class PythonEmission {
    private new() {}

    private static class Expression {
        val String source
        new(String source) { this.source = source }
    }

    def static Object required() { new Expression("...") }

    def static Object enumMember(Object value, Map<String, Schema.Declaration> types) {
        if (!(value instanceof String)) throw new IllegalArgumentException("Enum expression must be a string")
        val text = value as String
        if (!text.matches("[A-Za-z][A-Za-z0-9_]*\\.[A-Za-z][A-Za-z0-9_]*"))
            throw new IllegalArgumentException("Expected EnumType.MEMBER: " + text)
        val parts = text.split("\\.")
        if (parts.length != 2) throw new IllegalArgumentException("Expected EnumType.MEMBER: " + text)
        PythonRenderer.identifier(parts.get(0))
        PythonRenderer.identifier(parts.get(1))
        val declaration = types.get(parts.get(0))
        if (declaration === null || !declaration.literals().contains(parts.get(1)))
            throw new IllegalArgumentException("Unknown enum member: " + text)
        new Expression(text)
    }

    def static Object enumTree(Object value, Map<String, Schema.Declaration> types) {
        if (value instanceof Map<?, ?>) {
            val Map<Object, Object> result = new LinkedHashMap<Object, Object>()
            for (key : value.keySet()) result.put(key, enumTree(value.get(key), types))
            return result
        }
        if (value instanceof List<?>) {
            val result = new ArrayList<Object>()
            for (item : value) result.add(enumTree(item, types))
            return result
        }
        if (value instanceof String) return enumMember(value, types)
        // Booleans/numbers/null remain data in conditional trees.
        value
    }

    def static Object factory(Object value, Map<String, Schema.Declaration> types) {
        if (!(value instanceof String)) throw new IllegalArgumentException("Factory must be a name")
        val name = value as String
        PythonRenderer.identifier(name)
        if (name != "list" && name != "dict" && !types.containsKey(name))
            throw new IllegalArgumentException("Unknown factory: " + name)
        new Expression(if (types.containsKey(name)) name else "_types_builtins." + name)
    }

    def static Object predefined(Object value) {
        if (value != "list_templates")
            throw new IllegalArgumentException("Only predefined_from=\"list_templates\" is supported")
        new Expression("_types_model_utils.list_templates()")
    }

    def static String literal(Object value) {
        if (value instanceof Expression) return value.source
        if (value instanceof Map<?, ?>)
            return '''{«FOR key : value.keySet() SEPARATOR ', '»«PythonValues.literal(key)»: «literal(value.get(key))»«ENDFOR»}'''.toString
        if (value instanceof List<?>)
            return '''[«FOR item : value SEPARATOR ', '»«literal(item)»«ENDFOR»]'''.toString
        PythonValues.literal(value)
    }
}
