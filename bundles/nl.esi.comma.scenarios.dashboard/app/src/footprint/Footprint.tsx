import React from 'react';
import * as types from '../types';
import {MatrixDiffEntry, MatrixEntry, MatrixEntryBase, Mode, ViewType} from './types';
import svgPanZoom from '@dash14/svg-pan-zoom';
// @ts-expect-error
import * as d3 from 'd3';

interface Props {
    graph: types.Graph;
    onHover: (hovered: MatrixEntry | MatrixDiffEntry) => void;
    viewType: ViewType;
}

const colorLookup = {
    sometimes: 'yellow',
    always: 'green',
    never: 'lightgray',
    does_not_exist: 'red',
}

class FootprintView extends React.Component<Props> {
    container: React.RefObject<HTMLDivElement>;
    cache: {[s: string]: SVGElement} = {};

    constructor(props: Props) {
        super(props);
        this.container = React.createRef();
    }

    getNodesAndMatrix(): [string[], (MatrixEntry | MatrixDiffEntry)[]] {
        const matrix: (MatrixEntry | MatrixDiffEntry)[] = [];
        let nodes: string[] = [];

        const getMode = (n1: string, n2: string, footprint: types.Footprint): {mode: Mode, occurence: number, followsCount: number} => {
            if (n1 in footprint.occurences && n2 in footprint.occurences) {
                const occurence = footprint.occurences[n1];
                const followsCount = footprint.table[n1][n2];

                let mode: Mode = 'sometimes';
                if (occurence === followsCount) mode = 'always';
                if (followsCount === 0) mode = 'never';
                return {occurence, followsCount, mode};
           }
           return {occurence: -1, followsCount: -1, mode: 'does_not_exist'};
       }

        if (this.props.viewType === 'diff') {
            const before = this.props.graph.meta.footprintA;
            const after = this.props.graph.meta.footprintB;
            nodes = Array.from(new Set([...Object.keys(before.occurences),
                ...Object.keys(after.occurences)]))

            for (const n1 of nodes) {
                for (const n2 of nodes) {
                   matrix.push({
                       ID: `${n1}_${n2}`,
                        x: nodes.indexOf(n2),
                        y: nodes.indexOf(n1),
                        modeBefore: getMode(n1, n2, before).mode,
                        modeAfter: getMode(n1, n2, after).mode,
                        ny: this.props.graph.nodes[n1],
                        nx: this.props.graph.nodes[n2],
                    })
                }
            }
        } else {
            const footprint = this.props.viewType === 'before' ?
                this.props.graph.meta.footprintA :
                this.props.graph.meta.footprintB;
            
            nodes = Object.keys(footprint.occurences);
            for (const n1 of nodes) {
                for (const n2 of nodes) {
                    matrix.push({
                        ID: `${n1}_${n2}`,
                        x: nodes.indexOf(n2),
                        y: nodes.indexOf(n1),
                        ny: this.props.graph.nodes[n1],
                        nx: this.props.graph.nodes[n2],
                        ...getMode(n1, n2, footprint),
                    })
                }
            }
        }
        return [nodes, matrix];
    }

    getNodeAxisColor(n: string): string {
        const node = this.props.graph.nodes[n];
        if (node.changeType.includes('data_added') || node.changeType.includes('testset_added') || 
            node.changeType.includes('product_added')) return 'green';
        else if (node.changeType.includes('data_updated')) return 'yellow';
        else if (node.changeType.includes('data_deleted') || node.changeType.includes('testset_removed') || 
            node.changeType.includes('product_removed')) return 'red';
        return 'lightgrey';
    }

