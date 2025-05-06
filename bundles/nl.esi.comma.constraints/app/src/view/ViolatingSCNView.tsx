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
import React, {useState} from 'react';
import ConformanceResult from '../model/ConformanceResult';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import Paper from '@mui/material/Paper';
import * as Constant from '../model/Constants';
import FullDialog from './FullDialog';
import ViolatingScenario from '../model/ViolatingScenario';
interface IViolatingSCNProps {
    conformanceResults: ConformanceResult[];
}

function ViolatingSCNView(props: IViolatingSCNProps): JSX.Element{
    const [isOpen, setOpen] = useState(false);
    const [content, setContent] = useState('');
    const [option, setOption] = useState('');
    const [constraintId, setConstraintId] = useState<number>();
    const [scnId, setScnId] = useState<number>();

    function highlighted(scn: ViolatingScenario, item: string): React.ReactNode{
        if (scn.highlighted.includes(item)){
            return <b>{item}</b>;
        } else {
            return item;
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
                            <Constant.StyledTableCell>Index</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="20%">Constraint Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="30%">Scenario Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="30%">Violating Action</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="30%">Description</Constant.StyledTableCell>
                            <Constant.StyledTableCell>FilePath</Constant.StyledTableCell>
                        </Constant.StyledTableRow>
                    </TableHead>
                    <TableBody>
                    {
                        props.conformanceResults.map((res:ConformanceResult, idx) => (
                            res.violatingScenarios.map((scn:ViolatingScenario, index:number) => (
                            <Constant.StyledTableRow key={index} sx={{ '&:last-child td, &:last-child th': { border: 0 } }} style={{verticalAlign: 'top'}}>
                                <Constant.StyledTableCell align="left">{index}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'300px', maxWidth:'300px'}}><div onMouseOver={()=>setShow(idx, index)} onMouseLeave={()=>setShow(-1, -1)}>{res.constraintName}
                                {res.base64Dot ? (<div><button onClick={handleClickOpen(true, res.base64Dot, 'graph')}>SVG</button></div>) : ''}
                                {isShown(idx, index) && (
                                    <div>{res.constraintText.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</div>
                                )}</div></Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'230px', maxWidth:'230px'}}>{scn.scnID}
                                {scn.configurations.length > 0 && <div><b>is associated with</b> {scn.configurations.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</div>}
                                </Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'250px', maxWidth:'250px'}}>{scn.violatingAction?.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{scn.scenarios?.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{highlighted(scn, item)}</li>))}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'200px', maxWidth:'200px'}}>{scn.filePath}<button onClick={handleClickOpen(true, scn.base64Content, 'feature')}>...</button></Constant.StyledTableCell>
                            </Constant.StyledTableRow>
                        ))))
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

export default ViolatingSCNView;