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

import java.util.LinkedHashMap;
import java.util.Map;

import org.eclipse.xtext.generator.IGeneratorContext;
import org.eclipse.xtext.util.CancelIndicator;

public class StandardProjectGeneratorContext implements IGeneratorContext {
	private final Map<String, String> renamingRules;
	private final Map<String, String> generatorParams;

	private final CancelIndicator cancelIndicator;

	public StandardProjectGeneratorContext() {
		this(CancelIndicator.NullImpl, new LinkedHashMap<String, String>(), new LinkedHashMap<String, String>());
	}

	public StandardProjectGeneratorContext(CancelIndicator cancelIndicator, Map<String, String> renamingRules,
			Map<String, String> generatorParams) {
		this.cancelIndicator = cancelIndicator;
		this.renamingRules = renamingRules;
		this.generatorParams = generatorParams;
	}

	public CancelIndicator getCancelIndicator() {
		return cancelIndicator;
	}

	public Map<String, String> getRenamingRules() {
		return renamingRules;
	}

	public Map<String, String> getGeneratorParams() {
		return generatorParams;
	}
}
