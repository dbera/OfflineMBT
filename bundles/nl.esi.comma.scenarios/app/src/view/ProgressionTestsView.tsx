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
import ProgressionTest from '../model/ProgressionTest';
import * as Constant from '../model/Constants';
import FullDialog from './FullDialog';
interface IProgressionTestProps {
    progressionTests: ProgressionTest[];
}
type ProgressionTestState = {
    isOpen: boolean;
    content: string;
}
class ProgressionTestsView extends React.Component<IProgressionTestProps, ProgressionTestState> {
    constructor(props:IProgressionTestProps){
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
                            <Constant.StyledTableCell width="35%">Scenario Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="15%">Configuration</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="30%">Reason</Constant.StyledTableCell>
                            <Constant.StyledTableCell>FilePath</Constant.StyledTableCell>
                        </Constant.StyledTableRow>
                    </TableHead>
                    <TableBody>
                    {
                        this.props.progressionTests.map((test, index) => (
                            <Constant.StyledTableRow key={index} sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                <Constant.StyledTableCell align="left">{index}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'260px', maxWidth:'260px'}}>{test.scnID}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{test.configs.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left">{test.reason.map((item:string) => (<li key={item} style={{ listStyleType: "none" }}>{item}</li>))}</Constant.StyledTableCell>
                                <Constant.StyledTableCell align="left" style={{minWidth:'200px', maxWidth:'200px'}}>{test.filePath}<button onClick={handleClickOpen(true, test.base64Content)}>...</button></Constant.StyledTableCell>
                            </Constant.StyledTableRow>
                        ))
                    }
                    </TableBody>
                </Table>
                </TableContainer>
                <FullDialog
                    open={this.state.isOpen}
                    content={this.state.content}
                    handleClickOpen={handleClickOpen}
                />
            </div>
        )
    }
}

export default ProgressionTestsView;