    renderFootprint() {
        this.container.current!.innerHTML = "";
        if (this.cache[this.props.viewType]) {
            this.container.current?.appendChild(this.cache[this.props.viewType]);
            return;
        }

        const svgElement = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        svgElement.style.cssText = "width: 100%; height: 100%";
        this.container.current!.appendChild(svgElement);
        this.cache[this.props.viewType] = svgElement;

        const svg = d3.select(svgElement);
        const [nodes, matrix] = this.getNodesAndMatrix();

        svg
            .append('g')
            .attr('id', 'adjacencyG')

        if (this.props.viewType === 'diff') {
            for (const mode of ['modeBefore', 'modeAfter'] as ('modeBefore' | 'modeAfter')[]) {
                d3.select('#adjacencyG')
                    .append('g')
                    .selectAll('rect')
                    .data(matrix)
                    .enter()
                    .append('rect')
                    .attr('width', 12.5)
                    .attr('height', 25)
                    .attr('x', (d: MatrixDiffEntry) => (d.x * 25) + (mode === 'modeAfter' ? 12.5 : 0))
                    .attr('y', (d: MatrixDiffEntry) => d.y * 25)
                    .style('fill', (d: MatrixDiffEntry) => d.modeBefore === d.modeAfter ? 'white' : colorLookup[d[mode]])
            }

            for (const axis of ['x', 'y']) {
                d3.select('#adjacencyG')
                    .append('g')
                    .selectAll('rect')
                    .data(nodes)
                    .enter()
                    .append('rect')
                    .attr('width', axis === 'x' ? 20 : 10)
                    .attr('height', axis === 'y' ? 20 : 10)
                    .attr('x', (d: string) => axis === 'y' ? (nodes.indexOf(d) * 25) + 7.5 : -20)
                    .attr('y', (d: string) => axis === 'x' ? (nodes.indexOf(d) * 25) + 7.5 : -20)
                    .style('fill', (d: string) => this.getNodeAxisColor(d))
            }
        }

        d3.select('#adjacencyG')
            .append('g')
            .selectAll('rect')
            .data(matrix)
            .enter()
            .append('rect')
            .attr('class', 'node')
            .attr('width', 25)
            .attr('height', 25)
            .attr('x', (d: MatrixEntryBase) => d.x * 25)
            .attr('y', (d: MatrixEntryBase) => d.y * 25)
            .style('stroke', 'black')
            .style('stroke-width', '1px')
            .style('fill', (d: MatrixEntry | MatrixDiffEntry) => 'mode' in d && colorLookup[d.mode])
            .style('fill-opacity', (d: MatrixEntry | MatrixDiffEntry) => 'mode' in d  ? 1 : 0)
            .on('mouseover', (d: {target: {__data__: MatrixEntry | MatrixDiffEntry}}) => {
                const hovered = d.target.__data__;
                this.props.onHover(hovered);
                d3.selectAll('.node').style('stroke-width', (e: MatrixEntryBase) => {
                    return e.nx.actionName === hovered.nx.actionName || e.ny.actionName === hovered.ny.actionName ? '5px' : '1px';
                });
            })

        const nameScale = d3
            .scaleBand()
            .domain(d3.range(0, nodes.length))
            .rangeRound([0, nodes.length * 25]);

        const tickSizeInner = this.props.viewType === 'diff' ? 0 : 6;
        const tickPadding = this.props.viewType === 'diff' ? 16 : 3;
        const xAxis = d3.axisTop(nameScale).tickSize(4).tickSizeInner(tickSizeInner).tickPadding(tickPadding).tickFormat((i: number) => nodes[i]);
        const yAxis = d3.axisLeft(nameScale).tickSize(4).tickSizeInner(tickSizeInner).tickPadding(tickPadding).tickFormat((i: number) => nodes[i]);

        d3.select('#adjacencyG')
            .append('g')
            .call(xAxis)
            .selectAll('text').style('text-anchor', 'end')
            .attr('transform', this.props.viewType === 'diff' ? 'translate(-18, -25) rotate(90)' : 'translate(-10, -10) rotate(90)');
        d3.select('#adjacencyG')
            .append('g')
            .call(yAxis)
            .selectAll('text').style('text-anchor', 'end')
            .attr('transform', this.props.viewType === 'diff' ? 'translate(-10, 0)' : 'translate(0, -0)');
            
        // Resize SVG to be at least as tall as required.
        const node = d3.select('#adjacencyG').node();
        if (node) {
            const box = node.getBBox();
            d3.select('#adjacencyG').attr('transform', `translate(${-1 * box.x}, ${-1 * box.y})`);
            svg.attr('height', box.height);
        }

        svgPanZoom(svgElement);
    }

    componentDidMount() {
        this.renderFootprint();
    }

    componentDidUpdate(prevProps: Props) {
        if (prevProps.viewType !== this.props.viewType) {
            this.renderFootprint();
        }
    }

    render(): React.ReactNode {
        return (
            <div style={{width: '100%', height: '100%'}} ref={this.container}/> 
        );
    }
}

export default FootprintView;
