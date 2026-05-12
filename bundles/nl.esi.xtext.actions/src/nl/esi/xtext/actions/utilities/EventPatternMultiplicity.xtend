/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.actions.utilities

class EventPatternMultiplicity {
	public long lower = 1
	public long upper = 1
	
	def boolean isOptional(){
		lower == 0
	}
	
	def boolean isMultiple(){
		upper > 1 || upper == -1
	}
	
	def boolean isOne(){
		lower == 1 && upper == 1
	}
}