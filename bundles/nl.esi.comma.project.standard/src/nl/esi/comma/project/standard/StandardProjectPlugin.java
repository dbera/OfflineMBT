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
package nl.esi.comma.project.standard;

import org.eclipse.emf.common.EMFPlugin.EclipsePlugin;
import org.osgi.framework.BundleContext;

import nl.esi.comma.project.standard.generator.extension.IStandardProjectGeneratorExtension;
import nl.esi.comma.project.standard.generator.extension.StandardProjectGeneratorExtensionRegistryReader;

public class StandardProjectPlugin extends EclipsePlugin {
	private StandardProjectGeneratorExtensionRegistryReader registryReader;

	@Override
	public void start(BundleContext context) throws Exception {
		super.start(context);
		if (registryReader == null) {
			registryReader = new StandardProjectGeneratorExtensionRegistryReader(this);
			registryReader.readRegistry();
			IStandardProjectGeneratorExtension.Registry.INSTANCE
					.addAll(registryReader.getStandardProjectGeneratorExtensions());
		}
	}

	@Override
	public void stop(BundleContext context) throws Exception {
		super.stop(context);
		if (registryReader != null) {
			registryReader.dispose();
			registryReader = null;
		}
	}
}
