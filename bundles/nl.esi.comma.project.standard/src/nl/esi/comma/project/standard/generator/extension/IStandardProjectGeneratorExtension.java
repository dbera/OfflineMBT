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

import java.util.List;

import org.eclipse.xtext.generator.IGenerator2;

import com.google.inject.ProvidedBy;

public interface IStandardProjectGeneratorExtension extends IGenerator2 {
	@ProvidedBy(Registry.RegistryProvider.class)
	interface Registry extends List<IStandardProjectGeneratorExtension> {
		final static Registry INSTANCE = new StandardProjectGeneratorExtensionRegistryImpl();

		public static class RegistryProvider implements com.google.inject.Provider<Registry> {
			@Override
			public Registry get() {
				return INSTANCE;
			}
		}
	}
}
