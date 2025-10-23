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
package nl.esi.comma.types.utilities;

import java.util.Iterator;
import java.util.Map;
import java.util.Optional;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.common.CommonPlugin;
import org.eclipse.emf.common.util.BasicDiagnostic;
import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.common.util.DiagnosticException;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.util.Diagnostician;
import org.eclipse.emf.ecore.util.EObjectValidator;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.IGrammarAccess;
import org.eclipse.xtext.nodemodel.BidiTreeIterable;
import org.eclipse.xtext.nodemodel.INode;
import org.eclipse.xtext.resource.SaveOptions;
import org.eclipse.xtext.resource.XtextResource;
import org.eclipse.xtext.serializer.ISerializer;
import org.eclipse.xtext.util.ITextRegion;

import com.google.inject.Guice;
import com.google.inject.Module;

import nl.esi.comma.types.types.Import;

public class EcoreUtil3 extends EcoreUtil2 {
	/**
	 * @see EcoreUtil2#getResource(Resource, String)
	 */
	public static Resource getResource(Import imp) {
		return EcoreUtil2.getResource(imp.eResource(), imp.getImportURI());
	}

	/**
	 * @see #resolveUri(Resource, String)
	 */
	public static URI resolveUri(Import imp) {
		return resolveUri(imp.eResource(), imp.getImportURI());
	}

	/**
	 * @see CommonPlugin#resolve(URI)
	 * @See {@link URI#toFileString()}
	 */
	public static String toPath(URI uri) {
		return uri == null ? null : CommonPlugin.resolve(uri).toFileString();
	}

	/**
	 * @see EcoreUtil2#getResource(Resource, String)
	 */
	public static URI resolveUri(Resource context, String path) {
		URI contextURI = context.getURI();
		URI referenceURI = URI.createURI(path);
		if (contextURI.isHierarchical() && !contextURI.isRelative()
				&& (referenceURI.isRelative() && !referenceURI.isEmpty())) {
			referenceURI = referenceURI.resolve(contextURI);
		}
		return referenceURI;
	}
	
	public static <T extends EObject> T unformat(T eObject) {
		if (eObject == null) {
			return null;
		}
		removeFormatting(eObject);
		eObject.eAllContents().forEachRemaining(EcoreUtil3::removeFormatting);
		return eObject;
	}

	private static void removeFormatting(EObject eObject) {
		eObject.eAdapters().removeIf(e -> e instanceof INode);
	}

	public static String serialize(EObject eObject) {
		return serialize(eObject, false);
	}

	/**
	 * Serialized an {@link EObject} to text, either using the {@link Module modules} or loaded {@link XtextResource}.
	 */
	public static String serialize(EObject eObject, boolean format, com.google.inject.Module... modules) {
		if (eObject == null) {
			return null;
		}
		ISerializer serializer = null;
		if (modules != null && modules.length > 0) {
			serializer = Guice.createInjector(modules).getInstance(ISerializer.class);
		} else if (eObject.eResource() instanceof XtextResource xtextResource) {
			serializer = xtextResource.getResourceServiceProvider().get(ISerializer.class);
		}
		
		if (serializer == null) {
			throw new RuntimeException("Failed to serialize EObject: " + eObject);
		}
		SaveOptions.Builder opt = SaveOptions.newBuilder();
		if (format) {
			opt.format();
		}
		return serializer.serialize(eObject, opt.getOptions()).trim();
	}
	
	public static <T> T getService(EObject eObject, Class<T> serviceClazz) {
		if (eObject == null) {
			return null;
		}
		if (eObject.eResource() instanceof XtextResource xtextResource) {
			return xtextResource.getResourceServiceProvider().get(serviceClazz);
		}
		return null;
	}

	/**
	 * Serializes the {@code eObject} into text, allowing to replace parts of
	 * descendant {@link EObject}s by means of providing a {@code replacer}. The
	 * {@code eObject} should be loaded in an {@link XtextResource} for this
	 * function to work properly. The {@code replacer} should avoid to replace text
	 * of ancestor EObjects when a replacement has already been applied to one of
	 * its descendants.
	 * 
	 * @param eObject  the Xtext EObject to serialize
	 * @param replacer A replacer that provides replacements for specific descendant
	 *                 {@link EObject}s, returns {@code null} when no replacement is
	 *                 required for the {@link EObject}.
	 * @return the serialized text.
	 */
	public static String serialize(EObject eObject, Function<? super EObject, ? extends CharSequence> replacer) {
		return serializeXtext(eObject, node -> {
			return node.hasDirectSemanticElement() ? replacer.apply(node.getSemanticElement()) : null;
		});
	}

