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
package nl.asml.matala.generator.types;

import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.xtext.resource.IResourceServiceProvider;
import org.eclipse.xtext.resource.XtextResourceSet;

/**
 * Equinox command-line entry point for the Types-to-Python generator.
 *
 * <p>
 * This application intentionally uses the Xtext resource-service registry
 * initialized by Equinox. It does not instantiate a language-specific
 * StandaloneSetup class. This keeps parser ownership and file-extension
 * registration aligned with the installed OfflineMBT language bundles.
 * </p>
 */
public final class TypesToPythonCli implements IApplication {

	private static final String APPLICATION_ID = "nl.asml.matala.generator.fast.typesToPython";

	private static final String USAGE = "Usage: eclipse -nosplash -application " + APPLICATION_ID
			+ " -- <input.types> <output/models.py>";

	@Override
	public Object start(IApplicationContext context) {
		PrintWriter err = new PrintWriter(System.err, true);

		try {
			String[] args = applicationArguments(context);

			if (args.length != 2) {
				err.println(USAGE);
				return Integer.valueOf(2);
			}

			Path input = Path.of(args[0]).toAbsolutePath().normalize();
			Path output = Path.of(args[1]).toAbsolutePath().normalize();

			generate(input, output);

			System.out.println("Generated Python model: " + output);

			return IApplication.EXIT_OK;
		} catch (Exception exception) {
			err.println("Types-to-Python generation failed: " + exception.getMessage());
			exception.printStackTrace(err);
			return Integer.valueOf(1);
		}
	}

	@Override
	public void stop() {
		// The operation is synchronous, so there is no background work to stop.
	}

	/**
	 * Generate one Python module from one .types resource.
	 */
	static void generate(Path input, Path output) throws Exception {
		validateInput(input);

		URI inputUri = URI.createFileURI(input.toString());
		ResourceSet resourceSet = createResourceSet(inputUri);
		Resource resource = resourceSet.getResource(inputUri, true);

		validateResource(resource);

		String python = new TypesToPythonGenerator().generate(resource);
		writeAtomically(output, python);
	}

	/**
	 * Obtain an Xtext-aware ResourceSet from the registered language service.
	 *
	 * <p>
	 * When running as an Equinox application, the extension registry has already
	 * loaded the language registrations from the installed plug-ins.
	 * </p>
	 */
	private static ResourceSet createResourceSet(URI inputUri) {
		IResourceServiceProvider serviceProvider = IResourceServiceProvider.Registry.INSTANCE
				.getResourceServiceProvider(inputUri);

		if (serviceProvider == null) {
			throw new IllegalStateException("No Xtext language is registered for " + inputUri
					+ ". Ensure the plug-in owning the .types " + "extension is installed and active.");
		}

		XtextResourceSet xtextResourceSet = serviceProvider.get(XtextResourceSet.class);

		if (xtextResourceSet != null) {
			return xtextResourceSet;
		}

		/*
		 * Normally the XtextResourceSet is available from the language's injector. Keep
		 * an EMF fallback for language configurations that register their resource
		 * factory but do not bind XtextResourceSet.
		 */
		return new ResourceSetImpl();
	}

	private static void validateInput(Path input) {
		if (!Files.exists(input)) {
			throw new IllegalArgumentException("Input file does not exist: " + input);
		}

		if (!Files.isRegularFile(input)) {
			throw new IllegalArgumentException("Input path is not a file: " + input);
		}

		if (!Files.isReadable(input)) {
			throw new IllegalArgumentException("Input file is not readable: " + input);
		}
	}

	private static void validateResource(Resource resource) {
		if (resource.getContents().isEmpty()) {
			throw new IllegalArgumentException("The input resource is empty: " + resource.getURI());
		}

		if (!resource.getErrors().isEmpty()) {
			StringBuilder message = new StringBuilder("The input contains syntax or linking errors:");

			for (Resource.Diagnostic diagnostic : resource.getErrors()) {
				message.append(System.lineSeparator()).append("  ").append(resource.getURI()).append(':')
						.append(diagnostic.getLine()).append(':').append(diagnostic.getColumn()).append(": ")
						.append(diagnostic.getMessage());
			}

			throw new IllegalArgumentException(message.toString());
		}
	}

	private static void writeAtomically(Path output, String content) throws Exception {
		Path parent = output.getParent();

		/*
		 * toAbsolutePath() normally provides a parent, but retain a defensive fallback
		 * for unusual filesystem providers.
		 */
		if (parent == null) {
			parent = Path.of(".").toAbsolutePath().normalize();
			output = parent.resolve(output.getFileName());
		}

		Files.createDirectories(parent);

		Path temporary = Files.createTempFile(parent, output.getFileName().toString() + ".", ".tmp");

		try {
			Files.writeString(temporary, content, StandardCharsets.UTF_8);

			try {
				Files.move(temporary, output, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
			} catch (java.nio.file.AtomicMoveNotSupportedException exception) {
				Files.move(temporary, output, StandardCopyOption.REPLACE_EXISTING);
			}
		} finally {
			Files.deleteIfExists(temporary);
		}
	}

	private static String[] applicationArguments(IApplicationContext context) {
		Object value = context.getArguments().get(IApplicationContext.APPLICATION_ARGS);

		if (value instanceof String[] arguments) {
			return arguments;
		}

		return new String[0];
	}
}