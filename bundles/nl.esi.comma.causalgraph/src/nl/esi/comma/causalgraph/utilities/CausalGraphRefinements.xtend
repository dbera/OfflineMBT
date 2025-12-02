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

import java.util.List
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.CausalGraphFactory
import nl.esi.comma.causalgraph.causalGraph.ControlFlowEdge
import nl.esi.comma.causalgraph.causalGraph.DataFlowEdge
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.ScenarioDecl
import nl.esi.comma.causalgraph.causalGraph.ScenarioStep
import nl.esi.comma.expressions.expression.Variable

import static extension nl.esi.comma.causalgraph.utilities.CausalGraphQueries.*

class CausalGraphRefinements {
    static extension val CausalGraphFactory m_cg = CausalGraphFactory::eINSTANCE

    private new() {
        // Private constructor for utility classes
    }

    static def CausalGraph createCausalGraph(List<ScenarioStep> steps, (ScenarioStep)=>NodeAttributes nodeAttrFunctor) {
        val scenarios = steps.map[scenario].toSet
        if (scenarios.size != 1) {
            throw new IllegalArgumentException('Expected an ordered list of steps for a single scenario')
        }
        val graph = createCausalGraph
        graph.requirements += scenarios.flatMap[requirements]
        graph.scenarios += scenarios
        graph.variables += steps.flatMap[stepVariables].map[variable]
        graph.types += graph.variables.map[type.type].filter[eResource === null]
        // Optionally add types if step parameters are used
        graph.types += steps.flatMap[stepArguments].map[assignment.type.type].filter[eResource === null]

        steps.forEach [ step, counter |
            step.stepNumber = counter + 1
            val nodeAttr = nodeAttrFunctor.apply(step)

            val node = createNode
            node.name = 'n' + step.stepNumber
            node.steps += step
            nodeAttr.applyTo(node)

            if (!step.stepArguments.isEmpty) {
                node.stepParameters += step.stepArguments.map[assignment]
                node.stepBody = step.stepBody
            }

            graph.nodes += node
        ]

        graph.addControlFlowEdges
        graph.addDataFlowEdges

        return graph
    }

    static def void addControlFlowEdges(CausalGraph graph) {
        for (scenario : graph.scenarios) {
            graph.getSteps(scenario).reduce [ s1, s2 |
                graph.addControlFlowEdge(s1.node, s2.node)
                return s2
            ]
        }
    }

    static def void addControlFlowEdge(CausalGraph graph, Node _source, Node _target) {
        if (!graph.edges.filter(ControlFlowEdge).exists[source == _source && target == _target]) {
            graph.edges += createControlFlowEdge => [
                source = _source
                target = _target
            ]
        }
    }

    static def void addDataFlowEdges(CausalGraph graph) {
        for (scenario : graph.scenarios) {
            val writes = newHashMap
            for (step : graph.getSteps(scenario)) {
                step.stepVariables.filter[read].forEach [
                    val target = writes.get(variable)
                    if (target === null) {
                        throw new IllegalStateException('''Error in scenario «scenario.name»: variable «variable.name» cannot be read before it has been written''')
                    }
                    graph.addDataFlowEdge(step.node, target, scenario, variable)
                ]
                step.stepVariables.filter[write].forEach[writes.put(variable, step.node)]
            }
        }
    }

    static def void addDataFlowEdge(CausalGraph graph, Node _source, Node _target, ScenarioDecl _scenario,
        Variable _variable) {
        var edge = graph.edges.filter(DataFlowEdge).findFirst[source == _source && target == _target]
        if (edge === null) {
            edge = createDataFlowEdge
            edge.source = _source
            edge.target = _target
            graph.edges += edge
        }

        var dataRef = edge.dataReferences.findFirst[scenario == _scenario]
        if (dataRef === null) {
            dataRef = createDataReference
            dataRef.scenario = _scenario
            edge.dataReferences += dataRef
        }

        if (!dataRef.variables.contains(_variable)) {
            dataRef.variables += _variable
        }
    }
}
