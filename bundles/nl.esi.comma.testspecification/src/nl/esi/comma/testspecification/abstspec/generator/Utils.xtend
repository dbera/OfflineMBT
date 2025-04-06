package nl.esi.comma.testspecification.abstspec.generator

import org.eclipse.emf.common.util.EList
import nl.esi.comma.testspecification.testspecification.StepReference
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.testspecification.generator.ExpressionGenerator
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import java.util.HashSet
import nl.esi.comma.testspecification.testspecification.ComposeStep

class Utils 
{
    // Gets the list of referenced compose steps
    // RULE. Exactly one referenced Compose Step. 
    def getComposeSteps(RunStep rstep, AbstractTestDefinition atd) {
        var listOfComposeSteps = new HashSet<ComposeStep>
        for(elm : rstep.stepRef) {
            for(cstep: atd.eAllContents.filter(ComposeStep).toIterable) {
                if(elm.refStep.name.equals(cstep.name)) {
                    listOfComposeSteps.add(cstep)
                }
            }
        }
        listOfComposeSteps
    }

    def printRecord(String stepName, String prefix, EList<StepReference> stepRef, RecordFieldAssignmentAction rec) {
        var field = printField(rec.fieldAccess, false)
        var value = (new ExpressionGenerator(stepRef,stepName)).exprToComMASyntax(rec.exp)
        var p = (rec.exp instanceof ExpressionVector || rec.exp instanceof ExpressionFunctionCall) ? "" : prefix
        return field + " := " + p + value
    }

    dispatch def String printField(ExpressionRecordAccess exp, boolean printVar) {
        return printField(exp.record, printVar) + "." + exp.field.name
    }

    dispatch def String printField(ExpressionVariable exp, boolean printVar) {
        if(printVar) return exp.getVariable().getName()
        else return ""
    }
}