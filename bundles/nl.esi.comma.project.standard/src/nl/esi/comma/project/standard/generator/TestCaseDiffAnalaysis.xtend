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
 
package nl.esi.comma.project.standard.generator

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import nl.esi.comma.project.standard.standardProject.TestCaseDiffBlock
import org.eclipse.emf.ecore.resource.ResourceSet
import nl.esi.comma.project.standard.standardProject.Project
import nl.esi.comma.testspecification.generator.json.TestspecificationJsonGenerator
import nl.esi.comma.project.standard.generator.^extension.IStandardProjectGeneratorExtension
import org.eclipse.emf.ecore.resource.Resource

import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import org.eclipse.xtext.EcoreUtil2

class TestCaseDiffAnalaysis extends AbstractGenerator 
{
    val TestspecificationJsonGenerator testSpecificationJsonGenerator = new TestspecificationJsonGenerator

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        res.contents.filter(Project).flatMap[testCaseDiffBlocks].forEach[doGenerate(res, fsa, ctx)]
    }

    def doGenerate(TestCaseDiffBlock task, ResourceSet rst, IFileSystemAccess2 fsa, IGeneratorContext ctx) 
    {
        if(task.oldScenario !== null) {
            var tspecResource = EcoreUtil2.getResource(task.eResource, task.oldScenario)
            val tspecUri = task.eResource.resolveUri(task.oldScenario)
            val conTspecRes = rst.getResource(tspecUri, true)
            if(tspecResource === null) { throw new Exception(task.oldScenario + " Could not be resolved.") }
            var tspec = tspecResource.allContents.head
            if(tspec !== null && tspec instanceof TSMain) {
                val ctd = ((tspec as TSMain).model as TestDefinition)
                testSpecificationJsonGenerator.generate("old_", ctd, conTspecRes, fsa)
            }
        }

        if(task.newScenario !== null) {
            var tspecResource = EcoreUtil2.getResource(task.eResource, task.newScenario)
            val tspecUri = task.eResource.resolveUri(task.newScenario)
            val conTspecRes = rst.getResource(tspecUri, true)
            if(tspecResource === null) { throw new Exception(task.newScenario + " Could not be resolved.") }
            var tspec = tspecResource.allContents.head
            if(tspec !== null && tspec instanceof TSMain) {
                val ctd = ((tspec as TSMain).model as TestDefinition)
                testSpecificationJsonGenerator.generate("new_", ctd, conTspecRes, fsa)
            }
        }
    }
}