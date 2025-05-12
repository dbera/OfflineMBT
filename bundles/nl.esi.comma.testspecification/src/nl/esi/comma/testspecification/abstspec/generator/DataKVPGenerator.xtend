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
package nl.esi.comma.testspecification.abstspec.generator

import java.util.ArrayList
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.RunStep

import static extension nl.esi.comma.testspecification.abstspec.generator.Utils.*

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
                        "parameters" : {
                            «FOR ref : step.stepRef»
                                «IF ref.refStep instanceof ComposeStep»«generateStepRefs(ref.refStep as ComposeStep)»«ENDIF»
                            «ENDFOR»
                        }
                        "JSON" : {
                            file-name: ""   file-path = ""
                            «generateExpressionText(step,atd)»
                        }
                    }
                ]
            «ENDFOR»
        «ENDFOR»
        '''
        return txt
    }

    def generateStepRefs(ComposeStep cs) 
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

    def generateExpressionText(RunStep rstep, AbstractTestDefinition atd) {
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
    
    def prepareStepInputExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps) 
    {
        return 
        '''
        «FOR composeStep : composeSteps»
            «printJSONOutput(rstep.name.split("_").get(0) + "Input", composeStep)»
        «ENDFOR»
        '''
    }

    def printJSONOutput(String prefix, ComposeStep step) {
        var kv = ""
        if (!step.suppress) {
            for (o : step.output) {
                kv += o.jsonvals.stringValue 
                // printKVInputPairs(prefix, o.name.name, o.kvPairs)
            }
        }
        return kv
    }
}