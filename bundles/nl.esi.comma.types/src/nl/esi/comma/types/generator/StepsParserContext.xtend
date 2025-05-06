/**
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
package nl.esi.comma.types.generator

import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.util.CancelIndicator
import java.util.List

class StepsParserContext implements IGeneratorContext {
	
	public String stepsFilePath
	public List<String> testContext
	public String output
	
	new(String stepsFilePath, List<String> testContext, String output) {
		this.stepsFilePath = stepsFilePath
		this.testContext = testContext
		this.output = output
	}
	
	override getCancelIndicator() {
		CancelIndicator.NullImpl
	}
	
}