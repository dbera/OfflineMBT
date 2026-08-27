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
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.PrintStream
import java.nio.file.Files
import java.nio.file.Path
import java.util.Collections
import java.util.concurrent.TimeUnit
import nl.esi.xtext.common.lang.reporting.IStatusReporting
import nl.esi.xtext.common.lang.reporting.StatusReport
import nl.esi.xtext.common.lang.reporting.StatusReportHelper
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static nl.esi.comma.project.standard.generator.^extension.IStandardProjectGeneratorExtension.*

import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import java.nio.charset.StandardCharsets

class PetriNetToAbstractTspecGenerator extends AbstractGenerator {

    val IStatusReporting reporting;
    val String pythonExe;

    new(String pythonExe, IStatusReporting reporting) {
        this.pythonExe = pythonExe ?: 'python.exe'
        this.reporting = reporting
    }

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        doGenerate(res.resourceSet, res.URI, fsa, ctx)
    }

    def void doGenerate(ResourceSet rst, URI uri, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val statusReportFile = fsa.rootURI.appendSegment("status_report.json").toPath
        val process = Runtime.getRuntime().exec(#[
            pythonExe,
            uri.toPath,
            '-no_sim=TRUE',
            '-tsdir=' + fsa.rootURI.toPath,
            '-pudir=' + fsa.getURI('plantuml').toPath,
            '-srfile=' + statusReportFile,
            '-pspath=' + '../' + FOLDER_PSPEC + '/'
        ])
        val errOut = new ByteArrayOutputStream
        process.inputReader.pipeTo(System.out)
        process.errorReader.pipeTo(System.err, new PrintStream(errOut))
        val report = if (!process.waitFor(10, TimeUnit::MINUTES)) {
            process.destroyForcibly
            val childReports = newArrayList()
            val statusReport = statusReportFile.readReport
            if (statusReport !== null) {
                childReports += statusReport
            }
            StatusReportHelper.errorReport('Python process did not end in time', childReports)
        } else if (process.exitValue != 0) {
            val childReports = newArrayList()
            val statusReport = statusReportFile.readReport
            if (statusReport !== null) {
                childReports += statusReport
            }
            if (errOut.size > 0) {
                childReports += StatusReportHelper.errorReport(
                    new String(errOut.toByteArray, StandardCharsets.UTF_8), Collections.emptyList)
            }
            StatusReportHelper.errorReport('Python process exited with exit code ' + process.exitValue, childReports)
        } else {
            statusReportFile.readReport ?: StatusReportHelper.warningReport('Status report is not available', Collections.emptyList)
        }
        reporting.addReport(report)
        // Refresh the files-system to detect the generated files
        fsa.refresh
    }

    private def StatusReport readReport(String statusReportFile) {
        val statusReportPath = Path.of(statusReportFile)
        if (!Files.exists(statusReportPath)) {
            return null
        }
        try {
            val report = StatusReportHelper.fromJson(Files.readString(statusReportPath))
            return report
        } catch (IOException e) {
            val report = StatusReportHelper.fromException(e, 'Failed to read status report', Collections.emptyList)
            return report
        }
    }

    private def Thread pipeTo(BufferedReader input, PrintStream... outputs) {
        return Thread.startVirtualThread [
            var String line = null
            while ((line = input.readLine()) !== null) {
                for (out : outputs) {
                    out.println(line)
                }
            }
        ]
    }
}
