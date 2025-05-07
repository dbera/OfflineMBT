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

class SpecDiffContext implements IGeneratorContext {
	
	public String oriFeaturePath
	public String updFeaturePath
	public int sensitivity
	
	new(String oriFeaturePath, String updFeaturePath, int sensitivity){
		this.oriFeaturePath = oriFeaturePath
		this.updFeaturePath = updFeaturePath
		this.sensitivity = sensitivity
	}
	
	override getCancelIndicator() {
		CancelIndicator.NullImpl
	}
	
}