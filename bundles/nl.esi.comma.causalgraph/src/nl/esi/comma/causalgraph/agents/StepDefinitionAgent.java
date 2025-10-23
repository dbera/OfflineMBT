package nl.esi.comma.causalgraph.agents;

import java.util.*;
import java.util.stream.Collectors;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.azure.AzureOpenAiChatModel;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;

import nl.esi.comma.causalgraph.causalGraph.*;
import nl.esi.comma.causalgraph.utilities.CausalGraphQueries;
import nl.esi.comma.causalgraph.utilities.VariableHelper;
import nl.esi.comma.expressions.expression.Variable;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionFactory;
import nl.esi.comma.types.types.Type;
import nl.esi.comma.types.types.TypeDecl;
import nl.esi.comma.types.types.TypeReference;
import nl.esi.comma.types.types.TypesFactory;
import nl.esi.comma.types.BasicTypes;
import org.eclipse.emf.common.util.EList;

/**
 * StepDefinitionAgent class for processing causal graph nodes and generating step definitions.
 * This class analyzes causal graph nodes, analyzes data dependencies, and uses LLM to generate
 * parameterized step definitions for similar code snippets.
 */
public class StepDefinitionAgent {    
    private ChatModel llm;
    private Map<String, String> sourceCode;
    private ObjectMapper objectMapper;
    
    /**
     * Initialize the StepDefinitionAgent with the provided configuration.
     *
     * @param config The configuration map
     * @param sourceCodeFiles List of paths to source code files for reference
     */
    public StepDefinitionAgent(Map<String, Object> config, List<String> sourceCodeFiles) {
        this.objectMapper = new ObjectMapper();
        this.sourceCode = loadSourceCode(sourceCodeFiles);
        
        try {
            System.out.println("StepDefinitionAgent constructor started");
            
            @SuppressWarnings("unchecked")
            Map<String, Object> gptConfig = (Map<String, Object>) config.get("gpt");
            System.out.println(String.format("GPT Config: %s", gptConfig));
            
            String azureEndpoint = gptConfig != null ? (String) gptConfig.get("endpoint") : null;
            String azureApiKey = gptConfig != null ? (String) gptConfig.get("api_key") : null;
            String llmModel = gptConfig != null ? (String) gptConfig.get("llm") : null;
            String apiVersion = gptConfig != null ? (String) gptConfig.get("version") : null;
            String temperatureStr = gptConfig != null ? (String) gptConfig.get("temperature") : null;
            Float temperature = temperatureStr != null ? Float.parseFloat(temperatureStr) : 1.0f;

            if (azureEndpoint != null && azureApiKey != null) {
                System.out.println("Configuration validated successfully");
                this.llm = initializeLLM(llmModel, apiVersion, temperature, azureEndpoint, azureApiKey);
                System.out.println("StepDefinitionAgent constructor completed successfully");
            } else {
                System.err.println("Missing required configuration");
            }
            
        } catch (Exception e) {
            System.err.println(String.format("Error in StepDefinitionAgent constructor: %s", e.getMessage()));
            e.printStackTrace();
        }
    }

    /**
     * Load source code files for reference.
     *
     * @param sourceCodeFiles List of paths to source code files
     * @return Map of filename to file content
     */
    private Map<String, String> loadSourceCode(List<String> sourceCodeFiles) {
        Map<String, String> sourceCodeMap = new HashMap<>();
        if (sourceCodeFiles != null) {
            for (String path : sourceCodeFiles) {
                try {
                    String content = Files.readString(Paths.get(path));
                    sourceCodeMap.put(path, content);
                } catch (IOException e) {
                    sourceCodeMap.put(path, String.format("// %s not found", path));
                }
            }
        }
        return sourceCodeMap;
    }

