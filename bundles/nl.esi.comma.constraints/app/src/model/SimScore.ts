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
class SimScore {
    public newTestId: string;
    public jaccardIndex: number;
    public normalizedEditDistance: number;

    constructor(jsonData: JsonData) {
        this.newTestId = jsonData.newTestId
        this.jaccardIndex = jsonData.jaccardIndex
        this.normalizedEditDistance = jsonData.normalizedEditDistance
    }

}

export default SimScore;