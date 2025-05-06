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

import nl.asml.matala.bpmn4s.Main
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import static extension nl.esi.comma.types.utilities.FileSystemAccessUtil.*

class Bpmn4sToPspecGenerator extends AbstractGenerator {
    val boolean simulation
    val int numTests
    val int depthLimit

    new() {
        this(false, 1, 300)
    }

    new(boolean simulation, int numTests, int depthLimit) {
        this.simulation = simulation
        this.numTests = numTests
        this.depthLimit = depthLimit
    }

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        doGenerate(res.resourceSet, res.URI, fsa, ctx)
    }

    /**
     * FIXME: nl.asml.matala.bpmn4s.Main should implement Xtext generator API
     */
    def void doGenerate(ResourceSet rst, URI uri, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        // Temporary generate the file to ensure that folders exist
        val pspecPath = uri.trimFileExtension.appendFileExtension('ps').lastSegment
        fsa.generateFile(pspecPath, '// TODO: Generate content')
        val typesPath = uri.trimFileExtension.appendFileExtension('types').lastSegment
        fsa.generateFile(typesPath, '// TODO: Generate content')

        // Generate the pspec file from the bpmn file
        Main.compile(uri.toPath, simulation, fsa.rootURI.toPath, depthLimit, numTests)

        // Refresh the files-system to detect the generated files
        fsa.refresh
    }
}