    /**
     * Initialize the LLM with the specified model and API version using LangChain4j.
     * 
     * @param llmModel The LLM model name
     * @param apiVersion The API version
     * @param temperature The temperature setting for the model
     * @param azureEndpoint The Azure OpenAI endpoint
     * @param azureApiKey The Azure OpenAI API key
     * @return The initialized ChatModel instance
     */
    private ChatModel initializeLLM(String llmModel, String apiVersion, Float temperature, String azureEndpoint, String azureApiKey) {
        System.out.println("initializeLLM called with parameters:");
        System.out.println(String.format("  llmModel: %s", llmModel));
        System.out.println(String.format("  apiVersion: %s", apiVersion));
        System.out.println(String.format("  temperature: %s", temperature));
        
        if (azureEndpoint == null || azureApiKey == null) {
            System.err.println("Azure OpenAI configuration missing");
            return null;
        }
   
        try {
            System.out.println("Starting AzureOpenAiChatModel creation...");
            ChatModel model = AzureOpenAiChatModel.builder()
                .endpoint(azureEndpoint)
                .serviceVersion(apiVersion)
                .apiKey(azureApiKey)
                .deploymentName(llmModel != null ? llmModel : "gpt-4")
                .temperature(temperature != null ? temperature : 1.0)
                .timeout(java.time.Duration.ofSeconds(30))
                .maxRetries(3)
                .build();
                
            System.out.println("AzureOpenAiChatModel created successfully");
            return model;
            
        } catch (Exception e) {
            System.err.println(String.format("Error creating AzureOpenAiChatModel: %s", e.getMessage()));
            e.printStackTrace();
            return null;
        }
    }

    /**
     * Process a node in the causal graph to generate step definitions by using the initialized variables,
     * source code, and scenario steps based upon data dependencies. TO DO source code should be added to the prompt.
     * 
     * @param node The node to process
     * @param graph The complete causal graph
     */
    public void processNode(Node node, CausalGraph graph) {
        if (this.llm == null) {
            System.err.println("LLM not initialized");
            return;
        }

        try {
            System.out.println(String.format("Processing node: %s", node.getName()));
            
            List<ScenarioStepInfo> scenarioSteps = extractNodeScenarios(node);
            
            if (scenarioSteps.isEmpty()) {
                System.out.println(String.format("No scenario steps found for node: %s", node.getName()));
                return;
            }

            Map<String, String> variables = extractVariables(graph);
            Map<String, Object> variableInitialValues = extractVariableInitialValues(graph);
            
            System.out.println(String.format("Extracted %d variables from graph", variables.size()));
            System.out.println(String.format("Extracted %d variable initial values from graph", variableInitialValues.size()));

            Map<String, List<ScenarioStepInfo>> previousCGSteps = extractPreviousStepsWithDataDependencies(node, graph);

            StepDefinition stepDefinition = generateStepDefinitions(
                scenarioSteps, variables, variableInitialValues, previousCGSteps);

            if (stepDefinition != null) {
                applyStepDefinitionToNode(node, stepDefinition);
                System.out.println(String.format("Applied complete step definition '%s' to node %s", stepDefinition.stepName, node.getName()));
            }
            
        } catch (Exception e) {
            System.err.println(String.format("Error processing node %s: %s", node.getName(), e.getMessage()));
            e.printStackTrace();
        }
    }
 
    /**
     * Extract scenario information from a single node.
     *
     * @param node The causal graph
     * @return Map of node name to list of scenario step information
     */
    private List<ScenarioStepInfo> extractNodeScenarios(Node node) {
        List<ScenarioStepInfo> scenarioSteps = new ArrayList<>();
        
        for (ScenarioStep step : node.getSteps()) {
            ScenarioStepInfo stepInfo = new ScenarioStepInfo();
            stepInfo.scenarioId = step.getScenario().getName();
            stepInfo.stepNumber = String.valueOf(step.getStepNumber());
            stepInfo.stepType = node.getStepType().toString();
            
            stepInfo.stepBody = step.getStepBody() != null ? extractStepBodyContent(step.getStepBody()) : 
                               (node.getStepBody() != null ? extractStepBodyContent(node.getStepBody()) : "");
            scenarioSteps.add(stepInfo);
        }
        
        return scenarioSteps;
    }

    
    /**
     * Extract variables from the causal graph.
     *
     * @param graph The causal graph
     * @return Map of variable names to their types
     */
    private Map<String, String> extractVariables(CausalGraph graph) {
        Map<String, String> variables = new HashMap<>();
        
        
        if (graph.getVariables() != null) {
            for (Variable variable : graph.getVariables()) {
                variables.put(variable.getName(), variable.getType().toString());
                System.out.println(String.format("Extracted variable: %s of type %s", variable.getName(), variable.getType().toString()));
            }
        }
        
        return variables;
    }

