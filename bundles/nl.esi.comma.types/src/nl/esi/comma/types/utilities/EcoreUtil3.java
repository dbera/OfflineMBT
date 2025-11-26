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

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.common.CommonPlugin;
import org.eclipse.emf.common.util.BasicDiagnostic;
import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.common.util.DiagnosticException;
import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.common.util.WrappedException;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.util.Diagnostician;
import org.eclipse.emf.ecore.util.EObjectValidator;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.IGrammarAccess;
import org.eclipse.xtext.formatting2.regionaccess.IEObjectRegion;
import org.eclipse.xtext.formatting2.regionaccess.ITextRegionAccess;
import org.eclipse.xtext.formatting2.regionaccess.ITextRegionRewriter;
import org.eclipse.xtext.formatting2.regionaccess.ITextReplacement;
import org.eclipse.xtext.nodemodel.BidiTreeIterable;
import org.eclipse.xtext.nodemodel.ICompositeNode;
import org.eclipse.xtext.nodemodel.INode;
import org.eclipse.xtext.nodemodel.util.NodeModelUtils;
import org.eclipse.xtext.resource.SaveOptions;
import org.eclipse.xtext.resource.XtextResource;
import org.eclipse.xtext.serializer.ISerializer;
import org.eclipse.xtext.serializer.impl.Serializer;
import org.eclipse.xtext.util.ITextRegion;

import com.google.inject.Guice;
import com.google.inject.Module;

import nl.esi.comma.types.types.Import;

