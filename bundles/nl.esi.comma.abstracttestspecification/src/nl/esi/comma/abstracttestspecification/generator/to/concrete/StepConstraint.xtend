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
package nl.esi.comma.abstracttestspecification.generator.to.concrete

import org.eclipse.xtend.lib.annotations.Data

@Data
class StepConstraint 
{
    val String composeStepName
    val String runStepName
    val String lhs
    val String rhs

    def String getText() '''«lhs.trim» := «rhs.trim»'''
}
