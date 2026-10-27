package nl.esi.comma.testspecification.generator.json

import java.util.Map

/** Dependency-free deterministic JSON writer. */
class JsonWriter {

    def String write(Object value) {
        val out = new StringBuilder
        appendValue(value, out, 0)
        out.append('\n')
        return out.toString
    }

    private def void appendValue(Object value, StringBuilder out, int indent) {
        if (value === null) {
            out.append("null")
        } else if (value instanceof String) {
            appendQuoted(value as String, out)
        } else if (value instanceof Number || value instanceof Boolean) {
            out.append(value.toString)
        } else if (value instanceof Map) {
            appendObject(value as Map<?, ?>, out, indent)
        } else if (value instanceof Iterable) {
            appendArray(value as Iterable<?>, out, indent)
        } else {
            appendQuoted(value.toString, out)
        }
    }

    private def void appendObject(Map<?, ?> map, StringBuilder out, int indent) {
        out.append('{')
        var first = true

        for (Object key : map.keySet) {
            if (first) {
                out.append('\n')
                first = false
            } else {
                out.append(",\n")
            }

            appendSpaces(out, indent + 2)
            appendQuoted(String.valueOf(key), out)
            out.append(": ")
            appendValue(map.get(key), out, indent + 2)
        }

        if (!first) {
            out.append('\n')
            appendSpaces(out, indent)
        }
        out.append('}')
    }

    private def void appendArray(Iterable<?> values, StringBuilder out, int indent) {
        out.append('[')
        var first = true

        for (Object value : values) {
            if (first) {
                out.append('\n')
                first = false
            } else {
                out.append(",\n")
            }

            appendSpaces(out, indent + 2)
            appendValue(value, out, indent + 2)
        }

        if (!first) {
            out.append('\n')
            appendSpaces(out, indent)
        }
        out.append(']')
    }

    private def void appendQuoted(String text, StringBuilder out) 
    {
        out.append('"')

        for (var i = 0; i < text.length; i++) {
            val c = text.charAt(i)
    
            if (c == 34) {
                // Double quote
                out.append('\\')
                out.append('"')
            } else if (c == 92) {
                // Backslash
                out.append('\\')
                out.append('\\')
            } else if (c == 8) {
                out.append('\\')
                out.append('b')
            } else if (c == 12) {
                out.append('\\')
                out.append('f')
            } else if (c == 10) {
                out.append('\\')
                out.append('n')
            } else if (c == 13) {
                out.append('\\')
                out.append('r')
            } else if (c == 9) {
                out.append('\\')
                out.append('t')
            } else if (c < 32) {
                out.append(
                    String.format(
                        "\\u%04x",
                        c as int
                    )
                )
            } else {
                out.append(c)
            }
        }
    
        out.append('"')
    }


//    private def void appendQuoted(String text, StringBuilder out) {
//        out.append('"')
//
//        for (var i = 0; i < text.length; i++) {
//            val c = text.charAt(i)
//
//            if (c == '"') {
//                out.append("\\\"")
//            } else if (c == '\\') {
//                out.append("\\\\")
//            } else if (c == '\b') {
//                out.append("\\b")
//            } else if (c == '\f') {
//                out.append("\\f")
//            } else if (c == '\n') {
//                out.append("\\n")
//            } else if (c == '\r') {
//                out.append("\\r")
//            } else if (c == '\t') {
//                out.append("\\t")
//            } else if ((c as int) < 32) {
//                out.append(String.format("\\u%04x", c as int))
//            } else {
//                out.append(c)
//            }
//        }
//
//        out.append('"')
//    }

    private def void appendSpaces(StringBuilder out, int count) {
        for (var i = 0; i < count; i++) {
            out.append(' ')
        }
    }
}
