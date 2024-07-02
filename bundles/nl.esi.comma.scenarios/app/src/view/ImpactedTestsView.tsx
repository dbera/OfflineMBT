import React from 'react';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import Paper from '@mui/material/Paper';
import ImpactedTest from '../model/ImpactedTest';
import * as Constant from '../model/Constants';
import FullDialog from './FullDialog';
interface IImpactedTestProps {
    impactedTests: ImpactedTest[];
}
type ImpactedTestState = {
    isOpen: boolean;
    content: string;
}
class ImpactedTestsView extends React.Component<IImpactedTestProps, ImpactedTestState> {

    constructor(props:IImpactedTestProps){
        super(props);
        this.state = {
            isOpen: false,
            content: ''
        };
    }

    getBGColor(): string {
        return this.props.impactedTests.length == 0 ? "green" : "red";
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
                        this.props.impactedTests.map((test, index) => (
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



function TableWithSearchbar(props:IImpactedTestProps) {
    const [search, setSearch] = React.useState('');
    const handleSearch = (event: any) => {
        setSearch(event.target.value);
    };
    const data = {
        nodes: props.impactedTests.filter((item: ImpactedTest) =>
            item.scnID.includes(search)
        ),
    };
    return (
        <div>
        <label htmlFor="search">
            Search by Task:
            <input id="search" type="text" onChange={handleSearch} />
        </label>
            <TableContainer component={Paper}>
                <Table style={{width: '100%'}} size="small">
                    <TableHead>
                        <Constant.StyledTableRow>
                            <Constant.StyledTableCell>Index</Constant.StyledTableCell>
                            <Constant.StyledTableCell width="30%">Scenario Name</Constant.StyledTableCell>
                            <Constant.StyledTableCell>Configuration</Constant.StyledTableCell>
                            <Constant.StyledTableCell>FilePath</Constant.StyledTableCell>
                            <Constant.StyledTableCell>Reason</Constant.StyledTableCell>
                        </Constant.StyledTableRow>
                    </TableHead>
                    <TableBody>
                    {
                    //    data.nodes.map((test, index) => (
                    //             <Constant.StyledTableRow key={index} sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                    //                 <Constant.StyledTableCell align="left">{index}</Constant.StyledTableCell>
                    //                 <Constant.StyledTableCell align="left">{test.scnID}</Constant.StyledTableCell>
                    //                 <Constant.StyledTableCell align="left">{Constant.confList(test.configs)}</Constant.StyledTableCell>
                    //                 <Constant.StyledTableCell align="left">{test.filePath}</Constant.StyledTableCell>
                    //                 <Constant.StyledTableCell align="left">{test.reason}</Constant.StyledTableCell>
                    //             </Constant.StyledTableRow>
                    //         ))
                    }
                    </TableBody>
                </Table>
            </TableContainer>
        </div>
    );
}
export default ImpactedTestsView;