import { JsonData } from "../types";

class TestConfigOverview {
    public config: string;
    public tests: string[];
    public category: string;

    constructor(jsonData: JsonData){
        this.config = jsonData.config
        this.tests = jsonData.selectedTests
        this.category = jsonData.category
    }
}

export default TestConfigOverview;