	/**
	 * Serializes the {@code eObject} into text, allowing to replace parts of
	 * descendant {@link EObject}s by means of providing a {@code replacer}. The
	 * {@code eObject} should be loaded in an {@link XtextResource} for this
	 * function to work properly. The {@code replacer} should avoid to replace text
	 * of ancestor EObjects when a replacement has already been applied to one of
	 * its descendants.
	 * 
	 * @param eObject  the Xtext EObject to serialize
	 * @param replacer A replacer that provides replacements for specific descendant
	 *                 {@link EObject}s (first argument) and specific grammar rules
	 *                 (second argument), returns {@code null} when no replacement
	 *                 is required for the {@link EObject}.
	 * @return the serialized text.
	 * @see IGrammarAccess
	 */
	public static String serialize(EObject eObject, BiFunction<? super EObject, ? super EObject, ? extends CharSequence> replacer) {
		return serializeXtext(eObject, node -> {
			EObject semanticElement = node.getSemanticElement();
			EObject grammarElement = node.getGrammarElement();
			if (semanticElement != null && grammarElement != null) {
				return replacer.apply(semanticElement, grammarElement);
			}
			return null;
		});
	}

	public static String serializeXtext(EObject eObject, Function<? super INode, ? extends CharSequence> replacer) {
		Optional<INode> eObjectNode = eObject.eAdapters().stream().filter(INode.class::isInstance).map(INode.class::cast).findFirst();
		if (eObjectNode.isEmpty()) {
			throw new IllegalArgumentException("Not an Xtext eObject");
		}
		ITextRegion eObjectTextRegion = eObjectNode.get().getTotalTextRegion();
		StringBuilder text = new StringBuilder(eObjectNode.get().getText());
		if (eObjectNode.get() instanceof BidiTreeIterable<?> iterable) {
			for (@SuppressWarnings("unchecked") Iterator<INode> iterator = (Iterator<INode>) iterable.reverse().iterator(); iterator.hasNext();) {
				INode node = iterator.next();
				CharSequence replacement = replacer.apply(node);
				if (replacement != null) {
					int replaceStart = node.getOffset() - eObjectTextRegion.getOffset();
					int replaceEnd = replaceStart + node.getLength();
					text.replace(replaceStart, replaceEnd, replacement.toString());
				}
			}
		}
		return text.toString();
	}

	/**
	 * @throws ValidationException
	 * @see {@link Diagnostician#validate(EObject)}
	 */
	public static void validate(EObject eObject) throws ValidationException {
		Diagnostician diagnostician = new Diagnostician();
		BasicDiagnostic diagnostics = diagnostician.createDefaultDiagnostic(eObject);
		Map<Object, Object> context = diagnostician.createDefaultContext();

		boolean result = diagnostician.validate(eObject, diagnostics, context);

		if (!result) {
			throw new ValidationException(diagnostics);
		}
	}

	/**
	 * @throws ValidationException
	 * @see {@link Diagnostician#validate(EObject)}
	 */
	public static void validate(Resource resource) throws ValidationException {
		Diagnostician diagnostician = new Diagnostician();
		BasicDiagnostic diagnostics = new BasicDiagnostic(EObjectValidator.DIAGNOSTIC_SOURCE, 0,
				"Diagnosis of " + resource.getURI(), new Object[] { resource });
		Map<Object, Object> context = diagnostician.createDefaultContext();

		boolean result = true;
		for (EObject eObject : resource.getContents()) {
			result &= diagnostician.validate(eObject, diagnostics, context);
		}

		if (!result) {
			throw new ValidationException(diagnostics);
		}
	}

	public static final class ValidationException extends Exception {
		private static final long serialVersionUID = 4543121779695994392L;

		public ValidationException(Diagnostic diagnostic) {
			super(createMessage(diagnostic), new DiagnosticException(diagnostic));
		}

		@Override
		public synchronized DiagnosticException getCause() {
			return DiagnosticException.class.cast(super.getCause());
		}

		private static String createMessage(Diagnostic diagnostic) {
			String details = diagnostic.getChildren().stream()
					.filter(c -> c.getSeverity() != Diagnostic.OK)
					.map(c -> "- " + c.getMessage())
					.collect(Collectors.joining("\n"));
			return diagnostic.getMessage() + (details.isEmpty() ? "" : "\n" + details);
		}
	}
}
