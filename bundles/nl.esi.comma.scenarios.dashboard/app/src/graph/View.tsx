/*
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
import React from 'react';
import Graph from './Graph';
import * as types from '../types';
import Sidebar from './Sidebar';
import {SplitPane} from 'react-multi-split-pane';
import Dialog from './Dialog';
import {GraphOptions} from './types';

interface Props {
    graph: types.Graph;
}

interface State {
    highlightedNode: types.Node | null;
    selectedNodes: types.Node[];
    dialogTestSet: string[] | null;
    graphOptions: GraphOptions;
}

class View extends React.Component<Props, State> {
    constructor(props: Props) {
        super(props);
        this.state = {
            highlightedNode: null, selectedNodes: [], dialogTestSet: null,
            graphOptions: {edgeType: 'bezier', view: 'interactive', spacing: 10, minTestSet: 0}
        };
    }

    render(): React.ReactNode {
        return (
            <div style={{width: '100%', height: '100%'}}>
                <Dialog
                    graph={this.props.graph}
                    testSet={this.state.dialogTestSet}
                    clearTestSet={() => this.setState({dialogTestSet: null})}
                />
                <SplitPane defaultSizes={[0.8, 0.3]}>
                    <Graph 
                        setSelectedNodes={(selectedNodes: types.Node[]) => this.setState({selectedNodes})}
                        selectedNodes={this.state.selectedNodes}
                        highlightedNode={this.state.highlightedNode}
                        graph={this.props.graph} 
                        graphOptions={this.state.graphOptions}
                        onHighlightNode={(highlightedNode: types.Node | null) => this.setState({highlightedNode})}
                    />
                    <Sidebar
                        graph={this.props.graph}
                        setDialogTestSet={(dialogTestSet: string[]) => this.setState({dialogTestSet})}
                        selectedNodes={this.state.selectedNodes} 
                        setGraphOptions={(graphOptions: GraphOptions) => {this.setState({graphOptions})}}
                        graphOptions={this.state.graphOptions}
                        highlightedNode={this.state.highlightedNode}
                    />
                </SplitPane>
            </div>
        );
    }
}

export default View;
