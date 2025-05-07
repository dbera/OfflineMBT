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
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import * as types from '../types';
import Button from '@mui/material/Button';
import colors from './colors';
import ButtonGroup from '@mui/material/ButtonGroup';
import {GraphOptions} from './types';
import TextField from '@mui/material/TextField';
// @ts-expect-error
import { debounce } from "debounce";
import Slider from '@mui/material/Slider';
import Grid from '@mui/material/Grid';
import {EdgeType} from './types';

const legendCircle: React.CSSProperties = {width: '20px', height: '20px', borderRadius: '50%', marginRight: '10px'}
const legendCircleOuter: React.CSSProperties = {...legendCircle, backgroundColor: 'white', borderStyle: 'solid'}

interface Props {
    graph: types.Graph;
    highlightedNode: types.Node | null;
    selectedNodes: types.Node[];
    graphOptions: GraphOptions;
    setGraphOptions: (graphOptions: GraphOptions) => void;
    setDialogTestSet: (dialogTestSet: string[]) => void;
}

interface State {
    spacing: number;
}

class Sidebar extends React.Component<Props, State> {
    spacingChanged = debounce((spacing: number) => this.props.setGraphOptions({...this.props.graphOptions, spacing}), 1000);

    constructor(props: Props) {
        super(props);
        this.state = {spacing: props.graphOptions.spacing}
    }

    componentDidUpdate(prevProps: Props, prevState: State) {
        if (prevState.spacing !== this.state.spacing) {
            this.spacingChanged(this.state.spacing);
        }
    }

