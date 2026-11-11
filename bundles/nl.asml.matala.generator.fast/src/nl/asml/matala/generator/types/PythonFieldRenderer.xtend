/* Copyright (c) 2026 TNO-ESI
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.generator.types

import java.util.ArrayList
import java.util.HashSet
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import java.util.Set

/** Field rendering extensions; all Python structure is emitted with rich strings. */
final class PythonFieldRenderer {
    def String render(Schema.Field field, Map<String, Schema.Declaration> types) {
        val meta = new LinkedHashMap<String, Object>(field.metadata())
        val options = options(meta.remove("_python"))
        var String pythonType = new PythonRenderer().type(field.type(), types)
        val storageType = pythonType
        if (flag(options, "identifier")) {
            if (pythonType == "_types_builtins.str") pythonType = "_TypesIdentifier"
            else if (pythonType == "_types_builtins.list[_types_builtins.str]") pythonType = "_types_builtins.list[_TypesIdentifier]"
            else throw new IllegalArgumentException("@Identifier requires string or string[]: " + field.name())
        }
        var String helper = if (field.helper() === null) {
            if (storageType.startsWith("_types_builtins.list[")) "L" else "F"
        } else field.helper()
        if (!PythonRenderer.HELPERS.contains(helper))
            throw new IllegalArgumentException("Unsupported helper: " + helper)
        if (Set.of("L", "RefList").contains(helper) && !storageType.startsWith("_types_builtins.list["))
            throw new IllegalArgumentException(helper + " requires a list: " + field.name())
        if (Set.of("Ref", "FileSelector", "Template").contains(helper) && storageType != "_types_builtins.str")
            throw new IllegalArgumentException(helper + " requires a string: " + field.name())
        if (helper == "RefList" && storageType != "_types_builtins.list[_types_builtins.str]")
            throw new IllegalArgumentException("RefList requires string[]")
        for (key : meta.keySet()) PythonRenderer.identifier(key)
        if (meta.containsKey("default") && meta.containsKey("default_enum"))
            throw new IllegalArgumentException("default and default_enum conflict")
        if ((meta.containsKey("default") || meta.containsKey("default_enum")) && meta.containsKey("default_factory"))
            throw new IllegalArgumentException("default and default_factory conflict: " + field.name())
        if (meta.containsKey("predefined") && meta.containsKey("predefined_from"))
            throw new IllegalArgumentException("predefined and predefined_from conflict")
        if (meta.containsKey("required") && !(meta.get("required") instanceof Boolean))
            throw new IllegalArgumentException("required must be boolean")
        for (legacy : List.of("kind", "item_required", "file_filter")) {
            if (helper == "L" && meta.containsKey(legacy))
                throw new IllegalArgumentException("List file metadata belongs in items_json, not " + legacy)
        }
        for (key : List.of("filters", "items", "relevant_if", "required_if")) {
            if (meta.containsKey(key) && !(meta.get(key) instanceof Map<?, ?>))
                throw new IllegalArgumentException(key + " must be an object")
        }
        if (meta.containsKey("predefined") && !(meta.get("predefined") instanceof List<?>))
            throw new IllegalArgumentException("predefined must be a list")
        val low = meta.get("ge")
        val high = meta.get("le")
        if (low instanceof Number) {
            if (high instanceof Number) {
                if (low.doubleValue() > high.doubleValue())
                    throw new IllegalArgumentException("ge must not exceed le")
            }
        }
        // Explicit expression-bearing keys are the only way to emit enum code.
        for (key : new ArrayList<String>(meta.keySet())) {
            if (key.endsWith("_enum")) {
                val target = key.substring(0, key.length() - 5)
                if (!Set.of("default", "relevant_if", "required_if", "filters").contains(target))
                    throw new IllegalArgumentException("Unsupported enum metadata: " + key)
                if (meta.containsKey(target)) throw new IllegalArgumentException("Duplicate enum metadata: " + target)
                val value = meta.remove(key)
                if (target == "default" && types.containsKey(field.type()) && !types.get(field.type()).literals().empty) {
                    if (!(value instanceof String)) throw new IllegalArgumentException("default_enum must be a string")
                    if (!(value as String).startsWith(field.type() + "."))
                        throw new IllegalArgumentException("default_enum must belong to " + field.type())
                }
                if (target != "default" && !(value instanceof Map<?, ?>))
                    throw new IllegalArgumentException(target + "_enum must be an object")
                meta.put(target, if (target == "default") PythonEmission.enumMember(value, types) else PythonEmission.enumTree(value, types))
            }
        }
        if (meta.containsKey("predefined_from")) {
            if (helper != "Template") throw new IllegalArgumentException("predefined_from requires @Template")
            meta.put("predefined", PythonEmission.predefined(meta.remove("predefined_from")))
        }
        if (flag(options, "nullable") || (meta.containsKey("default") && meta.get("default") === null))
            pythonType = pythonType + " | None"
        if (flag(options, "constraints")) {
            if (flag(options, "identifier"))
                throw new IllegalArgumentException("Use Identifier or Annotated constraints, not both")
            if (!Set.of("_types_builtins.int", "_types_builtins.float", "_types_builtins.str").contains(storageType))
                throw new IllegalArgumentException("Annotated constraints require a primitive scalar")
            val constraints = new ArrayList<String>()
            for (key : List.of("ge", "le", "gt", "lt", "min_length", "max_length", "pattern")) {
                if (meta.containsKey(key))
                    constraints.add('''«key»=«PythonEmission.literal(meta.remove(key))»'''.toString)
            }
            if (constraints.empty) throw new IllegalArgumentException("constraints=true needs a constraint")
            pythonType = '''_types_typing.Annotated[«pythonType», _types_pydantic.Field(«constraints.join(", ")») ]'''.toString
        }
        val args = new ArrayList<String>()
        if (helper == "Ref" || helper == "RefList") {
            val path = meta.remove("path")
            if (!(path instanceof String)) throw new IllegalArgumentException("Reference path required")
            if ((path as String).isBlank()) throw new IllegalArgumentException("Reference path required")
            args.add(PythonEmission.literal(path))
        }
        if (!meta.containsKey("default") && !meta.containsKey("default_factory")) {
            if (Boolean.TRUE.equals(meta.get("required"))) meta.put("default", PythonEmission.required())
            else if (types.containsKey(field.type()) && record(types.get(field.type()))) {
                cycle(field.type(), types, new HashSet<String>())
                meta.put("default_factory", field.type())
            } else if (helper == "F") {
                meta.put("default", scalarDefault(storageType))
            }
        }
        if (flag(options, "plain")) {
            if (helper != "F")
                throw new IllegalArgumentException("plain=true cannot discard a UI helper")
            if (meta.size() != 1 || !meta.containsKey("default"))
                throw new IllegalArgumentException("plain=true requires only a default after extracting constraints")
            return '''«field.name()»: «pythonType» = «PythonEmission.literal(meta.get("default"))»'''.toString
        }
        for (entry : meta.entrySet()) {
            val value = if (entry.key == "default_factory")
                PythonEmission.literal(PythonEmission.factory(entry.value, types))
            else PythonEmission.literal(entry.value)
            args.add('''«entry.key»=«value»'''.toString)
        }
        '''
            «field.name()»: «pythonType» = _types_ui_api.«helper»(
                «FOR argument : args»
                «argument»,
                «ENDFOR»
            )
        '''.toString
    }