public class EcoreUtil3 extends EcoreUtil2 {
	public static Resource getResource(Import imp) {
		URI uri = resolveUri(imp);
		try {
			Resource res = imp.eResource().getResourceSet().getResource(uri, true);
	        if (!res.getErrors().isEmpty()) {
				throw new RuntimeException("Resource contains errors: \n\t"
						+ res.getErrors().stream().map(org.eclipse.emf.ecore.resource.Resource.Diagnostic::getMessage)
								.collect(Collectors.joining("\n\t")));
	        }
	        return res;
		} catch (WrappedException e) {
			throw e;
		} catch (RuntimeException e) {
			throw new WrappedException("Cannot load resource: " + uri, e);
		}
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
		if (contextURI.isHierarchical() && (referenceURI.isRelative() && !referenceURI.isEmpty())) {
			if (!contextURI.isRelative()) {
				referenceURI = referenceURI.resolve(contextURI);
			} else if (contextURI.isFile()) {
				Path contextPath = Path.of(contextURI.toFileString());
				if (!Files.isDirectory(contextPath)) {
					contextPath = contextPath.getParent();
				}
				referenceURI = URI.createURI(contextPath.resolve(path).toUri().toString());
			}
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
		ISerializer serializer = getService(eObject, ISerializer.class, modules);
		if (serializer == null) {
			throw new RuntimeException("Failed to serialize EObject: " + eObject);
		}
		SaveOptions.Builder opt = SaveOptions.newBuilder();
		if (format) {
			opt.format();
		}
		return serializer.serialize(eObject, opt.getOptions()).trim();
	}
	
	public static <T> T getService(EObject eObject, Class<T> serviceClazz, com.google.inject.Module... modules) {
		if (modules != null && modules.length > 0) {
			return Guice.createInjector(modules).getInstance(serviceClazz);
		} else if (eObject != null && eObject.eResource() instanceof XtextResource xtextResource) {
			return xtextResource.getResourceServiceProvider().get(serviceClazz);
		}
		return null;
	}

	/**
	 * Serializes the {@code eObject} into text, allowing to replace parts of
	 * descendant {@link EObject}s by means of providing a {@code replacer}. The
	 * {@code eObject} should be loaded in an {@link XtextResource} for this
	 * function to work properly.
	 * 
	 * 
	 * @param eObject    the Xtext EObject to serialize
	 * @param replacer   A replacer that provides replacements for specific
	 *                   descendant {@link EObject}s, returns {@code null} when no
	 *                   replacement is required for the {@link EObject} or the
	 *                   adapted text to use for the node.
	 * @return the serialized text.
	 * @see #xSerialize(EObject, Serializer, Function)
	 */
	@SuppressWarnings("restriction")
	public static String serialize(EObject eObject, Function<? super EObject, ? extends CharSequence> replacer) {
		return serialize(eObject, getService(eObject, Serializer.class), replacer);
	}
	
	/**
	 * Serializes the {@code eObject} into text, allowing to replace parts of
	 * descendant {@link EObject}s by means of providing a {@code replacer}.
	 * 
	 * 
	 * @param eObject    the Xtext EObject to serialize
	 * @param serializer the serializer to use
	 * @param replacer   A replacer that provides replacements for specific
	 *                   descendant {@link EObject}s, returns {@code null} when no
	 *                   replacement is required for the {@link EObject} or the
	 *                   adapted text to use for the node.
	 * @return the serialized text.
	 */
	@SuppressWarnings("restriction")
	public static String serialize(EObject eObject, Serializer serializer, Function<? super EObject, ? extends CharSequence> replacer) {
		if (eObject == null) {
			return null;
		}
		if (serializer == null) {
			throw new IllegalStateException("Cannot serialize an eObject that has no associated serializer");
		}
		if (replacer.apply(eObject) instanceof CharSequence replacement) {
			// A full replacement
			return replacement.toString();
		}
		ITextRegionAccess regionAccess = serializer.serializeToRegions(eObject);
		ITextRegionRewriter rewriter = regionAccess.getRewriter();
		ArrayList<ITextReplacement> replacements = new ArrayList<ITextReplacement>();
		for (TreeIterator<EObject> i = eObject.eAllContents(); i.hasNext();) {
			EObject next = i.next();
			CharSequence replacement = replacer.apply(next);
			if (replacement != null) {
				// A partial replacement
				IEObjectRegion objRegion = regionAccess.regionForEObject(next);
				replacements.add(rewriter.createReplacement(
						objRegion.getOffset(), 
						objRegion.getLength(),
						replacement.toString()));
				// Prevent replacing descendant AST nodes
				i.prune();
			}
		}
		return rewriter.renderToString(replacements);
	}

	/**
	 * Serializes the {@code eObject} into text, allowing to replace parts of
	 * descendant {@link EObject}s by means of providing a {@code replacer}. The
	 * {@code eObject} should be loaded in an {@link XtextResource} for this
	 * function to work properly. The {@code replacer} should avoid to replace text
	 * of ancestor EObjects when a replacement has already been applied to one of
	 * its descendants.
	 * 
	 * 
	 * @param eObject  the Xtext EObject to serialize
	 * @param replacer A replacer that provides replacements for specific descendant
	 *                 {@link EObject}s ({@link INode#getSemanticElement()}) and/or
	 *                 specific grammar rules ({@link INode#getGrammarElement()}),
	 *                 returns {@code null} when no replacement is required for the
	 *                 {@link EObject} or the adapted {@link INode#getText()} to use
	 *                 for the node.
	 * @return the serialized text.
	 * @see IGrammarAccess
	 */
	public static String serializeXtext(EObject eObject, Function<? super INode, ? extends CharSequence> replacer) {
		ICompositeNode eObjectNode = NodeModelUtils.getNode(eObject);
		if (eObjectNode instanceof BidiTreeIterable<?> iterable) {
			ITextRegion eObjectTextRegion = eObjectNode.getTotalTextRegion();
			StringBuilder text = new StringBuilder(eObjectNode.getText());
			for (@SuppressWarnings("unchecked") INode node: (Iterable<INode>) iterable.reverse()) {
				CharSequence replacement = replacer.apply(node);
				if (replacement != null) {
					int replaceStart = node.getOffset() - eObjectTextRegion.getOffset();
					int replaceEnd = replaceStart + node.getLength();
					text.replace(replaceStart, replaceEnd, replacement.toString());
				}
			}
			return text.toString();
		} else {
			throw new IllegalStateException("Cannot serialize an eObject that has no associated node");
		}
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
