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
package nl.esi.comma.behavior.scl.ui.plantuml

import java.util.Collection
import nl.esi.comma.behavior.scl.generator.ConstraintsStateMachineGenerator
import nl.esi.comma.behavior.scl.scl.Model
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil

class ConstraintsDiagramTextProvider implements IXtextDiagramTextProvider {
    override getDiagramText(Collection<EObject> selection) {
        val constraints = selection.map[EcoreUtil.getRootContainer(it, true)].filter(Model).head
        if (constraints === null) {
            return null
        }
//        val mapContraintToAutomata = (new ConstraintsStateMachineGenerator()).generateStateMachine(constraints, 'dummyPath', 'dummyName')
//        if (!mapContraintToAutomata.isEmpty) {
//            return '''
//                @startdot
//                
//                «mapContraintToAutomata.values.head.dot»
//                
//                @enddot
//            '''
//        }
    }
}
