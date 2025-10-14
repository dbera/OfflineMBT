package nl.esi.comma.causalgraph.transform

import java.util.List
import java.util.ArrayList
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.agents.ConfigManager
import nl.esi.comma.causalgraph.utilities.NodeAttributes

import static extension nl.esi.comma.causalgraph.utilities.CausalGraphQueries.*
import nl.esi.comma.causalgraph.agents.MergeAgent
import nl.esi.comma.causalgraph.agents.StepDefinitionAgent

class Rcg2BddUcgTransformer extends Rcg2UcgTransformer {
    
    MergeAgent mergeAgent
    StepDefinitionAgent stepDefinitionAgent
    
    /**
     * Constructor initializes both MergeAgent and StepDefinitionAgent
     */
    new() {
        try {
            val config = ConfigManager.getConfig()
            // Initialize both agents with empty source code files for now
            val sourceCodeFiles = new ArrayList<String>()
            mergeAgent = new MergeAgent(config)
            stepDefinitionAgent = new StepDefinitionAgent(config, sourceCodeFiles)
            System.out.println("MergeAgent and StepDefinitionAgent initialized successfully in Rcg2BddUcgTransformer")
        } catch (Exception e) {
            System.err.println("Failed to initialize agents: " + e.getMessage())
            e.printStackTrace()
        }
    }
    
    override protected List<NodeGroup> groupNodes(CausalGraph... rcgs) {
        val nodeGroups = super.groupNodes(rcgs)

        if (mergeAgent !== null) {
            val regroupedNodes = regroupWithLLM(nodeGroups)
            // Sort the regrouped nodes by their minimum step number to preserve execution order
            return sortNodeGroupsByStepOrder(regroupedNodes)
        } else {
            System.err.println("MergeAgent not available, using default grouping")
            return sortNodeGroupsByStepOrder(nodeGroups)
        }
    }
    
    /**
     * Regroup nodes based on LLM comparison of step bodies using MergeAgent
     */
    private def List<NodeGroup> regroupWithLLM(List<NodeGroup> originalGroups) {
        val newGroups = new ArrayList<NodeGroup>()
        
        for (originalGroup : originalGroups) {
            if (originalGroup.inputNodes.size <= 1) {
                newGroups += originalGroup
            } else {
                val regroupedGroups = processGroupWithLLM(originalGroup)
                newGroups.addAll(regroupedGroups)
            }
        }
        
        System.out.println('''Regrouping completed: «originalGroups.size» original groups -> «newGroups.size» new groups''')
        return newGroups
    }
    
    /**
     * Process a group with multiple steps using MergeAgent to determine if they should stay together
     */
    private def List<NodeGroup> processGroupWithLLM(NodeGroup originalGroup) {
        val result = new ArrayList<NodeGroup>()
        val stepsToProcess = new ArrayList<Node>(originalGroup.inputNodes)
        
        System.out.println('''Processing group with «stepsToProcess.size» steps using MergeAgent''')
        
        // Start with the first step as the first group
        if (!stepsToProcess.empty) {
            val firstStep = stepsToProcess.remove(0)
            val currentGroup = createNewGroupFromStep(firstStep, originalGroup.key)
            result += currentGroup
            
            // Compare each remaining step with existing groups
            for (stepToCompare : stepsToProcess) {
                val bestGroupIndex = findBestGroupForStep(stepToCompare, result)
                
                if (bestGroupIndex >= 0) {
                    // Add to existing group
                    result.get(bestGroupIndex).inputNodes += stepToCompare
                    System.out.println('''Step added to existing group «bestGroupIndex»''')
                } else {
                    // Create new group
                    val newGroup = createNewGroupFromStep(stepToCompare, originalGroup.key)
                    result += newGroup
                    System.out.println('''Step created new group «result.size - 1»''')
                }
            }
        }
        
        return result
    }
    
