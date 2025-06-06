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
import Footprint from './Footprint';
import * as types from '../types';
import Sidebar from './Sidebar';
import {SplitPane} from 'react-multi-split-pane';
import {MatrixDiffEntry, MatrixEntry, ViewType} from './types';

interface Props {
    graph: types.Graph;
}

interface State {
    hovered: MatrixEntry | MatrixDiffEntry | null;
    viewType: ViewType;
}

class View extends React.Component<Props, State> {
    constructor(props: Props) {
        super(props);
        this.state = {hovered: null, viewType: 'before'};
    }

    render(): React.ReactNode {
        return (
            <SplitPane defaultSizes={[0.8, 0.3]}>
                <Footprint
                    viewType={this.state.viewType}
                    onHover={(hovered: MatrixEntry | MatrixDiffEntry) => {this.setState({hovered})}}
                    graph={this.props.graph}
                />
                <Sidebar
                    setViewType={(viewType: ViewType) => this.setState({viewType})}
                    viewType={this.state.viewType}
                    hovered={this.state.hovered}
                />
            </SplitPane>
        );
    }
}

export default View;