    render(): React.ReactNode {
        const intersectionTestSet = this.props.selectedNodes.length !== 0 ?
            this.props.selectedNodes.map((n) => n.testSet).reduce((a, b) => a.filter(c => b.includes(c))) : [];
        const unionTestSet = new Set(this.props.selectedNodes.map((n) => n.testSet).flat());

        let highlightedData = <div><b>Data:</b> -</div>;
        let highlightedTestSet = <div><b>Test set:</b> -</div>
        if (this.props.highlightedNode) {
            const data = Array.from(new Set(this.props.highlightedNode.data.map(d => d.dataMap.map(dd => dd.value).join(', '))));
            if (data.length === 0) {
                highlightedData = <div><b>Data:</b> None</div>
            } else {
                highlightedData = <div><b>Data:</b>{data.map((d, i) => <div key={i}>- {d}</div>)}</div>;
            }

            const testSet = Array.from(new Set(this.props.highlightedNode.testSet.map((t) => this.props.graph.meta.features[t].name)))
            highlightedTestSet = <div><b>Test set: </b>{testSet.map((d, i) => <div key={i}>- {d}</div>)}</div>;
        }

        const graphOptions = this.props.graphOptions;
        const edgeTypes: EdgeType[] = ['bezier', 'cont', 'curved'];
        const viewTypes: ('interactive' | 'svg')[] = ['interactive', 'svg'];
        const isInteractive = this.props.graphOptions.view === 'interactive';
        const testSetMax = Math.max(...Object.values(this.props.graph.nodes).map((n) => n.testSet.length));
        return (
            <div style={{backgroundColor: 'rgb(248, 248, 248)', width: '100%', padding: '10px', overflowY: 'auto'}}>
                <Card>
                    <CardContent>
                        <Typography sx={{ fontSize: 14 }} color="text.secondary" gutterBottom>
                            Graph options
                        </Typography>
                        <Typography variant="body2" component='span'>
                            <table style={{width: '100%'}}>
                                <tbody>
                                <tr>
                                    <td>View</td>
                                    <td>
                                        <ButtonGroup aria-label="outlined primary button group">
                                        {viewTypes.map((o, i) => 
                                            <Button 
                                                key={i} 
                                                onClick={() => this.props.setGraphOptions({...graphOptions, view: o})}
                                                variant={graphOptions.view === o ? 'contained' : 'outlined'}>
                                                {o}
                                            </Button>
                                        )}
                                        </ButtonGroup>
                                    </td>
                                </tr>
                                {isInteractive &&
                                <tr>
                                    <td>Edge type</td>
                                    <td>
                                        <ButtonGroup aria-label="outlined primary button group">
                                        {edgeTypes.map((o, i) => 
                                            <Button 
                                                key={i} 
                                                onClick={() => this.props.setGraphOptions({...graphOptions, edgeType: o})}
                                                variant={graphOptions.edgeType === o ? 'contained' : 'outlined'}>
                                                {o}
                                            </Button>
                                        )}
                                        </ButtonGroup>
                                    </td>
                                </tr>
                                }
                                <tr>
                                    <td>Spacing</td>
                                    <td>
                                        <TextField
                                            value={this.state.spacing}
                                            variant="standard" label={null} type="number"
                                            onChange={(e) => this.setState({spacing: parseInt(e.target.value)})}
                                        />
                                    </td>
                                </tr>
                                {isInteractive &&
                                <tr>
                                    <td>Min. testset</td>
                                    <td>
                                        <Grid container spacing={2} alignItems="center">
                                            <Grid item style={{flex: '1'}}>
                                                <Slider
                                                    value={this.props.graphOptions.minTestSet}
                                                    onChange={(e, v) =>
                                                        this.props.setGraphOptions({...graphOptions, minTestSet: v as number})}
                                                    max={testSetMax}
                                                    min={0}
                                                />
                                            </Grid>
                                            <Grid item>
                                                {this.props.graphOptions.minTestSet}
                                            </Grid>
                                        </Grid>
                                    </td>
                                </tr>
                                }
                                </tbody>
                            </table>
                        </Typography>
                    </CardContent>
                </Card>
                <Card style={{marginTop: '10px'}}>
                    <CardContent>
                        <Typography sx={{ fontSize: 14 }} color="text.secondary" gutterBottom>
                            Legend
                        </Typography>
                        <Typography variant="body2" component='span'>
                            <table>
                                <tbody>
                                    <tr>
                                        <td><div style={{backgroundColor: colors.added, ...legendCircle}}/></td>
                                        <td>node_added / data_added</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: colors.updated, ...legendCircle}}/></td>
                                        <td>node_updated / data_updated</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: colors.deleted, ...legendCircle}}/></td>
                                        <td>node_deleted / data_deleted</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: colors.nodeNoChanges, ...legendCircle}}/></td>
                                        <td>no_changes</td>
                                    </tr>
                                    {isInteractive &&
                                    <tr>
                                        <td><div style={{...legendCircleOuter, borderColor: colors.selected}}/></td>
                                        <td>selected</td>
                                    </tr>
                                    }
                                    {isInteractive &&
                                    <tr>
                                        <td><div style={{...legendCircleOuter, borderColor: colors.highlight}}/></td>
                                        <td>highlighted</td>
                                    </tr>
                                    }
                                </tbody>
                            </table>
                        </Typography>
                    </CardContent>
                </Card>
                {isInteractive &&
                <Card style={{marginTop: '10px'}}>
                    <CardContent>
                        <Typography sx={{ fontSize: 14 }} color="text.secondary" gutterBottom>
                            Selected nodes ({this.props.selectedNodes.length}) (right click to select)
                        </Typography>
                        <Typography variant="body2" component='span'>
                            <table style={{width: '100%'}}>
                                <tbody>
                                    <tr>
                                        <td>Union testcases</td>
                                        <td>{unionTestSet.size}</td>
                                        <td>
                                            <IconButton 
                                                color="primary" 
                                                disabled={unionTestSet.size === 0} 
                                                onClick={() => this.props.setDialogTestSet(Array.from(unionTestSet))}>
                                                <ArrowForwardIcon />
                                            </IconButton>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>Intersection testcases</td>
                                        <td>{intersectionTestSet.length}</td>
                                        <td>
                                            <IconButton 
                                                color="primary" 
                                                disabled={intersectionTestSet.length === 0} 
                                                onClick={() => this.props.setDialogTestSet(intersectionTestSet)}>
                                                <ArrowForwardIcon />
                                            </IconButton>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </Typography>
                    </CardContent>
                </Card>
                }
                {isInteractive &&
                <Card style={{marginTop: '10px'}}>
                    <CardContent>
                        <Typography sx={{ fontSize: 14 }} color="text.secondary" gutterBottom>
                            Highlighted node (hover/left click to highlight)
                        </Typography>
                        <Typography variant="body2" style={{wordBreak: 'break-all', textAlign: 'center'}}>
                            <b>{this.props.highlightedNode?.actionName || <i>Highlight a node</i>}</b>
                        </Typography>
                        <Typography variant="body2" style={{wordBreak: 'break-all'}}>
                            <b>Changes:</b> {this.props.highlightedNode?.changeType.join(', ') || '-'}
                        </Typography>
                        <Typography variant="body2" style={{wordBreak: 'break-all'}}>
                            <b>Product set:</b> {this.props.highlightedNode?.productSet.join(', ') || '-'}
                        </Typography>
                        <Typography component='span' variant="body2" style={{wordBreak: 'break-all'}}>
                            {highlightedData}
                        </Typography>
                        <Typography component='span' variant="body2" style={{wordBreak: 'break-all'}}>
                            {highlightedTestSet}
                        </Typography>
                    </CardContent>
                </Card>
                }   
            </div>
        );
    }
}

export default Sidebar;
