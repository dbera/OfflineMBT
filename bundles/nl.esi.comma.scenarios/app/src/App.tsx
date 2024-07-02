import React from 'react';
import CssBaseline from '@material-ui/core/CssBaseline';
import Box from '@material-ui/core/Box';
import Header from './view/Header';
import ImpactedTestsView from './view/ImpactedTestsView';
import ProgressionTestsView from './view/ProgressionTestsView';
import RegressionTestsView from './view/RegressionTestsView';
import StatisticsOverview from './view/StatisticsOverview';
import ImpactAnalysisReport from './model/ImpactAnalysisReport';
import { JsonData } from './types';

// eslint-disable-next-line
interface IProps { }

interface IState {
    selectedViewId: string;
    report: ImpactAnalysisReport;
}

class App extends React.Component<IProps, IState> {
    constructor(props: IProps) {
        super(props);
        this.state = {
            selectedViewId: 'StatisticsOverview',
            report: new ImpactAnalysisReport(null)
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
            report: new ImpactAnalysisReport(loadedReport)
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
                <Box component="div" display={this.isViewSelected('StatisticsOverview') ? '' : 'none'}>
                    <StatisticsOverview definedTests={this.state.report.statisticsInfo.definedTests} 
                    definedConfigurations={this.state.report.statisticsInfo.definedConfigurations}
                    definedTestConfigPairs={this.state.report.statisticsInfo.definedTestConfigPairs}
                    estBuildTimeDefined={this.state.report.statisticsInfo.estBuildTimeDefined}
                    selectedTests={this.state.report.statisticsInfo.selectedTests}
                    selectedConfigurations={this.state.report.statisticsInfo.selectedConfigurations}
                    selectedTestConfigPairs={this.state.report.statisticsInfo.selectedTestConfigPairs}
                    estBuildTimeSelected={this.state.report.statisticsInfo.estBuildTimeSelected}
                    testConfigsOverview={this.state.report.testSelectionOverview}
                    progressionTests={this.state.report.progressionTestSet}
                    regressionTests={this.state.report.regressionTestSet}
                    configInfo={this.state.report.config}/>
                </Box>
                <Box component="div" display={this.isViewSelected('ImpactedTestsView') ? '' : 'none'}>
                    <ImpactedTestsView impactedTests={this.state.report.impactedTestSet} />
                </Box>
                <Box component="div" display={this.isViewSelected('ProgressionTestsView') ? '' : 'none'}>
                    <ProgressionTestsView progressionTests={this.state.report.progressionTestSet} />
                </Box>
                <Box component="div" display={this.isViewSelected('RegressionTestsView') ? '' : 'none'}>
                    <RegressionTestsView regressionTests={this.state.report.regressionTestSet} />
                </Box>
            </div>
        );
    }
}

export default App;
