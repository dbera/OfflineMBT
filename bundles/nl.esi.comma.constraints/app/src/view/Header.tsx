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
import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import IconButton from '@material-ui/core/IconButton';
import Typography from '@material-ui/core/Typography';
import MenuIcon from '@material-ui/icons/Menu';
import { makeStyles } from "@material-ui/core/styles";
import Drawer from '@material-ui/core/Drawer';
import MenuList from './MenuList';
import ImpactAnalysisReport from '../model/ConformanceCheckingReport';

const useStyles = makeStyles((theme) => ({
  root: {
    flexGrow: 1,
  },
  menuButton: {
    marginRight: theme.spacing(2),
  },
  title: {
    flexGrow: 1,
    textAlign: 'center'
  },
}));
interface IHeaderProps {
  toggleView(viewId: string): void;
  report: ImpactAnalysisReport;
}

const Header: React.FC<IHeaderProps> = ({ toggleView, report }) => {
  const classes = useStyles();
  const [state, setState] = React.useState({
    isOpen: false
  });
  
  const toggleDrawer = (open: boolean) => (
    event: React.KeyboardEvent | React.MouseEvent,
  ) => {
    if (
      event.type === 'keydown' &&
      ((event as React.KeyboardEvent).key === 'Tab' ||
        (event as React.KeyboardEvent).key === 'Shift')
    ) {
      return;
    }

    setState({ ...state, ['isOpen']: open });
  };

  const doToggleView = (viewId: string) => {
    toggleView(viewId);
  };

  return (
    <div>
      <AppBar position="relative">
        <Toolbar>
          <IconButton edge="start" className={classes.menuButton} color="inherit" aria-label="menu" onClick={toggleDrawer(true)}>
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" className={classes.title}>
            Conformance Checking Report
          </Typography>
          <Typography color="inherit">
            {
              report.meta.createdAt.toLocaleDateString(window.navigator.language, {
                weekday: 'short', year: 'numeric', month: 'short', day: 'numeric'
              })
            }
          </Typography>
        </Toolbar>
      </AppBar>

      <Drawer anchor='left' open={state.isOpen} onClose={toggleDrawer(false)}>
        <MenuList
          toggleDrawer={toggleDrawer}
          toggleView={doToggleView}
          report={report} />
      </Drawer>
    </div>
  );
}

export default Header;
