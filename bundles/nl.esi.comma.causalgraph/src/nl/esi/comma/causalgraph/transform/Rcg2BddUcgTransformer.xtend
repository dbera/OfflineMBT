package nl.esi.comma.causalgraph.transform

import java.util.List
import java.util.ArrayList
import java.util.Map
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.agents.ConfigManager
import nl.esi.comma.causalgraph.utilities.NodeAttributes

import static extension nl.esi.comma.causalgraph.utilities.CausalGraphQueries.*
import nl.esi.comma.causalgraph.agents.MergeAgent
import nl.esi.comma.causalgraph.agents.StepDefinitionAgent
import java.io.File
import java.nio.file.Paths
import java.nio.file.Files

class Rcg2BddUcgTransformer extends Rcg2UcgTransformer {
    
    MergeAgent mergeAgent
    StepDefinitionAgent stepDefinitionAgent
    
    /**
     * Constructor initializes both MergeAgent and StepDefinitionAgent with VendingMachine source files
     */
    new() {
        try {
            val config = ConfigManager.getConfig()
            
            // Automatically discover and load source code files Sources directory
            val sourceCodeFiles = getSourceFiles()
            
            mergeAgent = new MergeAgent(config)
            stepDefinitionAgent = new StepDefinitionAgent(config, sourceCodeFiles)
            System.out.println(String.format("MergeAgent and StepDefinitionAgent initialized successfully in Rcg2BddUcgTransformer"));
            System.out.println(String.format("Loaded %d source code files from VendingMachine Sources directory", sourceCodeFiles.size));
        } catch (Exception e) {
            System.err.println(String.format("Failed to initialize agents: %s", e.getMessage()))
            e.printStackTrace()
        }
    }
    
    /**
     * Discover and return paths to all source code files in the VendingMachine Sources directory
     * @return List of absolute paths to source code files
     */
    private def List<String> getSourceFiles() {
        val sourceCodeFiles = new ArrayList<String>()
        
        try {
            val config = ConfigManager.getConfig()
            System.out.println(String.format("Config loaded: %s", (config !== null ? "yes" : "no")));
            
            val sourcesConfig = config.get("sources") as Map<String, Object>
            System.out.println(String.format("Sources config section: %s", (sourcesConfig !== null ? "found" : "not found")));
            
            var String primaryPath = null
            
            if (sourcesConfig !== null) {
                primaryPath = sourcesConfig.get("source_file_path") as String
                System.out.println(String.format("Raw source_file_path from config: '%s'", primaryPath));
            } else {
                System.err.println(String.format("No [sources] section found in config"))
            }
            
            
            System.out.println(String.format("Using source path: %s", primaryPath));

            val sourcesPath = Paths.get(primaryPath)
            val absoluteSourcesPath = sourcesPath.toAbsolutePath()
            System.out.println(String.format("Absolute path: %s", absoluteSourcesPath.toString));
            System.out.println(String.format("Path exists: %s", Files.exists(sourcesPath)));
            System.out.println(String.format("Is directory: %s", Files.isDirectory(sourcesPath)));
            
            if (Files.exists(sourcesPath) && Files.isDirectory(sourcesPath)) {
                val sourceFiles = Files.list(sourcesPath)
                    .filter[path | Files.isRegularFile(path)]
                    .filter[path | {
                        val fileName = path.fileName.toString.toLowerCase
                        val isSourceFile = fileName.endsWith(".cpp") || fileName.endsWith(".h")
                        System.out.println(String.format("Checking file: %s - is source file: %s", fileName, isSourceFile));
                        return isSourceFile
                    }]
                    .toArray
                    
                System.out.println(String.format("Found %d source files", sourceFiles.length));
                    
                for (sourceFile : sourceFiles) {
                    val absolutePath = (sourceFile as java.nio.file.Path).toAbsolutePath.toString
                    sourceCodeFiles.add(absolutePath)
                    System.out.println(String.format("Added source file: %s", absolutePath));
                }                
                System.out.println(String.format("Successfully discovered %d source files from primary path", sourceCodeFiles.size));
            } else {
                System.err.println(String.format("Sources directory not found or not a directory at: %s", absoluteSourcesPath.toString));
                
                // Try to list parent directory contents for debugging
                try {
                    val parentPath = sourcesPath.parent
                    if (parentPath !== null && Files.exists(parentPath)) {
                        System.err.println(String.format("Parent directory contents:"));
                        Files.list(parentPath).forEach[path | 
                            System.err.println(String.format("  - %s%s", path.fileName, (Files.isDirectory(path) ? " (dir)" : " (file)")))
                        ]
                    }
                } catch (Exception e) {
                    System.err.println(String.format("Could not list parent directory: %s", e.getMessage()))
                }
            }            
        } catch (Exception e) {
            System.err.println(String.format("Error discovering source files: %s", e.getMessage()))
            e.printStackTrace()
        }       
        return sourceCodeFiles
    }
    
    /**
     * Executes the regrouping based upon the MergAgent and afterward sorts the regrouped nodes by their minimum step 
     * number to preserve execution order
     * @param rcgs Variable number of CausalGraph objects to be grouped
     * @return List of NodeGroup objects sorted by step order
     */    
    override protected List<NodeGroup> groupNodes(CausalGraph... rcgs) {
        val nodeGroups = super.groupNodes(rcgs)

        if (mergeAgent !== null) {
            val regroupedNodes = regroupWithLLM(nodeGroups)
            //    
            return sortNodeGroupsByStepOrder(regroupedNodes)
        } else {
            System.err.println(String.format("MergeAgent not available, using default grouping"))
            return sortNodeGroupsByStepOrder(nodeGroups)
        }
    }
    
