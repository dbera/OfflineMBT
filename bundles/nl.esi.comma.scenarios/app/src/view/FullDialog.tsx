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
import { createStyles, makeStyles, Theme } from '@material-ui/core/styles';
import Dialog from '@material-ui/core/Dialog';
import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import IconButton from '@material-ui/core/IconButton';
import Typography from '@material-ui/core/Typography';
import CloseIcon from '@material-ui/icons/Close';
import Slide from '@material-ui/core/Slide';
import { TransitionProps } from '@material-ui/core/transitions';
import Box from '@material-ui/core/Box';
interface IFullDialogProps {
    open : boolean;
    content : string;
    handleClickOpen(isOpen: boolean, content: string): React.MouseEventHandler<HTMLButtonElement>;
}
const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    appBar: {
      position: 'relative',
    },
    title: {
      marginLeft: theme.spacing(2),
      flex: 1,
    },
  }),
);

const Transition = React.forwardRef(function Transition(
    props: TransitionProps & { children?: React.ReactElement },
    ref: React.Ref<unknown>,
  ) {
    return <Slide direction="up" ref={ref} {...props} />;
});

const FullDialog: React.FC<IFullDialogProps> = ({open, content, handleClickOpen}) => {
    
    const classes = useStyles();

    return (
        <div>
            <Dialog fullScreen open={open} TransitionComponent={Transition}>
                <AppBar className={classes.appBar}>
                  <Toolbar>
                    <IconButton edge="start" color="inherit" onClick={handleClickOpen(false, "")} aria-label="close">
                      <CloseIcon />
                    </IconButton>
                    <Typography variant="h6" className={classes.title}>
                      Feature File
                    </Typography>
                  </Toolbar>
                </AppBar>
                <Box justifyContent="center" m={2} boxShadow={2} p={2} >
                    <Typography style={{ whiteSpace: 'pre-wrap' }}>{atob(content)}</Typography>
                </Box>
              </Dialog>
            </div>
    );
}

export default FullDialog;