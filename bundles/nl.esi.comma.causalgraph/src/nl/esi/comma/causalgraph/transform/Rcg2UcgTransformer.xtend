package nl.esi.comma.causalgraph.transform

import java.util.List
import java.util.Set
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.CausalGraphFactory
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.StepType
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.types.types.NamedElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.EcoreUtil2

import static extension nl.esi.comma.causalgraph.utilities.CausalGraphQueries.*
import static extension org.eclipse.lsat.common.xtend.Queries.*

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

            requirements += rcgs.flatMap[requirements].resolveNameConflicts(true, true)
            scenarios += rcgs.flatMap[scenarios].resolveNameConflicts(false, true)

            types += rcgs.flatMap[types].resolveNameConflicts(true, true)
            variables += rcgs.flatMap[variables].resolveNameConflicts(true, false)
        ]

        // Important: grouping nodes should be done after merging the variables!
        val nodeGroups = rcgs.groupNodes

        // All add output nodes to the merged graph
        nodeGroups.forEach[group, index |
            group.outputNode.name = 'n' + index
            mergedGraph.nodes += group.outputNode
        ]

        // Now create the content and edges of the output nodes
        for (group : nodeGroups) {
            // Just move all the steps from the group to the output node
            group.outputNode.steps += group.inputNodes.flatMap[steps].toList

            // Get all the original control flows and group them based on their output node, i.e. resolveOne()
            val controlFlows = group.inputNodes.flatMap[outgoingControlFlows].groupBy[nodeGroups.resolveOne(target)]
            controlFlows.keySet.forEach[ targetNode |
                mergedGraph.edges += createControlFlowEdge => [
                    source = group.outputNode
                    target = targetNode
                ]
            ]

            // Get all the original data flows and group them based on their output node
            val dataFlows = group.inputNodes.flatMap[outgoingDataFlows].groupBy[nodeGroups.resolveOne(target)]
            dataFlows.entrySet.forEach[ dfEntry |
                mergedGraph.edges += createDataFlowEdge => [
                    source = group.outputNode
                    target = dfEntry.key
                    dataReferences += dfEntry.value.flatMap[dataReferences].toList
                ]
            ]
        }

        return mergedGraph
    }

    def protected List<NodeGroup> groupNodes(CausalGraph... rcgs) {
        val nodeGroupsMap = rcgs.flatMap[nodes].groupBy[groupKey]
        // The asserts that are not functions should not be matched by their step-name,
        // we need to look at their incoming data dependencies to find possible matches.
        val nonFunctionAsserts = nodeGroupsMap.filter[k, v |!k.function && k.stepType == StepType::THEN].values.flatten.toList
        nonFunctionAsserts.forEach[assertNode | nodeGroupsMap.remove(assertNode.groupKey)]

        val nodeGroups = nodeGroupsMap.entrySet.map[new NodeGroup(key, value)].toList

        val assertGroups = nonFunctionAsserts.groupBy[assertGroupKey].values.sortedBy[size]
        for (assertGroup : assertGroups) {
            val stepName = assertGroup.map[stepName].toSet.join(', ')
            var groupKey = new NodeGroupKey(false, stepName, StepType::THEN)
            nodeGroups += new NodeGroup(groupKey, assertGroup)
        }

        nodeGroups.groupBy[key].filter[k, v|v.size > 1].forEach [k, v |
            System.err.println('''Found «v.size» overlapping nodes for «k»''')
        ]
        return nodeGroups
    }

    private static def <T extends NamedElement> Iterable<T> resolveNameConflicts(Iterable<T> elements, boolean merge, boolean rename) {
        val mergedElements = newLinkedHashMap
        val conflicts = newLinkedHashSet
        for (element : elements) {
            val registered = mergedElements.putIfAbsent(element.name, element)
            if (registered !== null && registered !== element) {
                if(merge && EcoreUtil.equals(registered, element)) {
                    // These elements can be merged, update all references to use the registered element
                    element.graph.replaceAllReferences(element, registered)
                } else if (rename) {
                    // Found a conflicting type, use different names for the elements
                    registered.name = registered.graph.name + '_' + registered.name
                    mergedElements.put(registered.name, registered)
                    element.name = element.graph.name + '_' + element.name
                    mergedElements.put(element.name, element)
                } else {
                    // We cannot do anything alse then add the conflict, 
                    // this will result in a non-validating model
                    conflicts += element
                }
            }
        }
        return mergedElements.values.union(conflicts).toSet
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

    /**
     * When asserts use the same variables form the same nodes, they can be (potentially) merged.
     */
    protected def getAssertGroupKey(Node node) {
        return node.outgoingDataFlows.map[ edge |
            new AssertGroupKey(edge.target.groupKey, edge.dataReferences.flatMap[variables].toSet)
        ].toSet
    }

    @Data
    protected static class AssertGroupKey {
        val NodeGroupKey key
        val Set<Variable> variables
    }

    protected def Node resolveOne(List<NodeGroup> nodeGroups, Node node) {
        return nodeGroups.findFirst[inputNodes.contains(node)]?.outputNode
    }

    protected def NodeGroupKey getGroupKey(Node node) {
        return new NodeGroupKey(node.function, node.stepName, node.stepType)
    }

    @Data
    protected static class NodeGroupKey {
        val boolean function
        val String stepName
        val StepType stepType
    }

    @Accessors
    protected static class NodeGroup {
        val NodeGroupKey key
        val List<Node> inputNodes = newArrayList()
        val Node outputNode

        new(NodeGroupKey _key, Iterable<Node> _inputNodes) {
            key = _key;
            inputNodes += _inputNodes
            outputNode = CausalGraphFactory::eINSTANCE.createNode => [ node |
                node.function = _key.function
                node.stepName = _key.stepName
                node.stepType = _key.stepType
            ]
        }
    }
}
