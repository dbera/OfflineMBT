import React from 'react';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import CloseIcon from '@mui/icons-material/Close';
import CloudDownloadIcon from '@mui/icons-material/CloudDownload';
import Slide from '@mui/material/Slide';
import { TransitionProps } from '@mui/material/transitions';
import { DataGrid, GridRowId } from '@mui/x-data-grid';
import { downloadFile } from '../utils';
import * as types from '../types';

const Transition = React.forwardRef(function Transition(
    props: TransitionProps & {children: React.ReactElement;},
    ref: React.Ref<unknown>
) {
    return <Slide direction="up" ref={ref} {...props} />;
});

const columns = [
    {field: 'name', headerName: 'Name', flex: 1},
    {field: 'productSet', headerName: 'Product set', flex: 1},
];

interface Props {
    graph: types.Graph;
    testSet: string[] | null;
    clearTestSet: () => void;
}

interface State {
    selected: GridRowId[];
}

class Header extends React.Component<Props, State> {
    constructor(props: Props) {
        super(props);
        this.state = {selected: []}
    }

    onDownloadClick() {
        const obj = this.state.selected.map((idx) => {
            const feature = this.props.graph.meta.features[this.props.testSet![idx as number]];
            return {name: feature.name, productSet: feature.productSet, path: feature.path};
        })
        downloadFile("features.json", JSON.stringify(obj, null, 2));
    }

    onClose() {
        this.setState({selected: []});
        this.props.clearTestSet();
    }

    render(): React.ReactNode {
        const rows = this.props.testSet?.map((t, id) => {
            const feature = this.props.graph.meta.features[t];
            return {id, name: feature?.name, productSet: feature?.productSet.join(', ')};
        })

        return (
            <Dialog
                fullScreen
                TransitionComponent={Transition}
                open={!!this.props.testSet}
                onClose={() => this.onClose()}
            >
                <AppBar sx={{ position: 'relative' }}>
                    <Toolbar>
                        <IconButton
                            edge="start"
                            color="inherit"
                            onClick={() => this.onClose()}
                        >
                            <CloseIcon />
                        </IconButton>
                        <Typography sx={{ ml: 2, flex: 1 }} variant="h6" component="div">
                            Select features
                        </Typography>
                        <Button autoFocus color="inherit" 
                            disabled={this.state.selected.length === 0}
                            onClick={() => this.onDownloadClick()}
                        >
                            <CloudDownloadIcon/>
                        </Button>
                    </Toolbar>
                </AppBar>
                {rows &&
                    <div style={{ height: '100%', width: '100%' }}>
                        <DataGrid
                            onSelectionModelChange={(selected) => this.setState({selected})}
                            rows={rows!}
                            columns={columns}
                            checkboxSelection
                        />
                    </div>
                }
            </Dialog>
        );
    }
}

export default Header;
