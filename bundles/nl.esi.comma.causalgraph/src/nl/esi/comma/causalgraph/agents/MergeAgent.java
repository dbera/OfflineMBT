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
            System.out.println("MergeAgent constructor started");
            
            @SuppressWarnings("unchecked")
            Map<String, Object> gptConfig = (Map<String, Object>) config.get("gpt");
            System.out.println("GPT Config: " + gptConfig);
            
            String azureEndpoint = gptConfig != null ? (String) gptConfig.get("endpoint") : null;
            String azureApiKey = gptConfig != null ? (String) gptConfig.get("api_key") : null;
            String llmModel = gptConfig != null ? (String) gptConfig.get("llm") : null;
            String apiVersion = gptConfig != null ? (String) gptConfig.get("version") : null;
            String temperatureStr = gptConfig != null ? (String) gptConfig.get("temperature") : null;
            Float temperature = temperatureStr != null ? Float.parseFloat(temperatureStr) : null;
 
            System.out.println("Azure Endpoint: " + azureEndpoint);
            System.out.println("LLM Model: " + llmModel);
            System.out.println("API Version: " + apiVersion);
            System.out.println("Temperature: " + temperature);
 
            // Initialize LLM if configuration is present
            if (azureEndpoint != null && azureApiKey != null) {
                System.out.println("Configuration validated successfully");
                this.llm = initializeLLM(llmModel, apiVersion, temperature, azureEndpoint, azureApiKey);
                System.out.println("MergeAgent constructor completed successfully");
            } else {
                System.err.println("Missing required configuration");
            }
            
        } catch (Exception e) {
            System.err.println("Error in MergeAgent constructor: " + e.getMessage());
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
	    System.out.println("initializeLLM called with parameters:");
	    System.out.println("  llmModel: " + llmModel);
	    System.out.println("  apiVersion: " + apiVersion);
	    System.out.println("  temperature: " + temperature);
	    System.out.println("  azureEndpoint: " + azureEndpoint);
	    System.out.println("  azureApiKey: " + (azureApiKey != null ? "***PRESENT***" : "null"));
	    
	    if (azureEndpoint == null || azureApiKey == null) {
	        System.err.println("Azure OpenAI configuration missing");
	        return null;
	    }
	    
	    // Ensure endpoint doesn't have trailing slash for some Azure configurations
	    String cleanEndpoint = azureEndpoint.endsWith("/") ? azureEndpoint.substring(0, azureEndpoint.length() - 1) : azureEndpoint;
	    
	    System.out.println("About to create AzureOpenAiChatModel...");
	    System.out.println("Validating configuration:");
	    System.out.println("  Endpoint format: " + (azureEndpoint.startsWith("https://") ? "Valid" : "Invalid - should start with https://"));
	    System.out.println("  Deployment name: " + llmModel);
	    
	    try {
	        System.out.println("Starting AzureOpenAiChatModel creation...");
	        ChatModel model = AzureOpenAiChatModel.builder()
	            .endpoint(cleanEndpoint)
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
	        System.err.println("This might be due to:");
	        System.err.println("  1. Incorrect deployment name (currently: " + llmModel + ")");
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
            
            System.out.println("LLM Response: " + response);
            return response;
            
        } catch (Exception e) {
            System.err.println("Error calling LLM: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    /**
     * Main method for testing the MergeAgent.
     *
     * @param args Command line arguments
     */
    public static void main(String[] args) {
        try {
            Map<String, Object> config = ConfigManager.getConfig();
            MergeAgent MergeAgent = new MergeAgent(config);
 
            String[] codeSnippets = {
                """
            	bool isExplicitlyEnabled = Environment::getInstance()->isExplicitlyEnabled();
                if (!isExplicitlyEnabled && (!testConfig.isBiplane || testConfig.isSinglePC || testConfig.isDebugBuild)) GTEST_SKIP() << "Test is marked explicit";
                m_testMode.channel = XrayFrontendEmulator::XrayChannel::Lateral;
                m_testMode.rtoActive = false;
                """,
                """
                bool isExplicitlyEnabled = Environment::getInstance()->isExplicitlyEnabled();
                if (!isExplicitlyEnabled && (!testConfig.isBiplane || testConfig.isSinglePC || testConfig.isDebugBuild)) GTEST_SKIP() << "Test is marked explicit";
                m_testMode.channel = XrayFrontendEmulator::XrayChannel::Frontal;
                """
            };
 
            String output = MergeAgent.invoke(codeSnippets);
            System.out.println(output);
           
        } catch (Exception e) {
            System.err.println("Error in main: " + e.getMessage());
            e.printStackTrace();
        }
    }
}