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