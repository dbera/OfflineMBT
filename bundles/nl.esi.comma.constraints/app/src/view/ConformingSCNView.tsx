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
import ConformanceResult from '../model/ConformanceResult';
import * as Constant from '../model/Constants';
import FullDialog from './FullDialog';
import ConformingScenario from '../model/ConformingScenario';
interface IConformingSCNProps {
    conformanceResults: ConformanceResult[];
}
type ConformingSCNState = {
    isOpen: boolean;
    content: string;
}
class ConformingSCNView extends React.Component<IConformingSCNProps, ConformingSCNState> {

    constructor(props:IConformingSCNProps){
        super(props);
        this.state = {
            isOpen: false,
            content: ''
        };
    }
    
    render(): React.ReactNode {
        const handleClickOpen = (open: boolean, content: string) => () => {
            this.setState({ ...this.state, ['isOpen']: open , ['content'] : content});
        };
        return (
            <div style={{ display: "block", padding: 80, width: '100%' }}>
                <TableContainer component={Paper}>
                <Table style={{width: '100%'}} size="small">
                    <TableHead>
                        <Constant.StyledTableRow>
                            <Constant.StyledTableCell>Index</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="20%">Constraint Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="30%">Scenario Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="30%">Description</Constant.StyledTableCell>
                            <Constant.StyledTableCell>FilePath</Constant.StyledTableCell>
                        </Constant.StyledTableRow>
                    </TableHead>
                    <TableBody>
                    {
                        this.props.conformanceResults.map((res:ConformanceResult) => (
                            (res.conformingScenarios.map((scn:ConformingScenario, index:number) => (
                            <Constant.StyledTableRow key={index} sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                <Constant.StyledTableCell align="left">{index}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{res.constraintName}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'260px', maxWidth:'200px'}}>{scn.scnID}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{scn.scenarios?.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'200px', maxWidth:'200px'}}>{scn.filePath}<button onClick={handleClickOpen(true, scn.base64Content)}>...</button></Constant.StyledTableCell>
                            </Constant.StyledTableRow>
                        )))))
                    }
                    </TableBody>
                </Table>
                </TableContainer>
                <FullDialog
                    open={this.state.isOpen}
                    content={this.state.content}
                    option={''}
                    handleClickOpen={handleClickOpen}
                />
            </div>
        )
    }
}
export default ConformingSCNView;