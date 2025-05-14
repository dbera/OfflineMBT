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

import java.util.Map;
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
import org.eclipse.xtext.nodemodel.INode;
import org.eclipse.xtext.resource.SaveOptions;
import org.eclipse.xtext.resource.XtextResource;
import org.eclipse.xtext.serializer.ISerializer;

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
