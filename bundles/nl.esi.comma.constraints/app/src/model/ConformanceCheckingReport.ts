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

import ConformanceResult from './ConformanceResult';
import TestGeneration from './TestGeneration';
import MetaInfo from './MetaInfo';
import { JsonData } from '../types';

class ConformanceCheckingReport {
    public meta : MetaInfo;
    public conformanceResults : ConformanceResult[];
    public testGenerations : TestGeneration[];

    constructor(data: JsonData | null) {
        this.meta = new MetaInfo(data != null ? data.meta : new Date());
        this.conformanceResults = data != null ? data.conformanceResults?.map((d: JsonData) => new ConformanceResult(d)) : [];
        this.testGenerations = data != null ? data.testGenerations?.map((d:JsonData) => new TestGeneration(d)) : [];
    }
}

export default ConformanceCheckingReport;