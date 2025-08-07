package nl.esi.comma.causalgraph.utilities

import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.ControlFlowEdge
import nl.esi.comma.causalgraph.causalGraph.DataFlowEdge
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.ScenarioStep
import nl.esi.comma.causalgraph.causalGraph.DataReference
import nl.esi.comma.causalgraph.causalGraph.Edge

class CausalGraphQueries {
    private new() {
        // Private constructor for utility classes
    }

    static def getGraph(Node node) {
        return node === null ? null : node.eContainer as CausalGraph
    }

    static def getGraph(Edge edge) {
        return edge === null ? null : edge.eContainer as CausalGraph
    }

    static def getNode(ScenarioStep step) {
        return step === null ? null : step.eContainer as Node
    }

    static def getEdge(DataReference dataReference) {
        return dataReference === null ? null : dataReference.eContainer as DataFlowEdge
    }


    static def getIncomingEdges(Node node) {
        val graph = node.graph
        return graph === null ? emptyList : graph.edges.filter[target === node]
    }

    static def getIncomingControlFlows(Node node) {
        node.incomingEdges.filter(ControlFlowEdge)
    }

    static def getIncomingDataFlows(Node node) {
        node.incomingEdges.filter(DataFlowEdge)
    }

    static def getOutgoingEdges(Node node) {
        val graph = node.graph
        return graph === null ? emptyList : graph.edges.filter[source === node]
    }

    static def getOutgoingControlFlows(Node node) {
        node.outgoingEdges.filter(ControlFlowEdge)
    }

    static def getOutgoingDataFlows(Node node) {
        node.outgoingEdges.filter(DataFlowEdge)
    }
}
