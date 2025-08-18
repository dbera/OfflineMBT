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
import nl.esi.comma.causalgraph.causalGraph.AliasTypeDecl
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.ControlFlowEdge
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.LanguageBody
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.ScenarioDecl
import nl.esi.comma.causalgraph.causalGraph.ScenarioStep
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import org.eclipse.xtext.generator.IFileSystemAccess2

import static extension nl.esi.comma.causalgraph.utilities.CausalGraphQueries.*

class CausalGraphBDD {
    def generateBDD(CausalGraph prod, IFileSystemAccess2 fsa) {
        // Causal Graph Handling
        generateFeatures(prod, fsa)
        generateStepDefinitions(prod, fsa)
        generateCppSteps(prod, fsa)
    }

    /**
     * Entry: only process BDDUnifiedCausalGraph (type BDDUCG)
     */
    def generateStepDefinitions(CausalGraph cg, IFileSystemAccess2 fsa) {
        if (cg.type == GraphType.BDDUCG)
            toCSharpStepDefinitions(cg, fsa)
    }

    /**
     * Entry: only process BDDUnifiedCausalGraph (type BDDUCG)
     */
    def generateFeatures(CausalGraph cg, IFileSystemAccess2 fsa) {
        if (cg.type == GraphType.BDDUCG)
            toFeatureFile(cg, fsa)
    }