    /**
     * Regroup nodes based on LLM comparison of step bodies using MergeAgent
     * @param originalGroups List of original NodeGroup objects to be regrouped
     * @return List of regrouped NodeGroup objects
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
        
        System.out.println(String.format("Regrouping completed: %d original groups -> %d new groups", originalGroups.size, newGroups.size));
        return newGroups
    }
    
    /**
     * Process a group with multiple steps using MergeAgent to determine if they should stay together
     * @param originalGroup The NodeGroup to be processed and potentially split
     * @return List of NodeGroup objects after processing with LLM
     */
    private def List<NodeGroup> processGroupWithLLM(NodeGroup originalGroup) {
        val result = new ArrayList<NodeGroup>()
        val stepsToProcess = new ArrayList<Node>(originalGroup.inputNodes)
        
        System.out.println(String.format("Processing group with %d steps using MergeAgent", stepsToProcess.size));
        
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
                    System.out.println(String.format("Step added to existing group %d", bestGroupIndex));
                } else {
                    // Create new group
                    val newGroup = createNewGroupFromStep(stepToCompare, originalGroup.key)
                    result += newGroup
                    System.out.println(String.format("Step created new group %d", result.size - 1));
                }
            }
        }
        
        return result
    }
    
    /**
     * Find the best group for a step by comparing step bodies with MergeAgent
     * Compare with representative step from the group for now we have chosen the first step as a
     * representative of the group (this can be changed in the future)
     * The first group that the LLM determines to be similar enough is returned directly
     * @param stepToCompare The Node step to find a suitable group for
     * @param existingGroups List of existing NodeGroup objects to compare against
     * @return Index of the best matching group, or -1 if no suitable group found
     */
    private def int findBestGroupForStep(Node stepToCompare, List<NodeGroup> existingGroups) {
        val stepStepBody = extractStepBody(stepToCompare)
        
        if (stepStepBody === null || stepStepBody.trim.empty) {
            return -1 // No step body to compare
        }
        
        for (var i = 0; i < existingGroups.size; i++) {
            val group = existingGroups.get(i)
            
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
     * @param step The Node from which to extract the step body
     * @return String representation of the step body, or null if not found
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
     * @param stepBody1 First step body to compare
     * @param stepBody2 Second step body to compare
     * @return true if the step bodies should be merged, false otherwise
     */
    private def boolean shouldMergeStepBodies(String stepBody1, String stepBody2) {
        try {
            val input = #[stepBody1, stepBody2]
            val result = mergeAgent.invoke(input)
            
            if (result !== null) {
                val trimmedResult = result.trim.toLowerCase
                val shouldMerge = trimmedResult.equals("true")
                System.out.println(String.format("MergeAgent comparison result: %s -> %s", result, shouldMerge));
                return shouldMerge
            } else {
                System.err.println(String.format("MergeAgent returned null result"))
                return false
            }
        } catch (Exception e) {
            System.err.println(String.format("Error calling MergeAgent for comparison: %s", e.getMessage()))
            return false
        }
    }
    
    /**
     * Create a new NodeGroup from a single step
     * @param step The Node to create a group from
     * @param originalKey The NodeAttributes key to use for the new group
     * @return A new NodeGroup containing the single step
     */
    private def NodeGroup createNewGroupFromStep(Node step, NodeAttributes originalKey) {
        val nodeList = new ArrayList<Node>()
        nodeList += step
        return new NodeGroup(originalKey, nodeList)
    }
    
    /**
     * Sort node groups by their minimum step number to preserve execution order
     * @param nodeGroups List of NodeGroup objects to be sorted
     * @return List of NodeGroup objects sorted by minimum step number
     */
    private def List<NodeGroup> sortNodeGroupsByStepOrder(List<NodeGroup> nodeGroups) {
        return nodeGroups.sortBy[group |
            group.inputNodes.flatMap[steps].map[stepNumber].min ?: Integer.MAX_VALUE
        ]
    }
    
    /**
     * Merges the scenario steps of a node with the stepDefinitionAgent by generating step definitions and
     * afterward removes the step bodies at the scenario step level since now there is a step body at the node level
     * @param rcgs Variable number of CausalGraph objects to be merged
     * @return The merged CausalGraph with type set to BDDUCG
     */
    override CausalGraph merge(CausalGraph... rcgs) {
        val outputGraph = super.merge(rcgs)
        outputGraph.type = GraphType::BDDUCG
        
        if (stepDefinitionAgent !== null) {
            try {
                System.out.println("Processing merged graph with StepDefinitionAgent...")

                for (node : outputGraph.nodes) {
                    stepDefinitionAgent.processNode(node, outputGraph)
                }
                
                System.out.println("Successfully processed graph with both agents")
                
                cleanupScenarioStepBodies(outputGraph)
                
            } catch (Exception e) {
                System.err.println("Error processing graph with agents: " + e.getMessage())
                e.printStackTrace()
            }
        } else {
            System.err.println(String.format("Agents not available, skipping step definition generation"))
        }

        return outputGraph
    }

    
    /**
     * Clean up step bodies at scenario step level in the graph
     * @param graph The CausalGraph to clean up step bodies from
     */
    private def void cleanupScenarioStepBodies(CausalGraph graph) {
        try {
            for (node : graph.nodes) {
                if (!node.steps.empty) {
                    for (scenarioStep : node.steps) {
                        scenarioStep.stepBody = null
                    }
                }
            }
            
            System.out.println(String.format("Step bodies cleaned up at scenario step level"));
        } catch (Exception e) {
            System.err.println(String.format("Error during step body cleanup: %s", e.getMessage()))
            e.printStackTrace()
        }
    }
}