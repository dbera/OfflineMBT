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
import nl.esi.comma.testspecification.testspecification.TSJsonValue
import nl.esi.comma.testspecification.testspecification.TSJsonString
import nl.esi.comma.testspecification.testspecification.TSJsonBool
import nl.esi.comma.testspecification.testspecification.TSJsonFloat
import nl.esi.comma.testspecification.testspecification.TSJsonLong
import nl.esi.comma.testspecification.testspecification.TSJsonObject
import nl.esi.comma.testspecification.testspecification.TSJsonArray
import nl.esi.comma.testspecification.testspecification.TSJsonMember

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

    /* ComMA Expression Handler */
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
    /* *********************** */
    
    dispatch def String parseJSON(TSJsonValue v) { return parseJSON(v) }
        // TSJsonString | TSJsonBool | TSJsonFloat | TSJsonLong | TSJsonObject | TSJsonArray
    dispatch def String parseJSON(TSJsonString v) { return v.value}
    dispatch def String parseJSON(TSJsonBool v) { return v.value.toString }
    dispatch def String parseJSON(TSJsonFloat v) { return v.value.toString }
    dispatch def String parseJSON(TSJsonLong v) { return v.value.toString }
    dispatch def String parseJSON(TSJsonObject v) { 
        var txt = 
        '''
        {
            «FOR m : v.members SEPARATOR ''','''»
                «parseJSON(m)»
            «ENDFOR»
        }'''
        return txt.toString
    }
    //  '{' (members+=TSJsonMember) (',' members+=TSJsonMember)* '}'
    dispatch def String parseJSON(TSJsonMember v) { 
        // key=STRING ':' value=TSJsonValue
        var txt = 
        '''
        «v.key» : «parseJSON(v.value)»
        '''
        return txt
    }
    dispatch def String parseJSON(TSJsonArray v) { 
        // '[' (values+=TSJsonValue)? (',' values+=TSJsonValue)* ']'
        var txt = 
        '''
        [
            «FOR value : v.values SEPARATOR ''','''»
                «parseJSON(value)»
            «ENDFOR»
        ]
        '''
        return txt
    }

}