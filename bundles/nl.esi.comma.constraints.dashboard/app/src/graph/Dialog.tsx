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
import { GridRowId } from '@mui/x-data-grid';
import * as types from '../types';

const Transition = React.forwardRef(function Transition(
    props: TransitionProps & {children: React.ReactElement;},
    ref: React.Ref<unknown>
) {
    return <Slide direction="up" ref={ref} {...props} />;
});

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

    onClose() {
        this.setState({selected: []});
        this.props.clearTestSet();
    }

    render(): React.ReactNode {

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
                        >
                            <CloudDownloadIcon/>
                        </Button>
                    </Toolbar>
                </AppBar>
            </Dialog>
        );
    }
}

export default Header;
