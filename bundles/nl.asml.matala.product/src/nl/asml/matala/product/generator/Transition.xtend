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
package nl.asml.matala.product.generator


class Transition {
	public var bname = new String
	public var name = new String
	public var qname = new String
	new (String b, String n, String q) {
		bname = b
		name = n
		qname = q
	}
}
