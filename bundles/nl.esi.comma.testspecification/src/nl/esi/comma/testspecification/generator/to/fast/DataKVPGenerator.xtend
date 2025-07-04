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
package nl.esi.comma.testspecification.generator.to.fast

import java.util.ArrayList
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.RunStep

import static extension nl.esi.comma.testspecification.generator.utils.Utils.*
import static extension nl.esi.comma.types.utilities.EcoreUtil3.serialize
import nl.esi.comma.testspecification.generator.to.concrete.ReferenceExpressionHandler

class DataKVPGenerator 
{
    def generateFAST(AbstractTestDefinition atd) {
        var txt = 
        '''
        «FOR test : atd.testSeq»
            «FOR step : test.step.filter(RunStep)»
                in.data.global_parameters = { }
                in.data.suts = [ ]
                in.data.steps = [
                    { "id" : "«step.name»", "type" : "«step.stepType.head.replaceAll("_dot_",".")»", "input_file" : "",
                        "parameters": {
                            «FOR ref : step.stepRef»
                                «IF ref.refStep instanceof ComposeStep»«generateStepRefs(ref.refStep as ComposeStep)»«ENDIF»
                            «ENDFOR»
                        }
                        "JSON" : {
                            "file-name": ""
                            "file-path": ""
                            «generateExpressionText(step,atd)»
                        }
                    }
                ]
            «ENDFOR»
        «ENDFOR»
        '''
        return txt
    }

    def private generateStepRefs(ComposeStep cs) 
    {
        var txt = ''''''
        var runSteps = (new ReferenceExpressionHandler(true)).
            getReferencedRunSteps(cs, new ArrayList<RunStep>)
        for(r : runSteps) {
            txt += 
            '''
                «r.name» : «r.name»
            '''
        }
        return txt
    }

    def private generateExpressionText(RunStep rstep, AbstractTestDefinition atd) {
        // At most one (TODO validate this)
        // Observation: when multiple steps have indistinguishable outputs, 
        // multiple consumes from is possible. TODO Warn user.   
        var composeSteps = rstep.composeSteps
        var mapLHStoRHS = (new ReferenceExpressionHandler(true)).
                resolveStepReferenceExpressions(rstep, composeSteps)
        // Get text for concrete data expressions
        var txt = prepareStepInputExpressions(rstep, composeSteps)
        // Append text for reference data expressions
        for(k : mapLHStoRHS.keySet) {
            txt += 
            '''
            «k» := «mapLHStoRHS.get(k)»
            '''
        }
        return txt
    }
    
    def private prepareStepInputExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps) 
    {
        return 
        '''
        «FOR composeStep : composeSteps»
            «printJSONOutput(rstep.inputVar, composeStep)»
        «ENDFOR»
        '''
    }

    def private String printJSONOutput(CharSequence prefix, ComposeStep cstep) {
        // FIXME: Not supporting suppressed record fields yet, only suppressed variables are supported
        val suppressVars = cstep.suppressedVarFields.toSet
        return '''«FOR out : cstep.output.reject[suppressVars.contains(it.name.name)]»
            "«out.name.name»": «out.jsonvals.serialize»
        «ENDFOR»'''
    }
}