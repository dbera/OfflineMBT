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
package nl.esi.comma.project.standard.cli;

import java.util.Set;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.IGrammarAccess;
import org.eclipse.xtext.resource.IResourceServiceProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.inject.Injector;

import nl.asml.matala.server.ServerLauncher;
import nl.esi.xtext.types.generator.XPlusMain;

public class Main {
	private static final Logger LOG = LoggerFactory.getLogger(Main.class);
	private static final String REST_SERVER = "--rest-server";

	/**
	 * Pseudo file extensions of abstract/library grammars that are only used as super grammars and never parsed
	 * directly; a different injector for these does not affect content assist.
	 */
	private static final Set<String> IGNORED_EXTENSIONS = Set.of("base_lang", "___xbase");

	public static void main(String[] args) {
		if (args.length>0 && REST_SERVER.equals(args[0])) {
			LaunchServer(args);
		}
		else {
			generateFiles(args);
		}
	}

	public static void LaunchServer(String[] args) {
		Injector injector = new StandardProjectCliSetup().createInjectorAndDoEMFRegistration();
		checkGlobalRegistries(injector.getInstance(IResourceServiceProvider.Registry.class));
		ServerLauncher.launch(args, injector);
	}

	/**
	 * Sanity check: the global EMF registry must use the same injector (i.e. Grammar instance) per language as the
	 * registry used by the language server. Otherwise content assist fails with a NullPointerException in
	 * BaseContentAssistParser because rule names cannot be resolved.
	 */
	private static void checkGlobalRegistries(IResourceServiceProvider.Registry registry) {
		for (String ext : registry.getExtensionToFactoryMap().keySet()) {
			URI uri = URI.createURI("dummy." + ext);
			IResourceServiceProvider lspProvider = registry.getResourceServiceProvider(uri);
			IResourceServiceProvider globalProvider = IResourceServiceProvider.Registry.INSTANCE
					.getResourceServiceProvider(uri);
			if (lspProvider == null || globalProvider == null) {
				continue;
			}
			IGrammarAccess lspGrammar = lspProvider.get(IGrammarAccess.class);
			IGrammarAccess globalGrammar = globalProvider.get(IGrammarAccess.class);
			if (lspGrammar != null && globalGrammar != null && lspGrammar.getGrammar() != globalGrammar.getGrammar()) {
				LOG.warn("Language '{}' ({}) is registered with different injectors in the global and language server "
						+ "registries; content assist may fail.", ext, lspGrammar.getGrammar().getName());
			}
		}
	}

	public static void generateFiles(String[] args) {
		Injector injector = new StandardProjectCliSetup().createInjectorAndDoEMFRegistration();
		XPlusMain main = injector.getInstance(XPlusMain.class);
		main.configure(args, "ComMA Standard project generator", "project", ".prj");
		main.read();
	}
}