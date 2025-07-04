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
package nl.esi.comma.testspecification.generator.to.concrete

import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.StepReference

import java.util.List
import java.util.ArrayList
import java.util.HashMap

import org.eclipse.emf.common.util.EList

import static extension nl.esi.comma.testspecification.generator.utils.Utils.*
import nl.asml.matala.product.product.VarRef
import nl.esi.comma.testspecification.generator.to.concrete.ExpressionGenerator

class ReferenceExpressionHandler 
{
    var isFast = false
    
    new(boolean _isFast) { isFast = _isFast }

    /*
     * Support Interleaving of Compose and Run Steps. 
     * Q1 2025.  
     */
    def resolveStepReferenceExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps)
    {
        // System.out.println("Run Step: " + rstep.name)
        var mapLHStoRHS = new HashMap<String,List<String>>
        // Find preceding Compose Step
        for(cstep : composeSteps) // at most one 
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
        /*for(k : mapLHStoRHS.keySet) {
            for(v : mapLHStoRHS.get(k))
            System.out.println("    > K: " + k + " > V: " + v)
        }*/
        // Rewrite expressions in mapLHStoRHS
        // TODO Validate that LHS and RHS are unique. 
        // No collisions are allowed.
        var refKeyList = new ArrayList<String>
        // Commented to rewrite with list values in mapLHStoRHS
        /*for(k : mapLHStoRHS.keySet) {
            for(_k : mapLHStoRHS.keySet) { 
                if(_k.equals(mapLHStoRHS.get(k))) { // if LHS equals RHS
                    mapLHStoRHS.put(k, mapLHStoRHS.get(_k)) // rewrite
                    refKeyList.add(_k)
                }
            }
        }*/
        // Rewrite implementation for list of values in mapLHStoRHS
        var _mapLHStoRHS = new HashMap<String, List<String>>
        for(k : mapLHStoRHS.keySet) { _mapLHStoRHS.put(k,new ArrayList<String>(mapLHStoRHS.get(k))) }
        for(k : mapLHStoRHS.keySet) {
            for(_k : mapLHStoRHS.keySet) { 
                var idx = 0
                for(v : mapLHStoRHS.get(k)) {
                    // if(!v.startsWith("add")) { // TODO. How to rewrite with functions? Problem for nested compose. 
                        if(_k.equals(v)) { // if LHS equals RHS
                            // replace the value at a specific index of value list
                            _mapLHStoRHS.get(k).addAll(idx, new ArrayList<String>(_mapLHStoRHS.get(_k))) // insert list of values at idx
                            if(idx + _mapLHStoRHS.get(_k).size <= _mapLHStoRHS.get(k).size) 
                                _mapLHStoRHS.get(k).remove(idx + _mapLHStoRHS.get(_k).size)
                            // mapLHStoRHS.put(k, mapLHStoRHS.get(_k)) // rewrite
                            refKeyList.add(_k)
                        }
                    // }
                    idx++
                }
            }
        }
        /*for(k : _mapLHStoRHS.keySet) {
            for(v : _mapLHStoRHS.get(k))
            System.out.println("    > K: " + k + " > V: " + v)
        }*/
        // remove intermediate expressions
        for(k : refKeyList) { _mapLHStoRHS.remove(k) }

        return _mapLHStoRHS
    }

    def _printRecord_(String varRefName, String composeStepName, String runStepName, 
        EList<StepReference> stepRef, RecordFieldAssignmentAction rec, boolean isFirstCompose) {

        // Run block input data structure = Concrete TSpec step input data structure
        var blockInputName = new String 
        var pi = new String

        // System.out.println(" Field: " + printField(rec.fieldAccess, true))
        var field = new String
        if(isFirstCompose) {
            blockInputName = runStepName.split("_").get(0) + "Input"
            pi = blockInputName + "."
            field = rec.fieldAccess.printField
        } else {
            blockInputName = "step_" + composeStepName + ".output."
            pi = blockInputName
            field = rec.fieldAccess.printField
        }

        var value = (new ExpressionGenerator(stepRef, runStepName, varRefName)).exprToComMASyntax(rec.exp)

//        if (!(rec.exp instanceof ExpressionVector || rec.exp instanceof ExpressionFunctionCall)) {
//            // For record expressions. 
//            // The rest is handled as override functions in ExpressionGenerator.
//            for(csref : stepRef) {
//                for(csrefdata : csref.refData) {
//                    // System.out.println(" Replacing: " + sd.name + " with " + sr.refStep.name)
//                    if(csref.refStep instanceof RunStep && 
//                        value.toString.contains(csrefdata.name)) {
//                        if(!isFast) value = "step_" + csref.refStep.name + ".output." + value
//                        else value = csref.refStep.name + "." + value
//                    }
//                }
//            }
//        }
        if(!isFast)
            return new StepConstraint ( runStepName,
                                    composeStepName, 
                                    pi + field, // lhs
                                    value.toString, // rhs
                                    pi + field + " := " + value // text
                                  )
        else
            return new StepConstraint ( runStepName,
                                    composeStepName, 
                                    field, // lhs
                                    value.toString, // rhs
                                    field + " = " + value // text
                                  ) 
    }


    // Gets the list of referenced compose steps by a compose step, recursively!
    // RULE. Compose Step may reference at most one preceding Compose Step. 
    // RULE. Each Compose Step must reference at least one Run Step. 
    def List<ComposeStep> getNestedComposeSteps(ComposeStep cstep, List<ComposeStep> listOfComposeSteps) 
    {
        if(cstep.stepRef.isNullOrEmpty) return listOfComposeSteps

        for(elm : cstep.stepRef) 
        {
            if(elm.refStep instanceof ComposeStep) {
                listOfComposeSteps.add(elm.refStep as ComposeStep)
                getNestedComposeSteps(elm.refStep as ComposeStep, listOfComposeSteps)
            }
        }
        return listOfComposeSteps
    }

    def List<RunStep> getReferencedRunSteps(ComposeStep cstep, List<RunStep> listOfRunSteps) 
    {
        if(cstep.stepRef.isNullOrEmpty) return listOfRunSteps

        for(elm : cstep.stepRef) 
        {
            if(elm.refStep instanceof RunStep) {
                listOfRunSteps.add(elm.refStep as RunStep)
                return listOfRunSteps
            }
            else if(elm.refStep instanceof ComposeStep) {
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