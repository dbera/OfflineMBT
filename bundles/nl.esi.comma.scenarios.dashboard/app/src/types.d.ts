export interface Node {
    actionName: string,
    changeType: (
        'node_added' | 'node_deleted' | 'node_updated' | 'data_added' | 'data_deleted' | 'data_updated' |
        'testset_removed' | 'testset_added' | 'product_removed' | 'product_added'
    )[],
    testSet: string[],
    productSet: string[],
    data: {dataMap: {key: string, value: string}[]}[]
}

export interface Edge {
    source: string,
    target: string,
    changeType:  'edge_added' | 'edge_deleted' | 'edge_updated' | '',
}

export interface Feature {
    name: string,
    path: string,
    productSet: string[],
}

export interface Footprint {
    table: {[s: string]: {[s: string]: number}},
    occurences: {[s: string]: number},
}

export interface Graph {
    nodes: {[s: string]: Node}
    edges: Edge[],
    meta: {
        features: {[s: string]: Feature},
        footprintA: Footprint,
        footprintB: Footprint,
    }
}
