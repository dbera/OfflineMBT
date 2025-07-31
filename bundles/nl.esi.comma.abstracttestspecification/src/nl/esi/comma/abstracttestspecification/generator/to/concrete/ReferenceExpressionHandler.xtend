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
import nl.asml.matala.product.product.VarRef
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ComposeStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.StepReference
import org.eclipse.emf.common.util.EList

import static extension nl.esi.comma.abstracttestspecification.generator.utils.Utils.*

class ReferenceExpressionHandler 
{
    /*
     * Support Interleaving of Compose and Run Steps. 
     * Q1 2025.  
     */

     // Commented Code below to Resolve earlier TODO How to rewrite with functions? 
     // Resolved DB 31.07.2025. See comments in replacement function below. //

//    def resolveStepReferenceExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps) {
//        // System.out.println("Run Step: " + rstep.name)
//        var mapLHStoRHS = new HashMap<String, List<String>>
//        // Find preceding Compose Step
//        for (cstep : composeSteps) // at most one 
//        {
//            // System.out.println("    -> compose-name: " + cstep.name)
//            var refTxt = new String
//            for (cons : cstep.refs) {
//                // System.out.println("    -> constraint-var: " + cons.name)
//                for (refcons : cons.ce) {
//                    var varRefName = (refcons.eContainer.eContainer as VarRef).ref.name
//                    for (a : refcons.act.actions) {
//                        var constraint = _printRecord_(varRefName, cstep.name, rstep.name, cstep.stepRef,
//                            a as RecordFieldAssignmentAction, true)
//                        refTxt += constraint.getText + "\n"
//                        // mapLHStoRHS.put(constraint.lhs, constraint.rhs)
//                        if (mapLHStoRHS.containsKey(constraint.lhs)) {
//                            var constraintList = mapLHStoRHS.get(constraint.lhs)
//                            if(!constraintList.contains(constraint.rhs)) constraintList.add(constraint.rhs)
//                            mapLHStoRHS.put(constraint.lhs, constraintList)
//                        } else {
//                            var constraintList = new ArrayList<String>
//                            if(!constraintList.contains(constraint.rhs)) constraintList.add(constraint.rhs)
//                            mapLHStoRHS.put(constraint.lhs, constraintList)
//                        }
//                    }
//                }
//            }
//            // if(!refTxt.isEmpty) System.out.println("\nLocal Constraints:\n" + refTxt)
//            var cstepList = getNestedComposeSteps(cstep, new ArrayList<ComposeStep>)
//            for (cs : cstepList) {
//                // System.out.println("        -> compose-name: " + cs.name)
//                refTxt = new String
//                for (cons : cs.refs) {
//                    // System.out.println("        -> constraint-var: " + cons.name)
//                    for (refcons : cons.ce) {
//                        var varRefName = (refcons.eContainer.eContainer as VarRef).ref.name
//                        for (a : refcons.act.actions) {
//                            var constraint = _printRecord_(varRefName, cs.name, rstep.name, cs.stepRef,
//                                a as RecordFieldAssignmentAction, false)
//                            refTxt += constraint.getText + "\n"
//                            // mapLHStoRHS.put(constraint.lhs, constraint.rhs)
//                            if (mapLHStoRHS.containsKey(constraint.lhs)) {
//                                var constraintList = mapLHStoRHS.get(constraint.lhs)
//                                if(!constraintList.contains(constraint.rhs)) constraintList.add(constraint.rhs)
//                                mapLHStoRHS.put(constraint.lhs, constraintList)
//                            } else {
//                                var constraintList = new ArrayList<String>
//                                if(!constraintList.contains(constraint.rhs)) constraintList.add(constraint.rhs)
//                                mapLHStoRHS.put(constraint.lhs, constraintList)
//                            }
//                        }
//                    }
//                }
//            }
//        // if(!refTxt.isEmpty) System.out.println("\nRef Constraints:\n" + refTxt)
//        }
//        /*for(k : mapLHStoRHS.keySet) {
//         *     for(v : mapLHStoRHS.get(k))
//         *     System.out.println("    > K: " + k + " > V: " + v)
//         }*/
//        // Rewrite expressions in mapLHStoRHS
//        // TODO Validate that LHS and RHS are unique. 
//        // No collisions are allowed.
//        var refKeyList = new ArrayList<String>
//        // Commented to rewrite with list values in mapLHStoRHS
//        /*for(k : mapLHStoRHS.keySet) {
//         *     for(_k : mapLHStoRHS.keySet) { 
//         *         if(_k.equals(mapLHStoRHS.get(k))) { // if LHS equals RHS
//         *             mapLHStoRHS.put(k, mapLHStoRHS.get(_k)) // rewrite
//         *             refKeyList.add(_k)
//         *         }
//         *     }
//         }*/
//        // Rewrite implementation for list of values in mapLHStoRHS
//        var _mapLHStoRHS = new HashMap<String, List<String>>
//        for (k : mapLHStoRHS.keySet) {
//            _mapLHStoRHS.put(k, new ArrayList<String>(mapLHStoRHS.get(k)))
//        }
//        for (k : mapLHStoRHS.keySet) {
//            for (_k : mapLHStoRHS.keySet) {
//                var idx = 0
//                for (v : mapLHStoRHS.get(k)) {
//                    // if(!v.startsWith("add")) { // TODO. How to rewrite with functions? Problem for nested compose. 
//                    if (_k.equals(v)) { // if LHS equals RHS
//                    // replace the value at a specific index of value list
//                        _mapLHStoRHS.get(k).addAll(idx, new ArrayList<String>(_mapLHStoRHS.get(_k))) // insert list of values at idx
//                        if (idx + _mapLHStoRHS.get(_k).size <= _mapLHStoRHS.get(k).size)
//                            _mapLHStoRHS.get(k).remove(idx + _mapLHStoRHS.get(_k).size)
//                        // mapLHStoRHS.put(k, mapLHStoRHS.get(_k)) // rewrite
//                        refKeyList.add(_k)
//                    }
//                    // }
//                    idx++
//                }
//            }
//        }
//        /*for(k : _mapLHStoRHS.keySet) {
//         *     for(v : _mapLHStoRHS.get(k))
//         *     System.out.println("    > K: " + k + " > V: " + v)
//         }*/
//        // remove intermediate expressions
//        for (k : refKeyList) {
//            _mapLHStoRHS.remove(k)
//        }
//
//        return _mapLHStoRHS
//    }

