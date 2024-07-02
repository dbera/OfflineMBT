import { JsonData } from "../types";

class ConfigInfo {
    public configFilePath: string;
    public assemblyFilePath: string;
    public testFilePathPrefix: string;
    public defaultConfigName: string;

    constructor(jsonData: JsonData | null){
        this.configFilePath = jsonData != null ? jsonData.configFilePath : "";
        this.assemblyFilePath = jsonData != null ? jsonData.assemblyFilePath:"";
        this.testFilePathPrefix = jsonData != null ? jsonData.testFilePathPrefix:"";
        this.defaultConfigName = jsonData != null ? jsonData.defaultConfigName:"";
    }
}

export default ConfigInfo;