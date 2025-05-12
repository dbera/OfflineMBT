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
import Header from './Header';
import CssBaseline from '@mui/material/CssBaseline';
import './index.css';
import FootprintView from './footprint/View';
import GraphView from './graph/View';
import types from './types';

interface Props {}
interface State {
    view: 'footprint' | 'graph';
}

class App extends React.Component<Props, State> {
    graph: types.Graph;

    constructor(props: Props) {
        super(props);
       if (!process.env.NODE_ENV || process.env.NODE_ENV === 'development') {
            this.graph = require('./testdata.js').default.graph;
       } else {
           // @ts-expect-error
           this.graph = window.report.graph;
       }

        this.state = {view: 'graph'}
    }

    render(): React.ReactNode {
        return (
            <React.Fragment>
                <CssBaseline />
                <div style={{display: 'flex', flexDirection: 'column', height: '100vh', width: '100vw'}}>
                    <Header view={this.state.view} setView={(view: 'graph' | 'footprint') => this.setState({view})}/>
                    <div style={{flex: 1, minHeight: 0}}>
                        {this.state.view === 'footprint' && <FootprintView graph={this.graph}/>}
                        {this.state.view === 'graph' && <GraphView graph={this.graph}/>}
                    </div>
                </div>
            </React.Fragment>
        );
    }
}

export default App;
