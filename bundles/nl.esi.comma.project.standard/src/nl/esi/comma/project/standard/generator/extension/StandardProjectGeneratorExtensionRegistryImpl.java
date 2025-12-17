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

class StandardProjectGeneratorExtensionRegistryImpl extends ArrayList<IStandardProjectGeneratorExtension>
		implements IStandardProjectGeneratorExtension.Registry {
	private static final long serialVersionUID = 7639105742002057113L;
}
