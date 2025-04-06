package nl.esi.comma.testspecification.abstspec.generator

import nl.esi.comma.testspecification.testspecification.RunStep
import java.util.HashSet
import nl.esi.comma.testspecification.testspecification.ComposeStep
import java.util.HashMap
import java.util.ArrayList
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import org.eclipse.emf.common.util.EList
import nl.esi.comma.testspecification.testspecification.StepReference
import java.util.List
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.generator.ExpressionGenerator

class ReferenceExpressionHandler {
    /*
     * Support Interleaving of Compose and Run Steps. 
     * Q1 2025.  
     */
    def resolveStepReferenceExpressions(RunStep rstep, HashSet<ComposeStep> listOfComposeSteps) 
    {
        // System.out.println("Run Step: " + rstep.name)
        var mapLHStoRHS = new HashMap<String,String>
        // Find preceding Compose Step
        for(cstep : listOfComposeSteps) // at most one 
        {
            // System.out.println("    -> compose-name: " + cstep.name)
            var refTxt = new String
            for(cons : cstep.refs) {
                // System.out.println("    -> constraint-var: " + cons.name)
                for(refcons : cons.ce) {
                    for (a : refcons.act.actions) {
                        var constraint = _printRecord_(cstep.name, 
                                                    rstep.name, cstep.stepRef, 
                                                    a as RecordFieldAssignmentAction, true)
                        refTxt += constraint.getText + "\n" 
                        mapLHStoRHS.put(constraint.lhs, constraint.rhs)
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
                        for (a : refcons.act.actions) {
                            var constraint = _printRecord_(cs.name, rstep.name, cs.stepRef, 
                                                a as RecordFieldAssignmentAction, false)
                            refTxt += constraint.getText + "\n"
                            mapLHStoRHS.put(constraint.lhs, constraint.rhs) 
                        }
                    }
                }
            }
            // if(!refTxt.isEmpty) System.out.println("\nRef Constraints:\n" + refTxt)
        }
        // Rewrite expressions in mapLHStoRHS
        // TODO Validate that LHS and RHS are unique. 
        // No collisions are allowed.
        var refKeyList = new ArrayList<String>
        for(k : mapLHStoRHS.keySet) {
            for(_k : mapLHStoRHS.keySet) { 
                if(_k.equals(mapLHStoRHS.get(k))) { // if LHS equals RHS
                    mapLHStoRHS.put(k, mapLHStoRHS.get(_k)) // rewrite
                    refKeyList.add(_k)
                }
            }
        }
        // remove intermediate expressions
        for(k : refKeyList) mapLHStoRHS.remove(k)

        return mapLHStoRHS
    }

    def _printRecord_(String composeStepName, String runStepName, 
        EList<StepReference> stepRef, RecordFieldAssignmentAction rec, boolean isFirstCompose) {

        // Run block input data structure = Concrete TSpec step input data structure
        var blockInputName = new String 
        var pi = new String

        // System.out.println(" Field: " + printField(rec.fieldAccess, true))
        var field = new String
        if(isFirstCompose) {
            blockInputName = runStepName.split("_").get(0) + "Input" 
            pi = blockInputName + "."
            field = (new Utils()).printField(rec.fieldAccess, true)
        } else field = (new Utils()).printField(rec.fieldAccess, true)

        var value = (new ExpressionGenerator(stepRef, runStepName)).exprToComMASyntax(rec.exp)
        // System.out.println(" value: " + value)

        if (!(rec.exp instanceof ExpressionVector || rec.exp instanceof ExpressionFunctionCall)) {
            // For record expressions. 
            // The rest is handled as override functions in ExpressionGenerator.
            for(csref : stepRef) {
                for(csrefdata : csref.refData) {
                    // System.out.println(" Replacing: " + sd.name + " with " + sr.refStep.name)
                    if(csref.refStep instanceof RunStep && 
                        value.toString.contains(csrefdata.name)) {
                        value = "step_" + csref.refStep.name + ".output." + value
                    }
                }
            }
        }
        return new StepConstraint ( runStepName,
                                    composeStepName, 
                                    pi + field, // lhs
                                    value.toString, // rhs
                                    pi + field + " := " + value // text
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

    /*
     * End of Feature Update: Support Interleaving of Compose and Run Steps
     * Q1 2025. 
     */
}