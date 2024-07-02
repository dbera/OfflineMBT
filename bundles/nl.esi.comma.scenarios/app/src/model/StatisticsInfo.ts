import { JsonData } from '../types';
class StatisticsInfo {
    public definedTests: number;
    public definedConfigurations: number;
    public definedTestConfigPairs: number;
    public estBuildTimeDefined: string;
    public selectedTests: number;
    public selectedConfigurations: number;
    public selectedTestConfigPairs: number;
    public estBuildTimeSelected: string;

    constructor(jsonData: JsonData | null) {
        this.definedTests = jsonData != null ? jsonData.definedTests : 0;
        this.definedConfigurations = jsonData != null ? jsonData.definedConfigurations : 0;
        this.definedTestConfigPairs = jsonData != null ? jsonData.definedTestConfigPairs : 0;
        this.estBuildTimeDefined = jsonData != null ? jsonData.estBuildTimeDefined : "";
        this.selectedTests = jsonData != null ? jsonData.selectedTests : 0;
        this.selectedConfigurations = jsonData != null ? jsonData.selectedConfigurations : 0;
        this.selectedTestConfigPairs = jsonData != null ? jsonData.selectedTestConfigPairs : 0;
        this.estBuildTimeSelected = jsonData != null ? jsonData.estBuildTimeSelected : "";
    }
}

export default StatisticsInfo;