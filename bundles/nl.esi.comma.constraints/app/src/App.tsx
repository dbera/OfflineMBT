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
import CssBaseline from '@material-ui/core/CssBaseline';
import Box from '@material-ui/core/Box';
import Header from './view/Header';
import TestGenerationView from './view/TestGenerationView';
import Overview from './view/Overview';
import { JsonData } from './types';
import ConformanceCheckingReport from './model/ConformanceCheckingReport';
import ViolatingSCNView from './view/ViolatingSCNView';

// eslint-disable-next-line
interface IProps { }

interface IState {
    selectedViewId: string;
    report: ConformanceCheckingReport;
}

class App extends React.Component<IProps, IState> {
    constructor(props: IProps) {
        super(props);
        this.state = {
            selectedViewId: 'Overview',
            report: new ConformanceCheckingReport(null)
        };
    }

    componentDidMount(): void {
        let loadedReport: JsonData;

        if (!process.env.NODE_ENV || process.env.NODE_ENV === 'development') {
            // eslint-disable-next-line
            loadedReport = require('./testdata.js').default;
            console.log(loadedReport);
        } else {
            // eslint-disable-next-line
            // @ts-ignore
            loadedReport = window.report;
        }

        this.setState({
            report: new ConformanceCheckingReport(loadedReport)
        });
    }

    isViewSelected(viewId: string): boolean {
        return (viewId == this.state.selectedViewId);
    }

    render(): React.ReactNode {
        return (
            <div className="App">

                <CssBaseline />
                <Header
                    toggleView={(viewId: string): void => {
                        this.setState({ selectedViewId: viewId });
                    }}
                    report={this.state.report} />
                <Box component="div" display={this.isViewSelected('Overview') ? '' : 'none'}>
                    <Overview conformanceResults={this.state.report.conformanceResults}/>
                </Box>
                <Box component="div" display={this.isViewSelected('ViolatingSCNView') ? '' : 'none'}>
                    <ViolatingSCNView conformanceResults={this.state.report.conformanceResults} />
                </Box>
                <Box component="div" display={this.isViewSelected('TestGenerationView') ? '' : 'none'}>
                    <TestGenerationView testGenerations={this.state.report.testGenerations} />
                </Box>
            </div>
        );
    }
}

export default App;
