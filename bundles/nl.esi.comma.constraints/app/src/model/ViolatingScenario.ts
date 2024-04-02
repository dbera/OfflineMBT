import { JsonData } from "../types";

class  ViolatingScenario {
    public scnID: string;
    public scenarios: string[];
    public configurations: string[];
    public filePath: string;
    public constraintName: string;
    public violatingAction: string[];
    public base64Content: string;
    public highlighted: string[];

    constructor(jsonData: JsonData) {
        this.scnID = jsonData.scenarioName
        this.scenarios = jsonData.violatingScenario
        this.configurations = jsonData.configurations
        this.highlighted = jsonData.highlightedKeywords != null ? jsonData.highlightedKeywords : [];
        this.filePath = jsonData.featureFileLocation
        this.constraintName = jsonData.constraintName
        this.violatingAction = jsonData.violatingAction
        this.base64Content = jsonData != null ? jsonData.featureContent : "";
    }
}

export default  ViolatingScenario;