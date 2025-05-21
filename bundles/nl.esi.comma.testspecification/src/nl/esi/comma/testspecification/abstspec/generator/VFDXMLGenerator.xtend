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

import java.util.HashMap
import java.util.List
import java.util.stream.Collectors
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.testspecification.testspecification.AbstractStep
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.comma.testspecification.testspecification.Binding
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.RunStep
import org.eclipse.emf.common.util.EList

class VFDXMLGenerator {
    
    def String generateXMLFromSUTVars(AbstractTestDefinition atd) {
        var aliasField = new HashMap<String,String>()
        return
        '''
        «FOR testseq : atd.testSeq»
            «FOR step : testseq.step» 
                «var stepSutDataIn = getSUTData(step.input, getSUTVars(step))»
                «parseVaribles(stepSutDataIn, aliasField)»

                «var stepSutDataOut = getSUTData(step.output, getSUTVars(step))»
                «parseVaribles(stepSutDataOut, aliasField)»


            «ENDFOR»
        «ENDFOR»
        '''
    }

    def List<Binding> getSUTData(EList<Binding> bindings, EList<Variable> sutvars) {
        val sutvars_names = sutvars.map[s|s.name]
        return bindings .stream
                        .filter(p | sutvars_names.contains(p.name.name))
                        .collect(Collectors.toList())
    }

    def String parseVaribles(List<Binding> variables, HashMap<String,String> aliasField) 
        '''
        «FOR attr: variables»
        «JsonHelper.toXMLElement(attr.jsonvals)»
        «ENDFOR»
        '''
    def EList<Variable> getSUTVars(AbstractStep sequence) {
        switch (sequence) {
        	ComposeStep:   return sequence.varID
        	RunStep:       return sequence.varID
        	AssertionStep: return sequence.varID
        	default: throw new RuntimeException("Not supported")
        }
    }
    def EList<Binding> getStepInputData(AbstractStep sequence) {
        switch (sequence) {
            ComposeStep:   return sequence.input
            RunStep:       return sequence.input
            AssertionStep: return sequence.input
            default: throw new RuntimeException("Not supported")
        }
    }
    def EList<Binding> getStepOutputData(AbstractStep sequence) {
        switch (sequence) {
            ComposeStep:   return sequence.output
            RunStep:       return sequence.output
            AssertionStep: return sequence.output
            default: throw new RuntimeException("Not supported")
        }
    }

}