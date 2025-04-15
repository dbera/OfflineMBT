package nl.esi.comma.testspecification.abstspec.generator

import nl.esi.comma.testspecification.testspecification.RunStep
import java.util.HashSet
import nl.esi.comma.testspecification.testspecification.ComposeStep
import org.eclipse.emf.common.util.EList
import nl.esi.comma.testspecification.testspecification.NestedKeyValuesPair
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction

class ConcreteExpressionHandler 
{
    /* TODO. Q2 2025. Yuri. 
     * Fix JSON Object to ComMA Expression Reconstruction.
     */
    def prepareStepInputExpressions(RunStep rstep, HashSet<ComposeStep> listOfComposeSteps) 
    {
        return 
        '''
        «FOR composeStep : listOfComposeSteps»
        «printKVOutputPairs(rstep.name.split("_").get(0) + "Input", composeStep)»
        «ENDFOR»
        '''
    }

    /* Removed ComMA Expression Printing 04.04.2025 */
    /* TODO Rewrite this function to parse JSON Object */
    def printKVOutputPairs(String prefix, ComposeStep step) {
        var kv = ""
//      if (!step.suppress) {
//          for (o : step.output) {
//              kv += printKVInputPairs(prefix, o.name.name, o.kvPairs)
//          }
//      }
        return kv
    }

    def printKVInputPairs(String prefix, String field, EList<NestedKeyValuesPair> pairs) {
        var kv = ""
        for (p : pairs) {
            for (a : p.actions) {
                kv += prefix + "." + field + (new Utils()).printRecord("", "", null, a as RecordFieldAssignmentAction) + "\n"
            }
        }
        return kv
    }

}