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

class CmdLineContext implements IGeneratorContext {

	final static String context = "CMD_LINE"

	def String getContextString() {
		context
	}

	override getCancelIndicator() {
		CancelIndicator.NullImpl
	}
}
