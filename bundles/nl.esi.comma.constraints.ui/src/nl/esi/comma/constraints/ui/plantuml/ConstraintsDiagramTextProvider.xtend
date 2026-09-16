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
package nl.esi.comma.constraints.ui.plantuml

import java.util.Collection
import java.util.Collections
import nl.esi.comma.constraints.constraints.Composition
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.generator.ConstraintsStateMachineGenerator
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2

class ConstraintsDiagramTextProvider implements IXtextDiagramTextProvider {
    override getDiagramText(Collection<EObject> selection) {
        val constraints = selection.map[EcoreUtil2.getContainerOfType(it, Constraints)].head
        if (constraints === null) {
            return null
        }
        val composition = selection.map[EcoreUtil2.getContainerOfType(it, Composition)].head
        val name = if (composition !== null) {
            composition.name
        } else if (!constraints.compositions.isNullOrEmpty) {
            constraints.compositions.head.name
        } else {
            'dummyName'
        }

        val mapContraintToAutomata = (new ConstraintsStateMachineGenerator()).generateStateMachine(constraints,
            Collections.emptyMap, 'dummyPath', name, null, false, false)
        if (!mapContraintToAutomata.isEmpty) {
            return '''
                @startdot
                
                «mapContraintToAutomata.get(name).dot»
                
                @enddot
            '''
        }
    }
}
