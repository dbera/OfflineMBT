/* Copyright (c) 2026 TNO-ESI
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.generator.types;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtext.generator.AbstractGenerator;
import org.eclipse.xtext.generator.IFileSystemAccess2;
import org.eclipse.xtext.generator.IGeneratorContext;
import org.eclipse.xtext.nodemodel.util.NodeModelUtils;

import nl.esi.comma.project.standard.generator.extension.IStandardProjectGeneratorExtension;
import nl.esi.xtext.common.lang.base.Annotatable;
import nl.esi.xtext.common.lang.base.AnnotationValue;
import nl.esi.xtext.common.lang.base.NamedElement;
import nl.esi.xtext.common.lang.utilities.AnnotationUtil;
import nl.esi.xtext.expressions.expression.ExpressionModel;
import nl.esi.xtext.types.types.EnumTypeDecl;
import nl.esi.xtext.types.types.RecordTypeDecl;
import nl.esi.xtext.types.types.SimpleTypeDecl;
import nl.esi.xtext.types.types.TypeDecl;

/**
 * Explicit generator entry point. Traverses the generated language interfaces,
 * with annotation values obtained exclusively through the existing
 * AnnotationUtil. The intermediate Schema remains a renderer boundary, not a
 * second parser.
 */
public class TypesToPythonGenerator extends AbstractGenerator implements IStandardProjectGeneratorExtension {

	@Override
	public void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		// Render completely before writing, so invalid input cannot produce partial
		// output.
		fsa.generateFile("models.py", generate(resource));
	}

	public String generate(Resource resource) {
		EcoreUtil.resolveAll(resource);
		if (!resource.getErrors().isEmpty())
			throw new IllegalArgumentException("Invalid types input: " + resource.getErrors());
		if (resource.getContents().isEmpty())
			throw new IllegalArgumentException("Empty types resource");
		if (!(resource.getContents().get(0) instanceof ExpressionModel model))
			throw new IllegalArgumentException("Expected an ExpressionModel parsed by the Expression language");
		return generate(model);
	}

	/** Also accepts a model already parsed by ParseHelper<ExpressionModel>. */
	public String generate(ExpressionModel model) {
		List<Schema.Declaration> declarations = new ArrayList<>();
		for (TypeDecl declaration : model.getTypes()) {
			if (declaration instanceof RecordTypeDecl record) {
				List<Schema.Field> fields = new ArrayList<>();
				for (var field : record.getFields()) {
					String helper = null;
					Map<String, Object> metadata = new LinkedHashMap<>();
					for (String candidate : PythonRenderer.HELPERS) {
						Map<String, Object> values = annotation(field, candidate);
						// The demonstrated AnnotationUtil API exposes values, not
						// presence of an annotation with zero arguments. Such a
						// marker is therefore equivalent to an unannotated field.
						if (values.isEmpty())
							continue;
						if (helper != null)
							throw new IllegalArgumentException(
									"Multiple UI helpers on " + record.getName() + "." + field.getName());
						helper = candidate;
						metadata.putAll(values);
					}
					fields.add(new Schema.Field(field.getName(), typeSpelling(field.getType()), helper, metadata));
				}
				declarations.add(new Schema.Declaration(record.getName(), null, List.of(), fields, Map.of()));
			} else if (declaration instanceof EnumTypeDecl enumeration) {
				List<String> literals = new ArrayList<>();
				Map<String, Object> metadata = new LinkedHashMap<>();
				for (var literal : enumeration.getLiterals()) {
					literals.add(literal.getName());
					Map<String, Object> values = annotation(literal, "F");
					if (values.containsKey("default"))
						metadata.put("value_" + literal.getName(), values.get("default"));
				}
				if (literals.isEmpty())
					throw new IllegalArgumentException("Empty enum: " + enumeration.getName());
				declarations.add(new Schema.Declaration(enumeration.getName(), null, literals, List.of(), metadata));
			} else if (declaration instanceof SimpleTypeDecl simple) {
				if (simple.getBase() == null)
					throw new IllegalArgumentException("Simple type requires a base: " + simple.getName());
				declarations.add(new Schema.Declaration(simple.getName(), simple.getBase().getName(), List.of(),
						List.of(), Map.of()));
			} else {
				throw new IllegalArgumentException("Unsupported declaration: " + declaration.getName());
			}
		}
		if (declarations.isEmpty())
			throw new IllegalArgumentException("Input contains no type declarations");
		return new PythonRenderer().render(new Schema(declarations));
	}

	/**
	 * Keep the existing collection spelling conversion in PythonRenderer. This
	 * reads ONLY the type node reached through the typed field.getType() accessor;
	 * annotations are never inspected as nodes or matched as source text. The
	 * inherited Types grammar/metamodel was not supplied, so constructor accessor
	 * names must not be invented here.
	 */
	private String typeSpelling(org.eclipse.emf.ecore.EObject type) {
		var node = NodeModelUtils.getNode(type);
		if (node == null)
			throw new IllegalArgumentException("Type spelling requires a parsed type node");
		return NodeModelUtils.getTokenText(node);
	}

	/** Annotation access mirrors ExpressionAnnotationsTest: map + first value. */
	private Map<String, Object> annotation(NamedElement owner, String name) {
		Map<String, Object> values = AnnotationUtil.getAnnotationValues((Annotatable) owner, name);
		AnnotationValue first = AnnotationUtil.getAnnotationValue((Annotatable) owner, name);
		Map<String, Object> result = new LinkedHashMap<>();
		for (var entry : values.entrySet()) {
			String key = entry.getKey();
			if (key == null || key.isEmpty()) {
				key = positionalKey(name);
				if (first != null) {
					put(result, key, first);
				}
			} else {
				put(result, key, entry.getValue());
			}
		}
		if (result.isEmpty() && first != null) {
			put(result, positionalKey(name), first);
		}
		return result;
	}

	private String positionalKey(String helper) {
		return helper.equals("Ref") || helper.equals("RefList") ? "path" : "default";
	}

	/** Decode structured metadata only AFTER AnnotationUtil has read its value. */
	private void put(Map<String, Object> result, String key, Object value) {
		if (key.endsWith("_json")) {
			key = key.substring(0, key.length() - 5);
			if (!(value instanceof String text))
				throw new IllegalArgumentException("JSON annotation value must be a string");
			value = PythonValues.json(text);
		}
		if (result.containsKey(key))
			throw new IllegalArgumentException("Duplicate normalized annotation parameter: " + key);
		result.put(key, value);
	}

	@Override
	public void beforeGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		// TODO Auto-generated method stub

	}

	@Override
	public void afterGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		// TODO Auto-generated method stub

	}
}
