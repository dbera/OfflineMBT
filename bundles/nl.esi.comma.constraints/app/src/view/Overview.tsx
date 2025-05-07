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

import React, { useState } from 'react';
import TableContainer from '@mui/material/TableContainer';
import Paper from '@mui/material/Paper';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableHead from '@mui/material/TableHead';
import * as Constant from '../model/Constants';
import ConformanceResult from '../model/ConformanceResult';
import ConformingScenario from '../model/ConformingScenario';
import FullDialog from './FullDialog';

interface IOverviewProps {
    conformanceResults: ConformanceResult[];
}

function Overview(props:IOverviewProps): JSX.Element{
    const [isOpen, setOpen] = useState(false);
    const [content, setContent] = useState('');
    const [option, setOption] = useState('');
    const [constraintId, setConstraintId] = useState<number>();
    const [scnId, setScnId] = useState<number>();

    function highlighted(scn: ConformingScenario, item: string): React.ReactNode{
        if (scn.highlighted.includes(item)){
            return <b>{item}</b>;
        } else {
            return item;
        }
    }

    function decimalValue(coverage : number) : string {
        if (coverage.toString().indexOf('.') !== -1){
            return coverage.toFixed(4);
        } else {
            return coverage.toString();
        }
    }

    const isShown = (idx:number, index:number) => constraintId==idx && scnId == index? true : false;

    const handleClickOpen = (open: boolean, content: string, option: string) => () => {
        setOpen(open);
        setContent(content);
        setOption(option);
    };

    function setShow(idx:number, scnId:number){
        setConstraintId(idx)
        setScnId(scnId)
    }

    return (
        <div style={{ display: "block", padding: 80, width: '100%' }}>
            <TableContainer component={Paper}>
                <Table style={{width: '100%'}} size="small">
                    <TableHead>
                        <Constant.StyledTableRow>
                            <Constant.StyledTableCell width="25%">Constraint Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="40%">Number of Conforming Scn.</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="10%">State Coverage</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="10%">Transition Coverage</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="10%">Test Coverage</Constant.StyledTableCell>
                        </Constant.StyledTableRow>
                    </TableHead>
                    <TableBody>
                    {
                        props.conformanceResults.map((config, idx) => (
                            <Constant.StyledTableRow key={idx} sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                <Constant.StyledTableCell align="left"><div>{config.constraintName}
                                {config.base64Dot ? (<div><button onClick={handleClickOpen(true, config.base64Dot, 'graph')}>SVG</button></div>) : ''}
                                </div></Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{config.numberOfConformingSCN}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{decimalValue(config.stateCoverage)}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{decimalValue(config.transitionCoverage)}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{decimalValue(config.testCoverage)}</Constant.StyledTableCell>
                            </Constant.StyledTableRow>
                        ))
                    }
                    </TableBody>
                </Table>
                </TableContainer>
                <br/>
                <TableContainer component={Paper}>
                <Table style={{width: '100%'}} size="small">
                    <TableHead>
                        <Constant.StyledTableRow>
                            <Constant.StyledTableCell>Index</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="15%">Constraint Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="25%">Scenario Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="35%">Description</Constant.StyledTableCell>
                            <Constant.StyledTableCell>FilePath</Constant.StyledTableCell>
                        </Constant.StyledTableRow>
                    </TableHead>
                    <TableBody>
                    {
                        props.conformanceResults.map((res:ConformanceResult, idx) => (
                            (res.conformingScenarios.map((scn:ConformingScenario, index) => (
                            <Constant.StyledTableRow key={index} sx={{ '&:last-child td, &:last-child th': { border: 0 } }} style={{verticalAlign: 'top'}}>
                                <Constant.StyledTableCell align="left">{index}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'300px', maxWidth:'300px'}}><div onMouseOver={()=>setShow(idx, index)} onMouseLeave={()=>setShow(-1, -1)}>{res.constraintName}
                                {res.base64Dot ? (<div><button onClick={handleClickOpen(true, res.base64Dot, 'graph')}>SVG</button></div>) : ''}
                                {isShown(idx, index) && (
                                    <div key={index}>{res.constraintText.map((item:string, idx) => (<li key={idx} style={{ listStyleType: "none" }}>{item}</li>))}</div>
                                )}</div></Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'260px', maxWidth:'260px'}}>{scn.scnID}
                                {scn.configurations.length > 0 && <div><b>is associated with</b> {scn.configurations.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</div>}
                                </Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{scn.scenarios?.map((item:string, idx) => (<li key={idx} style={{ listStyleType: "none" }}>{highlighted(scn, item)}</li>))}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'200px', maxWidth:'200px'}}>{scn.filePath}<button onClick={handleClickOpen(true, scn.base64Content, 'feature')}>...</button></Constant.StyledTableCell>
                            </Constant.StyledTableRow>
                        )))))
                    }
                    </TableBody>
                </Table>
                </TableContainer>
                <FullDialog
                    open={isOpen}
                    content={content}
                    option={option}
                    handleClickOpen={handleClickOpen}
                />
        </div>
    );
}

export default Overview;