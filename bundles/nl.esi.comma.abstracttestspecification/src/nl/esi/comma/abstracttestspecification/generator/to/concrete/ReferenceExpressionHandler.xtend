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
package nl.esi.comma.abstracttestspecification.generator.to.concrete

import java.util.List
import java.util.Map
import java.util.Set
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ComposeStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.evaluation.ExpressionEvaluator
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.types.types.RecordFieldKind
import nl.esi.xtext.common.lang.utilities.EcoreUtil3

import static extension nl.esi.comma.assertthat.utilities.AssertThatUtilities.*
import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.lsat.common.xtend.Queries.*

class ReferenceExpressionHandler {
    
    def resolveStepReferenceExpressions(RunStep rstep) {
        debug(" [INFO] Resolving references for Run Step: " + rstep.name)
        val Map<String, List<String>> mapLHStoRHS = newLinkedHashMap
        val Set<String> nestedFieldPrefixes = newHashSet

        for (cstep : rstep.referencedComposeSteps) {
            debug(" [INFO] > Referenced Compose Step: " + cstep.name)
            // Run block input data structure = Concrete TSpec step input data structure
            cstep.evaluateReferenceConstrains('''«rstep.name.split("_").get(0)»Input.''', mapLHStoRHS)

            for (nestedcstep : #[cstep].closure[referencedComposeSteps]) {
                debug(" [INFO] --> Nested Compose Step: " + nestedcstep.name)
                // Run block input data structure = Concrete TSpec step input data structure
                val fieldPrefix = '''step_«nestedcstep.name».output.'''
                nestedFieldPrefixes += fieldPrefix
                nestedcstep.evaluateReferenceConstrains(fieldPrefix, mapLHStoRHS)
            }
        }

        debug(" [INFO] Expressions Before Rewrite: ")
        mapLHStoRHS.forEach[k, l | l.forEach[v | debug('''    > K: «k» > V: «v»''')]]

        rewriteVariableReferences(mapLHStoRHS)

        debug(" [INFO] Expressions After Rewrite: ")
        mapLHStoRHS.forEach[k, l | l.forEach[v | debug('''    > K: «k» > V: «v»''')]]

        // remove the fields of the nested compose steps as they are not an input of this run step,
        // and were only used for rewriting the RHS expressions
        mapLHStoRHS.keySet.removeIf(field | nestedFieldPrefixes.exists[ prefix | field.startsWith(prefix)])

        return mapLHStoRHS
    }

    private def debug(String message) {
        // println(message)
    }

    private def getReferencedComposeSteps(AbstractStep step) {
        return step.stepRef.map[refStep].filter(ComposeStep)
    }

    private def void evaluateReferenceConstrains(ComposeStep cstep, String fieldPrefix, Map<String, List<String>> mapLHStoRHS) {
         val expressionEvaluator = EcoreUtil3.getService(cstep, ExpressionEvaluator)

        // Iterate all record field assignments of all constraints
        for (action : cstep.refs.flatMap[ce].flatMap[act.actions.filter(RecordFieldAssignmentAction)]) {
            // Run block input data structure = Concrete TSpec step input data structure
            val field = fieldPrefix + EcoreUtil3.serialize(action.fieldAccess)

            // action.exp is a reference to the original pspec, hence we should not update that expression!
            // However, serialization requires the expression to be contained by an XtextResource
            // So, we store the original expression, before copying and evaluating it. Then we serialize
            // the evaluated expression and restore the original expression.
            val orgExp = action.exp
            action.exp = expressionEvaluator.evaluate(action.exp.copy) [ variable |
                cstep.input.findFirst[name == variable]?.jsonvals.toExpression(variable.type.typeObject, self) [
                    // Only consider concrete values as we're evaluating symbolic expressions here
                    kind == RecordFieldKind::CONCRETE
                ]
            ]
            val value = action.exp.serialize [ obj |
                if (obj instanceof ExpressionVariable) {
                    val vname = obj.variable.name
                    val stepRef = cstep.stepRef.findFirst[refData.exists[name == vname]]
                    if (stepRef !== null) {
                        return '''step_«stepRef.refStep.name».output.«vname»'''
                    }
                }
            ]
            action.exp = orgExp

            mapLHStoRHS.computeIfAbsent(field)[newArrayList] += value
        }
    }

    private def void rewriteVariableReferences(Map<String, List<String>> mapLHStoRHS) {
        for (expressions : mapLHStoRHS.values) {
            for (var i = 0; i < expressions.size; i++) {
                val expression = expressions.get(i)
                val variableReference = mapLHStoRHS.keySet.findFirst[k|expression.contains(k)]
                if (variableReference !== null) {
                    // RHS expression should be rewritten as it references a variable
                    val replacements = mapLHStoRHS.get(variableReference)
                    // Replace the (variable in the) expression with all expressions that are assigned to the variable
                    expressions.remove(i)
                    expressions.addAll(i, replacements.map[exp|expression.replace(variableReference, exp)])
                    // The inserted expressions might refer to other variables in their turn,
                    // so make sure to re-evalue them again
                    i--
                }
            }
        }
    }
}