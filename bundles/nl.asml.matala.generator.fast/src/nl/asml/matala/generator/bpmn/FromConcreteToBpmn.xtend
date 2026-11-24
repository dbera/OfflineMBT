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
package nl.asml.matala.generator.bpmn

import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition
import nl.esi.comma.project.standard.generator.^extension.IStandardProjectGeneratorExtension
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*
import nl.esi.comma.testspecification.testspecification.TestDefinition

class FromConcreteToBpmn extends AbstractGenerator implements IStandardProjectGeneratorExtension {

    val String FOLDER_BPMN_TSPEC = "generated_bpmn/"

    override doGenerate(Resource conTspecRes, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        // Find and load the abstract tspec for this concrete tspec
        val absTspecFsa = fsa.createFolderAccess(FOLDER_ABSTRACT_TSPEC)
        val absTspecURI = conTspecRes.URI.trimFileExtension.appendFileExtension('atspec')
        val absTspecRes = absTspecFsa.loadResource(absTspecURI.lastSegment, conTspecRes.resourceSet)
        absTspecRes.checkResource()

        val atd = absTspecRes.contents.filter(nl.esi.comma.abstracttestspecification.abstractTestspecification.TSMain)
                                      .map[model]
                                      .filter(AbstractTestDefinition).head
        val ctd = conTspecRes.contents.filter(nl.esi.comma.testspecification.testspecification.TSMain)
                                      .map[model]
                                      .filter(TestDefinition).head

        val bpmnFileName = conTspecRes.URI.lastSegment.replaceAll('\\.tspec$', '.bpmn')
        val bpmnTspecFsa = fsa.createFolderAccess(FOLDER_BPMN_TSPEC)
        bpmnTspecFsa.generateFile(bpmnFileName, generateBPMNModel(atd,ctd))
    }

    def private String generateBPMNModel(AbstractTestDefinition atd, TestDefinition ctd) {
        return CamundaParser.generateBPMNModel(atd, ctd)
    }
}