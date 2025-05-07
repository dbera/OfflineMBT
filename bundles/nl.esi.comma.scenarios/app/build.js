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
/**
 * This script inlines the bundle.js in index.html and saves it as the dashboard.html.
 */

const fs = require('fs')
const index = fs.readFileSync('public/index.html', 'utf8');
const bundle = fs.readFileSync('public/bundle.js', 'utf8');

let content = index.split("<script src=\"bundle.js\"></script>");
content = content[0] + `<script>${bundle}</script>` + content[1]
fs.writeFileSync('../resource/impactAnalysis.html', content);
console.log('Saved to ../resource/impactAnalysis.html');
