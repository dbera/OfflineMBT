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
package nl.esi.comma.abstracttestspecification.generator.to.bpmn

import nl.esi.comma.abstracttestspecification.abstractTestspecification.TSMain
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

class FromAbstractToBpmn extends AbstractGenerator {

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val atd = res.contents.filter(TSMain).map[model].filter(AbstractTestDefinition).head
        if (atd === null) {
            throw new Exception('No abstract tspec found in resource: ' + res.URI)
        }

        val bpmnFileName = res.URI.lastSegment.replaceAll('\\.atspec$', '.bpmn')
        fsa.generateFile(bpmnFileName, atd.generateBPMNModel())
    }

    def private String generateBPMNModel(AbstractTestDefinition atd) {
        return CamundaParser.generateBPMNModel(atd)
    }
}
