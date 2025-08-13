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

import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.HashMap
import java.util.Map
import nl.esi.comma.testspecification.testspecification.TestDefinition

class VFDXMLGenerator {

    static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    static final String DEFAULT_NS    ='http://www.comma.esi/default/VFDSchema'
    static final String DEFAULT_XSI   ='http://www.comma.esi/default/VFDSchema-instance'
    static final String DEFAULT_LOC   ='http://www.comma.esi/default/VFDSchema-location'
    static final String DEFAULT_TITLE ='Default Title'

    String ns
    String xsi
    String loc
    String title

    Map<String, String> rename  = new HashMap<String,String>()
    Map<String, String> args = new HashMap<String,String>()

    new(){
        this(
            DEFAULT_NS, 
            DEFAULT_XSI, 
            DEFAULT_LOC, 
            DEFAULT_TITLE
        )
    }

    new(String ns, String xsi, String loc, String title){
        this.ns=ns
        this.xsi=xsi
        this.loc=loc
        this.title=title
    }

    new(Map<String, String> params, Map<String, String> renameRules) {
        this(
            params.getOrDefault('xmlns', DEFAULT_NS),
            params.getOrDefault('xsi',   DEFAULT_XSI),
            params.getOrDefault('loc',   DEFAULT_LOC),
            params.getOrDefault('title', DEFAULT_TITLE)
        )
        this.args.putAll(params)
        this.rename.putAll(renameRules)
    }

    def generateXMLFromSUTVars(TestDefinition atd) 
    {
        var now = LocalDateTime.now();

        return '''
        <?xml version="1.0" encoding="UTF-8"?>
        <VirtualFabDefinition:VirtualFabDefinition xmlns:VirtualFabDefinition="«this.ns»" xmlns:xsi="«this.xsi»" xsi:schemaLocation="«this.loc»">
          <Header>
            <Title>«this.title»</Title>
            <CreateTime>«now.format(VFDXMLGenerator.formatter)»</CreateTime>
          </Header>
          <Definition>
            <Name>atd</Name>
            <Description>sutsdesc</Description>
            <SUTList>
            «IF atd.sutList !== null »
            «FOR attr : atd.sutList.values»
                <SUT>
                    «JsonHelper.toXMLElement(attr, this.rename)»
                </SUT>
            «ENDFOR»
            «ENDIF»
            </SUTList>
          </Definition>
        </VirtualFabDefinition:VirtualFabDefinition>
        '''
    }
    
    def setRenamingRules(Map<String, String> map) {
        this.rename = new HashMap<String, String>(map)
    }

    def setGeneratorParams(Map<String, String> map) {
        this.args = new HashMap<String, String>(map)
    }

}