    def generateCppSteps(CausalGraph cg, IFileSystemAccess2 fsa) {
        if (cg.type == GraphType.BDDUCG) {
            toCPPStepDefinitionsHeaderFile(cg, fsa)
            toCPPStepDefinitionsCPPFile(cg, fsa)
            toCPPTestValidationCode(cg, fsa)
        }
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
                var stepName = stepNameProcessing(node.stepName)

                // arguments
                val args = step.stepArguments.filter[a|a instanceof AssignmentAction].map [ a |
                    val aa = a as AssignmentAction
                    "<" + aa.getAssignment().getName() + ">"
                ]
                if (!args.empty)
                    steps.add(keyword + " " + stepName + " with " + args.join(" and "))
                else
                    steps.add(keyword + " " + stepName)

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

        // Gather all parameter names used by these scenarios
        val paramNames = scenarios.flatMap [ sc |
            cg.nodes.flatMap [ n |
                // find the step (never null)
                val step = n.steps.findFirst[s|s.scenario.name == sc]
                // if stepArguments is null, fall back to empty list
                val args = step?.stepArguments ?: #[]
                args.filter[a|a instanceof AssignmentAction].map[a|(a as AssignmentAction).getAssignment().getName()]
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

            val kw = node.stepType.getName().toLowerCase.toFirstUpper
            val keyword = if(kw == prevKw) "And" else kw
            prevKw = keyword
            var stepName = stepNameProcessing(node.stepName)
            content.append("  ").append(keyword).append(" ").append(stepName)

            val argMap = getParaArgMap(node, step)

            if (!argMap.empty) {
                content.append(" with ").append(argMap.values.join(" and ")).append("\n")
            } else {
                content.append("\n")
            }

            num++
            node = findNextNode(cg, node, sc, num)
        }
    }

    def getParaArgMap(Node node, ScenarioStep step) {
        // 1) Collect parameter names (in order)
        val parameterNames = node.stepParameters.map[p|p.name].toList

        // 2) Gather only AssignmentAction arguments (null-safe on stepArguments)
        val assignmentArgs = (step?.stepArguments ?: #[]).filter[a|a instanceof AssignmentAction].map [ a |
            a as AssignmentAction
        ]
        // 3) Build an ordered argMap aligned to parameterNames
        val argMap = new LinkedHashMap<String, String>
        for (pName : parameterNames) {
            val match = assignmentArgs.findFirst[aa|argName(aa) == pName]
            argMap.put(pName, if(match !== null) renderExpressionValue(match.exp) else "")
        }
        argMap
    }

    // Helper to get the argument's name regardless of model variant
    def String argName(AssignmentAction aa) {
        if(aa.assignment !== null) aa.assignment.name else ""
    }

    protected def toCSharpStepDefinitions(CausalGraph cg, IFileSystemAccess2 fsa) {
        val sb = new StringBuilder
//        sb.append("using TechTalk.SpecFlow;\n")
//        sb.append("using Xunit;\n\n")
        sb.append("using Reqnroll;\n")
        sb.append("using System;\n")
        sb.append("using Xunit;\n")

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
            // var regexPattern = node.stepName
            var stepName = stepNameProcessing(node.stepName)
            val methodName = stepName.replaceAll(" ", "")

            var paraGroup = new ArrayList<String>;
            // Replace each (type name) with the appropriate capture group
            for (param : node.stepParameters) {
                val typeName = param.type.type.name
                
                // Select capture group based on type (strings are quoted)
                val group = if (typeName.equalsIgnoreCase("string")) "\"(.*)\"" else "(.*)"
                paraGroup.add(group)
            }

            if (!paraGroup.empty)
                sb.append("    [").append(keyword.toLowerCase.toFirstUpper).append("(@\"^").append(stepName).append(
                    " with ").append(paraGroup.join(" and ")).append("$\")]").append("\n")
            else
                sb.append("    [").append(keyword.toLowerCase.toFirstUpper).append("(@\"^").append(stepName).append(
                    "$\")]").append("\n")

            // Parameters list
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

    protected def getUniqueNodes(CausalGraph cg) {
        // Collect unique nodes used in any scenario
        val uniqueNodes = cg.nodes.filter [ n |
            cg.scenarios.exists [ sc |
                n.steps.exists[t|t.scenario.name == sc.name]
            ]
        ]
        return uniqueNodes
    }

    protected def stepNameProcessing(String rawStepName) {
        return rawStepName.replaceAll("\\([^)]*\\)", "").replaceAll("([a-z0-9])([A-Z])", "$1 $2").replaceAll("_", " ").
            trim
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

    def toCPPStepDefinitionsHeaderFile(CausalGraph cg, IFileSystemAccess2 fsa) {
        val sb = new StringBuilder
        // Includes
        if (!cg.header.empty) {
            sb.append(cg.header.trim).append("\n")
        }
        sb.append("\n")
        sb.append("class " + cg.name + "{\n")
        sb.append("public:\n")

        // Global variables
        for (variable : cg.getVariables()) {
            val variableType = variable.getType().getType()
            var variableTypeName = ""
            if (variableType instanceof AliasTypeDecl) {
                variableTypeName = variableType.getAlias()
            } else {
                variableTypeName = variableType.getName()
            }

            val cppType = if(variableTypeName.equalsIgnoreCase("real")) "float" else variableTypeName
            sb.append(cppType).append(" ").append(variable.name)
            val match = cg.getAssignments().findFirst[aa|argName(aa) == variable.name]
            if (match !== null) {
                sb.append(" = " + renderExpressionValue(match.exp))
            }
            sb.append(";\n")
        }

        // Collect unique nodes used in any scenario
        val uniqueNodes = getUniqueNodes(cg)

        // Step definitions
        for (node : uniqueNodes) {
            val fnName = node.stepName.replaceAll("\\(.*?\\)", "").replaceAll("[^A-Za-z0-9]", "_")
            val params = node.stepParameters.map [ p |
                val rawType = p.getType().getType().getName
                val cppType = if(rawType.equalsIgnoreCase("real")) "float" else rawType
                cppType + " " + p.name
            ].join(", ")
            sb.append("void ").append(fnName).append("(").append(params).append(");")
            sb.append("\n")

        }

        sb.append("};\n\n")

        fsa.generateFile(cg.name + "Steps.h", sb.toString)
    }

    def toCPPStepDefinitionsCPPFile(CausalGraph cg, IFileSystemAccess2 fsa) {
        val sb = new StringBuilder
        // Includes
        if (!cg.header.isNullOrEmpty) {
            sb.append(cg.header.trim).append("\n")
        }
        sb.append("#include " + "\"" + cg.name + "Steps.h" + "\"" + "\n")
        sb.append("\n")

        // Collect unique nodes used in any scenario
        val uniqueNodes = getUniqueNodes(cg)

        // Step definitions
        for (node : uniqueNodes) {
            val fnName = node.stepName.replaceAll("\\(.*?\\)", "").replaceAll("[^A-Za-z0-9]", "_")
            val params = node.stepParameters.map [ p |
                val rawType = p.getType().getType().getName
                val cppType = if(rawType.equalsIgnoreCase("real")) "float" else rawType
                cppType + " " + p.name
            ].join(", ")
            sb.append("void ").append(cg.name + "::" + fnName).append("(").append(params).append(") {")
            sb.append("\n")
            // step body
            if (node.stepBody instanceof LanguageBody) {
                val body = (node.stepBody as LanguageBody).body
                // indent each line
                body.split("\r?\n").forEach [ line |
                    sb.append("    ").append(line).append("\n")
                ]
            }
            sb.append("}\n\n")
        }
        fsa.generateFile(cg.name + "Steps.cpp", sb.toString)
    }

    def toCPPTestValidationCode(CausalGraph cg, IFileSystemAccess2 fsa) {
        val sb = new StringBuilder
        // Includes
        sb.append("#include <gtest/gtest.h>")
        sb.append("#include " + "\"" + cg.name + "Steps.h" + "\"" + "\n")
        sb.append("\n")

        // Generate class stub
        var className = cg.name + "Test"
        sb.append("class " + className + ": public ::testing::Test {\n")
        sb.append("protected:\n")
        var instanceName = cg.name.toFirstLower;
        sb.append(cg.name + " " + instanceName + ";\n")
        sb.append("};\n\n")

        val scenarios = cg.scenarios.map[s|s]
        for (sc : scenarios) {
            sb.append("TEST_F(" + className + "," + sc.name + ")" + "{\n")
            var methodCalls = buildCPPFuncCallChain(cg, sc)
            for (mc : methodCalls) {
                sb.append(instanceName + "." + mc + ";\n")
            }
            sb.append("}\n\n")
        }
        fsa.generateFile(cg.name + "Test.cpp", sb.toString)
    }

    /**
     * Walks the control-flow chain for a scenario and builds a list of cpp function calls.
     */
    protected def List<String> buildCPPFuncCallChain(CausalGraph cg, ScenarioDecl sc) {
        val steps = new ArrayList<String>
        var stepNum = 1
        var node = findNodeFor(cg, sc.name, stepNum)
        while (node !== null) {
            // capture current step number for closure
            val currentStep = stepNum
            val step = node.steps.findFirst [ s |
                s.getScenario() == sc && s.stepNumber == currentStep
            ]
            if (step !== null) {
                var stepName = stepNameProcessing(node.stepName)
                val methodName = stepName.replaceAll(" ", "")

                val argMap = getParaArgMap(node, step)
                if (!argMap.empty)
                    steps.add(methodName + "(" + argMap.values.join(" , ") + ")")
                else
                    steps.add(methodName + "()")

                stepNum++
                node = findNextNode(cg, node, sc.name, stepNum)
            }
        }
        steps
    }

}
