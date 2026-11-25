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
	public static final String CONTEXT_PYTHON_EXE = "pythonExe";
	public static final String CONTEXT_CPNSERVER_PATH = "cpnserverPath";
	public static final String CONTEXT_BPMN_URI = "bpmnURI";
	public static final String CONTEXT_PRODUCT_URI = "productURI";
	public static final String CONTEXT_PETRI_NET_URI = "petriNetURI";
	public static final String CONTEXT_ABSTRACT_TSPEC_URI = "atspecURI";
	public static final String CONTEXT_CONCRETE_TSPEC_URI = "tspecURI";

    private final Map<String, Object> parameters;

	private final CancelIndicator cancelIndicator;

	public StandardProjectGeneratorContext() {
		this(CancelIndicator.NullImpl, new LinkedHashMap<String, Object>());
	}

	public StandardProjectGeneratorContext(CancelIndicator cancelIndicator, Map<String, Object> parameters) {
		this.cancelIndicator = cancelIndicator;
		this.parameters = parameters;
	}

	public CancelIndicator getCancelIndicator() {
		return cancelIndicator;
	}

	public Map<String, Object> getParameters() {
		return parameters;
	}

}
