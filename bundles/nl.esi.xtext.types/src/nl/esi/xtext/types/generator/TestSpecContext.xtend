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