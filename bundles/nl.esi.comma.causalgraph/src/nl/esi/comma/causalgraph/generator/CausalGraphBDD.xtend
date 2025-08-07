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
package nl.esi.comma.causalgraph.generator

import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.List
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.ControlFlowEdge
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.ScenarioDecl
import nl.esi.comma.causalgraph.causalGraph.StepType
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import org.eclipse.xtext.generator.IFileSystemAccess2

class CausalGraphBDD {
    def generateBDD(CausalGraph prod, IFileSystemAccess2 fsa) {
        // Causal Graph Handling
        generateFeatures(prod, fsa)
        generateStepDefinitions(prod, fsa)
    }

    /**
     * Entry: only process BDDUnifiedCausalGraph (type BDDUCG)
     */
    def generateStepDefinitions(CausalGraph cg, IFileSystemAccess2 fsa) {
        if (cg.type == GraphType.BDDUCG)
            toStepDefinitions(cg, fsa)
    }

    /**
     * Entry: only process BDDUnifiedCausalGraph (type BDDUCG)
     */
    def generateFeatures(CausalGraph cg, IFileSystemAccess2 fsa) {
        if (cg.type == GraphType.BDDUCG)
            toFeatureFile(cg, fsa)
    }

    /**
     * Groups scenarios by their full step sequence.
     * Emits a Scenario Outline for any group >1, or separate Scenario blocks otherwise.
     */
    def toFeatureFile(CausalGraph cg, IFileSystemAccess2 fsa) {
        // 1) collect scenario names
        val scenarios = cg.scenarios.map[s|s]
        // 2) build (scenarioName -> stepPath) pairs
        val pathEntries = scenarios.map [ sc |
            Pair.of(sc, buildPath(cg, sc))
        ]
        // 3) convert to Map<String, List<String>> using key/value mappers
        val pathMap = IterableExtensions.toMap(
            pathEntries,
            [entry|entry.key],
            [entry|entry.value]
        )
        val groups = pathMap.entrySet.groupBy[e|e.value]

        val content = new StringBuilder

        content.append("Feature: ").append(cg.name).append("\n\n")

        groups.values.forEach [ group |
            var scs = group.map[e|e.key]
            val names = group.map[e|e.key.name]
            val path = group.head.value


            var reqs = new ArrayList<String>
            for (ScenarioDecl sc : scs) {
                for (rq : sc.getRequirements()) {
                    reqs.add(rq.getName())

                }
            }
            reqs.toSet().forEach[req|content.append("@").append(req).append("\n")]

            if (names.size > 1) {
                emitScenarioOutline(cg, content, cg.name, path, names)
            } else {
                emitSingleScenario(content, cg, names.head)
            }
            content.append("\n")
        ]

        fsa.generateFile(cg.name + ".feature", content.toString)
    }

    /**
     * Walks the control-flow chain for a scenario and builds a list of step lines.
     */
    protected def List<String> buildPath(CausalGraph cg, ScenarioDecl sc) {
        val steps = new ArrayList<String>
        var stepNum = 1
        var node = findNodeFor(cg, sc.name, stepNum)
        var prevKw = ""
        while (node !== null) {
            // capture current step number for closure
            val currentStep = stepNum
            val step = node.steps.findFirst [ s |
                s.getScenario() == sc && s.stepNumber == currentStep
            ]
            if (step !== null) {
                val kw = node.stepType.getName().toLowerCase.toFirstUpper
                val keyword = if(kw == prevKw) "And" else kw
                prevKw = keyword
                val pretty = node.stepName.replaceAll("\\(.*?\\)", "").replaceAll("([a-z0-9])([A-Z])", "$1 $2").
                    replaceAll("_", " ").trim

                // arguments
                val args = step.stepArguments.filter[a|a instanceof AssignmentAction].map [ a |
                    val aa = a as AssignmentAction
                    "<" + aa.getAssignment().getName() + ">"
                ]
                if (!args.empty)
                    steps.add(keyword + " " + pretty + " with " + args.join(" and "))
                else
                    steps.add(keyword + " " + pretty)

                stepNum++
                node = findNextNode(cg, node, sc.name, stepNum)
            }
        }
        steps
    }

    /**
     * Emits a Scenario Outline for scenarios sharing a common path,
     * parameterizing all AssignmentAction args per scenario.
     */
    protected def emitScenarioOutline(CausalGraph cg, StringBuilder content, String featureName, List<String> path,
        List<String> scenarios) {
        content.append("Scenario Outline:").append(scenarios.join(",")).append("\n")
        // Print the common steps as template lines
        for (line : path) {
            content.append("  ").append(line).append("\n")
        }

        // Gather *all* parameter names used by these scenarios
        val paramNames = scenarios.flatMap [ sc |
            cg.nodes.flatMap [ n |
                n.steps.findFirst[s|s.getScenario().getName() == sc]?.stepArguments.filter[a|a instanceof AssignmentAction].map [ a |
                    (a as AssignmentAction).getAssignment().getName()
                ]
            ]
        ].toSet.toList

        // Emit Examples header
        content.append("\nExamples:\n| scenario | ").append(paramNames.join(" | ")).append(" |\n")

        // Emit one row per scenario, listing each parameter’s value
        for (sc : scenarios) {
            // Build a map from param → value for this scenario
            val argMap = new LinkedHashMap<String, String>
            for (n : cg.nodes) {
                for (step : n.steps) {
                    if (step.getScenario().name == sc) {
                        for (a : step.stepArguments.filter[arg|arg instanceof AssignmentAction].map [ arg |
                            arg as AssignmentAction
                        ]) {
                            argMap.put(a.getAssignment().getName(), renderExpressionValue(a.exp))
                        }
                    }
                }
            }
            // Print the row
            content.append("| ").append(sc)
            for (p : paramNames) {
                content.append(" | ").append(argMap.get(p) ?: "")
            }
            content.append(" |\n")
        }
    }

