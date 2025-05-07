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
/* eslint-disable no-native-reassign */
/* eslint-disable no-restricted-globals */
const workercode = () => {
    const libBase = 'https://cdn.jsdelivr.net/npm/@hpcc-js/wasm@1.16.0/dist/';
    // @ts-expect-error
    importScripts(libBase + "index.min.js");
    // @ts-expect-error
    const hpccWasm = self["@hpcc-js/wasm"];
    let __nativeFetch = fetch;
    // @ts-expect-error
    fetch = function(input, init) {
        input = libBase + input;
        return __nativeFetch(input, init);
    }

    onmessage = function(e) {
        hpccWasm.graphviz.layout(e.data.dot, e.data.output, "dot").then((out: any) => {
            self.postMessage(out);
        });
    };
};

let code = workercode.toString();
code = code.substring(code.indexOf("{") + 1, code.lastIndexOf("}"));
const blob = new Blob([code], { type: "application/javascript" });
const worker_script = URL.createObjectURL(blob);

export default worker_script;  