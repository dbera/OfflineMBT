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
const fs = require('fs')
let index = fs.readFileSync('build/index.html', 'utf8');

index = index.replace(/<script defer=\"defer\" src=\"(.+)\"><\/script>/g, function(match, token) {
    return `<script>${fs.readFileSync(`build/${token}`)}</script>`;
});

index = index.replace(/<link.*href="(.+)" rel="stylesheet">/g, function(match, token) {
    return `<style>${fs.readFileSync(`build/${token}`)}</style>`;
});

const output = '../resource/constraints_dashboard.html';
fs.writeFileSync(output, index);
console.log(`Saved to ${output}`);
