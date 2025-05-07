///
/// Copyright (c) 2024, 2025 TNO-ESI
///
/// See the NOTICE file(s) distributed with this work for additional
/// information regarding copyright ownership.
///
/// This program and the accompanying materials are made available
/// under the terms of the MIT License which is available at
/// https://opensource.org/licenses/MIT
///
/// SPDX-License-Identifier: MIT
///

import { JsonData } from '../types';
import ConformingScenario from './ConformingScenario';
import ViolatingScenario from './ViolatingScenario';
class ConformanceResult {
    public constraintName: string;
    public constraintText: string[];
    public base64Dot: string;
    public numberOfConformingSCN: number;
    public testCoverage: number;
    public stateCoverage: number;
    public transitionCoverage: number;
    public conformingScenarios : ConformingScenario[];
    public violatingScenarios : ViolatingScenario[];

    constructor(jsonData: JsonData | null) {
        this.constraintName = jsonData != null ? jsonData.constraintName : "";
        this.constraintText = jsonData != null ? jsonData.constraintText : [];
        this.base64Dot = jsonData != null ? jsonData.constraintDot : "";
        this.numberOfConformingSCN = jsonData != null ? jsonData.numberOfConformingSCN : 0;
        this.testCoverage = jsonData != null ? jsonData.testCoverage : 0;
        this.stateCoverage = jsonData != null ? jsonData.stateCoverage : 0;
        this.transitionCoverage = jsonData != null ? jsonData.transitionCoverage : 0;
        this.conformingScenarios = jsonData != null ? jsonData.listOfConformingScenarios.map((d: JsonData) => new ConformingScenario(d)) : [];
        this.violatingScenarios = jsonData != null ? jsonData.listOfViolatingScenarios.map((d: JsonData) => new ViolatingScenario(d)) : [];
    }
}

export default ConformanceResult;