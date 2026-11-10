/* Copyright (c) 2026 TNO-ESI
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.generator.types

import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import java.util.Set

/** Build MODEL_SUMMARIES from scalar-valued, repeatable field annotations. */
final class ModelSummaryBuilder {
    private new() {}

    public static val Set<String> NAMES = Set.of(
        "SchemaField", "SchemaFlag", "SchemaCount", "SchemaTitle"
    )

    static class Entry {
        public val String field
        public val String kind
        public val Map<String, Object> values

        new(String field, String kind, Map<String, Object> values) {
            this.field = field
            this.kind = kind
            this.values = values
        }
    }

    private static class Line {
        public val String label
        public val List<String> fields = new ArrayList<String>()
        public val Map<String, String> flags = new LinkedHashMap<String, String>()
        public var String count

        new(String label) { this.label = label }
    }

    def static Map<String, Object> build(List<Entry> entries) {
        val Map<String, Object> result = new LinkedHashMap<String, Object>()
        val Map<String, Line> lines = new LinkedHashMap<String, Line>()
        var String title = null

        for (entry : entries) {
            validate(entry)
            val path = path(entry)
            if (entry.kind == "SchemaTitle") {
                if (title !== null && title != path)
                    throw new IllegalArgumentException("Multiple distinct summary titles")
                title = path
            } else {
                val label = string(entry.values, "label", entry.field)
                var line = lines.get(label)
                if (line === null) {
                    line = new Line(label)
                    lines.put(label, line)
                }
                switch entry.kind {
                    case "SchemaField": {
                        if (line.count !== null) throw conflict(label)
                        // Identical repeats are harmless; preserve first occurrence.
                        if (!line.fields.contains(path)) line.fields.add(path)
                    }
                    case "SchemaFlag": {
                        if (line.count !== null) throw conflict(label)
                        val text = string(entry.values, "text", leaf(path))
                        val previous = line.flags.get(path)
                        if (previous !== null && previous != text)
                            throw new IllegalArgumentException("Conflicting flag text for " + path)
                        line.flags.put(path, text)
                    }
                    case "SchemaCount": {
                        if (!line.fields.empty || !line.flags.empty ||
                            (line.count !== null && line.count != path)) throw conflict(label)
                        line.count = path
                    }
                }
            }
        }

        if (title !== null) result.put("title", title)
        if (title !== null || !lines.empty) {
            val output = new ArrayList<Map<String, Object>>()
            for (line : lines.values()) {
                val Map<String, Object> data = new LinkedHashMap<String, Object>()
                data.put("label", line.label)
                if (!line.fields.empty) data.put("fields", new ArrayList<String>(line.fields))
                if (!line.flags.empty) {
                    val flags = new ArrayList<Map<String, String>>()
                    for (flagPath : line.flags.keySet()) {
                        val Map<String, String> flag = new LinkedHashMap<String, String>()
                        flag.put("path", flagPath)
                        flag.put("text", line.flags.get(flagPath))
                        flags.add(flag)
                    }
                    data.put("flags", flags)
                }
                if (line.count !== null) data.put("count", line.count)
                output.add(data)
            }
            result.put("lines", output)
        }
        result
    }

    def private static void validate(Entry entry) {
        if (!NAMES.contains(entry.kind))
            throw new IllegalArgumentException("Unknown summary annotation: " + entry.kind)
        if (entry.field === null || !entry.field.matches("[A-Za-z_][A-Za-z0-9_]*"))
            throw new IllegalArgumentException("Invalid summary field: " + entry.field)
        val allowed = switch entry.kind {
            case "SchemaTitle": Set.of("subfield")
            case "SchemaFlag": Set.of("label", "subfield", "text")
            default: Set.of("label", "subfield")
        }
        for (key : entry.values.keySet()) {
            if (!allowed.contains(key))
                throw new IllegalArgumentException("Unknown @" + entry.kind + " parameter: " + key)
            // Summary arguments have named string values; empty annotations are valid.
            string(entry.values, key, "")
        }
    }

    def private static String path(Entry entry) {
        if (!entry.values.containsKey("subfield")) return entry.field
        val subfield = string(entry.values, "subfield", "")
        if (!subfield.matches("[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*"))
            throw new IllegalArgumentException("Invalid summary subfield: " + subfield)
        entry.field + "." + subfield
    }

    def private static String string(Map<String, Object> values, String key, String fallback) {
        if (!values.containsKey(key)) return fallback
        val value = values.get(key)
        if (!(value instanceof String))
            throw new IllegalArgumentException(key + " must be a string")
        if ((value as String).isBlank())
            throw new IllegalArgumentException(key + " must not be blank")
        value as String
    }

    def private static String leaf(String path) {
        path.substring(path.lastIndexOf('.') + 1)
    }

    def private static IllegalArgumentException conflict(String label) {
        new IllegalArgumentException("Conflicting count/line definitions for label: " + label)
    }
}
