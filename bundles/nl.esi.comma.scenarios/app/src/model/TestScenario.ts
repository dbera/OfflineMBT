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

class TestScenario {
    public scnID: string;
    public config: string;

    constructor(scnID: string, config: string){
        this.scnID = scnID;
        this.config = config;
    }

}

export default TestScenario;