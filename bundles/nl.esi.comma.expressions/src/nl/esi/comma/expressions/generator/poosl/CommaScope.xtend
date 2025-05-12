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
package nl.esi.comma.expressions.generator.poosl

/*
 * Type that indicates the scope of a ComMA variable
 * GLOBAL: variables defined in state machines and data/generic constraints variable blocks
 * TRANSITION: variables that are parameters of events
 * QUANTIFIER: variables that are iterators in quantifiers
 */
enum CommaScope {
	GLOBAL,
	TRANSITION,
	QUANTIFIER
}