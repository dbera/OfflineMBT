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
import java.io.PrintStream
import java.util.concurrent.TimeUnit
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*

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
        process.inputReader.pipeTo(System.out)
        process.errorReader.pipeTo(System.err)
        if (!process.waitFor(10, TimeUnit::MINUTES)) {
            process.destroyForcibly
            throw new RuntimeException('Python process did not end in time')
        } else if (process.exitValue != 0) {
            throw new RuntimeException(
                '''Python process exited with exit code «process.exitValue», see error output for details.''')
        }

        // Refresh the files-system to detect the generated files
        fsa.refresh
    }

    def Thread pipeTo(BufferedReader input, PrintStream output) {
        return Thread.startVirtualThread[
            var String line = null
            while ((line = input.readLine()) !== null) {
                output.println(line)
            }
        ]
    }
}