    /**
     * Find the best group for a step by comparing step bodies with MergeAgent
     */
    private def int findBestGroupForStep(Node stepToCompare, List<NodeGroup> existingGroups) {
        val stepStepBody = extractStepBody(stepToCompare)
        
        if (stepStepBody === null || stepStepBody.trim.empty) {
            return -1 // No step body to compare
        }
        
        for (var i = 0; i < existingGroups.size; i++) {
            val group = existingGroups.get(i)
            
            // Compare with representative step from the group (first step)
            if (!group.inputNodes.empty) {
                val representativeNode = group.inputNodes.get(0)
                val representativeStepBody = extractStepBody(representativeNode)
                
                if (representativeStepBody !== null && !representativeStepBody.trim.empty) {
                    if (shouldMergeStepBodies(stepStepBody, representativeStepBody)) {
                        return i // Returns the group immediately on the first match
                    }
                }
            }
        }
        
        return -1 // No suitable group found
    }
    
    /**
     * Extract step body from a step
     */
    private def String extractStepBody(Node step) {
        if (step.stepBody !== null) {
            return step.stepBody.toString
        } else if (!step.steps.empty && step.steps.get(0).stepBody !== null) {
            return step.steps.get(0).stepBody.toString
        }
        return null
    }
    
    /**
     * Use MergeAgent to determine if two step bodies should be merged
     */
    private def boolean shouldMergeStepBodies(String stepBody1, String stepBody2) {
        try {
            val input = #[stepBody1, stepBody2]
            val result = mergeAgent.invoke(input)
            
            if (result !== null) {
                val trimmedResult = result.trim.toLowerCase
                val shouldMerge = trimmedResult.equals("true")
                System.out.println('''MergeAgent comparison result: «result» -> «shouldMerge»''')
                return shouldMerge
            } else {
                System.err.println("MergeAgent returned null result")
                return false
            }
        } catch (Exception e) {
            System.err.println("Error calling MergeAgent for comparison: " + e.getMessage())
            return false
        }
    }
    
    /**
     * Create a new NodeGroup from a single step
     */
    private def NodeGroup createNewGroupFromStep(Node step, NodeAttributes originalKey) {
        val nodeList = new ArrayList<Node>()
        nodeList += step
        return new NodeGroup(originalKey, nodeList)
    }
    
    /**
     * Sort node groups by their minimum step number to preserve execution order
     */
    private def List<NodeGroup> sortNodeGroupsByStepOrder(List<NodeGroup> nodeGroups) {
        return nodeGroups.sortBy[group |
            // Find the minimum step number across all scenarios in this group
            group.inputNodes.flatMap[steps].map[stepNumber].min ?: Integer.MAX_VALUE
        ]
    }
    
    override CausalGraph merge(CausalGraph... rcgs) {
        val outputGraph = super.merge(rcgs)
        outputGraph.type = GraphType::BDDUCG
        System.out.println('''outputGraph «outputGraph»''')
        
        // Process the merged graph with both agents
        if (stepDefinitionAgent !== null) {
            try {
                System.out.println("Processing merged graph with StepDefinitionAgent...")
                
                // Process each node with the agents
                for (node : outputGraph.nodes) {
                    // Use StepDefinitionAgent to process the node and generate step definitions
                    stepDefinitionAgent.processNode(node, outputGraph)
                }
                
                System.out.println("Successfully processed graph with both agents")
                
                // Clean up step bodies at scenario step level after agent processing
                cleanupScenarioStepBodies(outputGraph)
                
            } catch (Exception e) {
                System.err.println("Error processing graph with agents: " + e.getMessage())
                e.printStackTrace()
            }
        } else {
            System.err.println("Agents not available, skipping step definition generation")
        }

        return outputGraph
    }

    
    /**
     * Clean up step bodies at scenario step level in the graph
     */
    private def void cleanupScenarioStepBodies(CausalGraph graph) {
        try {
            for (node : graph.nodes) {
                // Clear step bodies from all scenario steps (the nested steps within each node)
                if (!node.steps.empty) {
                    for (scenarioStep : node.steps) {
                        scenarioStep.stepBody = null
                    }
                }
            }
            
            System.out.println("Step bodies cleaned up at scenario step level")
        } catch (Exception e) {
            System.err.println("Error during step body cleanup: " + e.getMessage())
            e.printStackTrace()
        }
    }
}