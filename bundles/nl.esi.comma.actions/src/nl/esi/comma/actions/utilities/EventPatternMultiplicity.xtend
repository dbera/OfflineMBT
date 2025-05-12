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
package nl.esi.comma.actions.utilities

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