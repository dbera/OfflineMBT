import React from 'react';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import ButtonGroup from '@mui/material/ButtonGroup';
import {MatrixDiffEntry, MatrixEntry, ViewType} from './types';
const legendCircle = {width: '20px', height: '20px', marginRight: '10px', border: '2px solid black'}
const legendLine = {width: '20px', height: '7px', marginRight: '10px'}

interface Props {
    hovered: MatrixEntry | MatrixDiffEntry | null;
    viewType: ViewType;
    setViewType: (viewType: ViewType) => void;
}

class Sidebar extends React.Component<Props> {
    render(): React.ReactNode {
        const hovered = this.props.hovered;
        const buttons: ViewType[] = ['before', 'after', 'diff'];
        return (
            <div style={{backgroundColor: 'rgb(248, 248, 248)', width: '100%', padding: '10px', overflowY: 'auto'}}>
                <Card>
                    <CardContent style={{textAlign: 'center'}}>
                        <ButtonGroup>
                            {buttons.map((b, i) => 
                                <Button 
                                    key={i}
                                    onClick={() => this.props.setViewType(b)}
                                    variant={this.props.viewType === b ? 'contained' : 'outlined'}
                                >
                                    {b}
                                </Button>
                            )}
                        </ButtonGroup>
                    </CardContent>
                </Card>
                <Card style={{marginTop: '10px'}}>
                    <CardContent>
                        <Typography sx={{ fontSize: 14 }} color="text.secondary" gutterBottom>
                            Legend
                        </Typography>
                        <Typography variant="body2" component='span'>
                            Columns: left (Y-axis) is directly followed by top (X-axis):
                            <table>
                                <tbody>
                                    <tr>
                                        <td><div style={{backgroundColor: 'green', ...legendCircle}}/></td>
                                        <td>always</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: 'yellow', ...legendCircle}}/></td>
                                        <td>sometimes</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: 'lightgray', ...legendCircle}}/></td>
                                        <td>never</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: 'red', ...legendCircle}}/></td>
                                        <td>does not exist (only for diff)</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: 'white', ...legendCircle}}/></td>
                                        <td>no change (only for diff)</td>
                                    </tr>
                                </tbody>
                            </table>
                           Rows: changes to node data (only for diff):
                            <table>
                                <tbody>
                                    <tr>
                                        <td><div style={{backgroundColor: 'green', ...legendLine}}/></td>
                                        <td>data/testset/product added</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: 'yellow', ...legendLine}}/></td>
                                        <td>data updated</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: 'red', ...legendLine}}/></td>
                                        <td>data/testset/product removed</td>
                                    </tr>
                                    <tr>
                                        <td><div style={{backgroundColor: 'lightgrey', ...legendLine}}/></td>
                                        <td>no changes</td>
                                    </tr>
                                </tbody>
                            </table>
                        </Typography>
                    </CardContent>
                </Card>
                <Card style={{marginTop: '10px'}}>
                    <CardContent>
                        <Typography sx={{ fontSize: 14 }} color="text.secondary" gutterBottom>
                            Hovered
                        </Typography>
                        <Typography variant="body2" style={{wordBreak: 'break-all', textAlign: 'center'}} component={'span'}>
                            {!hovered && <i>Hover on a cell</i>}
                            {(hovered && 'mode' in hovered) &&
                                <div>
                                    <i>{hovered.nx.actionName}</i><br/>
                                    <b>{hovered.mode}</b> directly follows<br/>
                                    <i>{hovered.ny.actionName}</i><br/>
                                    ({hovered.followsCount} out of {hovered.occurence})
                                </div>
                            }
                            {(hovered && 'modeBefore' in hovered) &&
                                <div>
                                    <i>{hovered.nx.actionName}</i><br/>
                                    <b>{'...'}</b> directly follows<br/>
                                    <i>{hovered.ny.actionName}</i><br/>
                                    <br/>
                                    <div style={{textAlign: 'left'}}>
                                        Before: {hovered.modeBefore}<br/>
                                        After: {hovered.modeAfter}<br/>
                                        X-node: {hovered.nx.actionName} ({hovered.nx.changeType.join(', ')})<br/>
                                        Y-node: {hovered.ny.actionName} ({hovered.ny.changeType.join(', ')})
                                    </div>
                                </div>
                            }
                        </Typography>
                    </CardContent>
                </Card>
            </div>
        );
    }
}

export default Sidebar;
