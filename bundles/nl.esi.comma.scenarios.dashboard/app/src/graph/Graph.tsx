import React from 'react';
import types from '../types';
import colors from './colors';
import {EdgeType, GraphOptions} from './types';
import svgPanZoom from '@dash14/svg-pan-zoom';
import dotWorkerScript from "./dotWorker";
import {Network, Options} from 'vis-network';
import {DataSet} from 'vis-data';

const colorLookup: {[s: string]: string} = {
  node_added: colors.added,
  data_added: colors.added,
  node_updated: colors.updated,
  data_updated: colors.updated,
  node_deleted: colors.deleted,
  data_deleted: colors.deleted,
  edge_added: colors.added,
  edge_updated: colors.updated,
  edge_removed: colors.deleted,
  edge_deleted: colors.deleted,
}

interface Props {
    highlightedNode: types.Node | null;
    graph: types.Graph;
    onHighlightNode: (highlightedNode: types.Node | null) => void;
    selectedNodes: types.Node[];
    graphOptions: GraphOptions;
    setSelectedNodes: (selectedNode: types.Node[]) => void;
}

interface State {
    loading: boolean;
}

class GraphView extends React.Component<Props, State> {
    container: React.RefObject<HTMLDivElement>;
    stickyHighlightedNode: types.Node | null = null;
    cache: {[s: string]: string} = {};
    dotWorker: Worker | null = null;
    vis: Network | null = null;

    constructor(props: Props) {
        super(props);
        this.container = React.createRef();
        this.state = {loading: false};
    }

    async getDot(output: 'json' | 'svg'): Promise<string> {
        const cacheKey = `${output}_${this.props.graphOptions.spacing}`;
        if (this.cache[cacheKey]) {
            return this.cache[cacheKey];
        }

        const ranksep = this.props.graphOptions.spacing / 10;
        const dot = `digraph G {
            graph [pad="0", ranksep="${ranksep}", nodesep="0.25"];
            ${Object.values(this.props.graph.nodes).map((n) => {
                return `${n.actionName} [fillcolor="${this.getNodeColor(n)}" style=filled];`
            }).join('\n')}
            ${this.props.graph.edges.map((e) => `${e.source} -> ${e.target} [color="${this.getEdgeColor(e)}" penwidth=3];`).join('\n')}
        }`;

        return new Promise((resolve) => {
            this.dotWorker = new Worker(dotWorkerScript); 
            this.dotWorker.onmessage = (m) => {
                this.cache[cacheKey] = m.data;
                resolve(m.data);
            };

            this.dotWorker.postMessage({dot, output});
        });
    }

    getNodeColor(node: types.Node): string {
        let color = colors.nodeNoChanges;
        const nodeChange = node.changeType.find((c) => c.startsWith("node_"));
        const dataChange = node.changeType.find((c) => c.startsWith("data_"));
        if (nodeChange) color = colorLookup[nodeChange];
        else if (dataChange) color = colorLookup[dataChange];
        return color;
    }

    getEdgeColor(edge: types.Edge): string {
        let color = colors.edgeNoChanges;
        if (edge.changeType !== '') color = colorLookup[edge.changeType];
        return color;
    }

    componentDidUpdate(prevProps: Props) {
        for (const property of Object.keys(prevProps.graphOptions)) {
            if (property !== 'minTestSet' && 
                    (prevProps.graphOptions as any)[property] !== (this.props.graphOptions as any)[property]) {
                this.renderGraph();
                break;
            }
        }

        if (prevProps.selectedNodes !== this.props.selectedNodes ||
            prevProps.highlightedNode !== this.props.highlightedNode ||
            prevProps.graphOptions.minTestSet !== this.props.graphOptions.minTestSet) {
            this.updateNodes();
        }
    }

    updateNodes() {
        const lessVisibleNodesIDs = Object.values(this.props.graph.nodes)
            .filter(n => n.testSet.length < this.props.graphOptions.minTestSet).map(n => n.actionName);

        const higlightedAction = this.props.highlightedNode?.actionName;
        const connectedToHighlightedAction = this.props.graph.edges
            .filter((e) => e.source === higlightedAction || e.target === higlightedAction)
            .map((e) => e.source === higlightedAction ? e.target : e.source);
        for (const node of Object.values(this.props.graph.nodes)) {
            let color = this.getNodeColor(node);
            let borderColor = color;
            if (node === this.props.highlightedNode || connectedToHighlightedAction.includes(node.actionName)) {
                borderColor = colors.highlight;
            } else if (this.props.selectedNodes.includes(node)) borderColor = colors.selected;

            if (lessVisibleNodesIDs.includes(node.actionName)) {
                color += '10';
                borderColor += '10';
            }


            // @ts-ignore
            const visNode = this.vis.body.nodes[node.actionName];
            visNode.options.color.background = color;
            visNode.options.color.border = borderColor;
            visNode.options.color.highlight = {border: visNode.options.color.border, background: visNode.options.color.background}
            visNode.options.color.hover = {border: visNode.options.color.border, background: visNode.options.color.background}

            let fontColor = colors.black;
            if (lessVisibleNodesIDs.includes(node.actionName)) fontColor += '18';
            if (visNode.options.font.color !== fontColor) {
                visNode.setOptions({font: {color: fontColor}})
            }
        }

        for (let i = 0; i < this.props.graph.edges.length; i++) {
            const edge = this.props.graph.edges[i];
            let color = this.getEdgeColor(edge);
            let width = 0;
            if (higlightedAction === edge.source || higlightedAction === edge.target) {
                color = colors.highlight;
                width = 2;
            }

            if (lessVisibleNodesIDs.includes(edge.source) || lessVisibleNodesIDs.includes(edge.target)) color += '10';

            // @ts-ignore
            const options = this.vis.body.edges[`edge_${i}`].options;
            options.color.color = color;
            options.color.highlight = color;
            options.color.hover = color;
            options.selectionWidth = width;
            options.hoverWidth = width;
        }

        // @ts-ignore
        this.vis.body.emitter.emit('_dataChanged');
        this.vis?.redraw();
    }

