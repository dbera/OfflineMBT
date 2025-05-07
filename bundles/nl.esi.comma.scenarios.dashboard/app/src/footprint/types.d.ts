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

import {Node} from '../types';

export type Mode = 'sometimes' | 'always' | 'never' | 'does_not_exist';

export interface MatrixEntryBase {
    ID: string; x: number; y: number; nx: Node; ny: Node;
}

export interface MatrixDiffEntry extends MatrixEntryBase {
    modeBefore: Mode; modeAfter: Mode;
}

export interface MatrixEntry extends MatrixEntryBase {
    occurence: number; followsCount: number; mode: Mode;
}

export type ViewType = 'before' | 'after' | 'diff';