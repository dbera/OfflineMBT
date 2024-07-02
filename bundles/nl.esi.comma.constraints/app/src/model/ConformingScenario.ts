import { JsonData } from "../types";

class ConformingScenario {
    public scnID: string;
    public scenarios: string[];
    public configurations: string[];
    public highlighted: string[];
    public filePath: string;
    public constraintName: string;
    public base64Content: string;

    constructor(jsonData: JsonData) {
        this.scnID = jsonData.scenarioName
        this.scenarios = jsonData.conformingScenario
        this.configurations = jsonData.configurations
        this.highlighted = jsonData.highlightedKeywords != null ? jsonData.highlightedKeywords : [];
        this.filePath = jsonData.featureFileLocation
        this.constraintName = jsonData.constraintName
        this.base64Content = jsonData != null ? jsonData.featureContent : "";
    }
}

export default ConformingScenario;