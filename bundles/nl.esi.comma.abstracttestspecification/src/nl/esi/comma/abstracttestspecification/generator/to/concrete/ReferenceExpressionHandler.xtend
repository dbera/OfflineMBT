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
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.lsat.common.xtend.Queries.*

class ReferenceExpressionHandler {

    def resolveStepReferenceExpressions(RunStep rstep) {
        debug(" [INFO] Resolving references for Run Step: " + rstep.name)
        val Map<String, List<String>> mapLHStoRHS = newLinkedHashMap

        for (cstep : rstep.referencedComposeSteps) {
            debug(" [INFO] > Referenced Compose Step: " + cstep.name)
            // Run block input data structure = Concrete TSpec step input data structure
            cstep.evaluateReferenceConstrains('''«rstep.name.split("_").get(0)»Input.''', mapLHStoRHS)

            for (nestedcstep : #[cstep].closure[referencedComposeSteps]) {
                debug(" [INFO] --> Nested Compose Step: " + nestedcstep.name)
                // Run block input data structure = Concrete TSpec step input data structure
                nestedcstep.evaluateReferenceConstrains('''step_«nestedcstep.name».output.''', mapLHStoRHS)
            }
        }

        debug(" [INFO] Expressions Before Rewrite: ")
        mapLHStoRHS.forEach[k, l | l.forEach[v | debug('''    > K: «k» > V: «v»''')]]

        val appliedKeys = rewriteExpressions(mapLHStoRHS)

        debug(" [INFO] Expressions After Rewrite: ")
        mapLHStoRHS.forEach[k, l | l.forEach[v | debug('''    «IF appliedKeys.contains(k)»*«ELSE»>«ENDIF» K: «k» > V: «v»''')]]

        // remove expressions that were used to overwrite other expressions
        mapLHStoRHS.keySet.removeAll(appliedKeys)

        return mapLHStoRHS
    }

    private def debug(String message) {
        // println(message)
    }

    private def getReferencedComposeSteps(AbstractStep step) {
        return step.stepRef.map[refStep].filter(ComposeStep)
    }

    private def void evaluateReferenceConstrains(ComposeStep cstep, String fieldPrefix, Map<String, List<String>> mapLHStoRHS) {
        // Iterate all record field assignments of all constraints
        for (action : cstep.refs.flatMap[ce].flatMap[act.actions.filter(RecordFieldAssignmentAction)]) {
            // Run block input data structure = Concrete TSpec step input data structure
            val field = fieldPrefix + EcoreUtil3.serialize(action.fieldAccess)

            // action.exp is a reference to the original pspec, hence we should not update that expression!
            // However, serialization requires the expression to be contained by an XtextResource
            // So, we store the original expression, before copying and evaluating it. Then we serialize
            // the evaluated expression and restore the original expression.
            val orgExp = action.exp
            action.exp = new ExpressionEvaluator().evaluate(action.exp.copy) [ variable |
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

    private def Set<String> rewriteExpressions(Map<String, List<String>> mapLHStoRHS) {
        val appliedKeys = newHashSet
        for (expressions : mapLHStoRHS.values) {
            for (var i = 0; i < expressions.size; i++) {
                val expression = expressions.get(i)
                for (key : mapLHStoRHS.keySet.filter[k|expression.contains(k)]) {
                    // RHS expression should be rewritten as it references a variable
                    val varRHS = mapLHStoRHS.get(key)
                    appliedKeys += key

                    // Replace the (variable in the) expression with all expressions that are assigned to the variable
                    expressions.remove(i)
                    expressions.addAll(i, varRHS.map[varExp|expression.replace(key, varExp)])
                    // The inserted expressions might refer to other variables in their turn,
                    // so make sure to re-evalue them again
                    i--
                }
            }
        }
        return appliedKeys
    }
}