    componentDidMount() {
        this.renderGraph();
    }

    async renderGraph() {
        this.setState({loading: true});
        this.dotWorker?.terminate();
        this.container.current!.innerHTML = "";
        if (this.props.graphOptions.view === 'interactive') {
            await this.renderGraphInteractive();
        } else {
            await this.renderGraphSVG();
        }
        this.setState({loading: false});
    }

    async renderGraphSVG() {
        const svg = await this.getDot('svg');
        this.container.current!.innerHTML = svg;
        const element = this.container.current!.children[0] as SVGElement;
        element.style.cssText = "width: 100%; height: 100%";
        svgPanZoom(element, {zoomScaleSensitivity: 1, maxZoom: 20});
    }

    async renderGraphInteractive() {
        const graph = this.props.graph;
        const dot = JSON.parse((await this.getDot('json'))).objects;
        const nodes = new DataSet(Object.values(graph.nodes).map((n) => {
            const position = dot.find((o: any) => o.name === n.actionName).pos.split(',').map((n: string) => parseFloat(n));
            return {
                borderWidth: 2,
                id: n.actionName, label: `${n.actionName} [${n.testSet.length}]`, x: position[0], 
                y: position[1] * -1,
            };
        }));

        const edges = new DataSet(graph.edges.map((e, i) => {
            return {width: 2, id: 'edge_' + i.toString(), from: e.source, to: e.target, hoverWidth: 0, color: {inherit: false}};
        }));

        const edgeTypeMapping: {[s in EdgeType]: string} = {
            cont: 'continuous',
            bezier: 'cubicBezier',
            curved: 'curvedCW',
        }

        const options: Options = {
            interaction:{
                hover: true,
            },
            physics: {
                enabled: false
            },
            edges: {
                smooth: {
                    enabled: true,
                    type: edgeTypeMapping[this.props.graphOptions.edgeType],
                    forceDirection: false,
                    roundness: 0.3
                },
                arrows: {
                    to: {enabled: true, type: 'arrow'}
                  }
            }
        };

        // @ts-ignore
        this.vis = new Network(this.container.current!, {nodes, edges}, options);

        this.vis.on('hoverNode', (evt: any) => {
            if (this.stickyHighlightedNode === null) {
                this.props.onHighlightNode(graph.nodes[evt.node]);
            }
        });

        this.vis.on('blurNode', (evt: any) => {
            if (this.stickyHighlightedNode === null) {
                this.props.onHighlightNode(null);
            }
        });

        this.vis.on('selectNode', (evt: any) => {
            if (evt.nodes.length !== 0) {
                const node = graph.nodes[evt.nodes[0]];
                this.stickyHighlightedNode = node;
                this.props.onHighlightNode(this.stickyHighlightedNode);
            }
        });

        this.vis.on('deselectNode', (evt: any) => {
            this.stickyHighlightedNode = null;
            this.props.onHighlightNode(null);
        });

        this.vis.on('oncontext', (evt: any) => {
            evt.event.preventDefault();
            const name = this.vis?.getNodeAt(evt.pointer.DOM);
            if (name) {
                const node = graph.nodes[name];
                if (this.props.selectedNodes.includes(node)) {
                    this.props.setSelectedNodes(this.props.selectedNodes.filter((n) => n !== node));
                } else {
                    this.props.setSelectedNodes([...this.props.selectedNodes, node]);
                }
            }
        });

        this.updateNodes();
    }

    render(): React.ReactNode {
        return (
            <div style={{width: '100%', height: '100%'}}>
                <div style={{width: '100%', height: '100%', position: 'absolute'}} ref={this.container}/>
                {this.state.loading && <div style={{position: 'absolute', top: '50%', left: '50%'}}>Loading...</div>}
            </div>
        );
    }
}

export default GraphView;
