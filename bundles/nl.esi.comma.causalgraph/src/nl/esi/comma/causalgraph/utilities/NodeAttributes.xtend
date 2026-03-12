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
import java.util.Objects

@Data
class NodeAttributes {
    val boolean function
    val String stepName
    val String stepSignature
    val StepType stepType

    def applyTo(Node node) {
        node.function = function
        node.stepName = stepName
        node.stepSignature = stepSignature
        node.stepType = stepType
    }

    static def valueOf(Node node) {
        return new NodeAttributes(node.function, node.stepName, node.stepSignature, node.stepType)
    }
    
    /**
     * Create a merge key based on step-signature for grouping nodes.
     * Nodes with the same signature (but potentially different step names) will be grouped together.
     */
    def getMergeKey() {
        return new NodeMergeKey(function, stepSignature, stepType)
    }
    
    @Data
    static class NodeMergeKey {
        val boolean function
        val String stepSignature
        val StepType stepType
        
        override equals(Object obj) {
            if (this === obj) return true
            if (obj === null || !(obj instanceof NodeMergeKey)) return false
            val other = obj as NodeMergeKey
            return function == other.function && 
                   Objects.equals(stepSignature, other.stepSignature) && 
                   stepType == other.stepType
        }
        
        override hashCode() {
            return Objects.hash(function, stepSignature, stepType)
        }
    }
}
