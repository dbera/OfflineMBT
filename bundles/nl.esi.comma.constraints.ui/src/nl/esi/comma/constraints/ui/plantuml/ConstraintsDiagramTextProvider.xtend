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
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.generator.ConstraintsStateMachineGenerator
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil

class ConstraintsDiagramTextProvider implements IXtextDiagramTextProvider {
    override getDiagramText(Collection<EObject> selection) {
        val constraints = selection.map[EcoreUtil.getRootContainer(it, true)].filter(Constraints).head
        if (constraints === null) {
            return null
        }
        val mapContraintToAutomata = (new ConstraintsStateMachineGenerator()).generateStateMachine(constraints,
            Collections.emptyMap, 'dummyPath', 'dummyName', null, false, false)
        if (!mapContraintToAutomata.isEmpty) {
            return '''
                @startdot
                
                «mapContraintToAutomata.values.head.dot»
                
                @enddot
            '''
        }
    }
}
