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

import org.eclipse.xtext.resource.IResourceServiceProvider.Registry;
import org.eclipse.xtext.resource.ResourceServiceProviderServiceLoader;

import com.google.inject.Provider;

import nl.esi.comma.project.standard.StandardProjectRuntimeModule;
import nl.esi.comma.project.standard.generator.extension.IStandardProjectGeneratorExtension;
import nl.esi.comma.project.standard.generator.extension.StandardProjectGeneratorExtensionServiceLoader;

class StandardProjectCliModule extends StandardProjectRuntimeModule {
	@Override
	public Registry bindIResourceServiceProvider$Registry() {
		// Enabling discovery of languages via service provider API
		return new ResourceServiceProviderServiceLoader().get();
	}

	public Class<? extends Provider<? extends IStandardProjectGeneratorExtension.Registry>> provideIStandardProjectGeneratorExtension$Registry() {
		return StandardProjectGeneratorExtensionServiceLoader.class;
	}
}