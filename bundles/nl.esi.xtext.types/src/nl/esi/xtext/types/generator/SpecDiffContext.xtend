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