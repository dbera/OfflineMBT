package nl.esi.comma.testspecification.abstspec.generator

import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.comma.assertthat.assertThat.GenericScriptBlock
import java.util.ArrayList
import nl.esi.comma.testspecification.testspecification.AbstractStep
import org.eclipse.emf.common.util.EList
import nl.esi.comma.assertthat.assertThat.AssertThatBlock
import nl.esi.comma.assertthat.assertThat.AssertThatXMLFile
import nl.esi.comma.assertthat.assertThat.AssertThatValue
import nl.esi.comma.assertthat.assertThat.AssertThatXPaths
import nl.esi.comma.assertthat.assertThat.AssertValidation

class RefKVPGenerator {
    def generateRefKVP(AbstractTestDefinition atd) {
        var txt = 
        '''
        matlab_calls=[ 
        «FOR test : atd.testSeq»
            «FOR mlcal : getScriptCalls(test.step) SEPARATOR ',' »
                «AssertionsHelper.parseScriptCall(mlcal)»
            «ENDFOR»
        «ENDFOR»
        ]
        
        assertions = [
        «FOR test : atd.testSeq»
            «FOR asrt : getAssertionItems(test.step) SEPARATOR ',' »
                «AssertionsHelper.parseAssertThat(asrt)»
            «ENDFOR»
        «ENDFOR»
        ]
        '''
        return txt
    }

    def getScriptCalls(EList<AbstractStep> absteps) 
    {
        var assertionSteps = absteps.filter(AssertionStep)
        var scriptCalls = new ArrayList<GenericScriptBlock>()
        for (step : assertionSteps) {
            for (assert: step.asserts) {
                for (ce : assert.ce) {
                   for (mcal: ce.constr.filter(GenericScriptBlock)) {
                       scriptCalls.add(mcal)
                   }
                }
            }
        }
        return scriptCalls
    }
    
    def getAssertionItems(EList<AbstractStep> absteps) 
    {
        var assertionSteps = absteps.filter(AssertionStep)
        var assertionItems = new ArrayList<AssertThatBlock>()
        for (step : assertionSteps) {
            for (assert: step.asserts) {
                for (ce : assert.ce) {
                   for (asrt: ce.constr.filter(AssertThatBlock)) {
                       assertionItems.add(asrt)
                   }
                }
            }
        }
        return assertionItems
    }
    
    def getAssertionType(AssertValidation asrt){
        if (asrt instanceof AssertThatValue) return "Value" // assertion of type Value
        if (asrt instanceof AssertThatXPaths) return "XPaths" // assertion of type XPaths
        if (asrt instanceof AssertThatXMLFile) return "XMLFile" // assertion of type XMLFile
        throw new RuntimeException("Not supported")
    }
}