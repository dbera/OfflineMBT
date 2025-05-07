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
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import Paper from '@mui/material/Paper';
import * as Constant from '../model/Constants';
import TestGeneration from '../model/TestGeneration';
import FullDialog from './FullDialog';
import TransitionDialog from './TransitionDialog';
import SimilarityDialog from './SimilarityDialog';
import Similarity from '../model/Similarity';
interface ITestGenerationProps {
    testGenerations: TestGeneration[];
}

type TestGenerationState = {
    isShown: boolean;
    isOpen: boolean;
    isOpenTrans: boolean;
    isOpenSim: boolean;
    content: string;
    stats: {[key:string]:string[]};
    constraintId: string;
    similarity: Similarity[];
}

class TestGenerationView extends React.Component<ITestGenerationProps, TestGenerationState> {
    constructor(props:ITestGenerationProps){
        super(props);
        this.state = {
            isOpen: false,
            isOpenTrans: false,
            isOpenSim: false,
            content: '',
            isShown: false,
            stats: {},
            constraintId: '',
            similarity: []
        }
    }

    render(): React.ReactNode {
        const handleClickOpen = (open: boolean, content: string) => () => {
            this.setState({ ...this.state, ['isOpen']: open , ['content'] : content});
        };
        const handleClickTransition = (open: boolean, stats : {[key:string]:string[]}, constraintId: string) => () => {
            this.setState({...this.state, ['isOpenTrans']: open , ['stats'] : stats, ['constraintId'] : constraintId});
        };
        const handleClickSimilarity = (open: boolean, similarity : Similarity[], constraintId: string) => () => {
            this.setState({...this.state, ['isOpenSim']: open , ['similarity'] : similarity, ['constraintId'] : constraintId});
        };
        return (
            <div style={{ display: "block", padding: 80, width: '100%' }}>
                <TableContainer component={Paper}>
                    <Table style={{width: '100%'}} size="small">
                    <TableHead>
                        <Constant.StyledTableRow>
                            <Constant.StyledTableCell>Index</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="20%">Constraint Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="20%">Configurations</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="50%">Statistics</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="10%">File Name</Constant.StyledTableCell>
                        </Constant.StyledTableRow>
                    </TableHead>
                    <TableBody>
                    {
                        this.props.testGenerations.map((test:TestGeneration, index:number) => (
                            <Constant.StyledTableRow key={index} sx={{ '&:last-child td, &:last-child th': { border: 0 } }} style={{verticalAlign: 'top'}}>
                                <Constant.StyledTableCell align="left">{index}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'200px', maxWidth:'200px'}}><div>{test.constraintName}
                                {test.base64Dot ? (<div><button onClick={handleClickOpen(true, test.base64Dot)}>SVG</button></div>) : ''}
                                {this.state.isShown && (
                                    <div>{test.constraintText.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</div>
                                )}</div></Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'200px', maxWidth:'260px'}}>{test.configurations.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</Constant.StyledTableCell>
                                <Constant.StyledTableCell>
                                    <div>
                                        <b>Algorithm: </b>{test.statistics.algorithm}<br/>
                                        <b>Transitions in automaton: </b>{test.statistics.amountOfTransitionsInAutomaton}<br/>
                                        <b>Transitions covered by existing testcases: </b>{test.statistics.percentageTransitionsCoveredByExistingScenarios.toFixed(2)}%<br/>
                                        <b>States in automaton: </b>{test.statistics.amountOfStatesInAutomaton}<br/>
                                        <b>Sequences: </b>{test.statistics.amountOfPaths}<br/>
                                        <b>Steps: </b>{test.statistics.amountOfSteps}<br/>
                                        <b>Average steps per sequence: </b>{test.statistics.averageAmountOfStepsPerSequence.toFixed(2)}<br/>
                                        <b>State coverage: </b>{test.statistics.percentageOfStatesCovered.toFixed(2)}%<br/>
                                        <b>Transition coverage: </b>{test.statistics.percentageOfTransitionsCovered.toFixed(2)}%<br/>
                                        <b>Average transition execution:</b>{test.statistics.averageTransitionExecution.toFixed(2)}<br/>
                                        <br/>
                                        <div><button onClick={handleClickTransition(true, test.statistics.timesTransitionIsExecuted, test.constraintName)}>Times Transition Executed</button></div>
                                        <br/>
                                        <div><button onClick={handleClickSimilarity(true, test.similarities, test.constraintName)}>Similarity to Existing Tests</button></div>
                                    </div>
                                </Constant.StyledTableCell>
                                <Constant.StyledTableCell>{test.featureFileLocation}</Constant.StyledTableCell>
                            </Constant.StyledTableRow>
                        ))
                    }
                    </TableBody>
                    </Table>
                </TableContainer>
                <FullDialog
                    open={this.state.isOpen}
                    content={this.state.content}
                    option={"graph"}
                    handleClickOpen={handleClickOpen}
                />
                <TransitionDialog
                    open={this.state.isOpenTrans}
                    stats={this.state.stats}
                    consId={this.state.constraintId}
                    handleClickTransition={handleClickTransition}
                />
                <SimilarityDialog
                    open={this.state.isOpenSim}
                    similarity={this.state.similarity}
                    consId={this.state.constraintId}
                    handleClickSimilarity={handleClickSimilarity}
                />
            </div>
        )
    }
}

export default TestGenerationView;