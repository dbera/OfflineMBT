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
import java.nio.charset.StandardCharsets
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

import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*

class PetriNetToAbstractTspecGenerator extends AbstractGenerator {

    val IStatusReporting reporting;
    val String pythonExe;

    new(String pythonExe, IStatusReporting reporting) {
        this.pythonExe = pythonExe ?: 'python.exe'
        this.reporting = reporting
    }

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val resourceSet = res.resourceSet
        val petriNetURI = res.URI
        val productName = petriNetURI.trimFileExtension.appendFileExtension('ps').lastSegment
        val productURI = resourceSet.resources.map[URI].findFirst[lastSegment == productName]
        if (productURI === null) {
            reporting.addReport(StatusReportHelper.errorReport(
                '''Product file «productName» not found in resource set.''', newArrayList()))
        } else {
            doGenerate(resourceSet, petriNetURI, productURI, fsa, ctx)
        }
    }

    def void doGenerate(ResourceSet rst, URI petriNetURI, URI productURI, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val statusReportFile = fsa.getURI("status_report.json").toPath
        val pspath = productURI.trimSegments(1).appendSegment("").deresolve(fsa.getURI("dummy.atspec"), true, true, true)
        val process = Runtime.getRuntime().exec(#[
            pythonExe,
            petriNetURI.toPath,
            '-no_sim=TRUE',
            '-tsdir=' + fsa.rootURI.toPath,
            '-pudir=' + fsa.getURI('plantuml').toPath,
            '-srfile=' + statusReportFile,
            '-pspath=' + pspath
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
            statusReportFile.readReport ?: StatusReportHelper.warningReport('Python status report is not available', Collections.emptyList)
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
            val report = StatusReportHelper.fromException(e, 'Failed to read Python status report', Collections.emptyList)
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