    // Updated DB 31.07.2025. Support chaining of compose steps with functions in expressions.
    def resolveStepReferenceExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps)
    {
        // System.out.println("Run Step: " + rstep.name)
        var mapLHStoRHS = new HashMap<String,List<String>>
        // Find preceding Compose Step
        for(cstep : composeSteps) // at most one of a type
        {
            // System.out.println("    -> compose-name: " + cstep.name)
            var refTxt = new String
            for(cons : cstep.refs) {
                // System.out.println("    -> constraint-var: " + cons.name)
                for(refcons : cons.ce) {
                    var varRefName = (refcons.eContainer.eContainer as VarRef).ref.name
                    for (a : refcons.act.actions) {
                        var constraint = _printRecord_(varRefName, cstep.name, 
                                                    rstep.name, cstep.stepRef, 
                                                    a as RecordFieldAssignmentAction, true)
                        refTxt += constraint.getText + "\n"
                        // mapLHStoRHS.put(constraint.lhs, constraint.rhs)
                        if(mapLHStoRHS.containsKey(constraint.lhs)) {
                            var constraintList = mapLHStoRHS.get(constraint.lhs)
                            if(!constraintList.contains(constraint.rhs)) constraintList.add(constraint.rhs)
                            mapLHStoRHS.put(constraint.lhs, constraintList)
                        } else {
                            var constraintList = new ArrayList<String>
                            if(!constraintList.contains(constraint.rhs)) constraintList.add(constraint.rhs)
                            mapLHStoRHS.put(constraint.lhs, constraintList)
                        }
                    }
                }
            }
            // if(!refTxt.isEmpty) System.out.println("\nLocal Constraints:\n" + refTxt)
            var cstepList = getNestedComposeSteps(cstep, new ArrayList<ComposeStep>)
            for(cs : cstepList) {
                // System.out.println("        -> compose-name: " + cs.name)
                refTxt = new String
                for(cons : cs.refs) {
                    // System.out.println("        -> constraint-var: " + cons.name)
                    for(refcons : cons.ce) {
                        var varRefName = (refcons.eContainer.eContainer as VarRef).ref.name
                        for (a : refcons.act.actions) {
                            var constraint = _printRecord_(varRefName, cs.name, rstep.name, cs.stepRef, 
                                                a as RecordFieldAssignmentAction, false)
                            refTxt += constraint.getText + "\n"
                            // mapLHStoRHS.put(constraint.lhs, constraint.rhs)
                            if(mapLHStoRHS.containsKey(constraint.lhs)) {
                                var constraintList = mapLHStoRHS.get(constraint.lhs)
                                if(!constraintList.contains(constraint.rhs)) constraintList.add(constraint.rhs)
                                mapLHStoRHS.put(constraint.lhs, constraintList)
                            } else {
                                var constraintList = new ArrayList<String>
                                if(!constraintList.contains(constraint.rhs)) constraintList.add(constraint.rhs)
                                mapLHStoRHS.put(constraint.lhs, constraintList)
                            } 
                        }
                    }
                }
            }
            // if(!refTxt.isEmpty) System.out.println("\nRef Constraints:\n" + refTxt)
        }
        /*System.out.println(" Before Rewrite ")
        for(k : mapLHStoRHS.keySet) {
            for(v : mapLHStoRHS.get(k))
            System.out.println("    > K: " + k + " > V: " + v)
        }*/
        // Rewrite expressions in mapLHStoRHS
        // TODO Validate that LHS and RHS are unique. 
        // No collisions are allowed.
        var refAppliedKeyList = new ArrayList<String>
        var refUpdatedKeyList = new ArrayList<String>
        // Commented to rewrite with list values in mapLHStoRHS
        /*for(k : mapLHStoRHS.keySet) {
            for(_k : mapLHStoRHS.keySet) { 
                if(_k.equals(mapLHStoRHS.get(k))) { // if LHS equals RHS
                    mapLHStoRHS.put(k, mapLHStoRHS.get(_k)) // rewrite
                    refKeyList.add(_k)
                }
            }
        }*/
        // Rewrite Implementation to Support list of values in mapLHStoRHS
        // Same LHS many RHS assignments (typical in lists/maps)
        var _mapLHStoRHS = new HashMap<String, List<String>>
        for(k : mapLHStoRHS.keySet) { _mapLHStoRHS.put(k,new ArrayList<String>(mapLHStoRHS.get(k))) }
        for(k : mapLHStoRHS.keySet) {
            for(_k : mapLHStoRHS.keySet) { 
                var idx = 0
                for(v : mapLHStoRHS.get(k)) { 
                    // System.out.println("    <> _k: " + _k)
                    // System.out.println("    <>  v: " + v)
                    if(_k.equals(v)) 
                    { // if LHS equals RHS
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
                        refAppliedKeyList.add(_k)
                        refUpdatedKeyList.add(k)
                    }
                    // Resolves earlier TODO How to rewrite with functions? Resolved DB 31.07.2025
                    // TODO check if this condition is reached if a function was not involved in expression!
                    // Untested for this case. 
                    else if(v.contains(_k)) 
                    {
                        // Prefix matching. Added DB 30.07.2025
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
                        refAppliedKeyList.add(_k)
                        refUpdatedKeyList.add(k)
                    }
                    idx++
                }
            }
        }
        /*System.out.println(" [INFO] After Rewrite ")
        for(k : _mapLHStoRHS.keySet) {
            for(v : _mapLHStoRHS.get(k))
            System.out.println("    > K: " + k + " > V: " + v)
        }*/
        // remove expressions that were used to overwrite other expressions
        for(k : refAppliedKeyList) { _mapLHStoRHS.remove(k) }

        // Not Resolved DB 31.07.2025
        // Compute expressions that were not used in rewrites.
        // But this is not correct, since it will also remove KV pairs 
        // that were resolved directly to RUN in the first step
        // Question is how to know if an expression has been resolved to a RUN step.
        // For now TODO Add validation to detect dangling expressions, 
        // i.e., source run step never touches this expression.

        // var danglingRefs = new ArrayList<String> 
        /*for(k : _mapLHStoRHS.keySet) {
            if(!refUpdatedKeyList.contains(k))
                danglingRefs.add(k)
        }
        for(k : danglingRefs) { 
            System.out.println(" [INFO] Removing Dangling Ref Expressions... ")
            for(v : _mapLHStoRHS.get(k)) {
                System.out.println("          > K: " + k )
                System.out.println("          > V: " + v )
             }
            _mapLHStoRHS.remove(k)
        }*/

        return _mapLHStoRHS
    }

    def _printRecord_(String varRefName, String composeStepName, String runStepName, EList<StepReference> stepRef,
        RecordFieldAssignmentAction rec, boolean isFirstCompose) {

        // Run block input data structure = Concrete TSpec step input data structure
        var blockInputName = new String
        var pi = new String

        // System.out.println(" Field: " + printField(rec.fieldAccess, true))
        var field = new String
        if (isFirstCompose) {
            blockInputName = runStepName.split("_").get(0) + "Input"
            pi = blockInputName + "."
            field = rec.fieldAccess.printField
        } else {
            blockInputName = "step_" + composeStepName + ".output."
            pi = blockInputName
            field = rec.fieldAccess.printField
        }

        var value = (new ExpressionGenerator(stepRef, runStepName, varRefName)).exprToComMASyntax(rec.exp)

        return new StepConstraint(
            runStepName,
            composeStepName,
            pi + field, // lhs
            value.toString, // rhs
            pi + field + " := " + value // text
        )
    }

    // Gets the list of referenced compose steps by a compose step, recursively!
    // RULE. Compose Step may reference at most one preceding Compose Step.  
    // RULE. Each Compose Step must reference at least one Run Step. 
    // Update 31.07.2025 DB: None of these rules are needed anymore. May reference other compose steps
    // TODO validate it. 
    def List<ComposeStep> getNestedComposeSteps(ComposeStep cstep, List<ComposeStep> listOfComposeSteps) {
        if(cstep.stepRef.isNullOrEmpty) return listOfComposeSteps

        for (elm : cstep.stepRef) {
            if (elm.refStep instanceof ComposeStep) {
                listOfComposeSteps.add(elm.refStep as ComposeStep)
                getNestedComposeSteps(elm.refStep as ComposeStep, listOfComposeSteps)
            }
        }
        return listOfComposeSteps
    }

    def List<RunStep> getReferencedRunSteps(ComposeStep cstep, List<RunStep> listOfRunSteps) {
        if(cstep.stepRef.isNullOrEmpty) return listOfRunSteps

        for (elm : cstep.stepRef) {
            if (elm.refStep instanceof RunStep) {
                listOfRunSteps.add(elm.refStep as RunStep)
                return listOfRunSteps
            } else if (elm.refStep instanceof ComposeStep) {
                getReferencedRunSteps(elm.refStep as ComposeStep, listOfRunSteps)
            }
        }
        return listOfRunSteps
    }

/*
 * End of Feature Update: Support Interleaving of Compose and Run Steps
 * Q1 2025. 
 */
}
