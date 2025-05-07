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
class MetaInfo {
    public createdAt: Date;
    public taskName: string;

    constructor(jsonData: JsonData | null) {
        this.createdAt = jsonData != null ? new Date(jsonData.createdAt) : new Date();
        this.taskName = jsonData != null ? jsonData.taskName : "dummy";
    }
}

export default MetaInfo;