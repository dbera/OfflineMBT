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

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IConfigurationElement;
import org.eclipse.core.runtime.Platform;
import org.eclipse.emf.common.EMFPlugin.EclipsePlugin;
import org.eclipse.emf.ecore.plugin.RegistryReader;

public class StandardProjectGeneratorExtensionRegistryReader extends RegistryReader {
	private static final String EXTENSION_POINT_ID = "generator_extension";
	private static final String TAG_GENERATOR = "generator";

	private final EclipsePlugin plugin;

	private final ArrayList<IStandardProjectGeneratorExtension> extensions = new ArrayList<>();

	public StandardProjectGeneratorExtensionRegistryReader(EclipsePlugin plugin) {
		super(Platform.getExtensionRegistry(), plugin.getBundle().getSymbolicName(), EXTENSION_POINT_ID);
		this.plugin = plugin;
	}

	public List<IStandardProjectGeneratorExtension> getStandardProjectGeneratorExtensions() {
		return Collections.unmodifiableList(extensions);
	}

	public void dispose() {
		extensions.clear();
	}

	@Override
	protected boolean readElement(IConfigurationElement element, boolean add) {
		boolean recognized = false;
		if (element.getName().equals(TAG_GENERATOR)) {
			recognized = true;
			try {
				final IStandardProjectGeneratorExtension extension = (IStandardProjectGeneratorExtension) element
						.createExecutableExtension("class");
				extensions.add(extension);
			} catch (CoreException e) {
				plugin.getLog().error(
						"The generator extension cannot be created for: " + element.getContributor().getName(), e);
			}
		}
		return recognized;
	}
}
