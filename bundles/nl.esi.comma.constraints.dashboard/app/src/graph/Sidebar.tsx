import React from 'react';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Typography from '@mui/material/Typography';
import * as types from '../types';
import Button from '@mui/material/Button';
import colors from './colors';
import ButtonGroup from '@mui/material/ButtonGroup';
import {GraphOptions} from './types';
import TextField from '@mui/material/TextField';
// @ts-expect-error
import { debounce } from "debounce";
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

    connectedNodes() {
        let connectedNodes = new Set<types.Node>();
        if (this.props.selectedNodes.length !== 0) {
            for (const node of this.props.selectedNodes){
                for (const e of this.props.graph.edges) {
                    if (e.source === node.name){
                        connectedNodes.add(this.props.graph.nodes[e.target]);
                    }
                    if (e.target === node.name){
                        connectedNodes.add(this.props.graph.nodes[e.source]);
                    }
                }
            }
        }
        return connectedNodes;
    }

    render(): React.ReactNode {
        //const connectedNodes = this.props.selectedNodes.length !== 0 ?
            //this.props.selectedNodes.map((n) => ).reduce((a, b) => a.filter(c => b.includes(c))) : [];
        // const unionTestSet = new Set(this.props.selectedNodes.map((n) => n.testSet).flat());

        let missingConstraints = <div></div>;
        //let highlightedTestSet = <div><b>Test set:</b> -</div>
        if (this.props.highlightedNode) {
            if (this.props.highlightedNode.missing?.length > 0){
                missingConstraints = <div><b>Missing:</b> {this.props.highlightedNode.missing?.map(d => <div>- {d}</div>)}</div>;
            } else {
                missingConstraints = <div><b>Missing:</b> None</div>;
            }
            // const data = Array.from(new Set(this.props.highlightedNode.data.map(d => d.dataMap.map(dd => dd.value).join(', '))));
            // if (data.length === 0) {
            //     highlightedData = <div><b>Data:</b> None</div>
            // } else {
            //     highlightedData = <div><b>Data:</b>{data.map((d, i) => <div key={i}>- {d}</div>)}</div>;
            // }

           // const testSet = Array.from(new Set(this.props.highlightedNode.testSet.map((t) => this.props.graph.meta.features[t].name)))
            //highlightedTestSet = <div><b>Test set: </b>{testSet.map((d, i) => <div key={i}>- {d}</div>)}</div>;
        }

        const graphOptions = this.props.graphOptions;
        const edgeTypes: EdgeType[] = ['bezier', 'cont', 'curved'];
        const viewTypes: ('interactive' | 'svg')[] = ['interactive', 'svg'];
        const isInteractive = this.props.graphOptions.view === 'interactive';
        //const testSetMax = Math.max(...Object.values(this.props.graph.nodes).map((n) => 0));
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
                                {/* {isInteractive &&
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
                                } */}
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
                                        <td><div style={{backgroundColor: colors.black, ...legendCircle}}/></td>
                                        <td>Response</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: colors.red, ...legendCircle}}/></td>
                                        <td>Precedence</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: colors.blue, ...legendCircle}}/></td>
                                        <td>Dependency</td>
                                    </tr>
                                    {/* {isInteractive &&
                                    <tr>
                                        <td><div style={{...legendCircleOuter, borderColor: colors.selected}}/></td>
                                        <td>selected</td>
                                    </tr>
                                    } */}
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
                {/* {isInteractive &&
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
                                        <td></td>
                                        <td>
                                            <IconButton 
                                                color="primary" 
                                                disabled={true} 
                                                >
                                                <ArrowForwardIcon />
                                            </IconButton>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>Intersection testcases</td>
                                        <td></td>
                                        <td>
                                            <IconButton 
                                                color="primary" 
                                                disabled={true} 
                                                >
                                                <ArrowForwardIcon />
                                            </IconButton>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </Typography>
                    </CardContent>
                </Card>
                } */}
                {isInteractive &&
                <Card style={{marginTop: '10px'}}>
                    <CardContent>
                        <Typography sx={{ fontSize: 14 }} color="text.secondary" gutterBottom>
                            Highlighted node (hover/left click to highlight)
                        </Typography>
                        <Typography variant="body2" style={{wordBreak: 'break-all', textAlign: 'center'}}>
                            <b>{this.props.highlightedNode?.name || <i>Highlight a node</i>}</b>
                        </Typography>
                        <Typography component='span' variant="body2" style={{wordBreak: 'break-all'}}>
                            {missingConstraints}
                        </Typography>
                        {/* <Typography component='span' variant="body2" style={{wordBreak: 'break-all'}}>
                            {highlightedTestSet}
                        </Typography> */}
                    </CardContent>
                </Card>
                }   
            </div>
        );
    }
}

export default Sidebar;
