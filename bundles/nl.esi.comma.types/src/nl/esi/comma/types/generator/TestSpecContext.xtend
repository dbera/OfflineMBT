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
import java.nio.file.Path

class TestSpecContext implements IGeneratorContext {
	
	public Path tspecPath
	
	new(Path tspecPath){
		this.tspecPath = tspecPath
	}
	
	override getCancelIndicator() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
}