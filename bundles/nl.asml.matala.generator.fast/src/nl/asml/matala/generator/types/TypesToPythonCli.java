/* Copyright (c) 2026 TNO-ESI
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.generator.types;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.xtext.resource.XtextResource;

import nl.esi.xtext.expressions.ExpressionStandaloneSetup;

/**
 * Run with the workspace's language bundles on the classpath, or an Eclipse
 * launcher.
 */
public final class TypesToPythonCli {
	private TypesToPythonCli() {
	}

	public static void main(String[] args) throws Exception {
		if (args.length != 2)
			throw new IllegalArgumentException("Usage: TypesToPythonCli input.types output/models.py");
		var injector = new ExpressionStandaloneSetup().createInjectorAndDoEMFRegistration();
		ResourceSet set = injector.getInstance(ResourceSet.class);
		// Explicitly use the Expression parser, whose entry rule includes annotated
		// TypeDecl.
		// This avoids dependence on which language owns the .types extension in the
		// workspace.
		XtextResource resource = injector.getInstance(XtextResource.class);
		resource.setURI(URI.createFileURI(Path.of(args[0]).toAbsolutePath().toString()));
		set.getResources().add(resource);
		try (InputStream in = Files.newInputStream(Path.of(args[0]))) {
			resource.load(in, null);
		}
		String python = new TypesToPythonGenerator().generate(resource);
		Path output = Path.of(args[1]).toAbsolutePath();
		Files.createDirectories(output.getParent());
		Path temporary = Files.createTempFile(output.getParent(), "models-", ".tmp");
		try {
			Files.writeString(temporary, python);
			Files.move(temporary, output, StandardCopyOption.REPLACE_EXISTING);
		} finally {
			Files.deleteIfExists(temporary);
		}
	}
}
