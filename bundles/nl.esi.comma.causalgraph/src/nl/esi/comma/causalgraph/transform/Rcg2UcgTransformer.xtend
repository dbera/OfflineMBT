package nl.esi.comma.causalgraph.transform

import java.util.List
import java.util.Map
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.CausalGraphFactory
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.StepType
import nl.esi.comma.types.types.NamedElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.EcoreUtil2

import static extension nl.esi.comma.causalgraph.utilities.CausalGraphQueries.*
import static extension org.eclipse.lsat.common.xtend.Queries.*
import nl.esi.comma.types.utilities.EcoreUtil3
import nl.esi.comma.expressions.expression.Variable

class Rcg2UcgTransformer {
    static extension val CausalGraphFactory m_cg = CausalGraphFactory::eINSTANCE

    def CausalGraph merge(CausalGraph... rcgs) {
        if (rcgs.exists[type != GraphType.RCG]) {
            throw new IllegalArgumentException('Expected ' + GraphType.RCG.literal)
        } else if (rcgs.map[name].toSet.size != rcgs.size) {
            throw new IllegalArgumentException('Graphs should have unique names')
        }
        rcgs.forEach[EcoreUtil.resolveAll(it)]

        // Prepare the merged graph, just copy the imports, requirements and scenarios
        val mergedGraph = createCausalGraph => [
            name = rcgs.join('__')[name]
            type = GraphType::UCG
            // TODO: should imports be made unique? Or should the merged graph 
            // just not have any imports, but just inline the used types?
            imports += rcgs.flatMap[imports].toList

            requirements += rcgs.flatMap[requirements].resolveNameConflicts(true)
            scenarios += rcgs.flatMap[scenarios].resolveNameConflicts(false)

            types += rcgs.flatMap[types].resolveNameConflicts(true)
            variables += rcgs.flatMap[variables].resolveNameConflicts(true)
        ]

        val nodeGroups = rcgs.groupNodes

        // Create the merged nodes for all node groups
        val mergedNodes = newHashMap
        nodeGroups.keySet.forEach [ groupKey, index |
            val mergedNode = createNode => [
                name = 'n' + index
                stepName = groupKey.stepName
                stepType = groupKey.stepType
            ]
            mergedNodes.put(groupKey, mergedNode)
            mergedGraph.nodes += mergedNode
        ]

        // Now create the content and edges of the merged nodes
        for (ngEntry : nodeGroups.entrySet) {
            val mergedNode = mergedNodes.get(ngEntry.key)
            // Just move all the steps from the group to the merged target
            mergedNode.steps += ngEntry.value.flatMap[steps].toList

            // Get all the original control flows and group them based on their merged target node
            val controlFlows = ngEntry.value.flatMap[outgoingControlFlows].groupBy[mergedNodes.get(target.groupKey)]
            controlFlows.keySet.forEach[ targetNode |
                mergedGraph.edges += createControlFlowEdge => [
                    source = mergedNode
                    target = targetNode
                ]
            ]

            // Get all the original data flows and group them based on their merged target node
            val dataFlows = ngEntry.value.flatMap[outgoingDataFlows].groupBy[mergedNodes.get(target.groupKey)]
            dataFlows.entrySet.forEach[ dfEntry |
                mergedGraph.edges += createDataFlowEdge => [
                    source = mergedNode
                    target = dfEntry.key
                    dataReferences += dfEntry.value.flatMap[dataReferences].toList
                ]
            ]
        }

        return mergedGraph
    }

    def protected Map<NodeGroupKey, List<Node>> groupNodes(CausalGraph... rcgs) {
        // TODO: Refine grouping for 'Then' nodes
        return rcgs.flatMap[nodes].groupBy[groupKey]
    }

    private static def <T extends NamedElement> Iterable<T> resolveNameConflicts(Iterable<T> elements, boolean merge) {
        val mergedElements = newLinkedHashMap
        for (element : elements) {
            val registered = mergedElements.putIfAbsent(element.name, element)
            if (registered !== null) {
                if(merge && EcoreUtil.equals(registered, element)) {
                    // These elements can be merged, update all references to use the registered element
                    element.graph.replaceAllReferences(element, registered)
                } else {
                    // Found a conflicting type, use different names for the elements
                    registered.name = registered.graph.name + '_' + registered.name
                    mergedElements.put(registered.name, registered)
                    element.name = element.graph.name + '_' + element.name
                    mergedElements.put(element.name, element)
                }
            }
        }
        return mergedElements.values.toSet
    }

    private static def getGraph(EObject eObject) {
        return EcoreUtil2.getContainerOfType(eObject, CausalGraph)
    }

    private static def replaceAllReferences(EObject root, EObject from, EObject to) {
        for (eObject : root.eAllContents.toIterable.union(root)) {
            val eReferences = eObject.eClass.EAllReferences
                .reject[containment]
                .filter[changeable && EReferenceType.isInstance(from) && EReferenceType.isInstance(to)]
            for (eReference : eReferences) {
                if (eReference.isMany) {
                    val value = eObject.eGet(eReference) as List
                    var i = -1
                    while ((i = value.indexOf(from)) >= 0) {
                        value.set(i, to)
                    }
                } else if (eObject.eGet(eReference) == from) {
                    eObject.eSet(eReference, to)
                }
            }
        }
    }

    protected def getGroupKey(Node node) {
        return new NodeGroupKey(node.stepName, node.stepType)
    }

    @Data
    protected static class NodeGroupKey {
        val String stepName
        val StepType stepType
    }
}
