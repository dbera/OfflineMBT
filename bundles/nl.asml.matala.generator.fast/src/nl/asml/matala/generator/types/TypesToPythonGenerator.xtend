/* Copyright (c) 2026 TNO-ESI
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.generator.types

import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.List
import java.util.Map

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.nodemodel.util.NodeModelUtils

import nl.esi.comma.project.standard.generator.^extension.IStandardProjectGeneratorExtension
import nl.esi.xtext.common.lang.base.Annotatable
import nl.esi.xtext.common.lang.base.AnnotationValue
import nl.esi.xtext.common.lang.base.NamedElement
import nl.esi.xtext.common.lang.utilities.AnnotationUtil
import nl.esi.xtext.expressions.expression.ExpressionModel
import nl.esi.xtext.types.types.EnumTypeDecl
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.SimpleTypeDecl
import nl.esi.xtext.types.types.TypeDecl

/**
 * Explicit generator entry point. Traverses the generated language interfaces,
 * with annotation values obtained exclusively through the existing
 * AnnotationUtil. The intermediate Schema remains a renderer boundary, not a
 * second parser.
 */
class TypesToPythonGenerator extends AbstractGenerator implements IStandardProjectGeneratorExtension {

    override void doGenerate(
        Resource resource,
        IFileSystemAccess2 fsa,
        IGeneratorContext context
    ) {
        // Render completely before writing, so invalid input cannot produce partial
        // output.
        fsa.generateFile("models.py", generate(resource))
    }

    def String generate(Resource resource) {
        EcoreUtil.resolveAll(resource)

        if (!resource.errors.empty)
            throw new IllegalArgumentException("Invalid types input: " + resource.errors)

        if (resource.contents.empty)
            throw new IllegalArgumentException("Empty types resource")

        val model = resource.contents.get(0)
        if (!(model instanceof ExpressionModel))
            throw new IllegalArgumentException(
                "Expected an ExpressionModel parsed by the Expression language"
            )

        return generate(model as ExpressionModel)
    }

    /** Also accepts a model already parsed by ParseHelper<ExpressionModel>. */
    def String generate(ExpressionModel model) {
        val List<Schema.Declaration> declarations = new ArrayList<Schema.Declaration>()

        for (TypeDecl declaration : model.types) {
            if (declaration instanceof RecordTypeDecl) {
                val record = declaration
                val List<Schema.Field> fields = new ArrayList<Schema.Field>()

                for (field : record.fields) {
                    var String helper = null
                    val Map<String, Object> metadata = new LinkedHashMap<String, Object>()

                    for (String candidate : PythonRenderer.HELPERS) {
                        val Map<String, Object> values = annotation(field, candidate)

                        // The demonstrated AnnotationUtil API exposes values, not
                        // presence of an annotation with zero arguments. Such a
                        // marker is therefore equivalent to an unannotated field.
                        if (!values.empty) {
                            if (helper !== null)
                                throw new IllegalArgumentException(
                                    "Multiple UI helpers on " + record.name + "." + field.name
                                )

                            helper = candidate
                            metadata.putAll(values)
                        }
                    }

                    fields.add(
                        new Schema.Field(
                            field.name,
                            typeSpelling(field.type),
                            helper,
                            metadata
                        )
                    )
                }

                declarations.add(
                    new Schema.Declaration(
                        record.name,
                        null,
                        List.of(),
                        fields,
                        Map.of()
                    )
                )
            } else if (declaration instanceof EnumTypeDecl) {
                val enumeration = declaration
                val List<String> literals = new ArrayList<String>()
                val Map<String, Object> metadata = new LinkedHashMap<String, Object>()

                for (literal : enumeration.literals) {
                    literals.add(literal.name)
                    val Map<String, Object> values = annotation(literal, "F")

                    if (values.containsKey("default"))
                        metadata.put("value_" + literal.name, values.get("default"))
                }

                if (literals.empty)
                    throw new IllegalArgumentException("Empty enum: " + enumeration.name)

                declarations.add(
                    new Schema.Declaration(
                        enumeration.name,
                        null,
                        literals,
                        List.of(),
                        metadata
                    )
                )
            } else if (declaration instanceof SimpleTypeDecl) {
                val simple = declaration

                if (simple.base === null)
                    throw new IllegalArgumentException(
                        "Simple type requires a base: " + simple.name
                    )

                declarations.add(
                    new Schema.Declaration(
                        simple.name,
                        simple.base.name,
                        List.of(),
                        List.of(),
                        Map.of()
                    )
                )
            } else {
                throw new IllegalArgumentException(
                    "Unsupported declaration: " + declaration.name
                )
            }
        }

        if (declarations.empty)
            throw new IllegalArgumentException("Input contains no type declarations")

        return new PythonRenderer().render(new Schema(declarations))
    }

    /**
     * Keep the existing collection spelling conversion in PythonRenderer. This
     * reads ONLY the type node reached through the typed field.getType() accessor;
     * annotations are never inspected as nodes or matched as source text. The
     * inherited Types grammar/metamodel was not supplied, so constructor accessor
     * names must not be invented here.
     */
    def private String typeSpelling(org.eclipse.emf.ecore.EObject type) {
        val node = NodeModelUtils.getNode(type)

        if (node === null)
            throw new IllegalArgumentException(
                "Type spelling requires a parsed type node"
            )

        return NodeModelUtils.getTokenText(node)
    }

    /** Annotation access mirrors ExpressionAnnotationsTest: map + first value. */
    def private Map<String, Object> annotation(NamedElement owner, String name) {
        val Map<String, Object> values =
            AnnotationUtil.getAnnotationValues(owner as Annotatable, name)
        val AnnotationValue first =
            AnnotationUtil.getAnnotationValue(owner as Annotatable, name)
        val Map<String, Object> result = new LinkedHashMap<String, Object>()

        for (entry : values.entrySet()) {
            var String key = entry.key

            if (key === null || key.empty) {
                key = positionalKey(name)

                if (first !== null) {
                    put(result, key, first)
                }
            } else {
                put(result, key, entry.value)
            }
        }

        if (result.empty && first !== null) {
            put(result, positionalKey(name), first)
        }

        return result
    }

    def private String positionalKey(String helper) {
        return helper.equals("Ref") || helper.equals("RefList") ? "path" : "default"
    }

    /** Decode structured metadata only AFTER AnnotationUtil has read its value. */
    def private void put(Map<String, Object> result, String key, Object value) {
        var String normalizedKey = key
        var Object normalizedValue = value

        if (normalizedKey.endsWith("_json")) {
            normalizedKey = normalizedKey.substring(0, normalizedKey.length() - 5)

            if (!(normalizedValue instanceof String))
                throw new IllegalArgumentException(
                    "JSON annotation value must be a string"
                )

            normalizedValue = PythonValues.json(normalizedValue as String)
        }

        if (result.containsKey(normalizedKey))
            throw new IllegalArgumentException(
                "Duplicate normalized annotation parameter: " + normalizedKey
            )

        result.put(normalizedKey, normalizedValue)
    }

    override void beforeGenerate(
        Resource input,
        IFileSystemAccess2 fsa,
        IGeneratorContext context
    ) {
        // TODO Auto-generated method stub
    }

    override void afterGenerate(
        Resource input,
        IFileSystemAccess2 fsa,
        IGeneratorContext context
    ) {
        // TODO Auto-generated method stub
    }
}