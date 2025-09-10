package nl.esi.comma.causalgraph.utilities

import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.ControlFlowEdge
import nl.esi.comma.causalgraph.causalGraph.DataFlowEdge
import nl.esi.comma.causalgraph.causalGraph.DataReference
import nl.esi.comma.causalgraph.causalGraph.Edge
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.ScenarioDecl
import nl.esi.comma.causalgraph.causalGraph.ScenarioStep
import nl.esi.comma.causalgraph.causalGraph.StepVariable
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import nl.esi.comma.causalgraph.causalGraph.RequirementDecl

class CausalGraphQueries {
    private new() {
        // Private constructor for utility classes
    }

    static def getGraphType(String fileExtension) {
        return GraphType.getByName(fileExtension)
    }

    static def GraphType getType(CausalGraph graph) {
        return getGraphType(graph.eResource?.URI?.fileExtension)
    }

    static def void setType(CausalGraph graph, GraphType type) {
        if (type === null) {
            throw new IllegalArgumentException('Graph type cannot be null')
        } else if (graph.type != type) {
            val uri = URI.createURI(graph.name ?: 'unknown').appendFileExtension(type.getName)
            val resource = Resource.Factory.Registry.INSTANCE.getFactory(uri).createResource(uri)
            resource.contents += graph
        }
    }

    static def getSteps(CausalGraph graph, ScenarioDecl _scenario) {
        return graph.nodes.flatMap[steps].filter[scenario == _scenario].sortBy[stepNumber]
    }

    static def getGraph(RequirementDecl requirement) {
        return requirement === null ? null : requirement.eContainer as CausalGraph
    }

    static def getGraph(ScenarioDecl scenario) {
        return scenario === null ? null : scenario.eContainer as CausalGraph
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

    static def isRead(StepVariable stepVariable) {
        return switch (stepVariable.access) {
            case READ,
            case READ_WRITE: true
            default: false
        }
    }

    static def isWrite(StepVariable stepVariable) {
        return switch (stepVariable.access) {
            case WRITE,
            case READ_WRITE: true
            default: false
        }
    }
}