    /**
     * Emits a single Scenario block for an individual scenario.
     */
    protected def emitSingleScenario(StringBuilder content, CausalGraph cg, String sc) {
        content.append("Scenario: ").append(sc).append("\n")
        var num = 1
        var node = findNodeFor(cg, sc, num)
        var prevKw = ""
        while (node !== null) {
            val currentStep = num
            val step = node.steps.findFirst[s|s.getScenario().name == sc && s.stepNumber == currentStep]
            if (node.stepType != StepType.GIVEN) {
                val kw = node.stepType.getName().toLowerCase.toFirstUpper
                val keyword = if(kw == prevKw) "And" else kw
                prevKw = keyword
                val pretty = node.stepName.replaceAll("\\(.*?\\)", "").replaceAll("([a-z0-9])([A-Z])", "$1 $2").
                    replaceAll("_", " ").trim
                content.append("  ").append(keyword).append(" ").append(pretty)
                // arguments
                val args = step.stepArguments.filter[a|a instanceof AssignmentAction].map [ a |
                    val aa = a as AssignmentAction
                    renderExpressionValue(aa.exp)
                ]
                if(!args.empty) content.append(" with ").append(args.join(" and "))
                content.append("\n")
            }
            num++
            node = findNextNode(cg, node, sc, num)
        }
    }

    protected def toStepDefinitions(CausalGraph cg, IFileSystemAccess2 fsa) {
        val sb = new StringBuilder
        sb.append("using TechTalk.SpecFlow;\n")
        sb.append("using Xunit;\n\n")
        sb.append("namespace GeneratedSteps\n{");
        sb.append("\n  [Binding]\n")
        sb.append("  public class ").append(cg.name).append("Steps\n")
        sb.append("  {\n")

        // Collect unique nodes used in any scenario
        val uniqueNodes = cg.nodes.filter [ n |
            cg.scenarios.exists [ sc |
                n.steps.exists[t|t.scenario.name == sc.name]
            ]
        ]

        for (node : uniqueNodes) {
            val keyword = node.stepType.getName() // Given, When, Then
            var regexPattern = node.stepName
            val methodName = regexPattern.replaceAll('\\(.*?\\)', '')

            // Build the regex pattern: replace each (type name) in original stepName
            for (param : node.stepParameters) {
                // Determine literal placeholder in step text
                val placeholder = "(" + param.getType().getType().getName() + " " + param.name + ")"
                // Select capture group based on type
                val group = if (param.getType().getType().getName().equalsIgnoreCase("string"))
                        '"(.*)"'
                    else
                        '(.*)'
                // Replace placeholder with regex group
                regexPattern = regexPattern.replace(placeholder, group)
            }

            regexPattern = regexPattern.replaceAll("([a-z0-9])([A-Z])", "$1 $2")
            sb.append("    [").append(keyword).append("(@\"^").append(regexPattern).append("$\")]").append("\n");

            // parameters list
            val params = new ArrayList<String>
            for (param : node.stepParameters) {
                val rawType = param.getType().getType().getName
                val mappedType = if(rawType == "real") "double" else rawType
                params.add(mappedType + " " + param.name)
            }

            sb.append("    public void ").append(methodName).append("(").append(params.join(", ")).append(")\n")
            sb.append("    {\n")
            sb.append("        Console.WriteLine(\"").append(methodName).append(" executed\");\n");
            sb.append("    }\n\n")
        }

        sb.append("  }\n")
        sb.append("}\n")

        fsa.generateFile(cg.name + "Steps.cs", sb.toString)
    }

    protected def escapeRegex(String text) {
        text.replaceAll("([\\^\\$\\.\\*\\+\\?\\(\\)\\[\\]\\{\\}\\|])", "\\\\$1")
    }

    /**
     * Finds the node that contains the given scenario at given step number.
     */
    protected def findNodeFor(CausalGraph cg, String scenario, int stepNum) {
        cg.nodes.findFirst [ n |
            n.steps.exists [ s |
                s.scenario.name == scenario && s.stepNumber == stepNum
            ]
        ]
    }

    /**
     * Finds the next node in control-flow for the given scenario and next step.
     */
    protected def findNextNode(CausalGraph cg, Node currentNode, String scenario, int nextStep) {
        val edge = cg.edges.filter[e|e instanceof ControlFlowEdge && (e as ControlFlowEdge).source == currentNode].
            findFirst [ e |
                (e as ControlFlowEdge).target.steps.exists [ s |
                    s.scenario.name == scenario && s.stepNumber == nextStep
                ]
            ] as ControlFlowEdge
        return if(edge !== null) (edge as ControlFlowEdge).target else null
    }

    protected def String renderExpressionValue(Expression expr) {
        if (expr instanceof ExpressionConstantBool) {
            return (expr as ExpressionConstantBool).value.toString
        } else if (expr instanceof ExpressionConstantInt) {
            return (expr as ExpressionConstantInt).value.toString
        } else if (expr instanceof ExpressionConstantReal) {
            return (expr as ExpressionConstantReal).value.toString
        } else if (expr instanceof ExpressionConstantString) {
            val s = expr as ExpressionConstantString
            return '"' + s.value + '"'
        }
        // fallback for other expression types
        expr.toString
    }
}
