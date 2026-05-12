/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.types.generator

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