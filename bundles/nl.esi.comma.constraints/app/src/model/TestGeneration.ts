import { JsonData } from "../types";
import Similarity from "./Similarity";
import Statistics from "./Statistics";

class TestGeneration {
    public constraintName: string;
    public constraintText: string[];
    public base64Dot: string;
    public configurations: string[];
    public statistics: Statistics;
    public featureFileLocation: string;
    public similarities: Similarity[];

    constructor(jsonData: JsonData) {
        this.constraintName = jsonData != null ? jsonData.constraintName : "";
        this.constraintText = jsonData != null ? jsonData.constraintText : [];
        this.base64Dot = jsonData != null ? jsonData.constraintDot : "";
        this.configurations = jsonData.configurations
        this.statistics = jsonData.statistics
        this.featureFileLocation = jsonData.featureFileLocation
        this.similarities = jsonData.similarities
    }
}

export default TestGeneration;