    def private Map<String, Boolean> options(Object value) {
        val result = new LinkedHashMap<String, Boolean>()
        if (value === null) return result
        if (!(value instanceof Map<?, ?>)) throw new IllegalArgumentException("Invalid Python options")
        val settings = value as Map<?, ?>
        for (key : settings.keySet()) {
            if (!(key instanceof String)) throw new IllegalArgumentException("Invalid Python option name")
            if (!Set.of("identifier", "nullable", "plain", "constraints").contains(key))
                throw new IllegalArgumentException("Unknown Python option: " + key)
            val setting = settings.get(key)
            if (!(setting instanceof Boolean)) throw new IllegalArgumentException(key + " must be boolean")
            result.put(key as String, setting as Boolean)
        }
        result
    }

    def private boolean flag(Map<String, Boolean> options, String key) {
        Boolean.TRUE.equals(options.get(key))
    }

    def private Object scalarDefault(String type) {
        switch type {
            case "_types_builtins.str": ""
            case "_types_builtins.int": 0
            case "_types_builtins.float": 0.0
            case "_types_builtins.bool": false
            default: PythonEmission.required()
        }
    }

    def private boolean record(Schema.Declaration declaration) {
        declaration.base() === null && declaration.literals().empty
    }

    def private void cycle(String name, Map<String, Schema.Declaration> types, Set<String> visiting) {
        if (!visiting.add(name)) throw new IllegalArgumentException("Recursive default factories: " + name)
        for (field : types.get(name).fields()) {
            if (types.containsKey(field.type()) && record(types.get(field.type())) &&
                !field.metadata().containsKey("default") && !Boolean.TRUE.equals(field.metadata().get("required")))
                cycle(field.type(), types, visiting)
        }
        visiting.remove(name)
    }
}
