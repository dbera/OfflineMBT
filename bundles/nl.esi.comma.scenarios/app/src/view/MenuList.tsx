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
import List from '@material-ui/core/List';
import Divider from '@material-ui/core/Divider';
import ListItem from '@material-ui/core/ListItem';
import ListItemText from '@material-ui/core/ListItemText';
import { ListSubheader } from '@material-ui/core';
import ImpactAnalysisReport from '../model/ImpactAnalysisReport';
interface IMenuListProps {
    toggleView(viewId: string): void;
    toggleDrawer(isOpen: boolean): React.MouseEventHandler<HTMLDivElement>;
    report: ImpactAnalysisReport;
}
class MenuList extends React.Component<IMenuListProps> {

    render(): React.ReactNode {
        return (
            <div onClick={this.props.toggleDrawer(false)}>
                <Divider />
                <ListSubheader>{'Test Impact Analysis Result'}</ListSubheader>
                <List>
                    <ListItem button key='Statistics Overview' onClick={() => this.props.toggleView('StatisticsOverview')}>
                        <ListItemText primary={'Statistics Overview'} />
                    </ListItem>
                    <ListItem button key='Impacted Test Set' onClick={() => this.props.toggleView('ImpactedTestsView')}>
                        <ListItemText primary={'Impacted Test Set (' + this.props.report.impactedTestSet.length + ')'} />
                    </ListItem>
                    <ListItem button key='Progression Test Set' onClick={() => this.props.toggleView('ProgressionTestsView')}>
                        <ListItemText primary={'Progression Test Set (' + this.props.report.progressionTestSet.length + ')'} />
                    </ListItem>
                    <ListItem button key='Regression Test Set' onClick={() => this.props.toggleView('RegressionTestsView')}>
                        <ListItemText primary={'Regression Test Set (' + this.props.report.regressionTestSet.length + ')'} />
                    </ListItem>
                    <ListItem button key='Causal Graph'>
                        <a href={'..\\test-gen\\DiffCausalGraph\\'+this.props.report.meta.taskName+'\\diffGraph.html'} target="_blank" rel="noopener noreferrer"><ListItemText primary={'Causal Graph'} /></a>
                    </ListItem>
                </List>
            </div>);
    }
}

export default MenuList;