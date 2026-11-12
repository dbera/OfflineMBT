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
import java.util.LinkedHashSet
import java.util.Set
import java.util.List
import java.util.Map

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.nodemodel.util.NodeModelUtils

import nl.esi.comma.project.standard.generator.^extension.IStandardProjectGeneratorExtension
import nl.esi.comma.testspecification.testspecification.impl.TSMainImpl
import nl.esi.xtext.common.lang.base.Annotatable
import nl.esi.xtext.types.types.EnumTypeDecl
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.SimpleTypeDecl
import nl.esi.xtext.types.types.TypeDecl
import nl.esi.xtext.types.types.TypesModel
import nl.esi.xtext.types.types.impl.TypesModelImpl

import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*

/**
 * Explicit generator entry point. Traverses the generated language interfaces,
 * with annotation values decoded through the existing AnnotationUtil,
 * independently for each annotation occurrence. The intermediate Schema remains a renderer boundary, not a
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
        EcoreUtil.resolveAll(resource)

        if (!resource.errors.empty)
            throw new IllegalArgumentException("Invalid types input: " + resource.errors)

        if (resource.contents.empty)
            throw new IllegalArgumentException("Empty types resource")

        // Get TSpec file (Resource)
        val tspecRes = resource.contents.get(0)
        if (!(tspecRes instanceof TSMainImpl))
            throw new IllegalArgumentException("Expected an TSMainImpl parsed by the TSpec language")

        // Get TSpec specific Types file path, URI, and Resource
        val typesTspecPath = (tspecRes as TSMainImpl).imports.get(0).importURI
        val typesTspecURI = tspecRes.eResource.resolveUri(typesTspecPath)
        val typesTspecRes = resource.resourceSet.getResource(typesTspecURI, true).contents.get(0)
        if (!(typesTspecRes instanceof TypesModelImpl))
            throw new IllegalArgumentException("Expected a (TSpec) TypesModelImpl parsed by the Expression language")

        // Get PSpec specific Types file path, URI, and Resource
        val typesPspecPath = (typesTspecRes as TypesModelImpl).imports.get(0).importURI
        val typesPspecURI = tspecRes.eResource.resolveUri(typesPspecPath)
        val typesPspecRes = resource.resourceSet.getResource(typesPspecURI, true).contents.get(0)
        if (!(typesPspecRes instanceof TypesModelImpl))
            throw new IllegalArgumentException("Expected a (PSpec) TypesModelImpl parsed by the Expression language")

        val pythonFsa = fsa.createFolderAccess('generated_python/')
        pythonFsa.generateFile("models.py", generate(typesPspecRes as TypesModel))
    }

    def String generate(Resource resource) {
        EcoreUtil.resolveAll(resource)

        if (!resource.errors.empty)
            throw new IllegalArgumentException("Invalid types input: " + resource.errors)

        if (resource.contents.empty)
            throw new IllegalArgumentException("Empty types resource")

        // Get TSpec file (Resource)
        val tspecRes = resource.contents.get(0)
        if (!(tspecRes instanceof TypesModelImpl))
            throw new IllegalArgumentException("Expected a TypesModelImpl parsed by the Expression language")

        return generate(tspecRes as TypesModel)
    }

    /** Also accepts a model already parsed by ParseHelper<ExpressionModel>. */
    def String generate(TypesModel model) {
        val List<Schema.Declaration> declarations = new ArrayList<Schema.Declaration>()

        for (TypeDecl declaration : model.types) {
            if (declaration instanceof RecordTypeDecl) {
                val record = declaration
                val List<Schema.Field> fields = new ArrayList<Schema.Field>()
                val summaryEntries = new ArrayList<ModelSummaryBuilder.Entry>()
                // Record-level summaries use subfield as an absolute model-relative path.
                // This also preserves display-only paths absent from the active model.
                for (occurrence : AnnotationOccurrences.read(record as Annotatable, ModelSummaryBuilder.NAMES)) {
                    val values = new LinkedHashMap<String, Object>(occurrence.values)
                    val path = values.remove("subfield")
                    if (!(path instanceof String))
                        throw new IllegalArgumentException("Record-level summary requires subfield")
                    val text = path as String
                    if (!text.matches("[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*"))
                        throw new IllegalArgumentException("Invalid record summary subfield: " + text)
                    val dot = text.indexOf('.')
                    val root = if(dot < 0) text else text.substring(0, dot)
                    if(dot >= 0) values.put("subfield", text.substring(dot + 1))
                    summaryEntries.add(new ModelSummaryBuilder.Entry(root, occurrence.name, values))
                }

                for (field : record.fields) {
                    val Set<String> names = new LinkedHashSet<String>(PythonRenderer.HELPERS)
                    names.addAll(ModelSummaryBuilder.NAMES)
                    names.addAll(Set.of("Identifier", "Python", "FileSelectorList"))
                    val occurrences = AnnotationOccurrences.read(field as Annotatable, names)
                    var String helper = null
                    val Map<String, Object> metadata = new LinkedHashMap<String, Object>()
                    val Map<String, Object> python = new LinkedHashMap<String, Object>()

                    for (occurrence : occurrences) {
                        if (ModelSummaryBuilder.NAMES.contains(occurrence.name)) {
                            summaryEntries.add(new ModelSummaryBuilder.Entry(
                                field.name, occurrence.name, occurrence.values
                            ))
                        } else if (occurrence.name == "FileSelectorList") {
                            throw new IllegalArgumentException(
                                "@" + occurrence.name + " is no longer supported; use @Ref with filters_json or @L with items_json"
                            )
                        } else if (occurrence.name == "Identifier") {
                            if (!occurrence.values.empty)
                                throw new IllegalArgumentException("@Identifier is a marker")
                            if (python.containsKey("identifier"))
                                throw new IllegalArgumentException("Duplicate Identifier/Python identifier setting")
                            python.put("identifier", true)
                        } else if (occurrence.name == "Python") {
                            for (key : occurrence.values.keySet()) {
                                if (python.containsKey(key))
                                    throw new IllegalArgumentException("Duplicate Python option: " + key)
                                python.put(key, occurrence.values.get(key))
                            }
                        } else {
                            // Presence, not a non-empty argument map, selects a helper.
                            // Thus bare @F/@L/@FileSelector/etc. are recognized too.
                            if (helper !== null)
                                throw new IllegalArgumentException(
                                    "Multiple UI helpers on " + record.name + "." + field.name
                                )
                            helper = occurrence.name
                            metadata.putAll(uiValues(occurrence.name, occurrence.values))
                        }
                    }

                    if(!python.empty) metadata.put("_python", python)
                    fields.add(
                        new Schema.Field(
                            field.name,
                            typeSpelling(field.type),
                            helper,
                            metadata
                        )
                    )
                }

                val Map<String, Object> recordMetadata = new LinkedHashMap<String, Object>()
                val summary = ModelSummaryBuilder.build(summaryEntries)
                if(!summary.empty) recordMetadata.put("summary", summary)
                declarations.add(
                    new Schema.Declaration(
                        record.name,
                        null,
                        List.of(),
                        fields,
                        recordMetadata
                    )
                )
            } else if (declaration instanceof EnumTypeDecl) {
                val enumeration = declaration
                val List<String> literals = new ArrayList<String>()
                val Map<String, Object> metadata = new LinkedHashMap<String, Object>()

                for (literal : enumeration.literals) {
                    literals.add(literal.name)
                    val annotations = AnnotationOccurrences.read(literal as Annotatable, Set.of("F", "EnumValue"))
                    if (annotations.size() > 1)
                        throw new IllegalArgumentException("Multiple enum-value annotations on literal " + literal.name)
                    val Map<String, Object> values = new LinkedHashMap<String, Object>()
                    if (!annotations.empty) {
                        val occurrence = annotations.head
                        if (occurrence.name == "EnumValue") {
                            if (occurrence.values.size() != 1 || !occurrence.values.containsKey("value"))
                                throw new IllegalArgumentException("EnumValue requires only value=...")
                            values.put("default", occurrence.values.get("value"))
                        } else values.putAll(uiValues("F", occurrence.values))
                    }

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
    def private String typeSpelling(EObject type) {
        val node = NodeModelUtils.getNode(type)

        if (node === null)
            throw new IllegalArgumentException(
                "Type spelling requires a parsed type node"
            )

        return NodeModelUtils.getTokenText(node)
    }

    /** Normalize decoded UI values without passing raw AnnotationValue AST nodes. */
    def private Map<String, Object> uiValues(String helper, Map<String, Object> values) {
        val Map<String, Object> result = new LinkedHashMap<String, Object>()
        for (entry : values.entrySet()) {
            val key = if(entry.key === null || entry.key.empty) positionalKey(helper) else entry.key
            put(result, key, entry.value)
        }
        result
    }

    def private String positionalKey(String helper) {
        return if (helper == "Ref" || helper == "RefList") "path"
        else "default"
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
