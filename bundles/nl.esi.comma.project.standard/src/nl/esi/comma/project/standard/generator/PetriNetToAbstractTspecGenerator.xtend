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

import java.io.BufferedReader
import java.util.concurrent.TimeUnit
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import static extension nl.esi.comma.types.utilities.FileSystemAccessUtil.*

class PetriNetToAbstractTspecGenerator extends AbstractGenerator {
    val String pythonExe;

    new() {
        this(null)
    }

    new(String pythonExe) {
        this.pythonExe = pythonExe ?: 'python.exe'
    }

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        doGenerate(res.resourceSet, res.URI, fsa, ctx)
    }

    def void doGenerate(ResourceSet rst, URI uri, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val process = Runtime.getRuntime().exec(#[
            pythonExe,
            uri.toPath,
            '-no_sim=TRUE',
            '-tsdir=' + fsa.rootURI.toPath,
            '-pudir=' + fsa.getURI('plantuml').toPath
        ])

        val out = process.inputReader.readAll
        if (!out.isNullOrEmpty) {
            System.out.print(out)
        }
        val err = process.errorReader.readAll
        if (!err.isNullOrEmpty) {
            System.err.print(err)
        }
        if (!process.waitFor(10, TimeUnit::SECONDS)) {
            throw new RuntimeException('Python process did not end in time')
        } else if (process.exitValue != 0) {
            throw new RuntimeException(
                '''Python process exited with exit code «process.exitValue», see error output for details.''')
        }

        // Refresh the files-system to detect the generated files
        fsa.refresh
    }

    def String readAll(BufferedReader reader) {
        var text = ''
        var String line = null
        while ((line = reader.readLine()) !== null) {
            text += line + System.lineSeparator
        }
        return text
    }
}
