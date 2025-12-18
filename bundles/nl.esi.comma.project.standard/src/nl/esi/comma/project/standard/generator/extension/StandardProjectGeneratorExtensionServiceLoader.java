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
package nl.esi.comma.project.standard.generator.extension;

import java.util.ServiceLoader;

import com.google.common.collect.Iterables;
import com.google.inject.Provider;
import com.google.inject.Singleton;

import nl.esi.comma.project.standard.generator.extension.IStandardProjectGeneratorExtension.Registry;

@Singleton
public class StandardProjectGeneratorExtensionServiceLoader implements Provider<Registry> {
	private final ServiceLoader<IStandardProjectGeneratorExtension> extensionLoader = ServiceLoader
			.load(IStandardProjectGeneratorExtension.class);

	private final Registry registry = loadRegistry();

	private Registry loadRegistry() {
		StandardProjectGeneratorExtensionRegistryImpl registry = new StandardProjectGeneratorExtensionRegistryImpl();
		Iterables.addAll(registry, extensionLoader);
		return registry;
	}

	@Override
	public IStandardProjectGeneratorExtension.Registry get() {
		return this.registry;
	}
}