    /**
     * Extract variable initial values from the causal graph.
     *
     * @param graph The causal graph
     * @return Map of variable names to their initial values
     */
    private Map<String, Object> extractVariableInitialValues(CausalGraph graph) {
        Map<String, Object> variableInitialValues = new HashMap<>();
        
        if (graph.getAssignments() != null) {
            for (nl.esi.comma.actions.actions.AssignmentAction assignment : graph.getAssignments()) {
                try {
                    Variable assignedVariable = assignment.getAssignment();
                    if (assignedVariable != null) {
                        String varName = assignedVariable.getName();
                        
                        Expression assignmentExpression = assignment.getExp();
                        if (assignmentExpression != null) {
                            Object assignmentValue = extractExpressionValue(assignmentExpression);
                            if (assignmentValue != null) {
                                if (!variableInitialValues.containsKey(varName)) {
                                    variableInitialValues.put(varName, assignmentValue);
                                    System.out.println(String.format("Extracted initial value from assignment: %s = %s", varName, assignmentValue));
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    System.err.println(String.format("Error processing assignment: %s", e.getMessage()));
                }
            }
        }
            
        System.out.println(String.format("Total variable initial values extracted: %d", variableInitialValues.size()));
        return variableInitialValues;
    }
    
    /**
     * Extract a concrete value from an Expression object.
     * This method handles different types of constant expressions.
     *
     * @param expression The expression to extract value from
     * @return The extracted value, or null if not a constant expression
     */
    private Object extractExpressionValue(Expression expression) {
        if (expression == null) {
            return null;
        }
        
        try {
            if (expression instanceof nl.esi.comma.expressions.expression.ExpressionConstantInt) {
                nl.esi.comma.expressions.expression.ExpressionConstantInt intExpr = 
                    (nl.esi.comma.expressions.expression.ExpressionConstantInt) expression;
                return intExpr.getValue();
            }
            
            if (expression instanceof nl.esi.comma.expressions.expression.ExpressionConstantReal) {
                nl.esi.comma.expressions.expression.ExpressionConstantReal realExpr = 
                    (nl.esi.comma.expressions.expression.ExpressionConstantReal) expression;
                return realExpr.getValue();
            }
            
            if (expression instanceof nl.esi.comma.expressions.expression.ExpressionConstantString) {
                nl.esi.comma.expressions.expression.ExpressionConstantString stringExpr = 
                    (nl.esi.comma.expressions.expression.ExpressionConstantString) expression;
                return stringExpr.getValue();
            }
            
            if (expression instanceof nl.esi.comma.expressions.expression.ExpressionConstantBool) {
                nl.esi.comma.expressions.expression.ExpressionConstantBool boolExpr = 
                    (nl.esi.comma.expressions.expression.ExpressionConstantBool) expression;
                return boolExpr.isValue();
            }
            
            if (expression instanceof nl.esi.comma.expressions.expression.ExpressionVariable) {
                nl.esi.comma.expressions.expression.ExpressionVariable varExpr = 
                    (nl.esi.comma.expressions.expression.ExpressionVariable) expression;
                if (varExpr.getVariable() != null) {
                    return varExpr.getVariable().getName();
                }
            }
            
            // For other expression types, return a string representation for now
            System.out.println(String.format("Unsupported expression type for value extraction: %s", expression.getClass().getSimpleName()));
            return expression.toString();
            
        } catch (Exception e) {
            System.err.println(String.format("Error extracting value from expression: %s", e.getMessage()));
            return null;
        }
    }


    /**
     * Extract previous steps from the same scenarios that have data dependencies with the current node.
     *
     * @param currentNode The current node being processed
     * @param graph The complete causal graph
     * @return Map of scenario names to lists of previous step information that have data dependencies
     */
    private Map<String, List<ScenarioStepInfo>> extractPreviousStepsWithDataDependencies(Node currentNode, CausalGraph graph) {
        Map<String, List<ScenarioStepInfo>> previousSteps = new HashMap<>();
        
        try {
            Set<String> currentScenarios = currentNode.getSteps().stream()
                .map(step -> step.getScenario().getName())
                .collect(Collectors.toSet());
            
            System.out.println(String.format("Current node %s has scenarios: %s", currentNode.getName(), currentScenarios));
            
            // Get variables that this node needs from other nodes via outgoing data flows
            // Note: outgoing data flows indicate dependencies - the current node needs data from the target
            // In causal graph file for the data flow, n4 -> n3 means that n4 needs data from n3
            Set<String> requiredVariables = new HashSet<>();
            Set<Node> dependencySourceNodes = new HashSet<>();
            
            List<DataFlowEdge> outgoingDataFlows = new ArrayList<>();
            CausalGraphQueries.getOutgoingDataFlows(currentNode).forEach(outgoingDataFlows::add);
            
            for (DataFlowEdge dataFlow : outgoingDataFlows) {
                if (dataFlow.getDataReferences() != null) {
                    for (DataReference dataRef : dataFlow.getDataReferences()) {
                        if (dataRef.getVariables() != null) {
                            for (Variable variable : dataRef.getVariables()) {
                                requiredVariables.add(variable.getName());
                                dependencySourceNodes.add(dataFlow.getTarget());
                            }
                        }
                    }
                }
            }
            
            System.out.println(String.format("Node %s requires variables from other nodes: %s", currentNode.getName(), requiredVariables));
            System.out.println(String.format("Dependency source nodes: %s", dependencySourceNodes.stream().map(Node::getName).collect(Collectors.toList())));
            
            if (requiredVariables.isEmpty()) {
                System.out.println(String.format("No data flow dependencies found for node %s", currentNode.getName()));
                return previousSteps;
            }
            
            // For each scenario in the current node, find previous steps that provide required variables
            for (String scenarioName : currentScenarios) {
                List<ScenarioStepInfo> relevantPreviousSteps = new ArrayList<>();
                
                // Get the current node's step number for this scenario
                int currentStepNumber = currentNode.getSteps().stream()
                    .filter(step -> step.getScenario().getName().equals(scenarioName))
                    .mapToInt(ScenarioStep::getStepNumber)
                    .min().orElse(Integer.MAX_VALUE);
                
                System.out.println(String.format("Looking for previous steps before step %d in scenario %s", currentStepNumber, scenarioName));
                
                // Check dependency source nodes to see if they are previous steps in this scenario
                for (Node sourceNode : dependencySourceNodes) {
                    // Check if this source node participates in the same scenario
                    boolean participatesInScenario = sourceNode.getSteps().stream()
                        .anyMatch(step -> step.getScenario().getName().equals(scenarioName));
                    
                    if (!participatesInScenario) {
                        continue;
                    }
                    
                    // Get the source node's step number for this scenario
                    int sourceStepNumber = sourceNode.getSteps().stream()
                        .filter(step -> step.getScenario().getName().equals(scenarioName))
                        .mapToInt(ScenarioStep::getStepNumber)
                        .min().orElse(Integer.MAX_VALUE);
                    
                    if (sourceStepNumber >= currentStepNumber) {
                        continue;
                    }
                    
                    // Verify there's an actual data flow from this source to current node
                    boolean hasDataFlow = false;
                    List<DataFlowEdge> currentNodeOutgoingFlows = new ArrayList<>();
                    CausalGraphQueries.getOutgoingDataFlows(currentNode).forEach(currentNodeOutgoingFlows::add);
                    
                    for (DataFlowEdge dataFlow : currentNodeOutgoingFlows) {
                        if (dataFlow.getTarget() == sourceNode && dataFlow.getDataReferences() != null) {
                            for (DataReference dataRef : dataFlow.getDataReferences()) {
                                if (dataRef.getVariables() != null) {
                                    for (Variable variable : dataRef.getVariables()) {
                                        if (requiredVariables.contains(variable.getName())) {
                                            hasDataFlow = true;
                                            System.out.println(String.format("Found data dependency: current node %s needs %s from %s", currentNode.getName(), variable.getName(), sourceNode.getName()));
                                            break;
                                        }
                                    }
                                }
                                if (hasDataFlow) break;
                            }
                            if (hasDataFlow) break;
                        }
                    }
                    
                    if (hasDataFlow) {
                        ScenarioStep sourceScenarioStep = sourceNode.getSteps().stream()
                            .filter(step -> step.getScenario().getName().equals(scenarioName))
                            .findFirst().orElse(null);
                        
                        if (sourceScenarioStep != null) {
                            ScenarioStepInfo stepInfo = new ScenarioStepInfo();
                            stepInfo.scenarioId = scenarioName;
                            stepInfo.stepNumber = String.valueOf(sourceScenarioStep.getStepNumber());
                            stepInfo.stepType = sourceNode.getStepType() != null ? sourceNode.getStepType().toString() : "unknown";
                            stepInfo.stepBody = sourceScenarioStep.getStepBody() != null ? 
                                extractStepBodyContent(sourceScenarioStep.getStepBody()) : 
                                (sourceNode.getStepBody() != null ? extractStepBodyContent(sourceNode.getStepBody()) : "");
                            
                            relevantPreviousSteps.add(stepInfo);
                            System.out.println(String.format("Added previous step: scenario %s step %s", scenarioName, stepInfo.stepNumber));
                        }
                    }
                }
                
                if (!relevantPreviousSteps.isEmpty()) {
                    previousSteps.put(scenarioName, relevantPreviousSteps);
                    System.out.println(String.format("Found %d previous steps with data dependencies for scenario %s", relevantPreviousSteps.size(), scenarioName));
                }
            }
            
            System.out.println(String.format("Total previous overlay steps with data dependencies: %d", previousSteps.values().stream().mapToInt(List::size).sum()));
            
        } catch (Exception e) {
            System.err.println(String.format("Error extracting previous steps with data dependencies: %s", e.getMessage()));
            e.printStackTrace();
        }
        
        return previousSteps;
    }
    

    /**
     * Generate step definitions using LLM for similar scenario steps.
     * 
     * @param scenarioSteps List of scenario steps from the current node
     * @param variables Map of variable names to types
     * @param variableInitialValues Map of variable names to their initial values
     * @param previousScenarioSteps Map of scenario names to lists of previous step information with data dependencies
     * @return The generated step definition object with the step name, arguments, parameters, and body
     */
    private StepDefinition generateStepDefinitions(
            List<ScenarioStepInfo> scenarioSteps,
            Map<String, String> variables,
            Map<String, Object> variableInitialValues,
            Map<String, List<ScenarioStepInfo>> previousScenarioSteps) {
        
        StepDefinition stepDef = new StepDefinition();
        
        List<SystemMessages.Scenario> scenarios = scenarioSteps.stream()
            .map(step -> new SystemMessages.Scenario(step.scenarioId, step.stepNumber, step.stepBody))
            .collect(Collectors.toList());

        String stepNamePrompt = SystemMessages.generateStepNamePrompt(scenarios);
        String stepNameResponse = this.llm.chat(stepNamePrompt);
        String stepName = stepNameResponse.trim();

        if (scenarios.size() == 1) {
            // Single scenario - simple case no parameterization needed
            stepDef.stepName = stepName;
            stepDef.stepArguments = new HashMap<>();
            stepDef.stepParameters = new HashMap<>();
            stepDef.stepBody = scenarios.get(0).getStepBody();
            stepDef.stepType = scenarioSteps.get(0).stepType;
        } else {
            // Multiple scenarios
            String firstStepBody = scenarios.get(0).getStepBody();
            boolean allSameBody = scenarios.stream()
                .allMatch(scenario -> scenario.getStepBody().equals(firstStepBody));

            if (allSameBody) {
                // All have same body - no parameterization needed
                stepDef.stepName = stepName;
                stepDef.stepArguments = new HashMap<>();
                stepDef.stepParameters = new HashMap<>();
                stepDef.stepBody = firstStepBody;
                stepDef.stepType = scenarioSteps.get(0).stepType;
            } else {
                // Different bodies - need LLM to parameterize
                Map<String, List<SystemMessages.Scenario>> prevStepsConverted = new HashMap<>();
                for (Map.Entry<String, List<ScenarioStepInfo>> entry : previousScenarioSteps.entrySet()) {
                    List<SystemMessages.Scenario> convertedSteps = entry.getValue().stream()
                        .map(step -> new SystemMessages.Scenario(step.scenarioId, step.stepNumber, step.stepBody))
                        .collect(Collectors.toList());
                    prevStepsConverted.put(entry.getKey(), convertedSteps);
                }

                // Include source code in the prompt for better step definition generation
                String stepDefinitionPrompt = SystemMessages.generateStepDefinitionPrompt(
                    scenarios, variables, variableInitialValues, sourceCode, prevStepsConverted);

                System.out.println("Generating step definition with source code context:");
                System.out.println(String.format("Available source files: %s", sourceCode.keySet()));
                
                String response = this.llm.chat(stepDefinitionPrompt);
                System.out.println(String.format("LLM Response: %s", response));

                try {
                    String cleanedResponse = extractJsonFromResponse(response);
                    JsonNode jsonNode = objectMapper.readTree(cleanedResponse);
                    
                    stepDef.stepName = stepName;
                    stepDef.stepType = scenarioSteps.get(0).stepType;
                    
                    JsonNode stepArgsNode = jsonNode.get("step-arguments");
                    System.out.println(String.format("Step arguments node: %s", stepArgsNode));
                    if (stepArgsNode != null) {
                        stepDef.stepArguments = objectMapper.convertValue(stepArgsNode, Map.class);
                    } else {
                        stepDef.stepArguments = new HashMap<>();
                    }
                    
                    JsonNode stepParamsNode = jsonNode.get("step-parameters");
                    System.out.println(String.format("Step parameters node: %s", stepParamsNode));
                    if (stepParamsNode != null) {
                        stepDef.stepParameters = objectMapper.convertValue(stepParamsNode, Map.class);
                    } else {
                        stepDef.stepParameters = new HashMap<>();
                    }
                    
                    JsonNode stepBodyNode = jsonNode.get("step-body");
                    if (stepBodyNode != null) {
                        stepDef.stepBody = stepBodyNode.asText();
                    }
                    
                } catch (Exception e) {
                    System.err.println(String.format("Error parsing LLM response: %s", e.getMessage()));
                    e.printStackTrace();
                    
                    // Fallback - create simple step definition
                    stepDef.stepName = stepName;
                    stepDef.stepArguments = new HashMap<>();
                    stepDef.stepParameters = new HashMap<>();
                    stepDef.stepBody = firstStepBody;
                    stepDef.stepType = scenarioSteps.get(0).stepType;
                }
            }
        }
        
        return stepDef;
    }

    /**
     * Extract JSON from LLM response that may contain explanations.
     * 
     * @param response The raw LLM response
     * @return The extracted JSON string
     */
    private String extractJsonFromResponse(String response) {
        // Try to find JSON content between braces
        int startIndex = response.indexOf('{');
        int endIndex = response.lastIndexOf('}');
        
        if (startIndex >= 0 && endIndex > startIndex) {
            return response.substring(startIndex, endIndex + 1).trim();
        }
        
        return response.trim();
    }    
    
      
    /**
     * Apply all step definition properties to the EMF node model.
     * This replaces the original node information with the generated step definition.
     * So, the node's step name, body, parameters, and arguments are all updated.
     *
     * @param node The EMF node to update
     * @param stepDef The step definition containing all properties
     */
    private void applyStepDefinitionToNode(Node node, StepDefinition stepDef) {
        if (stepDef.stepName != null) {
            node.setStepName(stepDef.stepName);
            System.out.println(String.format("Set step name for node %s: %s", node.getName(), stepDef.stepName));
        }

        if (stepDef.stepBody != null && !stepDef.stepBody.trim().isEmpty()) {
            try {
                StepBody stepBodyObj = createStepBodyFromString(stepDef.stepBody);
                if (stepBodyObj != null) {
                    node.setStepBody(stepBodyObj);
                    System.out.println(String.format("Set step body for node %s: %s", node.getName(), stepDef.stepBody));
                }
            } catch (Exception e) {
                System.err.println(String.format("Error setting step body for node %s: %s", node.getName(), e.getMessage()));
                e.printStackTrace();
            }
        }
        
        if (stepDef.stepParameters != null && !stepDef.stepParameters.isEmpty()) {
            try {
                System.out.println(String.format("Creating %d step parameters for node %s", stepDef.stepParameters.size(), node.getName()));
                
                EList<Variable> stepParametersList = node.getStepParameters();
                
                stepParametersList.clear();
                
                for (Map.Entry<String, String> paramEntry : stepDef.stepParameters.entrySet()) {
                    String paramName = paramEntry.getKey();
                    String paramType = paramEntry.getValue();
                               
                    System.out.println(String.format("      Creating step parameter: %s of type %s", paramName, paramType));
                  
                    Variable variable = VariableHelper.createStepParameter(paramName, paramType);
                    
                    System.out.println(String.format("      Created variable: %s of type %s", variable.getName(), variable.getType().getType().getName()));
                    stepParametersList.add(variable);
                    System.out.println(String.format("      Added step parameter: %s", paramName));
                }
                
                System.out.println(String.format("Successfully added %d step parameters to node %s", stepParametersList.size(), node.getName()));
                
            } catch (Exception e) {
                System.err.println(String.format("Error setting step parameters for node %s: %s", node.getName(), e.getMessage()));
                e.printStackTrace();
            }
        }

        if (stepDef.stepArguments != null && !stepDef.stepArguments.isEmpty()) {
            try {
                System.out.println(String.format("Applying %d step arguments to node %s", stepDef.stepArguments.size(), node.getName()));
                
                for (Map.Entry<String, Object> argEntry : stepDef.stepArguments.entrySet()) {
                    String scenarioId = argEntry.getKey();
                    Object argsData = argEntry.getValue();
                    
                    System.out.println(String.format("      Processing step arguments for scenario: %s", scenarioId));
                    System.out.println(String.format("      Arguments data: %s", argsData));

                    // Find the corresponding scenario step for this scenario ID
                    // The scenarioId format might be "scenario T1, step 3" or "scenario T1 step 3"
                    ScenarioStep targetScenarioStep = null;
                    for (ScenarioStep step : node.getSteps()) {
                        String expectedScenarioId = "scenario " + step.getScenario().getName() + " step " + step.getStepNumber();
                        System.out.println(String.format("      Comparing '%s' with '%s'", scenarioId, expectedScenarioId));
                        
						// Normalize by removing commas and extra spaces
                        String normalizedScenarioId = scenarioId.replace(",", "");
                        String normalizedExpectedId = expectedScenarioId.replace(",", "");
                        
                        if (normalizedExpectedId.equals(normalizedScenarioId)) {
                            targetScenarioStep = step;
                            System.out.println(String.format("      Found matching scenario step: %s", expectedScenarioId));
                            break;
                        }
                    }
                    
                    if (targetScenarioStep == null) {
                        System.err.println(String.format("      Could not find scenario step for scenario ID: %s", scenarioId));
                        System.err.println(String.format("      Available scenario steps:"));
                        for (ScenarioStep step : node.getSteps()) {
                            String availableId = "scenario " + step.getScenario().getName() + " step " + step.getStepNumber();
                            System.err.println(String.format("        - %s", availableId));
                        }
                        continue;
                    }
                    
                    EList<nl.esi.comma.actions.actions.AssignmentAction> stepArgumentsList = targetScenarioStep.getStepArguments();
                    stepArgumentsList.clear();
                    
                    if (argsData instanceof Map) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> argumentsMap = (Map<String, Object>) argsData;
                        
                        System.out.println(String.format("      Creating %d step arguments for scenario %s", argumentsMap.size(), scenarioId));
                        
                        for (Map.Entry<String, Object> argDataEntry : argumentsMap.entrySet()) {
                            String paramName = argDataEntry.getKey();
                            Object paramValueData = argDataEntry.getValue();
                            
                            String paramType = "string";
                            Object paramValue = paramValueData;
                            
                            if (paramValueData instanceof Map) {
                                @SuppressWarnings("unchecked")
                                Map<String, Object> paramMap = (Map<String, Object>) paramValueData;
                                paramType = (String) paramMap.getOrDefault("type", "string");
                                paramValue = paramMap.getOrDefault("value", paramValueData.toString());
                            }
                            
                            if (!(paramValueData instanceof Map)) {
                                if (paramValueData instanceof Integer) {
                                    paramType = "int";
                                } else if (paramValueData instanceof Double || paramValueData instanceof Float) {
                                    paramType = "real";
                                } else if (paramValueData instanceof Boolean) {
                                    paramType = "bool";
                                } else {
                                    paramType = "string";
                                }
                                paramValue = paramValueData;
                            }
                            
                            System.out.println(String.format("      Creating step argument: %s of type %s with value %s", paramName, paramType, paramValue));
                            
                            Variable parameterVariable = null;
                            for (Variable stepParam : node.getStepParameters()) {
                                if (stepParam.getName().equals(paramName)) {
                                    parameterVariable = stepParam;
                                    System.out.println(String.format("      Found matching step parameter variable: %s", paramName));
                                    break;
                                }
                            }
                            
                            if (parameterVariable == null) {
                                System.err.println(String.format("      Could not find step parameter for argument: %s", paramName));
                                System.err.println(String.format("      Available step parameters:"));
                                for (Variable stepParam : node.getStepParameters()) {
                                    System.err.println(String.format("        - %s", stepParam.getName()));
                                }
                                continue;
                            }
                            
                            nl.esi.comma.actions.actions.AssignmentAction assignmentAction = VariableHelper.createStepArgumentWithVariable(
                                parameterVariable, paramValue, paramType);
                            
                            System.out.println(String.format("      Created assignment action for existing parameter variable: %s", assignmentAction.getAssignment().getName()));
                            
                            stepArgumentsList.add(assignmentAction);
                            System.out.println(String.format("      Added step argument: %s to scenario %s", paramName, scenarioId));
                        }
                        
                        System.out.println(String.format("      Successfully added %d step arguments to scenario %s", stepArgumentsList.size(), scenarioId));
                        
                    } else {
                        System.err.println(String.format("      Arguments data for scenario %s is not a Map, skipping", scenarioId));
                    }
                }
                
                System.out.println(String.format("Successfully applied step arguments to node %s", node.getName()));
                
            } catch (Exception e) {
                System.err.println(String.format("Error setting step arguments for node %s: %s", node.getName(), e.getMessage()));
                e.printStackTrace();
            }
        }

        System.out.println(String.format("Successfully applied complete step definition to node %s", node.getName()));
    }
    
    /**
     * Create a StepBody object using the proper EMF factory.
     * 
     * @param bodyString The string content for the step body
     * @return The created StepBody object
     */
    private StepBody createStepBodyFromString(String bodyString) {
        try {
            LanguageBody languageBody = CausalGraphFactory.eINSTANCE.createLanguageBody();
            languageBody.setBody(bodyString);
            System.out.println(String.format("      Created LanguageBody with content: %s", bodyString));
            return languageBody;
            
        } catch (Exception e) {
            System.err.println(String.format("Error creating LanguageBody from string: %s", e.getMessage()));
            return null;
        }
    }
    
    /**
     * Extract the actual body content from a StepBody object.
     * Handles different StepBody implementations properly.
     * 
     * @param stepBody The StepBody object
     * @return The extracted body content as a string
     */
    private String extractStepBodyContent(StepBody stepBody) {
        if (stepBody == null) {
            return "";
        }
        
        if (stepBody instanceof LanguageBody) {
            LanguageBody languageBody = (LanguageBody) stepBody;
            return languageBody.getBody() != null ? languageBody.getBody() : "";
        }
        
        return stepBody.toString();
    }


    /**
     * Helper class to represent scenario step information.
     */
    private static class ScenarioStepInfo {
        String scenarioId;
        String stepNumber;
        String stepType;
        String stepBody;
    }

    /**
     * Helper class to represent step definitions.
     */
    private static class StepDefinition {
        String stepName;
        String stepType;
        Map<String, Object> stepArguments;
        Map<String, String> stepParameters;
        String stepBody;
    }

}
