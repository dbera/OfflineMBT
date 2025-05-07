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