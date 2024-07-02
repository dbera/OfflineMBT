/**
 * Copyright (c) 2021 Contributors to the Eclipse Foundation
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';
// Polyfills for ie 11
import 'core-js';

ReactDOM.render(
    <App/>,
    document.getElementById('root')
);