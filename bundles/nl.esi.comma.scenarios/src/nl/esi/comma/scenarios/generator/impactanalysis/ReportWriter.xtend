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
package nl.esi.comma.scenarios.generator.impactanalysis

import org.eclipse.xtext.generator.IFileSystemAccess2

class ReportWriter {
	
	val IFileSystemAccess2 fsa
	val String fileName
	
	new(IFileSystemAccess2 fsa, String fileName) {
		this.fsa = fsa
		this.fileName = fileName
	}
	
	def void write(ImpactAnalysisReport report) {
		var reports = new Reports
		val byte[] dashboardHtml = reports.htmlTemplate

		fsa.generateFile(fileName, new String(dashboardHtml).replace("\"%REPORT%\"", report.toJson()))
	}
}