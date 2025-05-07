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