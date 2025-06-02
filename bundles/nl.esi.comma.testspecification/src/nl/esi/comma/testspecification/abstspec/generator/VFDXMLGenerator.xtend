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

import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.ArrayList
import java.util.HashMap
import java.util.Map
import java.util.List
import java.util.TreeSet
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

    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
    String ns=''
    String xsi=''
    String loc=''
    String title=''

    new(){
        this(new HashMap<String,String>())
    }

    new(String ns, String xsi, String loc, String title){
        this.ns=ns
        this.xsi=xsi
        this.loc=loc
        this.title=title
    }

    new(Map<String, String> map) {
        this(
            map.getOrDefault("ns",""),
            map.getOrDefault("xsi",""),
            map.getOrDefault("loc",""),
            map.getOrDefault("title","")
        )
    }

    def generateXMLFromSUTVars(AbstractTestDefinition atd) 
    {
        var now = LocalDateTime.now();
        var aliasField = new HashMap<String,String>()
        
        var stepSutDataIn = new ArrayList<Binding>()
        var stepSutDataOut = new ArrayList<Binding>()
        for (testseq : atd.testSeq) {
        	for (step : testseq.step) {
        		stepSutDataIn.addAll(getSUTData(step.input, getSUTVars(step)))
        		stepSutDataOut.addAll(getSUTData(step.output, getSUTVars(step)))
        	}
        }
        var stepSutData = removeDuplicates(stepSutDataIn,stepSutDataOut)
        
        return '''
        <?xml version="1.0" encoding="UTF-8"?>
        <VirtualFabDefinition:VirtualFabDefinition xmlns:VirtualFabDefinition="«this.ns»" xmlns:xsi="«this.xsi»" xsi:schemaLocation="«this.loc»">
          <Header>
            <Title>«this.title»</Title>
            <CreateTime>«now.format(this.formatter)»</CreateTime>
          </Header>
          <Definition>
            <Name>atd</Name>
            <Description>sutsdesc</Description>
            <SUTList>
            «FOR attr : stepSutData»
                <SUT>
                    «JsonHelper.toXMLElement(attr.jsonvals)»
                </SUT>
            «ENDFOR»
            </SUTList>
          </Definition>
        </VirtualFabDefinition:VirtualFabDefinition>
        '''
    }
    
    def List<Binding> removeDuplicates(List<Binding> inData, List<Binding> outData) {
        var join = new TreeSet<Binding>(new BindingComparator())
        for (element : inData) {
            join.add(element)
        }
        for (element : outData) {
            join.add(element)
        }
        return join.toList
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