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
import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';

interface Props {
    view: 'graph' | 'footprint';
    setView: (view: 'graph' | 'footprint') => void;
}

class Header extends React.Component<Props> {
    render(): React.ReactNode {
        return (
            <div style={{zIndex: 9}}>
                <Box sx={{ flexGrow: 1 }}>
                    <AppBar position="static">
                        <Toolbar>
                            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                                Causal diff
                            </Typography>
                            <Button 
                                color="inherit" 
                                onClick={() => this.props.setView(this.props.view === 'graph' ? 'footprint' : 'graph')}
                            >
                                {this.props.view === 'graph' ? 'Show causal footprint' : 'Show causal graph'}
                            </Button>
                        </Toolbar>
                    </AppBar>
                </Box>
            </div>
        );
    }
}

export default Header;
