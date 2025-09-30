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
import nl.esi.comma.expressions.expression.Variable;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionFactory;
import nl.esi.comma.types.types.Type;
import nl.esi.comma.types.types.TypeDecl;
import nl.esi.comma.types.types.TypeReference;
import nl.esi.comma.types.types.TypesFactory;
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
            System.out.println("GPT Config: " + gptConfig);
            
            String azureEndpoint = gptConfig != null ? (String) gptConfig.get("endpoint") : null;
            String azureApiKey = gptConfig != null ? (String) gptConfig.get("api_key") : null;
            String llmModel = gptConfig != null ? (String) gptConfig.get("llm") : null;
            String apiVersion = gptConfig != null ? (String) gptConfig.get("version") : null;
            String temperatureStr = gptConfig != null ? (String) gptConfig.get("temperature") : null;
            Float temperature = temperatureStr != null ? Float.parseFloat(temperatureStr) : 1.0f;

            // Initialize LLM if configuration is present
            if (azureEndpoint != null && azureApiKey != null) {
                System.out.println("Configuration validated successfully");
                this.llm = initializeLLM(llmModel, apiVersion, temperature, azureEndpoint, azureApiKey);
                System.out.println("StepDefinitionAgent constructor completed successfully");
            } else {
                System.err.println("Missing required configuration");
            }
            
        } catch (Exception e) {
            System.err.println("Error in StepDefinitionAgent constructor: " + e.getMessage());
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
                    sourceCodeMap.put(path, "// " + path + " not found");
                }
            }
        }
        return sourceCodeMap;
    }

    /**
     * Initialize the LLM with the specified model and API version using LangChain4j.
     */
    private ChatModel initializeLLM(String llmModel, String apiVersion, Float temperature, String azureEndpoint, String azureApiKey) {
        System.out.println("initializeLLM called with parameters:");
        System.out.println("  llmModel: " + llmModel);
        System.out.println("  apiVersion: " + apiVersion);
        System.out.println("  temperature: " + temperature);
        
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
            System.err.println("Error creating AzureOpenAiChatModel: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    /**
     * Process a node in the causal graph to generate step definitions.
     * This is the main method called by the transformer.
     *
     * @param node The node to process
     * @param graph The complete causal graph for context
     */
    public void processNode(Node node, CausalGraph graph) {
        if (this.llm == null) {
            System.err.println("LLM not initialized");
            return;
        }

        try {
            System.out.println("Processing node: " + node.getName());
            
            // Extract scenario steps from the node
            List<ScenarioStepInfo> scenarioSteps = extractNodeScenarios(node);
            
            if (scenarioSteps.isEmpty()) {
                System.out.println("No scenario steps found for node: " + node.getName());
                return;
            }

            // Extract variables and dependencies from the graph
            Map<String, String> variables = extractVariables(graph);
            Map<String, Object> variableInitialValues = extractVariableInitialValues(graph);

            // Get previous step definitions based on data dependencies
            Map<String, List<ScenarioStepInfo>> previousOverlaySteps = new HashMap<>();

            // Generate step definition using LLM
            StepDefinition stepDefinition = generateStepDefinitions(
                scenarioSteps, variables, variableInitialValues, previousOverlaySteps);

            // Apply the generated step definition to the node
            if (stepDefinition != null) {
                applyStepDefinitionToNode(node, stepDefinition);
                System.out.println("Applied complete step definition '" + stepDefinition.stepName + "' to node " + node.getName());
            }
            
        } catch (Exception e) {
            System.err.println("Error processing node " + node.getName() + ": " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Apply all step definition properties to the EMF node model.
     * This replaces the original node information with the generated step definition.
     *
     * @param node The EMF node to update
     * @param stepDef The step definition containing all properties
     */
    private void applyStepDefinitionToNode(Node node, StepDefinition stepDef) {
        // Apply step name - this replaces any existing step name
        if (stepDef.stepName != null) {
            node.setStepName(stepDef.stepName);
            System.out.println("Set step name for node " + node.getName() + ": " + stepDef.stepName);
        }

        // Apply step body - create and set the StepBody with the actual content
        if (stepDef.stepBody != null && !stepDef.stepBody.trim().isEmpty()) {
            try {
                StepBody stepBodyObj = createStepBodyFromString(stepDef.stepBody);
                if (stepBodyObj != null) {
                    node.setStepBody(stepBodyObj);
                    System.out.println("Set step body for node " + node.getName() + ": " + stepDef.stepBody);
                }
            } catch (Exception e) {
                System.err.println("Error setting step body for node " + node.getName() + ": " + e.getMessage());
                e.printStackTrace();
            }
        }

        // Apply step parameters using proper EMF containment for basic types
        if (stepDef.stepParameters != null && !stepDef.stepParameters.isEmpty()) {
            try {
                System.out.println("Creating " + stepDef.stepParameters.size() + " step parameters for node " + node.getName());
                
                // Get the EList of step parameters from the node
                EList<Variable> stepParametersList = node.getStepParameters();
                
                // Clear existing parameters if any
                stepParametersList.clear();
                
                // Create and add new Variable objects for each parameter
                for (Map.Entry<String, String> paramEntry : stepDef.stepParameters.entrySet()) {
                    String paramName = paramEntry.getKey();
                    String paramType = paramEntry.getValue();
                    
                    // Create a new Variable using the ExpressionFactory
                    Variable variable = ExpressionFactory.eINSTANCE.createVariable();
                    variable.setName(paramName);
                    
                    // Create a proper type for the variable
                    try {
                        Type type = createBasicType(paramType);
                        if (type != null) {
                            variable.setType(type);
                            System.out.println("      Created parameter: " + paramName + " with type: " + paramType);
                        } else {
                            // If we can't create a specific type, create a generic Type object
                            Type genericType = TypesFactory.eINSTANCE.createType();
                            variable.setType(genericType);
                            System.out.println("      Created parameter: " + paramName + " with generic type (requested: " + paramType + ")");
                        }
                    } catch (Exception typeEx) {
                        System.err.println("      Warning: Could not set type for parameter " + paramName + ": " + typeEx.getMessage());
                        // Create a minimal Type object to satisfy EMF requirements
                        Type fallbackType = TypesFactory.eINSTANCE.createType();
                        variable.setType(fallbackType);
                        System.out.println("      Created parameter: " + paramName + " with fallback type");
                    }
                    
                    // Add the variable to the EList
                    stepParametersList.add(variable);
                    System.out.println("      Added step parameter: " + paramName);
                }
                
                System.out.println("Successfully added " + stepParametersList.size() + " step parameters to node " + node.getName());
                
            } catch (Exception e) {
                System.err.println("Error setting step parameters for node " + node.getName() + ": " + e.getMessage());
                e.printStackTrace();
            }
        }

        // Apply step arguments to specific scenarios
        if (stepDef.stepArguments != null && !stepDef.stepArguments.isEmpty()) {
            System.out.println("Applying " + stepDef.stepArguments.size() + " step arguments to node " + node.getName());
        }
        
        System.out.println("Successfully applied complete step definition to node " + node.getName());
    }
    
    /**
     * Create a proper Type object for basic types (int, float, bool, str).
     * Following the EXACT pattern from ReducedCausalGraphGenerator.xtend with proper EMF containment
     */
    private Type createBasicType(String paramType) {
        try {
            // Following the EXACT pattern from ReducedCausalGraphGenerator:
            // createTypeReference => [
            //     type = createAliasTypeDecl => [
            //         name = 'x_type'
            //         alias = 'some_type'
            //     ]
            // ]
            
            // Create TypeReference
            TypeReference typeRef = TypesFactory.eINSTANCE.createTypeReference();
            
            // Create AliasTypeDecl for basic types (int, float, bool, str)
            AliasTypeDecl aliasTypeDecl = CausalGraphFactory.eINSTANCE.createAliasTypeDecl();
            aliasTypeDecl.setName(paramType + "_type");  // Following the pattern: 'x_type'
            aliasTypeDecl.setAlias(paramType);           // The actual type: 'some_type' -> paramType
            
            // Set the TypeDecl in the TypeReference (this creates proper EMF containment)
            // This is the key - the AliasTypeDecl becomes contained within the TypeReference
            typeRef.setType(aliasTypeDecl);
            
            // DO NOT add the AliasTypeDecl to the graph's types list!
            // The containment is: Variable -> TypeReference -> AliasTypeDecl
            // The AliasTypeDecl is contained within the TypeReference, not at the graph level
            
            System.out.println("        Created TypeReference with contained AliasTypeDecl for: " + paramType);
            return typeRef;
            
        } catch (Exception e) {
            System.err.println("        Error creating type for " + paramType + ": " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }


    /**
     * Create a StepBody object using the proper EMF factory.
     */
    private StepBody createStepBodyFromString(String bodyString) {
        try {
            // Use the CausalGraphFactory to create a LanguageBody which can store text content
            LanguageBody languageBody = CausalGraphFactory.eINSTANCE.createLanguageBody();
            languageBody.setBody(bodyString);
            System.out.println("      Created LanguageBody with content: " + bodyString);
            return languageBody;
            
        } catch (Exception e) {
            System.err.println("Error creating LanguageBody from string: " + e.getMessage());
            return null;
        }
    }
    


    /**
     * Extract the actual body content from a StepBody object.
     * Handles different StepBody implementations properly.
     */
    private String extractStepBodyContent(StepBody stepBody) {
        if (stepBody == null) {
            return "";
        }
        
        // If it's a LanguageBody, get the actual body content
        if (stepBody instanceof LanguageBody) {
            LanguageBody languageBody = (LanguageBody) stepBody;
            return languageBody.getBody() != null ? languageBody.getBody() : "";
        }
        
        // For other StepBody types, fall back to toString() for now
        // This could be expanded to handle ActionsBody and other types
        return stepBody.toString();
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
            
            // Use the helper method to properly extract step body content
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
        
        // Extract from assignments in the graph - simplified implementation
        // In a real implementation, you would properly extract values from the EMF model
        if (graph.getAssignments() != null) {
            for (Object assignment : graph.getAssignments()) {
                // For now, we'll skip the detailed assignment extraction
                // This would need to be implemented based on the actual EMF model structure
                System.out.println("Assignment found: " + assignment.toString());
            }
        }
        
        return variableInitialValues;
    }

    /**
     * Generate step definitions using LLM for similar scenario steps.
     */
    private StepDefinition generateStepDefinitions(
            List<ScenarioStepInfo> scenarioSteps,
            Map<String, String> overlayVariables,
            Map<String, Object> variableInitialValues,
            Map<String, List<ScenarioStepInfo>> previousOverlaySteps) {
        
        // Declare stepDef at method level so it's accessible for return
        StepDefinition stepDef = new StepDefinition();
        
        // Convert to SystemMessages.Scenario format
        List<SystemMessages.Scenario> scenarios = scenarioSteps.stream()
            .map(step -> new SystemMessages.Scenario(step.scenarioId, step.stepNumber, step.stepBody))
            .collect(Collectors.toList());

        // Generate step name
        String stepNamePrompt = SystemMessages.generateStepNamePrompt(scenarios);
        String stepNameResponse = this.llm.chat(stepNamePrompt);
        String stepName = stepNameResponse.trim();

        if (scenarios.size() == 1) {
            // Single scenario - simple case
            stepDef.stepName = stepName;
            stepDef.stepArguments = new HashMap<>();
            stepDef.stepParameters = new HashMap<>();
            stepDef.stepBody = scenarios.get(0).getStepBody();
            stepDef.stepType = scenarioSteps.get(0).stepType;
        } else {
            // Multiple scenarios - need parameterization
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
                for (Map.Entry<String, List<ScenarioStepInfo>> entry : previousOverlaySteps.entrySet()) {
                    List<SystemMessages.Scenario> convertedSteps = entry.getValue().stream()
                        .map(step -> new SystemMessages.Scenario(step.scenarioId, step.stepNumber, step.stepBody))
                        .collect(Collectors.toList());
                    prevStepsConverted.put(entry.getKey(), convertedSteps);
                }

                String stepDefinitionPrompt = SystemMessages.generateStepDefinitionPrompt(
                    scenarios, overlayVariables, variableInitialValues, sourceCode, prevStepsConverted);

                String response = this.llm.chat(stepDefinitionPrompt);
                System.out.println("LLM Response: " + response);

                try {
                    String cleanedResponse = extractJsonFromResponse(response);
                    JsonNode jsonNode = objectMapper.readTree(cleanedResponse);
                    
                    stepDef.stepName = stepName;
                    stepDef.stepType = scenarioSteps.get(0).stepType;
                    
                    // Parse step-arguments
                    JsonNode stepArgsNode = jsonNode.get("step-arguments");
                    System.out.println("Step arguments node: " + stepArgsNode);
                    if (stepArgsNode != null) {
                        stepDef.stepArguments = objectMapper.convertValue(stepArgsNode, Map.class);
                    } else {
                        stepDef.stepArguments = new HashMap<>();
                    }
                    
                    // Parse step-parameters
                    JsonNode stepParamsNode = jsonNode.get("step-parameters");
                    System.out.println("Step parameters node: " + stepParamsNode);
                    if (stepParamsNode != null) {
                        stepDef.stepParameters = objectMapper.convertValue(stepParamsNode, Map.class);
                    } else {
                        stepDef.stepParameters = new HashMap<>();
                    }
                    
                    // Parse step-body
                    JsonNode stepBodyNode = jsonNode.get("step-body");
                    if (stepBodyNode != null) {
                        stepDef.stepBody = stepBodyNode.asText();
                    }
                    
                } catch (Exception e) {
                    System.err.println("Error parsing LLM response: " + e.getMessage());
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
        
        // Return the single step definition directly
        return stepDef;
    }

    /**
     * Extract JSON from LLM response that may contain explanations.
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