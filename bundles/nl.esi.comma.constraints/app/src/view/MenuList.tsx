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
import ImpactAnalysisReport from '../model/ConformanceCheckingReport';
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
                <ListSubheader>{'Conformance Checking Result'}</ListSubheader>
                <List>
                    <ListItem button key='Conformance Overview' onClick={() => this.props.toggleView('Overview')}>
                        <ListItemText primary={'Overview'} />
                    </ListItem>
                    <ListItem button key='Violating Scenarios' onClick={() => this.props.toggleView('ViolatingSCNView')}>
                        <ListItemText primary={'Violating Scenarios'} />
                    </ListItem>
                    <ListItem button key='Test Generation' onClick={() => this.props.toggleView('TestGenerationView')}>
                        <ListItemText primary={'Test Generation'} />
                    </ListItem>
                </List>
            </div>);
    }
}

export default MenuList;