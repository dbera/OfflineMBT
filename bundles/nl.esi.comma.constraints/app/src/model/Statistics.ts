import { JsonData } from '../types';
class Statistics {
    public algorithm: string;
    public amountOfStatesInAutomaton: number;
    public amountOfTransitionsInAutomaton: number;
    public amountOfTransitionsCoveredByExistingScenarios: number;
    public amountOfPaths: number;
    public amountOfSteps: number;
    public percentageTransitionsCoveredByExistingScenarios: number;
    public averageAmountOfStepsPerSequence: number;
    public percentageOfStatesCovered: number;
    public percentageOfTransitionsCovered: number;
    public averageTransitionExecution: number;
    public timesTransitionIsExecuted: {[key:string]:string[]};

    constructor(jsonData: JsonData | null){
        this.algorithm = jsonData != null ? jsonData.algorithm : "";
        this.amountOfStatesInAutomaton = jsonData != null ? jsonData.amountOfStatesInAutomaton : 0;
        this.amountOfTransitionsInAutomaton = jsonData != null ? jsonData.amountOfTransitionsInAutomaton : 0;
        this.amountOfTransitionsCoveredByExistingScenarios = jsonData != null ? jsonData.amountOfTransitionsCoveredByExistingScenarios: 0;
        this.amountOfPaths = jsonData != null ? jsonData.amountOfPaths: 0;
        this.amountOfSteps = jsonData != null ? jsonData.amountOfSteps: 0;
        this.percentageTransitionsCoveredByExistingScenarios = jsonData != null ? jsonData.percentageTransitionsCoveredByExistingScenarios:0;
        this.averageAmountOfStepsPerSequence = jsonData != null ? jsonData.averageAmountOfStepsPerSequence:0;
        this.percentageOfStatesCovered = jsonData != null ? jsonData.percentageOfStatesCovered:0;
        this.percentageOfTransitionsCovered = jsonData != null ? jsonData.percentageOfTransitionsCovered: 0;
        this.averageTransitionExecution = jsonData != null ? jsonData.averageTransitionExecution:0;
        this.timesTransitionIsExecuted = jsonData != null ? jsonData.timesTransitionIsExecuted: {};
    }
}

export default Statistics;