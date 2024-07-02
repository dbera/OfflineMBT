import { JsonData } from "../types";

class ImpactedTest {
    public scnID: string;
    public configs: string[];
    public filePath: string;
    public reason: string[];
    public base64Content: string;

    constructor(jsonData: JsonData) {
        this.scnID = jsonData.scnID
        this.configs = jsonData.configs
        this.filePath = jsonData.filePath
        this.base64Content = jsonData != null ? jsonData.featureContent : "";
        this.reason = jsonData.reason
    }
}

export default ImpactedTest;