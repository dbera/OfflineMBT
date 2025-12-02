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
package nl.esi.comma.causalgraph.utilities

import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.StepType
import org.eclipse.xtend.lib.annotations.Data

@Data
class NodeAttributes {
    val boolean function
    val String stepName
    val StepType stepType

    def applyTo(Node node) {
        node.function = function
        node.stepName = stepName
        node.stepType = stepType
    }

    static def valueOf(Node node) {
        return new NodeAttributes(node.function, node.stepName, node.stepType)
    }
}
