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

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import nl.asml.matala.product.product.VarRef
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ComposeStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.evaluation.ExpressionEvaluator
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.types.types.RecordFieldKind
import nl.esi.comma.types.utilities.EcoreUtil3
import org.eclipse.xtend.lib.annotations.Data

import static extension nl.esi.comma.assertthat.utilities.AssertThatUtilities.*
import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.lsat.common.xtend.Queries.*
import java.util.LinkedHashSet

class ReferenceExpressionHandler
{
    /*
     * Support Interleaving of Compose and Run Steps. 
     * Q1 2025.  
     */
    // Updated DB 31.07.2025. Support chaining of compose steps with functions in expressions.
    def resolveStepReferenceExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps)
    {
        System.out.println(" [INFO] Resolving references for Run Step: " + rstep.name)
        val Map<String, List<String>> mapLHStoRHS = newLinkedHashMap
        // Find preceding Compose Step
        for(cstep : composeSteps) // at most one of a type
        {
            System.out.println(" [INFO] > Referenced Compose Step: " + cstep.name)
//            var refTxt = ''
            for(refcons : cstep.refs.flatMap[ce]) {
                var varRefName = (refcons.eContainer.eContainer as VarRef).ref.name
                for (action : refcons.act.actions.filter(RecordFieldAssignmentAction)) {
                    var constraint = _printRecord_(varRefName, rstep.name, cstep, action, true)
//                    refTxt += constraint.getText + "\n"
                    mapLHStoRHS.computeIfAbsent(constraint.lhs)[newArrayList] += constraint.rhs
                }
            }

//            if(!refTxt.isEmpty) System.out.println("\nLocal Constraints:\n" + refTxt)
            val nestedComposeSteps = #[cstep].closure[stepRef.map[refStep].filter(ComposeStep)]
            for(cs : nestedComposeSteps) {
                System.out.println(" [INFO] --> Nested Compose Step: " + cs.name)
//                refTxt = ''
                for(refcons : cs.refs.flatMap[ce]) {
                    var varRefName = (refcons.eContainer.eContainer as VarRef).ref.name
                    for (action : refcons.act.actions.filter(RecordFieldAssignmentAction)) {
                        var constraint = _printRecord_(varRefName, rstep.name, cs, action, false)
//                        refTxt += constraint.getText + "\n"
//                        if(!refTxt.isEmpty) System.out.println("\nRef Constraints:\n" + refTxt)
                        mapLHStoRHS.computeIfAbsent(constraint.lhs)[newArrayList] += constraint.rhs
                    }
                }
            }
//            if(!refTxt.isEmpty) System.out.println("\nRef Constraints:\n" + refTxt)
        }

        System.out.println(" [INFO] Expressions Before Rewrite: ")
        for(k : mapLHStoRHS.keySet) {
            for(v : mapLHStoRHS.get(k))
            System.out.println("    > K: " + k + " > V: " + v)
        }

        var rewriteOutput = rewriteExpressions(mapLHStoRHS)
        var rewriteFlag = rewriteOutput.atleastOneExpRewritten
        val refAppliedKeys = rewriteOutput.refAppliedKeys

        while(rewriteFlag) {
            rewriteOutput = rewriteExpressions(rewriteOutput.mapLHStoRHS)
            rewriteFlag = rewriteOutput.atleastOneExpRewritten
            refAppliedKeys += rewriteOutput.refAppliedKeys
        }

        System.out.println(" [INFO] Expressions After Rewrite: ")
        for(k : rewriteOutput.mapLHStoRHS.keySet) {
            for(v : rewriteOutput.mapLHStoRHS.get(k))
                System.out.println("    > K: " + k + " > V: " + v)
        }

        // remove expressions that were used to overwrite other expressions
        for(k : refAppliedKeys) { rewriteOutput.mapLHStoRHS.remove(k) }

        return rewriteOutput.mapLHStoRHS
    }

    private def rewriteExpressions(Map<String, List<String>> mapLHStoRHS)
    {
        // Rewrite Implementation to Support list of values in mapLHStoRHS
        // Same LHS many RHS assignments (typical in lists/maps)
        val refAppliedKeys = newLinkedHashSet
        var rewriteFlag = false
        val _mapLHStoRHS = new HashMap<String, List<String>>
        for(k : mapLHStoRHS.keySet) { _mapLHStoRHS.put(k,new ArrayList<String>(mapLHStoRHS.get(k))) }
        for(k : mapLHStoRHS.keySet) {
            for(_k : mapLHStoRHS.keySet) { 
                var idx = 0
                // System.out.println("    Value Size: " + mapLHStoRHS.get(k).size)
                for(v : mapLHStoRHS.get(k)) { 
                    // System.out.println("    <> _k: " + _k)
                    // System.out.println("    <>  v: " + v)
                    if(_k.equals(v)) 
                    { // if LHS equals RHS
                        rewriteFlag = true
                        // System.out.println(" [INFO] LHS and RHS Match! ")
                        // System.out.println("    => _k: " + _k)
                        // System.out.println("    =>  v: " + v)
                        // replace the value at a specific index of value list
                         // i.e., insert list of values at idx
                        _mapLHStoRHS.get(k).addAll(idx, new ArrayList<String>(_mapLHStoRHS.get(_k)))

                        // remove the original value at idx
                        if(idx + _mapLHStoRHS.get(_k).size <= _mapLHStoRHS.get(k).size) 
                            _mapLHStoRHS.get(k).remove(idx + _mapLHStoRHS.get(_k).size)

                        // Updated Key List is experimental. Not Used. See notes later 
                        refAppliedKeys.add(_k)
                        // refUpdatedKeyList.add(k)
                    }
                    // Resolves earlier TODO How to rewrite with functions? Resolved DB 31.07.2025
                    // TODO check if this condition is reached if a function was not involved in expression!
                    // Untested for this case. 
                    else if(v.contains(_k)) 
                    {
                        // Prefix matching. Added DB 30.07.2025
                        rewriteFlag = true
                        // System.out.println(" [INFO] LHS and RHS Subsequence Match! ")
                        // System.out.println("    => _k: " + _k)
                        // System.out.println("    =>  v: " + v)
                        // for each i in 1.. n add an entry with 
                        //_mapLHStoRHS.get(k).get(idx).replace(_k, _mapLHStoRHS.get(_k).get(i))
                        var rewrite_var = _mapLHStoRHS.get(k).get(idx)
                        // Create list of expressions with rhs being replaces with matched lhs
                        // lhs may in turn have a list of values
                        var list_of_rewrite_var = new ArrayList<String>
                        for(_v : _mapLHStoRHS.get(_k)) {
                            var temp_rewrite_var = rewrite_var
                            temp_rewrite_var = temp_rewrite_var.replace(_k, _v)
                            list_of_rewrite_var.add(temp_rewrite_var)
                        }
                        // add a list of rewritten expressions and remove original at idx
                        _mapLHStoRHS.get(k).addAll(idx, list_of_rewrite_var)
                        if(idx + list_of_rewrite_var.size <= _mapLHStoRHS.get(k).size) 
                            _mapLHStoRHS.get(k).remove(idx + list_of_rewrite_var.size)

                        // Updated Key List is experimental. Not Used. See notes later
                        refAppliedKeys.add(_k)
                        // refUpdatedKeyList.add(k)
                    }
                    idx++
                }
            }
        }

        return new RewriteOutput(rewriteFlag, _mapLHStoRHS, refAppliedKeys)
    }

    private def _printRecord_(String varRefName, String runStepName, ComposeStep composeStep,
        RecordFieldAssignmentAction rec, boolean isFirstCompose) {

        // Run block input data structure = Concrete TSpec step input data structure
        val field = isFirstCompose
            ? '''«runStepName.split("_").get(0)»Input.«EcoreUtil3.serialize(rec.fieldAccess)»'''
            : '''step_«composeStep.name».output.«EcoreUtil3.serialize(rec.fieldAccess)»'''

        // rec.exp is a reference to the original pspec, hence we should not update the expression!
        // However, serialization requires the expression to be contained by an XtextResource
        // So, we store the original expression, before copying and evaluating it. Then we serialize
        // the evaluated expression and restore the original expression.
        val orgExp = rec.exp
        rec.exp = new ExpressionEvaluator().evaluate(rec.exp.copy)[ variable |
            composeStep.input.findFirst[name == variable]?.jsonvals.toExpression(variable.type.typeObject, self) [
                // Only consider concrete values as we're evaluating symbolic expressions here
                kind == RecordFieldKind::CONCRETE
            ]
        ]
        val value = rec.exp.serialize[ obj |
            if (obj instanceof ExpressionVariable) {
                val vname = obj.variable.name
                val stepRef = composeStep.stepRef.findFirst[refData.exists[name == vname]]
                if (stepRef !== null) {
                    return '''step_«stepRef.refStep.name».output.«vname»'''
                }
            }
        ]
        rec.exp = orgExp

        return new StepConstraint(runStepName, composeStep.name, field.trim, value.trim)
    }

/*
 * End of Feature Update: Support Interleaving of Compose and Run Steps
 * Q1 2025. 
 */
}

@Data
class RewriteOutput {
    boolean atleastOneExpRewritten
    HashMap<String, List<String>> mapLHStoRHS
    LinkedHashSet<String> refAppliedKeys
}

@Data
class StepConstraint
{
    val String composeStepName
    val String runStepName
    val String lhs
    val String rhs

    def String getText() '''«lhs» := «rhs»'''
}
