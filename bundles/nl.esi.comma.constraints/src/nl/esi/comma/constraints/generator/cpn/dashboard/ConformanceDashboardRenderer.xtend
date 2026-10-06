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
            <title>Conformance</title>
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
                .trace-step .step-id,
                .trace-step .step-type {
                    display: block;
                    overflow-wrap: anywhere;
                }
                .trace-step .step-id { font-weight: 600; }
                .trace-step .step-type { color: #5c696d; font-size: 12px; }
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
                .constraint-entry > button { margin: 0; }
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
                    white-space: pre-wrap;
                    font: 12px/1.5 Consolas, monospace;
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
                            <h2>Not Conforming</h2>
                            <div id="failed"></div>
                        </section>
                        <section>
                            <h2>Accepted</h2>
                            <div id="accepted"></div>
                        </section>
                    </nav>
                    <section id="detail" aria-live="polite">
                        <p class="muted">Select a constraint.</p>
                    </section>
                </aside>
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
                let contexts = [];
                let contextIndex = -1;

                function parseTrace(text) {
                    const lines = text.split("\n");
                    const preamble = [];
                    const steps = [];
                    const trailer = [];
                    let current = null;
                    let pastSteps = false;

                    function finishCurrentStep() {
                        if (!current) return;
                        steps.push({
                            id: current.id,
                            type: current.type,
                            kind: current.kind,
                            content: current.lines.slice(2).join("\n")
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

                function diagnosticTraceData(result) {
                    const roles = new Map();
                    const contextsByFocus = new Map();

                    function addRole(id, role) {
                        if (!id) return;
                        if (!roles.has(id)) roles.set(id, new Set());
                        roles.get(id).add(role);
                    }

                    function contextFor(id) {
                        if (!contextsByFocus.has(id)) {
                            contextsByFocus.set(id, {
                                focusId: id,
                                stepIds: new Set([id])
                            });
                        }
                        return contextsByFocus.get(id);
                    }

                    function attachToNearestActivation(id, role, activationIds) {
                        addRole(id, role);
                        if (!activationIds.length) {
                            contextFor(id);
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
                            contextFor(nearestActivation.id).stepIds.add(id);
                        } else {
                            contextFor(id);
                        }
                    }

                    for (const diagnostic of result.diagnostics || []) {
                        const activationIds =
                            diagnostic.activationEvent?.stepIds || [];
                        for (const id of activationIds) {
                            addRole(id, "activation");
                            contextFor(id);
                        }

                        for (const [eventName, role] of [
                            ["event", "event"],
                            ["targetEvent", "target"],
                            ["blockerEvent", "blocker"]
                        ]) {
                            for (const id of diagnostic[eventName]?.stepIds || []) {
                                attachToNearestActivation(id, role, activationIds);
                            }
                        }

                        if (!activationIds.length) {
                            for (const id of diagnostic.event?.stepIds || []) {
                                addRole(id, "event");
                                contextFor(id);
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
                                addRole(boundaryStep.id, "event");
                                contextFor(boundaryStep.id);
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
                                    addRole(relatedStep.id, "target");
                                    contextFor(activationId).stepIds.add(relatedStep.id);
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

                function updateContextControls() {
                    const hasTargets = contexts.length > 0;
                    document.querySelector("#previous-context").disabled =
                        !hasTargets || contextIndex <= 0;
                    document.querySelector("#next-context").disabled =
                        !hasTargets || contextIndex >= contexts.length - 1;
                    document.querySelector("#context-position").textContent =
                        hasTargets
                            ? (contextIndex + 1) + " of " + contexts.length
                            : "No matching steps";
                }

                function renderTrace() {
                    traceView.replaceChildren();

                    const focusedContext = contexts[contextIndex];
                    const focusedId = focusedContext?.focusId;
                    let focusedElement = null;

                    function ensureStepBody(details, step) {
                        if (details.dataset.bodyRendered === "true") return;
                        const content = document.createElement("pre");
                        content.textContent = step.content;
                        details.append(content);
                        details.dataset.bodyRendered = "true";
                    }

                    for (const step of trace.steps) {
                        const details = document.createElement("details");
                        const inContext =
                            focusedContext?.stepIds.has(step.id) || false;
                        const roles = inContext
                            ? selectedTraceRoles.get(step.id) || new Set()
                            : new Set();
                        const highlighted = inContext && selectedTraceIds.has(step.id);
                        const focused = step.id === focusedId;

                        details.className = "trace-step";
                        details.classList.toggle("highlighted", highlighted);
                        details.classList.toggle("context-focus", focused);
                        for (const role of roles) {
                            details.classList.add("role-" + role);
                        }
                        const summaryLine = document.createElement("summary");
                        const stepId = document.createElement("span");
                        stepId.className = "step-id";
                        stepId.textContent = "step-id " + step.id;
                        const stepType = document.createElement("span");
                        stepType.className = "step-type";
                        stepType.textContent =
                            (step.kind === "assertion"
                                ? "assertion-type "
                                : "step-type ") + step.type;
                        summaryLine.append(stepId, stepType);

                        details.append(summaryLine);
                        details.addEventListener("toggle", () => {
                            if (details.open) ensureStepBody(details, step);
                        });
                        details.open = false;
                        traceView.append(details);

                        if (focused) focusedElement = details;
                    }

                    focusedElement?.scrollIntoView({ block: "center" });
                }

                function moveContext(offset) {
                    if (!contexts.length) return;

                    contextIndex = Math.max(
                        0,
                        Math.min(
                            contexts.length - 1,
                            contextIndex + offset
                        )
                    );
                    updateContextControls();
                    renderTrace();
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

                function showResult(result) {
                    detail.replaceChildren();

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
                            diagnostic.message || diagnostic.kind
                        );
                        message.append(narrative);

                        for (const [eventName, role, label] of [
                            ["activationEvent", "activation", "Activation"],
                            ["targetEvent", "target", "Target"],
                            ["blockerEvent", "blocker", "Blocker"],
                            ["event", "event", "Event"]
                        ]) {
                            const eventInfo = diagnostic[eventName];
                            if (!eventInfo) continue;

                            const eventDetail = document.createElement("span");
                            eventDetail.className =
                                "diagnostic-event role-" + role;
                            const parts = [label + ": " + (eventInfo.name || "")];
                            if (eventInfo.whereConcrete) {
                                parts.push("where-concrete " + eventInfo.whereConcrete);
                            }
                            if (eventInfo.correlationBinding) {
                                parts.push("with " + eventInfo.correlationBinding);
                            }
                            if (eventInfo.whereCorrelation) {
                                parts.push("where-correlation " + eventInfo.whereCorrelation);
                            }
                            if (eventInfo.stepIds?.length) {
                                parts.push("steps: " + eventInfo.stepIds.join(", "));
                            }
                            eventDetail.textContent = parts.join("\n");
                            message.append(eventDetail);
                        }
                        detail.append(message);
                    }

                    const traceData = diagnosticTraceData(result);
                    selectedTraceRoles = traceData.roles;
                    selectedTraceIds = new Set(selectedTraceRoles.keys());
                    contexts = traceData.contexts;
                    contextIndex = contexts.length ? 0 : -1;

                    updateContextControls();
                    renderTrace();
                }

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
                            declarationText += "\n" + text;
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
                                definition.append(badge);
                                if (declarationText) {
                                    const declaration = document.createElement("div");
                                    declaration.className = "constraint-declaration";
                                    declaration.textContent = declarationText;
                                    definition.append(declaration);
                                    declarationText = "";
                                }
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
                        } else if (text.startsWith("with ")) {
                            label = "Correlation binding";
                        } else if (text.startsWith("must")) {
                            label = "Requirement";
                            currentRole = "";
                        } else {
                            label = "";
                        }

                        const line = document.createElement("div");
                        line.className = "constraint-line";
                        if (currentRole) line.classList.add("role-" + currentRole);
                        const lineLabel = document.createElement("span");
                        lineLabel.className = "constraint-line-label";
                        lineLabel.textContent = label;
                        line.append(lineLabel);
                        const lineText = document.createElement("span");
                        lineText.textContent = text;
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
                        button.className = accepted ? "" : "failed";
                        button.type = "button";
                        button.innerHTML = "<strong></strong><span></span>";
                        button.querySelector("strong").textContent =
                            constraintName;
                        button.querySelector("span").textContent =
                            result.templateType || "";
                        button.addEventListener("click", () => {
                            document.querySelectorAll("button").forEach(item =>
                                item.setAttribute("aria-current", "false")
                            );
                            button.setAttribute("aria-current", "true");
                            showResult(result);
                        });

                        const entry = document.createElement("div");
                        entry.className = "constraint-entry";
                        entry.append(button);

                        const sourceDetails = document.createElement("details");
                        sourceDetails.className = "constraint-source";
                        const sourceSummary = document.createElement("summary");
                        sourceSummary.textContent = "Show constraint definition";
                        sourceDetails.append(sourceSummary);
                        sourceDetails.addEventListener("toggle", () => {
                            if (!sourceDetails.open ||
                                sourceDetails.dataset.rendered === "true") return;

                            const constraintDefinition =
                                extractConstraintDefinition(constraintName);
                            if (constraintDefinition) {
                                sourceDetails.append(
                                    renderConstraintDefinition(constraintDefinition)
                                );
                            } else {
                                const sourceContent = document.createElement("pre");
                                sourceContent.textContent =
                                    "Constraint definition not found in source.";
                                sourceDetails.append(sourceContent);
                            }
                            sourceDetails.dataset.rendered = "true";
                        });
                        entry.append(sourceDetails);
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
                        document.querySelector("#failed .constraint-entry > button");
                    if (firstFailedButton) {
                        firstFailedButton.setAttribute("aria-current", "true");
                    }
                    showResult(failed[0]);
                }
            </script>
        </body>
        </html>
        '''
    }
}