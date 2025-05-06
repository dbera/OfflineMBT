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
const path = require('path');
const fs = require('fs');

const root = path.join(__dirname, '..')
const source = path.join(root, 'node_modules', '@hpcc-js', 'wasm', 'dist', 'graphvizlib.wasm');
const target = path.join(root, 'public', 'static', 'js', 'graphvizlib.wasm');

fs.mkdirSync(path.dirname(target), {recursive: true});
fs.copyFileSync(source, target);
console.log(`Copied '${source}' to '${target}'`)