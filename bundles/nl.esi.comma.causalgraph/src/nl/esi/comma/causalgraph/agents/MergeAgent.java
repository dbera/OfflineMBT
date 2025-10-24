package nl.esi.comma.causalgraph.agents;

import java.util.*;
 
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.azure.AzureOpenAiChatModel;
 
/**
* MergeAgent class to let an LLM decide if two pieces of code should belong to the same group.
*/
public class MergeAgent {    
	private ChatModel llm;
    
    /**
     * Initialize the MergeAgent with the provided configuration.
     *
     * @param config The configuration map
     */
    public MergeAgent(Map<String, Object> config) {
        try {
            System.out.println(String.format("MergeAgent constructor started"));
            
            @SuppressWarnings("unchecked")
            Map<String, Object> gptConfig = (Map<String, Object>) config.get("gpt");
            System.out.println(String.format("GPT Config: %s", gptConfig));
            
            String azureEndpoint = gptConfig != null ? (String) gptConfig.get("endpoint") : null;
            String azureApiKey = gptConfig != null ? (String) gptConfig.get("api_key") : null;
            String llmModel = gptConfig != null ? (String) gptConfig.get("llm") : null;
            String apiVersion = gptConfig != null ? (String) gptConfig.get("version") : null;
            String temperatureStr = gptConfig != null ? (String) gptConfig.get("temperature") : null;
            Float temperature = temperatureStr != null ? Float.parseFloat(temperatureStr) : null;
 
            System.out.println(String.format("Azure Endpoint: %s", azureEndpoint));
            System.out.println(String.format("LLM Model: %s", llmModel));
            System.out.println(String.format("API Version: %s", apiVersion));
            System.out.println(String.format("Temperature: %s", temperature));
 
            // Initialize LLM if configuration is present
            if (azureEndpoint != null && azureApiKey != null) {
                System.out.println(String.format("Configuration validated successfully"));
                this.llm = initializeLLM(llmModel, apiVersion, temperature, azureEndpoint, azureApiKey);
                System.out.println(String.format("MergeAgent constructor completed successfully"));
            } else {
                System.err.println(String.format("Missing required configuration"));
            }
            
        } catch (Exception e) {
            System.err.println(String.format("Error in MergeAgent constructor: %s", e.getMessage()));
            e.printStackTrace();
        }
    }
 
 
	/**
	 * Initialize the LLM with the specified model and API version using LangChain4j.
	 *
	 * @param llmModel The LLM model name
	 * @param apiVersion The API version
	 * @param temperature The temperature setting
	 * @param azureEndpoint The Azure endpoint URL
	 * @param azureApiKey The Azure API key
	 * @return Initialized LLM object
	 */
	private ChatModel initializeLLM(String llmModel, String apiVersion, Float temperature, String azureEndpoint, String azureApiKey) {
	    System.out.println(String.format("initializeLLM called with parameters:"));
	    System.out.println(String.format("  llmModel: %s", llmModel));
	    System.out.println(String.format("  apiVersion: %s", apiVersion));
	    System.out.println(String.format("  temperature: %s", temperature));
	    System.out.println(String.format("  azureEndpoint: %s", azureEndpoint));
	    System.out.println(String.format("  azureApiKey: %s", (azureApiKey != null ? "***PRESENT***" : "null")));
	    
	    if (azureEndpoint == null || azureApiKey == null) {
	        System.err.println("Azure OpenAI configuration missing");
	        return null;
	    }
	    
	    // Ensure endpoint doesn't have trailing slash for some Azure configurations
	    String cleanEndpoint = azureEndpoint.endsWith("/") ? azureEndpoint.substring(0, azureEndpoint.length() - 1) : azureEndpoint;
	    
	    System.out.println(String.format("About to create AzureOpenAiChatModel..."));
	    System.out.println(String.format("Validating configuration:"));
	    System.out.println(String.format("  Endpoint format: %s", (azureEndpoint.startsWith("https://") ? "Valid" : "Invalid - should start with https://")));
	    System.out.println(String.format("  Deployment name: %s", llmModel));
	    
	    try {
	        System.out.println(String.format("Starting AzureOpenAiChatModel creation..."));
	        ChatModel model = AzureOpenAiChatModel.builder()
	            .endpoint(cleanEndpoint)
	            .serviceVersion(apiVersion)
	            .apiKey(azureApiKey)
	            .deploymentName(llmModel != null ? llmModel : "gpt-4")
	            .temperature(temperature != null ? temperature : 1.0)
	            .timeout(java.time.Duration.ofSeconds(30))
	            .maxRetries(3)
	            .build();
	            
	        System.out.println(String.format("AzureOpenAiChatModel created successfully"));
	        return model;
	        
	    } catch (Exception e) {
	        System.err.println(String.format("Error creating AzureOpenAiChatModel: %s", e.getMessage()));
	        System.err.println("This might be due to:");
	        System.err.println(String.format("  1. Incorrect deployment name (currently: %s)", llmModel));
	        System.err.println("  2. Network connectivity issues");
	        System.err.println("  3. Invalid API key or endpoint");
	        System.err.println("  4. Azure OpenAI service not available");
	        e.printStackTrace();
	        return null;
	    }
	}
 
    /**
     * Invoke the MergeAgent to determine if two code snippets should be merged.
     * 
     * @param codeSnippets Array of code snippets to compare (expects exactly 2 snippets)
     * @return String response from the LLM indicating whether to merge ("True" or "False")
     */
    public String invoke(String[] codeSnippets) {
        if (codeSnippets == null || codeSnippets.length != 2) {
            throw new IllegalArgumentException("Expected exactly 2 code snippets");
        }

        if (this.llm == null) {
            System.err.println("LLM not initialized");
            return null;
        }

        try {
            String prompt = SystemMessages.shouldCodeMergePrompt(Arrays.asList(codeSnippets));
            
            String response = this.llm.chat(prompt);
            
            System.out.println(String.format("LLM Response: %s", response));
            return response;
            
        } catch (Exception e) {
            System.err.println(String.format("Error calling LLM: %s", e.getMessage()));
            e.printStackTrace();
            return null;
        }
    }
}