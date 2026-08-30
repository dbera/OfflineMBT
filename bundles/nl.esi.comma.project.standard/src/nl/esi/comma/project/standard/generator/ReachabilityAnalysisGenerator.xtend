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

import nl.esi.comma.project.standard.standardProject.ReachabilityAnalysisBlock
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import nl.esi.comma.project.standard.standardProject.Project

import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import nl.asml.matala.product.product.Product
import nl.asml.matala.product.generator.ProductGenerator
import com.google.inject.Inject
import nl.esi.comma.project.standard.generator.^extension.IStandardProjectGeneratorExtension

import static nl.esi.comma.project.standard.generator.^extension.IStandardProjectGeneratorExtension.*;
import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*
import nl.asml.matala.product.generator.ProductGenerationMode

class ReachabilityAnalysisGenerator extends AbstractGenerator 
{
    @Inject
    IStandardProjectGeneratorExtension.Registry generatorExtensions;

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        res.contents.filter(Project).flatMap[reachabilityAnalysisBlocks].forEach[doGenerate(res, fsa, ctx)]
    }

    def doGenerate(ReachabilityAnalysisBlock task, ResourceSet rst, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        // val productURI = task.eResource.resolveUri(task.product)
        val productURI = if (task.bpmn.nullOrEmpty) {
                task.eResource.resolveUri(task.product)
            } else {
                val bpmnUri = task.eResource.resolveUri(task.bpmn)
                // val numTests = task.numTests <= 0 ? 1 : task.numTests
                val depthLimit = task.depthLimit <= 0 ? 300 : task.depthLimit
                val stateLimit = task.stateLimit <= 0 ? 1000 : task.stateLimit
                val pspecFsa = fsa.createFolderAccess(FOLDER_PSPEC)

                (new Bpmn4sToPspecGenerator(0, depthLimit, stateLimit)).doGenerate(rst, bpmnUri, pspecFsa, ctx)

                pspecFsa.getURI(bpmnUri.trimFileExtension.appendFileExtension('ps').lastSegment)
            }
        
        // Load and validate the (generated) product
        val productRes = rst.getResource(productURI, true)
        val product = productRes.contents.filter(Product).findFirst[specification !== null]
        if (product === null) {
            throw new Exception('No product found in resource: ' + productURI)
        }
        productRes.resolveAll()
        product.imports.forEach[productRes.getResource(importURI).validate()]
        productRes.validate()

        // PspecToPetriNetGenerator
//        (new ProductGenerator(true)).doGenerate(productRes, fsa, ctx)
        (new ProductGenerator(ProductGenerationMode.RG_GENERATION)).doGenerate(productRes, fsa, ctx)

        // Generate abstract tspec from petri-net
        val specName = product.specification.name
        val petriNetURI = fsa.getURI('''«FOLDER_CPN_SERVER»/«specName»/«specName».py''')
        val absTspecFsa = fsa.createFolderAccess(FOLDER_ABSTRACT_TSPEC)
        (new PetriNetToAbstractTspecGenerator(task.pythonExe)).doGenerate(rst, petriNetURI, absTspecFsa, ctx)
    }
}