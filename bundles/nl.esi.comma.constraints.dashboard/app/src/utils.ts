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

import {Node, Graph} from './types';

export function downloadFile(fileName: string, content: string) {
    const element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(content));
    element.setAttribute('download', fileName);
    element.style.display = 'none';
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
}

interface DfsNode {
    visited: boolean, 
    id: number,
    low: number,
    node: Node,
    outgoing: string[],
}

function scc_dfs(node: DfsNode, nodes: {[s: string]: DfsNode}, stack: string[]) {
    stack.push(node.node.name);
    node.visited = true;
    node.id = node.low = Object.values(nodes).filter((n) => n.visited).length;

    for (const neighbourID of node.outgoing) {
        const neighbour = nodes[neighbourID];
        if (!neighbour.visited) {
            scc_dfs(neighbour, nodes, stack);
        }
        if (stack.includes(neighbourID)) {
            node.low = Math.min(node.low, neighbour.low)
        }
    }

    if (node.id === node.low) {
        while (true) {
            const n = stack.pop() as string;
            nodes[n].low = node.id;
            if (n === node.node.name) break;
        }
    }
}

export function scc(graph: Graph) {
    const nodes = Object.fromEntries(Object.entries(graph.nodes).map((e) => {
        const n = {
            visited: false, id: -1, low: -1, node: e[1], 
            outgoing: graph.edges.filter((ee) => ee.source === e[0]).map((ee) => ee.target),
        };
        return [e[0], n];
    }));

    for (const node of Object.values(nodes)) {
        if (!node.visited) {
            scc_dfs(node, nodes, []);
        }
    }
    
    const result: {[s: number]: Node[]} = {};
    for (const node of Object.values(nodes)) {
        if (!(node.low in result)) result[node.low] = [];
        result[node.low].push(node.node);
    } 

    return Object.values(result);
}