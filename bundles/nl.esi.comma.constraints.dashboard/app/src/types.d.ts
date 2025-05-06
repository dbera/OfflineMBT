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

export interface Node {
    name: string,
    missing: string[]
    // changeType: (
    //     'node_added' | 'node_deleted' | 'node_updated' | 'data_added' | 'data_deleted' | 'data_updated' |
    //     'testset_removed' | 'testset_added' | 'product_removed' | 'product_added'
    // )[],
    // testSet: string[],
    // productSet: string[],
    // data: {dataMap: {key: string, value: string}[]}[]
}

export interface Edge {
    name: string,
    source: string,
    target: string,
    type:  'right' | 'dashedRight' | 'both' | 'dashedBoth' | 'left' | 'dashedLeft' | 'none' | '',
}

export interface Graph {
    nodes: {[s: string]: Node}
    edges: Edge[]
}
