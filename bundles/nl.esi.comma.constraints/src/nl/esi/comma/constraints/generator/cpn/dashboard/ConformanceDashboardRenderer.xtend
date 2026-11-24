/**
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
package nl.esi.comma.constraints.generator.cpn.dashboard

class ConformanceDashboardRenderer {
    def String render(String summaryJson, String concreteTspecText) {
        render(summaryJson, concreteTspecText, "")
    }

    def String render(String summaryJson, String concreteTspecText, String constraintSourceText) {
        // Embed source as text, not markup, while keeping the summary valid JSON in the page.
        val safeSummary = summaryJson.replace("<", "\\u003c")
        val safeConstraintText = constraintSourceText
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
        val safeTestCaseText = concreteTspecText
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")

        '''
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Conformance Checking with Constraints</title>
            <style>
                :root {
                    font-family: "Segoe UI", sans-serif;
                    color: #202a31;
                    background: #f3f6f4;
                    --activation-color: #286c91;
                    --activation-bg: #e7f2f8;
                    --target-color: #35784a;
                    --target-bg: #e9f4eb;
                    --blocker-color: #ad4141;
                    --blocker-bg: #faeaea;
                }
                body {
                    display: grid;
                    grid-template-rows: auto minmax(0, 1fr);
                    width: 100%;
                    height: 100vh;
                    margin: 0;
                    overflow: hidden;
                }
                header {
                    padding: 16px 24px;
                    color: white;
                    background: #183b3a;
                }
                h1 { margin: 0; font-size: 22px; }
                .file-meta {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 4px 20px;
                    margin-top: 8px;
                }
                .file-meta p { margin: 0; color: #d7e5e1; font-size: 13px; }
                .file-meta strong { color: white; font-weight: 600; }
                main {
                    display: grid;
                    grid-template-columns: minmax(340px, 0.85fr) minmax(420px, 1.4fr);
                    gap: 24px;
                    padding: 24px;
                    box-sizing: border-box;
                    min-height: 0;
                    align-items: stretch;
                }
                h2 { font-size: 14px; }
                button {
                    display: block;
                    width: 100%;
                    margin: 5px 0;
                    padding: 10px;
                    text-align: left;
                    color: inherit;
                    background: white;
                    border: 1px solid #d5ddda;
                    border-left: 4px solid #27806a;
                    cursor: pointer;
                }
                button.failed { border-left-color: #bd3e3e; }
                button[aria-current="true"] { outline: 2px solid #24766b; }
                button:disabled {
                    color: #7b8585;
                    cursor: default;
                    opacity: 0.65;
                }
                button strong, button span { display: block; }
                button span, .muted { color: #5c696d; font-size: 13px; }
                #constraints-panel {
                    display: flex;
                    min-width: 0;
                    min-height: 0;
                    flex-direction: column;
                    overflow: hidden;
                }
                #constraints-panel nav {
                    flex: 1;
                    min-height: 0;
                    overflow: auto;
                }
                #constraints-panel nav h2 {
                    position: sticky;
                    top: 0;
                    z-index: 2;
                    margin: 0;
                    padding: 9px 0;
                    background: #f3f6f4;
                }
                #detail {
                    flex: 0 1 34%;
                    min-height: 120px;
                    max-height: 40%;
                    margin-top: 18px;
                    padding: 20px;
                    overflow: auto;
                    background: white;
                    border: 1px solid #d5ddda;
                }
                #testcase-panel {
                    display: flex;
                    min-width: 0;
                    min-height: 0;
                    flex-direction: column;
                    padding: 20px;
                    overflow: hidden;
                    background: white;
                    border: 1px solid #d5ddda;
                }
                .trace-toolbar {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    margin-bottom: 10px;
                }
                .trace-toolbar button {
                    width: auto;
                    margin: 0;
                }
                #trace-view {
                    flex: 1;
                    min-height: 0;
                    overflow: auto;
                }
                .trace-preamble, .trace-step {
                    margin: 4px 0;
                    padding: 8px 10px;
                    background: #f7f9f8;
                    border: 1px solid #d5ddda;
                }
                .trace-step summary {
                    cursor: pointer;
                    overflow-wrap: anywhere;
                }
                .trace-step[open] summary {
                    font: 13px/1.5 Consolas, monospace;
                }
                .trace-step .step-id,
                .trace-step .step-type {
                    display: block;
                    overflow-wrap: anywhere;
                }
                .trace-step .step-id { font-weight: 600; }
                .trace-step .step-type { color: #5c696d; font-size: 12px; }
                .trace-step[open] .step-id,
                .trace-step[open] .step-type {
                    color: inherit;
                    font-size: inherit;
                    font-weight: 700;
                }
                .trace-step.highlighted {
                    background: #fff1cf;
                    border-color: #c78b25;
                }
                .trace-step.role-activation {
                    background: var(--activation-bg);
                    border-left: 4px solid var(--activation-color);
                }
                .trace-step.role-target {
                    background: var(--target-bg);
                    border-left: 4px solid var(--target-color);
                }
                .trace-step pre .code-line { display: block; min-height: 1em; }
                .code-line.line-relevant {
                    background: var(--activation-bg);
                    box-shadow: inset 3px 0 0 var(--activation-color);
                }
                .code-line.line-ref {
                    background: var(--target-bg);
                    box-shadow: inset 3px 0 0 var(--target-color);
                }
                .code-line.line-condition {
                    background: #fff6d6;
                    box-shadow: inset 3px 0 0 #c9a227;
                }
                .code-line.line-violation {
                    background: var(--blocker-bg);
                    box-shadow: inset 3px 0 0 var(--blocker-color);
                }
                .line-note {
                    margin-left: 12px;
                    color: var(--blocker-color);
                    font-weight: 700;
                    font-family: "Segoe UI", sans-serif;
                }
                .trace-step.role-blocker {
                    background: var(--blocker-bg);
                    border-left: 4px solid var(--blocker-color);
                }
                .trace-step.role-event {
                    background: #fff1cf;
                    border-left: 4px solid #c78b25;
                }
                .trace-step.context-focus {
                    outline: 2px solid #24766b;
                }
                .trace-step pre {
                    max-height: min(58vh, 720px);
                    margin: 8px 0 0;
                    overflow: auto;
                    white-space: pre-wrap;
                    overflow-wrap: anywhere;
                    font: 13px/1.5 Consolas, monospace;
                }
                .source-block {
                    margin-top: 12px;
                    border: 1px solid #d5ddda;
                    background: #f7f9f8;
                }
                .source-block summary {
                    padding: 9px 10px;
                    cursor: pointer;
                    overflow-wrap: anywhere;
                }
                .source-block pre {
                    max-height: 320px;
                    margin: 0;
                    padding: 10px;
                    overflow: auto;
                    white-space: pre-wrap;
                    overflow-wrap: anywhere;
                    border-top: 1px solid #d5ddda;
                    font: 12px/1.5 Consolas, monospace;
                }
                .constraint-entry { margin: 5px 0; }
                .constraint-entry-header { display: flex; align-items: stretch; }
                .constraint-entry-header > button { margin: 0; }
                .constraint-entry-header > .constraint-select { flex: 1; }
                .constraint-entry-header > .focus-toggle {
                    width: auto;
                    padding: 0 14px;
                    color: #24766b;
                    border-left: 1px solid #d5ddda;
                    font-weight: 600;
                    text-align: center;
                }
                #constraints-panel.focus-mode .constraint-entry:not(.focused),
                #constraints-panel.focus-mode #accepted-section,
                #constraints-panel:not(.focus-mode) #detail {
                    display: none;
                }
                .focus-diagnostics {
                    background: white;
                    border: 1px solid #d5ddda;
                    border-top: 0;
                }
                .focus-diagnostics > summary {
                    padding: 8px 10px;
                    color: #5c696d;
                    cursor: pointer;
                    font-size: 13px;
                }
                .focus-diagnostics #detail {
                    max-height: none;
                    margin: 0;
                    border: 0;
                    border-top: 1px solid #d5ddda;
                }
                .constraint-source {
                    background: white;
                    border: 1px solid #d5ddda;
                    border-top: 0;
                }
                .constraint-source summary {
                    padding: 8px 10px;
                    color: #5c696d;
                    cursor: pointer;
                    font-size: 13px;
                }
                .constraint-source pre {
                    max-height: 360px;
                    margin: 0;
                    padding: 12px;
                    overflow: auto;
                    white-space: pre-wrap;
                    overflow-wrap: anywhere;
                    border-top: 1px solid #d5ddda;
                    font: 12px/1.5 Consolas, monospace;
                }
                .message {
                    margin-top: 14px;
                    padding: 10px;
                    background: #f7f9f8;
                    border-left: 3px solid #879498;
                }
                .message.role-event {
                    color: #765816;
                    background: #fff1cf;
                    border-left-color: #c78b25;
                }
                .diagnostic-message { margin: 0 0 8px; }
                .diagnostic-message .role-activation { color: var(--activation-color); font-weight: 700; }
                .diagnostic-message .role-target { color: var(--target-color); font-weight: 700; }
                .diagnostic-message .role-blocker { color: var(--blocker-color); font-weight: 700; }
                .diagnostic-event {
                    display: block;
                    margin-top: 6px;
                    padding: 7px 9px;
                    overflow-wrap: anywhere;
                    border-left: 4px solid;
                    font: 12px/1.5 Consolas, monospace;
                }
                .diagnostic-event-heading {
                    display: grid;
                    grid-template-columns: minmax(112px, 145px) minmax(0, 1fr);
                    gap: 8px;
                    margin-bottom: 4px;
                    font-weight: 700;
                }
                .diagnostic-event-fields {
                    display: grid;
                    gap: 4px;
                }
                .diagnostic-field {
                    display: grid;
                    grid-template-columns: minmax(112px, 145px) minmax(0, 1fr);
                    gap: 8px;
                    align-items: start;
                }
                .diagnostic-field-label {
                    color: #526166;
                    font: 11px/1.6 "Segoe UI", sans-serif;
                }
                .diagnostic-field-value {
                    min-width: 0;
                    white-space: pre-wrap;
                    overflow-wrap: anywhere;
                }
                .diagnostic-event.role-activation {
                    color: #204e69;
                    background: var(--activation-bg);
                    border-color: var(--activation-color);
                }
                .diagnostic-event.role-target {
                    color: #285d38;
                    background: var(--target-bg);
                    border-color: var(--target-color);
                }
                .diagnostic-event.role-blocker {
                    color: #7f3030;
                    background: var(--blocker-bg);
                    border-color: var(--blocker-color);
                }
                .diagnostic-event.role-event {
                    color: #765816;
                    background: #fff1cf;
                    border-color: #c78b25;
                }
                .constraint-definition {
                    padding: 12px;
                    overflow: auto;
                    background: #fbfcfb;
                    border-top: 1px solid #d5ddda;
                    font: 12px/1.55 Consolas, monospace;
                }
                .constraint-declaration {
                    margin-bottom: 8px;
                    color: #183b3a;
                    font-weight: 700;
                }
                .constraint-indicator {
                    display: inline-block;
                    margin-bottom: 8px;
                    padding: 2px 7px;
                    color: #183b3a;
                    background: #e5efeb;
                    border: 1px solid #b8cec5;
                    font-weight: 700;
                }
                .constraint-line {
                    display: grid;
                    grid-template-columns: minmax(96px, 130px) minmax(0, 1fr);
                    gap: 8px;
                    padding: 2px 0;
                    white-space: pre-wrap;
                    overflow-wrap: anywhere;
                }
                .constraint-line-label {
                    color: #5c696d;
                    font: 11px/1.6 "Segoe UI", sans-serif;
                }
                .constraint-line.role-activation { color: var(--activation-color); }
                .constraint-line.role-target { color: var(--target-color); }
                .constraint-line.role-blocker { color: var(--blocker-color); }
                @media (max-width: 800px) {
                    body {
                        display: block;
                        height: auto;
                        min-height: 100vh;
                        overflow: auto;
                    }
                    main { grid-template-columns: 1fr; padding: 14px; }
                    #constraints-panel, #testcase-panel { overflow: visible; }
                    #constraints-panel nav { flex: none; overflow: visible; }
                    #detail { flex: none; max-height: none; }
                    #trace-view { flex: none; max-height: 60vh; }
                    .trace-toolbar { flex-wrap: wrap; }
                }
            </style>
            «inspectionStyles»
        </head>
        <body>
            <header>
                <h1>Conformance</h1>
                <div class="file-meta">
                    <p><strong>Test case:</strong> <span id="testcase"></span></p>
                    <p><strong>Constraint file:</strong> <span id="constraint-file"></span></p>
                </div>
            </header>
            <main>
                <aside id="constraints-panel">
                    <nav aria-label="Constraints">
                        <section>
                            <h2>Violated Constraints</h2>
                            <div id="failed"></div>
                        </section>
                        <section id="accepted-section">
                            <h2>Accepted Constraints</h2>
                            <div id="accepted"></div>
                        </section>
                    </nav>
                    <section id="detail" aria-live="polite">
                        <p class="muted">Select a constraint.</p>
                    </section>
                </aside>
                <div id="sidebar-divider" class="pane-divider" role="separator" aria-label="Constraint list width" aria-orientation="vertical" tabindex="0"></div>
                <div id="inspection-divider" class="pane-divider horizontal" role="separator" aria-label="Constraint inspection height" aria-orientation="horizontal" tabindex="0"></div>
                <section id="inspection-panel" aria-label="Selected constraint">
                    <div class="inspection-toolbar">
                        <label><input id="full-constraint" type="checkbox" checked> Full definition</label>
                        <label><input id="all-diagnostics" type="checkbox"> All diagnostics</label>
                        <button id="reset-layout" type="button">Reset layout</button>
                    </div>
                    <div id="selected-definition" role="region" aria-label="Constraint definition"></div>
                    <div id="definition-divider" class="pane-divider" role="separator" aria-label="Definition and diagnostics widths" aria-orientation="vertical" tabindex="0"></div>
                    <div id="diagnostics-host"></div>
                </section>
                <section id="testcase-panel">
                    <h2>Concrete Test Case</h2>
                    <div class="trace-toolbar">
                        <button id="previous-context" type="button" disabled>
                            Previous context
                        </button>
                        <span id="context-position" class="muted" aria-live="polite"></span>
                        <button id="next-context" type="button" disabled>
                            Next context
                        </button>
                    </div>
                    <div class="inspection-toolbar">
                        <label><input id="intermediate-steps" type="checkbox"> Intermediate steps</label>
                        <label><input id="all-steps" type="checkbox" checked> Entire trace</label>
                        <label><input id="all-lines" type="checkbox"> Unhighlighted lines</label>
                        <label class="step-split-control">Step split <input id="step-split" type="range" min="25" max="75" value="50" aria-label="Step comparison widths"></label>
                    </div>
                    <div class="highlight-legend" aria-label="Line highlighting">
                        <span class="legend-condition">Condition field</span>
                        <span class="legend-reference">Reference field</span>
                        <span class="legend-violation">Reference mismatch</span>
                    </div>
                    <pre id="testcase-source" hidden>«safeTestCaseText»</pre>
                    <pre id="constraint-source" hidden>«safeConstraintText»</pre>
                    <div id="trace-view"></div>
                </section>
            </main>
            <script id="summary-data" type="application/json">«safeSummary»</script>
            <script>
                const summary = JSON.parse(
                    document.querySelector("#summary-data").textContent
                );
                document.querySelector("#testcase").textContent =
                    summary.testCasePath || "";
                document.querySelector("#constraint-file").textContent =
                    summary.constraintFilePath || "";
                const detail = document.querySelector("#detail");
                const traceText =
                    document.querySelector("#testcase-source").textContent;
                const constraintSourceText =
                    document.querySelector("#constraint-source").textContent;
                const traceView = document.querySelector("#trace-view");
                let selectedTraceIds = new Set();
                let selectedTraceRoles = new Map();
                const expandedSteps = new Set();
                const collapsedSteps = new Set();
                const revealedGaps = new Set();
                const diagnosticElements = [];

                function updateInspection() {
                    const context = contexts[contextIndex];
                    const allDiagnostics = document.querySelector("#all-diagnostics").checked;
                    detail.classList.toggle("expanded-diagnostics", allDiagnostics);
                    for (const { element, diagnostic } of diagnosticElements) {
                        element.hidden = Boolean(!allDiagnostics && context &&
                            !context.diagnostics.has(diagnostic));
                    }
                    const host = document.querySelector("#selected-definition");
                    const sourceScroll = host.scrollTop;
                    host.replaceChildren();
                    if (selectedResult) {
                        const heading = document.createElement("h2");
                        heading.textContent = "Constraint definition";
                        host.append(heading);
                        const source = extractConstraintDefinition(
                            selectedResult.constraintName || selectedResult.constraint
                        );
                        if (!source) {
                            const empty = document.createElement("p");
                            empty.className = "muted";
                            empty.textContent = "Constraint definition not found in source.";
                            host.append(empty);
                            return;
                        }
                        const definition = renderConstraintDefinition(source);
                        definition.classList.toggle("compact-definition", !document.querySelector("#full-constraint").checked);
                        host.append(definition);
                        host.scrollTop = sourceScroll;
                    }
                }
                let contexts = [];
                let contextIndex = -1;
                let selectedResult = null;

                const layoutDefaults = { sidebar: 260, inspection: 38, definition: 50, steps: 50 };
                let layout = { ...layoutDefaults };
                const layoutKey = "conformance-layout:" + location.pathname;
                try {
                    const saved = JSON.parse(sessionStorage.getItem(layoutKey) || "null");
                    for (const key of Object.keys(layoutDefaults)) {
                        if (Number.isFinite(saved?.[key])) layout[key] = saved[key];
                    }
                } catch (error) {}

                function applyLayout() {
                    const main = document.querySelector("main");
                    layout.sidebar = Math.max(180, Math.min(layout.sidebar, Math.max(180, main.clientWidth - 540)));
                    layout.inspection = Math.max(25, Math.min(65, layout.inspection));
                    layout.definition = Math.max(25, Math.min(75, layout.definition));
                    layout.steps = Math.max(25, Math.min(75, layout.steps));
                    main.style.setProperty("--sidebar-width", layout.sidebar + "px");
                    main.style.setProperty("--inspection-height", layout.inspection + "%");
                    document.querySelector("#inspection-panel").style.setProperty("--definition-width", layout.definition + "fr");
                    document.querySelector("#inspection-panel").style.setProperty("--diagnostics-width", (100 - layout.definition) + "fr");
                    traceView.style.setProperty("--step-left-width", layout.steps + "%");
                    traceView.style.setProperty("--step-right-width", (100 - layout.steps) + "%");
                    document.getElementById("step-split").value = layout.steps;
                    for (const [id, key, min, max] of [
                        ["sidebar-divider", "sidebar", 180, Math.max(180, main.clientWidth - 540)],
                        ["inspection-divider", "inspection", 25, 65],
                        ["definition-divider", "definition", 25, 75]
                    ]) {
                        const divider = document.getElementById(id);
                        divider.setAttribute("aria-valuemin", min);
                        divider.setAttribute("aria-valuemax", max);
                        divider.setAttribute("aria-valuenow", Math.round(layout[key]));
                        divider.setAttribute("aria-valuetext", Math.round(layout[key]) + (key === "sidebar" ? " pixels" : " percent"));
                    }
                    try { sessionStorage.setItem(layoutKey, JSON.stringify(layout)); } catch (error) {}
                }

                for (const [id, key, horizontal] of [
                    ["sidebar-divider", "sidebar", false],
                    ["inspection-divider", "inspection", true],
                    ["definition-divider", "definition", false]
                ]) {
                    const divider = document.getElementById(id);
                    let dragging = false;
                    divider.addEventListener("pointerdown", event => {
                        if (event.button !== 0 || matchMedia("(max-width: 850px)").matches) return;
                        event.preventDefault();
                        dragging = true;
                        divider.setPointerCapture(event.pointerId);
                        document.body.classList.add("resizing");
                    });
                    divider.addEventListener("pointermove", event => {
                        if (!dragging) return;
                        const bounds = (key === "definition"
                            ? document.getElementById("inspection-panel") : document.querySelector("main")).getBoundingClientRect();
                        layout[key] = key === "sidebar" ? event.clientX - bounds.left
                            : horizontal ? 100 * (event.clientY - bounds.top) / bounds.height
                            : 100 * (event.clientX - bounds.left) / bounds.width;
                        applyLayout();
                    });
                    const stopDragging = () => {
                        dragging = false;
                        document.body.classList.remove("resizing");
                    };
                    divider.addEventListener("pointerup", stopDragging);
                    divider.addEventListener("pointercancel", stopDragging);
                    divider.addEventListener("lostpointercapture", stopDragging);
                    divider.addEventListener("keydown", event => {
                        const decrement = horizontal ? "ArrowUp" : "ArrowLeft";
                        const increment = horizontal ? "ArrowDown" : "ArrowRight";
                        if (![decrement, increment, "Home", "End"].includes(event.key)) return;
                        event.preventDefault();
                        layout[key] = event.key === "Home" ? Number(divider.getAttribute("aria-valuemin"))
                            : event.key === "End" ? Number(divider.getAttribute("aria-valuemax"))
                            : layout[key] + (event.key === increment ? 1 : -1) * (key === "sidebar" ? 16 : 2);
                        applyLayout();
                    });
                    divider.addEventListener("dblclick", () => {
                        layout[key] = layoutDefaults[key];
                        applyLayout();
                    });
                }
                document.getElementById("step-split").addEventListener("input", event => {
                    layout.steps = Number(event.target.value);
                    applyLayout();
                });
                document.getElementById("reset-layout").addEventListener("click", () => {
                    layout = { ...layoutDefaults };
                    applyLayout();
                });
                window.addEventListener("resize", applyLayout);
                applyLayout();

                // TSpec has no JSON structure here; step marker lines delimit each block.
                function parseTrace(text) {
                    const lines = text.split("\n");
                    const preamble = [];
                    const steps = [];
                    const trailer = [];
                    let current = null;
                    let pastSteps = false;

                    function finishCurrentStep() {
                        if (!current) return;
                        const bodyLines = current.lines.slice(2);
                        let commonIndent = null;
                        for (const line of bodyLines) {
                            if (!line.trim()) continue;
                            const indentation = line.match(/^[ \t]*/)[0].length;
                            commonIndent = commonIndent === null
                                ? indentation
                                : Math.min(commonIndent, indentation);
                        }
                        if (commonIndent === null) commonIndent = 0;

                        steps.push({
                            id: current.id,
                            type: current.type,
                            kind: current.kind,
                            content: bodyLines.map(line => {
                                if (!line.trim()) return "";
                                const indentation = line.match(/^[ \t]*/)[0].length;
                                return line.slice(Math.min(commonIndent, indentation));
                            }).join("\n").trimEnd()
                        });
                        current = null;
                    }

                    for (const line of lines) {
                        const trimmed = line.trimStart();
                        const stepPrefix = trimmed.startsWith("step-id ")
                            ? "step-id "
                            : trimmed.startsWith("assertion-id ")
                                ? "assertion-id "
                                : null;
                        const trailerStart =
                            trimmed.startsWith("generate-file ") ||
                            trimmed.startsWith("step-parameters") ||
                            trimmed.startsWith("sut-param-init");

                        if (trailerStart) {
                            finishCurrentStep();
                            pastSteps = true;
                            trailer.push(line);
                            continue;
                        }

                        if (stepPrefix) {
                            finishCurrentStep();
                            current = {
                                id: trimmed.slice(stepPrefix.length).trim(),
                                type: "",
                                kind: stepPrefix === "assertion-id "
                                    ? "assertion"
                                    : "step",
                                lines: [line]
                            };
                            pastSteps = true;
                            continue;
                        }

                        if (current) {
                            current.lines.push(line);
                            if (trimmed.startsWith("step-type ")) {
                                current.type =
                                    trimmed.slice("step-type ".length).trim();
                            } else if (trimmed.startsWith("assertion-type ")) {
                                current.type =
                                    trimmed.slice("assertion-type ".length).trim();
                            }
                        } else if (pastSteps) {
                            trailer.push(line);
                        } else {
                            preamble.push(line);
                        }
                    }

                    finishCurrentStep();

                    return {
                        preamble: preamble.join("\n").trim(),
                        steps,
                        trailer: trailer.join("\n").trim()
                    };
                }

                const trace = parseTrace(traceText);

                // Shorten generated type qualifiers for display only; keep the source and IDs intact.
                function shortenInputTypeNames(text) {
                    return text.replace(
                        /\b[A-Z][A-Za-z0-9_]*Input\./g,
                        ""
                    );
                }

                // Map diagnostic step IDs to roles and group related steps into one navigation context.
                function diagnosticTraceData(result) {
                    const roles = new Map();
                    const contextsByFocus = new Map();
                    const stepIndices = new Map(trace.steps.map((step, index) => [step.id, index]));

                    function addRole(context, id, role, diagnostic) {
                        if (!stepIndices.has(id)) return;
                        if (!roles.has(id)) roles.set(id, new Set());
                        roles.get(id).add(role);
                        context.stepIds.add(id);
                        if (!context.roles.has(id)) context.roles.set(id, new Set());
                        context.roles.get(id).add(role);
                        context.diagnostics.add(diagnostic);
                    }

                    function contextFor(id) {
                        if (!contextsByFocus.has(id)) {
                            contextsByFocus.set(id, {
                                focusId: id,
                                stepIds: new Set([id]),
                                roles: new Map(),
                                diagnostics: new Set()
                            });
                        }
                        return contextsByFocus.get(id);
                    }

                    function attachToNearestActivation(id, role, activationIds, diagnostic) {
                        if (!stepIndices.has(id)) return;
                        if (!activationIds.length) {
                            addRole(contextFor(id), id, role, diagnostic);
                            return;
                        }

                        const relatedIndex = trace.steps.findIndex(step => step.id === id);
                        const nearestActivation = activationIds
                            .map(activationId => ({
                                id: activationId,
                                index: trace.steps.findIndex(step => step.id === activationId)
                            }))
                            .filter(item => item.index >= 0)
                            .sort((left, right) =>
                                Math.abs(left.index - relatedIndex) -
                                Math.abs(right.index - relatedIndex)
                            )[0];
                        if (nearestActivation) {
                            addRole(contextFor(nearestActivation.id), id, role, diagnostic);
                        } else {
                            addRole(contextFor(id), id, role, diagnostic);
                        }
                    }

                    for (const diagnostic of result.diagnostics || []) {
                        const activationIds =
                            (diagnostic.activationEvent?.stepIds || []).filter(id => stepIndices.has(id));
                        for (const id of activationIds) {
                            addRole(contextFor(id), id, "activation", diagnostic);
                        }

                        for (const [eventName, role] of [
                            ["event", "event"],
                            ["targetEvent", "target"],
                            ["blockerEvent", "blocker"]
                        ]) {
                            for (const id of diagnostic[eventName]?.stepIds || []) {
                                attachToNearestActivation(id, role, activationIds, diagnostic);
                            }
                        }
                        if (!activationIds.length) {
                            for (const id of diagnostic.event?.stepIds || []) {
                                if (stepIndices.has(id)) addRole(contextFor(id), id, "event", diagnostic);
                            }
                        }

                        const relation = diagnostic.violationStep;
                        if (!relation) continue;

                        if (relation.relation === "testCaseBoundary") {
                            const boundaryStep = relation.position === "first"
                                ? trace.steps[0]
                                : relation.position === "last"
                                    ? trace.steps[trace.steps.length - 1]
                                    : null;
                            if (boundaryStep) {
                                addRole(contextFor(boundaryStep.id), boundaryStep.id, "event", diagnostic);
                            }
                        } else if (
                            relation.relation === "immediateSuccessor" ||
                            relation.relation === "immediatePredecessor"
                        ) {
                            const activationIds =
                                diagnostic[relation.after || relation.of]?.stepIds || [];

                            for (const activationId of activationIds) {
                                const index = trace.steps.findIndex(
                                    step => step.id === activationId
                                );
                                if (index < 0) continue;

                                const offset =
                                    relation.relation === "immediateSuccessor" ? 1 : -1;
                                const relatedStep = trace.steps[index + offset];
                                if (relatedStep) {
                                    addRole(contextFor(activationId), relatedStep.id, "related", diagnostic);
                                }
                            }
                        }
                    }

                    const orderedContexts = Array.from(contextsByFocus.values());
                    orderedContexts.sort((left, right) =>
                        trace.steps.findIndex(step => step.id === left.focusId) -
                        trace.steps.findIndex(step => step.id === right.focusId)
                    );
                    return { roles, contexts: orderedContexts };
                }

                // Drop comments and collapse whitespace in expression text.
                function cleanExpressionText(text) {
                    return (text || "")
                        .replace(/\/\*[\s\S]*?\*\//g, "")
                        .replace(/(^|\s)\/\/.*$/gm, "$1")
                        .replace(/\s+/g, " ")
                        .trim();
                }

                // Split an access expression into its root variable and dotted field path.
                function referencePathParts(text) {
                    const cleaned = cleanExpressionText(text)
                        .replace(/^(get\(\s*)*((input|output)\s+)?/, "")
                        .replace(/\s+/g, "");
                    const match = /^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*/.exec(cleaned);
                    if (!match) return null;
                    const segments = match[0].split(".");
                    return { root: segments[0], path: segments.slice(1).join(".") };
                }

                function pathsOverlap(left, right) {
                    return left === right ||
                        left.startsWith(right + ".") ||
                        right.startsWith(left + ".");
                }

                // Split on commas that are not nested in brackets or quotes.
                function splitTopLevel(text) {
                    const parts = [];
                    let depth = 0;
                    let quote = "";
                    let start = 0;
                    for (let i = 0; i < text.length; i++) {
                        const character = text[i];
                        if (quote) {
                            if (character === "\\") i++;
                            else if (character === quote) quote = "";
                        } else if (character === "\"" || character === "'") {
                            quote = character;
                        } else if ("([{".includes(character)) {
                            depth++;
                        } else if (")]}".includes(character)) {
                            depth--;
                        } else if (character === "," && depth === 0) {
                            parts.push(text.slice(start, i).trim());
                            start = i + 1;
                        }
                    }
                    parts.push(text.slice(start).trim());
                    return parts.filter(Boolean);
                }

                // Reference links come from the constraint's consumes clauses plus reported violations.
                function selectedReferenceLinks(result) {
                    const links = [];
                    const seen = new Set();
                    function add(targetText, sourceText) {
                        const target = referencePathParts(targetText);
                        const key = (targetText || "").replace(/\s+/g, "") + "|" +
                            (sourceText || "").replace(/\s+/g, "");
                        if (!target || seen.has(key)) return;
                        seen.add(key);
                        links.push({ target, targetText, sourceText });
                    }

                    const definition = extractConstraintDefinition(
                        result.constraintName || result.constraint
                    );
                    const consumesPattern = /\bconsumes\s*\(/g;
                    let consumesMatch;
                    while ((consumesMatch = consumesPattern.exec(definition)) !== null) {
                        let depth = 0;
                        let body = "";
                        for (let i = consumesMatch.index + consumesMatch[0].length - 1;
                             i < definition.length; i++) {
                            const character = definition[i];
                            if (character === "(") {
                                depth++;
                                if (depth === 1) continue;
                            } else if (character === ")") {
                                depth--;
                                if (depth === 0) break;
                            }
                            body += character;
                        }
                        for (const part of splitTopLevel(cleanExpressionText(body))) {
                            const link = /^(.+?)\s+from\s+(.+)$/.exec(part);
                            if (link) add(link[1], link[2]);
                        }
                    }
                    for (const diagnostic of result.diagnostics || []) {
                        if (diagnostic.kind === "unsatisfiedReference") {
                            add(diagnostic.target, diagnostic.source);
                        }
                    }
                    return links;
                }

                // Field paths mentioned in the where/with clauses of the event role this step plays.
                function conditionPathsFor(result, roles, inputName) {
                    const paths = [];
                    if (!result || !roles || !inputName) return paths;
                    const definition = extractConstraintDefinition(
                        result.constraintName || result.constraint
                    ).replace(/\/\*[\s\S]*?\*\//g, "").replace(/(^|\s)\/\/.*$/gm, "$1");
                    let role = "";
                    for (const raw of definition.split(/\r?\n/)) {
                        const text = raw.trim();
                        if (/^(if|whenever)\b/.test(text)) role = "activation";
                        else if (/^then\b/.test(text)) role = "target";
                        else if (/^with\s+no\b/.test(text)) role = "blocker";
                        else if (/^must/.test(text)) role = "";
                        if (!role || !roles.has(role)) continue;
                        for (const match of text.matchAll(/\b[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)+/g)) {
                            const parts = referencePathParts(match[0]);
                            if (parts && parts.root === inputName) paths.push(parts.path);
                        }
                    }
                    return paths;
                }

                // Build a step body, marking assignments used by the constraint's conditions and reference links.
                function renderStepBody(step) {
                    const pre = document.createElement("pre");
                    const lines = step.content.split("\n");
                    const result = selectedResult;
                    const inputName =
                        (/^\s*step-input\s+(\S+)/m.exec(step.content) || [])[1] || "";
                    const selectedContext = contexts[contextIndex];
                    const inContext = !selectedContext || selectedContext.stepIds.has(step.id);
                    const stepRoles = new Set(selectedContext?.roles.get(step.id) || selectedTraceRoles.get(step.id) || []);
                    if (stepRoles.has("related")) stepRoles.add("target");
                    const conditionPaths =
                        inContext ? conditionPathsFor(result, stepRoles, inputName) : [];
                    const links = result && inContext ? selectedReferenceLinks(result) : [];
                    const violations = (result?.diagnostics || []).filter(diagnostic =>
                        inContext && (!selectedContext || selectedContext.diagnostics.has(diagnostic)) &&
                        diagnostic.kind === "unsatisfiedReference" &&
                        (diagnostic.targetEvent?.stepIds || []).includes(step.id)
                    );
                    const activationIds = new Set();
                    for (const diagnostic of result?.diagnostics || []) {
                        for (const id of diagnostic.activationEvent?.stepIds || []) {
                            activationIds.add(id);
                        }
                    }

                    const classes = lines.map(() => "");
                    const violationStarts = new Set();
                    const startPattern =
                        /^\s*([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*:=/;
                    const starts = [];
                    lines.forEach((line, index) => {
                        const match = startPattern.exec(line);
                        if (match) starts.push({ index, name: match[1] });
                    });

                    starts.forEach((start, position) => {
                        let end = position + 1 < starts.length
                            ? starts[position + 1].index
                            : lines.length;
                        for (let i = start.index + 1; i < end; i++) {
                            if (lines[i].trim() && !/^\s/.test(lines[i])) {
                                end = i;
                                break;
                            }
                        }
                        const statement = referencePathParts(start.name);
                        if (!statement || (inputName && statement.root !== inputName)) return;

                        const violation = violations.find(diagnostic => {
                            const target = referencePathParts(diagnostic.target);
                            return target && pathsOverlap(statement.path, target.path);
                        });
                        const relevant = violation || links.some(link =>
                            (!inputName || link.target.root === inputName) &&
                            pathsOverlap(statement.path, link.target.path)
                        );
                        const condition = conditionPaths.some(path =>
                            pathsOverlap(statement.path, path)
                        );
                        if (!relevant && !condition) return;

                        for (let i = start.index; i < end; i++) {
                            classes[i] = violation
                                ? "line-violation"
                                : relevant ? "line-relevant" : "line-condition";
                            if (relevant && !violation) {
                                const reference = /([A-Za-z_]\w*)\.output\b/.exec(lines[i]);
                                if (reference && activationIds.has(reference[1])) {
                                    classes[i] = "line-ref";
                                }
                            }
                        }
                        if (violation) violationStarts.add(start.index);
                    });

                    let firstViolation = null;
                    lines.forEach((line, index) => {
                        const element = document.createElement("span");
                        element.className = ("code-line " + classes[index]).trim();
                        element.textContent = line || " ";
                        if (classes[index]) {
                            element.title = classes[index] === "line-violation" ? "Reference mismatch"
                                : classes[index] === "line-condition" ? "Field used by a constraint condition"
                                : "Field selected by a reference check";
                        }
                        if (violationStarts.has(index) && !firstViolation) {
                            firstViolation = element;
                        }
                        pre.append(element);
                    });
                    pre.classList.toggle("has-highlights", classes.some(Boolean));
                    return { pre, firstViolation };
                }

                function updateContextControls() {
                    const hasTargets = contexts.length > 0;
                    document.querySelector("#previous-context").disabled =
                        !hasTargets || contextIndex <= 0;
                    document.querySelector("#next-context").disabled =
                        !hasTargets || contextIndex >= contexts.length - 1;
                    document.querySelector("#context-position").textContent =
                        hasTargets
                            ? "Context " + (contextIndex + 1) + " of " + contexts.length +
                                " / step " + (trace.steps.findIndex(step => step.id === contexts[contextIndex].focusId) + 1)
                            : "No diagnostic context";
                }

                // Keep large step bodies out of the DOM until the user opens that step.
                function renderTrace(scrollToContext = false) {
                    const previousPanels = traceView.querySelector(".trace-panels");
                    const traceScroll = previousPanels?.scrollTop || 0;
                    const traceHorizontalScroll = previousPanels?.scrollLeft || 0;
                    const sequenceScroll = traceView.querySelector(".trace-sequence")?.scrollLeft || 0;
                    for (const details of traceView.querySelectorAll(".trace-step")) {
                        if (details.open) {
                            expandedSteps.add(details.dataset.stepId);
                            collapsedSteps.delete(details.dataset.stepId);
                        } else {
                            collapsedSteps.add(details.dataset.stepId);
                            expandedSteps.delete(details.dataset.stepId);
                        }
                    }
                    traceView.replaceChildren();
                    const sequence = document.createElement("nav");
                    sequence.className = "trace-sequence";
                    sequence.setAttribute("aria-label", "Test step sequence");
                    const panels = document.createElement("div");
                    panels.className = "trace-panels";
                    panels.setAttribute("role", "region");
                    panels.setAttribute("aria-label", "Test steps in sequence order");
                    panels.tabIndex = 0;
                    traceView.append(sequence, panels);

                    const focusedContext = contexts[contextIndex];
                    updateInspection();
                    traceView.classList.toggle("relevant-lines", !document.querySelector("#all-lines").checked);
                    const entireTrace = document.querySelector("#all-steps").checked || !focusedContext;
                    const intermediate = document.querySelector("#intermediate-steps").checked;
                    document.querySelector("#intermediate-steps").disabled = entireTrace;
                    const indices = trace.steps.map((step, index) =>
                        focusedContext?.stepIds.has(step.id) ? index : -1
                    ).filter(index => index >= 0);
                    const firstIndex = Math.min(...indices);
                    const lastIndex = Math.max(...indices);
                    function baseVisible(index) {
                        return entireTrace || focusedContext.stepIds.has(trace.steps[index].id) ||
                            (intermediate && index > firstIndex && index < lastIndex);
                    }
                    function appendGap(start, count) {
                        const gap = document.createElement("label");
                        gap.className = "trace-gap";
                        const checkbox = document.createElement("input");
                        checkbox.type = "checkbox";
                        checkbox.checked = revealedGaps.has(trace.steps[start].id);
                        checkbox.setAttribute("aria-label", "Show " + count + " steps starting at step " + (start + 1));
                        checkbox.addEventListener("change", () => {
                            for (let index = start; index < start + count; index++) {
                                if (checkbox.checked) revealedGaps.add(trace.steps[index].id);
                                else revealedGaps.delete(trace.steps[index].id);
                            }
                            renderTrace();
                        });
                        gap.append(checkbox, document.createTextNode("... " + count + " steps"));
                        sequence.append(gap);
                    }
                    const focusedId = focusedContext?.focusId;
                    let focusedElement = null;
                    let focusedLink = null;

                    function ensureStepBody(details, step) {
                        if (details.dataset.bodyRendered === "true") return null;
                        const body = renderStepBody(step);
                        details.append(body.pre);
                        details.dataset.bodyRendered = "true";
                        return body;
                    }

                    for (const [stepIndex, step] of trace.steps.entries()) {
                        if (!baseVisible(stepIndex)) {
                            if (stepIndex === 0 || baseVisible(stepIndex - 1)) {
                                let end = stepIndex + 1;
                                while (end < trace.steps.length && !baseVisible(end)) end++;
                                appendGap(stepIndex, end - stepIndex);
                            }
                            if (!revealedGaps.has(step.id)) continue;
                        }
                        const details = document.createElement("details");
                        const inContext =
                            focusedContext?.stepIds.has(step.id) || false;
                        const roles = inContext
                            ? focusedContext.roles.get(step.id) || new Set()
                            : new Set();
                        const highlighted = inContext && selectedTraceIds.has(step.id);
                        const focused = step.id === focusedId;

                        details.className = "trace-step";
                        details.dataset.stepId = step.id;
                        details.classList.toggle("highlighted", highlighted);
                        details.classList.toggle("context-focus", focused);
                        for (const role of roles) {
                            details.classList.add("role-" + role);
                        }
                        const summaryLine = document.createElement("summary");
                        const roleLabel = document.createElement("span");
                        roleLabel.className = "step-role";
                        roleLabel.textContent = "#" + (stepIndex + 1) + "  " +
                            (Array.from(roles).map(role => role === "related" ? "Adjacent step" : role).join(" / ") || "Step");
                        const stepId = document.createElement("span");
                        stepId.className = "step-id";
                        stepId.textContent = "step-id " + step.id;
                        const stepType = document.createElement("span");
                        stepType.className = "step-type";
                        stepType.textContent =
                            (step.kind === "assertion"
                                ? "assertion-type "
                                : "step-type ") + step.type;
                        summaryLine.append(roleLabel, stepType, stepId);
                        const stepLink = document.createElement("button");
                        stepLink.type = "button";
                        stepLink.className = "sequence-step";
                        for (const role of roles) stepLink.classList.add("role-" + role);
                        stepLink.textContent = "#" + (stepIndex + 1) + " " + step.type;
                        stepLink.title = Array.from(roles).join(" / ") + " " + step.id;
                        stepLink.setAttribute("aria-current", focused ? "step" : "false");
                        if (focused) focusedLink = stepLink;
                        stepLink.addEventListener("click", () => {
                            let linkedContext = contexts.findIndex(context => context.focusId === step.id);
                            if (linkedContext < 0 && !inContext) {
                                linkedContext = contexts.findIndex(context => context.stepIds.has(step.id));
                            }
                            if (linkedContext >= 0 && linkedContext !== contextIndex) {
                                moveContext(linkedContext - contextIndex);
                                return;
                            }
                            details.open = true;
                            ensureStepBody(details, step);
                            details.scrollIntoView({ block: "nearest", inline: "nearest" });
                            summaryLine.focus();
                        });
                        sequence.append(stepLink);

                        details.append(summaryLine);
                        details.addEventListener("toggle", () => {
                            if (!details.isConnected) return;
                            if (details.open) ensureStepBody(details, step);
                            if (details.open) {
                                expandedSteps.add(step.id);
                                collapsedSteps.delete(step.id);
                            } else {
                                expandedSteps.delete(step.id);
                                collapsedSteps.add(step.id);
                            }
                        });
                        details.open = (scrollToContext && inContext) ||
                            (!collapsedSteps.has(step.id) && (expandedSteps.has(step.id) || inContext));
                        panels.append(details);

                        // Open steps that hold a violation so the offending line is visible.
                        if (inContext) {
                            const body = ensureStepBody(details, step);
                            if (body?.firstViolation) {
                                details.open = scrollToContext || !collapsedSteps.has(step.id);
                            }
                        }

                        if (focused) focusedElement = details;
                    }

                    if (focusedContext) {
                        const missingTarget = (selectedResult?.diagnostics || []).find(diagnostic =>
                            diagnostic.targetEvent && !diagnostic.targetEvent.stepIds?.length &&
                            diagnostic.activationEvent?.stepIds?.some(id => focusedContext.stepIds.has(id))
                        );
                        const hasTarget = Array.from(focusedContext.stepIds).some(id =>
                            focusedContext.roles.get(id)?.has("target")
                        );
                        if (missingTarget && !hasTarget) {
                            const empty = document.createElement("section");
                            empty.className = "missing-target";
                            const heading = document.createElement("h2");
                            heading.textContent = "Target not matched";
                            const event = document.createElement("p");
                            event.textContent = missingTarget.targetEvent.name || "Target";
                            empty.append(heading, event);
                            panels.append(empty);
                        }
                    }

                    if (scrollToContext) {
                        if (focusedElement) {
                            panels.scrollLeft += focusedElement.getBoundingClientRect().left - panels.getBoundingClientRect().left;
                            panels.scrollTop = 0;
                        }
                        focusedLink?.scrollIntoView({ block: "nearest", inline: "center" });
                    } else {
                        panels.scrollTop = traceScroll;
                        panels.scrollLeft = traceHorizontalScroll;
                        sequence.scrollLeft = sequenceScroll;
                    }
                }

                function moveContext(offset) {
                    if (!contexts.length) return;
                    revealedGaps.clear();

                    const nextIndex = Math.max(
                        0,
                        Math.min(
                            contexts.length - 1,
                            contextIndex + offset
                        )
                    );
                    const previous = contexts[contextIndex];
                    const next = contexts[nextIndex];
                    for (const step of traceView.querySelectorAll(".trace-step")) {
                        if (previous?.stepIds.has(step.dataset.stepId) && !next.stepIds.has(step.dataset.stepId)) {
                            step.open = false;
                        }
                    }
                    contextIndex = nextIndex;
                    updateContextControls();
                    renderTrace(true);
                }

                document.querySelector("#previous-context").addEventListener(
                    "click",
                    () => moveContext(-1)
                );
                document.querySelector("#next-context").addEventListener(
                    "click",
                    () => moveContext(1)
                );

                function appendColoredMessage(container, text) {
                    const rolePattern = /\b(activation|target|blocker)\b/gi;
                    let previousIndex = 0;
                    let match;

                    while ((match = rolePattern.exec(text)) !== null) {
                        if (match.index > previousIndex) {
                            container.append(document.createTextNode(
                                text.slice(previousIndex, match.index)
                            ));
                        }
                        const role = document.createElement("span");
                        role.className = "role-" + match[0].toLowerCase();
                        role.textContent = match[0];
                        container.append(role);
                        previousIndex = rolePattern.lastIndex;
                    }

                    if (previousIndex < text.length) {
                        container.append(document.createTextNode(
                            text.slice(previousIndex)
                        ));
                    }
                }

                // Put conjunctions on separate rows without splitting text inside quoted values.
                function formatConjunctions(text) {
                    const parts = [];
                    let start = 0;
                    let quote = "";
                    let escaped = false;

                    for (let index = 0; index < text.length; index++) {
                        const character = text[index];
                        if (quote) {
                            if (escaped) {
                                escaped = false;
                            } else if (character === "\\") {
                                escaped = true;
                            } else if (character === quote) {
                                quote = "";
                            }
                            continue;
                        }
                        if (character === "\"" || character === "'") {
                            quote = character;
                            continue;
                        }

                        if (
                            text.startsWith("and", index) &&
                            index > 0 && /\s/.test(text[index - 1]) &&
                            index + 3 < text.length && /\s/.test(text[index + 3])
                        ) {
                            parts.push(text.slice(start, index).trim());
                            start = index;
                            index += 2;
                        }
                    }

                    parts.push(text.slice(start).trim());
                    return parts.join("\n");
                }

                // Render a serialized reference path as step.output.field["key"][index].
                function formatReferencePath(path) {
                    if (!Array.isArray(path) || path.length !== 2) return "";
                    let text = String(path[0]);
                    for (const [kind, selection] of path[1] || []) {
                        if (kind === "field") text += "." + selection;
                        else if (kind === "key") text += "[" + JSON.stringify(selection) + "]";
                        else if (kind === "index") text += "[" + selection + "]";
                    }
                    return text;
                }

                function stepTypeFor(stepIds) {
                    const step = trace.steps.find(item => item.id === (stepIds || [])[0]);
                    return step ? step.type : "";
                }

                function appendDiagnosticField(container, label, value) {
                    const field = document.createElement("div");
                    field.className = "diagnostic-field";

                    const fieldLabel = document.createElement("span");
                    fieldLabel.className = "diagnostic-field-label";
                    fieldLabel.textContent = label;

                    const fieldValue = document.createElement("span");
                    fieldValue.className = "diagnostic-field-value";
                    fieldValue.textContent = formatConjunctions(value);

                    field.append(fieldLabel, fieldValue);
                    container.append(field);
                }

                // Build the selected constraint's diagnostic panel from structured verdict fields.
                function showResult(result) {
                    selectedResult = result;
                    traceView.replaceChildren();
                    expandedSteps.clear();
                    collapsedSteps.clear();
                    revealedGaps.clear();
                    diagnosticElements.length = 0;
                    detail.replaceChildren();
                    document.querySelector("#selected-definition").scrollTop = 0;
                    document.querySelector("#diagnostics-host").scrollTop = 0;

                    const title = document.createElement("h2");
                    title.textContent =
                        result.constraintName || result.constraint || "Constraint";
                    detail.append(title);

                    const type = document.createElement("p");
                    type.className = "muted";
                    type.textContent = result.templateType || "";
                    detail.append(type);

                    for (const diagnostic of result.diagnostics || []) {
                        const message = document.createElement("p");
                        message.className = "message";
                        const narrative = document.createElement("span");
                        narrative.className = "diagnostic-message";
                        if (diagnostic.event) {
                            narrative.classList.add("role-event");
                            message.classList.add("role-event");
                        }
                        appendColoredMessage(
                            narrative,
                            shortenInputTypeNames(
                                diagnostic.message || diagnostic.kind
                            )
                        );
                        message.append(narrative);

                        for (const [eventName, role, label] of [
                            ["activationEvent", "activation", "Activation"],
                            ["targetEvent", "target", "Target"],
                            ["blockerEvent", "blocker", "Blocker"],
                            ["event", "event", "Step type"]
                        ]) {
                            const eventInfo = diagnostic[eventName];
                            if (!eventInfo) continue;

                            const eventDetail = document.createElement("span");
                            eventDetail.className =
                                "diagnostic-event role-" + role;
                            const heading = document.createElement("div");
                            heading.className = "diagnostic-event-heading";
                            const roleLabel = document.createElement("span");
                            roleLabel.textContent = label;
                            const eventDisplayName = document.createElement("span");
                            eventDisplayName.textContent =
                                eventInfo.name || stepTypeFor(eventInfo.stepIds);
                            heading.append(roleLabel, eventDisplayName);
                            eventDetail.append(heading);

                            const fields = document.createElement("div");
                            fields.className = "diagnostic-event-fields";
                            if (eventInfo.whereConcrete) {
                                appendDiagnosticField(
                                    fields,
                                    "Where concrete",
                                    shortenInputTypeNames(eventInfo.whereConcrete)
                                );
                            }
                            if (eventInfo.correlationBinding) {
                                appendDiagnosticField(
                                    fields,
                                    "Correlation binding",
                                    shortenInputTypeNames(eventInfo.correlationBinding)
                                );
                            }
                            if (eventInfo.whereCorrelation) {
                                appendDiagnosticField(
                                    fields,
                                    "Where correlation",
                                    shortenInputTypeNames(eventInfo.whereCorrelation)
                                );
                            }
                            if (eventInfo.stepIds?.length) {
                                appendDiagnosticField(
                                    fields,
                                    "Test steps",
                                    eventInfo.stepIds.join(", ")
                                );
                            }
                            eventDetail.append(fields);
                            message.append(eventDetail);
                        }

                        if (diagnostic.kind === "unsatisfiedReference") {
                            const referenceDetail = document.createElement("span");
                            referenceDetail.className = "diagnostic-event role-target";
                            const heading = document.createElement("div");
                            heading.className = "diagnostic-event-heading";
                            heading.textContent = "Reference check";
                            const fields = document.createElement("div");
                            fields.className = "diagnostic-event-fields";
                            appendDiagnosticField(
                                fields,
                                "Consumed input",
                                shortenInputTypeNames(cleanExpressionText(diagnostic.target))
                            );
                            appendDiagnosticField(
                                fields,
                                "Required source",
                                shortenInputTypeNames(cleanExpressionText(diagnostic.source))
                            );
                            const expectedText = formatReferencePath(diagnostic.expected);
                            if (expectedText) {
                                appendDiagnosticField(
                                    fields,
                                    "Expected reference",
                                    expectedText
                                );
                            }
                            const actualTexts = (diagnostic.actual || [])
                                .map(formatReferencePath)
                                .filter(Boolean);
                            appendDiagnosticField(
                                fields,
                                "Actual references",
                                actualTexts.length ? actualTexts.join(", ") : "none"
                            );
                            referenceDetail.append(heading, fields);
                            message.append(referenceDetail);
                        }
                        detail.append(message);
                        diagnosticElements.push({ element: message, diagnostic });
                    }
                    if (!diagnosticElements.length) {
                        const empty = document.createElement("p");
                        empty.className = "muted";
                        empty.textContent = result.accepted ? "Accepted. No violations reported." : "No diagnostic details reported.";
                        detail.append(empty);
                    }

                    const traceData = diagnosticTraceData(result);
                    selectedTraceRoles = traceData.roles;
                    selectedTraceIds = new Set(selectedTraceRoles.keys());
                    contexts = traceData.contexts;
                    contextIndex = contexts.length ? 0 : -1;

                    updateContextControls();
                    renderTrace(true);
                }

                // The summary stores the full constraint file; select only the clicked declaration.
                function extractConstraintDefinition(name) {
                    if (!name || !constraintSourceText) return "";

                    const escapedName = name.replace(
                        /[.*+?^${}()|[\]\\]/g,
                        "\\$&"
                    );
                    const startPattern = new RegExp(
                        "^\\s*constraint\\s+" + escapedName + "(?=\\s|\\()",
                        "m"
                    );
                    const startMatch = startPattern.exec(constraintSourceText);
                    if (!startMatch) return "";

                    const nextPattern = /^\s*constraint\s+[A-Za-z_][\w.-]*(?=\s|\(|$)/gm;
                    nextPattern.lastIndex = startMatch.index + startMatch[0].length;
                    const nextMatch = nextPattern.exec(constraintSourceText);
                    const end = nextMatch ? nextMatch.index : constraintSourceText.length;

                    return constraintSourceText
                        .slice(startMatch.index, end)
                        .trim();
                }

                // Give temporal indicators, event roles, and their conditions distinct visual rows.
                function renderConstraintDefinition(sourceText) {
                    const definition = document.createElement("div");
                    definition.className = "constraint-definition";
                    let declarationText = "";
                    let declarationParenDepth = 0;
                    let collectingDeclaration = false;
                    let indicatorSeen = false;
                    let currentRole = "";
                    let insideBlockComment = false;

                    for (const rawLine of sourceText.split(/\r?\n/)) {
                        const text = rawLine.trim();
                        if (!text) continue;

                        if (insideBlockComment) {
                            if (text.includes("*/")) insideBlockComment = false;
                            continue;
                        }
                        if (text.startsWith("//")) continue;
                        if (text.startsWith("/*")) {
                            insideBlockComment = !text.includes("*/");
                            continue;
                        }

                        if (collectingDeclaration) {
                            declarationText += "\n" + rawLine.trimEnd();
                            declarationParenDepth +=
                                (text.match(/\(/g) || []).length -
                                (text.match(/\)/g) || []).length;
                            collectingDeclaration = declarationParenDepth > 0;
                            continue;
                        }

                        if (text.startsWith("constraint ")) {
                            declarationText = text;
                            declarationParenDepth =
                                (text.match(/\(/g) || []).length -
                                (text.match(/\)/g) || []).length;
                            collectingDeclaration = declarationParenDepth > 0;
                            continue;
                        }

                        if (!indicatorSeen) {
                            const indicator = /^(PF|F|P|E|C)\s*(<->|->|!>|>|<-|>=|<=|=|\^|\$)/.exec(text);
                            if (indicator) {
                                const badge = document.createElement("div");
                                badge.className = "constraint-indicator";
                                badge.textContent = indicator[0];
                                if (declarationText) {
                                    const declaration = document.createElement("div");
                                    declaration.className = "constraint-declaration";
                                    declaration.textContent = declarationText;
                                    definition.append(declaration);
                                    declarationText = "";
                                }
                                definition.append(badge);
                                indicatorSeen = true;
                                continue;
                            }
                        }

                        let label = "";
                        if (/^(if|whenever)\b/.test(text)) {
                            label = "Activation";
                            currentRole = "activation";
                        } else if (/^then\b/.test(text)) {
                            label = "Target";
                            currentRole = "target";
                        } else if (/^with\s+no\b/.test(text)) {
                            label = "Blocker";
                            currentRole = "blocker";
                        } else if (text.startsWith("where-concrete")) {
                            label = "Where concrete";
                        } else if (text.startsWith("where-correlation")) {
                            label = "Where correlation";
                        } else if (text.startsWith("consumes")) {
                            label = "Consumes";
                        } else if (text.startsWith("with ") || text.startsWith("with-correlation")) {
                            label = "Correlation binding";
                        } else if (text.startsWith("must")) {
                            label = "Requirement";
                            currentRole = "";
                        } else {
                            label = "";
                        }

                        const line = document.createElement("div");
                        line.className = "constraint-line";
                        if (/^[(){} ,]+$/.test(text)) line.classList.add("constraint-punctuation");
                        if (currentRole) line.classList.add("role-" + currentRole);
                        const lineLabel = document.createElement("span");
                        lineLabel.className = "constraint-line-label";
                        lineLabel.textContent = label;
                        line.append(lineLabel);
                        const lineText = document.createElement("span");
                        lineText.textContent = rawLine.trimEnd();
                        line.append(lineText);
                        definition.append(line);
                    }

                    if (declarationText) {
                        const declaration = document.createElement("div");
                        declaration.className = "constraint-declaration";
                        declaration.textContent = declarationText;
                        definition.prepend(declaration);
                    }
                    return definition;
                }

                const constraintsPanel = document.querySelector("#constraints-panel");
                document.querySelector("#diagnostics-host").append(detail);
                for (const id of ["full-constraint", "all-diagnostics", "intermediate-steps", "all-steps", "all-lines"]) {
                    document.getElementById(id).addEventListener("change", () => {
                        if (id === "full-constraint" || id === "all-diagnostics") {
                            updateInspection();
                        } else if (id === "all-lines") {
                            traceView.classList.toggle("relevant-lines", !document.getElementById(id).checked);
                        } else {
                            renderTrace();
                        }
                    });
                }
                let focusedEntry = null;

                // The diagnostics panel is moved under the focused entry and back again on exit.
                function exitFocus() {
                    if (!focusedEntry) return;
                    document.querySelector("#diagnostics-host").append(detail);
                    focusedEntry.querySelector(".focus-diagnostics")?.remove();
                    focusedEntry.querySelector(".focus-toggle").textContent = "Focus";
                    focusedEntry.querySelector(".focus-toggle").setAttribute("aria-pressed", "false");
                    focusedEntry.classList.remove("focused");
                    constraintsPanel.classList.remove("focus-mode");
                    focusedEntry = null;
                }

                function enterFocus(entry) {
                    exitFocus();
                    focusedEntry = entry;
                    entry.classList.add("focused");
                    constraintsPanel.classList.add("focus-mode");

                    entry.querySelector(".focus-toggle").textContent = "Unfocus";
                    entry.querySelector(".focus-toggle").setAttribute("aria-pressed", "true");
                    entry.scrollIntoView({ block: "start" });
                }

                // Each result keeps its diagnostic button and source disclosure together in the list.
                function addGroup(targetId, results, accepted) {
                    const target = document.querySelector(targetId);

                    if (!results.length) {
                        const empty = document.createElement("p");
                        empty.className = "muted";
                        empty.textContent = "None";
                        target.append(empty);
                        return;
                    }

                    for (const result of results) {
                        const constraintName =
                            result.constraintName || result.constraint || "Constraint";
                        const button = document.createElement("button");
                        button.className = accepted
                            ? "constraint-select"
                            : "constraint-select failed";
                        button.type = "button";
                        button.innerHTML = "<strong></strong><span></span>";
                        button.querySelector("strong").textContent =
                            constraintName;
                        button.querySelector("span").textContent =
                            (accepted ? "Accepted" : "Violated") + " | " + (result.templateType || "");
                        button.addEventListener("click", () => {
                            exitFocus();
                            document.querySelectorAll(".constraint-select").forEach(item =>
                                item.setAttribute("aria-current", "false")
                            );
                            button.setAttribute("aria-current", "true");
                            showResult(result);
                        });

                        const entry = document.createElement("div");
                        entry.className = "constraint-entry";
                        const entryHeader = document.createElement("div");
                        entryHeader.className = "constraint-entry-header";
                        entryHeader.append(button);
                        if (!accepted) {
                            const focusToggle = document.createElement("button");
                            focusToggle.className = "focus-toggle";
                            focusToggle.type = "button";
                            focusToggle.textContent = "Focus";
                            focusToggle.setAttribute("aria-label", "Focus " + constraintName);
                            focusToggle.setAttribute("aria-pressed", "false");
                            focusToggle.addEventListener("click", () => {
                                if (focusedEntry === entry) {
                                    exitFocus();
                                    return;
                                }
                                button.click();
                                enterFocus(entry);
                            });
                            entryHeader.append(focusToggle);
                        }
                        entry.append(entryHeader);

                        target.append(entry);
                    }
                }

                const results = summary.results || [];
                const failed = results.filter(item => item.accepted === false);
                const accepted = results.filter(item => item.accepted === true);
                addGroup("#failed", failed, false);
                addGroup("#accepted", accepted, true);
                renderTrace();

                if (failed.length) {
                    const firstFailedButton =
                        document.querySelector("#failed .constraint-select");
                    if (firstFailedButton) {
                        firstFailedButton.setAttribute("aria-current", "true");
                    }
                    showResult(failed[0]);
                } else if (accepted.length) {
                    document.querySelector("#accepted .constraint-select").click();
                }
            </script>
        </body>
        </html>
        '''
    }

    private def String inspectionStyles() {
        '''
        <style>
            :root { background: #f4f6f7; font-family: "Segoe UI Variable Text", "Segoe UI", sans-serif; --activation-color: #0072b2; --activation-bg: #edf5fa; --target-color: #475569; --target-bg: #f1f3f5; --blocker-color: #a63603; --blocker-bg: #fceee7; }
            * { box-sizing: border-box; }
            [hidden] { display: none !important; }
            header { padding: 12px 20px; background: #253b37; }
            h1 { font-size: 18px; }
            .file-meta p { overflow-wrap: anywhere; min-width: 0; }
            main { grid-template-columns: var(--sidebar-width, 260px) 8px minmax(0, 1fr); grid-template-rows: minmax(180px, var(--inspection-height, 38%)) 8px minmax(0, 1fr); grid-template-areas: "constraints sidebar inspection" "horizontal horizontal horizontal" "testcase testcase testcase"; gap: 0; padding: 0; }
            .pane-divider { background: #e6ece9; cursor: col-resize; touch-action: none; position: relative; z-index: 3; }
            .pane-divider::after { content: ""; position: absolute; width: 2px; height: 28px; left: calc(50% - 1px); top: calc(50% - 14px); background: #9caca5; border-radius: 2px; }
            .pane-divider:hover, .pane-divider:focus-visible { background: #b7d4ca; }
            .pane-divider.horizontal { cursor: row-resize; }
            .pane-divider.horizontal::after { width: 28px; height: 2px; left: calc(50% - 14px); top: calc(50% - 1px); }
            #sidebar-divider { grid-area: sidebar; }
            #inspection-divider { grid-area: horizontal; }
            #definition-divider { grid-column: 2; grid-row: 2; }
            body.resizing { user-select: none; }
            #constraints-panel { grid-area: constraints; padding: 14px 12px; border-right: 1px solid #d5ddda; }
            #constraints-panel nav h2 { background: #f4f6f7; font-size: 12px; padding: 10px 0; }
            .constraint-select { min-width: 0; padding: 10px 8px; border-radius: 4px; }
            .constraint-select strong { font-size: 12px; font-weight: 600; overflow-wrap: anywhere; }
            .constraint-select span { margin-top: 4px; font-size: 11px; }
            .constraint-select { border-left-color: #64748b; }
            .constraint-select.failed { border-left: 4px double #a63603; }
            button[aria-current="true"] { outline: 2px solid #253342; }
            .constraint-entry { margin: 0 0 8px; }
            .constraint-entry-header > .focus-toggle { padding: 0 6px; font-size: 11px; }
            .constraint-source { border: 0; background: transparent; }
            .constraint-source summary { font-size: 11px; padding: 6px 4px; }
            #inspection-panel { grid-area: inspection; display: grid; grid-template-columns: minmax(0, var(--definition-width, 50fr)) 8px minmax(0, var(--diagnostics-width, 50fr)); grid-template-rows: auto minmax(0, 1fr); gap: 0 12px; min-width: 0; min-height: 0; overflow: hidden; padding: 12px 20px; background: #fff; border-bottom: 1px solid #d5ddda; }
            #inspection-panel > .inspection-toolbar { grid-column: 1 / -1; padding-bottom: 10px; }
            #selected-definition, #diagnostics-host { min-width: 0; min-height: 0; overflow: auto; padding-right: 8px; }
            #detail, #constraints-panel:not(.focus-mode) #detail { display: block; min-height: 0; max-height: none; margin: 12px 0 0; padding: 0; border: 0; overflow: visible; }
            #detail h2 { overflow-wrap: anywhere; font-size: 14px; }
            .inspection-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 10px 16px; padding: 8px 0 12px; }
            .inspection-toolbar label { display: inline-flex; gap: 6px; align-items: center; font-size: 12px; color: #435357; cursor: pointer; }
            .inspection-toolbar button { width: auto; margin: 0 0 0 auto; padding: 5px 8px; border: 1px solid #c9d4d0; border-radius: 4px; font-size: 11px; }
            .inspection-toolbar input[type="range"] { width: 90px; accent-color: #24766b; }
            input[type="checkbox"] { accent-color: #24766b; margin: 0; flex-shrink: 0; }
            :focus-visible { outline: 2px solid #24766b; outline-offset: 3px; }
            .constraint-definition { border: 0; padding: 0; background: transparent; }
            #selected-definition > h2 { margin: 0 0 12px; font-size: 14px; }
            .constraint-declaration { white-space: pre-wrap; overflow-wrap: anywhere; line-height: 1.6; margin-bottom: 12px; }
            .constraint-indicator { display: block; width: max-content; }
            .constraint-line { grid-template-columns: 90px minmax(0, 1fr); font-size: 12px; padding: 2px 0; }
            .constraint-line-label { font-size: 10px; }
            .compact-definition .constraint-declaration, .compact-definition .constraint-punctuation { display: none; }
            .message { margin: 12px 0; padding: 10px 8px; background: #f7f9fa; font-size: 12px; overflow-wrap: anywhere; }
            .diagnostic-message { display: block; }
            .diagnostic-message .role-activation, .diagnostic-message .role-target, .diagnostic-message .role-blocker { color: #253342; }
            .message.role-event, .diagnostic-event.role-event { color: #253342; background: #f1f3f5; border-color: #64748b; }
            .diagnostic-field, .diagnostic-event-heading { grid-template-columns: 1fr; gap: 2px; }
            .diagnostic-event { padding: 6px; font-size: 11px; }
            #detail:not(.expanded-diagnostics) .diagnostic-event.role-activation .diagnostic-event-fields,
            #detail:not(.expanded-diagnostics) .diagnostic-event.role-blocker .diagnostic-event-fields { display: none; }
            #testcase-panel { grid-area: testcase; border: 0; background: #f4f6f7; padding: 12px 20px; }
            #testcase-panel > h2 { margin: 0 0 10px; font-size: 14px; }
            .trace-toolbar { flex-wrap: wrap; gap: 8px; margin: 0; }
            .trace-toolbar button { border: 1px solid #c9d4d0; border-radius: 4px; padding: 7px 10px; font-size: 12px; }
            .highlight-legend { display: flex; flex-wrap: wrap; gap: 8px 20px; padding: 0 0 8px; color: #253342; font-size: 11px; }
            .highlight-legend span { padding-left: 8px; }
            .legend-condition { border-left: 4px dotted #64748b; }
            .legend-reference { border-left: 4px solid #0072b2; }
            .legend-violation { border-left: 4px double #a63603; }
            #trace-view { display: flex; flex-direction: column; gap: 8px; overflow: hidden; padding: 4px; }
            .trace-panels { display: flex; flex: 1; min-height: 0; gap: 12px; align-items: flex-start; overflow: auto; padding: 4px 2px 12px; }
            .trace-panels > * { flex: 0 0 calc(var(--step-left-width, 50%) - 6px); }
            .trace-panels > :nth-child(even) { flex-basis: calc(var(--step-right-width, 50%) - 6px); }
            .trace-step { min-width: 0; margin: 0; padding: 0; border-radius: 4px; background: #fff; }
            .trace-panels > .trace-step:not([open]) { flex-basis: 190px; }
            .trace-step.highlighted, .trace-step.role-activation, .trace-step.role-target, .trace-step.role-event, .trace-step.role-blocker { background: #fff; border-color: #8c9ca5; }
            .trace-step.role-related { border-left: 4px dashed #64748b; }
            .trace-step.context-focus { outline: 2px solid #253342; }
            .trace-step summary { padding: 10px; font: 12px/1.5 "Segoe UI", sans-serif; }
            .trace-step[open] summary { font: 12px/1.5 "Segoe UI", sans-serif; border-bottom: 1px solid #d5ddda; }
            .step-role { display: block; font-size: 11px; text-transform: uppercase; font-weight: 600; }
            .trace-step .step-type, .trace-step[open] .step-type { font-size: 12px; font-weight: 600; color: #202a31; margin: 4px 0; }
            .trace-step .step-id, .trace-step[open] .step-id { font-size: 10px; font-weight: 400; color: #526166; }
            .trace-step pre { margin: 0; padding: 8px 0; max-height: 38vh; font-size: 12px; line-height: 1.65; background: #fff; }
            .trace-step pre .code-line { padding: 1px 10px; }
            .trace-step pre .line-condition { color: #253342; background: #f1f3f5; border-left: 4px dotted #64748b; box-shadow: none; }
            .trace-step pre .line-relevant, .trace-step pre .line-ref { color: #253342; background: #edf5fa; border-left: 4px solid #0072b2; box-shadow: none; }
            .trace-step pre .line-violation { color: #572000; background: #fceee7; border-left: 4px double #a63603; box-shadow: none; }
            .missing-target { min-width: 0; padding: 16px; background: #fff; border: 1px dashed #9ba9a4; border-radius: 4px; color: #526166; overflow-wrap: anywhere; }
            .missing-target h2 { margin: 0 0 6px; font-size: 13px; }
            .missing-target p { margin: 0; font-size: 12px; }
            .relevant-lines .has-highlights .code-line:not(.line-relevant):not(.line-ref):not(.line-condition):not(.line-violation) { display: none; }
            .trace-sequence { display: flex; flex-shrink: 0; gap: 8px; align-items: center; overflow-x: auto; padding: 4px 2px 10px; }
            .sequence-step { flex: 0 0 150px; width: 150px; height: 48px; margin: 0; padding: 6px 8px; border: 1px solid #c9d4d0; border-radius: 4px; font-size: 11px; overflow: hidden; overflow-wrap: anywhere; }
            .sequence-step.role-activation { border-top: 3px solid var(--activation-color); }
            .sequence-step.role-target { border-top: 3px solid var(--target-color); }
            .sequence-step.role-blocker { border-top: 3px solid var(--blocker-color); }
            .sequence-step.role-related { border-top: 3px dashed #64748b; }
            .sequence-step[aria-current="step"] { outline: 2px solid #253342; outline-offset: -2px; font-weight: 700; }
            .trace-gap { display: flex; flex: 0 0 auto; justify-content: center; align-items: center; gap: 8px; padding: 5px; font-size: 11px; color: #526166; cursor: pointer; }
            @media (max-width: 850px) {
                body { display: block; height: auto; overflow: auto; }
                main { grid-template-columns: 1fr; grid-template-rows: auto auto auto; grid-template-areas: "constraints" "inspection" "testcase"; }
                .pane-divider { display: none; }
                .inspection-toolbar .step-split-control { display: none; }
                #constraints-panel { max-height: 240px; overflow: auto; }
                #constraints-panel nav { overflow: visible; flex: none; }
                #inspection-panel, #testcase-panel { overflow: visible; }
                #inspection-panel { display: block; }
                #selected-definition, #diagnostics-host { max-height: 50vh; overflow: auto; }
                #trace-view { max-height: none; overflow: visible; grid-template-columns: 1fr; }
                .trace-panels { flex-direction: column; flex: none; overflow: visible; }
                .trace-panels > *, .trace-panels > :nth-child(even), .trace-panels > .trace-step:not([open]) { flex: none; width: 100%; }
                .trace-step pre { max-height: 55vh; }
            }
        </style>
        '''
    }
}