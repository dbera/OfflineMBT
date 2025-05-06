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