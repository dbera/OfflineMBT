package nl.esi.comma.causalgraph.agents;
 
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Map;
 
/**
* ConfigManager provides configuration settings for the causal graph functionality.
* Reads configuration from config.ini file with INI format support.
*/
public class ConfigManager {
    private static Map<String, Object> config = null;
    private static final String CONFIG_FILE = "config.ini";
    /**
     * Get the configuration map by reading from config.ini file.
     * 
     * @return Configuration map loaded from config.ini
     */
    public static Map<String, Object> getConfig() {
        if (config == null) {
            config = loadConfigFromFile();
        }
        return config;
    }
    /**
     * Load configuration from config.ini file with proper INI format parsing.
     *
     * @return Configuration map
     */
    private static Map<String, Object> loadConfigFromFile() {
        Map<String, Object> configMap = new HashMap<>();
        try {
            // Try to load from current directory first
            InputStream inputStream = null;
            try {
                inputStream = new FileInputStream(CONFIG_FILE);
            } catch (IOException e) {
                // If not found in current directory, try to load from classpath
                inputStream = ConfigManager.class.getClassLoader().getResourceAsStream(CONFIG_FILE);
            }
            if (inputStream != null) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
                String line;
                String currentSection = null;
                Map<String, Object> currentSectionMap = new HashMap<>();
                while ((line = reader.readLine()) != null) {
                    line = line.trim();
                    // Skip empty lines and comments
                    if (line.isEmpty() || line.startsWith("#") || line.startsWith(";")) {
                        continue;
                    }
                    // Check for section headers
                    if (line.startsWith("[") && line.endsWith("]")) {
                        // Save previous section if it exists
                        if (currentSection != null && !currentSectionMap.isEmpty()) {
                            configMap.put(currentSection, new HashMap<>(currentSectionMap));
                        }
                        // Start new section
                        currentSection = line.substring(1, line.length() - 1);
                        currentSectionMap = new HashMap<>();
                        continue;
                    }
                    int equalIndex = line.indexOf('=');
                    if (equalIndex > 0) {
                        String key = line.substring(0, equalIndex).trim();
                        String value = line.substring(equalIndex + 1).trim();
                        if (currentSection != null) {
                            currentSectionMap.put(key, value);
                        } else {
                            configMap.put(key, value);
                        }
                    }
                }
                // Save the last section
                if (currentSection != null && !currentSectionMap.isEmpty()) {
                    configMap.put(currentSection, new HashMap<>(currentSectionMap));
                }
                reader.close();
                inputStream.close();
                System.out.println(String.format("Successfully loaded configuration from %s", CONFIG_FILE));
                System.out.println(String.format("Config sections: %s", configMap.keySet()));
            } else {
                System.err.println(String.format("Could not find %s, using default configuration", CONFIG_FILE));
                return getDefaultConfig();
            }
        } catch (IOException e) {
            System.err.println(String.format("Error reading %s: %s", CONFIG_FILE, e.getMessage()));
            return getDefaultConfig();
        }
        return configMap;
    }
    /**
     * Get default configuration if config.ini cannot be loaded.
     * 
     * @return Default configuration map
     */
    private static Map<String, Object> getDefaultConfig() {
        Map<String, Object> defaultConfig = new HashMap<>();
        Map<String, Object> gptConfig = new HashMap<>();
        gptConfig.put("endpoint", "");
        gptConfig.put("api_key", "");
        gptConfig.put("llm", "gpt-4.1");
        gptConfig.put("version", "2024-12-01-preview");
        gptConfig.put("temperature", "0.1");
        defaultConfig.put("gpt", gptConfig);
        return defaultConfig;
    }
    /**
     * Set a configuration value.
     * 
     * @param key The configuration key
     * @param value The configuration value
     */
    public static void setConfig(String key, Object value) {
        if (config == null) {
            config = getConfig();
        }
        config.put(key, value);
    }
}