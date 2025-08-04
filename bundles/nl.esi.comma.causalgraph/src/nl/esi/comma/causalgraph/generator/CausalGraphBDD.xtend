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
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.ControlFlowEdge
import nl.esi.comma.causalgraph.causalGraph.GraphType
import nl.esi.comma.causalgraph.causalGraph.Node
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

    protected def toFeatureFile(CausalGraph cg, IFileSystemAccess2 fsa) {
        // collect scenarios from graph
        val scenarios = cg.scenarios
        val content = new StringBuilder

        // Feature header
        content.append("Feature: ").append(cg.name).append("\n\n")

        // iterate each scenario
        for (sc : scenarios) {
            for (rq : sc.getRequirements()) {
                content.append("@").append(rq.getName()).append("\n")
            }
            content.append("Scenario: ").append(sc.name).append("\n")

            // find first node (step 1)
            var stepNum = 1
            var currentNode = findNodeFor(cg, sc.name, stepNum)

            var previousKeyword = ""
            while (currentNode !== null) {
                // find scenario step on this node
                val curr = stepNum
                val step = currentNode.tests.findFirst[s|s.name.name == sc.name && s.stepNumber == curr]

                // map enum to capitalized keyword
                val baseKeyword = currentNode.stepType.getName().toLowerCase.toFirstUpper
                // if same as previous, use "And"
                val keyword = if(baseKeyword == previousKeyword) "And" else baseKeyword
                previousKeyword = keyword

                // prepare stepName: strip parameters, insert spaces at camelCase boundaries, replace underscores, and trim
                val pretty = currentNode.stepName.replaceAll("\\(.*?\\)", "").replaceAll("([a-z0-9])([A-Z])", "$1 $2").
                    trim
                content.append("  ").append(keyword).append(" ").append(pretty)

                // append parameters for AssignmentAction args
                val assignmentArgs = step.stepArguments.filter[arg|arg instanceof AssignmentAction].map [ arg |
                    arg as AssignmentAction
                ]

                if (!assignmentArgs.empty) {
                    content.append(" ").append(assignmentArgs.map [ a |
                        renderExpressionValue(a.getExp())
                    ].join(" , "))

                }
                content.append("\n")

                // go to the next node for the next step of this scenario
                stepNum++
                currentNode = findNextNode(cg, currentNode, sc.name, stepNum)
            }
            content.append("\n")
        }

        // write file
        fsa.generateFile(cg.name + ".feature", content.toString)
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
                n.tests.exists[t|t.name.name == sc.name]
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
            for (param : node.stepParameters)
                params.add(param.getType().getType().getName() + ' ' + param.name)

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
            n.tests.exists [ s |
                s.name.name == scenario && s.stepNumber == stepNum
            ]
        ]
    }

    /**
     * Finds the next node in control-flow for the given scenario and next step.
     */
    protected def findNextNode(CausalGraph cg, Node currentNode, String scenario, int nextStep) {
        val edge = cg.edges.filter[e|e instanceof ControlFlowEdge && (e as ControlFlowEdge).source == currentNode].
            findFirst [ e |
                (e as ControlFlowEdge).target.tests.exists [ s |
                    s.name.name == scenario && s.stepNumber == nextStep
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
