package nl.esi.comma.causalgraph.agents;

import java.util.*;
 
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.azure.AzureOpenAiChatModel;
 
/**
* MergeAgent class for processing code snippets and generating step definitions.
* Mock implementation that doesn't require external dependencies.
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
 
            // Mock initialization - just validate that configuration is present
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
	    
	    // Use a separate thread with hard timeout to prevent hanging
	    final ChatModel[] result = new ChatModel[1];
	    final Exception[] exception = new Exception[1];
	    
	    Thread initThread = new Thread(() -> {
	        try {
	            System.out.println("Starting AzureOpenAiChatModel creation in separate thread...");
	            ChatModel model = AzureOpenAiChatModel.builder()
	                .endpoint(cleanEndpoint)
	                .serviceVersion(apiVersion)
	                .apiKey(azureApiKey)
	                .deploymentName(llmModel != null ? llmModel : "gpt-4")
	                .temperature(temperature != null ? temperature : 1.0)
	                .timeout(java.time.Duration.ofSeconds(10))
	                .maxRetries(3)
	                .build();
	            result[0] = model;
	            System.out.println("AzureOpenAiChatModel created successfully in thread");
	        } catch (Exception e) {
	            exception[0] = e;
	            System.err.println("Error in thread creating AzureOpenAiChatModel: " + e.getMessage());
	        }
	    });
	    
	    initThread.setDaemon(true);
	    initThread.start();
	    
	    try {
	        // Wait maximum 15 seconds for initialization
	        initThread.join(15000);
	        
	        if (initThread.isAlive()) {
	            System.err.println("AzureOpenAiChatModel initialization timed out after 15 seconds");
	            System.err.println("This is likely due to network connectivity issues or Azure service problems");
	            initThread.interrupt();
	            return null;
	        }
	        
	        if (exception[0] != null) {
	            System.err.println("Error creating AzureOpenAiChatModel: " + exception[0].getMessage());
	            System.err.println("This might be due to:");
	            System.err.println("  1. Incorrect deployment name (currently: " + llmModel + ")");
	            System.err.println("  2. Network connectivity issues");
	            System.err.println("  3. Invalid API key or endpoint");
	            System.err.println("  4. Azure OpenAI service not available");
	            exception[0].printStackTrace();
	            return null;
	        }
	        
	        if (result[0] != null) {
	            System.out.println("AzureOpenAiChatModel initialized successfully");
	            return result[0];
	        } else {
	            System.err.println("AzureOpenAiChatModel initialization returned null");
	            return null;
	        }
	        
	    } catch (InterruptedException e) {
	        System.err.println("Initialization was interrupted");
	        Thread.currentThread().interrupt();
	        return null;
	    }
	}
 
    public String invoke(String[] input) {
 
        if (this.llm == null) {
            System.err.println("LLM not initialized");
            return null;
        }
 
        String prompt = """
            You should check if two pieces are similar enough to merge and paramaterize in a step
            definition. If so you should just return True and if not then you should return False. Do not
            return more than the Boolean.
 
            Rules:
            1. Only return True or False, nothing else.
            2. The code snippets should be similar enough to be merged into a single step definition with parameterization.
            3. The code snippets can be different in logic or structure, but there should be overlaping pieces of code that can be paramaterized
            4. With large pieces of code, it is even more important that pieces of the code are similar in logic, not the entire code has to be similar.
            5. Be very lenient code should almost always be merged only pieces of code that are very far apart shouldnt be merged!
 
            First I will present 2 examples with two code snippets that should be merged and parameterized in a step definition:
            Code snippet 1:
            bool y = true;
            float z = 0.85;
            y = function42(z);
            if(y) {
                x = x + 4;
                z = function2(x);
            }
            else { z = function2(x); }
            z = z + 3.7;
            h = test-interface::f1(z, y);
 
            Code snippet 2:
            bool y = true;
            float z = 0.5;
            y = function1(z);
            if(y) {
                x = x + 6;
                z = function2(x);
            }
            z = z + 3.7;
            h = test-interface::f1(z, y);
 
            Output:
            True
 
            code snippet 1:
            int expectedBalance = espressoCost + espressoCost;
            EXPECT_EQ(machine.GetBalance(), expectedBalance);
 
            code snippet 2:
            EXPECT_EQ(machine.GetBalance(), 0);
 
            Output:
            True
 
            Second I will present an example that should not be merged and paramaterized in a step
            definition:
            Code snippet 1:
            bool y = true;
            float z = 0.85;
            y = function42(z);
            if(y) {
                x = x + 4;
                z = function2(x);
            }
            else { z = function2(x); }
            z = z + 3.7;
            h = test-interface::f1(z, y);
 
            Code snippet 2:
            float y = 10;
            float z = 0.85;
 
            for y in range(y):
                z += 1;
 
            Output:
            False
 
            Now analyze these code snippets:
            """;
 
        prompt += String.format("""
            Now I will present two code snippets where you should decide if they should be merged and parameterized in a step
            definition:
            Code snippet 1:
            %s
 
            Code snippet 2:
            %s
 
            Output:
            """, input[0], input[1]);
 
        return this.llm.chat(prompt);
    }
 
    /**
     * Check if two code snippets should be merged based on mock analysis.
     *
     * @param snippet1 First code snippet
     * @param snippet2 Second code snippet
     * @return true if snippets should be merged, false otherwise
     */
    public boolean shouldMerge(String snippet1, String snippet2) {
        String[] input = {snippet1, snippet2};
        String result = invoke(input);
        System.out.println("MergeAgent result: " + result);
        return result != null && result.trim().equalsIgnoreCase("True");
    }
    /**
     * Main method for testing the MergeAgent.
     *
     * @param args Command line arguments
     */
    public static void main(String[] args) {
        try {
            Map<String, Object> config = ConfigManager.getConfig();
            MergeAgent mergeAgent = new MergeAgent(config);
 
            String[] codeSnippets = {
                """
                scenario dsaLateral step 3:
                step-body: «            bool isExplicitlyEnabled = Environment::getInstance()->isExplicitlyEnabled();
                if (!isExplicitlyEnabled && (!testConfig.isBiplane || testConfig.isSinglePC || testConfig.isDebugBuild)) GTEST_SKIP() << "Test is marked explicit";
                m_testMode.channel = XrayFrontendEmulator::XrayChannel::Lateral;
                m_testMode.rtoActive = false;»
                """,
                """
                scenario rcmImageFreezeFrontal step 3:
                step-body: «            bool isExplicitlyEnabled = Environment::getInstance()->isExplicitlyEnabled();
                if (!isExplicitlyEnabled && (!testConfig.isBiplane || testConfig.isSinglePC || testConfig.isDebugBuild)) GTEST_SKIP() << "Test is marked explicit";
                m_testMode.channel = XrayFrontendEmulator::XrayChannel::Frontal;»
                """
            };
 
            String output = mergeAgent.invoke(codeSnippets);
            System.out.println(output);
           
        } catch (Exception e) {
            System.err.println("Error in main: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
